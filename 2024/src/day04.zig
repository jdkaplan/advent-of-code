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

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("{d}\n", .{try part1(allocator, text)});
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

fn part1(allocator: Allocator, text: []u8) !usize {
    var grid = std.AutoHashMap(Coord, u8).init(allocator);
    defer grid.deinit();

    {
        var it = std.mem.tokenizeScalar(u8, text, '\n');
        var r: usize = 0;
        while (it.next()) |row| : (r += 1) {
            for (row, 0..) |char, c| {
                try grid.put(.{ .r = @intCast(r), .c = @intCast(c) }, char);
            }
        }
    }

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
