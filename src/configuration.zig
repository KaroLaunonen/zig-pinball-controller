const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;

const pin_configuration = @import("pin_configuration.zig");
const keymap = @import("keymap.zig");
const KeymapEntry = @import("keymap_entry").KeymapEntry;
const LedPosition = pin_configuration.LedPosition;

const GpioPinNumber = u5;

pub const HwConfig = struct {
    buttons: []const Button,
    leds: []const Led,
};

const Button = struct {
    switch_pin: GpioPinNumber,
    key: KeymapEntry,
};

const Led = struct {
    pin: GpioPinNumber,
    position: LedPosition,
};

const ConfigurationError = error{
    RedefinedPin,
    UnknownPin,
    OutOfMemory,
    UnknownError,
};

pub const HardwareConfiguration = struct {
    // Check configuration validity
    pin_conf: pin_configuration.PinConfiguration,
    button_pins: u30 = 0,

    pub fn init(config_data: HwConfig) ConfigurationError!HardwareConfiguration {
        std.log.info("Configuration has {d} {s}, {d} {s}", .{
            config_data.buttons.len,
            if (config_data.buttons.len == 1) "button" else "buttons",
            config_data.leds.len,
            if (config_data.leds.len == 1) "led" else "leds",
        });

        var pin_conf: pin_configuration.PinConfiguration = @splat(null);
        var button_pins: u30 = 0;

        // Handle button definitions
        for (config_data.buttons) |button| {
            if (pin_conf[button.switch_pin] != null) {
                std.log.err("Button pin GPIO{d} already defined", .{button.switch_pin});
                return ConfigurationError.RedefinedPin;
            }

            pin_conf[button.switch_pin] = .{
                .function = .button,
                .data = .{
                    .button = .{
                        .keycode = keymap.keycode_map.get(@tagName(button.key)).?,
                    },
                },
            };

            button_pins = button_pins | (@as(u30, 1) << button.switch_pin);
        }

        // Handle led definitions
        for (config_data.leds) |led| {
            if (pin_conf[led.pin] != null) {
                std.log.err("Led pin GPIO{d} already defined", .{led.pin});
                return ConfigurationError.RedefinedPin;
            }

            pin_conf[led.pin] = .{
                .function = .led,
                .data = .{
                    .led = .{
                        .position = led.position,
                    },
                },
            };
        }

        std.log.info("Configuration valid. Pins taken:", .{});
        for (pin_conf, 0..) |maybe_entry, pin| {
            if (maybe_entry) |entry| {
                std.log.info("  * GPIO{d}: {s}", .{ pin, switch (entry.function) {
                    .button => "button",
                    .led => "led",
                    .plunger_1 => "plunger_1",
                    .plunger_2 => "plunger_2",
                } });
            }
        }

        return .{
            .pin_conf = pin_conf,
            .button_pins = button_pins,
        };
    }

    pub fn num_buttons(self: *const @This()) u6 {
        return @popCount(self.button_pins);
    }
};
