const std = @import("std");
const aoc = @import("aoc.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("input/day07.txt", .{});
    defer file.close();

    const text = try file.readToEndAlloc(allocator, comptime 1 << 30);
    defer allocator.free(text);

    var equations = try aoc.parseAll(Equation, allocator, text, "\n");
    defer equations.deinit();
    defer {
        for (equations.items) |*eqn| eqn.deinit();
    }

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("{d}\n", .{try part1(allocator, equations.items)});
    try bw.flush();

    try stdout.print("{d}\n", .{try part2(allocator, equations.items)});
    try bw.flush();
}

fn part1(allocator: Allocator, equations: []Equation) !u64 {
    var sum: u64 = 0;
    for (equations) |eqn| {
        if (try eqn.solvable(allocator, &[_]Operator{ .Plus, .Times })) {
            sum += eqn.value;
        }
    }
    return sum;
}

fn part2(allocator: Allocator, equations: []Equation) !u64 {
    var sum: u64 = 0;
    for (equations) |eqn| {
        const ops1 = &[_]Operator{ .Plus, .Times };
        const ops2 = &[_]Operator{ .Plus, .Times, .Concat };
        if (try eqn.solvable(allocator, ops1) or try eqn.solvable(allocator, ops2)) {
            sum += eqn.value;
        }
    }
    return sum;
}

const Operator = enum {
    Plus,
    Times,
    Concat,

    fn eval(self: Operator, a: u64, b: u64) u64 {
        const pow = std.math.pow;
        const log = std.math.log;

        return switch (self) {
            .Plus => a + b,
            .Times => a * b,
            .Concat => (a * pow(u64, 10, 1 + log(u64, 10, b))) + b,
        };
    }
};

test "Operator.Concat" {
    const expect = std.testing.expect;

    const cases = [_]struct { u64, u64, u64 }{
        .{ 15, 6, 156 },
        .{ 100, 23, 10023 },
    };

    for (cases) |case| {
        const a, const b, const expected = .{ case[0], case[1], case[2] };
        const actual = Operator.Concat.eval(a, b);
        // std.debug.print("{}\n", .{actual});
        try expect(actual == expected);
    }
}

const Equation = struct {
    value: u64,
    operands: ArrayList(u64),

    const Self = @This();

    fn deinit(self: *Self) void {
        self.operands.deinit();
    }

    pub fn parse(allocator: Allocator, line: []const u8) !Self {
        const value, const rest = a: {
            var it = std.mem.splitSequence(u8, line, ": ");
            const value = try std.fmt.parseInt(u64, it.next().?, 10);
            break :a .{ value, it.rest() };
        };

        const operands = a: {
            var operands = std.ArrayList(u64).init(allocator);
            var it = std.mem.tokenizeScalar(u8, rest, ' ');
            while (it.next()) |num| {
                const n = try std.fmt.parseInt(u64, num, 10);
                try operands.append(n);
            }
            break :a operands;
        };

        return .{ .value = value, .operands = operands };
    }

    fn solvable(self: Self, allocator: Allocator, operators: []const Operator) !bool {
        const State = struct {
            partial: u64,
            operands: []u64,
        };

        var stack = ArrayList(State).init(allocator);
        defer stack.deinit();

        try stack.append(State{
            .partial = self.operands.items[0],
            .operands = self.operands.items[1..],
        });

        while (stack.popOrNull()) |state| {
            if (state.operands.len == 0) {
                if (state.partial == self.value) {
                    return true;
                }
                continue;
            }

            for (operators) |op| {
                try stack.append(State{
                    .partial = op.eval(state.partial, state.operands[0]),
                    .operands = state.operands[1..],
                });
            }
        }

        return false;
    }
};
