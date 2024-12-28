const std = @import("std");
const days = .{
    @import("day01.zig"),
    @import("day02.zig"),
    @import("day03.zig"),
    @import("day04.zig"),
    @import("day05.zig"),
    @import("day06.zig"),
    @import("day07.zig"),
    @import("day08.zig"),
    @import("day09.zig"),
    @import("day10.zig"),
    @import("day11.zig"),
    @import("day12.zig"),
    @import("day13.zig"),
    @import("day14.zig"),
    @import("day15.zig"),
    @import("day17.zig"),
    @import("day18.zig"),
    @import("day19.zig"),
};

pub fn main() !void {
    inline for (days, 1..) |day, nday| {
        std.debug.print("Day {d}\n", .{nday});
        inline for (.{ .one, .two }, 1..) |part, npart| {
            const f = try std.fs.cwd().openFile(day.input, .{});
            defer f.close();
            std.debug.print(
                "  [{d} of 2]: {d}\n",
                .{ npart, try day.solve(f.reader(), part) },
            );
        }
    }
}
