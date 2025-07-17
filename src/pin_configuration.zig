const microzig = @import("microzig");
const Pin = microzig.hal.pins.Pin;

const PinFunction = enum {
    button,
    led,
    plunger_1,
    plunger_2,
};

const PinEntry = struct {
    function: PinFunction,

    data: union {
        button: struct {
            keycode: u7,
        },

        led: struct {
            button_pin: Pin,
        },
    },
};

pub const PinConfiguration = struct {
    GPIO2: ?PinEntry = null,
    GPIO3: ?PinEntry = null,
    GPIO4: ?PinEntry = null,
    GPIO5: ?PinEntry = null,
    GPIO6: ?PinEntry = null,
    GPIO7: ?PinEntry = null,
    GPIO8: ?PinEntry = null,
    GPIO9: ?PinEntry = null,
    GPIO10: ?PinEntry = null,
    GPIO11: ?PinEntry = null,
    GPIO12: ?PinEntry = null,
    GPIO13: ?PinEntry = null,
    GPIO14: ?PinEntry = null,
    GPIO15: ?PinEntry = null,
    GPIO16: ?PinEntry = null,
    GPIO17: ?PinEntry = null,
    GPIO18: ?PinEntry = null,
    GPIO19: ?PinEntry = null,
    GPIO20: ?PinEntry = null,
    GPIO21: ?PinEntry = null,
    GPIO22: ?PinEntry = null,
    GPIO26: ?PinEntry = null,
    GPIO27: ?PinEntry = null,
    GPIO28: ?PinEntry = null,
};
