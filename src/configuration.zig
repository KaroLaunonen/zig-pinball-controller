const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;

const pin_configuration = @import("pin_configuration.zig");
const keymap = @import("keymap.zig");
const KeymapEntry = @import("keymap_entry").KeymapEntry;
const LedPosition = pin_configuration.LedPosition;

pub const HwConfig = struct {
    buttons: []const Button,
    leds: []const Led,
};

const Button = struct {
    switch_pin: hal.pins.Pin,
    key: KeymapEntry,
};

const Led = struct {
    pin: hal.pins.Pin,
    position: LedPosition,
};

const ConfigurationError = error {
    redefined_pin,
    unknown_pin
};

pub const HardwareConfiguration = struct {
    // Check configuration validity
    pin_conf: pin_configuration.PinConfiguration = .{},

    pub fn init(self: *const @This(), comptime config: HwConfig) ConfigurationError!void {
        const pin_conf_fields = @typeInfo(@TypeOf(self.pin_conf)).@"struct".fields;

        std.log.info("Configuration has {d} buttons, {d} leds", .{ config.buttons.len, config.leds.len });

        // Handle button definitions
        inline for (config.buttons) |button| {
            const pin_name = @tagName(button.switch_pin);

            var found = false;
            inline for (pin_conf_fields) |field| {
                if (std.mem.eql(u8, field.name, pin_name)) {
                    var conf_pin = @field(self.pin_conf, pin_name);
                    if (conf_pin != null) {
                        std.log.err("Redefined button pin: {s}", .{ pin_name });
                        return ConfigurationError.redefined_pin;
                    } else {
                        found = true;
                        std.log.info("Button pin found: {s}", .{ pin_name });
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

            if (!found) {
                std.log.err("Unknown pin: {s}", .{ pin_name });
                return ConfigurationError.unknown_pin;
            }
        }

        // Handle led definitions
        inline for (config.leds) |led| {
            const pin_name = @tagName(led.pin);

            var found = false;
            inline for (pin_conf_fields) |field| {
                if (std.mem.eql(u8, field.name, pin_name)) {
                    var conf_pin = @field(self.pin_conf, pin_name);
                    if (conf_pin != null) {
                        std.log.err("Redefined led pin: {s}", .{ pin_name });
                        return ConfigurationError.redefined_pin;
                    } else {
                        found = true;
                        std.log.info("Led pin found: {s}", .{ pin_name });
                        conf_pin = .{
                            .function = .led,
                            .data = .{
                                .led = .{
                                    .position = led.position,
                                },
                            },
                        };
                    }
                }

                if (!found) {
                    std.log.err("Unknown pin: {s}", .{ pin_name });
                    return ConfigurationError.unknown_pin;
                }
            }
        }

        std.log.info("Configuration valid. Pins taken:", .{});
        inline for (pin_conf_fields) |field| {
            if (@field(self.pin_conf, field.name)) |_| {
                std.log.info("  {s}", .{ field.name });
            }
        }
    }
};
