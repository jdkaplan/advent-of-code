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

    const text = try aoc.readAll(allocator, "input/day17.txt");
    defer allocator.free(text);

    var device = try Device.parse(allocator, text);
    defer device.deinit();

    var output = try device.run();
    defer output.deinit();

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = bw.writer();

    const out = try joinOutput(allocator, output.items);
    defer out.deinit();

    try stdout.print("{s}\n", .{out.items});
    try stdout.print("{d}\n", .{try quine(allocator, device.program)});
    try bw.flush();
}

fn joinOutput(allocator: Allocator, nums: []u3) !List(u8) {
    var buf = List(u8).init(allocator);
    var w = buf.writer();

    if (nums.len > 0) {
        try w.print("{d}", .{nums[0]});
    }

    if (nums.len > 1) {
        for (nums[1..]) |n| {
            try w.print(",{d}", .{n});
        }
    }

    return buf;
}

const Device = struct {
    a: u64,
    b: u64,
    c: u64,

    program: List(u3),
    ip: usize,

    allocator: Allocator,

    const Self = @This();

    fn parse(allocator: Allocator, text: []const u8) !Self {
        var blocks = std.mem.splitSequence(u8, text, "\n\n");
        const a, const b, const c = v: {
            const block = blocks.next().?;
            var lines = std.mem.tokenizeScalar(u8, block, '\n');

            var line = lines.next().?;
            line = takeLiteral(line, "Register A: ").?;
            line, const a = takeInt(line).?;
            if (line.len != 0) unreachable;

            line = lines.next().?;
            line = takeLiteral(line, "Register B: ").?;
            line, const b = takeInt(line).?;
            if (line.len != 0) unreachable;

            line = lines.next().?;
            line = takeLiteral(line, "Register C: ").?;
            line, const c = takeInt(line).?;
            if (line.len != 0) unreachable;

            break :v .{ a, b, c };
        };

        var program = List(u3).init(allocator);
        errdefer program.deinit();
        {
            var line = blocks.next().?;

            line = std.mem.trim(u8, line, " \n");
            line = takeLiteral(line, "Program: ").?;

            var nums = std.mem.tokenizeScalar(u8, line, ',');
            while (nums.next()) |num| {
                const n = try std.fmt.parseInt(u3, num, 10);
                try program.append(n);
            }
        }

        return Self{
            .a = a,
            .b = b,
            .c = c,

            .ip = 0,
            .program = program,

            .allocator = allocator,
        };
    }

    fn deinit(self: *Self) void {
        self.program.deinit();
    }

    fn run(self: *Self) !List(u3) {
        var output = List(u3).init(self.allocator);
        while (self.ip < self.program.items.len) {
            // self.dbg();
            self.ip, const out = self.tick();

            if (out) |n| {
                try output.append(@intCast(n));
            }
        }
        return output;
    }

    fn dbg(self: Self) void {
        std.debug.print("ip: {}\nA: {}\nB: {}\nC: {}\n", .{ self.ip, self.a, self.b, self.c });
        std.debug.print("op: {} {}\n", .{
            self.program.items[self.ip],
            self.program.items[self.ip + 1],
        });
        const stdin = std.io.getStdIn();
        var buf: [1]u8 = undefined;
        _ = stdin.reader().readUntilDelimiterOrEof(&buf, '\n') catch return orelse return;
    }

    fn tick(self: *Self) struct { usize, ?u64 } {
        const opcode: Opcode = @enumFromInt(self.program.items[self.ip]);
        const operand = self.program.items[self.ip + 1];

        const pow = std.math.pow;

        switch (opcode) {
            .adv => {
                const num = self.a;
                const denom = pow(u64, 2, self.combo(operand));
                self.a = @divTrunc(num, denom);

                return .{ self.ip + 2, null };
            },
            .bxl => {
                self.b = self.b ^ operand;

                return .{ self.ip + 2, null };
            },
            .bst => {
                const n = self.combo(operand);
                self.b = n % 8;

                return .{ self.ip + 2, null };
            },
            .jnz => {
                if (self.a == 0) {
                    return .{ self.ip + 2, null };
                } else {
                    return .{ operand, null };
                }
            },
            .bxc => {
                self.b = self.b ^ self.c;

                return .{ self.ip + 2, null };
            },
            .out => {
                const n = self.combo(operand);
                const out = n % 8;

                return .{ self.ip + 2, out };
            },
            .bdv => {
                const num = self.a;
                const denom = pow(u64, 2, self.combo(operand));
                self.b = @divTrunc(num, denom);

                return .{ self.ip + 2, null };
            },
            .cdv => {
                const num = self.a;
                const denom = pow(u64, 2, self.combo(operand));
                self.c = @divTrunc(num, denom);

                return .{ self.ip + 2, null };
            },
        }
    }

    fn combo(self: *Self, operand: u3) u64 {
        return switch (operand) {
            0 => 0,
            1 => 1,
            2 => 2,
            3 => 3,
            4 => self.a,
            5 => self.b,
            6 => self.c,
            7 => unreachable,
        };
    }
};

const Instruction = struct {
    opcode: u3,
    operand: u3,
};

const Opcode = enum(u3) {
    adv = 0,
    bxl = 1,
    bst = 2,
    jnz = 3,
    bxc = 4,
    out = 5,
    bdv = 6,
    cdv = 7,
};

fn takeLiteral(input: []const u8, want: []const u8) ?[]const u8 {
    if (std.mem.startsWith(u8, input, want)) {
        return input[want.len..];
    }
    return null;
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

fn quine(allocator: Allocator, program: List(u3)) !u64 {
    var stack = List(u64).init(allocator);
    defer stack.deinit();

    // Easier than figuring out reverse iteration lol
    var possible = Set(u64).init(allocator);
    defer possible.deinit();

    inline for (0..8) |a| {
        try stack.append(a);
    }

    while (stack.popOrNull()) |a| {
        var device = Device{
            .a = a,
            .b = 0,
            .c = 0,
            .program = program,
            .ip = 0,
            .allocator = allocator,
        };
        var out = try device.run();
        defer out.deinit();

        if (std.mem.endsWith(u3, program.items, out.items)) {
            if (program.items.len == out.items.len) {
                try possible.put(a);
                continue;
            }

            inline for (0..8) |next| {
                try stack.append((a << 3) + next);
            }
        }
    }

    var min: u64 = possible.pop().?;
    while (possible.pop()) |a| {
        if (a < min) {
            min = a;
        }
    }

    return min;
}
