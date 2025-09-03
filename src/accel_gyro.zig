const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const drivers = microzig.drivers;
const LSM6DS33 = drivers.sensor.LSM6DS33;

pub fn init() !?LSM6DS33 {
    std.log.info("init lsm6ds33", .{});
    var accel_gyro_device = hal.drivers.I2C_Device.init(microzig.hal.i2c.instance.I2C0, microzig.hal.i2c.Address.new(0x6a), drivers.time.Duration.from_ms(200));

    const accel_gyro_maybe: ?LSM6DS33 = LSM6DS33.init(accel_gyro_device.datagram_device(), true) catch null;

    if (accel_gyro_maybe) |accel_gyro| {
        try accel_gyro.reset();
        try accel_gyro.set_high_performance_mode(.enabled);
        try accel_gyro.set_output_data_rate(.hz_104);
        try accel_gyro.set_accelerator_full_scale(.fs_2g);
        try accel_gyro.set_anti_aliasing_filter_bandwidth(.fb_50hz);
        std.log.info("done init lsm6ds33", .{});
    }

    return accel_gyro_maybe;
}
