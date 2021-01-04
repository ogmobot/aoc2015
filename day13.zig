const std = @import("std");
const print = std.debug.warn;
const fmt = std.fmt;
const mem = std.mem;
const tokenize = mem.tokenize;

const input = @embedFile("input13.txt");
const num_guests = 8;

const Permutations = struct {
    // must create an array of numbers 0 .. n-1
    // and an array of bools with the same length
    allocator: *mem.Allocator,
    values: []usize,
    dirs: []bool,
    untouched: bool,
    const Self = @This();

    fn init(allocator: *mem.Allocator, size: usize) Self {
        var result = Self{
            .allocator = allocator,
            .values = allocator.alloc(usize, size) catch &[_]usize{},
            .dirs = allocator.alloc(bool, size) catch &[_]bool{},
            .untouched = true,
        };
        var index: usize = 0;
        while (index < size) {
            result.values[index] = index;
            result.dirs[index] = false;
            index += 1;
        }
        return result;
    }

    fn deinit(self: *Permutations) void {
        self.allocator.free(self.values);
        self.allocator.free(self.dirs);
    }

    fn next(self: *Permutations) ?[]usize {
        if (self.untouched) {
            self.untouched = false;
            return self.values;
        }
        // find highest "mobile" integer
        var highest_mobile: ?usize = null; //index of highest "mobile" number
        for (self.values) |n, i| {
            if ((self.dirs[i] and i + 1 < self.values.len and n > self.values[i + 1]) or ((!self.dirs[i]) and i >= 1 and n > self.values[i - 1])) {
                if (highest_mobile) |h_mob| {
                    if (n > self.values[h_mob]) {
                        highest_mobile = i;
                    }
                } else {
                    highest_mobile = i;
                }
            }
        }
        if (highest_mobile) |h_mob| {
            const tmp_int: usize = self.values[h_mob];
            // swap the direction of each integer higher than that integer
            for (self.values) |n, i| {
                if (n > tmp_int) {
                    self.dirs[i] = !self.dirs[i];
                }
            }
            const tmp_bool: bool = self.dirs[h_mob];
            // swap that integer with the appropriate adjacent integer
            if (self.dirs[h_mob]) { // facing right
                self.dirs[h_mob] = self.dirs[h_mob + 1];
                self.values[h_mob] = self.values[h_mob + 1];
                self.dirs[h_mob + 1] = tmp_bool;
                self.values[h_mob + 1] = tmp_int;
            } else { // facing left
                self.dirs[h_mob] = self.dirs[h_mob - 1];
                self.values[h_mob] = self.values[h_mob - 1];
                self.dirs[h_mob - 1] = tmp_bool;
                self.values[h_mob - 1] = tmp_int;
            }
            return self.values;
        } else {
            return null;
        }
    }

    fn reset(self: *Permutations) void {
        for (self.values) |n, i| {
            self.values[i] = i;
            self.dirs = false;
        }
        self.untouched = true;
    }
};

fn populate_guest_names(guest_names: *[num_guests][]const u8, text: []const u8) !void {
    var name_index: u8 = 0;
    var lines = tokenize(text, "\n");
    while (lines.next()) |line| {
        var words = tokenize(line, " .");
        var word_index: u8 = 0;
        while (words.next()) |word| {
            if (word.len == 0) continue;
            if ('A' <= word[0] and word[0] <= 'Z') { // name
                // Is it already here?
                var seen: bool = false;
                for (guest_names[0..name_index]) |name| {
                    if (mem.eql(u8, name, word)) seen = true;
                }
                if (!seen) {
                    guest_names[name_index] = word;
                    name_index += 1;
                }
            }
            word_index += 1;
        }
    }
}

fn reverse_lookup(guest_names: [num_guests][]const u8, maybe_guest_name: ?[]const u8) ?usize {
    if (maybe_guest_name) |guest_name| {
        for (guest_names) |test_name, index| {
            if (mem.eql(u8, test_name, guest_name)) {
                return index;
            }
        }
    }
    return null;
}

fn populate_matrix(matrix: *[num_guests][num_guests]i32, guest_names: [num_guests][]const u8, text: []const u8) void {
    var lines = tokenize(text, "\n");
    while (lines.next()) |line| {
        var words = tokenize(line, " .");

        const guest_x = words.next();
        _ = words.next(); // discard "would"
        const gain_lose = words.next();

        var happiness: i32 = undefined;
        const amount = words.next();
        if (amount) |amount_string| {
            happiness = fmt.parseInt(i32, amount_string, 10) catch 0;
        }
        if (gain_lose) |gl_string| {
            if (mem.eql(u8, gl_string, "lose")) happiness = -happiness;
        }

        var i: u8 = 0;
        while (i < 6) {
            _ = words.next(); // discard "happiness units by sitting next to"
            i += 1;
        }
        const guest_y = words.next();

        if (reverse_lookup(guest_names, guest_x)) |index_x| {
            if (reverse_lookup(guest_names, guest_y)) |index_y| {
                matrix[index_x][index_y] = happiness;
            }
        }
    }
}

fn test_arrangement(arrangement: []usize, prefs: [num_guests][num_guests]i32) i32 {
    var happiness: i32 = 0;
    for (arrangement) |person, seat| {
        if ((person < num_guests) and (arrangement[(seat + 1) % arrangement.len] < num_guests)) {
            happiness += prefs[person][arrangement[(seat + 1) % arrangement.len]];
            //print("prefs[{}][{}] = {}\n", .{ person, arrangement[(seat + 1) % arrangement.len], prefs[person][arrangement[(seat + 1) % arrangement.len]] });
            happiness += prefs[arrangement[(seat + 1) % arrangement.len]][person];
            //print("prefs[{}][{}] = {}\n", .{ arrangement[(seat + 1) % arrangement.len], person, prefs[arrangement[(seat + 1) % arrangement.len]][person] });
        }
    }
    return happiness;
}

pub fn main() void {
    const allocator = std.heap.page_allocator;
    var p = Permutations.init(allocator, num_guests);
    defer p.deinit();
    var q = Permutations.init(allocator, num_guests + 1);
    defer q.deinit();
    // Circular table will repeat a lot; all possible starting points, times two possible directions.
    // This is fine.

    var guest_names: [num_guests][]const u8 = undefined;
    _ = try populate_guest_names(&guest_names, input);

    var prefs: [num_guests][num_guests]i32 = undefined;
    populate_matrix(&prefs, guest_names, input);

    // part 1
    var best_happiness: i32 = std.math.minInt(i32);
    while (p.next()) |path| {
        var score = test_arrangement(path, prefs);
        if (score > best_happiness) {
            best_happiness = score;
            //for (path) |index| {
            //print("{} -> ", .{guest_names[index]});
            //}
            //print("... ({})\n", .{score});
        }
    }
    print("{}\n", .{best_happiness});
    // part 2
    best_happiness = std.math.minInt(i32);
    while (q.next()) |path| {
        var score = test_arrangement(path, prefs);
        if (score > best_happiness) {
            best_happiness = score;
            //for (path) |index| {
            //if (index < num_guests) {
            //print("{} -> ", .{guest_names[index]});
            //} else {
            //print("(YOU) -> ", .{});
            //}
            //}
            //print("... ({})\n", .{score});
        }
    }
    print("{}\n", .{best_happiness});
}
