A solo example (original from nanovg-zig/examples/example_blur.zig) using [nanovg-zig(https://github.com/fabioarnold/nanovg-zig).

Demo build.zig (zig 0.14.0-dev.2218) on how to use dependency and its resouces:

1. nanovg module
```zig
const nanovg = b.dependency("nanovg.zig", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("nanovg", nanovg.module("nanovg"));
```

2. examples/perf.zig
```zig
const perf = b.addModule("perf.zig", .{
    .root_source_file = nanovg.path("examples/perf.zig"),
});
perf.addImport("nanovg", nanovg.module("nanovg"));
exe.root_module.addImport("perf.zig", perf);
```

3. font or other assets of examples/
```zig
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
```

4. lib/gl2
```zig
exe.addIncludePath(nanovg.path("lib/gl2/include"));
exe.addCSourceFile(.{ .file = nanovg.path("lib/gl2/src/glad.c"), .flags = &.{} });
```
