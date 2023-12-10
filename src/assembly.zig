const std = @import("std");
const print = std.debug.print;
const gpa = std.heap.GeneralPurposeAllocator(.{}){};
const eval = @import("rvme.zig");

const c = @cImport({
    @cInclude("stdio.h");
});

// pub fn main() void {
//     const filename = "example.txt";
//     const mode = "w"; // Specify the file opening mode (e.g., "w" for write)

//     // Using `fopen` to open a file
//     const file: ?*c.FILE = c.fopen(filename, mode);
//     if (file == null) {
//         std.debug.print("Failed to open file '{s}'\n", .{filename});
//         return;
//     }

//     // Writing to the file using `fputs`
//     const message = "Hello, Zig!\n";
//     _ = c.fputs(message, file);

//     // Closing the file using `fclose`
//     _ = c.fclose(file);
// }
// pub fn main() void {
//     const filename = "example.txt";
//     const mode = "r"; // Specify the file opening mode (e.g., "r" for read)

//     // Using `fopen` to open a file for reading
//     const file: ?*c.FILE = c.fopen(filename, mode);
//     if (file == null) {
//         std.debug.print("Failed to open file '{s}'\n", .{filename});
//         return;
//     }

//     // Determine the size of the file
//     _ = c.fseek(file, 0, c.SEEK_END);
//     const fileSize = c.ftell(file);
//     _ = c.fseek(file, 0, c.SEEK_SET);

//     // Read the file content into a buffer
//     var buffer: [4096]u8 = undefined; // Adjust the buffer size as needed
//     const bytesRead = c.fread(buffer[0..], 1, @as(c_ulong, @intCast(fileSize)), file);

//     // Print the content (or process it as needed)
//     std.debug.print("Read {} bytes from file '{s}':\n", .{ bytesRead, filename });
//     std.debug.print("File Content:\n{s}\n", .{buffer[0..bytesRead]});

//     // Close the file
//     _ = c.fclose(file);
// }

// pub fn main() void {
//     const filename = "enum_data.Rvm";
//     const mode = "wb"; // Specify the file opening mode (e.g., "wb" for write in binary mode)

//     // Using `fopen` to open a file for writing
//     const file: ?*c.FILE = c.fopen(filename, mode);
//     if (file == null) {
//         std.debug.print("Failed to open file '{s}'\n", .{filename});
//         return;
//     }

//     // Array of enums to be written
//     const enumArray = [_]MyEnum{ MyEnum.Option1, MyEnum.Option2, MyEnum.Option3 };

//     // Writing binary data to the file
//     for (enumArray) |item| {
//         const data = enumToBytes(item);
//         _ = c.fwrite(&data, 1, @sizeOf(data), file);
//     }

//     // Closing the file
//     _ = c.fclose(file);
// }

// pub fn main() void {
//     const filename = "enum_data.Rvm";
//     const mode = "rb"; // Specify the file opening mode (e.g., "rb" for read in binary mode)

//     // Using `fopen` to open a file for reading
//     const file: ?*c.FILE = c.fopen(filename, mode);
//     if (file == null) {
//         std.debug.print("Failed to open file '{s}'\n", .{filename});
//         return;
//     }

//     // Determine the size of the file
//     _ = c.fseek(file, 0, c.SEEK_END);
//     const fileSize = c.ftell(file);
//     _ = c.fseek(file, 0, c.SEEK_SET);

//     // Read the file content into a buffer
//     var buffer: [4096]u8 = undefined; // Adjust the buffer size as needed
//     const bytesRead = c.fread(buffer[0..], 1, @as(c_ulong, @intCast(fileSize)), file);

//     // Interpret binary data as enum values
//     for (buffer[0..bytesRead]) |data| {
//         const enumValue = @as(MyEnum, @enumFromInt(data));
//         print("{any}\n", .{enumValue});
//         // std.debug.print("Read enum value: {:d}\n", .{enumValue});
//     }

//     // Close the file
//     _ = c.fclose(file);
// }

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

        //var r: [*]eval.Program = @ptrCast(@alignCast(buffer.ptr));
        print("This{}\n",.{@sizeOf(eval.Program)});
        return buffer;
    }
};

pub fn main() !void {
    // var array = [_]eval.Program{ .{ .inst_set = eval.INST_SET.PUSH, .operand = 2 }, .{ .inst_set = eval.INST_SET.POP, .operand = -1 } };

    // var as = Assembly.new(array, 2, @sizeOf(eval.Program), "astd.Rasm");
    // as.writer();
    // as.reader();
    // var bytes: [*]u8 = @ptrCast(@alignCast(&array));

    // const filename = "astd.Rasm";
    // const mode = "wb";
    // const file: ?*c.FILE = c.fopen(filename, mode);

    // if (file == null) {
    //     std.debug.print("Failed to open file '{s}'\n", .{filename});
    //     return;
    // }

    // _ = c.fwrite(bytes, @sizeOf(eval.Program), 2, file);
    // _ = c.fclose(file);
}

// pub fn main() void {
//     const filename = "astd.Rasm";
//     const mode = "rb"; // Specify the file opening mode (e.g., "rb" for read in binary mode)

//     // Using `fopen` to open a file for reading
//     const file: ?*c.FILE = c.fopen(filename, mode);
//     if (file == null) {
//         std.debug.print("Failed to open file '{s}'\n", .{filename});
//         return;
//     }

//     _ = c.fseek(file, 0, c.SEEK_END);
//     const fileSize = c.ftell(file);
//     _ = c.fseek(file, 0, c.SEEK_SET);

//     var buffer: [128]u8 = undefined;
//     const bytesRead = c.fread(buffer[0..], @sizeOf(eval.Program), @as(c_ulong, @intCast(fileSize)), file);

//     _ = bytesRead;
//     // Interpret binary data as enum values
//     var r: [*]eval.Program = @ptrCast(@alignCast(&buffer));
//     // Close the file
//     print("{any}\n", .{r[0]});
//     _ = c.fclose(file);
// }
