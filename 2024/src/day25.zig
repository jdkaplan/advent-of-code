const std = @import("std");
const aoc = @import("aoc.zig");

const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StringMap = std.StringHashMap;
const Set = aoc.AutoHashSet;
const PriorityQueue = std.PriorityQueue;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const text = try aoc.readAll(allocator, "input/day25.txt");
    defer allocator.free(text);

    var schematics = try aoc.parseAll(Schematic, allocator, text, "\n\n");
    defer schematics.deinit();
    defer for (schematics.items) |s| s.heights.deinit();

    var keys = List(Schematic).init(allocator);
    defer keys.deinit();
    var locks = List(Schematic).init(allocator);
    defer locks.deinit();

    for (schematics.items) |schematic| {
        if (schematic.isKey) {
            try keys.append(schematic);
        } else {
            try locks.append(schematic);
        }
    }

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = bw.writer();

    try stdout.print("{}\n", .{part1(keys.items, locks.items, 7)});
    try bw.flush();
}

const String = []const u8;

const Schematic = struct {
    isKey: bool,
    heights: List(u8),

    pub fn parse(allocator: Allocator, block: String) !Schematic {
        var seq = std.mem.tokenizeSequence(u8, block, "\n");
        var lines = List(String).init(allocator);
        defer lines.deinit();
        while (seq.next()) |line| {
            try lines.append(line);
        }

        const isKey = for (lines.items[0]) |b| {
            if (b == '.') break true;
        } else false;

        var heights = List(u8).init(allocator);
        for (0..lines.items[0].len) |c| {
            var filled: u8 = 0;
            for (0..lines.items.len) |r| {
                if (lines.items[r][c] == '#') {
                    filled += 1;
                }
            }
            try heights.append(filled);
        }

        return Schematic{
            .isKey = isKey,
            .heights = heights,
        };
    }
};

const Swap = struct {
    a: String,
    b: String,

    pub fn parse(_: Allocator, line: String) !Swap {
        var fields = std.mem.tokenizeSequence(u8, line, " ");
        const a = fields.next().?;
        const b = fields.next().?;
        return Swap{
            .a = a,
            .b = b,
        };
    }
};

fn part1(keys: []Schematic, locks: []Schematic, height: u8) u64 {
    var count: u64 = 0;
    for (keys) |key| {
        for (locks) |lock| {
            if (fits(key, lock, height)) {
                count += 1;
            }
        }
    }
    return count;
}

fn fits(key: Schematic, lock: Schematic, height: u8) bool {
    return for (key.heights.items, 0..) |k, i| {
        const l = lock.heights.items[i];

        if (k + l > height) break false;
    } else true;
}
