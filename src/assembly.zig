const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const eval = @import("rvme.zig");

const c = @cImport({
    @cInclude("stdio.h");
});


// constants
const RVM_MAGIC_BYTE        = 8;
const MAX_LINEAR_SIZE:usize = 123;

pub const Assembly = struct {
    program_size: usize,
    program_array: []eval.Program,
    byte_size: usize,
    name_to_be_assembled: [*c]const u8,
    gallocator: std.mem.Allocator,

    pub fn new(program: []eval.Program, pg_size: usize, b_size: usize, name: [*c]const u8, alloc: std.mem.Allocator) Assembly {
        return Assembly{ .program_array = program, .program_size = pg_size, .byte_size = b_size, .name_to_be_assembled = name, .gallocator = alloc };
    }

    pub fn writer(Self: *Assembly) void {
        // print("{any}", .{Self.program_array});
        var bytes: [*]u8 = @ptrCast(@alignCast(Self.program_array));
        const file: ?*c.FILE = c.fopen(Self.name_to_be_assembled, "wb");
        if (file == null) {
            print("Cannot open the file ERROR\n", .{});
            return;
        }
        _ = c.fwrite(bytes, Self.byte_size, Self.program_size, file);
        _ = c.fclose(file);
    }

    pub fn reader(Self: *Assembly) ![]u8 {
        const file: ?*c.FILE = c.fopen(Self.name_to_be_assembled, "rb");
        if (file == null) {
            std.debug.print("Failed to open file '{s}'\n", .{Self.name_to_be_assembled});
            return eval.Machine_Err.COULD_NOT_OPEN_FILE;
        }

        var buffer: []u8 = try Self.gallocator.alloc(u8, Self.program_size * Self.byte_size);

        _ = c.fread(buffer.ptr, Self.byte_size, @as(c_ulong, @intCast(Self.program_size)), file);

        //var r: [*]eval.Program = @ptrCast(@alignCast(buffer.ptr))
        return buffer;
    }
};

const string = []const u8;
const mutstring = [MAX_LINEAR_SIZE]u8;
const EQ = std.mem.eql;

const chunk = struct{
    raw:[MAX_LINEAR_SIZE]u8,
    len:usize,

    fn write(Self:*chunk,val:u8) void {
        Self.raw[Self.len] = val;
        Self.len += 1;
    }

    fn from_u8(Self:*chunk,val:[]u8) void {
        var i:usize = 0;
        while(i < val.len): (i += 1){
            Self.raw[i] = val[i];
        }
        Self.len = i;
    }

    fn eq(Self:chunk, a:[]const u8) bool {
        var i:usize = 0;

        if(Self.len > a.len){
            return false;
        }

        while(i < a.len) : (i += 1){
            if (Self.raw[i] != a[i]){
                return false;
            }
        }

        return true;
    }

    fn out_slice(Self:*chunk) []const u8{
        return Self.raw[0..Self.len];
    }
    
    fn debug(Self:chunk) void {
        var i:usize = 0;
        while(i < Self.len) : (i += 1){
            print("{c}",.{Self.raw[i]});
        }
        print("\n",.{});
    }
};

fn parse_str_chunk(arrl:*std.ArrayList(chunk)) !void {
    var i:usize = 0;
    var rm = eval.Rvm.new();
    
    while(i < arrl.items.len) :(i += 1){
        var it = std.mem.split(u8,arrl.items[i].out_slice()," ");
        while(it.next()) |v|{
            if(EQ(u8,v,"push")){
                if(it.next()) |ii|{
                    rm.push_program(.{.inst_set = eval.INST_SET.PUSH, .operand = try std.fmt.parseInt(i32,ii, 10)});
                }
            }else if(EQ(u8,v,"iadd")){
                rm.push_program(.{.inst_set = eval.INST_SET.IADD, .operand = undefined});
            }
        }
    }
    const allocator = gpa.allocator();
    
    var as = Assembly.new(&rm.programs,rm.program_size,RVM_MAGIC_BYTE,"precomp.rasm",allocator);
    as.writer();
}

pub fn convert_asm_to_bytes() !void {
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const file = try fs.cwd().openFile("mm.rat",.{});
    defer file.close();
    var b_reader = std.io.bufferedReader(file.reader());
    var in_stream = b_reader.reader();

    var contents = std.ArrayList(chunk).init(allocator);
    defer contents.deinit();

    var buffer:[1024]u8 = undefined;

    while(try in_stream.readUntilDelimiterOrEof(&buffer,'\n')) |line|{
        var a:chunk = undefined;
        a.from_u8(line);
        try contents.append(a);
    }

   try  parse_str_chunk(&contents);
}

pub fn main() !void {
    try convert_asm_to_bytes();
}
