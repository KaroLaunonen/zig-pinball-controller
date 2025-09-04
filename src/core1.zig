const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const pins = @import("pin_config.zig").pins;

const core1_log = std.log.scoped(.core1_log);

// How long (in microseconds) does the pin has to have the same reading
// to be considered stable.
const PIN_STABLE_DURATION_US = 2_000;

// Bitfield for values of all pins
var pin_readings = std.atomic.Value(u32){ .raw = 0 };
// Bitmask for used button pins
var button_pins = std.atomic.Value(u32){ .raw = 0 };
// Flag whether pin readings have changed since last get_readings call
var changed = false;

pub fn core1_entry() void {
    // Timestamp for previous signal edge
    var edge_times: [30]u64 = @splat(0);
    // Previous value for pin read
    var prev_reads: [30]u1 = @splat(0);

    // Bit field on pin readings, 1 = active (low physically), 0 = inactive
    var prev_readings: u32 = 0;

    var led_bright = false;

    // Read pin mask for configured pins
    core1_log.debug("waiting for pin config", .{});
    while (button_pins.load(.monotonic) == 0) {
        hal.time.sleep_ms(100);

        pins.led.set_level(if (led_bright) 100 else 20);
        led_bright = !led_bright;
    }

    var time_now = hal.time.get_time_since_boot();
    var led_stamp = hal.time.get_time_since_boot();

    // Skip unused pins from start and end by counting zero bits
    const temp_button_pins = button_pins.load(.monotonic);
    const start_index = @ctz(temp_button_pins);
    const end_index = 32 - @clz(temp_button_pins);

    core1_log.debug("start reading the pins", .{});

    while (true) {
        time_now = hal.time.get_time_since_boot();

        // Pin mask for checking current button
        var pin_mask: u32 = @as(u32, 1) << @truncate(start_index);
        var temp_pin_readings = pin_readings.load(.monotonic);
        prev_readings = temp_pin_readings;

        for (start_index..end_index) |pin_index| {
            // If this pin is in the configured ones
            if (temp_button_pins & pin_mask != 0) {
                const gpio_pin = hal.gpio.num(@truncate(pin_index));

                const value = gpio_pin.read();

                if (value != prev_reads[pin_index]) {
                    // Edge detected
                    edge_times[pin_index] = time_now.to_us();
                    prev_reads[pin_index] = value;
                }

                if (time_now.to_us() - edge_times[pin_index] > PIN_STABLE_DURATION_US) {
                    // Pin reading has been stable, commit the change
                    if (value == 0) {
                        temp_pin_readings = temp_pin_readings | pin_mask;
                    } else {
                        temp_pin_readings = temp_pin_readings & ~pin_mask;
                    }
                }
            }

            pin_mask <<= 1;
        }

        // Write the readings to core0 if they have changed and fifo is not full
        if (prev_readings != temp_pin_readings) {
            changed = true;
            pin_readings.store(temp_pin_readings, .monotonic);
        }

        if (time_now.diff(led_stamp).to_us() > 500_000) {
            pins.led.set_level(if (led_bright) 40 else 20);
            led_bright = !led_bright;
            led_stamp = time_now;
        }

        hal.time.sleep_us(100);
    }
}

pub fn get_pin_readings() ?u32 {
    if (changed) {
        changed = false;
        return pin_readings.load(.monotonic);
    }

    return null;
}

pub fn set_button_pins(pin_mask: u32) void {
    button_pins.store(pin_mask, .monotonic);
}
