const std = @import("std");
const print = std.debug.warn;
const fmt = std.fmt;
const tokenize = std.mem.tokenize;
const sort = std.sort;

const input = @embedFile("input22.txt");

const POISON_DAMAGE = 3;
const SHIELD_DR = 7;
const RECHARGE_MP = 101;

const Actor = struct {
    hitpoints: i32 = 0,
    damage: i32 = 0,
    armour: i32 = 0,
};

const Game_State = struct {
    // Defaults are zero so keys can be left out in spellbook below
    spent_mp: u32 = 0, // sort by this key
    player_hp: i16 = 0, // not sure if "Drain" spell can heal past 50 HP
    player_mp: i16 = 0, // max is 500 MP
    boss_hp: i8 = 0, // max is 58 HP
    boss_damage: i8 = 0, // value is 9 (for this input)
    shield_timer: i8 = 0, // max is 6
    poison_timer: i8 = 0, // max is 6
    recharge_timer: i8 = 0, // max is 5
    turn_count: u8 = 0,
    history: u64 = 0, // each triplet of bits is a spell:
    // 000: nothing
    // 001: missile
    // 010: drain
    // 011: shield
    // 100: poison
    // 101: recharge
};

// Spellbook
// (spells add their state to the current game state)
const sp_magic_missile = Game_State{
    .spent_mp = 53,
    .player_mp = -53,
    .boss_hp = -4,
};
const sp_drain = Game_State{
    .spent_mp = 73,
    .player_mp = -73,
    .boss_hp = -2,
    .player_hp = 2,
};
const sp_shield = Game_State{
    // increases DR by 7
    .spent_mp = 113,
    .player_mp = -113,
    .shield_timer = 6,
};
const sp_poison = Game_State{
    // deals 3 damage per turn
    .spent_mp = 173,
    .player_mp = -173,
    .poison_timer = 6,
};
const sp_recharge = Game_State{
    // replenishes 101 MP per turn
    .spent_mp = 229,
    .player_mp = -229,
    .recharge_timer = 5,
};
const spellbook = [_]Game_State{ sp_magic_missile, sp_drain, sp_shield, sp_poison, sp_recharge };

fn extract_number(text: []const u8) i8 {
    for (text) |ch, i| {
        if ('0' <= ch and ch <= '9') return (fmt.parseInt(i8, text[i..], 10) catch 0);
    }
    return 0;
}

fn mana_spent_less_than(lhs: Game_State, rhs: Game_State) bool {
    return lhs.spent_mp < rhs.spent_mp;
}

fn write_history(history: u64) void {
    var tmp = history;
    while (tmp > 0) {
        switch (tmp % 0b1000) {
            0b000 => print("[nothing]<-", .{}),
            0b001 => print("[magic missile]<-", .{}),
            0b010 => print("[drain]<-", .{}),
            0b011 => print("[shield]<-", .{}),
            0b100 => print("[poison]<-", .{}),
            0b101 => print("[recharge]<-", .{}),
            else => print("[invalid]<-", .{}),
        }
        tmp >>= 3;
    }
    print("\n", .{});
}

fn do_turn(orig_state: Game_State, spell_index: usize, hard_mode: bool) ?Game_State {
    // Returns the game state that is the result of casting `spell`,
    // or `null` if spell is illegal or player dies.
    var state = Game_State{
        .spent_mp = orig_state.spent_mp,
        .player_hp = orig_state.player_hp,
        .player_mp = orig_state.player_mp,
        .boss_hp = orig_state.boss_hp,
        .boss_damage = orig_state.boss_damage,
        .shield_timer = orig_state.shield_timer,
        .poison_timer = orig_state.poison_timer,
        .recharge_timer = orig_state.recharge_timer,
        .turn_count = orig_state.turn_count + 1,
        .history = (orig_state.history << 3) + (spell_index + 1),
    };

    // Start of player's turn.
    if (hard_mode) {
        state.player_hp -= 1;
        if (state.player_hp <= 0) return null;
    }
    // Tick down effects.
    if (state.shield_timer > 0) state.shield_timer -= 1;
    if (state.poison_timer > 0) {
        state.boss_hp -= POISON_DAMAGE;
        state.poison_timer -= 1;
    }
    if (state.recharge_timer > 0) {
        state.player_mp += RECHARGE_MP;
        state.recharge_timer -= 1;
    }
    // Player casts spell.
    const spell = spellbook[spell_index];
    // On illegal spell, return null.
    if (state.shield_timer > 0 and spell.shield_timer > 0) return null;
    if (state.poison_timer > 0 and spell.poison_timer > 0) return null;
    if (state.recharge_timer > 0 and spell.recharge_timer > 0) return null;
    // Do spell effects
    state.spent_mp += spell.spent_mp;
    state.player_hp += spell.player_hp;
    state.player_mp += spell.player_mp;
    state.boss_hp += spell.boss_hp;
    state.boss_damage += spell.boss_damage; // should do nothing
    state.shield_timer += spell.shield_timer;
    state.poison_timer += spell.poison_timer;
    state.recharge_timer += spell.recharge_timer;
    // If player has negative mana, they lose.
    if (state.player_mp < 0) return null;

    // Start of boss's turn
    // Tick down effects
    if (state.shield_timer > 0) state.shield_timer -= 1;
    if (state.poison_timer > 0) {
        state.boss_hp -= POISON_DAMAGE;
        state.poison_timer -= 1;
    }
    if (state.recharge_timer > 0) {
        state.player_mp += RECHARGE_MP;
        state.recharge_timer -= 1;
    }
    // If boss is dead, they can't attack back.
    // (Check after poison damage is applied)
    if (state.boss_hp <= 0) {
        return state;
    }
    // Boss attacks
    var boss_damage = state.boss_damage;
    if (state.shield_timer > 0) boss_damage -= SHIELD_DR;
    if (boss_damage < 1) boss_damage = 1;
    state.player_hp -= boss_damage;
    // If player has no hp left, they lose.
    if (state.player_hp <= 0) return null;

    return state;
}

pub fn main() !void {
    // WELCOME TO WIZARD SIMULATOR 20XX
    var allocator = std.heap.page_allocator;
    var many_universes = std.PriorityQueue(Game_State).init(allocator, mana_spent_less_than);
    defer many_universes.deinit();

    var lines = tokenize(input, "\n");
    const boss_hp = extract_number(lines.next().?);
    const boss_damage = extract_number(lines.next().?);

    try many_universes.add(.{
        .player_hp = 50,
        .player_mp = 500,
        .boss_hp = boss_hp,
        .boss_damage = boss_damage,
    });

    var winner: Game_State = undefined;

    // part 1
    while (true) {
        var candidate: Game_State = many_universes.remove();
        if (candidate.boss_hp <= 0) {
            // winner winner!
            winner = candidate;
            break;
        } else {
            for (spellbook) |spell, i| {
                if (do_turn(candidate, i, false)) |state| {
                    _ = try many_universes.add(state);
                }
            }
        }
    }
    //print("{}\n", .{winner});
    //_ = write_history(winner.history);
    print("{}\n", .{winner.spent_mp});

    // part 2
    while (many_universes.len > 0) {
        _ = many_universes.remove();
    } // empty the queue

    _ = try many_universes.add(.{
        .player_hp = 50,
        .player_mp = 500,
        .boss_hp = boss_hp,
        .boss_damage = boss_damage,
    });

    while (true) {
        var candidate: Game_State = many_universes.remove();
        if (candidate.boss_hp <= 0) {
            // winner winner!
            winner = candidate;
            break;
        } else {
            for (spellbook) |spell, i| {
                if (do_turn(candidate, i, true)) |state| {
                    _ = try many_universes.add(state);
                }
            }
        }
    }
    //print("{}\n", .{winner});
    //_ = write_history(winner.history);
    print("{}\n", .{winner.spent_mp});
}
