const print = @import("std").debug.warn;
const input = @embedFile("input01.txt");

fn count_brackets(str: []const u8) i32 {
    // ( => +1
    // ) => -1
    var total: i32 = 0;
    for (str) |ch| {
        if (ch == '(') {
            total += 1;
        } else if (ch == ')') {
            total -= 1;
        }
    }
    return total;
}

fn find_basement_bracket(str: []const u8) usize {
    // returns the first index at which the total becomes negative, +1
    var total: i32 = 0;
    for (str) |ch, i| {
        if (ch == '(') {
            total += 1;
        } else if (ch == ')') {
            total -= 1;
        }
        if (total < 0) {
            return i + 1;
        }
    }
    return 0;
}

pub fn main() !void {
    print("{}\n{}\n", .{
        // part 1
        count_brackets(input),
        // part 2
        find_basement_bracket(input),
        });
}
