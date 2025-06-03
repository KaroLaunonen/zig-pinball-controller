const std = @import("std");

pub const acceleration = [3]i16;

inline fn squared(value: i17) u33 {
    return @as(u33, @intCast(@as(i33, @intCast(value)) * @as(i33, @intCast(value))));
}

pub inline fn accel_distance(accel_1: acceleration, accel_2: acceleration) u17 {
    var squared_sum: u34 = squared(@as(i17, @intCast(accel_1[0])) - @as(i17, @intCast(accel_2[0])));
    squared_sum += squared(@as(i17, @intCast(accel_1[1])) - @as(i17, @intCast(accel_2[1])));
    squared_sum += squared(@as(i17, @intCast(accel_1[2])) - @as(i17, @intCast(accel_2[2])));

    return std.math.sqrt(squared_sum);
}

test accel_distance {
    var accel_1: acceleration = .{ 1, 1, 1 };
    var accel_2: acceleration = .{ 2, 2, 2 };

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

pub fn calculate_accel_ringbuf_avg(accel_ringbuf: []acceleration) acceleration {
    var accel_sum: [3]i32 = @splat(0);
    for (accel_ringbuf) |accel| {
        inline for (0..3) |i| accel_sum[i] += accel[i];
    }

    const factor = @as(i32, @intCast(accel_ringbuf.len));

    // Calculate average
    const accel_avg: acceleration = .{
        @as(i16, @intCast(@divTrunc(accel_sum[0], factor))),
        @as(i16, @intCast(@divTrunc(accel_sum[1], factor))),
        @as(i16, @intCast(@divTrunc(accel_sum[2], factor))),
    };

    return accel_avg;
}
