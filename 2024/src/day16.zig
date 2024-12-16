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
    const start, const goal = v: {
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
    };

    const Entry = struct {
        path: List(State),
        cost: u64,

        const Self = @This();

        fn compare(_: void, a: Self, b: Self) std.math.Order {
            return std.math.order(a.cost, b.cost);
        }
    };

    var queue = PriorityQueue(Entry, void, comptime Entry.compare).init(allocator, {});
    defer queue.deinit();
    defer while (queue.removeOrNull()) |*entry| entry.path.deinit();

    try queue.add(v: {
        var path = List(State).init(allocator);
        try path.append(State{
            .pos = start,
            .dir = Direction.e,
        });
        break :v Entry{
            .path = path,
            .cost = 0,
        };
    });

    var expanded = Set(State).init(allocator);
    defer expanded.deinit();

    while (queue.removeOrNull()) |entry| {
        const path, const cost = .{ entry.path, entry.cost };
        defer path.deinit();

        const state = path.getLast();

        if (expanded.contains(state)) {
            continue;
        }
        try expanded.put(state);

        if (std.meta.eql(state.pos, goal)) {
            return cost;
        }

        // Move once in the direction we're already going.
        {
            const move = state.pos.move(state.dir);
            if (grid.get(move) != '#') {
                var next = try path.clone();
                try next.append(State{
                    .pos = move,
                    .dir = state.dir,
                });
                try queue.add(Entry{
                    .path = next,
                    .cost = cost + 1,
                });
            }
        }

        // There's never any reason to turn unless we're going to immediately
        // move forward. This keeps the search from every trying to spin in a circle.
        //
        // As a consequence, there's never *ever* a reason to turn twice in a row
        // and go back the way we came in.
        for ([_]Direction{ state.dir.clockwise(), state.dir.counterclockwise() }) |dir| {
            const move = state.pos.move(dir);
            if (grid.get(move) == '#') {
                continue;
            }

            var next = try path.clone();
            try next.append(State{
                .pos = move,
                .dir = dir,
            });
            try queue.add(Entry{
                .path = next,
                .cost = cost + 1000 + 1,
            });
        }
    }

    return 0;
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
