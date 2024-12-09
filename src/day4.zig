const std = @import("std");
const Part = @import("lib.zig").Part;
pub const input = "data/input4.txt";

pub fn Matrix() type {
    return struct {
        rows: usize = 0,
        cols: usize = 0,
        data: []u8 = undefined,
        alloc: std.mem.Allocator,

        const Self = @This();
        const Dimensions = struct { r: usize, c: usize };

        pub fn init(rdr: anytype, r: usize, c: usize, alloc: std.mem.Allocator) !Self {
            var s = Self{
                .rows = r,
                .cols = c,
                .alloc = alloc,
            };
            try s.load(rdr);
            return s;
        }

        // pub fn init(rdr: anytype, alloc: std.mem.Allocator) !Self {
        //     const dim = try get_dimensions(rdr);
        //     var s = Self{
        //         .rows = dim.r,
        //         .cols = dim.c,
        //         .alloc = alloc,
        //     };
        //     try s.load(rdr);
        //     return s;
        // }

        pub fn at(self: *Self, row: usize, col: usize) !u8 {
            if (row < 0 or row >= self.rows or col < 0 or col >= self.cols) return error.OutOfBounds;
            return self.data[row * self.cols + col];
        }

        pub fn deinit(self: *Self) void {
            self.alloc.free(self.data);
        }

        fn get_dimensions(rdr: anytype) !Dimensions {
            var buffer: [140 * 140]u8 = undefined; // max size of input
            var s: Dimensions = .{ .r = 0, .c = 0 };

            _ = try rdr.readAll(&buffer);
            var iter = std.mem.splitScalar(u8, &buffer, '\n');
            const first_row = iter.first();
            s.r += 1;

            while (iter.next()) |_| {
                s.r += 1;
            }

            s.c = first_row.len;
            return s;
        }

        fn load(self: *Self, rdr: anytype) !void {
            var buffer: [140]u8 = undefined;
            const d = try get_dimensions(rdr);
            self.data = try self.alloc.alloc(u8, d.r * d.c);

            var r: usize = 0;
            while (try rdr.readUntilDelimiterOrEof(&buffer, '\n')) |line| : (r += 1) {
                // std.debug.print("loading: {s}\n", .{line});
                for (line, 0..) |ch, col| {
                    self.data[r * self.cols + col] = ch;
                }
                // std.debug.print("loaded : {s}\n", .{self.data[r * self.cols .. r * self.cols + line.len]});
            }
        }
    };
}

pub fn solve(
    rdr: anytype,
    part: Part,
) !i32 {
    _ = part;
    var m = try Matrix().init(rdr, 140, 140, std.heap.page_allocator);
    defer m.deinit();
    // std.debug.print("    Matrix [{d},{d}] = ...\n", .{ m.rows, m.cols });

    return 0;
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
    var stream = std.io.fixedBufferStream(test_input);
    var m = try Matrix().init(stream.reader(), 10, 10, std.testing.allocator);
    defer m.deinit();

    try std.testing.expect(m.rows == 10);
    try std.testing.expect(m.cols == 10);

    std.debug.print("{c}\n", .{m.data[0]});

    // try std.testing.expect(try m.at(0, 0) == 'M');
}
