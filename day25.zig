const std = @import("std");
const print = std.debug.warn;
const fmt = std.fmt;

const input = @embedFile("input25.txt");
const INITIAL_SEED: i32 = 20151125;

inline fn int_at_location(r: i32, c: i32) i32 {
    // Source: pen & paper. Trust me dude.
    // Gotta be i32 because of those (r-2) terms.
    return ((c * (c + 1)) + (r - 1) * ((2 * c) + r - 2)) >> 1;
}

inline fn rnd_next(seed: i32) i32 {
    return @intCast(i32, (@intCast(u64, seed) * 252533) % 33554393);
}

inline fn is_digit(ch: u8) bool {
    return ('0' <= ch and ch <= '9');
}

fn extract_numbers(text: []const u8) [2]i32 {
    // extracts two ints from a line of text
    var result = [_]i32{0} ** 2;
    var result_index: u8 = 0;
    for (text) |ch, i| {
        if (is_digit(ch) and (i == 0 or !is_digit(text[i - 1]))) {
            // Start of a number
            var end_index = i;
            while (end_index < text.len and is_digit(text[end_index])) {
                end_index += 1;
            }
            result[result_index] = fmt.parseInt(i32, text[i..end_index], 10) catch unreachable;
            result_index += 1;
        }
    }
    return result;
}

pub fn main() void {
    const location = extract_numbers(input);
    const num_cycles = int_at_location(location[0], location[1]);
    var num = INITIAL_SEED;
    var i: u32 = 0;
    while (i + 1 < num_cycles) {
        num = rnd_next(num);
        i += 1;
    }
    print("{}\n", .{num});
}
