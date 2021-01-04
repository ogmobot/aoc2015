const std = @import("std");
const print = std.debug.warn;
const fmt = std.fmt;
const mem = std.mem;
const split = mem.split;
const tokenize = mem.tokenize;

const input = @embedFile("input19.txt");
const bufsz: usize = 512;
// input19.test should produce 7 and 6

// Transformations are
// X => X1 X2
// X => X1 Rn X2 Ar
// X => X1 Rn X2 Y X3 Ar
// X => X1 Rn X2 Y X3 Y X4 Ar

// e.g. { .from = "H", .to  "HO" }
const Conversion_Type = enum {
    t0, // X1 X2
    t1, // X1 Rn X2 Ar
    t2, // X1 Rn X2 Y X3 Ar
    t3, // X1 Rn X2 Y X3 Y X4 Ar
};

const Conversion = struct {
    from: []const u8,
    to: []const u8,
    class: Conversion_Type,
};

fn process_text(text: []const u8, conversions: *std.ArrayList(Conversion)) ?[]const u8 {
    // Converts text "H => HO" to a list of conversions.
    // Upon encountering a blank line, returns the next line of text.
    // The `conversions` argument should be an empty list.
    var lines = split(text, "\n");
    while (lines.next()) |line| {
        if (mem.eql(u8, line, "")) return lines.next();
        var tokens = mem.tokenize(line, "=> ");
        var item = Conversion{
            .from = undefined,
            .to = undefined,
            .class = undefined,
        };
        if (tokens.next()) |token| {
            item.from = token;
        }
        if (tokens.next()) |token| {
            item.to = token;
            // determine type of conversion
            var ycount: u32 = 0;
            var ar = false;
            for (token) |ch, i| {
                if (ch == 'Y') ycount += 1;
                if (i == 0) continue;
                if (ch == 'r' and token[i - 1] == 'A') ar = true;
            }
            switch (ycount) {
                0 => {
                    if (ar) {
                        item.class = .t1;
                    } else {
                        item.class = .t0;
                    }
                },
                1 => {
                    item.class = .t2;
                },
                2 => {
                    item.class = .t3;
                },
                else => {},
            }
        }
        conversions.*.append(item) catch unreachable;
    }
    return null;
}

fn count_new_molecules(molecule: []const u8, conversions: std.ArrayList(Conversion)) usize {
    // we're counting unique strings here, so better use a hash map
    var allocator = std.heap.page_allocator;
    var new_molecules = std.StringHashMap(void).init(allocator);
    defer new_molecules.deinit();

    for (conversions.items) |c| {
        // assume no keys are substrings of other keys,
        // i.e. `H` and `He` will not both appear.
        for (molecule) |ch, i| {
            if (i + c.from.len > molecule.len) break;
            if (mem.eql(u8, c.from, molecule[i..(i + c.from.len)])) {
                var buffer = allocator.alloc(u8, bufsz) catch "";
                //defer allocator.free(buffer);
                // can't free this here, because it'll mess with the hash map
                const key: []u8 = fmt.bufPrint(buffer, "{}{}{}", .{
                    molecule[0..i],
                    c.to,
                    molecule[(i + c.from.len)..],
                }) catch "";
                var existing_entry = new_molecules.put(key, {}) catch unreachable;
                if (existing_entry) |entry| {
                    allocator.free(entry.key);
                }
            }
        }
    }
    const result = new_molecules.count();
    var iterator = new_molecules.iterator();
    while (iterator.next()) |entry| {
        allocator.free(entry.key);
        // Memory management is everyone's responsibility!
        // (Does this even work, though? entry.key is []u8, but the original allocated buffer is [512]u8...)
        // (Oh well, the function only gets called once and allocates ~20kb. Even if it's leaky, it's fine.)
    }
    return result;
}

fn count_reductions(text: []const u8) u32 {
    // filtered
    var num_tokens: u32 = 0;
    var num_commas: u32 = 0;
    var num_rbrackets: u32 = 0;
    var num_lbrackets: u32 = 0;
    for (text) |ch, i| {
        num_tokens += 1;
        switch (ch) {
            'Y' => num_commas += 1,
            'A' => {
                // This can't be last character
                if (text[i + 1] == 'r') {
                    num_rbrackets += 1;
                }
            },
            'R' => num_lbrackets += 1,
            'a'...'z' => num_tokens -= 1, // this isn't a real token
            else => {},
        }
    }
    // With only .t0 rules, it takes (num_tokens - 1) to reduce to `e`.
    // In .t1, .t2 and .t3 rules, Rn .. Ar pairs are effectively reduced for free.
    // Each Y symbol is associated with one additional symbol, so both the Y and the extra symbol are reduced for free.
    return num_tokens - (num_rbrackets + num_lbrackets) - (2 * num_commas) - 1;
}

pub fn main() void {
    var allocator = std.heap.page_allocator;
    var conversions = std.ArrayList(Conversion).init(allocator);
    defer conversions.deinit();
    const start_molecule = process_text(input, &conversions);
    if (start_molecule) |s| {
        // part 1
        print("{}\n", .{count_new_molecules(s, conversions)});
        // part 2
        print("{}\n", .{count_reductions(s)});
    }
    //for (conversions.items) |c| {
    //print("{}\n", .{c});
    //}
}
