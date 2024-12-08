const std = @import("std");
const aoc = @import("aoc.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("input/day08.txt", .{});
    defer file.close();

    const text = try file.readToEndAlloc(allocator, comptime 1 << 30);
    defer allocator.free(text);

    var grid = try Grid.parse(allocator, text);
    defer grid.deinit();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("{d}\n", .{try part1(allocator, grid)});
    try bw.flush();
}

fn part1(allocator: Allocator, grid: Grid) !u64 {
    var nodes = std.AutoHashMap(u8, aoc.AutoHashSet(Pos)).init(allocator);
    defer nodes.deinit();
    defer {
        var it = nodes.valueIterator();
        while (it.next()) |v| {
            v.deinit();
        }
    }

    {
        var it = grid.iterator();
        while (it.next()) |mapEntry| {
            const pos = mapEntry.key_ptr.*;
            const id = mapEntry.value_ptr.*;
            if (id == '.') {
                continue;
            }

            var nodeEntry = try nodes.getOrPut(id);
            if (!nodeEntry.found_existing) {
                nodeEntry.value_ptr.* = aoc.AutoHashSet(Pos).init(allocator);
            }
            try nodeEntry.value_ptr.put(pos);
        }
    }

    var antinodes = aoc.AutoHashSet(Pos).init(allocator);
    defer antinodes.deinit();

    var it = nodes.valueIterator();
    while (it.next()) |nodeSet| {
        var aa = nodeSet.iterator();
        while (aa.next()) |a| {
            var bb = nodeSet.iterator();
            while (bb.next()) |b| {
                if (a == b) {
                    continue;
                }

                const d = a.distance(b.*);
                const pos = a.add(.{
                    .dr = 2 * d.dr,
                    .dc = 2 * d.dc,
                });
                if (grid.inBounds(pos)) {
                    try antinodes.put(pos);
                }
            }
        }
    }

    return antinodes.count();
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

const Delta = struct {
    dr: i32,
    dc: i32,
};

const Grid = struct {
    const Map = std.AutoHashMap(Pos, u8);

    map: Map,
    max: Pos,

    fn parse(allocator: std.mem.Allocator, text: []const u8) !Grid {
        var map = Map.init(allocator);
        var max = Pos{ .r = 0, .c = 0 };

        var it = std.mem.tokenizeScalar(u8, text, '\n');
        var r: usize = 0;
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
