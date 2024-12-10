const std = @import("std");
const aoc = @import("aoc.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("input/day10.txt", .{});
    defer file.close();

    const text = try file.readToEndAlloc(allocator, comptime 1 << 30);
    defer allocator.free(text);

    var grid = try Grid.parse(allocator, text);
    defer grid.deinit();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const part1, const part2 = try findTrails(allocator, grid);

    try stdout.print("{d}\n", .{part1});
    try bw.flush();

    try stdout.print("{d}\n", .{part2});
    try bw.flush();
}

fn findTrails(allocator: Allocator, grid: Grid) !struct { usize, usize } {
    var stack = ArrayList(ArrayList(Pos)).init(allocator);
    defer stack.deinit();
    defer for (stack.items) |*trail| trail.deinit();

    // Find valid starts
    {
        var it = grid.iterator();
        while (it.next()) |entry| {
            const pos = entry.key_ptr.*;
            const height = entry.value_ptr.*;
            if (height == '0') {
                var trail = ArrayList(Pos).init(allocator);
                try trail.append(pos);
                try stack.append(trail);
            }
        }
    }

    var total: usize = 0;

    var trailheads = std.AutoHashMap(Pos, aoc.AutoHashSet(Pos)).init(allocator);
    defer trailheads.deinit();
    defer {
        var it = trailheads.valueIterator();
        while (it.next()) |set| set.deinit();
    }

    while (stack.popOrNull()) |trail| {
        defer trail.deinit();

        const pos = trail.getLast();
        const height = grid.get(pos).?;
        if (height == '9') {
            total += 1;

            const start = trail.items[0];
            const entry = try trailheads.getOrPut(start);
            if (!entry.found_existing) {
                entry.value_ptr.* = aoc.AutoHashSet(Pos).init(allocator);
            }
            try entry.value_ptr.put(pos);
            continue;
        }

        for (std.enums.values(Direction)) |dir| {
            const next = pos.add(dir.delta());
            if (grid.get(next) != height + 1) {
                continue;
            }

            var t = try trail.clone();
            try t.append(next);
            try stack.append(t);
        }
    }

    var uniq: u64 = 0;
    var it = trailheads.valueIterator();
    while (it.next()) |set| {
        uniq += set.count();
    }
    return .{ uniq, total };
}

const Pos = struct {
    r: i32,
    c: i32,

    fn add(self: Pos, d: Delta) Pos {
        return .{
            .r = self.r + d.dr,
            .c = self.c + d.dc,
        };
    }

    fn distance(self: Pos, other: Pos) Delta {
        return .{
            .dr = other.r - self.r,
            .dc = other.c - self.c,
        };
    }

    pub fn format(
        self: Pos,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("({}, {})", .{ self.r, self.c });
    }
};

const Direction = enum {
    n,
    e,
    s,
    w,

    fn delta(self: Direction) Delta {
        return switch (self) {
            .n => Delta.new(-1, 0),
            .s => Delta.new(1, 0),
            .w => Delta.new(0, -1),
            .e => Delta.new(0, 1),
        };
    }

    fn clockwise(self: Direction) Direction {
        return switch (self) {
            .n => .e,
            .e => .s,
            .s => .w,
            .w => .n,
        };
    }
};

const Delta = struct {
    dr: i32,
    dc: i32,

    fn new(dr: i32, dc: i32) Delta {
        return Delta{ .dr = dr, .dc = dc };
    }
};

const Grid = struct {
    const Map = std.AutoHashMap(Pos, u8);

    map: Map,
    max: Pos,

    fn parse(allocator: std.mem.Allocator, text: []const u8) !Grid {
        var map = Map.init(allocator);
        var max = Pos{ .r = 0, .c = 0 };

        var it = std.mem.tokenizeScalar(u8, text, '\n');
        var r: i32 = 0;
        while (it.next()) |row| : (r += 1) {
            for (row, 0..) |char, c| {
                const pos = Pos{
                    .r = @intCast(r),
                    .c = @intCast(c),
                };
                try map.put(pos, char);
                max = pos;
            }
        }

        return .{ .map = map, .max = max };
    }

    fn deinit(self: *Grid) void {
        self.map.deinit();
    }

    fn iterator(self: *const Grid) Map.Iterator {
        return self.map.iterator();
    }

    fn get(self: *const Grid, pos: Pos) ?u8 {
        return self.map.get(pos);
    }

    fn inBounds(self: Grid, pos: Pos) bool {
        return 0 <= pos.r and pos.r <= self.max.r and
            0 <= pos.c and pos.c <= self.max.c;
    }
};
