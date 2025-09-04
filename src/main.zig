const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;

const pin_config = @import("pin_config.zig");
const pins = pin_config.pins;

const uart_log = @import("uart_log.zig");
const usb_if = @import("usb_if.zig");
const accel_math = @import("accel_math.zig");
const acceleration = accel_math.acceleration;
const flash_storage = @import("flash_storage.zig");
const core1 = @import("core1.zig");
const multicore = hal.multicore;

const gpio = hal.gpio;
const time = hal.time;

const i2c1 = hal.i2c.instance.I2C1;

const usb_dev = hal.usb.Usb(.{
    .max_interfaces_count = 2,
    .max_endpoints_count = 3,
});
const usb = microzig.core.usb;

const drivers = microzig.drivers;
const LSM6DS33 = drivers.sensor.LSM6DS33;

const Acceleration = accel_math.Acceleration;
const AccelerationRingbuf = accel_math.AccelerationRingbuf;
const ACCELERATION_RINGBUF_LEN = accel_math.ACCELERATION_RINGBUF_LEN;

const configuration = @import("configuration.zig");
const LedPosition = @import("pin_configuration.zig").LedPosition;

const kbd_log = std.log.scoped(.keyboard);
const ms_log = std.log.scoped(.motion_sensor);

// Set std.log to go to uart
pub const microzig_options = microzig.Options{
    .log_level = .info,
    .logFn = hal.uart.log_threadsafe,
    .log_scope_levels = &.{
        .{
            .scope = .usb,
            .level = .info,
        },
        .{
            .scope = .pwm,
            .level = .info,
        },
        .{
            .scope = .core1_log,
            .level = .debug,
        },
        .{
            .scope = .keyboard,
            .level = .info,
        },
        .{
            .scope = .motion_sensor,
            .level = .debug,
        },
    },
};

pub fn main() !void {
    multicore.launch_core1(core1.core1_entry);

    pin_config.pin_config.apply();

    _ = uart_log.init();

    std.log.info("Starting pinball controller!\r\n", .{});

    var flash = flash_storage.FlashStorage{};
    const config = flash.getConfigData();

    std.log.info("Flash had config version: {d}", .{config.version});

    // Enable PWM on LED pin
    pins.led.slice().set_wrap(100);
    pins.led.slice().enable();

    const hw_config = try configuration.HardwareConfiguration.init(.{
        .buttons = &.{
            .{
                .switch_pin = 6,
                .key = .left_shift,
            },
            .{
                .switch_pin = 5,
                .key = .right_shift,
            },
        },
        .leds = &.{
            .{
                .pin = 16,
                .position = LedPosition.left_flipper,
            },
        },
    });

    // Setup all button pins for input
    const mask = gpio.mask(hw_config.button_pins);
    mask.set_direction(.in);
    mask.set_pull(.up);

    // Set up I2C
    i2c1.apply(.{
        .clock_config = hal.clock_config,
        .baud_rate = 400_000,
    });

    std.log.info("init lsm6ds33\r\n", .{});
    var i2c_device = hal.drivers.I2C_Device.init(i2c1, drivers.time.Duration.from_ms(200));
    const accel_gyro_maybe: ?LSM6DS33 = LSM6DS33.init(i2c_device.i2c_device(), @enumFromInt(0x6a), true) catch null;

    if (accel_gyro_maybe) |accel_gyro| {
        try accel_gyro.reset();
        try accel_gyro.set_high_performance_mode(.enabled);
        try accel_gyro.set_output_data_rate(.hz_104);
        try accel_gyro.set_accelerator_full_scale(.fs_4g);
        try accel_gyro.set_anti_aliasing_filter_bandwidth(.fb_50hz);
        std.log.info("done init lsm6ds33\r\n", .{});
    }

    var joy_old = time.get_time_since_boot();
    var key_old = time.get_time_since_boot();

    var stable_baseline: Acceleration = undefined;

    var accel_ringbuf: AccelerationRingbuf = @as([1]Acceleration, .{.{ 0, 0, 0 }}) ** ACCELERATION_RINGBUF_LEN;
    var ringbuf_index: u32 = 0;
    var prev_accel_avg: Acceleration = @splat(0);

    if (accel_gyro_maybe) |accel_gyro|
    // Get stable acceleration baseline
    {
        try accel_math.get_stable_baseline(&accel_gyro, pins.led, &accel_ringbuf, &stable_baseline);
        std.log.info("stabilization done", .{});
    } else {
        std.log.info("Skipping stabilization loop", .{});
    }

    var prev_acc: Acceleration = stable_baseline;
    ringbuf_index = 0;
    var stabilization_round: u8 = 10;
    var nudged = false;

    std.log.info("usb init", .{});

    try usb_if.init(usb_dev);
    std.log.info("usb init done", .{});

    std.log.info("start main loop", .{});

    // Inform core1 of the button pins
    core1.set_button_pins(hw_config.button_pins);

    var keycodes: [6]u8 = @splat(0);

    const pin_start_index = @ctz(hw_config.button_pins);
    const pin_end_index = @as(u32, 32) - @clz(hw_config.button_pins);

    while (true) {
        const time_now = time.get_time_since_boot();

        if (time_now.diff(key_old).to_us() > 10_000) {
            if (core1.get_pin_readings()) |readings| {
                keycodes = @splat(0);
                kbd_log.debug("{b:032}", .{readings});

                var key_modifiers: u8 = 0;
                var keycode_index: u3 = 0;
                var pin_mask: u32 = @as(u32, 1) << @truncate(pin_start_index);
                pin_check_loop: for (pin_start_index..pin_end_index) |pin_index| {
                    if (readings & pin_mask != 0) {
                        const keycode = hw_config.pin_conf[pin_index].?.data.button.keycode;

                        if (keycode >= 0xe0 and keycode < 0xe8) {
                            const bit_mask: u8 = @as(u8, 1) << @truncate(keycode - 0xe0);
                            key_modifiers = key_modifiers | bit_mask;
                        } else {
                            keycodes[keycode_index] = hw_config.pin_conf[pin_index].?.data.button.keycode;
                            keycode_index += 1;
                        }

                        if (keycode_index == 6) {
                            kbd_log.warn("key buffer full: {any}", .{keycodes});
                            break :pin_check_loop;
                        }
                    }

                    pin_mask <<= 1;
                }

                usb_if.send_keyboard_report(usb_dev, key_modifiers, keycodes[0..]);
            }

            key_old = time_now;
        }

        // Process pending USB housekeeping
        try usb_dev.task(true);

        if (accel_gyro_maybe) |accel_gyro| {
            const acc = try accel_gyro.read_raw_acceleration();

            // If at least 10ms has passed since last report
            if (time_now.diff(joy_old).to_us() > 10_000) {
                const dist = accel_math.accel_distance(acc, stable_baseline);

                // If we were nudged and not returned to stable position, keep on reporting
                if ((!nudged and dist > 200.0) or nudged) {
                    // Don't report repeating values
                    if (prev_acc[0] != acc[0] or prev_acc[1] != acc[1] or prev_acc[2] != acc[2]) {
                        if (!nudged and dist > 400.0) {
                            nudged = true;
                            ms_log.debug("nudge! {any}", .{acc});
                            pins.led.set_level(100);
                        }

                        prev_acc = acc;
                        usb_if.send_joystick_report(usb_dev, acc);
                        joy_old = time_now;
                    }

                    if (nudged and dist < 50.0) {
                        nudged = false;
                        pins.led.set_level(10);
                    }
                }
            }

            accel_ringbuf[ringbuf_index % ACCELERATION_RINGBUF_LEN] = acc;
            if (ringbuf_index > 0 and ringbuf_index % ACCELERATION_RINGBUF_LEN == 0) {
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
        }

        const elapsed_time = time.get_time_since_boot().diff(time_now).to_us();
        if (elapsed_time < 1_000) {
            time.sleep_us(1_000 - elapsed_time);
        }
    }
}
