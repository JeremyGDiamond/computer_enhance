const std = @import("std");
const Io = std.Io;

const computer_enhance = @import("computer_enhance");
const Inst = enum { mov_reg_mem_to_reg, mov_imm_to_reg_mem, mov_imm_to_reg, mov_mem_to_acc, mov_acc_to_mem, mov_reg_mem_to_segreg, mov_segreg_toreg_mem, fail };
// const Direct = enum { right_into_left, left_into_right };
const WidthMode = enum { eight_bit, sixT_bit };
// const EightRegNames = enum { AL, CL, DL, BL, AH, CH, DH, BH };
// const SixTRegNames = enum { AX, CX, DX, BX, SP, BP, Sl, DI };

pub fn opcode(buf: *u8) Inst {
    const instructMask = (buf.* & 0b11111100);
    // std.debug.print("ponter: {}  ", .{buf});
    // std.debug.print("opbyte: {b}  ", .{buf.*});
    return (switch (instructMask) {
        0b10001000 => Inst.mov_reg_mem_to_reg,
        else => Inst.fail,
    });
}

pub fn mov_reg_mem_to_reg(buf: [4096]u8, index: u64, instruction: Inst, width: WidthMode) u64 {
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
        Inst.mov_reg_mem_to_reg => "mov",
        Inst.mov_imm_to_reg_mem => "mov",
        Inst.mov_imm_to_reg => "mov",
        Inst.mov_mem_to_acc => "mov",
        Inst.mov_acc_to_mem => "mov",
        Inst.mov_reg_mem_to_segreg => "mov",
        Inst.mov_segreg_toreg_mem => "mov",

        Inst.fail => "fail",
    };
    std.debug.print("{s} {s} {s}\n", .{ numonic, r2, r1 });
    return 0;
}

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

    var index: u64 = 0;

    // debug print of raw bin in 2 byte width
    // while (index < n) {
    //     std.debug.print("{b}", .{buf[index]});
    //     std.debug.print("{b}", .{buf[index + 1]});
    //     std.debug.print("\n", .{});
    //     index += 2;
    // }
    // index = 0;

    std.debug.print("bits 16\n\n", .{});

    while (index < n) {
        // if the first 6bits are 0b100010 it is a mov
        const instruction = opcode(&(buf[index]));

        // if the 7th is 0 direction is to register else from register
        // const dirMask = (buf[index] & 0b00000010);
        // const direction = switch (dirMask) {
        //     0b00000000 => Direct.left_into_right,
        //     else => Direct.right_into_left,
        // };
        //

        const wMask = (buf[index] & 0b00000001);
        const width = switch (wMask) {
            0b00000000 => WidthMode.eight_bit,
            else => WidthMode.sixT_bit,
        };

        var iter: u64 = switch (instruction) {
            Inst.mov_reg_mem_to_reg => 2,
            Inst.mov_imm_to_reg_mem => 3,
            Inst.mov_imm_to_reg => 2,
            Inst.mov_mem_to_acc => 3,
            Inst.mov_acc_to_mem => 3,
            Inst.mov_reg_mem_to_segreg => 2,
            Inst.mov_segreg_toreg_mem => 2,

            Inst.fail => 2,
        };

        if ((instruction == Inst.mov_imm_to_reg_mem or instruction ==
            Inst.mov_imm_to_reg) and width == WidthMode.sixT_bit)
        {
            iter += 1;
        }

        if (instruction == Inst.mov_reg_mem_to_reg) {
            iter += mov_reg_mem_to_reg(buf, index, instruction, width);
        } else {
            std.debug.print("fail\n", .{});
        }

        index += iter;
    }
}
