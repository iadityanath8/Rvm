// standars
const std = @import("std");
const print = std.debug.print;

// allocations 
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
const eval = @import("rvme.zig");

// requiring c library
const c = @cImport({
    @cInclude("stdio.h");
});

// constants
const MAGIC_BYTE_SIZE:usize = 8;


// TODO: read a file and then evaluate the following bytecode in here

//pub fn reader()
  //  const file: ?*c.FILE = c.fopen(Self.name_to_be_assembled, "rb");

    //if (file == null) {
      //   std.debug.print("Failed to open file '{s}'\n", .{Self.name_to_be_assembled});
        //    return;
   // }

    //var buffer: [128]u8 = undefined;

    //_ = c.fread(buffer[0..], Self.byte_size, @as(c_ulong, @intCast(Self.program_size)), file);

    //var r: [*]eval.Program = @ptrCast(@alignCast(&buffer));
   // print("{any}\n", .{r[1]});
 // _ = c.fclose(file);
//
//}

fn disassembly(filename:[:0]u8) !void {
    const file:?*c.FILE = c.fopen(filename,"rb");

    if(file == null){
        return eval.Machine_Err.COULD_NOT_OPEN_FILE;
    }

     _ = c.fseek(file, 0, c.SEEK_END);
    const fileSize = c.ftell(file);
    _ = c.fseek(file, 0, c.SEEK_SET);
    
    var buffer:[]u8 = try allocator.alloc(u8,MAGIC_BYTE_SIZE*@as(usize,@intCast(fileSize)));
    defer _ = allocator.free(buffer);

    
    _ = c.fread(buffer.ptr, MAGIC_BYTE_SIZE,@as(c_ulong,@intCast(fileSize)), file);

    
    var r:[*]eval.Program = @ptrCast(@alignCast(buffer.ptr));
    var emulator = eval.Rvm.new();
    emulator.fill_prog(@as(u32,@intCast(fileSize)),r);
    try emulator.evaluate_program();
    emulator.stack_debug_print();
    _ = c.fclose(file);
}

pub fn main() !void {
    defer _ = gpa.deinit();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // getting and printing the string of args in here
    //print("{s}\n",.{args[1]});
    try disassembly(args[1]);
    //print("{}\n",.{args.len});
    //print("{}\n",.{@TypeOf(args)});
}

// type ==> [][:0]u8
// usage: diassembly file_name.rasm
