const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;

const pin_configuration = @import("pin_configuration.zig");
const keymap = @import("keymap.zig");
const KeymapEntry = @import("keymap_entry").KeymapEntry;

const Button = struct {
    switch_pin: hal.pins.Pin,
    key: KeymapEntry,
};

const ConfigurationError = error {
    redefined_pin,
    unknown_pin
};

pub fn init(comptime buttons: []const Button) ConfigurationError!void {
    _ = std.fmt.comptimePrint("Number of buttons defined: {d}", .{ buttons.len });

    // Check configuration validity
    const pin_conf: pin_configuration.PinConfiguration = .{};

    const pin_conf_fields = @typeInfo(@TypeOf(pin_conf)).@"struct".fields;

    inline for (buttons) |button| {
        const pin_name = @tagName(button.switch_pin);

        inline for (pin_conf_fields) |field| {
            if (std.mem.eql(u8, field.name, pin_name)) {
                var conf_pin = @field(pin_conf, pin_name);
                if (conf_pin != null) {
                    return ConfigurationError.redefined_pin;
                } else {
                    conf_pin = .{
                        .function = .button,
                        .data = .{
                            .button = .{
                                .keycode = keymap.keycode_map.get(@tagName(button.key)).?,
                            },
                        },
                    };
                }
            }
        }
    }
}
