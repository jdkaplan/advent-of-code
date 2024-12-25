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

    const text = try aoc.readAll(allocator, "input/day21.txt");
    defer allocator.free(text);

    const codes = try aoc.splitAll(allocator, text, "\n");
    defer codes.deinit();

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = bw.writer();

    try stdout.print("{}\n", .{try part1(allocator, codes.items)});
    try bw.flush();

    try stdout.print("{}\n", .{try part2(allocator, codes.items)});
    try bw.flush();
}

const String = []const u8;

fn part1(allocator: Allocator, codes: []String) !u64 {
    var sum: u64 = 0;
    for (codes) |code| {
        const presses = try solve1(allocator, code);

        sum += complexity(code, @intCast(presses));
    }
    return sum;
}

fn complexity(code: String, presses: u64) u64 {
    const a, const n = takeInt(code).?;
    if (!std.mem.eql(u8, a, "A")) unreachable;

    return n * presses;
}

fn takeInt(input: []const u8) ?struct { []const u8, u64 } {
    var i: usize = 0;
    var n: u64 = 0;

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

fn solve1(allocator: Allocator, code: String) !usize {
    // Step 0: The actual passcode (numpad)
    var digits = List(Numpad).init(allocator);
    defer digits.deinit();
    for (code) |c| try digits.append(Numpad.parse(c));

    var total: usize = 0;
    var start = Numpad.a;
    for (digits.items) |next| {
        total += try digitCost1(allocator, start, next);
        start = next;
    }
    return total;
}

fn digitCost1(allocator: Allocator, start: Numpad, end: Numpad) !usize {
    var best: usize = std.math.maxInt(usize);
    const digits = [_]Numpad{end};

    // Step 1: Depressurized (dpad)
    var robot1 = try numpadToDpad(allocator, digits[0..], start);
    defer robot1.deinit();
    while (try robot1.next()) |r1| {
        defer r1.deinit();

        // Step 2: High radiation (dpad)
        var robot2 = try dpadToDpad(allocator, r1.items, Dpad.a);
        defer robot2.deinit();
        while (try robot2.next()) |r2| {
            defer r2.deinit();

            // Step 3: Very cold (dpad)
            var robot3 = try dpadToDpad(allocator, r2.items, Dpad.a);
            defer robot3.deinit();
            while (try robot3.next()) |r3| {
                defer r3.deinit();

                // Step 4: Direct manipulation (no cost!)
                if (r3.items.len < best) {
                    best = r3.items.len;
                }
            }
        }
    }

    return best;
}

fn part2(allocator: Allocator, codes: []String) !u64 {
    var sum: u64 = 0;
    for (codes) |code| {
        const presses = try solve2(allocator, code);

        sum += complexity(code, @intCast(presses));
    }
    return sum;
}

fn solve2(allocator: Allocator, code: String) !usize {
    // Step 0: The actual passcode (numpad)
    var digits = List(Numpad).init(allocator);
    defer digits.deinit();
    for (code) |c| try digits.append(Numpad.parse(c));

    var total: usize = 0;
    var start = Numpad.a;
    for (digits.items) |next| {
        total += try digitCost2(allocator, start, next);
        start = next;
    }
    return total;
}

fn digitCost2(allocator: Allocator, start: Numpad, end: Numpad) !usize {
    var memo = Map(MemoState, usize).init(allocator);
    defer memo.deinit();

    // One (1) numpad that a robot is using
    var nums = try numpadToDpad(allocator, &[_]Numpad{end}, start);
    defer nums.deinit();

    var best: usize = std.math.maxInt(usize);
    while (try nums.next()) |path| {
        defer path.deinit();

        var cost: usize = 0;
        var prev = Dpad.a;
        for (path.items) |button| {
            // Twenty-five (25) dpads that robots are using
            cost += try costMemo(allocator, prev, button, 25, &memo);
            prev = button;
        }
        best = @min(best, cost);
    }

    return best;
}

const MemoState = struct {
    depth: usize,
    start: Dpad,
    button: Dpad,
};

fn costMemo(allocator: Allocator, start: Dpad, button: Dpad, depth: usize, memo: *Map(MemoState, usize)) !usize {
    if (depth == 0) {
        return 1;
    }

    const state = MemoState{
        .depth = depth,
        .start = start,
        .button = button,
    };

    if (memo.get(state)) |cost| {
        return cost;
    }

    var paths = try dpadToDpad(allocator, &[_]Dpad{button}, start);
    defer paths.deinit();

    var best: usize = std.math.maxInt(usize);
    while (try paths.next()) |path| {
        defer path.deinit();

        var cost: usize = 0;
        var prev = Dpad.a;
        for (path.items) |btn| {
            cost += try costMemo(allocator, prev, btn, depth - 1, memo);
            prev = btn;
        }

        best = @min(best, cost);
    }

    try memo.put(state, best);
    return best;
}

fn numpadToDpad(allocator: Allocator, output: []const Numpad, start: Numpad) !ButtonIterator(Numpad, Dpad) {
    return try ButtonIterator(Numpad, Dpad).init(allocator, output, start);
}

fn dpadToDpad(allocator: Allocator, output: []const Dpad, start: Dpad) !ButtonIterator(Dpad, Dpad) {
    return try ButtonIterator(Dpad, Dpad).init(allocator, output, start);
}

fn ButtonIterator(comptime Target: type, comptime Input: type) type {
    return struct {
        allocator: Allocator,
        stack: List(State),

        const Self = @This();
        const State = struct {
            prev: Target,
            buttons: []const Target,
            inputs: List(Input),

            fn deinit(self: *State) void {
                self.inputs.deinit();
            }
        };

        fn init(allocator: Allocator, buttons: []const Target, start: Target) !Self {
            var stack = List(State).init(allocator);
            try stack.append(State{
                .prev = start,
                .buttons = buttons,
                .inputs = List(Input).init(allocator),
            });

            return Self{
                .allocator = allocator,
                .stack = stack,
            };
        }

        fn deinit(self: *Self) void {
            for (self.stack.items) |*s| s.deinit();
            self.stack.deinit();
        }

        fn next(self: *Self) !?List(Input) {
            while (self.stack.popOrNull()) |state| {
                const buttons, var inputs = .{ state.buttons, state.inputs };

                if (buttons.len == 0) {
                    return inputs;
                }

                defer inputs.deinit();

                const start = state.prev;
                const btn = buttons[0];
                const delta = btn.pos().sub(start.pos());

                var moves = try arrows(self.allocator, delta);
                defer moves.deinit();
                while (try moves.next()) |inp| {
                    defer inp.deinit();

                    var ii = try inputs.clone();
                    // Move to button (arrows)
                    var pos = start.pos();
                    for (inp.items) |i| {
                        pos = pos.add(i.delta());
                        if (!Target.valid(pos)) {
                            ii.deinit();
                            break;
                        }
                        try ii.append(i);
                    } else {
                        // Press button (A)
                        try ii.append(Input.a);

                        try self.stack.append(State{
                            .prev = btn,
                            .buttons = buttons[1..],
                            .inputs = ii,
                        });
                    }
                }
            }
            return null;
        }
    };
}

fn arrows(allocator: Allocator, delta: Delta) !MovesIterator {
    return try MovesIterator.init(allocator, delta);
}

const MovesIterator = struct {
    allocator: Allocator,
    stack: List(State),

    const Self = @This();
    const State = struct {
        delta: Delta,
        moves: List(Dpad),

        fn deinit(self: *State) void {
            self.moves.deinit();
        }
    };

    fn init(allocator: Allocator, delta: Delta) !Self {
        var stack = List(State).init(allocator);
        try stack.append(State{
            .delta = delta,
            .moves = List(Dpad).init(allocator),
        });

        return Self{
            .allocator = allocator,
            .stack = stack,
        };
    }

    fn deinit(self: *Self) void {
        for (self.stack.items) |*s| s.deinit();
        self.stack.deinit();
    }

    fn next(self: *Self) !?List(Dpad) {
        while (self.stack.popOrNull()) |state| {
            const delta, var moves = .{ state.delta, state.moves };
            const dr, const dc = .{ delta.dr, delta.dc };

            if (dr == 0 and dc == 0) {
                return moves;
            }

            defer moves.deinit();

            if (dr < 0) {
                var m = try moves.clone();
                try appendMulti(Dpad, &m, Dpad.up, @intCast(@abs(dr)));

                try self.stack.append(State{
                    .delta = Delta.new(0, dc),
                    .moves = m,
                });
            }

            if (dr > 0) {
                var m = try moves.clone();
                try appendMulti(Dpad, &m, Dpad.down, @intCast(@abs(dr)));

                try self.stack.append(State{
                    .delta = Delta.new(0, dc),
                    .moves = m,
                });
            }

            if (dc < 0) {
                var m = try moves.clone();
                try appendMulti(Dpad, &m, Dpad.left, @intCast(@abs(dc)));

                try self.stack.append(State{
                    .delta = Delta.new(dr, 0),
                    .moves = m,
                });
            }

            if (dc > 0) {
                var m = try moves.clone();
                try appendMulti(Dpad, &m, Dpad.right, @intCast(@abs(dc)));

                try self.stack.append(State{
                    .delta = Delta.new(dr, 0),
                    .moves = m,
                });
            }
        }
        return null;
    }
};

fn appendMulti(comptime T: type, l: *List(T), elt: T, n: usize) !void {
    for (0..n) |_| {
        try l.append(elt);
    }
}

const Numpad = enum {
    one,
    two,
    three,
    four,
    five,
    six,
    seven,
    eight,
    nine,
    zero,
    a,

    const Self = @This();

    fn pos(self: Self) Pos {
        return switch (self) {
            .seven => Pos.new(0, 0),
            .eight => Pos.new(0, 1),
            .nine => Pos.new(0, 2),
            .four => Pos.new(1, 0),
            .five => Pos.new(1, 1),
            .six => Pos.new(1, 2),
            .one => Pos.new(2, 0),
            .two => Pos.new(2, 1),
            .three => Pos.new(2, 2),
            // empty at (3, 0)
            .zero => Pos.new(3, 1),
            .a => Pos.new(3, 2),
        };
    }

    fn valid(p: Pos) bool {
        return !(p.r == 3 and p.c == 0);
    }

    fn parse(c: u8) Self {
        return switch (c) {
            '1' => .one,
            '2' => .two,
            '3' => .three,
            '4' => .four,
            '5' => .five,
            '6' => .six,
            '7' => .seven,
            '8' => .eight,
            '9' => .nine,
            '0' => .zero,
            'A' => .a,
            else => unreachable,
        };
    }

    pub fn format(
        self: Numpad,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        const c: u8 = switch (self) {
            .one => '1',
            .two => '2',
            .three => '3',
            .four => '4',
            .five => '5',
            .six => '6',
            .seven => '7',
            .eight => '8',
            .nine => '9',
            .zero => '0',
            .a => 'A',
        };
        try writer.print("{c}", .{c});
    }
};

const Dpad = enum {
    up,
    down,
    left,
    right,
    a,

    pub fn pos(self: Dpad) Pos {
        return switch (self) {
            // empty at (0, 0)
            .up => Pos.new(0, 1),
            .a => Pos.new(0, 2),
            .left => Pos.new(1, 0),
            .down => Pos.new(1, 1),
            .right => Pos.new(1, 2),
        };
    }

    fn valid(p: Pos) bool {
        return !(p.r == 0 and p.c == 0);
    }

    pub fn delta(self: Dpad) Delta {
        return switch (self) {
            .up => Delta.new(-1, 0),
            .down => Delta.new(1, 0),
            .left => Delta.new(0, -1),
            .right => Delta.new(0, 1),
            .a => Delta.new(0, 0),
        };
    }

    pub fn format(
        self: Dpad,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        const c: u8 = switch (self) {
            .up => '^',
            .down => 'v',
            .left => '<',
            .right => '>',
            .a => 'A',
        };
        try writer.print("{c}", .{c});
    }
};

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

    fn sub(self: Pos, other: Pos) Delta {
        return .{
            .dr = self.r - other.r,
            .dc = self.c - other.c,
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

const Delta = struct {
    dr: i32,
    dc: i32,

    fn new(dr: i32, dc: i32) Delta {
        return Delta{ .dr = dr, .dc = dc };
    }
};
