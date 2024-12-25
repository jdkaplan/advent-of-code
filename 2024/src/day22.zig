const std = @import("std");
const aoc = @import("aoc.zig");

const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const Set = aoc.AutoHashSet;
const PriorityQueue = std.PriorityQueue;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const text = try aoc.readAll(allocator, "input/day22.txt");
    defer allocator.free(text);

    var lines = std.mem.tokenizeScalar(u8, text, '\n');

    var seeds = List(u64).init(allocator);
    defer seeds.deinit();
    while (lines.next()) |line| {
        const seed = try std.fmt.parseInt(u64, line, 10);
        try seeds.append(seed);
    }

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = bw.writer();

    try stdout.print("{}\n{}\n", try solve(allocator, seeds.items));
    try bw.flush();
}

fn solve(allocator: Allocator, seeds: []u64) !struct { u64, u64 } {
    var totals = Map([4]i64, u64).init(allocator);
    defer totals.deinit();

    var sum: u64 = 0;
    for (seeds) |seed| {
        var profit = Map([4]i64, u64).init(allocator);
        defer profit.deinit();

        sum += try populate(seed, 2000, &profit);

        var it = profit.iterator();
        while (it.next()) |entry| {
            const changes, const bananas = .{ entry.key_ptr.*, entry.value_ptr.* };

            const total = try totals.getOrPutValue(changes, 0);
            total.value_ptr.* += bananas;
        }
    }

    var best: u64 = 0;
    var it = totals.valueIterator();
    while (it.next()) |p| {
        best = @max(best, p.*);
    }
    return .{ sum, best };
}

fn populate(seed: u64, steps: usize, profit: *Map([4]i64, u64)) !u64 {
    var n: u64 = seed;
    var prices = [_]u64{0} ** 4;

    // Pre-fill the first few updates, since those don't have enough changes yet.
    for (0..3) |i| {
        const price = n % 10;
        prices[i] = price;

        n = ((n * 64) ^ n) % 16777216;
        n = ((n / 32) ^ n) % 16777216;
        n = ((n * 2048) ^ n) % 16777216;
    }

    var changes = [_]i64{0} ** 4;
    for (1..4) |i| {
        const next: i64 = @intCast(prices[i]);
        const prev: i64 = @intCast(prices[i - 1]);
        changes[i] = next - prev;
    }

    // This is the first time we have a usable change sequence.
    _ = try profit.getOrPutValue(changes, prices[3]);

    for (3..steps) |_| {
        n = ((n * 64) ^ n) % 16777216;
        n = ((n / 32) ^ n) % 16777216;
        n = ((n * 2048) ^ n) % 16777216;

        const price = n % 10;

        std.mem.copyForwards(u64, &prices, prices[1..]);
        prices[3] = price;

        std.mem.copyForwards(i64, &changes, changes[1..]);
        {
            const a: i64 = @intCast(prices[3]);
            const b: i64 = @intCast(prices[2]);
            changes[3] = a - b;
        }
        _ = try profit.getOrPutValue(changes, prices[3]);
    }

    // Everything but the update, because we *can* still sell here.
    {
        const price = n % 10;

        std.mem.copyForwards(u64, &prices, prices[1..]);
        prices[3] = price;

        std.mem.copyForwards(i64, &changes, changes[1..]);
        {
            const a: i64 = @intCast(prices[3]);
            const b: i64 = @intCast(prices[2]);
            changes[3] = a - b;
        }
        _ = try profit.getOrPutValue(changes, prices[3]);
    }

    return n;
}
