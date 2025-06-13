const microzig = @import("microzig");
const gpio = microzig.hal.gpio;

const PinFunction = enum {
    button,
    led,
    plunger_!,
    plunger_2,
};

const PinConfig = struct {
    function: PinFunction,

    union {
        button = struct {
            keycode: u7,
        },
        led = struct {
            button_pin: gpio.Pin,
        },
    },
};

const Configuration = struct {
    pin_config: struct {
        GPIO2: ?PinConfig = null,
        GPIO3: ?PinConfig = null,
        GPIO4: ?PinConfig = null,
        GPIO5: ?PinConfig = null,
        GPIO6: ?PinConfig = null,
        GPIO7: ?PinConfig = null,
        GPIO8: ?PinConfig = null,
        GPIO9: ?PinConfig = null,
        GPIO10: ?PinConfig = null,
        GPIO11: ?PinConfig = null,
        GPIO12: ?PinConfig = null,
        GPIO13: ?PinConfig = null,
        GPIO14: ?PinConfig = null,
        GPIO15: ?PinConfig = null,
        GPIO16: ?PinConfig = null,
        GPIO17: ?PinConfig = null,
        GPIO18: ?PinConfig = null,
        GPIO19: ?PinConfig = null,
        GPIO20: ?PinConfig = null,
        GPIO21: ?PinConfig = null,
        GPIO22: ?PinConfig = null,
        GPIO26: ?PinConfig = null,
        GPIO27: ?PinConfig = null,
        GPIO28: ?PinConfig = null,
    },
};