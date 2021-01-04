const std = @import("std");
const print = std.debug.warn;
const fmt = std.fmt;
const mem = std.mem;
const tokenize = mem.tokenize;

const input = @embedFile("input17.txt");
const total_nog: u8 = 150;

fn ways_to_fill(volume: u8, containers: *std.ArrayList(u8), start_index: usize, limit: usize) u32 {
    // using at most `limit` containers
    if (limit == 0) return 0;

    var total: u32 = 0;
    for (containers.*.items) |container, i| {
        if (i < start_index) {
            continue;
        } else if (container == volume) {
            total += 1;
        } else if (container < volume) {
            total += ways_to_fill(volume - container, containers, i + 1, limit - 1);
        }
    }
    return total;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var containers = std.ArrayList(u8).init(allocator);
    defer containers.deinit();

    var lines = mem.tokenize(input, "\n");
    while (lines.next()) |line| {
        try containers.append(fmt.parseUnsigned(u8, line, 10) catch 0);
    }
    // part 1
    print("{}\n", .{ways_to_fill(total_nog, &containers, 0, containers.items.len)});
    // part 2
    var limit: usize = 0;
    while (ways_to_fill(total_nog, &containers, 0, limit) == 0) {
        limit += 1;
    }
    print("{}\n", .{ways_to_fill(total_nog, &containers, 0, limit)});
}
