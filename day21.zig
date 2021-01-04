const std = @import("std");
const print = std.debug.warn;
const fmt = std.fmt;
const mem = std.mem;
const tokenize = mem.tokenize;

const input = @embedFile("input21.txt");

const Actor = struct {
    hitpoints: i32 = 0,
    damage: i32 = 0,
    armour: i32 = 0,
};

const Equipment = struct {
    name: []const u8,
    cost: i32,
    damage: i32,
    armour: i32,
};

const weapon_shop = [_]Equipment{
    .{
        .name = "Dagger",
        .cost = 8,
        .damage = 4,
        .armour = 0,
    },
    .{
        .name = "Shortsword",
        .cost = 10,
        .damage = 5,
        .armour = 0,
    },
    .{
        .name = "Warhammer",
        .cost = 25,
        .damage = 6,
        .armour = 0,
    },
    .{
        .name = "Longsword",
        .cost = 40,
        .damage = 7,
        .armour = 0,
    },
    .{
        .name = "Greataxe",
        .cost = 74,
        .damage = 8,
        .armour = 0,
    },
};

const armour_shop = [_]Equipment{
    .{
        .name = "No Armour",
        .cost = 0,
        .damage = 0,
        .armour = 0,
    },
    .{
        .name = "Leather",
        .cost = 13,
        .damage = 0,
        .armour = 1,
    },
    .{
        .name = "Chainmail",
        .cost = 31,
        .damage = 0,
        .armour = 2,
    },
    .{
        .name = "Splintmail",
        .cost = 53,
        .damage = 0,
        .armour = 3,
    },
    .{
        .name = "Bandedmail",
        .cost = 75,
        .damage = 0,
        .armour = 4,
    },
    .{
        .name = "Platemail",
        .cost = 102,
        .damage = 0,
        .armour = 5,
    },
};

const ring_shop = [_]Equipment{
    .{
        .name = "Damage +1",
        .cost = 25,
        .damage = 1,
        .armour = 0,
    },
    .{
        .name = "Damage +2",
        .cost = 50,
        .damage = 2,
        .armour = 0,
    },
    .{
        .name = "Damage +3",
        .cost = 100,
        .damage = 3,
        .armour = 0,
    },
    .{
        .name = "Defense +1",
        .cost = 20,
        .damage = 0,
        .armour = 1,
    },
    .{
        .name = "Defense +2",
        .cost = 40,
        .damage = 0,
        .armour = 2,
    },
    .{
        .name = "Defense +3",
        .cost = 80,
        .damage = 0,
        .armour = 3,
    },
    .{
        .name = "No Ring (R)",
        .cost = 0,
        .damage = 0,
        .armour = 0,
    },
    .{
        .name = "No Ring (L)",
        .cost = 0,
        .damage = 0,
        .armour = 0,
    },
};

fn extract_number(text: []const u8) i32 {
    for (text) |ch, i| {
        if ('0' <= ch and ch <= '9') return (fmt.parseInt(i32, text[i..], 10) catch 0);
    }
    return 0;
}

fn actor_from_text(text: []const u8) Actor {
    var result: Actor = undefined;
    var lines = tokenize(text, "\n");
    result.hitpoints = extract_number(lines.next().?);
    result.damage = extract_number(lines.next().?);
    result.armour = extract_number(lines.next().?);
    return result;
}

fn evaluate_build(loadout: [4]Equipment, part_2: bool) ?i32 {
    // returns null if the loadout can't beat boss, or cost if it can
    var player = Actor{
        .hitpoints = 100,
        .damage = 0,
        .armour = 0,
    };
    var total_cost: i32 = 0;
    for (loadout) |slot| {
        player.damage += slot.damage;
        player.armour += slot.armour;
        total_cost += slot.cost;
    }
    const player_wins = wins_against(player, actor_from_text(input));
    if ((player_wins and !part_2) or ((!player_wins) and part_2)) {
        return total_cost;
    } else {
        return null;
    }
}

fn wins_against(attacker: Actor, defender: Actor) bool {
    var damage = attacker.damage - defender.armour;
    if (damage < 1) damage = 1;
    const remaining_hp = defender.hitpoints - damage;
    if (remaining_hp <= 0) {
        return true;
    } else {
        const counter_attacker = Actor{
            .hitpoints = remaining_hp,
            .damage = defender.damage,
            .armour = defender.armour,
        };
        return !(wins_against(counter_attacker, attacker));
    }
}

pub fn main() void {
    var lowest_cost: i32 = 999999;
    var highest_cost: i32 = -999999;
    for (weapon_shop) |weapon| {
        for (armour_shop) |armour| {
            for (ring_shop) |ring1, i| {
                for (ring_shop[i + 1 ..]) |ring2| {
                    var cost = evaluate_build(.{ weapon, armour, ring1, ring2 }, false);
                    var cost_2 = evaluate_build(.{ weapon, armour, ring1, ring2 }, true);
                    // part 1
                    if (cost) |c| {
                        if (c < lowest_cost) {
                            lowest_cost = c;
                            //print("GOOD: {} {} {} {} (${})\n", .{ weapon.name, armour.name, ring1.name, ring2.name, c });
                        }
                        // part 2
                    } else if (cost_2) |c| {
                        if (c > highest_cost) {
                            highest_cost = c;
                            //print("BAD: {} {} {} {} (${})\n", .{ weapon.name, armour.name, ring1.name, ring2.name, c });
                        }
                    }
                }
            }
        }
    }
    print("Part 1: {}\nPart 2: {}\n", .{ lowest_cost, highest_cost });
}
