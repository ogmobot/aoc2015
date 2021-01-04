const std = @import("std");
const print = std.debug.warn;
const mem = std.mem;
const tokenize = mem.tokenize;
const fmt = std.fmt;

const input = @embedFile("input06.txt");

const light_size: u16 = 1000;

fn process_line(line: []const u8) [5]u16 {
    // extracts the mode of the line, plus four numbers from a line
    // "toggle 0,322 through 498,323" => {2, 0, 322, 498, 323}
    var result: [5]u16 = undefined;
    if (starts_with(line, "turn off")) {
        result[0] = 0;
    } else if (starts_with(line, "turn on")) {
        result[0] = 1;
    } else {
        result[0] = 2;
    }

    var result_index: usize = 0;
    var last_ch: u8 = line[0];
    for (line) |ch, line_index| {
        if (line_index == 0) continue;
        if (('0' <= ch and ch <= '9') and (!('0' <= last_ch and last_ch <= '9'))) {
            // this is the start of a number
            var end_index: usize = line_index;
            while (end_index < line.len and ('0' <= line[end_index] and line[end_index] <= '9')) {
                end_index += 1;
            }
            result[result_index + 1] = fmt.parseUnsigned(u16, line[line_index..end_index], 10) catch 0;
            result_index += 1;
        }
        last_ch = ch;
    }
    return result;
}

fn starts_with(long_string: []const u8, short_string: []const u8) bool {
    return mem.eql(u8, long_string[0..short_string.len], short_string);
}

fn do_bool_lights(lights: *[light_size][light_size]bool, line_vals: [5]u16) void {
    // 0: mode, 1: from_row, 2: from_col, 3: to_row, 4: to_col
    var row_index: u16 = line_vals[1];
    while (row_index <= line_vals[3]) {
        var col_index: u16 = line_vals[1];
        while (col_index <= line_vals[4]) {
            lights.*[row_index][col_index] = switch (line_vals[0]) {
                0, 1 => (line_vals[0] > 0),
                else => !(lights.*[row_index][col_index]),
            };
            col_index += 1;
        }
        row_index += 1;
    }
}

fn do_int_lights(lights: *[light_size][light_size]u16, line_vals: [5]u16) void {
    // 0: mode, 1: from_row, 2: from_col, 3: to_row, 4: to_col
    var row_index: u16 = line_vals[1];
    while (row_index <= line_vals[3]) {
        var col_index: u16 = line_vals[2];
        while (col_index <= line_vals[4]) {
            const current_value: u16 = lights.*[row_index][col_index];
            lights.*[row_index][col_index] = switch (line_vals[0]) {
                1, 2 => current_value + line_vals[0],
                else => if (current_value == 0) 0 else (current_value - 1),
            };
            col_index += 1;
        }
        row_index += 1;
    }
}

pub fn main() void {
    // TODO learn how to initialize memory...

    // part 1: boolean lights
    var lights_bool: [light_size][light_size]bool = undefined;
    for (lights_bool) |row, r| {
        for (row) |light, c| {
            lights_bool[r][c] = false;
        }
    }
    // part 2: integer lights
    var lights_int: [light_size][light_size]u16 = undefined;
    for (lights_int) |row, r| {
        for (row) |light, c| {
            lights_int[r][c] = 0;
        }
    }

    var lines = tokenize(input, "\n");
    while (lines.next()) |line| {
        var line_values: [5]u16 = process_line(line);
        do_bool_lights(&lights_bool, line_values);
        do_int_lights(&lights_int, line_values);
    }

    var totals = [_]u32{ 0, 0 };
    for (lights_bool) |row_bool, r| {
        for (row_bool) |light_bool, c| {
            if (lights_bool[r][c]) totals[0] += 1;
            totals[1] += lights_int[r][c];
        }
    }

    print("{}\n{}\n", .{ totals[0], totals[1] });
}
