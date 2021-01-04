const std = @import("std");
const print = std.debug.warn;
const mem = std.mem;
const tokenize = mem.tokenize;

const input = @embedFile("input18.txt");
const grid_size: usize = 100;
const grid_type = u1;

//literally just Conway's Game of Life.
// . . . . .
// . # # # .
// . # . . .
// . . # . .
// . . . . .

// Let's use... a fixed-size array.

fn count_neighbours(universe: [grid_size][grid_size]grid_type, row: usize, col: usize) u8 {
    var delta_r: i8 = -1;
    var delta_c: i8 = undefined;
    var total: u8 = 0;
    while (delta_r <= 1) {
        if ((delta_r == -1 and row == 0) or (delta_r == 1 and row + 1 == grid_size)) {
            // skip this row
        } else {
            delta_c = -1;
            while (delta_c <= 1) {
                if ((delta_c == -1 and col == 0) or (delta_c == 1 and col + 1 == grid_size) or (delta_c == 0 and delta_r == 0)) {
                    // skip this cell
                } else {
                    total += universe[@intCast(usize, @intCast(i64, row) + delta_r)][@intCast(usize, @intCast(i64, col) + delta_c)];
                }
                delta_c += 1;
            }
        }
        delta_r += 1;
    }
    return total;
}

fn create_universe(universe: *[grid_size][grid_size]grid_type, text: []const u8) void {
    // populates a universe, discarding any existing data in `universe`
    var lines = tokenize(text, "\n");
    var line_index: usize = 0;
    while (lines.next()) |line| {
        if (line_index >= grid_size) continue; // should never happen
        for (line) |ch, i| {
            universe[line_index][i] = if (ch == '#') 1 else 0;
        }
        line_index += 1;
    }
}

fn update_universe(universe: *[grid_size][grid_size]grid_type) void {
    // destroys existing state of universe
    var new_universe: [grid_size][grid_size]grid_type = undefined;

    for (universe.*[0..]) |row, ri| {
        for (row[0..]) |cell, ci| {
            const num_neighbours = count_neighbours(universe.*, ri, ci);
            if (num_neighbours == 3 or (cell == 1 and num_neighbours == 2)) {
                new_universe[ri][ci] = 1;
            } else {
                new_universe[ri][ci] = 0;
            }
        }
    }
    for (new_universe[0..]) |row, ri| {
        for (row[0..]) |cell, ci| {
            universe[ri][ci] = cell;
        }
    }
}

fn census(universe: [grid_size][grid_size]grid_type) u64 {
    var total: u64 = 0;
    for (universe[0..]) |row| {
        for (row[0..]) |cell| {
            total += cell;
        }
    }
    return total;
}

pub fn main() void {
    var universe: [100][100]grid_type = undefined;
    // part 1
    create_universe(&universe, input);
    var time_index: u32 = 0;
    while (time_index < 100) {
        update_universe(&universe);
        time_index += 1;
    }
    print("{}\n", .{census(universe)});
    // part 2
    create_universe(&universe, input);
    time_index = 0;
    while (time_index < 100) {
        update_universe(&universe);
        universe[0][0] = 1;
        universe[0][grid_size - 1] = 1;
        universe[grid_size - 1][0] = 1;
        universe[grid_size - 1][grid_size - 1] = 1;
        time_index += 1;
    }
    print("{}\n", .{census(universe)});
}
