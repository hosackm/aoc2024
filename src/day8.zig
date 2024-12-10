const std = @import("std");
const lib = @import("lib.zig");
pub const input = "data/input8.txt";

const Point = struct {
    r: i64,
    c: i64,
};

fn permutations(T: type, items: []T, alloc: std.mem.Allocator) ![][2]T {
    var perms = std.ArrayList([2]T).init(alloc);

    for (0..items.len) |i| {
        for (0..items.len) |j| {
            if (i == j) continue;
            try perms.append(.{ items[i], items[j] });
        }
    }

    return try perms.toOwnedSlice();
}

const Solver = struct {
    mapping: std.AutoHashMap(u8, std.ArrayList(Point)) = undefined,
    alloc: std.mem.Allocator,
    lines: [][]u8 = undefined,
    nodes: std.AutoHashMap(Point, bool) = undefined,
    rows: usize = undefined,
    cols: usize = undefined,

    const Self = @This();

    pub fn count_antinodes(self: *Self, part: lib.Part) !usize {
        self.nodes.clearAndFree();
        var iter = self.mapping.iterator();
        while (iter.next()) |entry| {
            const points = entry.value_ptr.*;

            const perms = try permutations(Point, points.items, self.alloc);
            defer self.alloc.free(perms);

            for (perms) |perm| {
                const one = perm[0];
                const two = perm[1];
                const dx = two.c - one.c;
                const dy = two.r - one.r;

                switch (part) {
                    .one => {
                        const nx = one.r - dy;
                        const ny = one.c - dx;
                        if (!self.contains(Point{ .c = nx, .r = ny })) continue;
                        try self.nodes.put(Point{ .r = ny, .c = nx }, true);
                    },
                    .two => {
                        var n = one;
                        while (self.contains(n)) : (n = Point{ .r = n.r - dy, .c = n.c - dx }) {
                            try self.nodes.put(n, true);
                        }
                    },
                }
            }
        }

        return self.nodes.count();
    }

    pub fn init(lines: [][]u8, alloc: std.mem.Allocator) !Self {
        var instance = Self{
            .alloc = alloc,
            .mapping = std.AutoHashMap(u8, std.ArrayList(Point)).init(alloc),
            .lines = lines,
            .nodes = std.AutoHashMap(Point, bool).init(alloc),
        };

        for (lines, 0..) |ln, row| {
            for (ln, 0..) |ch, col| {
                if (ch == '.') continue;

                const p: Point = .{ .r = @intCast(row), .c = @intCast(col) };
                if (!instance.mapping.contains(ch)) {
                    var lst = std.ArrayList(Point).init(alloc);
                    try lst.append(p);
                    try instance.mapping.put(ch, lst);
                } else {
                    var lst = instance.mapping.get(ch).?;
                    try lst.append(p);
                    try instance.mapping.put(ch, lst);
                }
            }
        }

        instance.rows = lines.len;
        instance.cols = lines[0].len;

        return instance;
    }

    pub fn deinit(self: *Self) void {
        var iter = self.mapping.iterator();
        while (iter.next()) |lst| {
            lst.value_ptr.*.deinit();
        }
        self.mapping.deinit();
        self.nodes.deinit();
    }

    fn contains(self: *Self, p: Point) bool {
        return p.c >= 0 and p.c < self.cols and p.r >= 0 and p.r < self.rows;
    }
};

pub fn solve(rdr: anytype, part: lib.Part) !usize {
    const alloc = std.heap.page_allocator;
    var lr = try lib.LineReader.init(rdr, alloc);
    defer lr.deinit();
    var solver = try Solver.init(lr.lines, alloc);
    defer solver.deinit();
    return try solver.count_antinodes(part);
}

pub fn main() !void {
    _ = try lib.run(usize, solve, "Day 8", input);
}

test "advent of code day 8 example part 1" {
    const alloc = std.testing.allocator;
    const test_input =
        \\......#....#
        \\...#....0...
        \\....#0....#.
        \\..#....0....
        \\....0....#..
        \\.#....A.....
        \\...#........
        \\#......#....
        \\........A...
        \\.........A..
        \\..........#.
        \\..........#.
    ;

    var stream = std.io.fixedBufferStream(test_input);

    var lr = try lib.LineReader.init(stream.reader(), alloc);
    defer lr.deinit();
    var solver = try Solver.init(lr.lines, alloc);
    defer solver.deinit();

    try std.testing.expect(try solver.count_antinodes(.one) == 33);
    try std.testing.expect(try solver.count_antinodes(.two) == 64);
}
