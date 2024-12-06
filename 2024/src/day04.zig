const std = @import("std");
const aoc = @import("aoc.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("input/day04.txt", .{});
    defer file.close();

    const text = try file.readToEndAlloc(allocator, comptime 1 << 30);
    defer allocator.free(text);

    var grid = try Grid.parse(allocator, text);
    defer grid.deinit();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("{d}\n", .{try part1(grid)});
    try bw.flush();

    try stdout.print("{d}\n", .{try part2(grid)});
    try bw.flush();
}

const Coord = struct {
    r: i32,
    c: i32,

    fn move(self: Coord, dir: Direction) Coord {
        const d = dir.delta();
        return .{ .r = self.r + d.dr, .c = self.c + d.dc };
    }
};

const Delta = struct { dr: i32, dc: i32 };

const Direction = enum {
    N,
    E,
    S,
    W,

    NE,
    SE,
    SW,
    NW,

    fn delta(self: Direction) Delta {
        return switch (self) {
            // zig fmt: off
            .N  => .{ .dr = -1, .dc =  0 },
            .E  => .{ .dr =  0, .dc =  1 },
            .S  => .{ .dr =  1, .dc =  0 },
            .W  => .{ .dr =  0, .dc = -1 },

            .NE => .{ .dr = -1, .dc =  1 },
            .SE => .{ .dr =  1, .dc =  1 },
            .SW => .{ .dr =  1, .dc = -1 },
            .NW => .{ .dr = -1, .dc = -1 },
            // zig fmt: on
        };
    }
};

const Grid = struct {
    const Map = std.AutoHashMap(Coord, u8);

    map: Map,

    fn parse(allocator: std.mem.Allocator, text: []u8) !Grid {
        var map = Map.init(allocator);

        var it = std.mem.tokenizeScalar(u8, text, '\n');
        var r: usize = 0;
        while (it.next()) |row| : (r += 1) {
            for (row, 0..) |char, c| {
                try map.put(.{ .r = @intCast(r), .c = @intCast(c) }, char);
            }
        }

        return .{ .map = map };
    }

    fn deinit(self: *Grid) void {
        self.map.deinit();
    }

    fn iterator(self: *const Grid) Map.Iterator {
        return self.map.iterator();
    }

    fn get(self: *const Grid, k: Coord) ?u8 {
        return self.map.get(k);
    }
};

fn part1(grid: Grid) !usize {
    var count: usize = 0;
    var it = grid.iterator();
    while (it.next()) |entry| {
        const v = entry.value_ptr.*;
        if (v != 'X') {
            continue;
        }

        for (std.enums.values(Direction)) |dir| {
            var p = entry.key_ptr.*;
            for ("MAS") |c| {
                p = p.move(dir);
                if (grid.get(p) != c) {
                    break;
                }
            } else {
                count += 1;
            }
        }
    }

    return count;
}

fn part2(grid: Grid) !usize {
    var count: usize = 0;
    var it = grid.iterator();
    while (it.next()) |entry| {
        const v = entry.value_ptr.*;
        if (v != 'A') {
            continue;
        }

        var a = entry.key_ptr.*;

        const nw = grid.get(a.move(Direction.NW)) orelse continue;
        const se = grid.get(a.move(Direction.SE)) orelse continue;

        const sw = grid.get(a.move(Direction.SW)) orelse continue;
        const ne = grid.get(a.move(Direction.NE)) orelse continue;

        if (is_mas(nw, se) and is_mas(sw, ne)) {
            count += 1;
        }
    }

    return count;
}

fn is_mas(x: u8, y: u8) bool {
    return (x == 'M' and y == 'S') or (y == 'M' and x == 'S');
}
