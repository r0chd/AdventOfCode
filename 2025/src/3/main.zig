const std = @import("std");
const zbench = @import("zbench");
const mem = std.mem;
const fs = std.fs;
const heap = std.heap;

pub fn first(input: []const u8) !u32 {
    _ = input;
    return 0;
}

pub fn second(input: []const u8) !u32 {
    _ = input;
    return 0;
}

fn benchFirst(alloc: mem.Allocator) void {
    const input = std.mem.trimEnd(u8, @embedFile("./input.txt"), "\n");
    _ = first(input) catch {};
    _ = alloc;
}

fn benchSecond(alloc: mem.Allocator) void {
    const input = std.mem.trimEnd(u8, @embedFile("./input.txt"), "\n");
    _ = second(input) catch {};
    _ = alloc;
}

pub fn main() !void {
    const alloc = heap.page_allocator;

    const input = mem.trimEnd(u8, @embedFile("./input.txt"), "\n");
    std.debug.print("First solution: {any}\n", .{first(input)});
    std.debug.print("Second solution: {any}\n", .{second(input)});

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
