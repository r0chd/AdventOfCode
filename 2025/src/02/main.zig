const std = @import("std");
const zbench = @import("zbench");
const mem = std.mem;
const fs = std.fs;
const heap = std.heap;
const fmt = std.fmt;
const math = std.math;

fn calculateFirst(id_range: []const u8, sum: *std.atomic.Value(usize)) void {
    const dash_pos = mem.indexOf(u8, id_range, "-").?;
    const start = fmt.parseInt(usize, id_range[0..dash_pos], 10) catch @panic("parseInt error");
    const end = fmt.parseInt(usize, id_range[(dash_pos + 1)..], 10) catch @panic("parseInt error");

    var buf: [20]u8 = undefined;
    for (start..end + 1) |i| {
        const id = fmt.bufPrint(&buf, "{}", .{i}) catch @panic("bufPrint error");
        const middle = (id.len / 2);
        if (mem.eql(u8, id[0..middle], id[middle..])) {
            _ = sum.fetchAdd(i, .monotonic);
        }
    }
}

pub fn first(comptime input: []const u8) !usize {
    var id_ranges = mem.splitScalar(u8, input, ',');

    var buffer: [527]std.Thread = undefined;
    var threads = std.ArrayList(std.Thread).initBuffer(&buffer);

    var sum = std.atomic.Value(usize).init(0);
    while (id_ranges.next()) |id_range| {
        if (id_range.len == 0) break;
        const thread = try std.Thread.spawn(.{}, calculateFirst, .{ id_range, &sum });
        threads.appendAssumeCapacity(thread);
    }

    for (threads.items) |thread| {
        thread.join();
    }

    return sum.load(.unordered);
}

fn calculateSecond(id_range: []const u8, sum: *std.atomic.Value(usize)) void {
    const dash_pos = mem.indexOf(u8, id_range, "-").?;
    const start = fmt.parseInt(usize, id_range[0..dash_pos], 10) catch @panic("parseInt failed");
    const end = fmt.parseInt(usize, id_range[(dash_pos + 1)..], 10) catch @panic("parseInt failed");

    var buf: [20]u8 = undefined;
    for (start..(end + 1)) |i| {
        const id = fmt.bufPrint(&buf, "{}", .{i}) catch @panic("bufPrint failed");
        for (0..(id.len / 2)) |index| {
            if (id.len % id[0 .. index + 1].len != 0) continue;
            const count = mem.count(u8, id, id[0 .. index + 1]);
            if (count >= math.divCeil(usize, id.len, id[0 .. index + 1].len) catch @panic("divCeil failed")) {
                _ = sum.fetchAdd(i, .monotonic);
                break;
            }
        }
    }
}

pub fn second(comptime input: []const u8) !usize {
    var sum = std.atomic.Value(usize).init(0);

    var buffer: [527]std.Thread = undefined;
    var threads = std.ArrayList(std.Thread).initBuffer(&buffer);

    var id_ranges = mem.splitScalar(u8, input, ',');
    while (id_ranges.next()) |id_range| {
        if (id_range.len == 0) break;
        const thread = try std.Thread.spawn(.{}, calculateSecond, .{ id_range, &sum });
        threads.appendAssumeCapacity(thread);
    }

    for (threads.items) |thread| {
        thread.join();
    }

    return sum.load(.unordered);
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
