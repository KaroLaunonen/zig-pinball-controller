const std = @import("std");
const microzig = @import("microzig");

const MicroBuild = microzig.MicroBuild(.{
    .rp2xxx = true,
});

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const keymap_generator = b.addExecutable(.{
        .name = "keymap_generator",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/keymap_generator.zig"),
            .target = b.graph.host,
        }),
    });

    const run_keymap_generator = b.addRunArtifact(keymap_generator);
    run_keymap_generator.addArgs(&.{
        "src/keymap.zig",
    });
    run_keymap_generator.addFileInput(b.path("src/keymap.zig"));

    const keymap_entry_path = run_keymap_generator.addOutputFileArg("zig-out/keymap_entry.zig");

    const keymap_entry_module = b.createModule(.{
        .root_source_file = keymap_entry_path,
    });

    const generator_step = b.step("keymap_generator", "Generates keymap_entry.zig file");

    const mz_dep = b.dependency("microzig", .{});
    const mb = MicroBuild.init(b, mz_dep) orelse return;

    const firmware = mb.add_firmware(.{
        .name = "pinball_controller",
        .target = mb.ports.rp2xxx.boards.raspberrypi.pico,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
        .linker_script = .{
            .generate = .none,
            .file = b.path("rp2040.ld"),
        },
    });

    firmware.artifact.step.dependOn(generator_step);
    firmware.app_mod.addImport("keymap_entry", keymap_entry_module);

    const want_uf2 = b.option(bool, "uf2", "Build uf2 image") orelse false;
    if (want_uf2) {
        mb.install_firmware(firmware, .{});
    } else {
        mb.install_firmware(firmware, .{ .format = .elf });
    }
}
