const std = @import("std");
const microzig = @import("microzig");

const flash = microzig.hal.flash;

// Magic number to determine, if the config flash has been initialized
const CONFIG_FLASH_MAGIC_NUMBER = 0xcafebabe;

// These are defined in the linker script
extern const config_data_start: u8;
extern const config_data_end: u8;

pub const ConfigData = packed struct {
    magic_number: u32,
    version: u8,

    // Actual config here, please
};

const EMPTY_CONFIG: ConfigData = .{
    .magic_number = CONFIG_FLASH_MAGIC_NUMBER,
    .version = 1,
};

pub const FlashStorage = struct {
    // Have to use volatile here as the flash is MMIO
    flash_data_ptr: *volatile ConfigData = undefined,

    pub fn getConfigData(self: *@This()) *const ConfigData {
        const config_data_start_addr = @intFromPtr(&config_data_start);

        self.flash_data_ptr = @ptrFromInt(config_data_start_addr);

        std.log.info("Config data at 0x{x}, sector size: {d}, page size: {d}", .{ @intFromPtr(self.flash_data_ptr), flash.SECTOR_SIZE, flash.PAGE_SIZE });
        if (self.flash_data_ptr.magic_number != CONFIG_FLASH_MAGIC_NUMBER) {
            std.log.info("config flash not initialized (magic was: {x} expected: {x})", .{ self.flash_data_ptr.magic_number, CONFIG_FLASH_MAGIC_NUMBER });

            // _init_flash(self);
            return &EMPTY_CONFIG;
        } else {
            std.log.info("Magic number matches, config flash ok", .{});

            return @volatileCast(self.flash_data_ptr);
        }
    }

    pub fn setConfigData(self: *@This(), config: ConfigData, allocator: std.mem.Allocator) !void {
        const flash_offset = @intFromPtr(self.flash_data_ptr) - flash.XIP_BASE;

        std.log.info("erasing config flash, flash_offset: 0x{x}, erase size: {}", .{ flash_offset, flash.SECTOR_SIZE });
        flash.range_erase(flash_offset, flash.SECTOR_SIZE);

        std.log.info("program config flash", .{});
        var buffer = allocator.alignedAlloc(u8, flash.PAGE_SIZE, flash.SECTOR_SIZE);
        @memcpy(buffer[0..@sizeOf(ConfigData)], std.mem.asBytes(&config));
        flash.range_program(flash_offset, &buffer);

        std.log.info("done flashing, magic: {x}", .{self.flash_data_ptr.magic_number});
    }

    // fn _init_flash(self: *@This()) void {
    //     // Initialize config flash with empty config data
    //
    //     const flash_offset = @intFromPtr(self.flash_data_ptr) - flash.XIP_BASE;
    //
    //     std.log.info("erasing config flash, flash_offset: 0x{x}, erase size: {}", .{ flash_offset, flash.SECTOR_SIZE });
    //     flash.range_erase(flash_offset, flash.SECTOR_SIZE);
    //
    //     std.log.info("program config flash", .{ });
    //     var buffer: [flash.PAGE_SIZE]u8 = @splat(0);
    //     @memcpy(buffer[0..@sizeOf(@TypeOf(EMPTY_CONFIG))], std.mem.asBytes(&EMPTY_CONFIG));
    //     flash.range_program(flash_offset, &buffer);
    //
    //     std.log.info("done flashing, magic: {x}", .{ self.flash_data_ptr.magic_number });
    // }
};
