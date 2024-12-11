const lib = @import("lib.zig");
const std = @import("std");
pub const input = "data/input10.txt";

const Point = struct { r: usize, c: usize };

const Mat = struct {
    data: [][]u8 = undefined,
    num_rows: usize = 0,
    num_cols: usize = 0,
    alloc: std.mem.Allocator = undefined,

    const Self = @This();

    fn init(lines: [][]const u8, alloc: std.mem.Allocator) !Self {
        var m = Mat{
            .num_rows = lines.len,
            .num_cols = lines[0].len,
            .alloc = alloc,
        };

        var matrix_list = std.ArrayList([]u8).init(alloc);
        for (lines) |ln| {
            var row = std.ArrayList(u8).init(alloc);
            defer row.deinit();

            for (ln) |ch| {
                try row.append(ch - '0');
            }
            try matrix_list.append(try row.toOwnedSlice());
        }

        m.data = try matrix_list.toOwnedSlice();
        return m;
    }

    fn deinit(self: Self) void {
        for (self.data) |ln| {
            self.alloc.free(ln);
        }
        self.alloc.free(self.data);
    }

    fn get_trailheads(self: Self) []Point {
        var points = std.ArrayList(Point).init(self.alloc);
        for (0..self.num_rows) |r| {
            for (0..self.num_cols) |c| {
                if (self.data[r][c] == 0) {
                    points.append(Point{ .r = r, .c = c }) catch unreachable;
                }
            }
        }
        return points.toOwnedSlice() catch unreachable;
    }

    fn _neighbors(self: Self, p: Point, val: u8) []Point {
        var ns = std.ArrayList(Point).init(self.alloc);
        if (p.r > 0 and self.data[p.r - 1][p.c] == val + 1) {
            ns.append(Point{ .r = p.r - 1, .c = p.c }) catch unreachable;
        }
        if (p.r < self.num_rows - 1 and self.data[p.r + 1][p.c] == val + 1) {
            ns.append(Point{ .r = p.r + 1, .c = p.c }) catch unreachable;
        }
        if (p.c > 0 and self.data[p.r][p.c - 1] == val + 1) {
            ns.append(Point{ .r = p.r, .c = p.c - 1 }) catch unreachable;
        }
        if (p.c < self.num_cols - 1 and self.data[p.r][p.c + 1] == val + 1) {
            ns.append(Point{ .r = p.r, .c = p.c + 1 }) catch unreachable;
        }

        return ns.toOwnedSlice() catch unreachable;
    }

    fn sum_trailheads(self: Self, part: lib.Part) !usize {
        var count: usize = 0;
        const trailheads = self.get_trailheads();
        defer self.alloc.free(trailheads);

        for (trailheads) |th| {
            count += switch (part) {
                // .one => try self.bfs(th),
                .one => try self.bfs(th, part),
                // .two => try self.bfs2(th),
                .two => try self.bfs(th, part),
            };
        }
        return count;
    }

    const Queue = std.ArrayList(Point);
    const Path = Queue;
    const PathsAggregator = std.ArrayList([]Point);
    const Visited = std.AutoHashMap(Point, bool);
    const RecurseContext = struct {
        queue: *Queue,
        path: *Path,
        paths: *PathsAggregator,
        visited: *Visited,
    };

    fn recurse(self: Self, ctx: *RecurseContext, part: lib.Part) !void {
        if (ctx.*.queue.*.items.len == 0) return;
        const p: Point = ctx.*.queue.*.orderedRemove(0);

        if (part == .one) {
            if (ctx.*.visited.*.contains(p)) return;
            try ctx.*.visited.*.put(p, true);
        }

        const val = self.data[p.r][p.c];
        if (val == 9) {
            try ctx.*.paths.append(try ctx.*.path.toOwnedSlice());
            return;
        }

        try ctx.*.path.*.append(p);

        const ns = self._neighbors(p, val);
        defer self.alloc.free(ns);

        for (ns) |n| {
            if (self.data[n.r][n.c] != self.data[p.r][p.c] + 1) continue;
            var new_q = try ctx.*.queue.*.clone();
            defer new_q.deinit();
            try new_q.append(n);
            var new_p = try ctx.*.path.*.clone();
            defer new_p.deinit();
            try new_p.append(n);

            var new_ctx = RecurseContext{
                .path = &new_p,
                .queue = &new_q,
                .paths = ctx.*.paths,
                .visited = ctx.*.visited,
            };

            try self.recurse(&new_ctx, part);
        }

        return;
    }

    fn bfs(self: Self, start: Point, part: lib.Part) !usize {
        var q = Queue.init(self.alloc);
        defer q.deinit();
        try q.append(start);

        var p = Path.init(self.alloc);
        defer p.deinit();

        var v = Visited.init(self.alloc);
        defer v.deinit();

        var pths = PathsAggregator.init(self.alloc);
        defer {
            for (pths.items) |pth| {
                self.alloc.free(pth);
            }
            pths.deinit();
        }

        var ctx = RecurseContext{
            .path = &p,
            .queue = &q,
            .paths = &pths,
            .visited = &v,
        };
        try self.recurse(&ctx, part);

        return ctx.paths.items.len;
    }
};

pub fn solve(rdr: anytype, part: lib.Part) !usize {
    const alloc = std.heap.page_allocator;
    var lr = try lib.LineReader.init(rdr, alloc);
    defer lr.deinit();

    const m = try Mat.init(lr.lines, alloc);
    defer m.deinit();
    return m.sum_trailheads(part);
}

pub fn main() !void {
    _ = try lib.run(
        usize,
        solve,
        "Day 10",
        "data/input10.txt",
    );
}

test "advent example part one" {
    const s =
        \\89010123
        \\78121874
        \\87430965
        \\96549874
        \\45678903
        \\32019012
        \\01329801
        \\10456732
    ;
    var stream = std.io.fixedBufferStream(s);
    const alloc = std.testing.allocator;

    var lr = try lib.LineReader.init(stream.reader(), alloc);
    defer lr.deinit();

    const m = try Mat.init(lr.lines, alloc);
    defer m.deinit();

    try std.testing.expect(std.mem.eql(u8, &.{ 8, 9, 0, 1, 0, 1, 2, 3 }, m.data[0]));
    try std.testing.expect(std.mem.eql(u8, &.{ 1, 0, 4, 5, 6, 7, 3, 2 }, m.data[7]));

    const ths = m.get_trailheads();
    defer alloc.free(ths);
    try std.testing.expect(ths.len == 9);

    try std.testing.expect(try m.sum_trailheads(.one) == 36);
    try std.testing.expect(try m.sum_trailheads(.two) == 81);
}
