const std = @import("std");
const print = std.debug.warn;
const fmt = std.fmt;
const mem = std.mem;
const tokenize = mem.tokenize;

const input = @embedFile("input15.txt");

const Ingredient = struct {
    name: []const u8,
    capacity: i32,
    durability: i32,
    flavour: i32,
    texture: i32,
    calories: i32,
};

const Recipe = struct {
    // r.ingredients[0] => { .name="Sugar", ... , .calories=1 }
    // r.qty[0] => 25
    ingredients: []Ingredient,
    // qty[i] >= 0, but using i32 here avoids intCasting later
    qty: []i32,
};

const Compositions = struct {
    allocator: *mem.Allocator,
    values: []i32, // avoids intCasting later
    a: i32, //size of integer to compose, e.g. 100
    k: usize, //number of parts, e.g. 4
    const Self = @This();

    fn init(allocator: *mem.Allocator, a: i32, k: usize) Self {
        var result = Self{
            .allocator = allocator,
            .a = a,
            .k = k,
            .values = allocator.alloc(i32, k) catch &[_]i32{},
        };
        result.reset();
        return result;
    }

    fn deinit(self: *Compositions) void {
        self.allocator.free(self.values);
    }

    // (100 0 0 0
    // (99 1 0 0) (98 2 0 0) .. (0 100 0 0)
    // (99 0 1 0) (98 1 1 0) .. (0 99 1 0)
    // (98 0 2 0) (97 1 2 0) .. (0 98 2 0) .. (0 0 100 0)
    // .. (0 0 0 100)
    fn next(self: *Compositions) ?[]i32 {
        var just_reset: bool = true;
        for (self.values) |v| {
            if (v != 0) just_reset = false;
        }
        if (just_reset) {
            self.values[0] = self.a;
            return self.values;
        } else {
            for (self.values) |val, i| {
                if (val == 0) continue;
                if (val == self.a) {
                    if (i + 1 == self.values.len) {
                        return null;
                    } else {
                        self.values[i] = 0;
                        self.values[i + 1] = 1;
                        self.values[0] = self.a - 1;
                        return self.values;
                    }
                } else {
                    // can't be at the end of the array yet
                    // this is the first non-zero cell
                    self.values[i + 1] += 1;
                    self.values[i] = 0;
                    self.values[0] = val - 1;
                    return self.values;
                }
            }
        }
        return null; //unreachable
    }

    fn reset(self: *Compositions) void {
        var index: usize = 0;
        while (index < self.k) {
            self.values[index] = 0;
            index += 1;
        }
    }
};

fn score(recipe: Recipe) i32 {
    var capacity: i32 = 0;
    var durability: i32 = 0;
    var flavour: i32 = 0;
    var texture: i32 = 0;
    for (recipe.ingredients) |ingredient, i| {
        capacity += ingredient.capacity * recipe.qty[i];
        durability += ingredient.durability * recipe.qty[i];
        flavour += ingredient.flavour * recipe.qty[i];
        texture += ingredient.texture * recipe.qty[i];
    }
    if (capacity < 0 or durability < 0 or flavour < 0 or texture < 0) return 0;
    return capacity * durability * flavour * texture;
}

fn calorie_count(recipe: Recipe) i32 {
    var calories: i32 = 0;
    for (recipe.ingredients) |ingredient, i| {
        calories += ingredient.calories * recipe.qty[i];
    }
    return calories;
}

fn line_to_ingredient(line: []const u8) Ingredient {
    var tokens = mem.tokenize(line, ":, ");
    var result = Ingredient{
        .name = "666",
        .capacity = 666,
        .durability = 666,
        .flavour = 666,
        .texture = 666,
        .calories = 666,
    };
    if (tokens.next()) |name| {
        result.name = name;
    }
    _ = tokens.next(); // discard "capacity"
    if (tokens.next()) |capacity| {
        result.capacity = fmt.parseInt(i32, capacity, 10) catch 777;
    }
    _ = tokens.next(); // discard "durability"
    if (tokens.next()) |durability| {
        result.durability = fmt.parseInt(i32, durability, 10) catch 777;
    }
    _ = tokens.next(); // discard "flavor"
    if (tokens.next()) |flavour| {
        result.flavour = fmt.parseInt(i32, flavour, 10) catch 777;
    }
    _ = tokens.next(); // discard "texture"
    if (tokens.next()) |texture| {
        result.texture = fmt.parseInt(i32, texture, 10) catch 777;
    }
    _ = tokens.next(); // discard "calories"
    if (tokens.next()) |calories| {
        result.calories = fmt.parseInt(i32, calories, 10) catch 777;
    }
    return result;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var comps = Compositions.init(allocator, 100, 4);
    defer comps.deinit();
    var ingredients = std.ArrayList(Ingredient).init(allocator);
    defer ingredients.deinit();

    var lines = mem.tokenize(input, "\n");
    while (lines.next()) |line| {
        try ingredients.append(line_to_ingredient(line));
    }

    var best_qtys = [_]i32{0} ** 4;
    var best_recipe = Recipe{
        .ingredients = ingredients.items,
        .qty = &best_qtys,
    };

    var best_500_qtys = [_]i32{0} ** 4;
    var best_500_recipe = Recipe{
        .ingredients = ingredients.items,
        .qty = &best_500_qtys,
    };

    while (comps.next()) |comp| {
        const test_recipe = Recipe{
            .ingredients = ingredients.items,
            .qty = comp,
        };
        // part 1
        if (score(test_recipe) > score(best_recipe)) {
            for (test_recipe.qty) |q, i| {
                best_recipe.qty[i] = q;
            }
        }
        // part 2
        if (calorie_count(test_recipe) == 500) {
            if (score(test_recipe) > score(best_500_recipe)) {
                for (test_recipe.qty) |q, i| {
                    best_500_recipe.qty[i] = q;
                }
            }
        }
    }
    //print("{} ({} {} {} {})\n", .{ br.qty[0], br.qty[1], br.qty[2], br.qty[3] });
    print("{}\n", .{score(best_recipe)});
    //print("{} ({} {} {} {})\n", .{ b5r.qty[0], b5r.qty[1], b5r.qty[2], b5r.qty[3] });
    print("{}\n", .{score(best_500_recipe)});
}
