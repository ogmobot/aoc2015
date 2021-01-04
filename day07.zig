const std = @import("std");
const print = std.debug.warn;
const mem = std.mem;
const tokenize = mem.tokenize;
const fmt = std.fmt;

const input = @embedFile("input07.txt");

const Operation = enum {
    OR,
    AND,
    NOT,
    LSHIFT,
    RSHIFT,
    STORE, // e.g. 1234 -> a
};

const Instruction = struct {
    a: ?[]const u8,
    b: ?[]const u8, // should be null for NOT or STORE
    op: Operation,
    target: ?[]const u8,
};

fn evaluate(inst: Instruction, table: std.StringHashMap(u16)) ?u16 {
    var a_val: ?u16 = null;
    var b_val: ?u16 = null;
    if (inst.a) |a| {
        if ('0' <= a[0] and a[0] <= '9') {
            // a is numeric
            a_val = fmt.parseUnsigned(u16, a, 10) catch 0;
        } else {
            a_val = table.getValue(a);
        }
    }
    if (inst.b) |b| {
        if ('0' <= b[0] and b[0] <= '9') {
            // b is numeric
            b_val = fmt.parseUnsigned(u16, b, 10) catch 0;
        } else {
            b_val = table.getValue(b);
        }
    }
    switch (inst.op) {
        .OR => if (a_val) |a| if (b_val) |b| return a | b,
        .AND => if (a_val) |a| if (b_val) |b| return a & b,
        .NOT => if (a_val) |a| return ~a,
        .LSHIFT => if (a_val) |a| if (b_val) |b| return a << @intCast(u4, b),
        .RSHIFT => if (a_val) |a| if (b_val) |b| return a >> @intCast(u4, b),
        .STORE => if (a_val) |a| return a_val,
    }
    return null;
}

fn line_to_instruction(line: []const u8) Instruction {
    var result: Instruction = undefined;
    var words = tokenize(line, " ");
    var word_index: u8 = 0;
    while (words.next()) |word| {
        switch (word_index) {
            0 => {
                if (mem.eql(u8, word, "NOT")) {
                    result.op = .NOT;
                    result.a = words.next();
                    _ = words.next(); // discard "->"
                    result.target = words.next();
                    result.b = null;
                    // end loop
                } else {
                    result.a = word;
                    word_index += 1;
                }
            },
            1 => {
                // Can't be "NOT"
                if (mem.eql(u8, word, "->")) {
                    result.op = .STORE;
                    result.b = null;
                    result.target = words.next();
                    // end loop
                } else if (mem.eql(u8, word, "OR")) {
                    result.op = .OR;
                } else if (mem.eql(u8, word, "AND")) {
                    result.op = .AND;
                } else if (mem.eql(u8, word, "LSHIFT")) {
                    result.op = .LSHIFT;
                } else if (mem.eql(u8, word, "RSHIFT")) {
                    result.op = .RSHIFT;
                }
                word_index += 1;
            },
            2 => {
                result.b = word;
                // discard  "->"
                _ = words.next();
                word_index += 1;
            },
            3 => {
                result.target = word;
            },
            else => {},
        }
    }
    return result;
}

fn make_wires(instructions_ptr: *std.ArrayList(Instruction), table_ptr: *std.StringHashMap(u16)) !void {
    while (table_ptr.*.count() < instructions_ptr.*.items.len) {
        for (instructions_ptr.*.items) |inst| {
            if (inst.target) |target| {
                if (!table_ptr.*.contains(target)) {
                    // we haven't successfully carried out this instruction yet
                    if (evaluate(inst, table_ptr.*)) |result| {
                        _ = try table_ptr.*.put(target, result);
                    }
                }
            }
        }
    }
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var instructions = std.ArrayList(Instruction).init(allocator);
    defer instructions.deinit();
    var table_1 = std.StringHashMap(u16).init(allocator);
    defer table_1.deinit();
    var table_2 = std.StringHashMap(u16).init(allocator);
    defer table_2.deinit();

    // part 1
    var lines = tokenize(input, "\n");
    var inst: Instruction = undefined;
    while (lines.next()) |line| {
        inst = line_to_instruction(line);
        try instructions.append(inst);
    }
    _ = try make_wires(&instructions, &table_1);
    //var table_iterator = table.iterator();
    //while (table_iterator.next()) |kv| { print("{}\n", .{kv}); }
    var final_a: ?u16 = table_1.getValue("a");
    print("{}\n", .{final_a});

    // part 2
    var a_string = [_]u8{0} ** 8;
    _ = try fmt.bufPrint(&a_string, "{: >8}", .{final_a});

    for (instructions.items) |item, index| {
        if (item.target) |var_name| {
            if (mem.eql(u8, var_name, "b")) {
                // replace this instruction with b -> final_a
                instructions.items[index].a = fmt.trim(a_string[0..]);
                break;
            }
        }
    }
    _ = try make_wires(&instructions, &table_2);
    print("{}\n", .{table_2.getValue("a")});
}
