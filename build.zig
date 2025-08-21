const std = @import("std");
const microzig = @import("microzig");

const MicroBuild = microzig.MicroBuild(.{
    .rp2xxx = true,
});

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const mz_dep = b.dependency("microzig", .{});
    const mb = MicroBuild.init(b, mz_dep) orelse return;

    const firmware = mb.add_firmware(.{
        .name = "pinball_controller",
        .target = mb.ports.rp2xxx.boards.raspberrypi.pico,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
        .linker_script = b.path("rp2040.ld"),
    });

    const want_uf2 = b.option(bool, "uf2", "Build uf2 image") orelse false;
    if (want_uf2) {
        mb.install_firmware(firmware, .{ });
    } else {
        mb.install_firmware(firmware, .{ .format = .elf });
    }
}
