const std = @import("std");

const keycode_map = @import("keymap.zig").keycode_map;

const GeneratorError = error{
    wrong_number_of_args,
    unable_to_open_target,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 3) {
        std.debug.print("Need source and dest parameters.", .{});
        return GeneratorError.wrong_number_of_args;
    }

    const cwd = std.fs.cwd();
    var keymap_entry_file = cwd.createFile(args[2], .{ .truncate = true }) catch {
        return GeneratorError.unable_to_open_target;
    };
    defer keymap_entry_file.close();

    var writer_buf: [256]u8 = undefined;
    var writer = keymap_entry_file.writer(writer_buf[0..]);
    defer writer.interface.flush() catch @panic("Flush failed");

    _ = try writer.interface.write(
    \\// This file is auto-generated on demand.
    \\
    \\pub const KeymapEntry = enum(u8) {
    \\
    );

    var buf: [256]u8 = undefined;
    for (keycode_map.keys()) |key| {
        buf = @splat(0);
        _ = try std.fmt.bufPrint(&buf, "    {s},\n", .{key});
        _ = try writer.interface.write(buf[0 .. std.mem.indexOf(u8, &buf, "\x00") orelse 0]);
    }
    _ = try writer.interface.write(
        \\};
        \\
    );
}
