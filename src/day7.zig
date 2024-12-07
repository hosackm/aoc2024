const std = @import("std");
const Part = @import("main.zig").Part;

pub const input = "data/input7.txt";

const Solver = struct {
    target: u64,
    inputs: []u64,

    const Self = @This();

    pub fn solve(self: *const Self, part: Part) u64 {
        return if (recurse(self.target, self.inputs[1..], self.inputs[0], part)) self.target else 0;
    }

    fn recurse(tgt: u64, ins: []u64, total: u64, part: Part) bool {
        if (total > tgt) return false;
        if (ins.len == 0) return total == tgt;

        return recurse(
            tgt,
            ins[1..],
            total + ins[0],
            part,
        ) or recurse(
            tgt,
            ins[1..],
            total * ins[0],
            part,
        ) or if (part == .two) recurse(
            tgt,
            ins[1..],
            concat(total, ins[0]) catch unreachable,
            part,
        ) else false;
    }
};

pub fn build_solvers(rdr: anytype, alloc: std.mem.Allocator) ![]Solver {
    var solvers = std.ArrayList(Solver).init(alloc);
    defer {
        for (solvers.items) |solver| {
            alloc.free(solver.inputs);
        }
    }

    while (try rdr.readUntilDelimiterOrEofAlloc(alloc, '\n', 1000)) |line| {
        defer alloc.free(line);

        var splitter = std.mem.splitSequence(u8, line, ": ");
        const target = try std.fmt.parseInt(u64, splitter.first(), 10);

        var inputs = std.ArrayList(u64).init(alloc);
        defer inputs.deinit();

        var numbers_iter = std.mem.splitScalar(u8, splitter.next().?, ' ');
        while (numbers_iter.next()) |num_str| {
            try inputs.append(try std.fmt.parseInt(u64, num_str, 10));
        }

        try solvers.append(Solver{ .inputs = try inputs.toOwnedSlice(), .target = target });
    }

    return solvers.toOwnedSlice();
}

pub fn free_solvers(solvers: []Solver, alloc: std.mem.Allocator) void {
    for (solvers) |slv| {
        alloc.free(slv.inputs);
    }
    alloc.free(solvers);
}

pub fn solve(rdr: anytype, part: Part) !u128 {
    const alloc = std.heap.page_allocator;
    const solvers = try build_solvers(rdr, alloc);
    defer free_solvers(solvers, alloc);

    var total: u128 = 0;
    for (solvers) |solver| {
        const output = solver.solve(part);
        if (output > 0) {
            total += output;
        }
    }

    return total;
}

fn concat(a: u64, b: u64) !u64 {
    return try std.fmt.parseInt(
        u64,
        try std.fmt.allocPrint(
            std.heap.page_allocator,
            "{d}{d}",
            .{ a, b },
        ),
        10,
    );
}

test "advent 7 example part 1" {
    const test_input =
        \\190: 10 19
        \\3267: 81 40 27
        \\83: 17 5
        \\156: 15 6
        \\7290: 6 8 6 15
        \\161011: 16 10 13
        \\192: 17 8 14
        \\21037: 9 7 18 13
        \\292: 11 6 16 20
    ;
    var stream = std.io.fixedBufferStream(test_input);
    const solvers = try build_solvers(stream.reader(), std.testing.allocator);
    defer free_solvers(solvers, std.testing.allocator);
}

test "concat numbers" {
    try std.testing.expect(try concat(12, 34) == 1234);
    try std.testing.expect(try concat(1, 23) == 123);
    try std.testing.expect(try concat(0, 23) == 23);
    try std.testing.expect(try concat(1, 0) == 10);
}
