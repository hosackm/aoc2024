const lib = @import("lib.zig");
const std = @import("std");
pub const input = "data/input13.txt";

fn calc(nums: []usize, part: lib.Part) usize {
    const ax: i64 = @intCast(nums[0]);
    const ay: i64 = @intCast(nums[1]);
    const bx: i64 = @intCast(nums[2]);
    const by: i64 = @intCast(nums[3]);
    var gx: i64 = @intCast(nums[4]);
    var gy: i64 = @intCast(nums[5]);
    if (part == .two) {
        gx += 10_000_000_000_000;
        gy += 10_000_000_000_000;
    }

    const divisor = bx * ay - by * ax;
    const a = @divTrunc((bx * gy - by * gx), divisor);
    const b = @divTrunc((ay * gx - ax * gy), divisor);

    return if (3 * a + b > 0 and
        a * ax + b * bx == gx and
        a * ay + b * by == gy)
        @intCast(3 * a + b)
    else
        0;
}

pub fn solve(rdr: anytype, part: lib.Part) !usize {
    const alloc = std.heap.page_allocator;

    const data = try rdr.readAllAlloc(alloc, 10000000);
    defer alloc.free(data);

    const num_numbers: usize = 1920;
    var numbers = try alloc.alloc(usize, num_numbers);
    defer alloc.free(numbers);

    var current_number: usize = 0;
    var start: usize = 0;
    var end: usize = 0;
    while (current_number < num_numbers) {
        start = if (end > 0) end + 1 else 0;
        while (!std.ascii.isDigit(data[start])) {
            start += 1;
        }
        end = start + 1;
        while (end < data.len and std.ascii.isDigit(data[end])) {
            end += 1;
        }

        numbers[current_number] = try std.fmt.parseInt(usize, data[start..end], 10);
        current_number += 1;
    }

    var total: usize = 0;
    const num_groups: usize = @divTrunc(numbers.len, 6);
    for (0..num_groups) |i| {
        const this_calc = calc(numbers[i * 6 .. i * 6 + 6], part);
        total += this_calc;
    }

    return total;
}

pub fn main() !void {
    _ = try lib.run(
        usize,
        solve,
        "Day 13",
        input,
    );
}
