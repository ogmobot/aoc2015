const std = @import("std");
const print = std.debug.warn;
const mem = std.mem;
const tokenize = mem.tokenize;
const fmt = std.fmt;

const input = @embedFile("input05.txt");

fn count_vowels(line: []const u8) u8 {
    var total: u8 = 0;
    for (line) |ch| {
        total = switch (ch) {
            'a', 'e', 'i', 'o', 'u' => total + 1,
            else => total,
        };
    }
    return total;
}

fn contains_double(line: []const u8) bool {
    for (line) |ch, index| {
        if (index + 2 > line.len) {
            return false;
        }
        if (ch == line[index + 1]) {
            return true;
        }
    }
    return false;
}

fn contains_substring(line: []const u8, sub: []const u8) bool {
    //inefficient for checking multiple substrings but w/e
    for (line) |ch, index| {
        if (index + sub.len > line.len) {
            return false;
        }
        if (mem.eql(u8, sub, line[index..(index + sub.len)])) {
            return true;
        }
    }
    return false;
}

fn contains_double_pair(line: []const u8) bool {
    for (line) |ch, index| {
        if (index + 2 > line.len) {
            return false;
        }
        if (contains_substring(line[(index + 2)..], line[index..(index + 2)])) {
            return true;
        }
    }
    return false;
}

fn contains_xyx(line: []const u8) bool {
    // returns true if there's a pair of letters with 1 other letter between
    for (line) |ch, index| {
        if (index + 2 >= line.len) {
            return false;
        }
        if (ch == line[index + 2]) {
            return true;
        }
    }
    return false;
}

pub fn main() void {
    var lines = tokenize(input, "\n");
    var totals = [_]u32{ 0, 0 };
    while (lines.next()) |line| {
        if ((count_vowels(line) >= 3) and contains_double(line) and !(contains_substring(line, "ab") or contains_substring(line, "cd") or contains_substring(line, "pq") or contains_substring(line, "xy"))) {
            totals[0] += 1;
        }
        if (contains_double_pair(line) and contains_xyx(line)) {
            totals[1] += 1;
        }
    }
    print("{}\n{}\n", .{ totals[0], totals[1] });
}
