const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;

const pin_config = @import("pin_config.zig").pin_config;
const uart_log = @import("uart_log.zig");
const usb_if = @import("usb_if.zig");

const gpio = hal.gpio;
const time = hal.time;

const i2c0 = hal.i2c.instance.I2C0;

const ssd1306 = microzig.drivers.display.SSD1306_I2C;

const usb_dev = hal.usb.Usb(.{});
const usb = microzig.core.usb;

const pins = pin_config.pins();

// Set std.log to go to uart
pub const microzig_options = microzig.Options {
    .log_level = .debug,
    .logFn = hal.uart.logFn,
};

pub fn main() !void {
    pin_config.apply();

    _ = uart_log.init();

    std.log.debug("Starting pinball controller!\r\n", .{});

    var blinky_prev = time.get_time_since_boot();

    const flipper_button_input = microzig.drivers.input.Debounced_Button(.{
        .active_state = .low,
    });

    var button_gpio = hal.drivers.GPIO_Device.init(pins.button_1);
    var button = try flipper_button_input.init(button_gpio.digital_io());

    // Set up I2C
    try i2c0.apply(.{
        .clock_config = hal.clock_config,
        .baud_rate = 400_000
    });

    // var display_device = rp2xxx.drivers.I2C_Device.init(i2c0, rp2xxx.i2c.Address.new(0x3c));
    // const display = try microzig.drivers.display.SSD1306_I2C.init(display_device.datagram_device());
    // try display.clear_screen(true);
    // var framebuffer = microzig.drivers.display.ssd1306.Framebuffer.init(.black);

    std.log.debug("init lsm6ds33\r\n", .{});
    var accel_gyro_device = hal.drivers.I2C_Device.init(microzig.hal.i2c.instance.I2C0, microzig.hal.i2c.Address.new(0x6a));
    var accel_gyro = try microzig.drivers.sensor.LSM6DS33.init(accel_gyro_device.datagram_device(), true);

    try accel_gyro.reset();
    try accel_gyro.set_output_data_rate(.hz_104);
    try accel_gyro.set_accelerator_full_scale(.fs_2g);
    try accel_gyro.set_anti_aliasing_filter_bandwidth(.fb_400hz);
    std.log.debug("done init lsm6ds33\r\n", .{});

    usb_if.init(usb_dev);

    var joy_old = time.get_time_since_boot();
    var report_buf: [7]u8 = .{ 0, 0, 0, 0, 0, 0, 1 << 7 };

    while (true) {
        // LED blinking to indicate running loop
        if (time.get_time_since_boot().diff(blinky_prev).to_us() > 500_000) {
            pins.led.toggle();
            blinky_prev = time.get_time_since_boot();
        }

        // Poll test button
        switch (button.poll() catch continue) {
            .pressed => {
                // std.log.debug("Pressed", .{});
                pins.led_1.put(1);
            },
            .released => {
                // std.log.debug("Released", .{});
                pins.led_1.put(0);
            },
            .idle => {}
        }

        // Log all other USB interrupts except BuffStatus
        const ints = usb_dev.callbacks.get_interrupts();
        const int_fields = comptime @typeInfo(microzig.core.usb.InterruptStatus).@"struct".fields;

        inline for (int_fields) |field| {
            if (@field(ints, field.name) == true and !std.mem.eql(u8, field.name, "BuffStatus")) {
                std.log.debug("#### {s}", .{ field.name });
            }
        }

        // Process pending USB housekeeping
        usb_dev.task(false) catch unreachable;

        const time_now = time.get_time_since_boot();
        if (time_now.diff(joy_old).to_us() > 10_000) {
            const acc = try accel_gyro.read_raw_acceleration();
            std.mem.writeInt(i16, report_buf[0..2], acc[0], .big);
            std.mem.writeInt(i16, report_buf[2..4], acc[1], .big);
            std.mem.writeInt(i16, report_buf[4..6], acc[2], .big);

            usb_if.send_joystick_report(usb_dev, hal.usb.Endpoint.to_address(1, .In), report_buf[0..]);
            joy_old = time_now;
        }

        time.sleep_ms(3);
    }
}
