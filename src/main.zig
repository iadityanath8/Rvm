const std = @import("std");
const print = @import("std").debug.print;
const mem = std.mem;
const expect = std.testing.expect;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

// [*]ptr is a c pointer and can easily be converted from any fat pointer also known as slices 
// more safe union in here0
const Word = union{
    as_int:i64,
    as_float:f64,
    as_bool:bool,
    as_u8:u8,
    as_ptr:*anyopaque
};

const INST_SET = enum {
    PUSH,
    POP,

    IADD,
    ISUB,
    IMUL,
    IDIV,
    HALT,

    inline fn len() usize{
        return @intFromEnum(INST_SET.HALT);
    }
};

const Machine_Err = error{
    STACK_UNDERFLOW,
    STACK_OVERFLOW,
    UNSATISFIED_OP_COUNT
};


const Program = struct{
    inst_set:INST_SET,
    operand:i32,
};

const Rvm = struct{
    stack:[1024]i32, // an i32 stack
    len:u32,
    
    programs:[1024]Program,
    program_size:u32,

    ip:i32,

    inline fn new() Rvm {
        return Rvm{
            .stack = mem.zeroes([1024]i32),
            .len = 0,
            .program_size = 0,
            .programs = inst_fill_zero(),
            .ip = -1,
        };
    }

    fn push_program(Self:*Rvm, prg:Program) void {
        Self.programs[Self.program_size] = prg;
        Self.program_size += 1;
    }

    fn stack_debug_print(Self:*Rvm) void {
        print("{any}\n",.{Self.stack});
    }
    
    fn evaluate_program(Self:*Rvm) !void {
        // TODO :next we are going to do evaluation in here
        Self.ip+=1;
        var ishalt = false;
    
        while(!ishalt){
            const instset = Self.programs[@intCast(Self.ip)].inst_set;
            const ops     = Self.programs[@intCast(Self.ip)].operand;
            switch(instset){
                INST_SET.PUSH => {
                    Self.stack[Self.len] = ops;
                    Self.len+=1;
                    //try expect(Self.len >= 2);
                    Self.ip += 1;
                },
                INST_SET.IADD => {
                    //print("One time \n",.{});
                    if(Self.len < 2){
                        print("please provide atleast 2 values for the following operations::",.{});
                        return Machine_Err.UNSATISFIED_OP_COUNT;
                    }
                    Self.stack[Self.len - 2] = Self.stack[Self.len - 1] + Self.stack[Self.len - 2];
                    Self.len -= 1;
                    Self.ip += 1;
                },
                INST_SET.ISUB => {
                    Self.stack[Self.len - 2] = Self.stack[Self.len - 1] - Self.stack[Self.len - 2];
                    Self.len -= 1;
                    Self.ip  += 1;
                },
                INST_SET.IMUL => {
                    Self.stack[Self.len - 2] = Self.stack[Self.len - 1] * Self.stack[Self.len - 2];
                    Self.len -= 1;
                    Self.ip  += 1;
                },
                INST_SET.IDIV => {
                    Self.stack[Self.len - 2] = @divFloor(Self.stack[Self.len - 1], Self.stack[Self.len - 2]);
                    Self.len -= 1;
                    Self.ip  += 1;
                },
                INST_SET.HALT => {
                    ishalt = true;
                    Self.ip = -1;
                },
                else => {}
            }
        }
    }
};


pub fn main() !void {   
    //var memory = try allocator.alloc(u8,100);
    var rm:Rvm = Rvm.new(); // stacks grows downwards 
    
    rm.push_program(.{.inst_set = INST_SET.PUSH,.operand = 89});
    //rm.push_program(.{.inst_set = INST_SET.PUSH,.operand = 12});
    //rm.push_program(.{.inst_set = INST_SET.PUSH,.operand = 10});
    rm.push_program(.{.inst_set = INST_SET.IADD,.operand = undefined});
    //rm.push_program(.{.inst_set = INST_SET.PUSH,.operand = 112});
    //rm.push_program(.{.inst_set = INST_SET.HALT, .operand = undefined});
    
    //rm.push_program(.{.inst_set = INST_SET.IADD,.operand = undefined});
   // print("{any}\n",.{rm.programs});
                   
    try rm.evaluate_program();
    rm.stack_debug_print();
    //print("{}\n",.{rm.ip});
    //FEED(.{.inst_set = INST_SET.PUSH, .operand = 0});
}


// utilities 

inline fn assert_test(cond:bool,Message:[]const u8) void {
    if(!cond){
        @panic(Message);
    }
}

inline fn pointer_cast_from_opaque(comptime T:type, reference: *anyopaque) *T {
    var sslice:*T =  @ptrCast(@alignCast(reference));
    return sslice;
}

inline fn sizeof(comptime T: type) comptime_int{
    return @sizeOf(T);
}

fn Gzero(raw:*anyopaque) *[]u8 {
    var slice:*[]u8 = pointer_cast_from_opaque([]u8, raw);
 
    return slice;
}

fn inst_fill_zero() [1024]Program { // copying 1024 values so there is serious performance overhead
    const len = 1024;
    var array:[1024]Program = undefined;
    
    for(0..len) |i| {
        array[i] = .{.inst_set = INST_SET.HALT, .operand = -1};
    }

    return array;
}
