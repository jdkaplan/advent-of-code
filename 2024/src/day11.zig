const std = @import("std");
const aoc = @import("aoc.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("input/day11.txt", .{});
    defer file.close();

    const text = try file.readToEndAlloc(allocator, comptime 1 << 30);
    defer allocator.free(text);

    var stones = try Stones.parse(allocator, text);
    defer stones.deinit();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("{d}\n", .{try part1(allocator, stones)});
    try bw.flush();

    try stdout.print("{d}\n", .{try part2(allocator, stones)});
    try bw.flush();
}

fn part1(allocator: Allocator, start: Stones) !usize {
    var stones = try start.clone();
    defer stones.deinit();

    for (0..25) |_| {
        try stones.blink(allocator);
    }

    return stones.list.items.len;
}

fn part2(allocator: Allocator, stones: Stones) !u64 {
    var memo = std.AutoHashMap(State, u64).init(allocator);
    defer memo.deinit();

    var total: u64 = 0;
    for (stones.list.items) |start| {
        total += try blinkMemo(&memo, start, 75);
    }
    return total;
}

const Stones = struct {
    list: ArrayList(u64),

    const Self = @This();

    fn deinit(self: *Self) void {
        self.list.deinit();
    }

    fn clone(self: Self) !Self {
        return .{ .list = try self.list.clone() };
    }

    fn parse(allocator: Allocator, text: []const u8) !Self {
        var list = ArrayList(u64).init(allocator);
        errdefer list.deinit();

        var lines = std.mem.tokenizeScalar(u8, text, '\n');
        var it = std.mem.tokenizeScalar(u8, lines.next().?, ' ');
        while (it.next()) |level| {
            const i = try std.fmt.parseInt(u64, level, 10);
            try list.append(i);
        }

        return .{ .list = list };
    }

    pub fn format(
        self: Self,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        if (self.list.items.len > 0) {
            try writer.print("{}", .{self.list.items[0]});
        }
        for (self.list.items[1..]) |i| {
            try writer.print(" {}", .{i});
        }
    }

    fn blink(self: *Self, allocator: Allocator) !void {
        var prev = self.list;
        defer prev.deinit();

        var next = ArrayList(u64).init(allocator);
        errdefer next.deinit();

        for (prev.items) |i| {
            if (i == 0) {
                try next.append(1);
            } else if (split(i)) |parts| {
                try next.append(parts[0]);
                try next.append(parts[1]);
            } else {
                try next.append(i * 2024);
            }
        }

        self.list = next;
    }
};

const State = struct {
    start: u64,
    ticks: usize,
};

fn blinkMemo(memo: *std.AutoHashMap(State, u64), start: u64, ticks: usize) !u64 {
    if (ticks == 0) {
        return 1;
    }

    const state = State{ .start = start, .ticks = ticks };
    if (memo.get(state)) |n| {
        return n;
    }

    var total: u64 = undefined;
    if (start == 0) {
        total = try blinkMemo(memo, 1, ticks - 1);
    } else if (split(start)) |parts| {
        const a = try blinkMemo(memo, parts[0], ticks - 1);
        const b = try blinkMemo(memo, parts[1], ticks - 1);
        total = a + b;
    } else {
        total = try blinkMemo(memo, start * 2024, ticks - 1);
    }

    try memo.put(state, total);
    return total;
}

fn split(n: u64) ?[2]u64 {
    const digits = 1 + std.math.log10(n);
    if (digits % 2 == 0) {
        const x = std.math.pow(u64, 10, digits / 2);
        return .{ n / x, n % x };
    }
    return null;
}

test "split" {
    const expectEqual = std.testing.expectEqual;

    try expectEqual(.{ 1, 0 }, split(10));
    try expectEqual(.{ 10, 0 }, split(1000));
    try expectEqual(.{ 9, 9 }, split(99));
}
