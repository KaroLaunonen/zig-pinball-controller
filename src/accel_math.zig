const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const time = hal.time;

const LSM6DS33 = microzig.drivers.sensor.LSM6DS33;

pub const Acceleration = [3]i16;
pub const ACCELERATION_RINGBUF_LEN = 100;
pub const AccelerationRingbuf = [ACCELERATION_RINGBUF_LEN]Acceleration;

inline fn squared(value: i17) u33 {
    return @as(u33, @intCast(@as(i33, @intCast(value)) * @as(i33, @intCast(value))));
}

pub inline fn accel_distance(accel_1: Acceleration, accel_2: Acceleration) u17 {
    var squared_sum: u34 = squared(@as(i17, @intCast(accel_1[0])) - @as(i17, @intCast(accel_2[0])));
    squared_sum += squared(@as(i17, @intCast(accel_1[1])) - @as(i17, @intCast(accel_2[1])));
    squared_sum += squared(@as(i17, @intCast(accel_1[2])) - @as(i17, @intCast(accel_2[2])));

    return std.math.sqrt(squared_sum);
}

pub fn get_stable_baseline(accel_gyro: *const LSM6DS33, led: hal.pwm.Pwm, accel_ringbuf: *AccelerationRingbuf, stable_baseline: *Acceleration) !void {
    var blinky_prev = time.get_time_since_boot();
    var stable = false;
    var led_on = false;
    var ringbuf_index: u32 = 0;
    var prev_accel_avg: Acceleration = @splat(0);

    std.log.info("start stabilization", .{});

    while (!stable) {
        // LED blinking to indicate running loop
        if (time.get_time_since_boot().diff(blinky_prev).to_us() > 500_000) {
            led.set_level(if (led_on) 100 else 0);
            led_on = !led_on;

            blinky_prev = time.get_time_since_boot();
        }

        const time_start = time.get_time_since_boot();
        accel_ringbuf[ringbuf_index % ACCELERATION_RINGBUF_LEN] = try accel_gyro.read_raw_acceleration();
        if (ringbuf_index > 0 and ringbuf_index % ACCELERATION_RINGBUF_LEN == 0) {
            // Have enough data, calculate average
            // Calculate average
            const accel_avg = calculate_accel_ringbuf_avg(accel_ringbuf[0..]);

            const distance = accel_distance(prev_accel_avg, accel_avg);

            prev_accel_avg = accel_avg;
            std.log.debug("avg: {any} distance prev: {d:5.1}", .{ accel_avg, distance });

            if (distance < 100.0) {
                stable = true;
                stable_baseline.* = accel_avg;
            }
        }

        ringbuf_index += 1;

        const elapsed_us = time.get_time_since_boot().diff(time_start).to_us();

        if (elapsed_us < 5000) {
            time.sleep_ms(@as(u32, @intCast(@divTrunc(5000 - elapsed_us, 1000))));
        }
    }
}

test accel_distance {
    var accel_1: Acceleration = .{ 1, 1, 1 };
    var accel_2: Acceleration = .{ 2, 2, 2 };

    try std.testing.expectEqual(std.math.sqrt(@as(u17, 3)), accel_distance(accel_1, accel_2));
    try std.testing.expectEqual(std.math.sqrt(@as(u17, 3)), accel_distance(accel_2, accel_1));

    accel_1 = .{ 1, 2, 3 };
    accel_2 = .{ 3, 2, 1 };

    try std.testing.expectEqual(2, accel_distance(accel_1, accel_2));

    accel_1 = .{ 32767, 32767, 32767 };
    accel_2 = .{ -32767, -32767, -32767 };

    try std.testing.expectEqual(113508, accel_distance(accel_1, accel_2));
    try std.testing.expectEqual(113508, accel_distance(accel_2, accel_1));
}

pub fn calculate_accel_ringbuf_avg(accel_ringbuf: []Acceleration) Acceleration {
    var accel_sum: [3]i32 = @splat(0);
    for (accel_ringbuf) |accel| {
        inline for (0..3) |i| accel_sum[i] += accel[i];
    }

    const factor = @as(i32, @intCast(accel_ringbuf.len));

    // Calculate average
    const accel_avg: Acceleration = .{
        @as(i16, @intCast(@divTrunc(accel_sum[0], factor))),
        @as(i16, @intCast(@divTrunc(accel_sum[1], factor))),
        @as(i16, @intCast(@divTrunc(accel_sum[2], factor))),
    };

    return accel_avg;
}
