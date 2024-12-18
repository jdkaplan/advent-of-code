const std = @import("std");
const aoc = @import("aoc.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("input/day03.txt", .{});
    defer file.close();

    const text = try file.readToEndAlloc(allocator, comptime 1 << 30);
    defer allocator.free(text);

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("{d}\n", .{part1(text)});
    try stdout.print("{d}\n", .{part2(text)});
    try bw.flush();
}

const Mul = struct {
    a: u32,
    b: u32,
};

const Instruction = union(enum) {
    do,
    dont,
    mul: Mul,
};

const Memory = struct {
    text: []u8,
    pos: usize,

    fn new(text: []u8) Memory {
        return .{
            .text = text,
            .pos = 0,
        };
    }

    fn next_mul(self: *Memory) ?Mul {
        while (self.pos < self.text.len) {
            self.pos += std.mem.indexOf(u8, self.text[self.pos..], "mul(") orelse return null;

            self.pos += consumeLiteral(self.text[self.pos..], "mul(").?;

            const a = consumeInt(self.text[self.pos..]) orelse continue;
            self.pos += a.chars.len;

            self.pos += consumeLiteral(self.text[self.pos..], ",") orelse continue;

            const b = consumeInt(self.text[self.pos..]) orelse continue;
            self.pos += b.chars.len;

            self.pos += consumeLiteral(self.text[self.pos..], ")") orelse continue;

            return .{ .a = a.value, .b = b.value };
        }
        return null;
    }

    fn next_instruction(self: *Memory) ?Instruction {
        while (self.pos < self.text.len) {
            if (consumeLiteral(self.text[self.pos..], "do()")) |n| {
                self.pos += n;
                return Instruction.do;
            }

            if (consumeLiteral(self.text[self.pos..], "don't()")) |n| {
                self.pos += n;
                return Instruction.dont;
            }

            if (consumeLiteral(self.text[self.pos..], "mul(")) |n| {
                self.pos += n;

                const a = consumeInt(self.text[self.pos..]) orelse continue;
                self.pos += a.chars.len;

                self.pos += consumeLiteral(self.text[self.pos..], ",") orelse continue;

                const b = consumeInt(self.text[self.pos..]) orelse continue;
                self.pos += b.chars.len;

                self.pos += consumeLiteral(self.text[self.pos..], ")") orelse continue;

                return Instruction{ .mul = .{ .a = a.value, .b = b.value } };
            }

            self.pos += 1;
        }
        return null;
    }
};

fn Match(comptime T: type) type {
    return struct {
        value: T,
        chars: []const u8,
    };
}

fn consumeLiteral(text: []const u8, want: []const u8) ?usize {
    if (std.mem.startsWith(u8, text, want)) {
        return want.len;
    }
    return null;
}

fn consumeInt(s: []u8) ?Match(u32) {
    var idx: usize = 0;
    var value: u32 = 0;

    while (idx < s.len and std.ascii.isDigit(s[idx])) {
        value *= 10;
        value += s[idx] - '0';
        idx += 1;
    }

    if (idx > 0) {
        return .{ .value = value, .chars = s[0..idx] };
    }
    return null;
}

fn part1(text: []u8) u32 {
    var mem = Memory.new(text);
    var sum: u32 = 0;
    while (mem.next_mul()) |mul| {
        sum += mul.a * mul.b;
    }
    return sum;
}

fn part2(text: []u8) u32 {
    var mem = Memory.new(text);
    var enabled = true;
    var sum: u32 = 0;
    while (mem.next_instruction()) |inst| {
        switch (inst) {
            .do => enabled = true,
            .dont => enabled = false,
            .mul => |*mul| if (enabled) {
                sum += mul.a * mul.b;
            },
        }
    }
    return sum;
}
