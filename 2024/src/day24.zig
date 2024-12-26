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

    const text2 = try aoc.readAll(allocator, "input/day24_swaps.txt");
    defer allocator.free(text2);
    const swaps = try aoc.parseAll(Swap, allocator, text2, "\n");
    defer swaps.deinit();

    var blocks = std.mem.tokenizeSequence(u8, text, "\n\n");

    var inputs = try aoc.parseAll(Input, allocator, blocks.next().?, "\n");
    defer inputs.deinit();

    var gates = try aoc.parseAll(Gate, allocator, blocks.next().?, "\n");
    defer gates.deinit();

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = bw.writer();

    try stdout.print("{}\n", .{try part1(allocator, inputs.items, gates.items)});
    try bw.flush();

    var wires = try part2(allocator, gates.items, swaps.items);
    defer wires.deinit();

    try stdout.print("{s}\n", .{wires.items});
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

const Swap = struct {
    a: String,
    b: String,

    pub fn parse(_: Allocator, line: String) !Swap {
        var fields = std.mem.tokenizeSequence(u8, line, " ");
        const a = fields.next().?;
        const b = fields.next().?;
        return Swap{
            .a = a,
            .b = b,
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
        var a = fields.next().?;
        const op = fields.next().?;
        var b = fields.next().?;
        if (!std.mem.eql(u8, fields.next().?, "->")) unreachable;
        const out = fields.next().?;

        if (std.mem.lessThan(u8, b, a)) {
            const t = a;
            a = b;
            b = t;
        }

        return Gate{
            .a = a,
            .b = b,
            .out = out,
            .op = Op.parse(op).?,
        };
    }

    pub fn format(
        self: Gate,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("{s} {s} {s} -> {s}", .{ self.a, self.op, self.b, self.out });
    }

    fn hasInputs(self: Gate, a: String, b: String) bool {
        return (streq(self.a, a) and streq(self.b, b)) or (streq(self.a, b) and streq(self.b, a));
    }

    fn hasOutput(self: Gate, out: String) bool {
        return streq(self.out, out);
    }

    fn mustOutput(self: Gate, out: String) Gate {
        if (self.hasOutput(out)) {
            return self;
        }
        std.debug.print("want: {s}, got: {s}\n", .{ out, self.out });
        unreachable;
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

    pub fn format(
        self: Op,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        const s = switch (self) {
            .And => "AND",
            .Or => "_OR",
            .Xor => "XOR",
        };
        try writer.print("{s}", .{s});
    }
};

fn part1(allocator: Allocator, inputs: []const Input, gates: []const Gate) !u64 {
    var values = try eval(allocator, gates, inputs);
    defer values.deinit();

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
    if (outputs.items.len != 46) unreachable;

    var n: u64 = 0;
    for (outputs.items) |z| {
        const v = values.get(z).?;

        n <<= 1;
        n += v;
    }
    return n;
}

fn eval(allocator: Allocator, gates: []const Gate, inputs: []const Input) !StringMap(u1) {
    var values = StringMap(u1).init(allocator);
    for (inputs) |i| {
        try values.put(i.name, i.value);
    }

    var pending = List(Gate).init(allocator);
    try pending.appendSlice(gates);

    while (pending.items.len > 0) {
        var next = List(Gate).init(allocator);
        var changed = false;
        for (pending.items) |g| {
            if (values.contains(g.a) and values.contains(g.b)) {
                const a = values.get(g.a).?;
                const b = values.get(g.b).?;
                try values.put(g.out, g.op.eval(a, b));
                changed = true;
            } else {
                try next.append(g);
            }
        }

        if (!changed) {
            // No progress, drop everything and quit.
            pending.deinit();
            next.deinit();
            break;
        }

        pending.deinit();
        pending = next;
    }

    return values;
}

fn ltString(_: void, a: String, b: String) bool {
    return std.mem.lessThan(u8, a, b);
}

fn gtString(_: void, a: String, b: String) bool {
    return std.mem.lessThan(u8, b, a);
}

fn streq(a: String, b: String) bool {
    return std.mem.eql(u8, a, b);
}

fn part2(allocator: Allocator, circuit: []const Gate, swaps: []const Swap) !List(u8) {
    if (swaps.len == 4) {
        return try formatWires(allocator, swaps);
    }

    var renames = StringMap(String).init(allocator);
    defer renames.deinit();
    for (swaps) |swap| {
        try renames.put(swap.a, swap.b);
        try renames.put(swap.b, swap.a);
    }

    var fixed = List(Gate).init(allocator);
    defer fixed.deinit();
    for (circuit) |g| {
        try fixed.append(Gate{
            .out = renames.get(g.out) orelse g.out,
            .a = g.a,
            .b = g.b,
            .op = g.op,
        });
    }
    const gates = fixed.items;

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const str = arena.allocator();

    // Assumption: Each input wire is used in exactly one one-bit adder.
    // Assumption: The input wires are never OR-ed directly for carries.
    for (0..45) |i| {
        const x = try std.fmt.allocPrint(str, "x{d:0>2}", .{i});
        const y = try std.fmt.allocPrint(str, "y{d:0>2}", .{i});

        var xors: usize = 0;
        var ands: usize = 0;
        for (gates) |g| {
            if (!g.hasInputs(x, y)) continue;

            if (g.op == .Xor) xors += 1;
            if (g.op == .And) ands += 1;
            if (g.op == .Or) unreachable;
        }

        if (xors != 1) unreachable;
        if (ands != 1) unreachable;
    }

    const lambda = struct {
        fn findGate(gs: []const Gate, i: String, j: String, op: Op) ?Gate {
            return for (gs) |g| {
                if (g.hasInputs(i, j) and g.op == op) break g;
            } else null;
        }

        fn findAdder(gs: []const Gate, i: String, j: String) ?struct { Gate, Gate } {
            const lo = for (gs) |g| {
                if (g.hasInputs(i, j) and g.op == .Xor) {
                    break g;
                }
            } else return null;

            const hi = for (gs) |g| {
                if (g.hasInputs(i, j) and g.op == .And) {
                    break g;
                }
            } else return null;
            return .{ lo, hi };
        }
    };

    // 00
    const a00, const b00 = lambda.findAdder(gates, "x00", "y00") orelse unreachable;
    std.debug.print("> a00 : {s}\n", .{a00});
    std.debug.print("> b00 : {s}\n", .{b00});

    const z00 = a00.mustOutput("z00");
    const c00 = b00;
    std.debug.print("> c00 : {s}\n", .{c00});
    std.debug.print("> z00 : {s}\n", .{z00});

    // 01 - end
    var c = List(String).init(allocator);
    defer c.deinit();
    try c.append(c00.out);

    for (1..45) |i| {
        const x = try std.fmt.allocPrint(str, "x{d:0>2}", .{i});
        const y = try std.fmt.allocPrint(str, "y{d:0>2}", .{i});
        const z = try std.fmt.allocPrint(str, "z{d:0>2}", .{i});

        const a, const b = lambda.findAdder(gates, x, y) orelse unreachable;
        std.debug.print("> a{d:0>2} : {s}\n", .{ i, a });
        std.debug.print("> b{d:0>2} : {s}\n", .{ i, b });

        const d, const e = lambda.findAdder(gates, c.items[i - 1], a.out) orelse unreachable;
        std.debug.print("> d{d:0>2} : {s}\n", .{ i, d });
        std.debug.print("> e{d:0>2} : {s}\n", .{ i, e });

        const zz = d.mustOutput(z);
        std.debug.print("> z{d:0>2} : {s}\n", .{ i, zz });

        const cc = lambda.findGate(gates, e.out, b.out, .Or) orelse unreachable;
        std.debug.print("> c{d:0>2} : {s}\n", .{ i, cc });

        try c.append(cc.out);
    }

    unreachable;
}

fn formatWires(allocator: Allocator, swaps: []const Swap) !List(u8) {
    var names = List(String).init(allocator);
    defer names.deinit();
    for (swaps) |swap| {
        try names.append(swap.a);
        try names.append(swap.b);
    }

    std.mem.sort(String, names.items, {}, ltString);

    var buf = List(u8).init(allocator);
    var w = buf.writer();

    if (names.items.len > 0) {
        try w.print("{s}", .{names.items[0]});
    }

    if (names.items.len > 1) {
        for (names.items[1..]) |n| {
            try w.print(",{s}", .{n});
        }
    }

    return buf;
}
