const std = @import("std");
const print = std.debug.warn;
const fmt = std.fmt;
const mem = std.mem;
const tokenize = mem.tokenize;

const input = @embedFile("input16.txt");

const Sue = struct {
    id: u16,
    children: ?u8 = null,
    cats: ?u8 = null,
    samoyeds: ?u8 = null,
    pomeranians: ?u8 = null,
    akitas: ?u8 = null,
    vizslas: ?u8 = null,
    goldfish: ?u8 = null,
    trees: ?u8 = null,
    cars: ?u8 = null,
    perfumes: ?u8 = null,
};

const input_evidence = Sue{
    .id = 0,
    .children = 3,
    .cats = 7,
    .samoyeds = 2,
    .pomeranians = 3,
    .akitas = 0,
    .vizslas = 0,
    .goldfish = 5,
    .trees = 3,
    .cars = 2,
    .perfumes = 1,
};

fn build_sue_profile(line: []const u8) Sue {
    //Sue 500: perfumes: 4, cars: 9, trees: 4
    var words = tokenize(line, ":, ");
    var sue = Sue{
        .id = 0,
    };
    // This seems cool and normal
    while (words.next()) |field_name| {
        if (mem.eql(u8, field_name, "Sue")) {
            if (words.next()) |id| {
                sue.id = fmt.parseUnsigned(u16, id, 10) catch 0;
            }
        } else if (mem.eql(u8, field_name, "children")) {
            if (words.next()) |children| {
                sue.children = fmt.parseUnsigned(u8, children, 10) catch 255;
            }
        } else if (mem.eql(u8, field_name, "cats")) {
            if (words.next()) |cats| {
                sue.cats = fmt.parseUnsigned(u8, cats, 10) catch 255;
            }
        } else if (mem.eql(u8, field_name, "samoyeds")) {
            if (words.next()) |samoyeds| {
                sue.samoyeds = fmt.parseUnsigned(u8, samoyeds, 10) catch 255;
            }
        } else if (mem.eql(u8, field_name, "pomeranians")) {
            if (words.next()) |pomeranians| {
                sue.pomeranians = fmt.parseUnsigned(u8, pomeranians, 10) catch 255;
            }
        } else if (mem.eql(u8, field_name, "akitas")) {
            if (words.next()) |akitas| {
                sue.akitas = fmt.parseUnsigned(u8, akitas, 10) catch 255;
            }
        } else if (mem.eql(u8, field_name, "vizslas")) {
            if (words.next()) |vizslas| {
                sue.vizslas = fmt.parseUnsigned(u8, vizslas, 10) catch 255;
            }
        } else if (mem.eql(u8, field_name, "goldfish")) {
            if (words.next()) |goldfish| {
                sue.goldfish = fmt.parseUnsigned(u8, goldfish, 10) catch 255;
            }
        } else if (mem.eql(u8, field_name, "trees")) {
            if (words.next()) |trees| {
                sue.trees = fmt.parseUnsigned(u8, trees, 10) catch 255;
            }
        } else if (mem.eql(u8, field_name, "cars")) {
            if (words.next()) |cars| {
                sue.cars = fmt.parseUnsigned(u8, cars, 10) catch 255;
            }
        } else if (mem.eql(u8, field_name, "perfumes")) {
            if (words.next()) |perfumes| {
                sue.perfumes = fmt.parseUnsigned(u8, perfumes, 10) catch 255;
            }
        }
    }
    return sue;
}

fn match_profile_to_evidence(profile: Sue, evidence: Sue) bool {
    // COOL AND NORMAL
    if (profile.children) |children| {
        if (children != evidence.children.?) return false;
    }
    if (profile.cats) |cats| {
        if (cats != evidence.cats.?) return false;
    }
    if (profile.samoyeds) |samoyeds| {
        if (samoyeds != evidence.samoyeds.?) return false;
    }
    if (profile.pomeranians) |pomeranians| {
        if (pomeranians != evidence.pomeranians.?) return false;
    }
    if (profile.akitas) |akitas| {
        if (akitas != evidence.akitas.?) return false;
    }
    if (profile.vizslas) |vizslas| {
        if (vizslas != evidence.vizslas.?) return false;
    }
    if (profile.goldfish) |goldfish| {
        if (goldfish != evidence.goldfish.?) return false;
    }
    if (profile.trees) |trees| {
        if (trees != evidence.trees.?) return false;
    }
    if (profile.cars) |cars| {
        if (cars != evidence.cars.?) return false;
    }
    if (profile.perfumes) |perfumes| {
        if (perfumes != evidence.perfumes.?) return false;
    }
    return true;
}

fn match_profile_to_evidence_2(profile: Sue, evidence: Sue) bool {
    // C O O L   A N D   N O R M A L
    if (profile.children) |children| {
        if (children != evidence.children.?) return false;
    }
    if (profile.cats) |cats| {
        if (cats <= evidence.cats.?) return false;
    }
    if (profile.samoyeds) |samoyeds| {
        if (samoyeds != evidence.samoyeds.?) return false;
    }
    if (profile.pomeranians) |pomeranians| {
        if (pomeranians >= evidence.pomeranians.?) return false;
    }
    if (profile.akitas) |akitas| {
        if (akitas != evidence.akitas.?) return false;
    }
    if (profile.vizslas) |vizslas| {
        if (vizslas != evidence.vizslas.?) return false;
    }
    if (profile.goldfish) |goldfish| {
        if (goldfish >= evidence.goldfish.?) return false;
    }
    if (profile.trees) |trees| {
        if (trees <= evidence.trees.?) return false;
    }
    if (profile.cars) |cars| {
        if (cars != evidence.cars.?) return false;
    }
    if (profile.perfumes) |perfumes| {
        if (perfumes != evidence.perfumes.?) return false;
    }
    return true;
}

pub fn main() !void {
    var lines = mem.tokenize(input, "\n");
    while (lines.next()) |line| {
        if (match_profile_to_evidence(build_sue_profile(line), input_evidence)) {
            print("Part 1: {}\n", .{build_sue_profile(line).id});
        }
        if (match_profile_to_evidence_2(build_sue_profile(line), input_evidence)) {
            print("Part 2: {}\n", .{build_sue_profile(line).id});
        }
    }
}
