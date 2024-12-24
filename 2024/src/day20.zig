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

    const text = try aoc.readAll(allocator, "input/day20.txt");
    defer allocator.free(text);

    var grid = try Grid.parse(allocator, text);
    defer grid.deinit();

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = bw.writer();

    var route = try search(allocator, grid);
    defer route.path.deinit();

    var path = try List(Pos).initCapacity(allocator, route.path.items.len);
    for (route.path.items) |s| {
        try path.append(s.pos);
    }
    defer path.deinit();

    try stdout.print("{}\n", .{part1(path.items)});
    try bw.flush();

    try stdout.print("{}\n", .{try part2(allocator, path.items)});
    try bw.flush();
}

fn search(allocator: Allocator, grid: Grid) !SearchIterator(State).End {
    const s = v: {
        var it = grid.iterator();
        while (it.next()) |entry| {
            switch (entry.value_ptr.*) {
                'S' => break :v entry.key_ptr.*,
                else => continue,
            }
        }
        unreachable;
    };

    const ctx = State.Context{
        .grid = grid,
    };

    const start = State.new(s);

    var exits = try SearchIterator(State).init(allocator, ctx, start);
    defer exits.deinit();

    const end = try exits.next(.{
        .goal = State.isGoal,
        .heuristic = State.heuristic,
        .neighbors = State.neighbors,
    });
    return end.?;
}

fn part1(path: []Pos) usize {
    var saves: usize = 0;

    for (path[0 .. path.len - 2], 0..) |p1, i| {
        for (path[i + 2 ..], i + 2..) |p2, j| {
            if (p1.distance(p2) != 2) continue;

            const saved = j - i - 2;
            if (saved < 100) continue;

            saves += 1;
        }
    }

    return saves;
}

fn part2(allocator: Allocator, path: []Pos) !u64 {
    var cheats = try findCheats(allocator, path, 20);
    defer cheats.deinit();

    var count: u64 = 0;
    var it = cheats.iterator();
    while (it.next()) |cheat| {
        if (cheat.saved < 100) continue;

        count += 1;
    }
    return count;
}

const Cheat = struct {
    start: Pos,
    end: Pos,
    saved: usize,
};

fn findCheats(allocator: Allocator, path: []Pos, distance: usize) !Set(Cheat) {
    var set = Set(Cheat).init(allocator);

    var idx = Map(Pos, usize).init(allocator);
    defer idx.deinit();
    for (path, 0..) |pos, i| try idx.put(pos, i);

    for (path, 0..) |start, i| {
        var window = try start.window(allocator, distance);
        defer window.deinit();

        for (window.items) |end| {
            const j = idx.get(end) orelse continue;
            if (j <= i) continue;

            const walk = j - i;

            const oob = start.distance(end);

            if (walk <= oob) continue;

            try set.put(Cheat{
                .start = start,
                .end = end,
                .saved = walk - oob,
            });
        }
    }

    return set;
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

    pub fn isGoal(self: Self, ctx: Context) bool {
        return ctx.grid.get(self.pos) == 'E';
    }

    pub fn heuristic(_: Self, _: Context) u64 {
        return 0;
    }

    pub const Neighbor = struct { Self, u64 };

    pub fn neighbors(self: Self, ctx: Context, allocator: Allocator) !List(Neighbor) {
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

    pub fn window(self: Pos, allocator: Allocator, limit: usize) !List(Pos) {
        var list = List(Pos).init(allocator);
        for (0..(limit + 1)) |dr| {
            for (0..(limit - dr) + 1) |dc| {
                const dri: i32 = @intCast(dr);
                const dci: i32 = @intCast(dc);

                try list.append(self.add(Delta.new(dri, dci)));
                try list.append(self.add(Delta.new(dri, -dci)));
                try list.append(self.add(Delta.new(-dri, dci)));
                try list.append(self.add(Delta.new(-dri, -dci)));
            }
        }
        return list;
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

    fn neg(self: Delta) Delta {
        return Delta{ .dr = -self.dr, .dc = -self.dc };
    }
};

const Grid = struct {
    allocator: Allocator,
    map: Map(Pos, u8),
    max: Pos,

    fn init(allocator: Allocator, max: Pos) !Grid {
        return Grid{
            .map = Map(Pos, u8).init(allocator),
            .max = max,
        };
    }

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

    fn populate(self: *Grid, positions: []Pos, v: u8) !void {
        for (positions) |pos| {
            try self.put(pos, v);
        }
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
        const NeighborsFn = fn (T, T.Context, Allocator) Allocator.Error!List(T.Neighbor);

        pub const End = struct {
            path: List(T),
            cost: u64,
        };

        pub const SearchParams = struct {
            goal: GoalFn,
            heuristic: HeuristicFn,
            neighbors: NeighborsFn,
        };

        pub fn next(self: *Self, params: SearchParams) !?End {
            while (self.queue.removeOrNull()) |entry| {
                const u, const cost = .{ entry.state, entry.cost };
                if (self.dist.get(u)) |best| {
                    if (best < cost) {
                        continue;
                    }
                }

                if (params.goal(u, self.ctx)) {
                    return End{
                        .path = try self.path(u),
                        .cost = cost,
                    };
                }

                var neighbors: List(T.Neighbor) = try params.neighbors(u, self.ctx, self.allocator);
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
                        .heuristic = params.heuristic(v, self.ctx),
                    });
                }
            }

            return null;
        }

        fn path(self: Self, end: T) !List(T) {
            var states = List(T).init(self.allocator);
            try states.insert(0, end);

            var state = end;
            while (self.prev.get(state)) |p| {
                try states.insert(0, p);
                state = p;
            }

            return states;
        }
    };
}
