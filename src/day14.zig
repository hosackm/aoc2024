const std = @import("std");
const lib = @import("lib.zig");
pub const input = "data/input14.txt";

const WIDTH: i64 = 101;
const HEIGHT: i64 = 103;
const NUM_ROBOTS: usize = 500;

const Robot = struct {
    px: i64 = 0,
    py: i64 = 0,
    vx: i64 = 0,
    vy: i64 = 0,

    const Self = @This();
    fn tick(self: *Self) void {
        self.px = @mod(self.px + self.vx, WIDTH);
        self.py = @mod(self.py + self.vy, HEIGHT);
    }

    fn tickn(self: *Self, n: i64) void {
        self.px = @mod(self.px + self.vx * n, WIDTH);
        self.py = @mod(self.py + self.vy * n, HEIGHT);
    }
};

fn count_quads(robots: []Robot) usize {
    var quads: [4]usize = .{ 0, 0, 0, 0 };
    for (robots) |r| {
        var which: usize = 0;
        if (r.px == WIDTH / 2 or r.py == HEIGHT / 2) continue;
        if (r.px > WIDTH / 2) which += 1;
        if (r.py > HEIGHT / 2) which += 2;
        quads[which] += 1;
    }

    return quads[0] * quads[1] * quads[2] * quads[3];
}

fn find_tree(robots: []Robot, n: usize) usize {
    var frame_num: usize = 1;
    var min_safety_factor: usize = 1_000_000_000_000_000;
    var min_frame: usize = 0;
    while (frame_num < n) : (frame_num += 1) {
        for (0..NUM_ROBOTS) |rn| {
            _ = &robots[rn].tick();
        }
        const safety_factor = count_quads(robots);
        if (safety_factor < min_safety_factor) {
            min_frame = frame_num;
            min_safety_factor = safety_factor;
        }
    }
    return min_frame;
}

fn parse_robots(data: []const u8, alloc: std.mem.Allocator) ![]Robot {
    var start: usize = 0;
    var end: usize = 0;
    var robots = std.ArrayList(Robot).init(alloc);
    for (0..NUM_ROBOTS) |_| {
        var numbers: [4]i64 = undefined;

        for (0..4) |i| {
            start = if (end > 0) end + 1 else 0;
            while (!std.ascii.isDigit(data[start]) and data[start] != '-') {
                start += 1;
            }
            end = start + 1;
            while (end < data.len and std.ascii.isDigit(data[end])) {
                end += 1;
            }

            numbers[i] = try std.fmt.parseInt(i64, data[start..end], 10);
        }

        try robots.append(Robot{
            .px = numbers[0],
            .py = numbers[1],
            .vx = numbers[2],
            .vy = numbers[3],
        });
    }

    return try robots.toOwnedSlice();
}

pub fn solve(rdr: anytype, part: lib.Part) !usize {
    const alloc = std.heap.page_allocator;

    const data = try rdr.readAllAlloc(alloc, 1000000000);
    defer alloc.free(data);

    var robots = try parse_robots(data, alloc);
    defer alloc.free(robots);

    if (part == .one) {
        for (0..NUM_ROBOTS) |n| {
            robots[n].tickn(100);
        }
        return count_quads(robots);
    } else {
        const frame = find_tree(robots, 10_000);
        return frame;
    }

    return 0;
}

pub fn main() !void {
    try lib.run(usize, solve, "Day 14", input);
}
