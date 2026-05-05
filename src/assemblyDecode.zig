const std = @import("std");
const Io = std.Io;

const computer_enhance = @import("computer_enhance");

pub fn main(init: std.process.Init) !void {
    // Prints to stderr, unbuffered, ignoring potential errors.
    //std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // TODO open bin file
    //
    const cwd = std.Io.Dir.cwd();
    const file = try cwd.openFile(init.io, "perfaware/part1/listing_0037_single_register_mov", .{});
    defer file.close(init.io);

    var buf: [4096]u8 = undefined;
    const n = try file.readPositionalAll(init.io, &buf, 0);
    _ = buf[0..n];
    // Now you have the file content as a mutable slice.
    std.debug.print("{x}\n", .{buf[0..n]});
    // TODO decode mov with target
    //
    // TODO print output
    //
    // TODO re assemble

}
