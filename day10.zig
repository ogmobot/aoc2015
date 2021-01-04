const std = @import("std");
const print = std.debug.warn;
const mem = std.mem;

// need approx. 5 MB to hold digits of 50th iteration
const input = "3113322113";

fn next_number(buffer: *std.ArrayList(u8), current: *std.ArrayList(u8)) !usize {
    // returns number of digits written to buffer
    var digit: u8 = '0';
    var count: u8 = '0'; // count is always 1 digit, so starting at '0' is okay
    var buffer_index: usize = 0;
    for (current.items) |ch| {
        if (ch != digit) { // arrived at new digit
            if (digit != '0') {
                _ = buffer.ensureCapacity(buffer_index + 4) catch unreachable;
                _ = buffer.expandToCapacity();
                buffer.items[buffer_index] = count;
                buffer.items[buffer_index + 1] = digit;
                buffer_index += 2;
            }
            count = '1';
            digit = ch;
            if (ch == 0) break;
        } else {
            count += 1;
        }
    }
    //print("end-of-next-number capacity={}\n", .{buffer.capacity});
    // Add terminator so next iteration knows when to stop.
    // (Can't use buffer.items.len because of expandToCapacity above)
    buffer.items[buffer_index] = 0;
    return buffer_index;
}

fn print_arr(arr: []const u8) void {
    for (arr) |elem| {
        if (elem == 0) break;
        print("{c}", .{elem});
    }
    print("\n", .{});
}

pub fn main() void {
    const allocator = std.heap.page_allocator;
    var current = std.ArrayList(u8).init(allocator);
    var buffer = std.ArrayList(u8).init(allocator);
    defer current.deinit();
    defer buffer.deinit();
    var size: usize = undefined;

    _ = current.ensureCapacity(input.len) catch unreachable;
    _ = current.expandToCapacity();
    mem.copy(u8, current.items, input); // copies null terminator from input

    // part 1
    var i: u8 = 0;
    while (i < 40) {
        //if (i < 10) print_arr(current.items);
        size = next_number(&buffer, &current) catch 0;
        //print("{}\n", .{size});
        _ = current.ensureCapacity(buffer.items.len) catch unreachable;
        _ = current.expandToCapacity();
        mem.copy(u8, current.items, buffer.items);
        i += 1;
    }
    print("{}\n", .{size});
    // part 2
    while (i < 50) {
        size = next_number(&buffer, &current) catch 0;
        _ = current.ensureCapacity(buffer.items.len) catch unreachable;
        _ = current.expandToCapacity();
        mem.copy(u8, current.items, buffer.items);
        i += 1;
    }
    print("{}\n", .{size});
}
