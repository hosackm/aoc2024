const std = @import("std");
const lib = @import("lib.zig");

pub const input = "data/input17.txt";

const OpCode = enum(u3) {
    adv = 0,
    bxl = 1,
    bst = 2,
    jnz = 3,
    bxc = 4,
    out = 5,
    bdv = 6,
    cdv = 7,
};

const Instruction = struct {
    opcode: OpCode,
    operand: u3,
};

const Emulator = struct {
    a: i128 = 0,
    b: i128 = 0,
    c: i128 = 0,
    instructions: []Instruction = undefined,
    instruction_pointer: usize = 0,
    output: std.ArrayList(u3) = undefined,
    alloc: std.mem.Allocator,

    fn init(alloc: std.mem.Allocator) @This() {
        return .{ .alloc = alloc, .output = std.ArrayList(u3).init(alloc) };
    }

    fn parse(self: *@This(), lines: [][]u8) !void {
        self.a = try num_from_register_line(lines[0]);
        self.b = try num_from_register_line(lines[1]);
        self.c = try num_from_register_line(lines[2]);
        self.instructions = try self.parse_instructions(lines[4]);
    }

    fn get_combo(self: @This(), operand: u3) i128 {
        return switch (operand) {
            0...3 => |n| @intCast(n),
            4 => self.a,
            5 => self.b,
            6 => self.c,
            7 => unreachable,
        };
    }

    fn run(self: *@This()) !void {
        while (self.instruction_pointer < self.instructions.len) {
            const inst = self.instructions[self.instruction_pointer];
            const combo = self.get_combo(inst.operand);

            switch (inst.opcode) {
                .adv => self.a = @divTrunc(self.a, std.math.pow(i128, 2, combo)),
                .bxl => self.b ^= @intCast(inst.operand),
                .bst => self.b = @mod(combo, 8),
                .jnz => if (self.a != 0) {
                    self.instruction_pointer = inst.operand / 2;
                },
                .bxc => self.b = self.b ^ self.c,
                .out => try self.output.append(@intCast(@mod(combo, 8))),
                .bdv => self.b = @divTrunc(self.a, std.math.pow(i128, 2, combo)),
                .cdv => self.c = @divTrunc(self.a, std.math.pow(i128, 2, combo)),
            }
            self.instruction_pointer += if (inst.opcode == .jnz and self.a != 0) 0 else 1;
        }
    }

    fn get_output(self: @This()) ![]u8 {
        var str_list = std.ArrayList(u8).init(self.alloc);
        for (self.output.items, 0..) |num, n| {
            const num_u8: u8 = @intCast(num);

            try str_list.append('0' + num_u8);
            if (n == self.output.items.len - 1) continue;
            try str_list.append(',');
        }

        return try str_list.toOwnedSlice();
    }

    fn num_from_register_line(s: []const u8) !i128 {
        var iter = std.mem.splitSequence(u8, s, ": ");
        _ = iter.next().?;
        const reg_str = std.mem.trim(
            u8,
            iter.next().?,
            &std.ascii.whitespace,
        );
        return try std.fmt.parseInt(i128, reg_str, 10);
    }

    fn parse_instructions(self: *@This(), line: []const u8) ![]Instruction {
        var iter = std.mem.splitSequence(u8, line, ": ");
        _ = iter.next().?;
        const instructions_str = std.mem.trim(
            u8,
            iter.next().?,
            &std.ascii.whitespace,
        );

        var comma_iter = std.mem.splitScalar(
            u8,
            instructions_str,
            ',',
        );
        var instructions_list = std.ArrayList(Instruction).init(self.alloc);
        while (comma_iter.next()) |op_code_str| {
            const operand_str = comma_iter.next().?;
            try instructions_list.append(Instruction{
                .opcode = @enumFromInt(try std.fmt.parseInt(u3, op_code_str, 10)),
                .operand = try std.fmt.parseInt(u3, operand_str, 10),
            });
        }
        return try instructions_list.toOwnedSlice();
    }

    fn deinit(self: @This()) void {
        self.output.deinit();
        self.alloc.free(self.instructions);
    }
};

pub fn solve(rdr: anytype, part: lib.Part) !usize {
    const alloc = std.heap.page_allocator;
    var lr = try lib.LineReader.init(rdr, alloc);
    defer lr.deinit();

    if (part == .one) {
        var em = Emulator.init(alloc);
        defer em.deinit();

        try em.parse(lr.lines);
        try em.run();
        const str = try em.get_output();
        defer alloc.free(str);
        std.debug.print("part 1: {s}\n", .{str});
    } else {
        var em = Emulator.init(alloc);
        defer em.deinit();

        // found by brute forcing guessing
        // multiply by 8 will add a digit to the left.
        // Then by incrementing by one you can set the
        // leftmost digit correctly (while maintaing the rightmost)
        // then repeat by adding 8
        const lines: []const []const u8 = &.{
            "Register A: 164540892147389",
            "Register B: 0",
            "Register C: 0",
            "",
            "Program: 2,4,1,1,7,5,1,5,4,5,0,3,5,5,3,0",
        };

        try em.parse(@ptrCast(@constCast(lines)));
        try em.run();
        const str = try em.get_output();
        defer alloc.free(str);
        std.debug.print("part 2: {s}\n", .{str});
    }

    return 0;
}

pub fn main() !void {
    try lib.run(usize, solve, "Day 14", input);
}

test "parse input" {
    const s =
        \\Register A: 30344604
        \\Register B: 0
        \\Register C: 0
        \\
        \\Program: 2,4,1,1,7,5,1,5,4,5,0,3,5,5,3,0
    ;
    var stream = std.io.fixedBufferStream(s);
    const alloc = std.testing.allocator;
    var lr = try lib.LineReader.init(stream.reader(), alloc);
    defer lr.deinit();

    var em = Emulator.init(alloc);
    defer em.deinit();
    try em.parse(lr.lines);

    try std.testing.expect(em.instructions[0].opcode == .bst);
    try std.testing.expect(em.instructions[0].operand == 4);
    try std.testing.expect(em.instructions[7].opcode == .jnz);
    try std.testing.expect(em.instructions[7].operand == 0);
    try std.testing.expect(em.a == 30344604);
    try std.testing.expect(em.b == 0);
    try std.testing.expect(em.c == 0);
}

test "run example input" {
    const s =
        \\Register A: 729
        \\Register B: 0
        \\Register C: 0
        \\
        \\Program: 0,1,5,4,3,0
    ;
    var stream = std.io.fixedBufferStream(s);
    const alloc = std.testing.allocator;
    var lr = try lib.LineReader.init(stream.reader(), alloc);
    defer lr.deinit();

    var em = Emulator.init(alloc);
    defer em.deinit();
    try em.parse(lr.lines);
    try em.run();

    try std.testing.expect(em.output.items.len == 10);

    const output = try em.get_output();
    defer alloc.free(output);
    try std.testing.expect(std.mem.eql(u8, output, "4,6,3,5,6,3,5,2,1,0"));
}
