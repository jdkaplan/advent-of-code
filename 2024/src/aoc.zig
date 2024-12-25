const std = @import("std");

pub const Lines = struct {
    buf_reader: std.io.BufferedReader(4096, std.fs.File.Reader),
    line: std.ArrayList(u8),

    pub fn init(allocator: std.mem.Allocator, file: std.fs.File) Lines {
        return .{
            .buf_reader = std.io.bufferedReader(file.reader()),
            .line = std.ArrayList(u8).init(allocator),
        };
    }

    pub fn deinit(self: Lines) void {
        self.line.deinit();
    }

    pub fn next(self: *Lines) !?std.ArrayList(u8) {
        const writer = self.line.writer();
        const reader = self.buf_reader.reader();

        self.line.clearRetainingCapacity();
        if (reader.streamUntilDelimiter(writer, '\n', null)) {
            return self.line;
        } else |err| switch (err) {
            error.EndOfStream => return null,
            else => return err,
        }
    }
};

pub fn AutoHashSet(comptime T: type) type {
    const Empty = struct {};
    const Map = std.AutoHashMap(T, Empty);

    return struct {
        map: Map,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .map = Map.init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            self.map.deinit();
        }

        pub fn put(self: *Self, v: T) !void {
            return self.map.put(v, .{});
        }

        pub fn contains(self: Self, v: T) bool {
            return self.map.contains(v);
        }

        pub const Iterator = Map.KeyIterator;

        pub fn iterator(self: Self) Iterator {
            return self.map.keyIterator();
        }

        pub fn count(self: Self) usize {
            return self.map.count();
        }

        pub fn pop(self: *Self) ?T {
            var it = self.iterator();
            const key_ptr = it.next() orelse return null;
            const key = key_ptr.*;
            _ = self.map.remove(key);
            return key;
        }

        pub fn remove(self: *Self, v: T) bool {
            return self.map.remove(v);
        }
    };
}

pub fn parseAll(
    comptime T: type,
    allocator: std.mem.Allocator,
    text: []const u8,
    sep: []const u8,
) !std.ArrayList(T) {
    var all = std.ArrayList(T).init(allocator);

    var it = std.mem.tokenizeSequence(u8, text, sep);
    while (it.next()) |s| {
        const v = try T.parse(allocator, s);
        try all.append(v);
    }

    return all;
}

pub fn splitAll(
    allocator: std.mem.Allocator,
    text: []const u8,
    sep: []const u8,
) !std.ArrayList([]const u8) {
    var all = std.ArrayList([]const u8).init(allocator);

    var it = std.mem.tokenizeSequence(u8, text, sep);
    while (it.next()) |s| {
        try all.append(s);
    }

    return all;
}

pub fn gcd(n: i32, m: i32) i32 {
    var a = @abs(n);
    var b = @abs(m);

    while (b != 0) {
        const t = b;
        b = a % b;
        a = t;
    }

    return @intCast(a);
}

test "gcd" {
    const expectEqual = std.testing.expectEqual;

    try expectEqual(2, gcd(2, 4));
    try expectEqual(1, gcd(2, 5));
    try expectEqual(1, gcd(-2, 3));
    try expectEqual(2, gcd(-2, -4));
}

pub fn readAll(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, comptime 1 << 30);
}
