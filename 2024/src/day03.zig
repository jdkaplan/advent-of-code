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
    try bw.flush();
}

const Mul = struct {
    a: u32,
    b: u32,
};

const MulIterator = struct {
    text: []u8,
    pos: usize,

    fn new(text: []u8) MulIterator {
        return .{
            .text = text,
            .pos = 0,
        };
    }

    fn next(self: *MulIterator) ?Mul {
        while (self.pos < self.text.len) {

            self.pos += std.mem.indexOf(u8, self.text[self.pos..], "mul(") orelse return null;
            self.pos += consume(self.text[self.pos..], "mul(").?;

            const a = parsePrefixInt(self.text[self.pos..]) orelse continue;
            self.pos += a.chars;

            self.pos += consume(self.text[self.pos..], ",") orelse continue;

            const b = parsePrefixInt(self.text[self.pos..]) orelse continue;
            self.pos += b.chars;

            self.pos += consume(self.text[self.pos..], ")") orelse continue;

            return .{ .a = a.value, .b = b.value };
        }
        return null;
    }
};

fn consume(text: []const u8, want: []const u8) ?usize {
    if (std.mem.startsWith(u8, text, want)) {
        return want.len;
    }
    return null;
}

fn parsePrefixInt(s: []u8) ?struct { value: u32, chars: usize } {
    var idx: usize = 0;
    var value: u32 = 0;

    while (idx < s.len and std.ascii.isDigit(s[idx])) {
        value *= 10;
        value += s[idx] - '0';
        idx += 1;
    }

    if (idx > 0) {
        return .{ .value = value, .chars = idx };
    }
    return null;
}

fn part1(text: []u8) u32 {
    var it = MulIterator.new(text);
    var sum: u32 = 0;
    while (it.next()) |mul| {
        sum += mul.a * mul.b;
    }
    return sum;
}
