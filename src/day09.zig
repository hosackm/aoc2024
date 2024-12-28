const std = @import("std");
const lib = @import("lib.zig");

pub const input = "data/input9.txt";

const PERIOD: i32 = -1;
const Span = struct {
    start: usize,
    end: usize,
};

fn get_files(layout: []i32, alloc: std.mem.Allocator) []Span {
    var files = std.ArrayList(Span).init(alloc);
    var start: usize = 0;
    var end: usize = start + 1;
    while (end < layout.len) {
        while (end < layout.len and layout[end] == layout[start]) end += 1;

        if (layout[start] != PERIOD) {
            files.append(Span{ .start = start, .end = end }) catch unreachable;
        }
        start = end;
        end = start + 1;
    }

    return files.toOwnedSlice() catch unreachable;
}

fn get_spaces(layout: []i32, alloc: std.mem.Allocator) []Span {
    var spaces = std.ArrayList(Span).init(alloc);
    var start: usize = 0;
    while (layout[start] != PERIOD) start += 1;

    var end = start + 1;
    while (end < layout.len) {
        while (end < layout.len and layout[end] == layout[start]) end += 1;

        if (layout[start] == PERIOD) spaces.append(Span{ .start = start, .end = end }) catch unreachable;

        start = end;
        end = start + 1;
    }

    return spaces.toOwnedSlice() catch unreachable;
}

fn compress(layout: []i32) void {
    var start: usize = 0;
    var end: usize = layout.len - 1;
    while (start < end) : (start += 1) {
        if (layout[start] != PERIOD) continue;
        layout[start] = layout[end];
        layout[end] = PERIOD;
        while (layout[end] == PERIOD) end -= 1;
    }
}

fn compress_part_two(layout: []i32, alloc: std.mem.Allocator) void {
    const files = get_files(layout, alloc);
    defer alloc.free(files);
    std.mem.reverse(Span, files);
    const spaces = get_spaces(layout, alloc);
    defer alloc.free(spaces);

    for (files) |f| {
        const fstart = f.start;
        const fend = f.end;
        const flen = f.end - f.start;
        for (spaces) |*sp| {
            const sstart = sp.*.start;
            const slen = sp.*.end - sp.*.start;

            if (fstart < sstart) break;

            if (flen <= slen) {
                var i: usize = 0;
                while (i < flen) : (i += 1) {
                    layout[sstart + i] = layout[fstart];
                    layout[fend - i - 1] = PERIOD;
                }

                // reassign to space list for next iteration
                sp.*.start += flen;
                break;
            }
        }
    }
}

fn calc_checksum(layout: []i32) u64 {
    var checksum: u64 = 0;
    for (layout, 0..) |digit, n| {
        checksum += @as(u64, @intCast(if (digit >= 0) digit else 0)) * n;
    }
    return checksum;
}

fn generate_layout(s: []const u8, alloc: std.mem.Allocator) ![]i32 {
    var layout = std.ArrayList(i32).init(alloc);
    for (s, 0..) |ch, i| {
        const val: i32 = if (i % 2 == 0) @intCast(@divTrunc(i, 2)) else PERIOD;
        for (0..ch - '0') |_| {
            try layout.append(val);
        }
    }
    return layout.toOwnedSlice();
}

pub fn solve(rdr: anytype, part: lib.Part) !u128 {
    // const s = "2333133121414131402";
    const alloc = std.heap.page_allocator;
    const s = try rdr.readAllAlloc(alloc, 100000);
    defer alloc.free(s);

    const layout = try generate_layout(s, alloc);
    defer alloc.free(layout);

    switch (part) {
        .one => compress(layout),
        .two => compress_part_two(layout, alloc),
    }
    return calc_checksum(layout);
}

pub fn main() !void {
    _ = try lib.run(u128, solve, "Day 9", input);
}

test "advent example part one" {
    const s = "2333133121414131402";
    const layout = try generate_layout(s, std.testing.allocator);
    defer std.testing.allocator.free(layout);

    try std.testing.expect(
        std.mem.eql(
            i32,
            &[_]i32{
                0,  0, -1, -1, -1, 1, 1, 1,  -1, -1, -1, 2, -1, -1,
                -1, 3, 3,  3,  -1, 4, 4, -1, 5,  5,  5,  5, -1, 6,
                6,  6, 6,  -1, 7,  7, 7, -1, 8,  8,  8,  8, 9,  9,
            },
            layout,
        ),
    );

    compress(layout);
    try std.testing.expect(calc_checksum(layout) == 1928);
}

test "advent example part two" {
    const s = "2333133121414131402";
    const layout = try generate_layout(s, std.testing.allocator);
    defer std.testing.allocator.free(layout);

    compress_part_two(layout, std.testing.allocator);
    try std.testing.expect(calc_checksum(layout) == 2858);
}
