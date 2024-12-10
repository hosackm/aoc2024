const lib = @import("lib.zig");
const std = @import("std");
const Part = lib.Part;
pub const input = "data/input5.txt";

const Mapping = struct {
    before: u8,
    after: u8,
};

pub fn main() !void {
    _ = try lib.run(i32, solve, "Day 5", input);
}

pub fn solve(rdr: anytype, part: Part) !i32 {
    _ = rdr;
    _ = part;

    // const alloc = std.heap.page_allocator;

    // const bytes = try rdr.readAllAlloc(alloc, 100000);
    // defer alloc.free(bytes);

    // var mappings = std.ArrayList(Mapping).init(alloc);

    // var lines_iter = std.mem.splitScalar(u8, bytes, '\n');
    // while (lines_iter.next()) |line| {
    //     if (std.mem.containsAtLeast(u8, line, 1, "|")) {
    //         var num_iter = std.mem.splitScalar(u8, line, '|');
    //         const before: []const u8 = num_iter.next().?;
    //         const after: []const u8 = num_iter.next().?;
    //         try mappings.append(.{
    //             .before = try std.fmt.parseInt(u8, before, 10),
    //             .after = try std.fmt.parseInt(u8, after, 10),
    //         });
    //     }
    //     if (std.mem.containsAtLeast(u8, line, 1, ",")) {
    //         var num_iter = std.mem.splitScalar(u8, line, '|');
    //         const before: []const u8 = num_iter.next().?;
    //         const after: []const u8 = num_iter.next().?;
    //         try mappings.append(.{
    //             .before = try std.fmt.parseInt(u8, before, 10),
    //             .after = try std.fmt.parseInt(u8, after, 10),
    //         });
    //     }
    //     std.debug.print("line: {s}\n", .{line});
    // }

    return 0;
}
