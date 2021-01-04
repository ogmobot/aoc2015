const std = @import("std");
const print = std.debug.warn;
const tokenize = std.mem.tokenize;
const fmt = std.fmt;

const input = @embedFile("input02.txt");

fn min(arr: []const u32) u32 {
    var result: u32 = std.math.maxInt(u32);
    for (arr) |val| {
        if (val < result) {
            result = val;
        }
    }
    return result;
}

fn get_dimensions(line: []const u8) [3]u32 {
    var nums: [3]u32 = undefined;
    var parts = tokenize(line, "x");
    var index: usize = 0;
    while (parts.next()) |val| {
        nums[index] = fmt.parseUnsigned(u32, val, 10) catch 0;
        //print("{}\n", .{nums[index]});
        index += 1;
    }
    return nums;
}

fn get_wrapping_amount(dims: [3]u32) u32 {
    // line is e.g. "3x11x24"
    const surfaces = [_]u32{
        dims[0] * dims[1],
        dims[1] * dims[2],
        dims[2] * dims[0],
    };
    return 2 * (surfaces[0] + surfaces[1] + surfaces[2]) + min(surfaces[0..]);
}

fn get_ribbon_length(dims: [3]u32) u32 {
    const half_perimeters = [_]u32{
        dims[0] + dims[1],
        dims[1] + dims[2],
        dims[2] + dims[0],
    };
    return 2 * min(half_perimeters[0..]) + (dims[0] * dims[1] * dims[2]);
}

pub fn main() void {
    var lines = tokenize(input, "\n");
    var totals = [_]u32{ 0, 0 };
    var dims: [3]u32 = undefined;
    while (lines.next()) |line| {
        dims = get_dimensions(line);
        // part 1
        totals[0] += get_wrapping_amount(dims);
        // part 2
        totals[1] += get_ribbon_length(dims);
    }
    print("{}\n{}\n", .{ totals[0], totals[1] });
}
