const std = @import("std");
const days = .{
    @import("day1.zig"),
    @import("day2.zig"),
    @import("day3.zig"),
    @import("day4.zig"),
};

pub const Part = enum {
    one,
    two,
};

pub fn main() !void {
    inline for (days, 1..) |day, nday| {
        inline for (.{ .one, .two }, 1..) |part, npart| {
            const f = try std.fs.cwd().openFile(day.input, .{});
            defer f.close();
            std.debug.print("Day {d}\n", .{nday});
            std.debug.print(
                "  [{d} of 2]: {d}\n",
                .{ npart, try day.solve(f.reader(), part) },
            );
        }
    }
}
