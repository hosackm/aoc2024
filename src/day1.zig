const std = @import("std");
const Part = @import("main.zig").Part;

pub const input = "data/input1.txt";

fn sorted_slices_reader(rdr: anytype, part: Part) !i32 {
    var buffer: [100]u8 = undefined;
    var left: [1000]i32 = undefined;
    var right: [1000]i32 = undefined;

    var i: u32 = 0;
    while (try rdr.readUntilDelimiterOrEof(&buffer, '\n')) |line| : (i += 1) {
        var iter = std.mem.splitSequence(u8, line, "   ");
        left[i] = try std.fmt.parseInt(i32, std.mem.trim(u8, iter.first(), " "), 10);
        right[i] = try std.fmt.parseInt(i32, std.mem.trim(u8, iter.next().?, " "), 10);
    }

    const lsl = left[0..i];
    const rsl = right[0..i];

    std.mem.sort(i32, lsl, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, rsl, {}, comptime std.sort.asc(i32));

    return switch (part) {
        .one => sum_diffs(lsl, rsl),
        .two => sum_instances(lsl, rsl),
    };
}

fn sum_diffs(first: []const i32, second: []const i32) i32 {
    var total: i32 = 0;
    for (first, second) |left, right| {
        total += @intCast(@abs(left - right));
    }
    return total;
}

fn sum_instances(first: []const i32, second: []const i32) !i32 {
    var counter = std.AutoHashMap(i32, i32).init(std.heap.page_allocator);
    defer counter.deinit();

    for (second) |num| {
        const entry = try counter.getOrPutValue(num, 0);
        entry.value_ptr.* += 1;
    }

    var total: i32 = 0;
    for (first) |num| {
        const count = counter.get(num) orelse 0;
        total += num * count;
    }
    return total;
}

pub fn solve(rdr: anytype, part: Part) !i32 {
    return sorted_slices_reader(rdr, part);
}

test "advent of code examples" {
    const test_input =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;
    var stream = std.io.fixedBufferStream(test_input);
    try std.testing.expect(try sorted_slices_reader(stream.reader(), .one) == 11);

    stream = std.io.fixedBufferStream(test_input);
    const output = try sorted_slices_reader(stream.reader(), .two);
    try std.testing.expect(output == 31);
}
