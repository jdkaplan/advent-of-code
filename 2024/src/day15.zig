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

    const text = try aoc.readAll(allocator, "input/day15.txt");
    defer allocator.free(text);

    var blocks = std.mem.splitSequence(u8, text, "\n\n");

    var grid = try Grid.parse(allocator, blocks.next().?);
    defer grid.deinit();

    var moves = try Direction.parseAll(allocator, blocks.next().?);
    defer moves.deinit();

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = bw.writer();

    try stdout.print("{d}\n", .{try part1(grid, moves.items)});
    try bw.flush();
}

fn part1(start: Grid, moves: []const Direction) !i64 {
    var grid = try start.clone();
    defer grid.deinit();

    var pos = v: {
        var it = grid.iterator();
        while (it.next()) |entry| {
            const pos = entry.key_ptr.*;
            const char = entry.value_ptr.*;

            if (char == '@') {
                break :v pos;
            }
        }
        unreachable;
    };
    try grid.map.put(pos, '.');

    for (moves) |move| {
        pos = try grid.move(pos, move);
    }

    var score: i64 = 0;
    var it = grid.iterator();
    while (it.next()) |entry| {
        const box = entry.key_ptr.*;
        const char = entry.value_ptr.*;

        if (char != 'O') {
            continue;
        }

        score += 100 * box.r + box.c;
    }

    return score;
}

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
        try writer.print("({d}, {d})", .{ self.r, self.c });
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

    fn parse(c: u8) Direction {
        return switch (c) {
            '^' => .n,
            'v' => .s,
            '<' => .w,
            '>' => .e,
            else => unreachable,
        };
    }

    fn parseAll(allocator: Allocator, text: []const u8) !List(Direction) {
        var lines = std.mem.tokenizeScalar(u8, text, '\n');
        var list = List(Direction).init(allocator);
        while (lines.next()) |line| {
            for (line) |c| {
                try list.append(Direction.parse(c));
            }
        }
        return list;
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
    allocator: Allocator,
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

        return Grid{
            .allocator = allocator,
            .map = map,
            .max = max,
        };
    }

    fn deinit(self: *Grid) void {
        self.map.deinit();
    }

    fn clone(self: Grid) !Grid {
        return Grid{
            .allocator = self.allocator,
            .map = try self.map.clone(),
            .max = self.max,
        };
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

    fn move(self: *Grid, robot: Pos, dir: Direction) !Pos {
        var stack = List(Pos).init(self.allocator);
        defer stack.deinit();

        const delta = dir.delta();
        var next = robot.add(delta);
        while (self.get(next) == 'O') {
            try stack.append(next);
            next = next.add(delta);
        }

        if (self.get(next) == '#') {
            return robot;
        }

        while (stack.popOrNull()) |box| {
            try self.map.put(box.add(delta), 'O');
            try self.map.put(box, '.');
        }

        return robot.add(delta);
    }
};
