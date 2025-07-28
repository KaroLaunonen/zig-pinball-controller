const microzig = @import("microzig");
const hal = microzig.hal;
const Pin = hal.gpio.Pin;

const Button = struct {
    button_pin: ?Pin,
    led_pin: ?Pin,
    keycode: ?u7,
};

const ButtonConfiguration = struct {
    pub fn init() void {}
};
