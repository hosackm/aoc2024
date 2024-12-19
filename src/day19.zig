const std = @import("std");
const lib = @import("lib.zig");

pub const input = "data/input19.txt";

fn combinations(pattern: []const u8, towels: []const []const u8, alloc: std.mem.Allocator) !usize {
    var d = try alloc.alloc(usize, pattern.len + 1);
    defer alloc.free(d);
    @memset(d, 0);

    d[0] = 1;
    for (1..pattern.len + 1) |n| {
        for (towels) |t| {
            if (!std.mem.endsWith(u8, pattern[0..n], t)) continue;
            d[n] += d[n - t.len];
        }
    }

    return d[pattern.len];
}

pub fn solve(rdr: anytype, part: lib.Part) !usize {
    const alloc = std.heap.page_allocator;
    var lr = try lib.LineReader.init(rdr, alloc);
    defer lr.deinit();

    var towels = std.ArrayList([]const u8).init(alloc);
    defer towels.deinit();

    var iter = std.mem.splitSequence(u8, lr.lines[0], ", ");
    while (iter.next()) |towel| {
        try towels.append(towel);
    }

    var patterns = std.ArrayList([]const u8).init(alloc);
    defer patterns.deinit();
    for (lr.lines[2..]) |ln| {
        const s = std.mem.trim(u8, ln, &std.ascii.whitespace);
        try patterns.append(s);
    }

    var total: usize = 0;
    for (patterns.items) |pattern| {
        const n = try combinations(pattern, towels.items, alloc);
        total += if (part == .one) (if (n > 0) 1 else 0) else n;
    }
    return total;
}

pub fn main() !void {
    try lib.run(usize, solve, "Day 19", input);
}

test "test advent example" {
    const patterns: []const []const u8 = &.{
        "brwrr",
        "bggr",
        "gbbr",
        "rrbgbr",
        "ubwu",
        "bwurrg",
        "brgr",
        "bbrgwb",
    };
    const towels: []const []const u8 = &.{
        "r",
        "wr",
        "b",
        "g",
        "bwu",
        "rb",
        "gb",
        "br",
    };
    const expected = [_]usize{ 2, 1, 4, 6, 0, 1, 2, 0 };
    for (expected, 0..) |exp, n| {
        try std.testing.expect(try combinations(
            patterns[n],
            towels,
            std.testing.allocator,
        ) == exp);
    }
}
