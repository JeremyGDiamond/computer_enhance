const std = @import("std");
const Io = std.Io;

const computer_enhance = @import("computer_enhance");
const Inst = enum { mov_reg_mem_to_reg, mov_imm_to_reg_mem, mov_imm_to_reg, mov_mem_to_acc, mov_acc_to_mem, mov_reg_mem_to_segreg, mov_segreg_toreg_mem, fail };
// const Direct = enum { right_into_left, left_into_right };
const WidthMode = enum { eight_bit, sixT_bit };

pub fn opcode(buf: *u8) Inst {
    // std.debug.print("ponter: {}  ", .{buf});
    // std.debug.print("opbyte: {b}  ", .{buf.*});

    if (buf.* & 0b11111100 == 0b10001000) return Inst.mov_reg_mem_to_reg;
    if (buf.* & 0b11111110 == 0b11000110) return Inst.mov_imm_to_reg_mem;
    if (buf.* & 0b11110000 == 0b10110000) return Inst.mov_imm_to_reg;
    if (buf.* & 0b11111110 == 0b10100000) return Inst.mov_mem_to_acc;
    if (buf.* & 0b11111110 == 0b10100010) return Inst.mov_acc_to_mem;
    if (buf.* == 0b10001110) return Inst.mov_reg_mem_to_segreg;
    if (buf.* == 0b10001100) return Inst.mov_segreg_toreg_mem;
    return Inst.fail;
}

pub fn mov_reg_mem_to_reg(buf: *[4096]u8, index: u64) u64 {
    const Mode_reg_mem_to_reg = enum { mem0, mem8, mem16, reg, fail };

    const mem_mode = switch (buf.*[index + 1] & 0b11000000) {
        0b00000000 => Mode_reg_mem_to_reg.mem0,
        0b01000000 => Mode_reg_mem_to_reg.mem8,
        0b10000000 => Mode_reg_mem_to_reg.mem16,
        0b11000000 => Mode_reg_mem_to_reg.reg,
        else => Mode_reg_mem_to_reg.fail,
    };

    const wMask = (buf[index] & 0b00000001);
    const width = switch (wMask) {
        0b00000000 => WidthMode.eight_bit,
        else => WidthMode.sixT_bit,
    };

    switch (mem_mode) {
        Mode_reg_mem_to_reg.reg => {
            var r1 = "xx";

            var r2 = "xx";

            if (width == .eight_bit) {
                r1 = switch ((buf.*[index + 1] & 0b00111000) >> 3) {
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

                r2 = switch (buf.*[index + 1] & 0b00000111) {
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
                r1 = switch ((buf.*[index + 1] & 0b00111000) >> 3) {
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
                r2 = switch (buf.*[index + 1] & 0b00000111) {
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

            std.debug.print("mov {s} {s}\n", .{ r2, r1 });
            return 0;
        },
        .mem0 => {
            std.debug.print("mov_reg_mem_to_reg mode mem0\n", .{});
            return 0;
        },

        .mem8 => {
            std.debug.print("mov_reg_mem_to_reg mode mem8\n", .{});
            return 1;
        },

        .mem16 => {
            std.debug.print("mov_reg_mem_to_reg mode mem16\n", .{});
            return 2;
        },
        else => {
            std.debug.print("mov_reg_mem_to_reg mode fail\n", .{});
        },
    }
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

        if ((instruction == Inst.mov_imm_to_reg_mem) or (instruction ==
            Inst.mov_imm_to_reg))
        {
            //mask w bit
            if (buf[index] & 0b00001000 == 0b00001000) {
                iter += 1;
            }
        }

        if (instruction == Inst.mov_reg_mem_to_reg) {
            iter += mov_reg_mem_to_reg(&buf, index);
        } else {
            switch (instruction) {
                .mov_imm_to_reg_mem => std.debug.print("mov_imm_to_reg_mem\n", .{}),
                .mov_imm_to_reg => std.debug.print("mov_imm_to_reg {b} {b} {b}\n", .{ buf[index], buf[index + 1], buf[index + 2] }),
                .mov_mem_to_acc => std.debug.print("mov_mem_to_acc\n", .{}),
                .mov_acc_to_mem => std.debug.print("mov_acc_to_mem\n", .{}),
                .mov_reg_mem_to_segreg => std.debug.print("mov_reg_mem_to_segreg\n", .{}),
                .mov_segreg_toreg_mem => std.debug.print("mov_segreg_toreg_mem\n", .{}),
                else => std.debug.print("fail {} {b}\n", .{ instruction, buf[index] }),
            }
        }

        index += iter;
    }
}
