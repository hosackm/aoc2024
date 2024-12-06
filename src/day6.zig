const std = @import("std");
const Part = @import("main.zig").Part;

pub const input = "data/input6.txt";

// Puzzle input is 130x130
const max_grid = 130 * 130;
// \n character for each row and 1 null byte just in case
const max_grid_buffer_size = max_grid + 131;

const Orientation = enum(u8) {
    left,
    right,
    up,
    down,

    fn delta(o: Orientation) struct { r: i2, c: i2 } {
        return switch (o) {
            .left => .{ .r = 0, .c = -1 },
            .right => .{ .r = 0, .c = 1 },
            .up => .{ .r = -1, .c = 0 },
            .down => .{ .r = 1, .c = 0 },
        };
    }
};

const StartInfo = struct {
    orientation: Orientation,
    row: usize,
    col: usize,
};

const PathState = enum {
    exited_normally,
    loop_detected,
    still_going,
};

const Pathwalker = struct {
    pos_x: usize,
    pos_y: usize,
    orientation: Orientation,

    pub fn init(info: StartInfo) Pathwalker {
        return Pathwalker{
            .pos_y = info.row,
            .pos_x = info.col,
            .orientation = info.orientation,
        };
    }

    pub fn tick(self: *Pathwalker, m: anytype) PathState {
        // Mark current grid location
        switch (self.orientation) {
            .up => m.*.history[self.pos_y][self.pos_x] |= 0b1000,
            .down => m.*.history[self.pos_y][self.pos_x] |= 0b0100,
            .left => m.*.history[self.pos_y][self.pos_x] |= 0b0010,
            .right => m.*.history[self.pos_y][self.pos_x] |= 0b0001,
        }

        // Forecast next location
        const d = self.orientation.delta();
        const next_x: i32 = @intCast(@as(i32, @intCast(self.pos_x)) + d.c);
        const next_y: i32 = @intCast(@as(i32, @intCast(self.pos_y)) + d.r);

        // We're exiting the maze
        if (next_x < 0 or next_x == m.*.num_cols or next_y < 0 or next_y == m.*.num_rows) {
            return .exited_normally;
        }

        // Change orientation if we're about to hit an obstacle
        const next_ch = m.*.grid[@intCast(next_y)][@intCast(next_x)];
        if (next_ch == '#') {
            self.orientation =
                switch (self.orientation) {
                .left => .up,
                .up => .right,
                .right => .down,
                .down => .left,
            };
        } else {
            self.pos_x = @intCast(next_x);
            self.pos_y = @intCast(next_y);
        }

        // Check if we've already moved through the next grid point
        // with this orientation (ie. we're in a loop)
        const next_history = m.*.history[@intCast(next_y)][@intCast(next_x)];
        switch (self.orientation) {
            .up => if (next_history & 0b1000 > 0) return .loop_detected,
            .down => if (next_history & 0b0100 > 0) return .loop_detected,
            .left => if (next_history & 0b0010 > 0) return .loop_detected,
            .right => if (next_history & 0b0001 > 0) return .loop_detected,
        }

        return .still_going;
    }
};

fn Grid(rows: usize, cols: usize) type {
    return struct {
        grid: [rows][cols]u8 = undefined,
        history: [rows][cols]u4 = undefined,
        num_rows: usize = rows,
        num_cols: usize = cols,

        const Self = @This();

        pub fn init(bytes: []const u8) Self {
            var m = Self{};
            m.fill(bytes);
            return m;
        }

        pub fn fill(self: *Self, bytes: []const u8) void {
            for (0..self.num_rows) |r| {
                for (0..self.num_cols) |c| {
                    self.grid[r][c] = bytes[r * self.num_cols + c];
                    self.history[r][c] = 0;
                }
            }
        }

        pub fn display(self: *Self) void {
            for (0..self.num_rows) |r| {
                std.debug.print("{s}\n", .{self.grid[r]});
            }
        }

        pub fn find_starting_point_and_orientation(self: *Self) StartInfo {
            var row: usize = 0;
            var col: usize = 0;
            for (0..self.num_rows) |r| {
                for (0..self.num_cols) |c| {
                    if (self.grid[r][c] == '^') {
                        row = r;
                        col = c;
                    }
                }
            }
            return StartInfo{
                .orientation = .up,
                .col = col,
                .row = row,
            };
        }

        pub fn count(self: *Self) i32 {
            var total: i32 = 0;
            for (0..self.num_rows) |r| {
                for (0..self.num_cols) |c| {
                    if (self.history[r][c] > 0) total += 1;
                }
            }
            return total;
        }

        pub fn clear_history(self: *Self) void {
            for (0..self.num_rows) |r| {
                for (0..self.num_cols) |c| {
                    self.history[r][c] = 0;
                }
            }
        }
    };
}

pub fn solve(rdr: anytype, part: Part) !i32 {
    const alloc = std.heap.page_allocator;
    const bytes = try rdr.readAllAlloc(alloc, max_grid_buffer_size);
    defer alloc.free(bytes);

    var buffer: [max_grid_buffer_size]u8 = undefined;
    _ = try rdr.readAll(&buffer);

    var bytes_stripped: [max_grid_buffer_size]u8 = undefined;
    _ = std.mem.replace(
        u8,
        bytes,
        "\n",
        "",
        &bytes_stripped,
    );

    const side = 130;

    const Matrix = Grid(side, side);

    if (part == .one) {
        var matrix = Matrix.init(&bytes_stripped);
        const info = matrix.find_starting_point_and_orientation();
        var p = Pathwalker.init(info);

        while (true) {
            switch (p.tick(&matrix)) {
                .loop_detected => {
                    std.debug.print("loop detected\n", .{});
                    break;
                },
                .still_going => {},
                .exited_normally => {
                    std.debug.print("exited normally\n", .{});
                    break;
                },
            }
        }

        return matrix.count();
    } else {
        var matrix = Matrix.init(&bytes_stripped);
        var total: i32 = 0;
        for (0..side) |r| {
            for (0..side) |c| {
                if (matrix.grid[r][c] != '.') continue;

                // add obstruction
                matrix.grid[r][c] = '#';
                matrix.clear_history();

                const info = matrix.find_starting_point_and_orientation();
                var p = Pathwalker.init(info);

                while (true) {
                    switch (p.tick(&matrix)) {
                        .loop_detected => {
                            total += 1;
                            break;
                        },
                        .exited_normally => {
                            break;
                        },
                        else => {},
                    }
                }

                // remove obstruction
                matrix.grid[r][c] = '.';
            }
        }
        return total;
    }
}

test "day 6 example part 1" {
    const test_input: []const u8 =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    ;
    var input_buffer: [100]u8 = undefined;
    _ = std.mem.replace(u8, test_input, "\n", "", &input_buffer);

    var matrix = Grid(10, 10).init(&input_buffer);
    const info = matrix.find_starting_point_and_orientation();

    try std.testing.expect(info.orientation == .up);
    try std.testing.expect(info.row == 6);
    try std.testing.expect(info.col == 4);

    var p = Pathwalker.init(info);
    while (p.tick(&matrix) == .still_going) {}
    try std.testing.expect(matrix.count() == 41);
}

test "day 6 example part 2 loop detected" {
    const test_input: []const u8 =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......##..
    ;
    var input_buffer: [100]u8 = undefined;
    _ = std.mem.replace(u8, test_input, "\n", "", &input_buffer);

    var matrix = Grid(10, 10).init(&input_buffer);
    const info = matrix.find_starting_point_and_orientation();

    var p = Pathwalker.init(info);
    var steps: u32 = 0;
    while (true) {
        steps += 1;
        const result = p.tick(&matrix);
        switch (result) {
            .still_going => continue,
            .loop_detected => break, // good
            .exited_normally => try std.testing.expect(false),
        }
    }
}
