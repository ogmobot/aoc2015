const std = @import("std");
const print = std.debug.warn;
const fmt = std.fmt;
const mem = std.mem;
const tokenize = mem.tokenize;

const input = @embedFile("input23.txt");

const Instruction = struct {
    word: enum { hlf, tpl, inc, jmp, jie, jio },
    r: enum { a, b },
    offset: i32, // max offset is not specified
};

const Computer = struct {
    instructions: std.ArrayList(Instruction),
    // registers
    a: u64 = 0,
    b: u64 = 0,
    // instruction pointer
    ip: usize = 0,
};

fn load_computer(computer: *Computer, text: []const u8) !void {
    var lines = tokenize(text, "\n");
    while (lines.next()) |line| {
        var instruction: Instruction = undefined;
        var tokens = tokenize(line, " ,+"); // '+' used only for positive ints
        if (tokens.next()) |word| {
            if (mem.eql(u8, word, "hlf")) {
                instruction.word = .hlf;
            } else if (mem.eql(u8, word, "tpl")) {
                instruction.word = .tpl;
            } else if (mem.eql(u8, word, "inc")) {
                instruction.word = .inc;
            } else if (mem.eql(u8, word, "jmp")) {
                instruction.word = .jmp;
            } else if (mem.eql(u8, word, "jie")) {
                instruction.word = .jie;
            } else if (mem.eql(u8, word, "jio")) {
                instruction.word = .jio;
            }
        }
        if (tokens.next()) |r| {
            // for jmp, this is offset, not r.
            if (instruction.word == .jmp) {
                instruction.offset = fmt.parseInt(i32, r, 10) catch unreachable;
            }
            if (r[0] == 'a') {
                instruction.r = .a;
            } else {
                instruction.r = .b;
            }
        }
        if (tokens.next()) |offset| {
            instruction.offset = fmt.parseInt(i32, offset, 10) catch unreachable;
        }
        try computer.*.instructions.append(instruction);
    }
}

fn step_computer(computer: *Computer) bool {
    // Returns false (halt) when attempting to execute an out-of-bounds instruction
    if (computer.*.ip < 0 or computer.*.ip >= computer.*.instructions.items.len) return false;
    const instruction = computer.*.instructions.items[computer.*.ip];
    const target: *u64 = if (instruction.r == .a) &(computer.*.a) else &(computer.*.b);
    computer.*.ip += 1;
    switch (instruction.word) {
        .hlf => target.* /= 2,
        .tpl => target.* *= 3,
        .inc => target.* += 1,
        .jmp => computer.*.ip = @intCast(usize, @intCast(i32, computer.*.ip) + instruction.offset - 1),

        .jie => {
            if (target.* % 2 == 0) computer.*.ip = @intCast(usize, @intCast(i32, computer.*.ip) + instruction.offset - 1);
        },
        .jio => {
            if (target.* == 1) computer.*.ip = @intCast(usize, @intCast(i32, computer.*.ip) + instruction.offset - 1);
        },
    }
    return true;
}

pub fn main() !void {
    var allocator = std.heap.page_allocator;
    var computer = Computer{ .instructions = std.ArrayList(Instruction).init(allocator) };
    defer computer.instructions.deinit();

    // part 1
    try load_computer(&computer, input);
    while (step_computer(&computer)) {}
    print("{}\n", .{computer.b});

    // part 2
    // manual reset
    computer.a = 1;
    computer.b = 0;
    computer.ip = 0;
    while (step_computer(&computer)) {}
    print("{}\n", .{computer.b});
}
