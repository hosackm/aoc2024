const lib = @import("lib.zig");
const std = @import("std");
const Part = lib.Part;
pub const input = "data/input5.txt";

const Mapping = struct {
    before: u8,
    after: u8,
};

const PageUpdater = struct {
    const SetType = std.ArrayList(u8);
    const HashType = std.AutoHashMap(u8, SetType);
    const UpdateList = []u8;
    const UpdateLists = std.ArrayList(UpdateList);
    before: HashType,
    update_lists: UpdateLists,
    alloc: std.mem.Allocator,

    const Self = @This();
    fn init(alloc: std.mem.Allocator) Self {
        return .{
            .before = HashType.init(alloc),
            .update_lists = UpdateLists.init(alloc),
            .alloc = alloc,
        };
    }

    fn count_valid_updates(self: *Self, part: lib.Part) usize {
        var total: usize = 0;
        for (self.update_lists.items) |*update_list| {
            var correction_required: bool = false;
            for (0..update_list.len - 1) |i| {
                for (i + 1..update_list.len) |j| {
                    if (self.before.contains(update_list.*[j]) and
                        std.mem.containsAtLeast(
                        u8,
                        self.before.get(update_list.*[j]).?.items,
                        1,
                        &[_]u8{update_list.*[i]},
                    )) {
                        correction_required = true;
                        if (part == .two) {
                            const tmp = update_list.*[i];
                            update_list.*[i] = update_list.*[j];
                            update_list.*[j] = tmp;
                        }
                    }
                }
            }

            const middle = update_list.*[update_list.len / 2];
            switch (part) {
                .one => {
                    if (!correction_required) total += middle;
                },
                .two => {
                    if (correction_required) total += middle;
                },
            }
        }
        return total;
    }

    fn load_rules(self: *Self, lines: [][]const u8) !void {
        for (lines) |ln| {
            if (std.mem.containsAtLeast(u8, ln, 1, "|")) {
                var iter = std.mem.splitScalar(u8, ln, '|');
                const gop = try self.before.getOrPut(try std.fmt.parseInt(
                    u8,
                    iter.next().?,
                    10,
                ));
                if (!gop.found_existing) gop.value_ptr.* = SetType.init(self.alloc);
                try gop.value_ptr.*.append(try std.fmt.parseInt(
                    u8,
                    iter.next().?,
                    10,
                ));
            } else if (std.mem.containsAtLeast(u8, ln, 1, ",")) {
                var list = std.ArrayList(u8).init(self.alloc);
                var iter = std.mem.splitScalar(u8, ln, ',');
                while (iter.next()) |num_str| {
                    const num = try std.fmt.parseInt(u8, num_str, 10);
                    try list.append(num);
                }
                try self.update_lists.append(try list.toOwnedSlice());
            }
        }
    }

    fn deinit(self: *Self) void {
        var iter = self.before.valueIterator();
        while (iter.next()) |list| {
            list.deinit();
        }
        self.before.deinit();
        for (self.update_lists.items) |list| {
            self.alloc.free(list);
        }
        self.update_lists.deinit();
    }
};

pub fn main() !void {
    _ = try lib.run(usize, solve, "Day 5", input);
}

pub fn solve(rdr: anytype, part: Part) !usize {
    const alloc = std.heap.page_allocator;
    var lr = try lib.LineReader.init(rdr, alloc);
    defer lr.deinit();

    var p = PageUpdater.init(alloc);
    defer p.deinit();
    try p.load_rules(lr.lines);

    return p.count_valid_updates(part);
}

test "advent of code part one" {
    const test_input =
        \\47|53
        \\97|13
        \\97|61
        \\97|47
        \\75|29
        \\61|13
        \\75|53
        \\29|13
        \\97|29
        \\53|29
        \\61|53
        \\97|53
        \\61|29
        \\47|13
        \\75|47
        \\97|75
        \\47|61
        \\75|61
        \\47|29
        \\75|13
        \\53|13
        \\
        \\75,47,61,53,29
        \\97,61,53,29,13
        \\75,29,13
        \\75,97,47,61,53
        \\61,13,29
        \\97,13,75,29,47
    ;
    const alloc = std.testing.allocator;
    var stream = std.io.fixedBufferStream(test_input);

    var lr = try lib.LineReader.init(stream.reader(), alloc);
    defer lr.deinit();

    var p = PageUpdater.init(alloc);
    defer p.deinit();
    try p.load_rules(lr.lines);

    try std.testing.expect(p.before.count() == 6);
    try std.testing.expect(p.count_valid_updates(.one) == 143);
    try std.testing.expect(p.count_valid_updates(.two) == 123);
}
