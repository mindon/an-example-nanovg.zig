const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "deqi",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const nanovg = b.dependency("nanovg.zig", .{
        .target = target,
        .optimize = optimize,
    });
    // main module
    exe.root_module.addImport("nanovg", nanovg.module("nanovg"));

    // module in examples
    const perf = b.addModule("perf.zig", .{
        .root_source_file = nanovg.path("examples/perf.zig"),
    });
    perf.addImport("nanovg", nanovg.module("nanovg"));
    exe.root_module.addImport("perf.zig", perf);

    // other assets
    const assets_mapping = [_][]const u8{
        "examples/Roboto-Regular.ttf", "assets/fonts/Roboto-Regular.ttf",
    };
    const imax = assets_mapping.len - 1;
    var i: usize = 0;
    while (i < imax) : (i += 2) {
        exe.root_module.addAnonymousImport(assets_mapping[i + 1], .{
            .root_source_file = nanovg.path(assets_mapping[i]),
        });
    }

    if (target.result.isWasm()) {
        exe.rdynamic = true;
        exe.entry = .disabled;
    } else {
        exe.addIncludePath(nanovg.path("lib/gl2/include"));
        exe.addCSourceFile(.{ .file = nanovg.path("lib/gl2/src/glad.c"), .flags = &.{} });
        switch (target.result.os.tag) {
            .windows => {
                b.installBinFile("glfw3.dll", "glfw3.dll");
                exe.linkSystemLibrary("glfw3dll");
                exe.linkSystemLibrary("opengl32");
            },
            .macos => {
                exe.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
                exe.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
                exe.linkSystemLibrary("glfw");
                exe.linkFramework("OpenGL");
            },
            .linux => {
                exe.linkSystemLibrary("glfw3");
                exe.linkSystemLibrary("GL");
                exe.linkSystemLibrary("X11");
            },
            else => {
                std.log.warn("Unsupported target: {}", .{target});
                exe.linkSystemLibrary("glfw3");
                exe.linkSystemLibrary("GL");
            },
        }
    }
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
