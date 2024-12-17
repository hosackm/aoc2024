const std = @import("std");
const lib = @import("lib.zig");
pub const input = "data/input15.txt";

const Mat = struct {
    grid: [][]u8 = undefined,
    moves: []u8 = undefined,
    rows: usize = 0,
    cols: usize = 0,
    rx: i64 = 0,
    ry: i64 = 0,
    alloc: std.mem.Allocator,

    const Self = @This();
    fn init(lines: [][]u8, alloc: std.mem.Allocator) Self {
        var s = Self{
            .cols = lines[0].len,
            .alloc = alloc,
        };
        var grid_list = std.ArrayList([]u8).init(alloc);
        var moves_list = std.ArrayList(u8).init(alloc);
        var row_count: usize = 0;

        for (lines, 0..) |row, r| {
            if (std.mem.count(u8, row, ">") > 0 or
                std.mem.count(u8, row, "^") > 0 or
                std.mem.count(u8, row, "<") > 0 or
                std.mem.count(u8, row, "v") > 0)
            {
                for (row) |ch| {
                    if (ch == '\n') continue;
                    moves_list.append(ch) catch unreachable;
                }
            } else if (std.mem.count(u8, row, "#") > 0) {
                row_count += 1;
                var row_list = std.ArrayList(u8).init(alloc);
                for (row, 0..) |ch, c| {
                    if (ch == '@') {
                        s.rx = @intCast(c);
                        s.ry = @intCast(r);
                    }
                    row_list.append(ch) catch unreachable;
                }

                grid_list.append(row_list.toOwnedSlice() catch unreachable) catch unreachable;
            }
        }
        s.grid = grid_list.toOwnedSlice() catch unreachable;
        s.moves = moves_list.toOwnedSlice() catch unreachable;
        s.rows = row_count;
        return s;
    }

    fn deinit(self: Self) void {
        for (self.grid) |row| {
            self.alloc.free(row);
        }
        self.alloc.free(self.grid);
        self.alloc.free(self.moves);
    }

    fn swap(self: Self, ay: i64, ax: i64, by: i64, bx: i64) void {
        const ayu: usize = @intCast(ay);
        const axu: usize = @intCast(ax);
        const byu: usize = @intCast(by);
        const bxu: usize = @intCast(bx);
        const tmp = self.grid[byu][bxu];
        self.grid[byu][bxu] = self.grid[ayu][axu];
        self.grid[ayu][axu] = tmp;
    }

    fn move(self: *Self, direction: u8) void {
        const delta: struct { y: i8, x: i8 } = switch (direction) {
            '>' => .{ .y = 0, .x = 1 },
            '^' => .{ .y = -1, .x = 0 },
            '<' => .{ .y = 0, .x = -1 },
            'v' => .{ .y = 1, .x = 0 },
            else => unreachable,
        };

        const new_y = @as(i64, @intCast(self.ry)) + delta.y;
        const new_x = @as(i64, @intCast(self.rx)) + delta.x;

        const ch = self.grid[@intCast(new_y)][@intCast(new_x)];
        switch (ch) {
            '#' => {},
            '.' => {
                self.swap(self.ry, self.rx, new_y, new_x);
                self.ry = new_y;
                self.rx = new_x;
            },
            'O' => {
                // find end of string of boxes
                var end_y = new_y + delta.y;
                var end_x = new_x + delta.x;
                while (self.grid[@intCast(end_y)][@intCast(end_x)] == 'O') {
                    end_y += delta.y;
                    end_x += delta.x;
                }
                // ends with a wall, ie. can't move
                if (self.grid[@intCast(end_y)][@intCast(end_x)] == '#') return;

                while (end_y != self.ry or end_x != self.rx) {
                    self.swap(end_y, end_x, end_y - delta.y, end_x - delta.x);
                    end_y -= delta.y;
                    end_x -= delta.x;
                }
                // move robot
                self.ry = new_y;
                self.rx = new_x;
            },
            else => unreachable,
        }
    }

    fn simulate(self: *Self) void {
        for (self.moves) |mv| {
            self.move(mv);
        }
    }

    fn calculate(self: Self) usize {
        var total: usize = 0;
        for (0..self.rows) |r| {
            for (0..self.cols) |c| {
                if (self.grid[r][c] == 'O') total += 100 * r + c;
            }
        }
        return total;
    }
};

pub fn solve(rdr: anytype, part: lib.Part) !usize {
    _ = part;
    const alloc = std.heap.page_allocator;
    var lr = try lib.LineReader.init(rdr, alloc);
    defer lr.deinit();

    var m = Mat.init(lr.lines, alloc);
    defer m.deinit();

    m.simulate();
    return m.calculate();
}

pub fn main() !void {
    try lib.run(usize, solve, "Day 14", input);
}

test "parse grid" {
    const s =
        \\##########
        \\#..O..O.O#
        \\#......O.#
        \\#.OO..O.O#
        \\#..O@..O.#
        \\#O#..O...#
        \\#O..O..O.#
        \\#.OO.O.OO#
        \\#....O...#
        \\##########
        \\
        \\<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
        \\vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
        \\><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
        \\<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
        \\^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
        \\^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
        \\>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
        \\<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
        \\^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
        \\v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
    ;

    var stream = std.io.fixedBufferStream(s);
    const alloc = std.testing.allocator;
    var lr = try lib.LineReader.init(stream.reader(), alloc);
    defer lr.deinit();

    var m = Mat.init(lr.lines, alloc);
    defer m.deinit();

    try std.testing.expect(m.rows == 10);
    try std.testing.expect(m.cols == 10);
    try std.testing.expect(m.rx == 4);
    try std.testing.expect(m.ry == 4);

    m.simulate();
    try std.testing.expect(m.calculate() == 10092);
}
