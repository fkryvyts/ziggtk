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

    app.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = "lib/" } });
    app.addLibraryPath(.{ .cwd_relative = "lib" });
    app.linkLibC();
    app.linkSystemLibrary("gtk4");
    app.linkSystemLibrary("libadwaita-1");
    app.linkSystemLibrary("goimagex-1");

    b.installArtifact(app);

    const run_cmd_b = b.addRunArtifact(app);
    run_cmd_b.step.dependOn(b.getInstallStep());

    const build_res_cmd = b.addSystemCommand(&.{"glib-compile-resources"});
    build_res_cmd.addArgs(&.{ "data/gresources.xml", "--sourcedir", "data", "--target", "src/widgets/resources/gresources.gresource" });

    const run_step_b = b.step("run", "Run the app");
    run_step_b.dependOn(&run_cmd_b.step);
    run_step_b.dependOn(&build_res_cmd.step);
}
