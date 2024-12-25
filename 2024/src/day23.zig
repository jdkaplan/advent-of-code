const std = @import("std");
const aoc = @import("aoc.zig");

const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const Set = aoc.AutoHashSet;
const PriorityQueue = std.PriorityQueue;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const text = try aoc.readAll(allocator, "input/day23.txt");
    defer allocator.free(text);

    var edges = try aoc.parseAll(Edge, allocator, text, "\n");
    defer edges.deinit();

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = bw.writer();

    try stdout.print("{}\n", .{try part1(allocator, edges.items)});
    try bw.flush();
}

// I really don't want to have to figure out string hashing again, so turn the
// strings into non-slice values. ("pre-hash" them?)
const Name = u16;

fn parseName(s: []const u8) Name {
    if (s.len != 2) unreachable;

    const hi: u16 = @intCast(s[0]);
    const lo: u16 = @intCast(s[1]);

    return (hi << 8) + lo;
}

fn nameStartsWith(n: Name, c: u8) bool {
    return n >> 8 == c;
}

const Edge = struct {
    a: Name,
    b: Name,

    pub fn parse(_: Allocator, line: []const u8) !Edge {
        var parts = std.mem.tokenizeScalar(u8, line, '-');
        const a = parts.next().?;
        const b = parts.next().?;

        return Edge{
            .a = parseName(a),
            .b = parseName(b),
        };
    }
};

const Graph = struct {
    allocator: Allocator,
    nodes: Set(Name),
    edges: Map(Name, Set(Name)),

    fn init(allocator: Allocator, edges: []const Edge) !Graph {
        var g = Graph{
            .allocator = allocator,
            .nodes = Set(Name).init(allocator),
            .edges = Map(Name, Set(Name)).init(allocator),
        };

        for (edges) |edge| {
            try g.nodes.put(edge.a);
            try g.nodes.put(edge.b);

            try g.addEdge(edge.a, edge.b);
            try g.addEdge(edge.b, edge.a);
        }

        return g;
    }

    fn deinit(self: *Graph) void {
        var it = self.edges.valueIterator();
        while (it.next()) |set| set.deinit();

        self.edges.deinit();
        self.nodes.deinit();
    }

    fn addEdge(self: *Graph, src: Name, dst: Name) !void {
        var res = try self.edges.getOrPut(src);
        if (!res.found_existing) {
            res.value_ptr.* = Set(Name).init(self.allocator);
        }
        try res.value_ptr.put(dst);
    }

    fn hasEdge(self: Graph, src: Name, dst: Name) bool {
        if (self.edges.get(src)) |set| {
            return set.contains(dst);
        }
        return false;
    }

    fn neighbors(self: Graph, src: Name) ?Set(Name).Iterator {
        if (self.edges.get(src)) |set| {
            return set.iterator();
        }
        return null;
    }
};

fn part1(allocator: Allocator, edges: []const Edge) !usize {
    var graph = try Graph.init(allocator, edges);
    defer graph.deinit();

    var lans = Set([3]Name).init(allocator);
    defer lans.deinit();

    var nodes = graph.nodes.iterator();
    while (nodes.next()) |n| {
        if (!nameStartsWith(n.*, 't')) continue;

        var us = graph.neighbors(n.*).?;
        while (us.next()) |u| {
            var vs = graph.neighbors(u.*).?;
            while (vs.next()) |v| {
                if (graph.hasEdge(v.*, n.*)) {
                    var lan = [3]Name{ n.*, u.*, v.* };
                    std.mem.sort(Name, &lan, {}, comptime std.sort.asc(Name));

                    try lans.put(lan);
                }
            }
        }
    }

    return lans.count();
}
