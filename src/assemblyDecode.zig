const std = @import("std");
const Io = std.Io;

const computer_enhance = @import("computer_enhance");

pub fn main(init: std.process.Init) !void {
    // Prints to stderr, unbuffered, ignoring potential errors.
    //std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

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
    var index: u64 = 0;

    // while (index < n) {
    //     std.debug.print("{b}", .{buf[index]});
    //     std.debug.print("{b}", .{buf[index + 1]});
    //     std.debug.print("\n", .{});
    //     index += 2;
    // }

    //

    //
    std.debug.print("bits 16\n\n", .{});

    const Inst = enum { mov, fail };
    // const Direct = enum { right_into_left, left_into_right };
    const WidthMode = enum { eight_bit, sixT_bit };
    // const EightRegNames = enum { AL, CL, DL, BL, AH, CH, DH, BH };
    // const SixTRegNames = enum { AX, CX, DX, BX, SP, BP, Sl, DI };

    while (index < n) {
        // if the first 6bits are 0b100010 it is a mov
        const instructMask = (buf[index] & 0b11111100);
        const instruction = switch (instructMask) {
            0b10001000 => Inst.mov,
            else => Inst.fail,
        };
        // if the 7th is 0 direction is to register else from register
        // const dirMask = (buf[index] & 0b00000010);
        // const direction = switch (dirMask) {
        //     0b00000000 => Direct.left_into_right,
        //     else => Direct.right_into_left,
        // };

        const wMask = (buf[index] & 0b00000001);
        const width = switch (wMask) {
            0b00000000 => WidthMode.eight_bit,
            else => WidthMode.sixT_bit,
        };

        var r1 = "xx";

        var r2 = "xx";

        if (width == .eight_bit) {
            r1 = switch ((buf[index + 1] & 0b00111000) >> 3) {
                0b00000000 => "al",
                0b00000001 => "cl",
                0b00000010 => "dl",
                0b00000011 => "bl",
                0b00000100 => "ah",
                0b00000101 => "ch",
                0b00000110 => "dh",
                0b00000111 => "bh",
                else => "fl",
            };

            r2 = switch (buf[index + 1] & 0b00000111) {
                0b00000000 => "al",
                0b00000001 => "cl",
                0b00000010 => "dl",
                0b00000011 => "bl",
                0b00000100 => "ah",
                0b00000101 => "ch",
                0b00000110 => "dh",
                0b00000111 => "bh",
                else => "fl",
            };
        } else {
            r1 = switch ((buf[index + 1] & 0b00111000) >> 3) {
                0b00000000 => "ax",
                0b00000001 => "cx",
                0b00000010 => "dx",
                0b00000011 => "bx",
                0b00000100 => "sp",
                0b00000101 => "bp",
                0b00000110 => "si",
                0b00000111 => "di",
                else => "fl",
            };
            r2 = switch (buf[index + 1] & 0b00000111) {
                0b00000000 => "ax",
                0b00000001 => "cx",
                0b00000010 => "dx",
                0b00000011 => "bx",
                0b00000100 => "sp",
                0b00000101 => "bp",
                0b00000110 => "si",
                0b00000111 => "di",
                else => "fl",
            };
        }

        const numonic = switch (instruction) {
            Inst.mov => "mov",
            Inst.fail => "fail",
        };

        std.debug.print("{s} {s} {s}\n", .{ numonic, r2, r1 });

        index += 2;
    }
}
