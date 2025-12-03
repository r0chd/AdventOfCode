const std = @import("std");
const zbench = @import("zbench");
const mem = std.mem;
const fs = std.fs;
const heap = std.heap;
const fmt = std.fmt;

pub fn first(comptime input: []const u8) !u32 {
    var sum: u32 = 0;

    var lines = mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var bytes = [2]u8{ 0, 0 };
        for (line, 0..) |battery, i| {
            if (battery > bytes[0] and line.len != i + 1) {
                bytes[0] = battery;
                bytes[1] = 0;
            } else if (battery > bytes[1]) {
                bytes[1] = battery;
            }
        }

        sum += try std.fmt.parseInt(u32, bytes[0..2], 10);
    }

    return sum;
}

pub fn second(comptime input: []const u8) !u32 {
    _ = input;
    return 0;
}

fn benchFirst(alloc: mem.Allocator) void {
    const input = comptime std.mem.trimEnd(u8, @embedFile("./input.txt"), "\n");
    _ = first(input) catch {};
    _ = alloc;
}

fn benchSecond(alloc: mem.Allocator) void {
    const input = comptime std.mem.trimEnd(u8, @embedFile("./input.txt"), "\n");
    _ = second(input) catch {};
    _ = alloc;
}

pub fn main() !void {
    const alloc = heap.page_allocator;

    const input = comptime mem.trimEnd(u8, @embedFile("./input.txt"), "\n");
    std.debug.print("First solution: {}\n", .{try first(input)});
    std.debug.print("Second solution: {}\n", .{try second(input)});

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
