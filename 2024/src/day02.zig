const std = @import("std");
const aoc = @import("aoc.zig");

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // const file = try std.fs.cwd().openFile("input/test.txt", .{});
    const file = try std.fs.cwd().openFile("input/day02.txt", .{});
    defer file.close();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var lines = aoc.Lines.init(allocator, file);
    defer lines.deinit();

    var reports = std.ArrayList(Report).init(allocator);
    defer reports.deinit();

    while (try lines.next()) |line| {
        const report = try Report.parse(allocator, line);
        try reports.append(report);
    }

    try stdout.print("{d}\n", .{part1(reports)});
    try stdout.print("{d}\n", .{try part2(allocator, reports)});
    try bw.flush();

    for (reports.items) |r| {
        r.deinit();
    }
}

const Report = struct {
    levels: std.ArrayList(i32),

    fn parse(allocator: std.mem.Allocator, line: std.ArrayList(u8)) !Report {
        var levels = std.ArrayList(i32).init(allocator);

        var it = std.mem.tokenizeScalar(u8, line.items, ' ');
        while (it.next()) |level| {
            const i = try std.fmt.parseInt(i32, level, 10);
            try levels.append(i);
        }

        return .{ .levels = levels };
    }

    fn deinit(self: Report) void {
        self.levels.deinit();
    }

    fn is_safe(self: Report) bool {
        return self.first_problem() == null;
    }

    fn first_problem(self: Report) ?usize {
        var prev = self.levels.items[0];

        const sign = Sign.of(self.levels.items[1] - self.levels.items[0]);

        var i: usize = 1;
        while (i < self.levels.items.len) {
            const next = self.levels.items[i];
            const diff = next - prev;

            if (Sign.of(diff) != sign or @abs(diff) < 1 or @abs(diff) > 3) {
                return i;
            }

            prev = next;
            i += 1;
        }

        return null;
    }

    fn is_safe_tolerant(self: Report, allocator: std.mem.Allocator) !bool {
        if (self.is_safe()) {
            return true;
        }

        for (0..self.levels.items.len) |i| {
            var fixed = std.ArrayList(i32).init(allocator);
            defer fixed.deinit();

            try fixed.appendSlice(self.levels.items[0..i]);
            try fixed.appendSlice(self.levels.items[i + 1 ..]);

            if (is_safe(Report{ .levels = fixed })) {
                return true;
            }
        }

        return false;
    }
};

const Sign = enum {
    pos,
    neg,
    zero,

    fn of(i: i32) Sign {
        if (i > 0) {
            return .pos;
        }
        if (i < 0) {
            return .neg;
        }
        return .zero;
    }
};

fn part1(reports: std.ArrayList(Report)) i32 {
    var n: i32 = 0;
    for (reports.items) |report| {
        if (report.is_safe()) {
            n += 1;
        }
    }

    return n;
}

fn part2(allocator: std.mem.Allocator, reports: std.ArrayList(Report)) !i32 {
    var n: i32 = 0;
    for (reports.items) |report| {
        if (report.is_safe() or try report.is_safe_tolerant(allocator)) {
            n += 1;
        }
    }
    return n;
}
