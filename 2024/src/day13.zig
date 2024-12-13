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

    const text = try aoc.readAll(allocator, "input/day13.txt");
    defer allocator.free(text);

    var games = try Game.parseAll(allocator, text);
    defer games.deinit();

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = bw.writer();

    try stdout.print("{d}\n", .{try part1(games.items)});
    try bw.flush();
}

fn part1(games: []const Game) !i64 {
    var total: i64 = 0;
    for (games) |game| {
        const buttons = game.solve() orelse continue;
        const cost = 3 * buttons.a + 1 * buttons.b;
        total += cost;
    }
    return total;
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

const Game = struct {
    a: Move,
    b: Move,
    prize: Pos,

    fn parse(block: []const u8) Game {
        var lines = std.mem.tokenizeScalar(u8, block, '\n');
        var line: []const u8 = undefined;

        const a = v: {
            line = lines.next().?;
            line = takeLiteral(line, "Button A: X+").?;
            line, const dx = takeInt(line).?;
            line = takeLiteral(line, ", Y+").?;
            line, const dy = takeInt(line).?;
            if (line.len != 0) unreachable;
            break :v Move.new(dx, dy);
        };

        const b = v: {
            line = lines.next().?;
            line = takeLiteral(line, "Button B: X+").?;
            line, const dx = takeInt(line).?;
            line = takeLiteral(line, ", Y+").?;
            line, const dy = takeInt(line).?;
            if (line.len != 0) unreachable;
            break :v Move.new(dx, dy);
        };

        const prize = prize: {
            line = lines.next().?;
            line = takeLiteral(line, "Prize: X=").?;
            line, const x = takeInt(line).?;
            line = takeLiteral(line, ", Y=").?;
            line, const y = takeInt(line).?;
            if (line.len != 0) unreachable;
            break :prize Pos.new(x, y);
        };

        return Game{ .a = a, .b = b, .prize = prize };
    }

    fn parseAll(allocator: Allocator, text: []const u8) !List(Game) {
        var games = List(Game).init(allocator);
        var it = std.mem.tokenizeSequence(u8, text, "\n\n");
        while (it.next()) |block| {
            try games.append(Game.parse(block));
        }
        return games;
    }

    pub fn format(
        self: Game,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("A={} B={} Prize={}", .{ self.a, self.b, self.prize });
    }

    const Solution = struct { a: i64, b: i64 };

    fn solve(
        self: Game,
    ) ?Solution {
        // [ dx_A dx_B ] [ n_A ] = [ px ]
        // [ dy_A dy_B ] [ n_B ] = [ py ]

        const det = self.a.dx * self.b.dy - self.b.dx * self.a.dy;
        if (det == 0) {
            return null;
        }

        // [ n_A ] = [  dy_B -dx_B ] [ px ]
        // [ n_B ] = [ -dy_A  dx_A ] [ py ]

        const nA: i64 = std.math.divExact(i64, self.b.dy * self.prize.x - self.b.dx * self.prize.y, det) catch return null;
        const nB: i64 = std.math.divExact(i64, self.a.dx * self.prize.y - self.a.dy * self.prize.x, det) catch return null;

        return Solution{
            .a = @intCast(nA),
            .b = @intCast(nB),
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
    while (i < input.len and std.ascii.isDigit(input[i])) : (i += 1) {
        n *= 10;
        n += input[i] - '0';
    }

    if (i == 0) {
        // Nothing consumed
        return null;
    }
    return .{ input[i..], n };
}
