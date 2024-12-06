const std = @import("std");
const aoc = @import("aoc.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("input/day06.txt", .{});
    defer file.close();

    const text = try file.readToEndAlloc(allocator, comptime 1 << 30);
    defer allocator.free(text);

    var lab = try Lab.parse(allocator, text);
    defer lab.deinit();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("{d}\n", .{try part1(allocator, lab)});
    try bw.flush();
}

const Coords = struct {
    r: i32,
    c: i32,

    fn plus(self: Coords, delta: Delta) Coords {
        return .{
            .r = self.r + delta.dr,
            .c = self.c + delta.dc,
        };
    }
};

const Delta = struct {
    dr: i32,
    dc: i32,

    fn new(dr: i32, dc: i32) Delta {
        return .{ .dr = dr, .dc = dc };
    }
};

const Direction = enum {
    N,
    E,
    S,
    W,

    fn delta(self: Direction) Delta {
        return switch (self) {
            .N => Delta.new(-1, 0),
            .S => Delta.new(1, 0),
            .W => Delta.new(0, -1),
            .E => Delta.new(0, 1),
        };
    }

    fn clockwise(self: Direction) Direction {
        return switch (self) {
            .N => .E,
            .E => .S,
            .S => .W,
            .W => .N,
        };
    }
};

const Lab = struct {
    const Self = @This();
    const Map = std.AutoHashMap(Coords, u8);

    map: Map,
    start: Coords,

    fn parse(allocator: std.mem.Allocator, text: []u8) !Self {
        var map = Map.init(allocator);
        var start: Coords = undefined;

        var it = std.mem.tokenizeScalar(u8, text, '\n');
        var r: usize = 0;
        while (it.next()) |row| : (r += 1) {
            for (row, 0..) |char, c| {
                const coords = Coords{ .r = @intCast(r), .c = @intCast(c) };
                try map.put(coords, char);

                if (char == '^') {
                    start = coords;
                }
            }
        }

        return .{ .map = map, .start = start };
    }

    fn deinit(self: *Self) void {
        self.map.deinit();
    }

    fn iterator(self: *const Self) Map.Iterator {
        return self.map.iterator();
    }

    fn get(self: *const Self, k: Coords) ?u8 {
        return self.map.get(k);
    }
};

const Guard = struct {
    coords: Coords,
    dir: Direction,

    fn facing(self: Guard) Coords {
        return self.coords.plus(self.dir.delta());
    }

    fn move(self: *Guard) void {
        self.coords = self.facing();
    }

    fn rotate(self: *Guard) void {
        self.dir = self.dir.clockwise();
    }
};

fn part1(allocator: Allocator, lab: Lab) !usize {
    var guard = Guard{
        .coords = lab.start,
        .dir = .N,
    };

    var visited = aoc.AutoHashSet(Guard).init(allocator);
    defer visited.deinit();

    while (!visited.contains(guard)) {
        try visited.put(guard);
        const next = lab.get(guard.facing()) orelse break;
        if (next == '#') {
            guard.rotate();
        } else {
            guard.move();
        }
    }

    var uniq = aoc.AutoHashSet(Coords).init(allocator);
    defer uniq.deinit();

    var it = visited.iterator();
    while (it.next()) |v| {
        try uniq.put(v.coords);
    }

    return uniq.count();
}
