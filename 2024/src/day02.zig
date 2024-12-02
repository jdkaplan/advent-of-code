const std = @import("std");
const aoc = @import("aoc.zig");

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

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
    try bw.flush();

    for (reports.items) |r| {
        r.deinit();
    }
}

const Report = struct {
    levels: std.ArrayList(u32),

    fn parse(allocator: std.mem.Allocator, line: std.ArrayList(u8)) !Report {
        var levels = std.ArrayList(u32).init(allocator);

        var it = std.mem.tokenizeScalar(u8, line.items, ' ');
        while (it.next()) |level| {
            const i = try std.fmt.parseInt(u32, level, 10);
            try levels.append(i);
        }

        return .{ .levels = levels };
    }

    fn deinit(self: Report) void {
        self.levels.deinit();
    }

    fn is_safe(self: Report) bool {
        var prev = self.levels.items[0];

        const sign = self.levels.items[1] > self.levels.items[0];

        var i: usize = 1;
        while (i < self.levels.items.len) {
            const next = self.levels.items[i];
            const diff = abs_diff(next, prev);

            if ((next > prev) != sign) {
                return false;
            }

            if (diff < 1 or diff > 3) {
                return false;
            }

            prev = next;
            i += 1;
        }

        return true;
    }
};

fn abs_diff(a: u32, b: u32) u32 {
    if (a > b) {
        return a - b;
    } else {
        return b - a;
    }
}

fn part1(reports: std.ArrayList(Report)) u32 {
    var n: u32 = 0;
    for (reports.items) |report| {
        if (report.is_safe()) {
            n += 1;
        }
    }

    return n;
}
