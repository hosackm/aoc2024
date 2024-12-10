const std = @import("std");
const days = .{
    @import("day1.zig"),
    @import("day2.zig"),
    @import("day3.zig"),
    @import("day4.zig"),
    @import("day5.zig"),
    @import("day6.zig"),
    @import("day7.zig"),
    @import("day8.zig"),
    @import("day9.zig"),
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
