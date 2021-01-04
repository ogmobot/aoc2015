const std = @import("std");
const print = std.debug.warn;

const input = @embedFile("input03.txt");

const Location = struct { x: i32, y: i32 };

fn update_location(current: Location, arrow: u8) Location {
    return switch (arrow) {
        '^' => .{ .x = current.x, .y = current.y - 1 },
        'v' => .{ .x = current.x, .y = current.y + 1 },
        '<' => .{ .x = current.x - 1, .y = current.y },
        '>' => .{ .x = current.x + 1, .y = current.y },
        else => current,
    };
}

fn count_presents(directions: []const u8, num_santas: u32) !usize {
    const allocator = std.heap.page_allocator;
    //var buffer: [1024 * 1024]u8 = undefined;
    //var fba = std.heap.FixedBufferAllocator.init(&buffer);
    //var allocator = &fba.allocator;

    var grid = std.AutoHashMap(Location, void).init(allocator);
    defer grid.deinit();

    var santa_index: u32 = 0;

    //var location: [num_santas]Location = .{ .x = 0, .y = 0 };
    var locations = std.ArrayList(Location).init(allocator);
    defer locations.deinit();

    while (santa_index < num_santas) {
        try locations.append(.{ .x = 0, .y = 0 });
        santa_index += 1;
    }
    _ = try grid.put(locations.items[0], .{});

    santa_index = 0;
    for (directions) |ch| {
        locations.items[santa_index] = update_location(locations.items[santa_index], ch);
        _ = try grid.put(locations.items[santa_index], .{});
        santa_index = (santa_index + 1) % num_santas;
    }
    return grid.count();
}

pub fn main() !void {
    print("{}\n{}\n", .{
        // part 1
        count_presents(input, 1),
        // part 2
        count_presents(input, 2),
    });
}
