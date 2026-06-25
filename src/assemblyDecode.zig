const std = @import("std");
const Io = std.Io;

const computer_enhance = @import("computer_enhance");
const Inst = enum { mov_reg_mem_to_reg, mov_imm_to_reg_mem, mov_imm_to_reg, mov_mem_to_acc, mov_acc_to_mem, mov_reg_mem_to_segreg, mov_segreg_toreg_mem, fail };
// const Direct = enum { right_into_left, left_into_right };
const WidthMode = enum { eight_bit, sixT_bit };

pub fn opcode(buf: *u8) Inst {
    // try std_out.print("ponter: {}  ", .{buf});
    // try std_out.print("opbyte: {b}  ", .{buf.*});

    if (buf.* & 0b11111100 == 0b10001000) return Inst.mov_reg_mem_to_reg;
    if (buf.* & 0b11111110 == 0b11000110) return Inst.mov_imm_to_reg_mem;
    if (buf.* & 0b11110000 == 0b10110000) return Inst.mov_imm_to_reg;
    if (buf.* & 0b11111110 == 0b10100000) return Inst.mov_mem_to_acc;
    if (buf.* & 0b11111110 == 0b10100010) return Inst.mov_acc_to_mem;
    if (buf.* == 0b10001110) return Inst.mov_reg_mem_to_segreg;
    if (buf.* == 0b10001100) return Inst.mov_segreg_toreg_mem;
    return Inst.fail;
}

pub fn regAss2(masked: u8, width: WidthMode) []const u8 {
    if (width == .eight_bit) {
        switch (masked) {
            0b00000000 => return "al",
            0b00000001 => return "cl",
            0b00000010 => return "dl",
            0b00000011 => return "bl",
            0b00000100 => return "ah",
            0b00000101 => return "ch",
            0b00000110 => return "dh",
            0b00000111 => return "bh",
            else => return "fl",
        }
    } else {
        switch (masked) {
            0b00000000 => return "ax",
            0b00000001 => return "cx",
            0b00000010 => return "dx",
            0b00000011 => return "bx",
            0b00000100 => return "sp",
            0b00000101 => return "bp",
            0b00000110 => return "si",
            0b00000111 => return "di",
            else => return "fl",
        }
    }
    return "fl";
}

pub fn dirAddr(buf: *[4096]u8, index: *const u64, std_out: *std.Io.Writer) !void {
    const value = std.mem.readInt(u16, buf[(index.* + 2)..][0..2], .little);
    try std_out.print("[{d}]", .{value});
}

pub fn setR3(buf: *[4096]u8, index: *const u64, std_out: *std.Io.Writer, mem_mode: bool) !void {
    
    if (mem_mode == false){
        const val = buf[index.*];
        if (val == 0) {
            try std_out.print("]", .{});
        } else {
            const intVal: i8 = @bitCast(val);
            try std_out.print("+ {}]", .{intVal});
            // try std_out.print("locStr: {s}\n", .{locStr});
        }
    }
    else{
        const val = ((@as(u16, buf[index.* + 3]) << 8) | @as(u16, buf[index.* + 2])); 
        if (val == 0) {
            try std_out.print("]", .{});
        } else {
            const intVal: i16 = @bitCast(val);
            try std_out.print("+ {}]", .{intVal});
            // try std_out.print("locStr: {s}\n", .{locStr});
        }
    }
    return;
}


pub fn mov_mem_to_acc(buf: *[4096]u8, index: u64, std_out: *std.Io.Writer) !u64 {

    const value = std.mem.readInt(u16, buf[(index + 1)..][0..2], .little);

    try std_out.print("mov ax, [{d}]\n", .{value});

    return 0;
}

pub fn mov_acc_to_mem(buf: *[4096]u8, index: u64, std_out: *std.Io.Writer) !u64 {
    const value = std.mem.readInt(u16, buf[(index + 1)..][0..2], .little);
    try std_out.print("mov {d}, ax\n", .{value});

    return 0;
}

pub fn mov_reg_mem_to_reg(buf: *[4096]u8, index: u64, std_out: *std.Io.Writer) !u64 {
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

    try std_out.print("mov ", .{});

    switch (mem_mode) {
        .reg => {
            if (d_bit == .src_reg){
                try std_out.print("{s}, ",.{regAss2((buf.*[index + 1] & 0b00111000) >> 3, width)});
            }

            if (width == .eight_bit) {
                switch ((buf.*[index + 1] & 0b00000111)) {
                    0b00000000 => try std_out.print( "al", .{}),
                    0b00000001 => try std_out.print( "cl", .{}),
                    0b00000010 => try std_out.print( "dl", .{}),
                    0b00000011 => try std_out.print( "bl", .{}),
                    0b00000100 => try std_out.print( "ah", .{}),
                    0b00000101 => try std_out.print( "ch", .{}),
                    0b00000110 => try std_out.print( "dh", .{}),
                    0b00000111 => try std_out.print( "bh", .{}),
                    else => try std_out.print( "fl", .{}),                }
            } else {
                switch ((buf.*[index + 1] & 0b00000111)) {
                    0b00000000 => try std_out.print("ax", .{}),
                    0b00000001 => try std_out.print("cx", .{}),
                    0b00000010 => try std_out.print("dx", .{}),
                    0b00000011 => try std_out.print("bx", .{}),
                    0b00000100 => try std_out.print("sp", .{}),
                    0b00000101 => try std_out.print("bp", .{}),
                    0b00000110 => try std_out.print("si", .{}),
                    0b00000111 => try std_out.print("di", .{}),
                    else => try std_out.print("fl", .{}),
                }
            }
            
            if (d_bit == .des_reg){
                try std_out.print(", {s}",.{regAss2((buf.*[index + 1] & 0b00111000) >> 3, width)});
            }
        },
        .mem0 => {
            if (d_bit == .src_reg){
                try std_out.print("{s} ,",.{regAss2(regBits, width)});
            }

            switch (rmBits) {
                0b00000000 => try std_out.print("[bx + si]", .{}),
                0b00000001 => try std_out.print("[bx + di]", .{}),
                0b00000010 => try std_out.print("[bp + si]", .{}),
                0b00000011 => try std_out.print("[bp + di]", .{}),
                0b00000100 => try std_out.print("[si]", .{}),
                0b00000101 => try std_out.print("[di]", .{}),
                0b00000110 => try dirAddr( buf, &index, std_out),
                0b00000111 => try std_out.print("[bx]", .{}),
                else => try std_out.print("fl", .{}),            }
            if (d_bit == .des_reg){
                try std_out.print(", {s}",.{regAss2(regBits, width)});
            }
        },

        .mem8 => {
            // try std_out.print("mov_reg_mem_to_reg mode mem8\n", .{});
            // try std_out.print("b {b}, b1 {b}, b2 {b}, b3 {b}\n", .{ buf[index], buf[index + 1], buf[index + 2], buf[index + 3] });
            if (d_bit == .src_reg){
                try std_out.print("{s}, ",.{regAss2(regBits, width)});
            }

            try switch (rmBits) {
                0b00000000 => std_out.print("[bx + si ", .{}),
                0b00000001 => std_out.print("[bx + di ", .{}),
                0b00000010 => std_out.print("[bp + si ", .{}),
                0b00000011 => std_out.print("[bp + di ", .{}),
                0b00000100 => std_out.print("[si      ", .{}),
                0b00000101 => std_out.print("[di      ", .{}),
                0b00000110 => std_out.print("[bp      ", .{}),
                0b00000111 => std_out.print("[bx      ", .{}),
                else => std_out.print("fl       ", .{}),
            };

            try setR3(buf, &(index + 2), std_out, false);

            if (d_bit == .des_reg){
                try std_out.print(", {s}",.{regAss2(regBits, width)});
            }
        },

        .mem16 => {
            // try std_out.print("mov_reg_mem_to_reg mode mem16\n", .{});
            if (d_bit == .src_reg){
                try std_out.print("{s}, ",.{regAss2(regBits, width)});
            }
            try switch (rmBits) {
                0b00000000 => std_out.print("[bx + si ", .{}),
                0b00000001 => std_out.print("[bx + di ", .{}),
                0b00000010 => std_out.print("[bp + si ", .{}),
                0b00000011 => std_out.print("[bp + di ", .{}),
                0b00000100 => std_out.print("[si      ", .{}),
                0b00000101 => std_out.print("[di      ", .{}),
                0b00000110 => std_out.print("[bp      ", .{}),
                0b00000111 => std_out.print("[bx      ", .{}),
                else => std_out.print("fl       ", .{}),
            };

            try setR3(buf, &(index + 2), std_out, false);
            if (d_bit == .des_reg){
                try std_out.print(", {s}",.{regAss2(regBits, width)});
            }

        },
        else => {
            try std_out.print("mov_reg_mem_to_reg mode fail\n", .{});
        },
    }

    try std_out.print("\n",.{});

        if (mem_mode == .mem0 and rmBits == 0b00000110) {
        return 2;
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

// pub fn mov_imm_to_reg_mem(buf: *[4096]u8, index: u64, std_out: *std.Io.Writer) !u64 {
//     const Mode_reg_mem_to_reg = enum { mem0, mem8, mem16, reg, fail };
//     const mem_mode = switch (buf.*[index + 1] & 0b11000000) {
//         0b00000000 => Mode_reg_mem_to_reg.mem0,
//         0b01000000 => Mode_reg_mem_to_reg.mem8,
//         0b10000000 => Mode_reg_mem_to_reg.mem16,
//         0b11000000 => Mode_reg_mem_to_reg.reg,
//         else => Mode_reg_mem_to_reg.fail,
//     };
//
//     const rmBits = buf.*[index + 1] & 0b00000111;
//
//     var r1 = "[xx + xx]";
//     var sliceLenR1: u64 = 9;
//     var r2 = "[xx + xx] ";
//     var sliceLenR2: u64 = 10;
//     var r3: [8:0]u8 = undefined;
//     var sliceLenR3: u64 = 9;
//     var r4: [8:0]u8 = undefined;
//     var sliceLenR4: u64 = 9;
//
//     const wMask = (buf[index] & 0b00000001);
//     const width = switch (wMask) {
//         0b00000000 => WidthMode.eight_bit,
//         else => WidthMode.sixT_bit,
//     };
//
//     switch (mem_mode) {
//         .reg => try std_out.print(": mov_imm_to_reg_mem mode reg :", .{}),
//         .mem0 => {
//             // try std_out.print(": mem0 :", .{});
//
//             sliceLenR2 = 0;
//             sliceLenR4 = 0;
//             r1 = switch (rmBits) {
//                 0b00000000 => sliceAndRet("[bx + si]", &sliceLenR1),
//                 0b00000001 => sliceAndRet("[bx + di]", &sliceLenR1),
//                 0b00000010 => sliceAndRet("[bp + si]", &sliceLenR1),
//                 0b00000011 => sliceAndRet("[bp + di]", &sliceLenR1),
//                 0b00000100 => sliceAndRet("[si]     ", &sliceLenR1),
//                 0b00000101 => sliceAndRet("[di]     ", &sliceLenR1),
//                 0b00000110 => sliceAndRet("[bp]     ", &sliceLenR1),
//                 0b00000111 => sliceAndRet("[bx]     ", &sliceLenR1),
//                 else => sliceAndRet("fl       ", &sliceLenR1),
//             };
//
//             if (width == .eight_bit) {
//                 const locstr = try std.fmt.bufPrint(&r3, " ,byte {d}", .{buf.*[index + 2]});
//                 sliceLenR3 = locstr.len;
//             } else {
//                 // untested
//                 const locstr = try std.fmt.bufPrint(&r3, " ,byte {d}", .{(@as(u16, buf[index + 3]) << 8) | @as(u16, buf[index + 2])});
//                 sliceLenR3 = locstr.len;
//             }
//         },
//         .mem8 => try std_out.print(": mov_imm_to_reg_mem mode mem8 :", .{}),
//         .mem16 => {
//             sliceLenR2 = 0;
//             r1 = switch (rmBits) {
//                 0b00000000 => sliceAndRet("[bx + si ", &sliceLenR1),
//                 0b00000001 => sliceAndRet("[bx + di ", &sliceLenR1),
//                 0b00000010 => sliceAndRet("[bp + si ", &sliceLenR1),
//                 0b00000011 => sliceAndRet("[bp + di ", &sliceLenR1),
//                 0b00000100 => sliceAndRet("[si      ", &sliceLenR1),
//                 0b00000101 => sliceAndRet("[di      ", &sliceLenR1),
//                 0b00000110 => sliceAndRet("[bp      ", &sliceLenR1),
//                 0b00000111 => sliceAndRet("[bx      ", &sliceLenR1),
//                 else => sliceAndRet("fl       ", &sliceLenR1),
//             };
//
//             if (width == .eight_bit) {
//                 //untested
//                 var locstr = try std.fmt.bufPrint(&r3, "+ {d}], ", .{buf.*[index + 2]});
//                 sliceLenR3 = locstr.len;
//                 locstr = try std.fmt.bufPrint(&r4, "byte {d}", .{buf.*[index + 4]});
//                 sliceLenR4 = locstr.len;
//             } else {
//                 // untested
//                 var locstr = try std.fmt.bufPrint(&r3, "+ {d}], ", .{(@as(u16, buf[index + 3]) << 8) | @as(u16, buf[index + 2])});
//                 sliceLenR3 = locstr.len;
//                 locstr = try std.fmt.bufPrint(&r4, "word {d}", .{(@as(u16, buf[index + 5]) << 8) | @as(u16, buf[index + 4])});
//                 sliceLenR4 = locstr.len;
//             }
//         },
//         .fail => try std_out.print(": mov_imm_to_reg_mem mode fail :", .{}),
//     }
//
//     try std_out.print("mov {s}{s}{s}{s}\n", .{ r1[0..sliceLenR1], r2[0..sliceLenR2], r3[0..sliceLenR3], r4[0..sliceLenR4] });
//
//     if (mem_mode == .mem16) {
//         return 3;
//     }
//     if (width == .sixT_bit) {
//         return 1;
//     }
//     return 0;
// }
//
// pub fn mov_imm_to_reg(buf: *[4096]u8, index: u64, std_out: *std.Io.Writer) u64 {
//     if (buf.*[index] & 0b00001000 == 0b00001000) {
//         const regStr = switch (buf.*[index] & 0b00000111) {
//             0b00000000 => "ax",
//             0b00000001 => "cx",
//             0b00000010 => "dx",
//             0b00000011 => "bx",
//             0b00000100 => "sp",
//             0b00000101 => "bp",
//             0b00000110 => "si",
//             0b00000111 => "di",
//             else => "fl",
//         };
//
//         try std_out.print("mov {s}, {d}\n", .{ regStr, std.mem.readInt(u16, @ptrCast(buf[index + 1 .. index + 2]), .native) });
//
//         return 1;
//     }
//
//     const regStr = switch (buf.*[index] & 0b00000111) {
//         0b00000000 => "al",
//         0b00000001 => "cl",
//         0b00000010 => "dl",
//         0b00000011 => "bl",
//         0b00000100 => "ah",
//         0b00000101 => "ch",
//         0b00000110 => "dh",
//         0b00000111 => "bh",
//         else => "fl",
//     };
//
//     try std_out.print("mov {s}, {d}\n", .{ regStr, buf.*[index + 1] });
//     return 0;
// }
//
pub fn main(init: std.process.Init) !void {
    // Prints to stderr, unbuffered, ignoring potential errors.
    //try std_out.print("All your {s} are belong to us.\n", .{"codebase"});

    //
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len < 2) {
        std.debug.print("Usage: program <file>\n", .{});
        return;
    }

    const io = std.Io.Threaded.global_single_threaded.io();

    var std_io_buffer: [4096]u8 = undefined;
    var std_io_writer= std.Io.File.stdout().writer(io, &std_io_buffer);
    const std_out = &std_io_writer.interface;

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
    //     try std_out.print("{b}", .{buf[index]});
    //     try std_out.print("{b}", .{buf[index + 1]});
    //     try std_out.print("\n", .{});
    //     index += 2;
    // }
    // index = 0;

    try std_out.print("bits 16 \n", .{});

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

        switch (instruction) {
            // .mov_imm_to_reg_mem => iter += try mov_imm_to_reg_mem(&buf, index),
            .mov_reg_mem_to_reg => iter += try mov_reg_mem_to_reg(&buf, index, std_out),
            // .mov_imm_to_reg => iter += mov_imm_to_reg(&buf, index),
            .mov_mem_to_acc => iter += try mov_mem_to_acc(&buf, index, std_out),
            .mov_acc_to_mem => iter += try mov_acc_to_mem(&buf, index, std_out),
            // .mov_reg_mem_to_segreg => try std_out.print("mov_reg_mem_to_segreg\n", .{}),
            // .mov_segreg_toreg_mem => try std_out.print("mov_segreg_toreg_mem\n", .{}),
            else => try std_out.print("fail {} {b}\n", .{ instruction, buf[index] }),
        }

        index += iter;
    }
    
    try std_out.flush();
}
