const lib = @import("lib.zig");
const std = @import("std");
pub const input = "data/input12.txt";

const Point = struct { r: usize, c: usize };

const Mat = struct {
    const Queue = std.ArrayList(Point);
    const Group = std.AutoHashMap(Point, bool);
    const Self = @This();

    data: [][]u8 = undefined,
    visited: [][]u8 = undefined,
    num_rows: usize = 0,
    num_cols: usize = 0,
    groups: std.ArrayList([]Point),
    alloc: std.mem.Allocator = undefined,

    fn init(lines: [][]const u8, alloc: std.mem.Allocator) !Self {
        var m = Mat{
            .num_rows = lines.len,
            .num_cols = lines[0].len,
            .groups = std.ArrayList([]Point).init(alloc),
            .alloc = alloc,
        };

        var matrix_list = std.ArrayList([]u8).init(alloc);
        var visited_list = std.ArrayList([]u8).init(alloc);
        for (lines) |ln| {
            var row = std.ArrayList(u8).init(alloc);
            defer row.deinit();

            var visited_row = std.ArrayList(u8).init(alloc);
            defer visited_row.deinit();

            for (ln) |ch| {
                try row.append(ch);
                try visited_row.append(ch);
            }

            try matrix_list.append(try row.toOwnedSlice());
            try visited_list.append(try visited_row.toOwnedSlice());
        }

        m.data = try matrix_list.toOwnedSlice();
        m.visited = try visited_list.toOwnedSlice();
        return m;
    }

    fn deinit(self: Self) void {
        for (self.visited) |ln| {
            self.alloc.free(ln);
        }
        self.alloc.free(self.visited);

        for (self.data) |ln| {
            self.alloc.free(ln);
        }
        self.alloc.free(self.data);
        for (self.groups.items) |pt_slice| {
            self.alloc.free(pt_slice);
        }
        self.groups.deinit();
    }

    fn flip(self: *Self, start: Point) struct { area: usize, perimeter: usize, sides: usize } {
        var group = Group.init(self.alloc);
        defer group.deinit();

        var queue = Queue.init(self.alloc);
        defer queue.deinit();
        queue.append(start) catch unreachable;

        var perimeter: usize = 0;

        while (queue.items.len > 0) {
            const pt = queue.orderedRemove(0);
            if (group.contains(pt)) continue;

            group.put(pt, true) catch unreachable;
            const nbs = self.neighbors(pt, self.data[pt.r][pt.c]);
            defer self.alloc.free(nbs);
            perimeter += 4 - nbs.len;

            for (nbs) |n| {
                queue.append(n) catch unreachable;
            }
        }

        var points = std.ArrayList(Point).init(self.alloc);

        var iter = group.keyIterator();
        while (iter.next()) |pt| {
            self.visited[pt.*.r][pt.*.c] = '-';
            points.append(pt.*) catch unreachable;
        }

        const pt_slice = points.toOwnedSlice() catch unreachable;
        const sides = self.count_sides(pt_slice);
        self.groups.append(pt_slice) catch unreachable;

        return .{ .area = group.count(), .perimeter = perimeter, .sides = sides };
    }

    fn neighbors(self: Self, p: Point, val: u8) []Point {
        var ns = std.ArrayList(Point).init(self.alloc);
        if (p.r > 0 and self.data[p.r - 1][p.c] == val) {
            ns.append(Point{ .r = p.r - 1, .c = p.c }) catch unreachable;
        }
        if (p.r < self.num_rows - 1 and self.data[p.r + 1][p.c] == val) {
            ns.append(Point{ .r = p.r + 1, .c = p.c }) catch unreachable;
        }
        if (p.c > 0 and self.data[p.r][p.c - 1] == val) {
            ns.append(Point{ .r = p.r, .c = p.c - 1 }) catch unreachable;
        }
        if (p.c < self.num_cols - 1 and self.data[p.r][p.c + 1] == val) {
            ns.append(Point{ .r = p.r, .c = p.c + 1 }) catch unreachable;
        }

        return ns.toOwnedSlice() catch unreachable;
    }

    fn calc_price(self: *Self, part: lib.Part) usize {
        self.clear_groups();

        var total: usize = 0;
        for (0..self.num_rows) |r| {
            for (0..self.num_cols) |c| {
                if (self.visited[r][c] == '-') continue;
                const result = self.flip(.{ .r = r, .c = c });
                total += result.area * if (part == .one) result.perimeter else result.sides;
            }
        }
        return total;
    }

    const Neighbor = enum {
        left,
        right,
        up,
        down,
        upleft,
        upright,
        downleft,
        downright,
    };

    fn is_missing(self: Self, p: Point, n: Neighbor) bool {
        return switch (n) {
            .left => p.c == 0 or self.data[p.r][p.c] != self.data[p.r][p.c - 1],
            .right => p.c == self.num_cols - 1 or self.data[p.r][p.c] != self.data[p.r][p.c + 1],
            .up => p.r == 0 or self.data[p.r][p.c] != self.data[p.r - 1][p.c],
            .down => p.r == self.num_rows - 1 or self.data[p.r][p.c] != self.data[p.r + 1][p.c],
            .upleft => p.r == 0 or p.c == 0 or self.data[p.r][p.c] != self.data[p.r - 1][p.c - 1],
            .upright => p.r == 0 or p.c == self.num_cols - 1 or self.data[p.r][p.c] != self.data[p.r - 1][p.c + 1],
            .downright => p.r == self.num_rows - 1 or p.c == self.num_cols - 1 or self.data[p.r][p.c] != self.data[p.r + 1][p.c + 1],
            .downleft => p.r == self.num_rows - 1 or p.c == 0 or self.data[p.r][p.c] != self.data[p.r + 1][p.c - 1],
        };
    }

    fn num_corners(self: Self, pt: Point) usize {
        var count: usize = 0;
        const outward_corners: [4][3]Neighbor = .{
            .{ .left, .upleft, .up },
            .{ .right, .upright, .up },
            .{ .left, .downleft, .down },
            .{ .right, .downright, .down },
        };
        for (outward_corners) |ns| {
            if (self.is_missing(pt, ns[0]) and
                self.is_missing(pt, ns[1]) and
                self.is_missing(pt, ns[2])) count += 1;
        }

        const inward_corners: [4][3]Neighbor = .{
            .{ .upright, .up, .right },
            .{ .upleft, .up, .left },
            .{ .downright, .down, .right },
            .{ .downleft, .down, .left },
        };
        for (inward_corners) |ns| {
            if (self.is_missing(pt, ns[0]) and
                !self.is_missing(pt, ns[1]) and
                !self.is_missing(pt, ns[2])) count += 1;
        }

        return count;
    }

    fn count_sides(self: Self, group: []Point) usize {
        var total: usize = 0;
        for (group) |p| {
            total += self.num_corners(p);
        }
        return total;
    }

    fn clear_groups(self: *Self) void {
        if (self.groups.items.len > 0) {
            for (self.groups.items) |p| {
                self.alloc.free(p);
            }
            self.groups.clearAndFree();
        }
    }
};

pub fn solve(rdr: anytype, part: lib.Part) !usize {
    const alloc = std.heap.page_allocator;
    var lr = try lib.LineReader.init(rdr, alloc);
    defer lr.deinit();

    var m = try Mat.init(lr.lines, alloc);
    defer m.deinit();

    return m.calc_price(part);
}

pub fn main() !void {
    _ = try lib.run(
        usize,
        solve,
        "Day 12",
        input,
    );
}

test "advent example part one" {
    const s =
        \\RRRRIICCFF
        \\RRRRIICCCF
        \\VVRRRCCFFF
        \\VVRCCCJFFF
        \\VVVVCJJCFE
        \\VVIVCCJJEE
        \\VVIIICJJEE
        \\MIIIIIJJEE
        \\MIIISIJEEE
        \\MMMISSJEEE
    ;
    const alloc = std.testing.allocator;
    var stream = std.io.fixedBufferStream(s);

    var lr = try lib.LineReader.init(stream.reader(), alloc);
    defer lr.deinit();

    var m = try Mat.init(lr.lines, alloc);
    defer m.deinit();

    try std.testing.expect(m.calc_price(.one) == 1930);
    try std.testing.expect(m.groups.items.len == 11);
}

test "advent example part two" {
    const s =
        \\RRRRIICCFF
        \\RRRRIICCCF
        \\VVRRRCCFFF
        \\VVRCCCJFFF
        \\VVVVCJJCFE
        \\VVIVCCJJEE
        \\VVIIICJJEE
        \\MIIIIIJJEE
        \\MIIISIJEEE
        \\MMMISSJEEE
    ;
    const alloc = std.testing.allocator;
    var stream = std.io.fixedBufferStream(s);

    var lr = try lib.LineReader.init(stream.reader(), alloc);
    defer lr.deinit();

    var m = try Mat.init(lr.lines, alloc);
    defer m.deinit();

    const price = m.calc_price(.two);
    try std.testing.expect(price == 1206);
}
