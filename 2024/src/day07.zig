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

    var equations = try Equation.parseAll(allocator, text);
    defer equations.deinit();
    defer {
        for (equations.items) |*eqn| eqn.deinit();
    }

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("{d}\n", .{try part1(allocator, equations.items)});
    try bw.flush();
}

const Operator = enum {
    Plus,
    Times,

    fn eval(self: Operator, a: u64, b: u64) u64 {
        return switch (self) {
            .Plus => a + b,
            .Times => a * b,
        };
    }
};

const Operators = ArrayList(Operator);

const Equation = struct {
    value: u64,
    operands: ArrayList(u64),

    const Self = @This();

    fn deinit(self: *Self) void {
        self.operands.deinit();
    }

    fn parse(allocator: Allocator, line: []const u8) !Self {
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

    fn parseAll(allocator: Allocator, text: []const u8) !ArrayList(Self) {
        var all = ArrayList(Self).init(allocator);

        var it = std.mem.tokenizeScalar(u8, text, '\n');
        while (it.next()) |line| {
            const eqn = try Self.parse(allocator, line);
            try all.append(eqn);
        }

        return all;
    }

    fn eval(self: Self, operators: ArrayList(Operator)) u64 {
        var v = self.operands.items[0];
        for (self.operands.items[1..], operators.items) |n, op| {
            v = op.eval(v, n);
        }
        return v;
    }

    fn solvable(self: Self, allocator: Allocator) !bool {
        var stack = ArrayList(Operators).init(allocator);
        defer stack.deinit();
        defer {
            for (stack.items) |ops| ops.deinit();
        }

        try stack.append(Operators.init(allocator));

        while (stack.popOrNull()) |ops| {
            defer ops.deinit();

            if (ops.items.len == self.operands.items.len - 1) {
                if (self.eval(ops) == self.value) {
                    return true;
                }
                continue;
            }

            var plus = try ops.clone();
            try plus.append(Operator.Plus);
            try stack.append(plus);

            var times = try ops.clone();
            try times.append(Operator.Times);
            try stack.append(times);
        }

        return false;
    }
};

fn part1(allocator: Allocator, equations: []Equation) !u64 {
    var sum: u64 = 0;
    for (equations) |eqn| {
        if (try eqn.solvable(allocator)) {
            sum += eqn.value;
        }
    }
    return sum;
}
