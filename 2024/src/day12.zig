const std = @import("std");
const aoc = @import("aoc.zig");

const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const Set = aoc.AutoHashSet;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const text = try aoc.readAll(allocator, "input/day12.txt");
    defer allocator.free(text);

    var grid = try Grid.parse(allocator, text);
    defer grid.deinit();

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = bw.writer();

    try stdout.print("{d}\n", .{try part1(allocator, grid)});
    try bw.flush();
}

fn part1(allocator: Allocator, grid: Grid) !u64 {
    var unused = Set(Pos).init(allocator);
    defer unused.deinit();
    {
        var r: i32 = 0;
        while (r <= grid.max.r) : (r += 1) {
            var c: i32 = 0;
            while (c <= grid.max.c) : (c += 1) {
                const pos = Pos.new(r, c);
                try unused.put(pos);
            }
        }
    }

    var cost: u64 = 0;
    while (unused.pop()) |root| {
        const label = grid.get(root).?;

        var region = Region.init(allocator, label);
        defer region.deinit();

        var queue = List(Pos).init(allocator);
        defer queue.deinit();

        try queue.append(root);

        while (queue.popOrNull()) |pos| {
            try region.add(pos);

            for (pos.neighbors()) |next| {
                if (grid.get(next) == label and unused.contains(next)) {
                    _ = unused.remove(next) or unreachable;
                    try queue.append(next);
                }
            }
        }

        cost += region.fencingCost();
    }

    return cost;
}

const Region = struct {
    label: u8,
    perimeter: u64,
    cells: Set(Pos),

    const Self = @This();

    fn init(allocator: Allocator, label: u8) Self {
        return .{
            .label = label,
            .perimeter = 0,
            .cells = Set(Pos).init(allocator),
        };
    }

    fn deinit(self: *Self) void {
        self.cells.deinit();
    }

    fn area(self: Self) usize {
        return self.cells.count();
    }

    fn add(self: *Self, pos: Pos) !void {
        if (self.cells.contains(pos)) {
            unreachable;
        }

        var shared: u64 = 0;
        for (pos.neighbors()) |n| {
            if (self.cells.contains(n)) {
                shared += 1;
            }
        }

        // This adds 4 line segments to the boundary, but that double-counts
        // the segments shared with existing neighbors (once for the neighbor,
        // once for the new cell), so undo that afterward.
        self.perimeter += 4;
        self.perimeter -= 2 * shared;

        try self.cells.put(pos);
    }

    fn fencingCost(self: Self) u64 {
        return self.area() * self.perimeter;
    }
};

const Pos = struct {
    r: i32,
    c: i32,

    fn new(r: i32, c: i32) Pos {
        return Pos{ .r = r, .c = c };
    }

    fn add(self: Pos, d: Delta) Pos {
        return .{
            .r = self.r + d.dr,
            .c = self.c + d.dc,
        };
    }

    fn neighbors(self: Pos) [4]Pos {
        return [4]Pos{
            self.add(Direction.n.delta()),
            self.add(Direction.e.delta()),
            self.add(Direction.s.delta()),
            self.add(Direction.w.delta()),
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
};

const Delta = struct {
    dr: i32,
    dc: i32,

    fn new(dr: i32, dc: i32) Delta {
        return Delta{ .dr = dr, .dc = dc };
    }
};

const Grid = struct {
    map: Map(Pos, u8),
    max: Pos,

    fn parse(allocator: std.mem.Allocator, text: []const u8) !Grid {
        var map = Map(Pos, u8).init(allocator);
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

    fn iterator(self: *const Grid) Map(Pos, u8).Iterator {
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
