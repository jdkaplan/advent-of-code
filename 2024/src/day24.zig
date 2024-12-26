const std = @import("std");
const aoc = @import("aoc.zig");

const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StringMap = std.StringHashMap;
const Set = aoc.AutoHashSet;
const PriorityQueue = std.PriorityQueue;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const text = try aoc.readAll(allocator, "input/day24.txt");
    defer allocator.free(text);

    var blocks = std.mem.tokenizeSequence(u8, text, "\n\n");

    var inputs = try aoc.parseAll(Input, allocator, blocks.next().?, "\n");
    defer inputs.deinit();

    var gates = try aoc.parseAll(Gate, allocator, blocks.next().?, "\n");
    defer gates.deinit();

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = bw.writer();

    try stdout.print("{}\n", .{try part1(allocator, inputs.items, gates.items)});
    try bw.flush();
}

const String = []const u8;

const Input = struct {
    name: String,
    value: u1,

    pub fn parse(_: Allocator, line: String) !Input {
        var fields = std.mem.tokenizeSequence(u8, line, ": ");
        const name = fields.next().?;
        const value = try std.fmt.parseInt(u1, fields.next().?, 10);

        return Input{
            .name = name,
            .value = value,
        };
    }
};

const Gate = struct {
    a: String,
    b: String,
    out: String,
    op: Op,

    pub fn parse(_: Allocator, line: String) !Gate {
        var fields = std.mem.tokenizeSequence(u8, line, " ");
        const a = fields.next().?;
        const op = fields.next().?;
        const b = fields.next().?;
        if (!std.mem.eql(u8, fields.next().?, "->")) unreachable;
        const out = fields.next().?;

        return Gate{
            .a = a,
            .b = b,
            .out = out,
            .op = Op.parse(op).?,
        };
    }
};

const Op = enum {
    And,
    Or,
    Xor,

    fn parse(s: String) ?Op {
        const eql = std.mem.eql;
        if (eql(u8, "AND", s)) return Op.And;
        if (eql(u8, "OR", s)) return Op.Or;
        if (eql(u8, "XOR", s)) return Op.Xor;
        return null;
    }

    fn eval(self: Op, a: u1, b: u1) u1 {
        return switch (self) {
            .And => a & b,
            .Or => a | b,
            .Xor => a ^ b,
        };
    }
};

fn part1(allocator: Allocator, inputs: []const Input, gates: []const Gate) !u64 {
    var values = StringMap(u1).init(allocator);
    defer values.deinit();

    for (inputs) |i| {
        try values.put(i.name, i.value);
    }

    var pending = List(Gate).init(allocator);
    try pending.appendSlice(gates);

    while (pending.items.len > 0) {
        var next = List(Gate).init(allocator);
        for (pending.items) |g| {
            if (values.contains(g.a) and values.contains(g.b)) {
                const a = values.get(g.a).?;
                const b = values.get(g.b).?;
                try values.put(g.out, g.op.eval(a, b));
            } else {
                try next.append(g);
            }
        }
        pending.deinit();
        pending = next;
    }

    var outputs = List(String).init(allocator);
    defer outputs.deinit();
    {
        var it = values.keyIterator();
        while (it.next()) |k| {
            const name = k.*;
            if (name[0] == 'z') {
                try outputs.append(name);
            }
        }
    }
    std.mem.sort(String, outputs.items, {}, gtString);

    var n: u64 = 0;
    for (outputs.items) |z| {
        const v = values.get(z).?;

        n <<= 1;
        n += v;
    }
    return n;
}

fn gtString(_: void, a: String, b: String) bool {
    return std.mem.lessThan(u8, b, a);
}
