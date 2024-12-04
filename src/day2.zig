const std = @import("std");
const Part = @import("main.zig").Part;

pub const input = "data/input2.txt";

const Direction = enum(u1) {
    incr,
    decr,
};

const FuncWrapper = struct { func: *const fn (i8, i8) bool };

fn cmp_incr(x: i8, y: i8) bool {
    return x - y <= 0 or x - y > 3;
}

fn cmp_decr(x: i8, y: i8) bool {
    return x - y >= 0 or x - y < -3;
}

fn is_stable(nums: []i8, part: Part) !bool {
    var num_list = std.ArrayList(i8).init(std.heap.page_allocator);
    defer num_list.deinit();
    for (nums) |n| try num_list.append(n);

    return try all_in_order_recursive(
        num_list,
        .incr,
        part == .two,
    ) or try all_in_order_recursive(
        num_list,
        .decr,
        part == .two,
    );
}

fn clone_except(original: std.ArrayList(i8), index: usize) !std.ArrayList(i8) {
    var copy = try original.clone();
    _ = copy.orderedRemove(index);
    return copy;
}

fn all_in_order_recursive(nums: std.ArrayList(i8), d: Direction, can_skip: bool) !bool {
    var x: usize = 1;
    const f: FuncWrapper = .{ .func = if (d == .incr)
        cmp_incr
    else
        cmp_decr };

    while (x < nums.items.len) : (x += 1) {
        if (f.func(nums.items[x], nums.items[x - 1])) {
            if (can_skip) {
                inline for (.{ x, x - 1 }) |i| {
                    const copy = try clone_except(nums, i);
                    defer copy.deinit();
                    if (try all_in_order_recursive(copy, d, false)) return true;
                }
            }
            return false;
        }
    }
    return true;
}

fn line_to_slice(line: []const u8, buf: []i8) ![]i8 {
    var index: usize = 1;
    var iter = std.mem.splitScalar(u8, line, ' ');
    buf[0] = try std.fmt.parseInt(i8, iter.first(), 10);
    while (iter.next()) |num| : (index += 1) {
        buf[index] = try std.fmt.parseInt(i8, num, 10);
    }
    return buf[0..index];
}

pub fn solve(rdr: anytype, part: Part) !i32 {
    var buffer: [100]u8 = undefined;
    var num_buffer: [8]i8 = undefined;
    var total: i32 = 0;
    while (try rdr.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        const nums = try line_to_slice(line, &num_buffer);
        total += if (try is_stable(nums, part)) 1 else 0;
    }
    return total;
}

test "advent of code part 1" {
    const test_input =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;
    var stream = std.io.fixedBufferStream(test_input);
    try std.testing.expect(try solve(stream.reader(), .one) == 2);
}

test "advent of code part 2" {
    const test_input =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;
    var stream = std.io.fixedBufferStream(test_input);
    try std.testing.expect(try solve(stream.reader(), .two) == 4);
}
