const std = @import("std");
const print = @import("std").debug.print;
const assembly = @import("assembly.zig").Assembly;
const mem = std.mem;
const expect = std.testing.expect;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

// globals

const PROGRAM_SIZE:usize = 1024;
const STACK_SIZE:usize   = 1024;

// [*]ptr is a c pointer and can easily be converted from any fat pointer also known as slices
// more safe union in here0
const Word = union { as_int: i64, as_float: f64, as_u8: u8, as_ptr: *anyopaque };

pub const INST_SET = enum {

    // stack operations
    PUSH,DUP,
    POP,SWAP,

    // mathematical instuctions
    IADD, ISUB,
    IMUL, IDIV,
    HALT,

    // conditional instruction
    JMP,CJMP,
    EQ,
    
    inline fn len() usize {
        return @intFromEnum(INST_SET.HALT);
    }
};

pub const Machine_Err = error{ STACK_UNDERFLOW, STACK_OVERFLOW, UNSATISFIED_OP_COUNT, COULD_NOT_OPEN_FILE,INSTRUCTION_ADDRESS_NOT_FOUND };

pub const Program = struct {
    inst_set: INST_SET,
    operand: i32,
};

pub const Rvm = struct {
    stack: [STACK_SIZE]i32, // an i32 static stack soon we will replace it with word mentioned above
    len: u32,

    programs: [PROGRAM_SIZE]Program, // static 
    program_size: u32,

    ip: i32,

    pub inline fn new() Rvm {
        return Rvm{
            .stack = mem.zeroes([1024]i32),
            .len = 0,
            .program_size = 0,
            .programs = inst_fill_zero(),
            .ip = -1,
        };
    }

    pub inline fn fill_prog(Self: *Rvm, size: u32, prog: [*]Program) void {
        var prog_pointer = Self.programs[0..size];
        // utils_full_copy_bbw_copy_array_and_pointer_slice(prog, prog_pointer);
        _ = prog_pointer;
        var i: usize = 0;

        while (i < size) {
            Self.programs[i] = prog[i];
            i += 1;
        }

        // i = 0;

        // while (i < size) {
        //     print("{any}\n", .{Self.programs[i]});
        //     i += 1;
        // }
    }

    pub fn push_program(Self: *Rvm, prg: Program) void {
        Self.programs[Self.program_size] = prg;
        Self.program_size += 1;
    }

    pub fn stack_debug_print(Self: *Rvm) void {
        print("t{any}\n", .{Self.stack});
    }

    pub fn top(Self: *Rvm) !void {
        if (Self.len < 1) {
            return Machine_Err.STACK_UNDERFLOW;
        }
        print("{any}\n", .{Self.stack[Self.len - 1]});
    }

    pub fn evaluate_program(Self: *Rvm) !void {
        // TODO :next we are going to do evaluation in here
        Self.ip += 1;
        var ishalt = false;

        while (!ishalt) {
            const instset = Self.programs[@intCast(Self.ip)].inst_set;
            const ops = Self.programs[@intCast(Self.ip)].operand;
            
            switch (instset) {
                INST_SET.PUSH => {
                    Self.stack[Self.len] = ops;
                    Self.len += 1;
                    //try expect(Self.len >= 2);
                    Self.ip += 1;
                },
                INST_SET.IADD => {
                    if (Self.len < 2) {
                        e2println();
                        return Machine_Err.UNSATISFIED_OP_COUNT;
                    }
                    Self.stack[Self.len - 2] = Self.stack[Self.len - 1] + Self.stack[Self.len - 2];
                    Self.len -= 1;
                    Self.ip += 1;
                },
                INST_SET.ISUB => {
                    if(Self.len < 2){
                        e2println();
                        return Machine_Err.UNSATISFIED_OP_COUNT;
                    }
                    Self.stack[Self.len - 2] = Self.stack[Self.len - 1] - Self.stack[Self.len - 2];
                    Self.len -= 1;
                    Self.ip += 1;
                },
                INST_SET.IMUL => {
                    if(Self.len < 2){
                        e2println();
                        return Machine_Err.UNSATISFIED_OP_COUNT;
                    }
                    Self.stack[Self.len - 2] = Self.stack[Self.len - 1] * Self.stack[Self.len - 2];
                    Self.len -= 1;
                    Self.ip += 1;
                },
                INST_SET.IDIV => {
                    if(Self.len < 2){
                        e2println();
                        return Machine_Err.UNSATISFIED_OP_COUNT;
                    }
                    Self.stack[Self.len - 2] = @divFloor(Self.stack[Self.len - 1], Self.stack[Self.len - 2]);
                    Self.len -= 1;
                    Self.ip += 1;
                },
                INST_SET.JMP => {
                    if(ops < 0 or ops >= Self.program_size){
                        print("Instruction pointer halt\n",.{});
                        return Machine_Err.INSTRUCTION_ADDRESS_NOT_FOUND;
                    }
                    Self.ip = ops;
                },
                INST_SET.CJMP => {
                    if(ops < 0 or ops >= Self.program_size){
                        print("Instruction pointer halt\n",.{});
                        return Machine_Err.INSTRUCTION_ADDRESS_NOT_FOUND;
                    }
                    if(Self.stack[Self.len - 1] == 1){
                        Self.ip = ops;
                    }else{
                        Self.ip += 1;
                    }
                },
                INST_SET.EQ =>{
                    if(Self.len < 2){
                        e2println();
                        return Machine_Err.UNSATISFIED_OP_COUNT;
                    }
                    if(Self.stack[Self.len - 1] == Self.stack[Self.len - 2]){
                        Self.stack[Self.len - 1] = 1;  // truth value
                    }else{
                        Self.stack[Self.len - 1] = 0;  // falsy value
                    }                       
                    Self.ip += 1;
                },
                INST_SET.HALT => {
                    ishalt = true;
                    Self.ip = -1;
                },
                else => {},
            } 
        }
    }
};

pub fn main() !void {
    //var memory = try allocator.alloc(u8,100);
    var rm: Rvm = Rvm.new(); // stacks grows downwards 9 -> 21 -> 78 -> iadd

    // rm.push_program(.{ .inst_set = INST_SET.PUSH, .operand = 9 });
    // rm.push_program(.{ .inst_set = INST_SET.PUSH, .operand = 12 });
    // rm.push_program(.{ .inst_set = INST_SET.IADD, .operand = -90 });
    // rm.push_program(.{ .inst_set = INST_SET.PUSH, .operand = 78 });
    // rm.push_program(.{ .inst_set = INST_SET.IMUL, .operand = undefined });
    // rm.push_program(.{ .inst_set = INST_SET.HALT, .operand = -1 });
    rm.push_program(.{.inst_set = INST_SET.PUSH,.operand = 1});
    rm.push_program(.{.inst_set = INST_SET.PUSH,.operand = 1});
    rm.push_program(.{.inst_set = INST_SET.EQ,.operand = undefined});
    rm.push_program(.{.inst_set = INST_SET.CJMP,.operand = 700});
    rm.push_program(.{.inst_set = INST_SET.HALT,.operand = undefined});
    rm.push_program(.{.inst_set = INST_SET.IADD,.operand = undefined});
    // rm.push_program(.{.inst_set = INST_SET.JMP,.operand = 0});
   
   // converts the upper program into the bytecode
    var as = assembly.new(&rm.programs, rm.program_size, @sizeOf(Program), "meow.rasm", allocator);
    as.writer();
    // end of the conversion as it writes the array / buffer into the memory

    // reads a memory into the buffer
    var buffer: []u8 = try as.reader();

    defer _ = gpa.deinit();
    defer allocator.free(buffer);
    // deletes the allocator and defers frees the buffer for reading purpose

    // emulating the arrays / Buffer
    try rm.evaluate_program();
    try rm.top();
    // ending the emulation and printing
}

// utilities

inline fn e2println() void {
    print("please provide atleast 2 values for the following operations::", .{});
}

inline fn assert_test(cond: bool, Message: []const u8) void {
    if (!cond) {
        @panic(Message);
    }
}

inline fn pointer_cast_from_opaque(comptime T: type, reference: *anyopaque) *T {
    var sslice: *T = @ptrCast(@alignCast(reference));
    return sslice;
}

inline fn sizeof(comptime T: type) comptime_int {
    return @sizeOf(T);
}

fn Gzero(raw: *anyopaque) *[]u8 {
    var slice: *[]u8 = pointer_cast_from_opaque([]u8, raw);

    return slice;
}

fn inst_fill_zero() [1024]Program { // copying 1024 values so there is serious performance overhead
    const len = 1024;
    var array: [1024]Program = undefined;

    for (0..len) |i| {
        array[i] = .{ .inst_set = INST_SET.HALT, .operand = -1 };
    }

    return array;
}
