const std = @import("std");
const print = std.debug.warn;
const fmt = std.fmt;
const mem = std.mem;
const tokenize = mem.tokenize;

const input = @embedFile("input14.txt");
const race_time = 2503;
//const input = @embedFile("input14.test");
//const race_time = 1000;

const Reindeer = struct {
    name: []const u8,
    speed: u32,
    fly_time: u32,
    rest_time: u32,
    distance: u32,
    timer: u32,
    score: u32,
    is_flying: bool,

    fn reset(self: *Reindeer) void {
        self.*.distance = 0;
        self.*.timer = self.*.fly_time;
        self.*.is_flying = true;
        self.*.score = 0;
    }

    fn step(self: *Reindeer) void {
        if (self.*.is_flying) self.*.distance += self.*.speed;
        self.*.timer -= 1;
        if (self.*.timer == 0) {
            self.*.is_flying = !self.*.is_flying;
            if (self.*.is_flying) {
                self.*.timer = self.*.fly_time;
            } else {
                self.*.timer = self.*.rest_time;
            }
        }
    }
};

fn reindeer_from_line(line: []const u8) Reindeer {
    var reindeer = Reindeer{
        .name = "666",
        .speed = 666,
        .fly_time = 666,
        .rest_time = 666,
        .distance = 0,
        .timer = 0,
        .is_flying = true,
        .score = 0,
    };
    var words = tokenize(line, " ");
    // Vixen can fly 8 km/s for 8 seconds, but then must rest for 53 seconds.
    if (words.next()) |name| {
        reindeer.name = name;
    }
    _ = words.next(); // can
    _ = words.next(); // fly
    if (words.next()) |speed| {
        reindeer.speed = fmt.parseUnsigned(u32, speed, 10) catch 777;
    }
    _ = words.next(); // km/s
    _ = words.next(); // for
    if (words.next()) |fly_time| {
        reindeer.fly_time = fmt.parseUnsigned(u32, fly_time, 10) catch 777;
    }
    var i: u8 = 0;
    while (i < 6) {
        _ = words.next(); // seconds, but then must rest for
        i += 1;
    }
    if (words.next()) |rest_time| {
        reindeer.rest_time = fmt.parseUnsigned(u32, rest_time, 10) catch 777;
    }
    return reindeer;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var reindeer_list = std.ArrayList(Reindeer).init(allocator);
    defer reindeer_list.deinit();

    var lines = tokenize(input, "\n");
    while (lines.next()) |line| {
        try reindeer_list.append(reindeer_from_line(line));
    }

    // part 1
    for (reindeer_list.items) |r, i| {
        reindeer_list.items[i].reset();
    }
    var t: u32 = 0;
    while (t < race_time) {
        //if (t < 10) print("t={}\n", .{t});
        for (reindeer_list.items) |r, i| {
            //if (t < 10) print("{}\n", .{r});
            reindeer_list.items[i].step();
        }
        t += 1;
    }
    var best_reindeer: ?Reindeer = null;
    for (reindeer_list.items) |r| {
        if (best_reindeer) |br| {
            if (r.distance > br.distance) best_reindeer = r;
        } else {
            best_reindeer = r;
        }
    }
    //print("{}\n", .{best_reindeer});
    print("{}\n", .{best_reindeer.?.distance});

    // part 2
    for (reindeer_list.items) |r, i| {
        reindeer_list.items[i].reset();
    }
    t = 0;
    var best_distance: u32 = 0;
    while (t < race_time) {
        for (reindeer_list.items) |r, i| {
            reindeer_list.items[i].step();
            if (reindeer_list.items[i].distance > best_distance) {
                best_distance = reindeer_list.items[i].distance;
            }
        }
        for (reindeer_list.items) |r, i| {
            if (r.distance == best_distance) {
                reindeer_list.items[i].score += 1;
            }
        }
        t += 1;
    }
    best_reindeer = null;
    for (reindeer_list.items) |r| {
        if (best_reindeer) |br| {
            if (r.score > br.score) best_reindeer = r;
        } else {
            best_reindeer = r;
        }
    }
    //print("{}\n", .{best_reindeer});
    print("{}\n", .{best_reindeer.?.score});
}
