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

    const text = try aoc.readAll(allocator, "input/day18.txt");
    defer allocator.free(text);

    var bytes = try aoc.parseAll(Pos, allocator, text, "\n");
    defer bytes.deinit();

    var grid = try Grid.init(allocator, Pos.new(70, 70));
    defer grid.deinit();

    for (bytes.items[0..1024]) |pos| {
        try grid.put(pos, '#');
    }

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = bw.writer();

    try stdout.print("{}\n", .{try search(allocator, grid, Pos.new(0, 0), grid.max)});
    try bw.flush();
}

fn search(allocator: Allocator, grid: Grid, pos: Pos, _: Pos) !u64 {
    const start = State.new(pos);

    const ctx = State.Context{
        .grid = grid,
    };

    var exits = try SearchIterator(State).init(allocator, ctx, start);
    defer exits.deinit();

    while (try exits.next(State.isGoal, State.heuristic)) |next| {
        return next.cost;
    }

    return 0;
}

const State = struct {
    pos: Pos,

    const Self = @This();

    pub const Context = struct {
        grid: Grid,
    };

    pub fn new(pos: Pos) Self {
        return Self{ .pos = pos };
    }

    pub fn isInVoid(self: Self, ctx: Context) bool {
        const lo, const hi = .{ -1, 1 };

        var dr: i32 = lo;
        while (dr <= hi) : (dr += 1) {
            var dc: i32 = lo;
            while (dc <= hi) : (dc += 1) {
                const d = Delta.new(dr, dc);
                if (!ctx.grid.passable(self.pos.add(d))) {
                    return false;
                }
            }
        }
        return true;
    }

    pub fn isGoal(self: Self, ctx: Context) bool {
        return std.meta.eql(self.pos, ctx.grid.max);
    }

    pub fn heuristic(self: Self, ctx: Context) u64 {
        return self.pos.distance(ctx.grid.max);
    }

    pub const Neighbor = struct { Self, u64 };

    pub fn neighbors(self: Self, allocator: Allocator, ctx: Context) !List(Neighbor) {
        var list = List(Neighbor).init(allocator);

        for (self.pos.neighbors()) |next| {
            if (!ctx.grid.inBounds(next)) continue;
            if (ctx.grid.get(next) == '#') continue;

            try list.append(Neighbor{ Self.new(next), 1 });
        }

        return list;
    }
};

const Pos = struct {
    r: i32,
    c: i32,

    pub fn parse(_: Allocator, line: []const u8) !Pos {
        var nums = std.mem.splitScalar(u8, line, ',');
        const r = try std.fmt.parseInt(i32, nums.next().?, 10);
        const c = try std.fmt.parseInt(i32, nums.next().?, 10);
        return Pos{ .r = r, .c = c };
    }

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

    fn distance(self: Pos, other: Pos) u64 {
        var d: u64 = 0;
        d += @abs(self.r - other.r);
        d += @abs(self.c - other.c);
        return d;
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
    map: Map(Pos, u8),
    max: Pos,

    fn init(allocator: Allocator, max: Pos) !Grid {
        return Grid{
            .map = Map(Pos, u8).init(allocator),
            .max = max,
        };
    }

    fn deinit(self: *Grid) void {
        self.map.deinit();
    }

    fn clone(self: Grid) !Grid {
        return Grid{
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

    fn put(self: *Grid, pos: Pos, v: u8) !void {
        try self.map.put(pos, v);
    }

    fn inBounds(self: Grid, pos: Pos) bool {
        return 0 <= pos.r and pos.r <= self.max.r and
            0 <= pos.c and pos.c <= self.max.c;
    }

    fn passable(self: Grid, pos: Pos) bool {
        return self.inBounds(pos) and self.get(pos) != '#';
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
                if (self.get(Pos.new(r, c))) |x| {
                    try writer.print("{c}", .{x});
                } else {
                    try writer.print(" ", .{});
                }
            }
            try writer.print("|\n", .{});
        }
    }
};

fn SearchIterator(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: Allocator,
        ctx: T.Context,

        queue: PriorityQueue(Entry, void, Entry.compare),
        dist: Map(T, u64),
        prev: Map(T, T),

        const Entry = struct {
            state: T,
            cost: u64,
            heuristic: u64,

            fn compare(_: void, a: Entry, b: Entry) std.math.Order {
                return std.math.order(a.cost + a.heuristic, b.cost + b.heuristic);
            }
        };

        fn init(allocator: Allocator, ctx: T.Context, start: T) Allocator.Error!Self {
            var queue = PriorityQueue(Entry, void, comptime Entry.compare).init(allocator, {});

            try queue.add(Entry{
                .state = start,
                .cost = 0,
                .heuristic = 0,
            });

            var dist = Map(T, u64).init(allocator);
            try dist.put(start, 0);

            const prev = Map(T, T).init(allocator);

            return Self{
                .allocator = allocator,
                .queue = queue,
                .dist = dist,
                .prev = prev,
                .ctx = ctx,
            };
        }

        fn deinit(self: *Self) void {
            self.prev.deinit();
            self.dist.deinit();
            self.queue.deinit();
        }

        const GoalFn = fn (T, T.Context) bool;
        const HeuristicFn = fn (T, T.Context) u64;

        const End = struct {
            state: T,
            cost: u64,
        };

        pub fn next(self: *Self, isGoal: GoalFn, heuristic: HeuristicFn) !?End {
            while (self.queue.removeOrNull()) |entry| {
                const u, const cost = .{ entry.state, entry.cost };
                if (self.dist.get(u)) |best| {
                    if (best < cost) {
                        continue;
                    }
                }

                if (isGoal(u, self.ctx)) {
                    return End{ .state = u, .cost = cost };
                }

                var neighbors: List(T.Neighbor) = try u.neighbors(self.allocator, self.ctx);
                defer neighbors.deinit();

                for (neighbors.items) |neighbor| {
                    const v, const extra = neighbor;
                    const alt = cost + extra;

                    if (self.dist.get(v)) |dv| {
                        if (alt >= dv) {
                            continue;
                        }
                    }

                    try self.prev.put(v, u);

                    try self.dist.put(v, alt);
                    try self.queue.add(Entry{
                        .state = v,
                        .cost = alt,
                        .heuristic = heuristic(v, self.ctx),
                    });
                }
            }

            return null;
        }
    };
}
