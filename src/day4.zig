const std = @import("std");
const lib = @import("lib.zig");
const Part = lib.Part;
pub const input = "data/input4.txt";

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
                try row.append(ch);
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

    fn count_crossing_mas(self: Self) usize {
        var total: usize = 0;
        for (0..self.num_rows) |r| {
            for (0..self.num_cols) |c| {
                if (r == 0 or r == self.num_rows - 1 or
                    c == 0 or c == self.num_cols - 1 or
                    self.data[r][c] != 'A') continue;

                const diag1: [3]u8 = .{
                    self.data[r - 1][c - 1],
                    self.data[r][c],
                    self.data[r + 1][c + 1],
                };
                const diag2: [3]u8 = .{
                    self.data[r - 1][c + 1],
                    self.data[r][c],
                    self.data[r + 1][c - 1],
                };

                const is_one_mas = std.mem.eql(u8, &diag1, "MAS") or std.mem.eql(u8, &diag1, "SAM");
                const is_two_mas = std.mem.eql(u8, &diag2, "MAS") or std.mem.eql(u8, &diag2, "SAM");
                if (is_one_mas and is_two_mas) {
                    total += 1;
                }
            }
        }

        return total;
    }

    fn count_xmas(self: Self) usize {
        var count: usize = 0;
        for (0..self.num_rows) |r| {
            for (0..self.num_cols) |c| {
                const strings = self.get_directional_strings(.{ .r = r, .c = c });
                defer self.alloc.free(strings);
                for (strings) |s| {
                    if (std.mem.eql(u8, &s, "XMAS")) count += 1;
                }
            }
        }
        return count;
    }

    fn get_directional_strings(self: Self, pt: Point) [][4]u8 {
        var strings = std.ArrayList([4]u8).init(self.alloc);

        const x = pt.c;
        const y = pt.r;
        if (x < self.num_cols - 3) { // right
            strings.append(
                .{
                    self.data[y][x],
                    self.data[y][x + 1],
                    self.data[y][x + 2],
                    self.data[y][x + 3],
                },
            ) catch unreachable;
        }
        if (x >= 3) { // left
            strings.append(
                .{
                    self.data[y][x],
                    self.data[y][x - 1],
                    self.data[y][x - 2],
                    self.data[y][x - 3],
                },
            ) catch unreachable;
        }
        if (y >= 3) { // up
            strings.append(
                .{
                    self.data[y][x],
                    self.data[y - 1][x],
                    self.data[y - 2][x],
                    self.data[y - 3][x],
                },
            ) catch unreachable;
        }
        if (y < self.num_rows - 3) { // down
            strings.append(
                .{
                    self.data[y][x],
                    self.data[y + 1][x],
                    self.data[y + 2][x],
                    self.data[y + 3][x],
                },
            ) catch unreachable;
        }
        if (y >= 3 and x >= 3) { // up-left
            strings.append(
                .{
                    self.data[y][x],
                    self.data[y - 1][x - 1],
                    self.data[y - 2][x - 2],
                    self.data[y - 3][x - 3],
                },
            ) catch unreachable;
        }
        if (y >= 3 and x < self.num_cols - 3) { // up-right
            strings.append(
                .{
                    self.data[y][x],
                    self.data[y - 1][x + 1],
                    self.data[y - 2][x + 2],
                    self.data[y - 3][x + 3],
                },
            ) catch unreachable;
        }
        if (y < self.num_rows - 3 and x >= 3) { // down-left
            strings.append(
                .{
                    self.data[y][x],
                    self.data[y + 1][x - 1],
                    self.data[y + 2][x - 2],
                    self.data[y + 3][x - 3],
                },
            ) catch unreachable;
        }
        if (y < self.num_rows - 3 and x < self.num_cols - 3) { // down-right
            strings.append(
                .{
                    self.data[y][x],
                    self.data[y + 1][x + 1],
                    self.data[y + 2][x + 2],
                    self.data[y + 3][x + 3],
                },
            ) catch unreachable;
        }

        return strings.toOwnedSlice() catch unreachable;
    }
};

pub fn solve(
    rdr: anytype,
    part: Part,
) !usize {
    const alloc = std.heap.page_allocator;
    var lr = try lib.LineReader.init(rdr, alloc);
    defer lr.deinit();

    var m = try Mat.init(lr.lines, alloc);
    defer m.deinit();

    return switch (part) {
        .one => m.count_xmas(),
        .two => m.count_crossing_mas(),
    };
}

pub fn main() !void {
    _ = try lib.run(usize, solve, "Day 4", input);
}

test "matrix from input" {
    const test_input =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
    ;
    const alloc = std.testing.allocator;
    var stream = std.io.fixedBufferStream(test_input);

    var lr = try lib.LineReader.init(stream.reader(), alloc);
    defer lr.deinit();

    var m = try Mat.init(lr.lines, alloc);
    defer m.deinit();

    try std.testing.expect(m.data[0][0] == 'M');
    try std.testing.expect(std.mem.eql(u8, m.data[0], "MMMSXXMASM"));
    try std.testing.expect(m.num_rows == 10);
    try std.testing.expect(m.num_cols == 10);

    try std.testing.expect(m.count_xmas() == 18);
    try std.testing.expect(m.count_crossing_mas() == 9);
}
