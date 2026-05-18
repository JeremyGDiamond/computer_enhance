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

pub fn regAss2(masked: u8, width: WidthMode) *const [2:0]u8 {
    var r1 = "xx";
    if (width == .eight_bit) {
        r1 = switch (masked) {
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
        r1 = switch (masked) {
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
    return r1;
}

pub fn sliceAndRet(str: *const [9:0]u8, slen: *u64) *const [9:0]u8 {
    var count: u64 = 9;
    var char = " "[0];
    while (char == " "[0]) {
        count -= 1;
        char = str[count - 1];
    }
    // we wnt past by one
    slen.* = count + 1;
    return str;
}

pub fn setR3(val: u8, slen: *u64, r3: *[8:0]u8) !void {
    if (val == 0) {
        slen.* = 1;
        r3.* = "]       ".*;
    } else {
        const locStr = try std.fmt.bufPrint(r3, "+ {d}]", .{val});
        // std.debug.print("locStr: {s}\n", .{locStr});
        slen.* = locStr.len;
    }
    return;
}

pub fn setR3STeen(val: u16, slen: *u64, r3: *[8:0]u8) !void {
    if (val == 0) {
        slen.* = 1;
        r3.* = "]       ".*;
    } else {
        const locStr = try std.fmt.bufPrint(r3, "+ {d}]", .{val});
        // std.debug.print("locStr: {s}\n", .{locStr});
        slen.* = locStr.len;
    }
    return;
}

pub fn mov_reg_mem_to_reg(buf: *[4096]u8, index: u64) !u64 {
    const Mode_reg_mem_to_reg = enum { mem0, mem8, mem16, reg, fail };
    const D_bit_modes = enum { src_reg, des_reg, fail };

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

    const dMask = (buf[index] & 0b00000010);
    const d_bit: D_bit_modes = switch (dMask) {
        0b00000010 => .src_reg,
        0b00000000 => .des_reg,
        else => .fail,
    };

    const regBits = (buf.*[index + 1] & 0b00111000) >> 3;

    const rmBits = buf.*[index + 1] & 0b00000111;

    var r1 = "xx";

    var r2 = "[xx + xx]";

    var sliceLenR2: u64 = 9;

    var r3: [8:0]u8 = undefined;

    var sliceLenR3: u64 = 8;

    switch (mem_mode) {
        .reg => {
            r1 = regAss2((buf.*[index + 1] & 0b00111000) >> 3, width);

            if (width == .eight_bit) {
                r2 = switch ((buf.*[index + 1] & 0b00000111)) {
                    0b00000000 => "al       ",
                    0b00000001 => "cl       ",
                    0b00000010 => "dl       ",
                    0b00000011 => "bl       ",
                    0b00000100 => "ah       ",
                    0b00000101 => "ch       ",
                    0b00000110 => "dh       ",
                    0b00000111 => "bh       ",
                    else => "fl       ",
                };
                sliceLenR2 = 2;
            } else {
                r2 = switch ((buf.*[index + 1] & 0b00000111)) {
                    0b00000000 => "ax       ",
                    0b00000001 => "cx       ",
                    0b00000010 => "dx       ",
                    0b00000011 => "bx       ",
                    0b00000100 => "sp       ",
                    0b00000101 => "bp       ",
                    0b00000110 => "si       ",
                    0b00000111 => "di       ",
                    else => "fl       ",
                };
                sliceLenR2 = 2;
            }
            sliceLenR3 = 0;
        },
        .mem0 => {
            r1 = regAss2(regBits, width);

            r2 = switch (rmBits) {
                0b00000000 => sliceAndRet("[bx + si]", &sliceLenR2),
                0b00000001 => sliceAndRet("[bx + di]", &sliceLenR2),
                0b00000010 => sliceAndRet("[bp + si]", &sliceLenR2),
                0b00000011 => sliceAndRet("[bp + di]", &sliceLenR2),
                0b00000100 => sliceAndRet("[si]     ", &sliceLenR2),
                0b00000101 => sliceAndRet("[di]     ", &sliceLenR2),
                0b00000110 => sliceAndRet("[bp]     ", &sliceLenR2),
                0b00000111 => sliceAndRet("[bx]     ", &sliceLenR2),
                else => sliceAndRet("fl       ", &sliceLenR2),
            };

            sliceLenR3 = 0;
        },

        .mem8 => {
            // std.debug.print("mov_reg_mem_to_reg mode mem8\n", .{});
            // std.debug.print("b {b}, b1 {b}, b2 {b}, b3 {b}\n", .{ buf[index], buf[index + 1], buf[index + 2], buf[index + 3] });
            r1 = regAss2(regBits, width);

            r2 = switch (rmBits) {
                0b00000000 => sliceAndRet("[bx + si ", &sliceLenR2),
                0b00000001 => sliceAndRet("[bx + di ", &sliceLenR2),
                0b00000010 => sliceAndRet("[bp + si ", &sliceLenR2),
                0b00000011 => sliceAndRet("[bp + di ", &sliceLenR2),
                0b00000100 => sliceAndRet("[si      ", &sliceLenR2),
                0b00000101 => sliceAndRet("[di      ", &sliceLenR2),
                0b00000110 => sliceAndRet("[bp      ", &sliceLenR2),
                0b00000111 => sliceAndRet("[bx      ", &sliceLenR2),
                else => sliceAndRet("fl       ", &sliceLenR2),
            };

            if (rmBits == 0b00000110) {
                sliceLenR2 -= 1;
            }

            try setR3(buf[index + 2], &sliceLenR3, &r3);
        },

        .mem16 => {
            // std.debug.print("mov_reg_mem_to_reg mode mem16\n", .{});
            r1 = regAss2(regBits, width);

            r2 = switch (rmBits) {
                0b00000000 => sliceAndRet("[bx + si ", &sliceLenR2),
                0b00000001 => sliceAndRet("[bx + di ", &sliceLenR2),
                0b00000010 => sliceAndRet("[bp + si ", &sliceLenR2),
                0b00000011 => sliceAndRet("[bp + di ", &sliceLenR2),
                0b00000100 => sliceAndRet("[si      ", &sliceLenR2),
                0b00000101 => sliceAndRet("[di      ", &sliceLenR2),
                0b00000110 => sliceAndRet("[bp      ", &sliceLenR2),
                0b00000111 => sliceAndRet("[bx      ", &sliceLenR2),
                else => sliceAndRet("fl       ", &sliceLenR2),
            };

            if (rmBits == 0b00000110) {
                sliceLenR2 -= 1;
            }

            try setR3STeen(((@as(u16, buf[index + 3]) << 8) | @as(u16, buf[index + 2])), &sliceLenR3, &r3);
        },
        else => {
            std.debug.print("mov_reg_mem_to_reg mode fail\n", .{});
        },
    }

    switch (d_bit) {
        .des_reg => std.debug.print("mov {s}{s}, {s}\n", .{ r2[0..sliceLenR2], r3[0..sliceLenR3], r1 }),
        .src_reg => std.debug.print("mov {s}, {s}{s}\n", .{ r1, r2[0..sliceLenR2], r3[0..sliceLenR3] }),
        .fail => std.debug.print("mov dbit error\n", .{}),
    }
    switch (mem_mode) {
        .reg => return 0,
        .mem0 => return 0,
        .mem8 => return 1,
        .mem16 => return 2,
        .fail => return 0,
    }

    return 0;
}

pub fn mov_imm_to_reg(buf: *[4096]u8, index: u64) u64 {
    if (buf.*[index] & 0b00001000 == 0b00001000) {
        const regStr = switch (buf.*[index] & 0b00000111) {
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

        std.debug.print("mov {s}, {d}\n", .{ regStr, std.mem.readInt(u16, @ptrCast(buf[index + 1 .. index + 2]), .native) });

        return 1;
    }

    const regStr = switch (buf.*[index] & 0b00000111) {
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

    std.debug.print("mov {s}, {d}\n", .{ regStr, buf.*[index + 1] });
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

        // if (instruction == Inst.mov_imm_to_reg) {
        //     iter += mov_imm_to_reg(&buf, index);
        // }

        if (instruction == Inst.mov_imm_to_reg_mem) {
            //mask w bit
            if (buf[index] & 0b00001000 == 0b00001000) {
                iter += 1;
            }
        }

        if (instruction == Inst.mov_reg_mem_to_reg) {
            iter += try mov_reg_mem_to_reg(&buf, index);
        } else {
            switch (instruction) {
                .mov_imm_to_reg_mem => std.debug.print("mov_imm_to_reg_mem\n", .{}),
                .mov_imm_to_reg => iter += mov_imm_to_reg(&buf, index),
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
