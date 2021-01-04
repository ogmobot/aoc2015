const std = @import("std");
const print = std.debug.warn;
const json = std.json;
const mem = std.mem;

const input = @embedFile("input12.json");

fn sum_numbers_json(tree_root: json.Value, forbid_red: bool) i64 {
    switch (tree_root) {
        .Null, .Bool => return 0,
        .Integer => |int| return int,
        .Float => return 0,
        .String => return 0,
        .Array => |arr| {
            var total: i64 = 0;
            for (arr.items) |element| {
                total += sum_numbers_json(element, forbid_red);
            }
            return total;
        },
        .Object => {
            var total: i64 = 0;
            var iterator = tree_root.Object.iterator();
            while (iterator.next()) |entry| {
                if (forbid_red) {
                    switch (entry.value) {
                        .String => |str| {
                            if (mem.eql(u8, str, "red")) return 0;
                        },
                        else => {},
                    }
                }
                total += sum_numbers_json(entry.value, forbid_red);
            }
            return total;
        },
        else => return 0,
    }
}

pub fn main() void {
    const allocator = std.heap.page_allocator;
    var parser = std.json.Parser.init(allocator, false);
    var tree: json.ValueTree = parser.parse(input) catch unreachable;
    // part 1
    print("{}\n", .{sum_numbers_json(tree.root, false)});
    // part 2
    print("{}\n", .{sum_numbers_json(tree.root, true)});
}
