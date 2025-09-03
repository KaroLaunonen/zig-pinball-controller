const microzig = @import("microzig");
const rp2xxx = microzig.hal;

// Compile-time pin configuration
pub const pin_config = rp2xxx.pins.GlobalConfiguration{
    .GPIO25 = .{
        .name = "led",
        .direction = .out,
        .function = .PWM4_B,
    },
    .GPIO0 = .{
        .function = .UART0_TX,
    },
    .GPIO1 = .{
        .function = .UART0_RX,
    },
    .GPIO2 = .{
        .name = "sda",
        .function = .I2C1_SDA,
        .slew_rate = .slow,
    },
    .GPIO3 = .{
        .name = "scl",
        .function = .I2C1_SCL,
        .slew_rate = .slow,
    },
};

pub const pins = pin_config.pins();
