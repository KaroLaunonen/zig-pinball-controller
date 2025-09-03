const std = @import("std");
const microzig = @import("microzig");
const Pin = microzig.hal.pins.Pin;

// What is the GPIO pin used for
const PinFunction = enum {
    button,
    led,
    plunger_1,
    plunger_2,
};

// Which position the LED is installed at
pub const LedPosition = enum {
    left_flipper,
    right_flipper,
    left_magnasave,
    right_magnasave,
    plunger_button,
    start_button,
    exit_button,
    coin_button,
};

//
pub const PinEntry = struct {
    function: PinFunction,

    data: union(enum) {
        button: struct {
            keycode: u8,
        },

        led: struct {
            position: LedPosition,
        },
    },
};

pub const PinConfiguration = [30]?PinEntry;
