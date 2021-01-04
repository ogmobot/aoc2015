const std = @import("std");
const print = std.debug.warn;
const math = std.math;

const input: u64 = 36000000;
const num_primes: usize = 1024 * 2;

fn make_primes() [num_primes]u64 {
    var primes = [_]u64{0} ** num_primes;
    primes[0] = 2;
    var index: usize = 1;
    while (index < num_primes) {
        primes[index] = next_prime(primes[index - 1]);
        index += 1;
    }
    return primes;
}

fn next_prime(n: u64) u64 {
    // finds next prime number above n,
    // by trial division (slow but might work)
    if (n == 2) return 3;
    if (n == 3) return 5;
    var test_number = n + 2;
    while (true) {
        // skip all the even numbers, so don't need to check div by 2
        var divisor: u64 = 3;
        var is_prime = true;
        while (divisor * divisor <= test_number) {
            // skip all the odd divisors too
            if (test_number % divisor == 0) {
                is_prime = false;
                break;
            }
            divisor += 2;
        }
        if (is_prime) return test_number;
        test_number += 2;
    }
}

fn sum_of_factors(n: u64, primes: []const u64) u64 {
    // product of all (p^a - 1)/(p - 1)
    // where p is each distince prime factor of n
    // and a is the maximum power such that p^a divides n
    var total: u64 = 1;
    for (primes) |p, i| {
        if (n % p != 0) continue;
        //if (p * p > n) break;
        //if (p == 1) break;
        var a: u64 = 0;
        var tmp = n;
        while (tmp % p == 0) {
            //print("p={}, tmp={}\n", .{ p, tmp });
            tmp /= p;
            a += 1;
        }
        total *= (math.pow(u64, p, a + 1) - 1) / (p - 1);
    }
    return total;
}

fn sum_of_factors_part2(n: u64, primes: []const u64) u64 {
    // subtract all factors that are less than n / 50
    var result: u64 = sum_of_factors(n, primes);
    //if (n > 2500) print("{} => {}\n", .{ n, result });
    // Trial division is sloooow.
    // To speed up, perhaps calculate prime factors and infer factors from those.
    var divisor: u64 = 1;
    while (divisor * 50 < n) {
        if (n % divisor == 0) {
            if (divisor > result)
                print("n={}, result={}, divisor={}\n", .{ n, result, divisor });
            result -= divisor;
        }
        divisor += 1;
    }
    return result;
}

fn reverse_sum_of_factors(target: u64, primes: []const u64) u64 {
    // Finds the lowest number with a factor sum of at least target.
    var factor_sum: u64 = 0;
    var trial: u64 = 1;
    while (sum_of_factors(trial, primes[0..]) < target) {
        trial += 1;
    }
    return trial;
}

fn reverse_sum_of_factors_part2(target: u64, primes: []const u64) u64 {
    // Finds the lowest number with a factor sum of at least target.
    var factor_sum: u64 = 0;
    var trial: u64 = 1;
    while (sum_of_factors_part2(trial, primes[0..]) < target) {
        trial += 1;
    }
    return trial;
}

pub fn main() void {
    const primes = make_primes();
    // part 1
    // elves give 10 presents each
    const target = input / 10;
    const result1 = reverse_sum_of_factors(target, primes[0..]);
    print("House {} receives {} gifts\n", .{ result1, 10 * sum_of_factors(result1, primes[0..]) });
    // part 2
    // elves give 11 presents each
    const target2 = (input / 11) + 1;
    const result2 = reverse_sum_of_factors_part2(target2, primes[0..]);
    print("House {} receives {} gifts\n", .{ result2, 11 * sum_of_factors_part2(result2, primes[0..]) });
}
