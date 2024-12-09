const std = @import("std");
const Part = @import("lib.zig").Part;
pub const input = "data/input3.txt";

const State = enum {
    start,
    digit1,
    comma,
    digit2,
    end,
};

const DoParser = struct {
    buffer: []u8,
    read_index: usize = 0,
    on: bool = true,

    const Self = @This();

    pub fn parse(self: *Self) ![]u8 {
        var list = std.ArrayList(u8).init(std.heap.page_allocator);
        defer list.deinit();

        while (self.read_index < self.buffer.len) {
            switch (self.on) {
                true => {
                    const p = self.peek(7) orelse break;
                    if (std.mem.eql(u8, p, "don't()")) {
                        self.read_index += 7;
                        self.on = false;
                    } else {
                        try list.append(self.buffer[self.read_index]);
                        self.read_index += 1;
                    }
                },
                false => {
                    const p = self.peek(4) orelse break;
                    if (std.mem.eql(u8, p, "do()")) {
                        self.read_index += 4;
                        self.on = true;
                    } else {
                        self.read_index += 1;
                    }
                },
            }
        }

        return try list.toOwnedSlice();
    }

    fn peek(self: *Self, n: usize) ?[]u8 {
        if (self.read_index + n > self.buffer.len) {
            return null;
        }

        return self.buffer[self.read_index .. self.read_index + n];
    }
};

const Parser = struct {
    buffer: []u8,
    read_index: usize = 0,
    state: State = .start,

    const Self = @This();

    pub fn parse(self: *Self) !?i32 {
        var digit1: i32 = 0;
        var digit2: i32 = 0;

        while (true) {
            switch (self.state) {
                .start => {
                    const p = self.peek(4) orelse return error.EOF;
                    if (std.mem.eql(u8, p, "mul(")) {
                        self.state = .digit1;
                        self.read_index += 4;
                    } else {
                        self.read_index += 1;
                    }
                },
                .digit1 => {
                    var n_digits: usize = 0;
                    while (std.ascii.isDigit(self.peek_ahead(n_digits + 1))) {
                        n_digits += 1;
                    }

                    if (n_digits == 0 or n_digits > 3) {
                        self.state = .start;
                        self.read_index += n_digits;
                        continue;
                    } else {
                        digit1 = try std.fmt.parseInt(i32, self.read(n_digits).?, 10);
                        self.state = .comma;
                    }
                },
                .comma => {
                    if (std.mem.eql(u8, self.peek(1).?, ",")) {
                        self.read_index += 1;
                        self.state = .digit2;
                    } else {
                        self.state = .start;
                    }
                },
                .digit2 => {
                    var n_digits: usize = 0;
                    while (std.ascii.isDigit(self.peek_ahead(n_digits + 1))) {
                        n_digits += 1;
                    }

                    // not a valid up-to-3 digit number
                    if (n_digits == 0 or n_digits > 3) {
                        self.state = .start;
                        self.read_index += n_digits;
                        continue;
                    } else {
                        digit2 = try std.fmt.parseInt(i32, self.read(n_digits).?, 10);
                        self.state = .end;
                    }
                },
                .end => {
                    if (std.mem.eql(u8, self.peek(1).?, ")")) {
                        self.read_index += 1;
                        self.state = .start;
                        return digit1 * digit2;
                    }
                    self.state = .start;
                },
            }
        }

        return error.EOF;
    }

    fn read(self: *Self, n: usize) ?[]u8 {
        if (self.read_index + n > self.buffer.len) {
            return null;
        }

        const start = self.read_index;
        self.read_index += n;
        return self.buffer[start .. start + n];
    }

    fn peek(self: *Self, n: usize) ?[]u8 {
        if (self.read_index + n > self.buffer.len) {
            return null;
        }

        return self.buffer[self.read_index .. self.read_index + n];
    }

    fn peek_ahead(self: *Self, n: usize) u8 {
        return self.buffer[self.read_index + n - 1];
    }
};

pub fn solve(
    rdr: anytype,
    part: Part,
) !i32 {
    const num_bytes = 18672; // by looking at AOC input
    var buffer: [num_bytes]u8 = undefined;
    _ = try rdr.readAll(&buffer);

    var parser: Parser = undefined;
    if (part == .two) {
        var dop = DoParser{ .buffer = &buffer };
        parser = Parser{ .buffer = try dop.parse() };
    } else {
        parser = Parser{ .buffer = &buffer };
    }

    var total: i32 = 0;
    while (true) {
        const num = parser.parse() catch break orelse 0;
        total += num;
    }

    return total;
}

test "part 1" {
    const test_input = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";
    var stream = std.io.fixedBufferStream(test_input);
    try std.testing.expect(try solve(stream.reader(), .one) == 161);
}

test "part 2" {
    const test_input = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";
    var stream = std.io.fixedBufferStream(test_input);
    try std.testing.expect(try solve(stream.reader(), .two) == 48);
}
