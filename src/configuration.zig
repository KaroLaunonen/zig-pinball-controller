const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;

const pin_configuration = @import("pin_configuration.zig");
const KeymapEntry = @import("keymap_entry").KeymapEntry;

const Button = struct {
    switch_pin: hal.pins.Pin,
    keycode: KeymapEntry,
};

const ConfigurationError = error {
    redefined_pin,
    unknown_pin
};

pub fn init(comptime buttons: []const Button) ConfigurationError!void {
    // Check configuration validity
    const pin_conf: pin_configuration.PinConfiguration = .{};

    inline for (buttons) |button| {
        const pin_name = @tagName(button.switch_pin);

        if (@hasField(@TypeOf(pin_conf), pin_name)) {
            std.debug.print("Pin {s} already defined.", .{ pin_name });
            return ConfigurationError.redefined_pin;
        } else ConfigurationError.unknown_pin;

        var conf_pin = @field(pin_conf, pin_name);
        conf_pin = .{
            .function = .button,
            .data = .{
                .button = button.keycode,
            }
        };
    }
}
