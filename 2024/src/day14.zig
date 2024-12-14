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

    const text = try aoc.readAll(allocator, "input/day14.txt");
    defer allocator.free(text);

    const floor = Pos{ .x = 101, .y = 103 };

    var robots = try aoc.parseAll(Robot, allocator, text, "\n");
    defer robots.deinit();

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = bw.writer();

    try stdout.print("{d}\n", .{part1(robots.items, floor)});
    try bw.flush();

    try stdout.print("{d}\n", .{try part2(allocator, robots.items, floor)});
    try bw.flush();
}

fn part1(robots: []const Robot, floor: Pos) i64 {
    return safetyScore(robots, floor, 100);
}

fn safetyScore(robots: []const Robot, floor: Pos, ticks: i64) i64 {
    var quadrants = [4]i64{ 0, 0, 0, 0 };
    for (robots) |robot| {
        const pos = robot.simulate(floor, ticks);
        if (pos.quadrant(floor)) |q| {
            quadrants[q] += 1;
        }
    }

    var safety: i64 = 1;
    for (quadrants) |n| {
        safety *= n;
    }
    return safety;
}

fn part2(allocator: Allocator, robots: []const Robot, floor: Pos) !i64 {
    var best: i64 = std.math.maxInt(i64);
    var tick: i64 = 0;
    while (tick < floor.x * floor.y) : (tick += 1) {
        const safety = safetyScore(robots, floor, tick);
        if (safety < best) {
            best = safety;

            var points = Set(Pos).init(allocator);
            defer points.deinit();
            for (robots) |robot| {
                const pos = robot.simulate(floor, tick);
                try points.put(pos);
            }

            if (try wasChristmasTree(floor, points)) {
                return tick;
            }
        }
    }
    return 0;
}

fn wasChristmasTree(floor: Pos, points: Set(Pos)) !bool {
    std.debug.print("\x1B[2J\x1B[H", .{});
    for (0..@intCast(floor.y + 1)) |y| {
        for (0..@intCast(floor.x + 1)) |x| {
            const pos = Pos{
                .x = @intCast(x),
                .y = @intCast(y),
            };
            if (points.contains(pos)) {
                std.debug.print("█", .{});
            } else {
                std.debug.print(" ", .{});
            }
        }
        std.debug.print("\n", .{});
    }

    const stdin = std.io.getStdIn();
    var buf: [32]u8 = undefined;
    const ans = (try stdin.reader().readUntilDelimiterOrEof(&buf, '\n')) orelse "";
    return ans.len > 0 and ans[0] == 'y';
}

const Pos = struct {
    x: i64,
    y: i64,

    fn new(x: i64, y: i64) Pos {
        return Pos{ .x = x, .y = y };
    }

    fn add(self: Pos, move: Move) Pos {
        return Pos{
            .x = self.x + move.dx,
            .y = self.y + move.dy,
        };
    }

    fn quadrant(self: Pos, floor: Pos) ?usize {
        const x, const y = .{ self.x, self.y };

        const zx = @divTrunc(floor.x, 2);
        const zy = @divTrunc(floor.y, 2);

        if (x > zx and y > zy) {
            return 0;
        } else if (x < zx and y > zy) {
            return 1;
        } else if (x < zx and y < zy) {
            return 2;
        } else if (x > zx and y < zy) {
            return 3;
        } else {
            return null;
        }
    }

    pub fn format(
        self: Pos,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("({}, {})", .{ self.x, self.y });
    }
};

const Move = struct {
    dx: i64,
    dy: i64,

    fn new(dx: i64, dy: i64) Move {
        return Move{ .dx = dx, .dy = dy };
    }

    pub fn format(
        self: Move,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("({}, {})", .{ self.dx, self.dy });
    }
};

const ParseError = error{ExtraText};

const Robot = struct {
    pos: Pos,
    vel: Move,

    const Self = @This();

    pub fn parse(_: Allocator, text: []const u8) !Self {
        var line = text;
        const pos = v: {
            line = takeLiteral(line, "p=").?;
            line, const x = takeInt(line).?;
            line = takeLiteral(line, ",").?;
            line, const y = takeInt(line).?;
            break :v Pos.new(x, y);
        };

        line = takeLiteral(line, " ").?;

        const vel = v: {
            line = takeLiteral(line, "v=").?;
            line, const dx = takeInt(line).?;
            line = takeLiteral(line, ",").?;
            line, const dy = takeInt(line).?;
            break :v Move.new(dx, dy);
        };

        if (line.len != 0) {
            return error.ExtraText;
        }

        return Self{ .pos = pos, .vel = vel };
    }

    pub fn format(
        self: Self,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("Pos={} Vel={}", .{ self.pos, self.vel });
    }

    fn simulate(self: Self, floor: Pos, ticks: i64) Pos {
        const w, const h = .{ floor.x, floor.y };
        const x, const y = .{ self.pos.x, self.pos.y };
        const dx, const dy = .{ self.vel.dx, self.vel.dy };

        return Pos{
            .x = @mod(x + ticks * dx, w),
            .y = @mod(y + ticks * dy, h),
        };
    }
};

fn takeLiteral(input: []const u8, want: []const u8) ?[]const u8 {
    if (std.mem.startsWith(u8, input, want)) {
        return input[want.len..];
    }
    return null;
}

fn takeInt(input: []const u8) ?struct { []const u8, i64 } {
    var i: usize = 0;
    var n: i64 = 0;
    var neg = false;

    if (i < input.len and input[i] == '-') {
        neg = true;
        i += 1;
    }

    while (i < input.len and std.ascii.isDigit(input[i])) : (i += 1) {
        n *= 10;
        n += input[i] - '0';
    }

    if (i == 0) {
        // Nothing consumed
        return null;
    }

    if (neg) {
        n = -n;
    }
    return .{ input[i..], n };
}
