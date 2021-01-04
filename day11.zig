const std = @import("std");
const print = std.debug.warn;
const mem = std.mem;

const input = "cqjxjnds";

// let's brute-force it

fn increment_passwd(passwd: [8]u8) [8]u8 {
    // don't forget to skip i l o
    var result: [8]u8 = undefined;
    var i: u8 = 0;
    var carry: bool = true;
    while (i < 8) {
        if (carry) { // add 1 to this digit
            carry = (passwd[7 - i] == 'z');
            result[7 - i] = switch (passwd[7 - i]) {
                'z' => 'a',
                'h' => 'j', // skip 'i'
                'k' => 'm', // skip 'l'
                'n' => 'p', // skip 'o'
                else => passwd[7 - i] + 1,
            };
        } else {
            result[7 - i] = passwd[7 - i];
        }
        i += 1;
    }
    return result;
}

fn contains_increasing_triplet(passwd: [8]u8) bool {
    // checks for e.g. abc, bcd, xyz
    for (passwd) |ch, index| {
        if (index >= 6) break;
        if ((passwd[index + 1] == (ch + 1)) and (passwd[index + 2] == (ch + 2))) return true;
    }
    return false;
}

fn contains_two_pairs(passwd: [8]u8) bool {
    // checks for two non-overlapping pairs
    var i: u8 = 0;
    var pair: bool = false; // whether one pair has been found yet
    while (i < 7) {
        if (passwd[i] == passwd[i + 1]) {
            if (pair) return true;
            // else
            pair = true;
            i += 2;
        } else {
            i += 1;
        }
    }
    return false;
}

pub fn main() void {
    var passwd: [8]u8 = undefined;
    for (input) |ch, index| {
        if (index >= 8) break;
        passwd[index] = ch;
    }

    // part 1
    while (!(contains_increasing_triplet(passwd) and contains_two_pairs(passwd))) {
        passwd = increment_passwd(passwd);
    }
    print("{}\n", .{passwd});
    // part 2
    passwd = increment_passwd(passwd);
    while (!(contains_increasing_triplet(passwd) and contains_two_pairs(passwd))) {
        passwd = increment_passwd(passwd);
    }
    print("{}\n", .{passwd});
}
