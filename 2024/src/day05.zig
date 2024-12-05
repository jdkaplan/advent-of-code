const std = @import("std");
const aoc = @import("aoc.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("input/day05.txt", .{});
    defer file.close();

    const text = try file.readToEndAlloc(allocator, comptime 1 << 30);
    defer allocator.free(text);

    var input = try Input.parse(allocator, text);
    defer input.deinit();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("{d}\n", .{try part1(input)});
    try bw.flush();

    try stdout.print("{d}\n", .{try part2(input)});
    try bw.flush();
}

const Input = struct {
    rules: ArrayList(Rule),
    updates: ArrayList(Update),
    constraints: std.AutoHashMap(u32, Constraints),

    fn deinit(self: *Input) void {
        self.rules.deinit();

        for (self.updates.items) |update| {
            update.deinit();
        }

        self.updates.deinit();

        var it = self.constraints.valueIterator();
        while (it.next()) |value| {
            value.before.deinit();
            value.after.deinit();
        }
        self.constraints.deinit();
    }

    fn parse(alloc: Allocator, text: []const u8) !Input {
        var blocks = std.mem.tokenizeSequence(u8, text, "\n\n");

        var rule_lines = std.mem.tokenizeScalar(u8, blocks.next().?, '\n');
        var rules = ArrayList(Rule).init(alloc);
        while (rule_lines.next()) |line| {
            try rules.append(try Rule.parse(line));
        }

        var update_lines = std.mem.tokenizeScalar(u8, blocks.next().?, '\n');
        var updates = ArrayList(Update).init(alloc);
        while (update_lines.next()) |line| {
            try updates.append(try Update.parse(alloc, line));
        }

        var constraints = std.AutoHashMap(u32, Constraints).init(alloc);

        for (rules.items) |rule| {
            {
                var c = try constraints.getOrPut(rule.x);
                if (!c.found_existing) {
                    c.value_ptr.* = Constraints.init(alloc);
                }
                try c.value_ptr.after.put(rule.y);
            }

            {
                var c = try constraints.getOrPut(rule.y);
                if (!c.found_existing) {
                    c.value_ptr.* = Constraints.init(alloc);
                }
                try c.value_ptr.before.put(rule.x);
            }
        }

        return .{
            .rules = rules,
            .updates = updates,
            .constraints = constraints,
        };
    }
};

const Rule = struct {
    x: u32,
    y: u32,

    fn parse(line: []const u8) !Rule {
        var it = std.mem.tokenizeScalar(u8, line, '|');

        const x = try std.fmt.parseInt(u32, it.next().?, 10);
        const y = try std.fmt.parseInt(u32, it.next().?, 10);

        return .{
            .x = x,
            .y = y,
        };
    }
};

const Update = struct {
    pages: ArrayList(u32),

    fn deinit(self: Update) void {
        self.pages.deinit();
    }

    fn parse(alloc: Allocator, line: []const u8) !Update {
        var pages = ArrayList(u32).init(alloc);

        var it = std.mem.tokenizeScalar(u8, line, ',');
        while (it.next()) |p| {
            const page = try std.fmt.parseInt(u32, p, 10);
            try pages.append(page);
        }

        return .{
            .pages = pages,
        };
    }

    fn valid(self: Update, constraints: std.AutoHashMap(u32, Constraints)) bool {
        const items = self.pages.items;
        for (items[0..(items.len - 1)], items[1..]) |x, y| {
            if (constraints.get(x)) |c| {
                if (!c.after.contains(y)) {
                    return false;
                }
            }
        }
        return true;
    }
};

const Constraints = struct {
    before: aoc.AutoHashSet(u32),
    after: aoc.AutoHashSet(u32),

    fn init(alloc: Allocator) Constraints {
        return .{
            .before = aoc.AutoHashSet(u32).init(alloc),
            .after = aoc.AutoHashSet(u32).init(alloc),
        };
    }

    fn deinit(self: *Constraints) void {
        self.before.deinit();
        self.before = undefined;
        self.after.deinit();
        self.after = undefined;
    }
};

fn part1(input: Input) !u32 {
    var sum: u32 = 0;
    for (input.updates.items) |u| {
        if (u.valid(input.constraints)) {
            sum += u.pages.items[u.pages.items.len / 2];
        }
    }
    return sum;
}

const FixUpdate = struct {
    constraints: std.AutoHashMap(u32, Constraints),

    fn lessThan(self: FixUpdate, x: u32, y: u32) bool {
        if (self.constraints.get(x)) |c| {
            return c.after.contains(y);
        }
        return false;
    }
};

fn part2(input: Input) !u32 {
    var sum: u32 = 0;
    for (input.updates.items) |u| {
        if (u.valid(input.constraints)) {
            continue;
        }

        std.mem.sort(
            u32,
            u.pages.items,
            FixUpdate{ .constraints = input.constraints },
            FixUpdate.lessThan,
        );

        sum += u.pages.items[u.pages.items.len / 2];
    }
    return sum;
}
