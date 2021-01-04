const std = @import("std");
const print = std.debug.warn;
const Md5 = std.crypto.Md5;
const fmt = std.fmt;

const input = "yzbqklnj";

fn is_valuable_hash(str: []const u8, integer: u64, num_zeros: u8) bool {
    // returns true iff the md5hash of "{str}{integer}" starts with "00000"
    var candidate = [_]u8{' '} ** 16;
    _ = fmt.bufPrint(&candidate, "{}{}", .{ str, integer }) catch unreachable;

    var raw_hash: [16]u8 = undefined;
    Md5.hash(fmt.trim(candidate[0..]), &raw_hash);

    var hex_hash: [32]u8 = undefined;
    _ = fmt.bufPrint(&hex_hash, "{x:0>32}", .{raw_hash}) catch unreachable;

    var index: u8 = 0;
    while (index < num_zeros) {
        if (hex_hash[index] != '0') {
            return false;
        }
        index += 1;
    }
    //print("{} => {}\n", .{ fmt.trim(candidate), hex_hash });
    return true;
}

pub fn main() !void {
    var hash_digits: u64 = 0;
    while (!is_valuable_hash(input, hash_digits, 5)) {
        hash_digits += 1;
    }
    print("{}\n", .{hash_digits});
    while (!is_valuable_hash(input, hash_digits, 6)) {
        hash_digits += 1;
    }
    // If it's not done in 5 minutes... just wait longer.
    print("{}\n", .{hash_digits});
}
