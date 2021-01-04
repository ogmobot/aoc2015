const std = @import("std");
const print = std.debug.warn;
const fmt = std.fmt;
const mem = std.mem;
const tokenize = mem.tokenize;

const input = @embedFile("input24.txt");

fn append_text_to_list(text: []const u8, list: *std.ArrayList(u16)) !void {
    var lines = tokenize(text, "\n");
    while (lines.next()) |line| {
        const value = fmt.parseUnsigned(u16, line, 10) catch 0;
        try list.*.append(value);
    }
}

fn sum_list(list: []u16) u16 {
    var result: u16 = 0;
    for (list) |n| {
        result += n;
    }
    return result; // 1548 for the given input. (1548 / 3 == 516)
}

fn populate_sums(matrix: *std.ArrayList(std.ArrayList(?bool)), nums: []u16) void {
    for (nums) |num, i| {
        for (matrix.*.items[i].items) |_, j| {
            if (j == 0) {
                matrix.*.items[i].items[j] = true;
                // Trivial case (sum of empty set == 0)
            } else if (i == 0) {
                if (num == j) {
                    matrix.*.items[i].items[j] = true;
                } else {
                    matrix.*.items[i].items[j] = false;
                }
            } else {
                // i > 0 and j > 0
                if (num > j) {
                    matrix.*.items[i].items[j] = matrix.*.items[i - 1].items[j].?;
                    // `num` is greater than the target sum `j`, so it can't be a part of the subset.
                    // This cell is true iff the sum can be completed without `num`'s help.
                } else {
                    matrix.*.items[i].items[j] = (matrix.*.items[i - 1].items[j].? or matrix.*.items[i - 1].items[j - num].?);
                    // (This is safe because j >= num.)
                    // This cell is true if the sum can be complted without `num`'s help,
                    // or if (j - num) can be completed without `num`'s help.
                }
            }
        }
    }
}

fn trace_all_paths(i: usize, sum: u16, nums: []u16, matrix: std.ArrayList(std.ArrayList(?bool)), path: *std.ArrayList(u16), paths: *std.ArrayList(std.ArrayList(u16)), allocator: *mem.Allocator) !void {
    // From trial and error, least items needed is 6.
    if (path.items.len > 6) return;
    // If we hit i == 0, this path works iff we can make the sum with only the first element.
    if (i == 0 and sum > 0 and matrix.items[0].items[sum].?) {
        try path.*.append(nums[i]);
        // print current path
        try paths.*.append(path.*);
        return;
    }
    // If we hit sum == 0, this path works.
    if (i == 0 and sum == 0) {
        // print current path
        try paths.*.append(path.*);
        return;
    }
    // i > 0
    // If we can ignore the current element...
    if (matrix.items[i - 1].items[sum].?) {
        // Find paths that result from ignoring this element.
        // Make a copy of this list first.
        var path_copy = std.ArrayList(u16).init(allocator); // potentially leaky
        for (path.items) |p| {
            try path_copy.append(p);
        }
        _ = trace_all_paths(i - 1, sum, nums, matrix, &path_copy, paths, allocator) catch unreachable;
    }
    // If we can include this element...
    if (sum >= nums[i] and matrix.items[i - 1].items[sum - nums[i]].?) {
        // push nums[i] to path
        try path.*.append(nums[i]);
        _ = trace_all_paths(i - 1, sum - nums[i], nums, matrix, path, paths, allocator) catch unreachable;
    }
}

pub fn main() !void {
    var allocator = std.heap.page_allocator;
    var package_list = std.ArrayList(u16).init(allocator);
    defer package_list.deinit();

    try append_text_to_list(input, &package_list);
    const target_sum = sum_list(package_list.items) / 3;

    // create a boolean matrix M[][] such that M[i][j] indicates
    // whether there is a subset of elements in list[0..i] with a sum of j.
    var can_sum_to = std.ArrayList(std.ArrayList(?bool)).init(allocator);
    defer can_sum_to.deinit();
    for (package_list.items) |_| {
        var row = std.ArrayList(?bool).init(allocator); // potentially leaky
        var i: u16 = 0;
        while (i <= target_sum) {
            try row.append(null);
            i += 1;
        }
        try can_sum_to.append(row);
    }

    _ = populate_sums(&can_sum_to, package_list.items);

    var paths = std.ArrayList(std.ArrayList(u16)).init(allocator);
    defer paths.deinit();

    var path = std.ArrayList(u16).init(allocator); // potentially leaky

    try trace_all_paths(package_list.items.len - 1, target_sum, package_list.items, can_sum_to, &path, &paths, allocator);

    var best_length: u16 = 0xFFFF;
    var best_product: u64 = 0xFFFFFFFFFFFFFFFF;
    for (paths.items) |p| {
        var product: u64 = 1;
        for (p.items) |n| {
            product *= n;
        }
        if (p.items.len < best_length or (p.items.len == best_length and product < best_product)) {
            best_product = product;
            best_length = @intCast(u16, p.items.len);
            //for (p.items) |item| {
            //print("{} ", .{item});
            //}
            //print("\n", .{});
        }
    }
    print("Part 1: {}\n", .{best_product});
    // This assumes (naively) that the remaining items can be divided into two parts of equal sums. But it works.

    // part 2
    const target_sum_2 = sum_list(package_list.items) / 4;
    var paths_2 = std.ArrayList(std.ArrayList(u16)).init(allocator);
    defer paths_2.deinit();

    var path_2 = std.ArrayList(u16).init(allocator); // potentially leaky

    try trace_all_paths(package_list.items.len - 1, target_sum_2, package_list.items, can_sum_to, &path_2, &paths_2, allocator);

    best_length = 0xFFFF;
    best_product = 0xFFFFFFFFFFFFFFFF;
    for (paths_2.items) |p| {
        var product: u64 = 1;
        for (p.items) |n| {
            product *= n;
        }
        if (p.items.len < best_length or (p.items.len == best_length and product < best_product)) {
            best_product = product;
            best_length = @intCast(u16, p.items.len);
            //for (p.items) |item| {
            //print("{} ", .{item});
            //}
            //print("\n", .{});
        }
    }
    print("Part 2: {}\n", .{best_product});
    // This assumes (naively) that the remaining items can be divided into three parts of equal sums. BUT IT WORKS TOO.
}
