const std = @import("std");
const zbench = @import("zbench");
const mem = std.mem;
const fs = std.fs;
const fmt = std.fmt;
const heap = std.heap;

const Direction = enum(u8) {
    left = 76,
    right = 82,
};

pub fn first(comptime input: []const u8) !i32 {
    var lines = mem.splitScalar(u8, input, '\n');

    var pos: i32 = 50;
    var sum: i32 = 0;
    while (lines.next()) |line| {
        if (line.len == 0) break;

        const direction: Direction = @enumFromInt(line[0]);
        const number = try fmt.parseInt(i32, line[1..], 10);

        pos = switch (direction) {
            .left => @mod(pos + number, 100),
            .right => @mod(pos - number, 100),
        };
        if (pos == 0) sum += 1;
    }

    return sum;
}

pub fn second(comptime input: []const u8) !i32 {
    var lines = mem.splitScalar(u8, input, '\n');

    var pos: i32 = 50;
    var sum: i32 = 0;
    while (lines.next()) |line| {
        if (line.len == 0) break;

        const direction: Direction = @enumFromInt(line[0]);
        const number = try fmt.parseInt(i32, line[1..], 10);

        sum += @divTrunc(number, 100);
        switch (direction) {
            .left => {
                const next = pos - @mod(number, 100);
                if (pos != 0 and (next <= 0 or pos - @mod(number, 100) >= 100)) sum += 1;
                pos = @mod(next, 100);
            },
            .right => {
                const next = pos + @mod(number, 100);
                if (pos != 0 and (next <= 0 or next >= 100)) sum += 1;
                pos = @mod(next, 100);
            },
        }
    }

    return sum;
}

fn benchFirst(alloc: mem.Allocator) void {
    const input = comptime mem.trimEnd(u8, @embedFile("./input.txt"), "\n");
    _ = first(input) catch {};
    _ = alloc;
}

fn benchSecond(alloc: mem.Allocator) void {
    const input = comptime mem.trimEnd(u8, @embedFile("./input.txt"), "\n");
    _ = second(input) catch {};
    _ = alloc;
}

pub fn main() !void {
    const alloc = heap.page_allocator;

    const input = comptime mem.trimEnd(u8, @embedFile("./input.txt"), "\n");
    std.debug.print("First solution: {any}\n", .{try first(input)});
    std.debug.print("Second solution: {any}\n", .{try second(input)});

    var bench = zbench.Benchmark.init(alloc, .{});
    defer bench.deinit();

    try bench.add("First", benchFirst, .{});
    try bench.add("Second", benchSecond, .{});

    var buf: [1024]u8 = undefined;
    var stdout = fs.File.stdout().writer(&buf);
    const writer = &stdout.interface;
    try bench.run(writer);
    try writer.flush();
}
