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

    const text = try aoc.readAll(allocator, "input/day16.txt");
    defer allocator.free(text);

    var blocks = std.mem.splitSequence(u8, text, "\n\n");

    var grid = try Grid.parse(allocator, blocks.next().?);
    defer grid.deinit();

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = bw.writer();

    try stdout.print("{d}\n", .{try part1(allocator, grid)});
    try bw.flush();
}

fn part1(allocator: Allocator, grid: Grid) !u64 {
    const pos, const goal = v: {
        var start: Pos = undefined;
        var end: Pos = undefined;

        var it = grid.iterator();
        while (it.next()) |entry| {
            switch (entry.value_ptr.*) {
                'S' => start = entry.key_ptr.*,
                'E' => end = entry.key_ptr.*,
                else => continue,
            }
        }
        break :v .{ start, end };
    };

    const State = struct {
        pos: Pos,
        dir: Direction,

        const Self = @This();

        pub const Context = struct {
            allocator: Allocator,
            grid: Grid,
            goal: Pos,
        };

        pub fn isGoal(self: Self, ctx: Context) bool {
            return std.meta.eql(self.pos, ctx.goal);
        }

        pub const Neighbor = struct {
            next: Self,
            extra: u64,
        };

        pub fn neighbors(self: Self, ctx: Context) !List(Neighbor) {
            var list = List(Neighbor).init(ctx.allocator);

            // Move once in the direction we're already going.
            {
                const move = self.pos.move(self.dir);
                if (ctx.grid.get(move) != '#') {
                    try list.append(Neighbor{
                        .next = Self{
                            .pos = move,
                            .dir = self.dir,
                        },
                        .extra = 1,
                    });
                }
            }

            // There's never any reason to turn unless we're going to immediately
            // move forward. This keeps the search from every trying to spin in a circle.
            //
            // As a consequence, there's never *ever* a reason to turn twice in a row
            // and go back the way we came in.
            for ([_]Direction{ self.dir.clockwise(), self.dir.counterclockwise() }) |dir| {
                const move = self.pos.move(dir);
                if (ctx.grid.get(move) == '#') {
                    continue;
                }

                try list.append(Neighbor{
                    .next = Self{
                        .pos = move,
                        .dir = dir,
                    },
                    .extra = 1000 + 1,
                });
            }

            return list;
        }
    };

    const start = State{
        .pos = pos,
        .dir = Direction.e,
    };

    const ctx = State.Context{
        .allocator = allocator,
        .grid = grid,
        .goal = goal,
    };

    return (try aoc.shortestPath(State, allocator, ctx, start)).?;
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

    fn move(self: Pos, dir: Direction) Pos {
        return self.add(dir.delta());
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

    fn clockwise(self: Direction) Direction {
        return switch (self) {
            .n => .e,
            .e => .s,
            .s => .w,
            .w => .n,
        };
    }

    fn counterclockwise(self: Direction) Direction {
        return switch (self) {
            .n => .w,
            .w => .s,
            .s => .e,
            .e => .n,
        };
    }

    pub fn format(
        self: Direction,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        const c: u8 = switch (self) {
            .n => 'N',
            .e => 'E',
            .s => 'S',
            .w => 'W',
        };
        try writer.print("{c}", .{c});
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
};
