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

    try stdout.print("{}\n", .{part1(seeds.items)});
    try bw.flush();
}

fn part1(seeds: []u64) u64 {
    var sum: u64 = 0;
    for (seeds) |seed| {
        sum += simulate(seed, 2000);
    }
    return sum;
}

fn simulate(seed: u64, steps: usize) u64 {
    var n: u64 = seed;
    for (0..steps) |_| {
        n = ((n * 64) ^ n) % 16777216;
        n = ((n / 32) ^ n) % 16777216;
        n = ((n * 2048) ^ n) % 16777216;
    }
    return n;
}
