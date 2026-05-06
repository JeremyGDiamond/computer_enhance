const std = @import("std");
const Io = std.Io;

const computer_enhance = @import("computer_enhance");

pub fn main(init: std.process.Init) !void {
    // Prints to stderr, unbuffered, ignoring potential errors.
    //std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // TODO open bin file
    //
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len < 2) {
        std.debug.print("Usage: program <file>\n", .{});
        return;
    }
    const path = args[1];

    const cwd = std.Io.Dir.cwd();
    const file = try cwd.openFile(init.io, path, .{});
    defer file.close(init.io);

    var buf: [4096]u8 = undefined;
    const n = try file.readPositionalAll(init.io, &buf, 0);
    _ = buf[0..n];

    // debug print of raw bin
    // var index: u64 = 0;
    // while (index < n) {
    //     std.debug.print("{b}", .{buf[index]});
    //     std.debug.print("{b}", .{buf[index + 1]});
    //     std.debug.print("\n", .{});
    //     index += 2;
    // }
    //
    // std.debug.print("\n", .{});
    //
    // TODO decode mov with target
    var index: u64 = 0;
    while (index < n) {
        // if the first 6bits are 100010 it is a mov
        // if the 7th is 0 direction is to register else from register
        // if the 8trh is 0 it is an 8bit op else 16 bits
        // 9 and 10 are reg mode
        // 11 to 13 are operand and opcode
        // 14 to 16 more opcode
        index += 2;
    }

    //
    // TODO print output

    //
    // TODO re assemble

}

