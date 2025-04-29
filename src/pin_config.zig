const microzig = @import("microzig");
const rp2xxx = microzig.hal;

// Compile-time pin configuration
pub const pin_config = rp2xxx.pins.GlobalConfiguration{
    .GPIO25 = .{
        .name = "led",
        .direction = .out,
    },
    .GPIO0 = .{
        .function = .UART0_TX
    },
    .GPIO1 = .{
        .function = .UART0_RX
    },

    .GPIO4 = .{
        .name = "sda",
        .function = .I2C0_SDA,
        .slew_rate = .slow
    },
    .GPIO5 = .{
        .name = "scl",
        .function = .I2C0_SCL,
        .slew_rate = .slow
    },

    .GPIO6 = .{
        .name = "button_1",
        .direction = .in,
        .pull = .up
    },

    .GPIO7 = .{
        .name = "led_1",
        .direction = .out,
    }
};
