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

        pub fn valueIterator(self: Self) Map.KeyIterator {
            return self.map.keyIterator();
        }
    };
}
