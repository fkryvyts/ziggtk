const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const app = b.addExecutable(.{
        .name = "app",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    app.linkSystemLibrary("c");
    app.linkSystemLibrary("gtk4");
    app.linkSystemLibrary("libadwaita-1");

    b.installArtifact(app);

    const run_cmd_b = b.addRunArtifact(app);
    run_cmd_b.step.dependOn(b.getInstallStep());

    const run_step_b = b.step("app", "Run the app");
    run_step_b.dependOn(&run_cmd_b.step);
}
