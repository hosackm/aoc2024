const std = @import("std");
const lib = @import("lib.zig");

pub const input = "data/input18.txt";

const Point = struct {
    x: usize,
    y: usize,

    fn eql(self: Point, other: Point) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const Path = struct {
    cost: usize,
    pts: std.AutoArrayHashMap(Point, bool),
};

const Cost = struct {
    cost: usize = 0,
    pt: Point = undefined,
};

fn ProgramSpace(n: usize) type {
    return struct {
        m: [n][n]u8 = undefined,
        alloc: std.mem.Allocator,
        num_dropped: usize = 0,
        barriers: std.AutoArrayHashMap(Point, bool),

        const Self = @This();
        const dim = n;

        fn init(alloc: std.mem.Allocator) Self {
            var s: Self = .{
                .barriers = std.AutoArrayHashMap(Point, bool).init(alloc),
                .alloc = alloc,
            };

            for (0..dim) |r| {
                for (0..n) |c| {
                    s.m[r][c] = '.';
                }
            }
            return s;
        }

        fn parse(self: *Self, lines: [][]const u8) !void {
            for (lines) |ln| {
                var iter = std.mem.splitScalar(u8, ln, ',');
                try self.barriers.put(.{
                    .x = try std.fmt.parseInt(usize, iter.next().?, 10),
                    .y = try std.fmt.parseInt(usize, iter.next().?, 10),
                }, true);
            }
        }

        fn drop(self: *Self, num: usize) Point {
            var iter = self.barriers.iterator();

            // skip those already dropped
            for (0..self.num_dropped) |_| {
                _ = iter.next().?;
            }

            // drop n new barriers
            var last: Point = undefined;
            for (0..num) |_| {
                const p = iter.next().?.key_ptr.*;
                self.m[p.y][p.x] = '#';
                self.num_dropped += 1;
                last = p;
            }
            return last;
        }

        fn order(_: void, a: Cost, b: Cost) std.math.Order {
            return std.math.order(a.cost, b.cost);
        }

        fn shortest_path(self: *Self) !?Path {
            var came_from = std.AutoHashMap(Point, Point).init(self.alloc);
            defer came_from.deinit();

            var pq = std.PriorityQueue(
                Cost,
                void,
                order,
            ).init(self.alloc, {});
            defer pq.deinit();

            try pq.add(.{ .cost = 0, .pt = .{ .x = 0, .y = 0 } });

            var visited = std.AutoHashMap(Point, bool).init(self.alloc);
            defer visited.deinit();

            var costs = std.AutoHashMap(Point, usize).init(self.alloc);
            defer costs.deinit();

            while (pq.count() != 0) {
                const obj = pq.remove();
                if (obj.pt.eql(.{ .x = dim - 1, .y = dim - 1 })) {
                    // reconstruct path
                    var points = std.ArrayList(Point).init(self.alloc);
                    defer points.deinit();
                    var p = obj.pt;
                    while (p.x != 0 or p.y != 0) : (p = came_from.get(p).?) try points.append(p);

                    var points_set = std.AutoArrayHashMap(Point, bool).init(self.alloc);
                    for (points.items) |one_pt| {
                        try points_set.put(one_pt, true);
                    }

                    std.mem.reverse(Point, points.items);
                    return .{ .cost = obj.cost, .pts = points_set };
                }

                if (visited.contains(obj.pt)) continue;
                try visited.put(obj.pt, true);

                const directions: [4]struct { dx: i2, dy: i2 } = .{
                    .{ .dx = 0, .dy = -1 }, .{ .dx = 0, .dy = 1 },
                    .{ .dx = 1, .dy = 0 },  .{ .dx = -1, .dy = 0 },
                };
                for (directions) |d| {
                    const nx: i32 = @as(i32, @intCast(obj.pt.x)) + d.dx;
                    const ny: i32 = @as(i32, @intCast(obj.pt.y)) + d.dy;
                    if (nx >= 0 and nx < dim and ny >= 0 and ny < dim) {
                        if (self.m[@intCast(ny)][@intCast(nx)] != '.') continue;

                        const new_pt = Point{ .x = @intCast(nx), .y = @intCast(ny) };
                        if (!costs.contains(new_pt) or obj.cost + 1 < costs.get(new_pt).?) {
                            try costs.put(new_pt, obj.cost + 1);
                            try came_from.put(new_pt, obj.pt);
                            try pq.add(.{ .cost = obj.cost + 1, .pt = new_pt });
                        }
                    }
                }
            }

            return null;
        }

        fn deinit(self: *Self) void {
            self.barriers.deinit();
        }
    };
}

pub fn solve(rdr: anytype, part: lib.Part) !usize {
    const alloc = std.heap.page_allocator;
    var lr = try lib.LineReader.init(rdr, alloc);
    defer lr.deinit();

    if (part == .one) {
        var p = ProgramSpace(71).init(alloc);
        defer p.deinit();
        try p.parse(lr.lines);
        _ = p.drop(1024);

        const obj = try p.shortest_path() orelse unreachable;
        return obj.cost;
    } else {
        var p = ProgramSpace(71).init(alloc);
        defer p.deinit();

        try p.parse(lr.lines);
        _ = p.drop(1024);

        var done = false;
        var path = (try p.shortest_path()).?;
        while (!done) {
            const b = p.drop(1);
            var iter = path.pts.iterator();

            while (iter.next()) |entry| {
                const pt = entry.key_ptr.*;
                if (b.x == pt.x and b.y == pt.y) {
                    // recompute
                    path.pts.deinit();
                    path = try p.shortest_path() orelse {
                        std.debug.print("part 2: {d},{d}\n", .{ b.x, b.y });
                        done = true;
                        break;
                    };
                    iter = path.pts.iterator();
                }
            }
        }

        return 0;
    }
}

pub fn main() !void {
    try lib.run(usize, solve, "Day 14", input);
}

test "construct program space" {
    const s =
        \\5,4
        \\4,2
        \\4,5
        \\3,0
        \\2,1
        \\6,3
        \\2,4
        \\1,5
        \\0,6
        \\3,3
        \\2,6
        \\5,1
        \\1,2
        \\5,5
        \\2,5
        \\6,5
        \\1,4
        \\0,4
        \\6,4
        \\1,1
        \\6,1
        \\1,0
        \\0,5
        \\1,6
        \\2,0
    ;
    const alloc = std.testing.allocator;
    var p = ProgramSpace(7).init(alloc);
    defer p.deinit();

    var stream = std.io.fixedBufferStream(s);
    var lr = try lib.LineReader.init(stream.reader(), alloc);
    defer lr.deinit();
    try p.parse(lr.lines);

    try std.testing.expect(p.m[0][0] == '.');
    try std.testing.expect(p.m[0][6] == '.');
    try std.testing.expect(p.m[6][6] == '.');
    try std.testing.expect(p.m[6][0] == '.');

    try std.testing.expect(p.barriers.count() == 25);

    var iter = p.barriers.iterator();
    var entry = iter.next().?;
    try std.testing.expect(entry.key_ptr.*.x == 5);
    try std.testing.expect(entry.key_ptr.*.y == 4);

    entry = iter.next().?;
    try std.testing.expect(entry.key_ptr.*.x == 4);
    try std.testing.expect(entry.key_ptr.*.y == 2);

    entry = iter.next().?;
    try std.testing.expect(entry.key_ptr.*.x == 4);
    try std.testing.expect(entry.key_ptr.*.y == 5);
}

test "drop barriers in space" {
    const s =
        \\5,4
        \\4,2
        \\4,5
        \\3,0
        \\2,1
        \\6,3
        \\2,4
        \\1,5
        \\0,6
        \\3,3
        \\2,6
        \\5,1
        \\1,2
        \\5,5
        \\2,5
        \\6,5
        \\1,4
        \\0,4
        \\6,4
        \\1,1
        \\6,1
        \\1,0
        \\0,5
        \\1,6
        \\2,0
    ;
    const alloc = std.testing.allocator;
    var p = ProgramSpace(7).init(alloc);
    defer p.deinit();

    var stream = std.io.fixedBufferStream(s);
    var lr = try lib.LineReader.init(stream.reader(), alloc);
    defer lr.deinit();
    try p.parse(lr.lines);

    try std.testing.expect(p.num_dropped == 0);

    _ = p.drop(1);
    try std.testing.expect(p.num_dropped == 1);

    try std.testing.expect(p.m[4][5] == '#');

    _ = p.drop(12);
    try std.testing.expect(p.num_dropped == 13);
    try std.testing.expect(p.m[2][1] == '#');
    try std.testing.expect(p.m[5][5] != '#');
}

test "path" {
    const s =
        \\5,4
        \\4,2
        \\4,5
        \\3,0
        \\2,1
        \\6,3
        \\2,4
        \\1,5
        \\0,6
        \\3,3
        \\2,6
        \\5,1
        \\1,2
        \\5,5
        \\2,5
        \\6,5
        \\1,4
        \\0,4
        \\6,4
        \\1,1
        \\6,1
        \\1,0
        \\0,5
        \\1,6
        \\2,0
    ;
    const alloc = std.testing.allocator;
    var p = ProgramSpace(7).init(alloc);
    defer p.deinit();

    var stream = std.io.fixedBufferStream(s);
    var lr = try lib.LineReader.init(stream.reader(), alloc);
    defer lr.deinit();
    try p.parse(lr.lines);

    var path = (try p.shortest_path()).?;
    defer path.pts.deinit();
}
