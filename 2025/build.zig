const std = @import("std");
const heap = std.heap;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const opts = .{ .target = target, .optimize = optimize };
    const zbench_module = b.dependency("zbench", opts).module("zbench");

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    for (1..13) |day| {
        const name = std.fmt.allocPrint(alloc, "{}", .{day}) catch @panic("OOM");
        const path = std.fmt.allocPrint(alloc, "src/{}/main.zig", .{day}) catch @panic("OOM");
        const exe = b.addExecutable(.{
            .name = name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(path),
                .target = target,
                .optimize = optimize,
            }),
        });
        b.installArtifact(exe);

        exe.root_module.addImport("zbench", zbench_module);

        const run_step = b.step(name, "Run the app");

        const run_cmd = b.addRunArtifact(exe);
        run_step.dependOn(&run_cmd.step);

        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
    }
}
