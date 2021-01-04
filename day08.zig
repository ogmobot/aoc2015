const std = @import("std");
const print = std.debug.warn;
const tokenize = std.mem.tokenize;
const fmt = std.fmt;

const input = @embedFile("input08.txt");

fn eval_string(buffer: []u8, raw_text: []const u8) usize {
    // "\x097b\\" => ab\
    // returns number of characters written to buffer
    var buffer_index: usize = 0;
    var raw_index: usize = 1;
    while (raw_index < raw_text.len - 1) {
        if (raw_text[raw_index] == '\\') {
            switch (raw_text[raw_index + 1]) {
                '\\', '\"' => {
                    buffer[buffer_index] = raw_text[raw_index + 1];
                    raw_index += 2;
                },
                'x' => {
                    buffer[buffer_index] = fmt.parseUnsigned(u8, raw_text[(raw_index + 2)..(raw_index + 4)], 16) catch 0;
                    raw_index += 4;
                },
                else => {
                    // panic!
                    // assume this is a literal '\'
                    buffer[buffer_index] = '\\';
                    raw_index += 1;
                },
            }
        } else {
            buffer[buffer_index] = raw_text[raw_index];
            raw_index += 1;
        }
        buffer_index += 1;
    }
    buffer[buffer_index] = 0;
    return buffer_index;
}

fn encode_string(buffer: []u8, raw_text: []const u8) usize {
    // returns number of characters written to buffer
    var buffer_index: usize = 1;
    var raw_index: usize = 0;
    buffer[0] = '\"';
    while (raw_index < raw_text.len) {
        switch (raw_text[raw_index]) {
            '\\', '\"' => {
                buffer[buffer_index] = '\\';
                buffer[buffer_index + 1] = raw_text[raw_index];
                buffer_index += 2;
            },
            else => {
                buffer[buffer_index] = raw_text[raw_index];
                buffer_index += 1;
            },
        }
        raw_index += 1;
    }
    buffer[buffer_index] = '\"';
    buffer_index += 1;
    buffer[buffer_index] = 0;
    return buffer_index;
}

pub fn main() void {
    var lines = tokenize(input, "\n");
    var buffer: [256]u8 = undefined;
    var raw_length: usize = 0;
    var eval_length: usize = 0;
    var encode_length: usize = 0;
    while (lines.next()) |line| {
        raw_length += line.len;
        // part 1
        eval_length += eval_string(&buffer, line);
        // part 2
        encode_length += encode_string(&buffer, line);
    }
    print("{}\n{}\n", .{ raw_length - eval_length, encode_length - raw_length });
}
