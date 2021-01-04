const std = @import("std");
const print = std.debug.warn;
const mem = std.mem;
const tokenize = mem.tokenize;
const fmt = std.fmt;

const input = @embedFile("input09.txt");
const num_cities: u8 = 8;

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

fn populate_city_names(city_names: *[num_cities][]const u8, text: []const u8) !void {
    var name_index: u8 = 0;
    var lines = tokenize(text, "\n");
    while (lines.next()) |line| {
        var words = tokenize(line, " ");
        var word_index: u8 = 0;
        while (words.next()) |word| {
            if ('A' <= word[0] and word[0] <= 'Z') { // city name
                // Is it already here?
                var seen: bool = false;
                for (city_names[0..name_index]) |city_name| {
                    if (mem.eql(u8, city_name, word)) seen = true;
                }
                if (!seen) {
                    city_names[name_index] = word;
                    name_index += 1;
                }
            }
            word_index += 1;
        }
    }
}

fn reverse_lookup(city_names: [num_cities][]const u8, maybe_city_name: ?[]const u8) ?usize {
    if (maybe_city_name) |city_name| {
        for (city_names) |test_name, index| {
            if (mem.eql(u8, test_name, city_name)) {
                return index;
            }
        }
    }
    return null;
}

fn populate_matrix(matrix: *[num_cities][num_cities]u32, city_names: [num_cities][]const u8, text: []const u8) void {
    var lines = tokenize(text, "\n");
    while (lines.next()) |line| {
        var words = tokenize(line, " ");
        const city_a = words.next();
        _ = words.next(); // discard "to"
        const city_b = words.next();
        _ = words.next(); // discard "="
        var distance: u32 = undefined;
        if (words.next()) |distance_string| {
            distance = fmt.parseUnsigned(u32, distance_string, 10) catch 0;
        }
        if (reverse_lookup(city_names, city_a)) |index_a| {
            if (reverse_lookup(city_names, city_b)) |index_b| {
                matrix[index_a][index_b] = distance;
                matrix[index_b][index_a] = distance;
            }
        }
    }
}

fn path_length(path: []usize, distances: [num_cities][num_cities]u32) u32 {
    var total: u32 = 0;
    for (path) |node, index| {
        if (index == 0) continue;
        total += distances[node][path[index - 1]];
    }
    return total;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var p = Permutations.init(allocator, num_cities);
    defer p.deinit();

    var city_names: [num_cities][]const u8 = undefined;
    _ = try populate_city_names(&city_names, input);

    var distances: [num_cities][num_cities]u32 = undefined;
    populate_matrix(&distances, city_names, input);

    var shortest_route: u32 = std.math.maxInt(u32);
    var longest_route: u32 = 0;
    while (p.next()) |path| {
        var pl = path_length(path, distances);
        // part 1
        if (pl < shortest_route) {
            shortest_route = pl;
            //print("Updating shortest route (", .{});
            //for (path) |index| {
            //print("{} -> ", .{city_names[index]});
            //}
            //print("end) = {}\n", .{pl});
        }
        // part 2
        if (pl > longest_route) {
            longest_route = pl;
            //print("Updating longest route (", .{});
            //for (path) |index| {
            //print("{} -> ", .{city_names[index]});
            //}
            //print("end) = {}\n", .{pl});
        }
    }
    print("{}\n{}\n", .{ shortest_route, longest_route });
}
