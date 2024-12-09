const std = @import("std");
const aoc = @import("aoc.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("input/day09.txt", .{});
    defer file.close();

    const text = try file.readToEndAlloc(allocator, comptime 1 << 30);
    defer allocator.free(text);

    var disk = try Disk.parse(allocator, text);
    defer disk.deinit();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("{d}\n", .{try part1(allocator, disk)});
    try bw.flush();
}

fn part1(_: Allocator, start: Disk) !u64 {
    var disk = start;
    while (try disk.defrag_step()) {}
    return disk.checksum();
}

const File = struct {
    id: usize,
    len: u64,
};

const Run = union(enum) {
    file: File,
    empty: struct {
        len: u64,
    },

    fn empty(len: u64) Run {
        return Run{ .empty = .{ .len = len } };
    }

    fn file(id: usize, len: u64) Run {
        return Run{ .file = .{ .id = id, .len = len } };
    }
};

const Disk = struct {
    runs: ArrayList(Run),

    fn deinit(self: *Disk) void {
        self.runs.deinit();
    }

    fn parse(allocator: Allocator, text: []const u8) !Disk {
        var runs = ArrayList(Run).init(allocator);

        var id: usize = 0;
        var isFile = true;
        for (text) |char| {
            if (char == '\n') {
                break;
            }

            const len = char - '0';
            if (isFile) {
                try runs.append(Run{ .file = .{ .id = id, .len = len } });
                id += 1;
            } else {
                try runs.append(Run{ .empty = .{ .len = len } });
            }

            isFile = !isFile;
        }

        return .{ .runs = runs };
    }

    fn defrag_step(self: *Disk) !bool {
        var last: File = undefined;

        while (true) {
            switch (self.runs.pop()) {
                .file => |file| {
                    last = file;
                    break;
                },
                .empty => continue,
            }
        }

        var i: usize = 0;
        while (i < self.runs.items.len) : (i += 1) {
            const want = switch (self.runs.items[i]) {
                .file => continue,
                .empty => |empty| empty.len,
            };

            if (last.len == want) {
                self.runs.items[i] = Run.file(last.id, want);
            } else if (last.len > want) {
                self.runs.items[i] = Run.file(last.id, want);
                try self.runs.append(Run.file(last.id, last.len - want));
            } else if (last.len < want) {
                self.runs.items[i] = Run.file(last.id, last.len);
                try self.runs.insert(i + 1, Run.empty(want - last.len));
            }

            return true;
        }

        try self.runs.append(Run{ .file = last });

        return false;
    }

    fn checksum(self: Disk) u64 {
        var sum: u64 = 0;
        var i: usize = 0;
        for (self.runs.items) |run| {
            switch (run) {
                .file => |file| {
                    for (0..file.len) |j| {
                        sum += file.id * (i + j);
                    }
                    i += file.len;
                },
                .empty => unreachable,
            }
        }
        return sum;
    }

    pub fn format(
        self: Disk,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        for (self.runs.items) |run| {
            switch (run) {
                .file => |file| {
                    for (0..file.len) |_| {
                        try writer.print("{}", .{file.id});
                    }
                },
                .empty => |empty| for (0..empty.len) |_| {
                    try writer.print(".", .{});
                },
            }
        }
    }
};
