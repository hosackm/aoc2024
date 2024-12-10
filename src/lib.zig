const std = @import("std");

pub const Part = enum {
    one,
    two,
};

pub fn run(T: type, func: fn (anytype, Part) anyerror!T, name: []const u8, input: []const u8) !void {
    std.debug.print("{s}\n", .{name});
    inline for (.{ .one, .two }, 1..) |part, npart| {
        const f = try std.fs.cwd().openFile(input, .{});
        defer f.close();
        std.debug.print(
            "  [{d} of 2]: {d}\n",
            .{ npart, try func(f.reader(), part) },
        );
    }
}

pub const LineReader = struct {
    lines: [][]u8 = undefined,
    alloc: std.mem.Allocator,

    const Self = @This();

    pub fn init(rdr: anytype, alloc: std.mem.Allocator) !Self {
        var ln_list = std.ArrayList([]u8).init(alloc);
        defer ln_list.deinit();

        while (try rdr.readUntilDelimiterOrEofAlloc(alloc, '\n', 1000)) |line| {
            try ln_list.append(line);
        }

        return .{
            .alloc = alloc,
            .lines = try ln_list.toOwnedSlice(),
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.lines) |ln| {
            self.alloc.free(ln);
        }
        self.alloc.free(self.lines);
    }
};

pub fn read_lines(rdr: anytype, alloc: std.mem.Allocator) ![][]u8 {
    var lines = std.ArrayList([]u8).init(alloc);
    defer lines.deinit();

    while (try rdr.readUntilDelimiterOrEofAlloc(alloc, '\n', 1000)) |line| {
        // defer alloc.free(line);
        try lines.append(line);
    }

    return lines.toOwnedSlice();
}

pub fn free_lines(lines: [][]u8, alloc: std.mem.Allocator) void {
    for (lines) |ln| {
        alloc.free(ln);
    }
    alloc.free(lines);
}
