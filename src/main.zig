const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;

const pin_config = @import("pin_config.zig").pin_config;
const uart_log = @import("uart_log.zig");
const usb_if = @import("usb_if.zig");
const accel_math = @import("accel_math.zig");
const acceleration = accel_math.acceleration;

const gpio = hal.gpio;
const time = hal.time;

const i2c0 = hal.i2c.instance.I2C0;

const ssd1306 = microzig.drivers.display.SSD1306_I2C;

const usb_dev = hal.usb.Usb(.{});
const usb = microzig.core.usb;

const pins = pin_config.pins();

// Set std.log to go to uart
pub const microzig_options = microzig.Options {
    .log_level = .info,
    .logFn = hal.uart.logFn,
};

pub fn main() !void {
    pin_config.apply();

    // Enable PWM on LED pin
    pins.led.slice().set_wrap(100);
    pins.led.slice().enable();

    _ = uart_log.init();

    std.log.info("Starting pinball controller!\r\n", .{});

    var blinky_prev = time.get_time_since_boot();

    const flipper_button_input = microzig.drivers.input.Debounced_Button(.{
        .active_state = .low,
        .filter_depth = 4
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

    std.log.info("init lsm6ds33\r\n", .{});
    var accel_gyro_device = hal.drivers.I2C_Device.init(microzig.hal.i2c.instance.I2C0, microzig.hal.i2c.Address.new(0x6a));
    var accel_gyro = try microzig.drivers.sensor.LSM6DS33.init(accel_gyro_device.datagram_device(), true);

    try accel_gyro.reset();
    try accel_gyro.set_high_performance_mode(.enabled);
    try accel_gyro.set_output_data_rate(.hz_104);
    try accel_gyro.set_accelerator_full_scale(.fs_4g);
    try accel_gyro.set_anti_aliasing_filter_bandwidth(.fb_50hz);
    std.log.info("done init lsm6ds33\r\n", .{});

    usb_if.init(usb_dev);

    var joy_old = time.get_time_since_boot();
    var key_old = time.get_time_since_boot();

    var stable_baseline: acceleration = undefined;

    const STABILIZATION_RUN = 100;

    var accel_ringbuf: [STABILIZATION_RUN]acceleration = @as([1]acceleration, .{ .{ 0, 0, 0}}) ** STABILIZATION_RUN;
    var ringbuf_index: u32 = 0;
    var time_start = time.get_time_since_boot();
    var prev_accel_avg: acceleration = @splat(0);

    var led_on = false;

    // Get stable acceleration baseline
    {
        var stable = false;
        std.log.info("start stabilization", .{});

        while (!stable) {
            // LED blinking to indicate running loop
            if (time.get_time_since_boot().diff(blinky_prev).to_us() > 500_000) {
                pins.led.set_level(if (led_on) 100 else 0);
                led_on = !led_on;

                blinky_prev = time.get_time_since_boot();
            }

            time_start = time.get_time_since_boot();
            accel_ringbuf[ringbuf_index % STABILIZATION_RUN] = try accel_gyro.read_raw_acceleration();
            if (ringbuf_index > 0 and ringbuf_index % STABILIZATION_RUN == 0) {
                // Have enough data, calculate average
                // Calculate average
                const accel_avg = accel_math.calculate_accel_ringbuf_avg(accel_ringbuf[0..]);

                const distance = accel_math.accel_distance(prev_accel_avg, accel_avg);

                prev_accel_avg = accel_avg;
                std.log.debug("avg: {any} distance prev: {d:5.1}", .{ accel_avg, distance });

                if (distance < 100.0) {
                    stable = true;
                    stable_baseline = accel_avg;
                }
            }

            ringbuf_index += 1;

            const elapsed_us = time.get_time_since_boot().diff(time_start).to_us();

            if (elapsed_us < 5000) {
                time.sleep_ms(@as(u32, @intCast(@divTrunc(5000 - elapsed_us, 1000))));
            }
        }

        std.log.info("stabilization done", .{});

    }

    var prev_acc: acceleration = stable_baseline;
    ringbuf_index = 0;
    var stabilization_round: u8 = 10;
    var nudged = false;

    pins.led.set_level(20);

    while (true) {
        time_start = time.get_time_since_boot();

        const time_now = time.get_time_since_boot();

        // Poll test button
        if (time_now.diff(key_old).to_us() > 1_000) {
            switch (button.poll() catch continue) {
                .pressed => {
                    std.log.debug("Pressed", .{});
                    pins.led_1.put(1);
                    var keycodes: [6]u8 = @splat(0);
                    keycodes[0] = 4; // 'a'
                    usb_if.send_keyboard_report(usb_dev, &keycodes);
                    usb_dev.task(true) catch unreachable;
                },
                .released => {
                    std.log.debug("Released", .{});
                    pins.led_1.put(0);
                    const keycodes: [6]u8 = @splat(0);
                    usb_if.send_keyboard_report(usb_dev, &keycodes);
                    usb_dev.task(true) catch unreachable;
                },
                .idle => {}
            }

            key_old = time_now;
        }

        // Process pending USB housekeeping
        usb_dev.task(false) catch unreachable;

        const acc = try accel_gyro.read_raw_acceleration();

        // If at least 10ms has passed since last report
        if (time_now.diff(joy_old).to_us() > 10_000) {
            const dist = accel_math.accel_distance(acc, stable_baseline);

            // If we were nudged and not returned to stable position, keep on reporting
            if ((!nudged and dist > 200.0) or nudged) {
                // Don't report repeating values
                if (prev_acc[0] != acc[0] or prev_acc[1] != acc[1] or prev_acc[2] != acc[2]) {

                    if (!nudged and dist > 200.0) {
                        nudged = true;
                        std.log.debug("nudge!", .{});
                        pins.led.set_level(100);
                    }

                    prev_acc = acc;
                    usb_if.send_joystick_report(usb_dev, acc);
                    joy_old = time_now;

                    usb_dev.task(false) catch unreachable;
                }

                if (nudged and dist < 50.0) {
                    nudged = false;
                    pins.led.set_level(10);
                }
            }
        }

        accel_ringbuf[ringbuf_index % STABILIZATION_RUN] = acc;
        if (ringbuf_index > 0 and ringbuf_index % STABILIZATION_RUN == 0) {
            // Enough samples to check for stable position
            const accel_avg = accel_math.calculate_accel_ringbuf_avg(accel_ringbuf[0..]);

            const distance = accel_math.accel_distance(prev_accel_avg, accel_avg);

            if (distance < 50.0) {
                stabilization_round -= 1;

                if (stabilization_round == 0) {
                    std.log.debug("stabilized", .{});
                    stable_baseline = accel_avg;
                    stabilization_round = 10;
                }
            } else {
                stabilization_round = 10;
            }

            prev_accel_avg = accel_avg;
        }

        ringbuf_index += 1;

        const elapsed_time = time.get_time_since_boot().diff(time_start).to_us();
        if (elapsed_time < 2_000) {
            time.sleep_us(2_000 - elapsed_time);
        }
    }
}
