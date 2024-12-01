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
