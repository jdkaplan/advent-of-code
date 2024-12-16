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
    try stdout.print("{d}\n", .{try part2(grid, moves.items)});
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

fn part2(original: Grid, moves: []const Direction) !i64 {
    var start: Pos = undefined;

    var grid = v: {
        var map = Map(Pos, u8).init(original.allocator);

        var it = original.iterator();
        while (it.next()) |entry| {
            const pos = entry.key_ptr.*;
            const char = entry.value_ptr.*;

            const left, const right = .{
                Pos.new(pos.r, 2 * pos.c),
                Pos.new(pos.r, 2 * pos.c + 1),
            };

            if (char == '#') {
                try map.put(left, '#');
                try map.put(right, '#');
            }
            if (char == 'O') {
                try map.put(left, '[');
                try map.put(right, ']');
            }
            if (char == '.') {
                try map.put(left, '.');
                try map.put(right, '.');
            }
            if (char == '@') {
                try map.put(left, '@');
                try map.put(right, '.');
                start = left;
            }
        }

        break :v Grid{
            .allocator = original.allocator,
            .map = map,
            .max = Pos.new(original.max.r, 2 * original.max.c + 1),
        };
    };
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

    for (moves) |dir| {
        if (grid.can_move2(pos, dir)) {
            var moved = Set(Pos).init(grid.allocator);
            defer moved.deinit();

            try grid.do_move2(pos, dir, &moved);
            pos = pos.add(dir.delta());
        }
    }

    var score: i64 = 0;
    var it = grid.iterator();
    while (it.next()) |entry| {
        const box = entry.key_ptr.*;
        const char = entry.value_ptr.*;

        if (char != '[') {
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

    pub fn format(
        self: Grid,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        var r: i32 = 0;
        while (r <= self.max.r) : (r += 1) {
            var c: i32 = 0;
            while (c <= self.max.c) : (c += 1) {
                try writer.print("{c}", .{self.get(Pos.new(r, c)).?});
            }
            try writer.print("\n", .{});
        }
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

    fn can_move2(self: *Grid, pos: Pos, dir: Direction) bool {
        const delta = dir.delta();
        const next = pos.add(delta);

        switch (self.get(next).?) {
            '#' => return false,
            '.' => return true,
            '@' => return self.can_move2(next, dir),

            '[' => switch (dir) {
                .n, .s => {
                    const left = self.can_move2(next, dir);
                    const right = self.can_move2(next.add(Direction.e.delta()), dir);
                    return left and right;
                },
                .e => return self.can_move2(next.add(Direction.e.delta()), dir),
                .w => return self.can_move2(next, dir),
            },
            ']' => switch (dir) {
                .n, .s => {
                    const left = self.can_move2(next, dir);
                    const right = self.can_move2(next.add(Direction.w.delta()), dir);
                    return left and right;
                },
                .w => return self.can_move2(next.add(Direction.w.delta()), dir),
                .e => return self.can_move2(next, dir),
            },
            else => unreachable,
        }
    }

    fn do_move2(self: *Grid, pos: Pos, dir: Direction, moved: *Set(Pos)) !void {
        if (moved.contains(pos)) {
            return;
        }
        try moved.put(pos);

        const delta = dir.delta();
        const next = pos.add(delta);

        const content = self.get(pos).?;

        switch (content) {
            '#' => unreachable,
            '.' => return,
            '@' => try self.do_move2(next, dir, moved),

            '[' => {
                const pair = pos.add(Direction.e.delta());
                switch (dir) {
                    .n, .s => {
                        try self.do_move2(next, dir, moved);
                        try self.do_move2(pair, dir, moved);
                    },
                    .e => {
                        try self.do_move2(pair, dir, moved);
                        try self.do_move2(next, dir, moved);
                    },
                    .w => try self.do_move2(next, dir, moved),
                }
            },
            ']' => {
                const pair = pos.add(Direction.w.delta());
                switch (dir) {
                    .n, .s => {
                        try self.do_move2(pair, dir, moved);
                        try self.do_move2(next, dir, moved);
                    },
                    .w => {
                        try self.do_move2(pair, dir, moved);
                        try self.do_move2(next, dir, moved);
                    },
                    .e => try self.do_move2(next, dir, moved),
                }
            },
            else => unreachable,
        }

        try self.map.put(next, content);
        try self.map.put(pos, '.');
    }
};
