const std = @import("std");
const aoc = @import("aoc.zig");

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("input/day01.txt", .{});
    defer file.close();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var lines = aoc.Lines.init(allocator, file);
    defer lines.deinit();

    var left = std.ArrayList(u32).init(allocator);
    defer left.deinit();

    var right = std.ArrayList(u32).init(allocator);
    defer right.deinit();

    while (try lines.next()) |line| {
        var it = std.mem.tokenizeScalar(u8, line.items, ' ');
        const l = it.next().?;
        const r = it.next().?;

        try left.append(try std.fmt.parseInt(u32, l, 10));
        try right.append(try std.fmt.parseInt(u32, r, 10));
    }

    std.mem.sort(u32, left.items, {}, comptime std.sort.asc(u32));
    std.mem.sort(u32, right.items, {}, comptime std.sort.asc(u32));

    try stdout.print("{d}\n", .{part1(left, right)});
    try stdout.print("{d}\n", .{try part2(allocator, left, right)});
    try bw.flush();
}

fn part1(left: std.ArrayList(u32), right: std.ArrayList(u32)) u32 {
    var i: usize = 0;
    var distance: u32 = 0;
    while (i < left.items.len) {
        distance += abs_diff(left.items[i], right.items[i]);
        i += 1;
    }

    return distance;
}

fn abs_diff(a: u32, b: u32) u32 {
    if (a > b) {
        return a - b;
    } else {
        return b - a;
    }
}

fn part2(allocator: std.mem.Allocator, left: std.ArrayList(u32), right: std.ArrayList(u32)) !u32 {
    var counts = std.AutoHashMap(u32, u32).init(allocator);
    defer counts.deinit();

    for (right.items) |r| {
        const v = counts.get(r) orelse 0;
        try counts.put(r, v + 1);
    }

    var similarity: u32 = 0;
    for (left.items) |l| {
        similarity += l * (counts.get(l) orelse 0);
    }

    return similarity;
}
