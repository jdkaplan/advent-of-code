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

    try stdout.print("{d}\n", .{try part1(disk)});
    try bw.flush();

    try stdout.print("{d}\n", .{try part2(disk)});
    try bw.flush();
}

fn part1(start: Disk) !u64 {
    var disk = try start.clone();
    defer disk.deinit();

    while (try disk.defrag_step_split()) {}
    return disk.checksum();
}

fn part2(start: Disk) !u64 {
    var disk = try start.clone();
    defer disk.deinit();

    var id = disk.max_id;
    // File 0 can't move anyway, so no need to deal with the integer overflow!
    while (id > 0) : (id -= 1) {
        _ = try disk.defrag_step_move(id);
    }
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
    max_id: usize,

    fn deinit(self: *Disk) void {
        self.runs.deinit();
    }

    fn clone(self: Disk) !Disk {
        const runs = try self.runs.clone();
        return .{
            .runs = runs,
            .max_id = self.max_id,
        };
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

        return .{
            .runs = runs,
            .max_id = id - 1,
        };
    }

    fn defrag_step_split(self: *Disk) !bool {
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

    fn defrag_step_move(self: *Disk, id: usize) !bool {
        var file: File = undefined;
        var pos: usize = undefined;

        for (self.runs.items, 0..) |run, i| {
            switch (run) {
                .file => |f| if (f.id == id) {
                    file = f;
                    pos = i;
                    break;
                },
                .empty => continue,
            }
        }

        for (self.runs.items, 0..) |run, i| {
            const want = switch (run) {
                .file => |f| if (f.id == file.id) {
                    return false;
                } else {
                    continue;
                },
                .empty => |empty| empty.len,
            };

            if (file.len == want) {
                self.runs.items[pos] = Run.empty(file.len);
                self.runs.items[i] = Run.file(file.id, file.len);
                return true;
            }
            if (file.len < want) {
                self.runs.items[pos] = Run.empty(file.len);
                self.runs.items[i] = Run.file(file.id, file.len);
                try self.runs.insert(i + 1, Run.empty(want - file.len));
                return true;
            }
        }

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
                .empty => |empty| {
                    i += empty.len;
                },
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
