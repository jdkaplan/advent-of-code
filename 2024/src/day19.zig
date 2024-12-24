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

    const text = try aoc.readAll(allocator, "input/day19.txt");
    defer allocator.free(text);

    var blocks = std.mem.tokenizeSequence(u8, text, "\n\n");

    const towels = try aoc.splitAll(allocator, blocks.next().?, ", ");
    defer towels.deinit();

    const arrangements = try aoc.splitAll(allocator, blocks.next().?, "\n");
    defer arrangements.deinit();

    if (blocks.next()) |_| unreachable;

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = bw.writer();

    try stdout.print("{}\n{}\n", try options(allocator, towels.items, arrangements.items));
    try bw.flush();
}

const String = []const u8;

fn options(
    allocator: Allocator,
    towels: []String,
    arrangements: []String,
) !struct { u64, u64 } {
    var possible: u64 = 0;
    var total: u64 = 0;

    var memo = std.StringHashMap(u64).init(allocator);
    defer memo.deinit();

    for (arrangements) |desired| {
        const count = try arrange(&memo, towels, desired);

        if (count > 0) {
            possible += 1;
            total += count;
        }
    }

    return .{ possible, total };
}

fn arrange(memo: *std.StringHashMap(u64), alphabet: []String, desired: String) !u64 {
    if (desired.len == 0) {
        return 1;
    }

    if (memo.get(desired)) |n| {
        return n;
    }

    var count: u64 = 0;
    for (alphabet) |atom| {
        if (std.mem.startsWith(u8, desired, atom)) {
            const suffix = desired[atom.len..desired.len];
            count += try arrange(memo, alphabet, suffix);
        }
    }

    try memo.put(desired, count);
    return count;
}
