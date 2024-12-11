const lib = @import("lib.zig");
const std = @import("std");
pub const input = "data/input11.txt";

const Counter = struct {
    const HashType = std.AutoHashMap(usize, usize);

    items: HashType,
    alloc: std.mem.Allocator,

    const Self = @This();

    fn init(line: ?[]const u8, alloc: std.mem.Allocator) Self {
        var items = HashType.init(alloc);
        if (line) |ln| {
            var iter = std.mem.splitScalar(
                u8,
                ln,
                ' ',
            );
            while (iter.next()) |str| {
                const n = std.fmt.parseInt(
                    usize,
                    str,
                    10,
                ) catch unreachable;
                items.put(n, 1) catch unreachable;
            }
        }

        return .{
            .items = items,
            .alloc = alloc,
        };
    }

    fn deinit(self: *Self) void {
        self.items.deinit();
    }
};

const Solver = struct {
    counter: Counter = undefined,
    alloc: std.mem.Allocator,

    var buffer: [1000]u8 = undefined;
    const Self = @This();

    fn blink(self: *Self) !void {
        var new_counter = Counter.init(null, self.alloc);
        defer new_counter.deinit();

        const one_or_two = union(enum) {
            one: usize,
            two: [2]usize,
        };

        var iter = self.counter.items.iterator();
        while (iter.next()) |entry| {
            const num = entry.key_ptr.*;
            const cnt = entry.value_ptr.*;
            const num_str = to_str(num);

            const updates: one_or_two = if (num == 0)
                .{ .one = 1 }
            else if (num_str.len % 2 == 0)
                .{
                    .two = .{
                        to_num(num_str[0..@divTrunc(num_str.len, 2)]),
                        to_num(num_str[@divTrunc(num_str.len, 2)..]),
                    },
                }
            else
                .{ .one = num * 2024 };

            switch (updates) {
                .one => |n| {
                    var total = cnt;
                    const result = try new_counter.items.getOrPut(n);
                    if (result.found_existing) total += result.value_ptr.*;
                    result.value_ptr.* = total;
                },
                .two => |nums| {
                    for (nums) |n| {
                        var total = cnt;
                        const result = try new_counter.items.getOrPut(n);
                        if (result.found_existing) total += result.value_ptr.*;
                        result.value_ptr.* = total;
                    }
                },
            }
        }

        self.counter.items.clearAndFree();
        self.counter.items = try new_counter.items.clone();
    }

    fn to_str(n: usize) []u8 {
        return std.fmt.bufPrintIntToSlice(
            &buffer,
            n,
            10,
            .lower,
            .{},
        );
    }

    fn to_num(s: []u8) usize {
        return std.fmt.parseInt(usize, s, 10) catch 0;
    }

    fn count(self: *Self) usize {
        var iter = self.counter.items.valueIterator();
        var total: usize = 0;
        while (iter.next()) |e| {
            total += e.*;
        }
        return total;
    }

    fn init(line: []const u8, alloc: std.mem.Allocator) Self {
        return .{
            .counter = Counter.init(line, alloc),
            .alloc = alloc,
        };
    }

    fn deinit(self: *Self) void {
        self.counter.deinit();
    }
};

pub fn solve(rdr: anytype, part: lib.Part) !usize {
    const alloc = std.heap.page_allocator;
    const line = try rdr.readUntilDelimiterOrEofAlloc(alloc, '\n', 10000);
    defer alloc.free(line.?);

    var slv = Solver.init(line.?, alloc);
    defer slv.deinit();

    const count: usize = if (part == .one) 25 else 75;
    for (0..count) |_| {
        try slv.blink();
    }

    return slv.count();
}

pub fn main() !void {
    _ = try lib.run(
        usize,
        solve,
        "Day 11",
        input,
    );
}

test "advent example part one" {
    const s = "125 17";
    const alloc = std.testing.allocator;

    var c = Counter.init(s, alloc);
    defer c.deinit();

    try std.testing.expect(c.items.count() == 2);
    try std.testing.expect(c.items.get(125).? == 1);
    try std.testing.expect(c.items.get(17).? == 1);

    var slv = Solver.init(s, alloc);
    defer slv.deinit();

    var c2 = Counter.init(null, alloc);
    defer c2.deinit();
    try std.testing.expect(c2.items.count() == 0);

    try slv.blink();
    try std.testing.expect(slv.count() == 3);
    try slv.blink();
    try std.testing.expect(slv.count() == 4);
    try slv.blink();
    try std.testing.expect(slv.count() == 5);
    try slv.blink();
    try std.testing.expect(slv.count() == 9);
    try slv.blink();
    try std.testing.expect(slv.count() == 13);
    try slv.blink();
    try std.testing.expect(slv.count() == 22);
}
