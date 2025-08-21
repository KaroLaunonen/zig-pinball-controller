const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;

const pin_config = @import("pin_config.zig").pin_config;
const uart_log = @import("uart_log.zig");
const usb_if = @import("usb_if.zig");
const accel_math = @import("accel_math.zig");
const acceleration = accel_math.acceleration;
const flash_storage = @import("flash_storage.zig");

const gpio = hal.gpio;
const time = hal.time;

const i2c1 = hal.i2c.instance.I2C1;

const usb_dev = hal.usb.Usb(.{});
const usb = microzig.core.usb;

const drivers = microzig.drivers;
const LSM6DS33 = drivers.sensor.LSM6DS33;

const pins = pin_config.pins();

const Acceleration = accel_math.Acceleration;
const AccelerationRingbuf = accel_math.AccelerationRingbuf;
const ACCELERATION_RINGBUF_LEN = accel_math.ACCELERATION_RINGBUF_LEN;

const configuration = @import("configuration.zig");
const LedPosition = @import("pin_configuration.zig").LedPosition;

const ButtonArray = std.BoundedArray(FlipperButton, 30);

const FlipperButtonReader = microzig.drivers.input.Debounced_Button(.{
    .active_state = .low,
    .filter_depth = 4,
});

const FlipperButton = struct {
    keycode: u8,
    reader: FlipperButtonReader,
};

const FlipperButtonList = std.MultiArrayList(FlipperButton);

// Set std.log to go to uart
pub const microzig_options = microzig.Options{
    .log_level = .debug,
    .logFn = hal.uart.log,
};

pub fn main() !void {
    pin_config.apply();

    _ = uart_log.init();

    std.log.info("Starting pinball controller!\r\n", .{});

    var flash = flash_storage.FlashStorage{};
    const config = flash.getConfigData();

    std.log.info("Flash had config version: {d}", .{config.version});

    // Enable PWM on LED pin
    pins.led.slice().set_wrap(100);
    pins.led.slice().enable();

    const hw_config = try configuration.HardwareConfiguration.init(.{
        .buttons = &.{.{
            .switch_pin = 6,
            .key = .left_shift,
        }},
        .leds = &.{
            .{
                .pin = 7,
                .position = LedPosition.left_flipper,
            },
        },
    });

    var buttons_buffer: [2048]u8 = @splat(0);
    var fba = std.heap.FixedBufferAllocator.init(&buttons_buffer);
    const allocator = fba.allocator();

    var buttons_list = FlipperButtonList{};
    try buttons_list.ensureTotalCapacity(allocator, hw_config.num_buttons());
    defer buttons_list.deinit(allocator);

    //var buttons = try ButtonArray.init(hw_config.num_buttons());
    try setup_buttons(&buttons_list, &hw_config);
    std.log.debug("{d} buttons set up", .{buttons_list.len});

    // Set up I2C
    i2c1.apply(.{
        .clock_config = hal.clock_config,
        .baud_rate = 400_000,
    });

    std.log.info("init lsm6ds33\r\n", .{});
    var accel_gyro_device = hal.drivers.I2C_Device.init(microzig.hal.i2c.instance.I2C1, microzig.hal.i2c.Address.new(0x6a), drivers.time.Duration.from_ms(200));

    const accel_gyro_maybe: ?LSM6DS33 = LSM6DS33.init(accel_gyro_device.datagram_device(), true) catch null;

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
    var time_start = time.get_time_since_boot();
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
    usb_if.init(usb_dev);

    pins.led.set_level(20);

    std.log.info("start main loop", .{});

    var keycodes: [6]u8 = @splat(0);

    while (true) {
        time_start = time.get_time_since_boot();

        const time_now = time.get_time_since_boot();

        // Poll test button
        if (time_now.diff(key_old).to_us() > 10_000) {
            var changed = false;

            // std.log.debug("Read {d} buttons", .{buttons_list.len});
            for (0..buttons_list.len) |button_index| {
                const button = buttons_list.get(button_index);

                var reader = button.reader;
                switch (reader.poll() catch continue) {
                    .pressed => {
                        // std.log.debug("prs {x}", .{button.keycode});

                        changed = changed or add_to_keycodes(&keycodes, button.keycode);
                    },
                    .released => {
                        std.log.debug(" rel {x}", .{button.keycode});

                        changed = changed or remove_from_keycodes(&keycodes, button.keycode);
                    },
                    .idle => {},
                }
            }

            if (changed) {
                usb_if.send_keyboard_report(usb_dev, 0, &keycodes);
                usb_dev.task(true) catch unreachable;
            }

            key_old = time_now;
        }

        // Process pending USB housekeeping
        usb_dev.task(false) catch unreachable;

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
                            std.log.debug("nudge!", .{});
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

        const elapsed_time = time.get_time_since_boot().diff(time_start).to_us();
        if (elapsed_time < 1_000) {
            time.sleep_us(1_000 - elapsed_time);
        }
    }
}

fn setup_buttons(buttons: *FlipperButtonList, conf: *const configuration.HardwareConfiguration) !void {
    var pin_mask: u30 = 1;

    std.log.debug("Setting up buttons", .{});
    var pin_num: u9 = 0;
    while (pin_num < 30) {
        if ((conf.button_pins & pin_mask) != 0) {
            const gpio_pin = hal.gpio.num(pin_num);
            gpio_pin.set_direction(.in);
            gpio_pin.set_pull(.up);

            std.log.debug("gpio {}", .{gpio_pin});
            var gpio_device = hal.drivers.GPIO_Device.init(gpio_pin);
            std.log.debug("gpio digi device {}", .{gpio_device});
            const digital_io_dev = gpio_device.digital_io();
            std.log.debug("digi io device {}", .{digital_io_dev});

            const keycode = conf.pin_conf[pin_num].?.data.button.keycode;
            std.log.debug("keycode {x}", .{keycode});
            std.log.debug("append", .{});
            // try buttons.append(allocator, .{
            //     .keycode = conf.pin_conf[pin].?.data.button.keycode,
            //     .reader = reader,
            // });
            buttons.appendAssumeCapacity(.{
                .keycode = keycode,
                .reader = try FlipperButtonReader.init(digital_io_dev),
            });
            std.log.debug("appended", .{});
        }

        pin_mask <<= 1;
        pin_num += 1;
    }
    std.log.debug("Buttons all set up", .{});
}

inline fn add_to_keycodes(keycodes: *[6]u8, keycode: u8) bool {
    var index: u4 = 0;

    while (index < 6) {
        if (keycodes[index] == keycode) {
            // Already there
            return false;
        } else if (keycodes[index] == 0) {
            // Found an empty spot
            std.log.debug(" * empty slot at {d}", .{index});
            keycodes[index] = keycode;
            return true;
        }

        index += 1;
    }

    // Didn't have space
    std.log.warn("Keypress didn't fit", .{});
    return false;
}

inline fn remove_from_keycodes(keycodes: *[6]u8, keycode: u8) bool {
    var index: u4 = 0;

    while (index < 6) {
        if (keycodes[index] == keycode) {
            // Found
            while (keycodes[index] != 0 and index < 5) {
                keycodes[index] = keycodes[index + 1];
                index += 1;
            }
            keycodes[5] = 0;

            return true;

        } else if (keycodes[index] == 0) {
            // Wasn't here
            return false;
        }

        index += 1;
    }

    // Wasn't here
    return false;
}
