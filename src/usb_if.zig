const std = @import("std");
const microzig = @import("microzig");

const rp2xxx = microzig.hal;
const flash = rp2xxx.flash;
const time = rp2xxx.time;
const gpio = rp2xxx.gpio;
const clocks = rp2xxx.clocks;
const usb = rp2xxx.usb;

const hid = usb.hid;

const HID_KeymodifierCodes = enum(u8) {
    left_control    = 0xe0,
    left_shift,
    left_alt,
    left_option,
    left_gui,
    right_control,
    right_shift,
    right_alt,
    right_gui
};

const HID_Report_IDs = enum(u8) {
    reserved    = 0x00,     // can't use report id 0
    joystick    = 0x01,
    keyboard,
    leds
};

const ReportDescriptorPinballController = hid.hid_usage_page(1, hid.UsageTable.desktop)
    ++ hid.hid_usage(1, hid.DesktopUsage.joystick)
    ++ hid.hid_collection(hid.CollectionItem.Application) // Application collection
    ++ hid.hid_collection(hid.CollectionItem.Logical)   // Logical collection

    ++ hid.hid_report_id(1, .{ @intFromEnum(HID_Report_IDs.joystick)} )
    ++ hid.hid_logical_min(2, "\x00\x80".*)     // -32767
    ++ hid.hid_logical_max(2, "\xff\x7f".*)     // 32767
    ++ hid.hid_report_size(1, "\x10".*)         // 16 bits
    ++ hid.hid_report_count(1, "\x03".*)        // 3 reports
    ++ hid.hid_usage(1, hid.DesktopUsage.x_axis)    // X axis
    ++ hid.hid_usage(1, hid.DesktopUsage.y_axis)    // Y axis
    ++ hid.hid_usage(1, hid.DesktopUsage.z_axis)    // Z axis
    ++ hid.hid_input(hid.HID_DATA | hid.HID_VARIABLE | hid.HID_ABSOLUTE | hid.HID_WRAP_NO | hid.HID_LINEAR | hid.HID_PREFERRED_STATE | hid.HID_NO_NULL_POSITION) //
                                                                                                                                                             //
    ++ hid.hid_usage_page(1, hid.UsageTable.button)     // Have to have a button, otherwise won't be interpreted as a joystick
    ++ hid.hid_usage(1, "\x01".*)           // Usage Buttons
    ++ hid.hid_report_size(1, "\x01".*)     // 1 bit
    ++ hid.hid_report_count(1, "\x01".*)    // 1 report
    ++ hid.hid_input(hid.HID_DATA | hid.HID_VARIABLE | hid.HID_ABSOLUTE)
    ++ hid.hid_report_count(1, "\x07".*)    // 7 bits padding
    ++ hid.hid_input(hid.HID_CONSTANT | hid.HID_VARIABLE | hid.HID_ABSOLUTE)
    // End
    ++ hid.hid_collection_end()
    ++ hid.hid_collection_end()

    // Keyboard HID
    ++ hid.hid_usage_page(1, hid.UsageTable.keyboard)
    ++ hid.hid_usage(1, hid.DesktopUsage.keyboard)
    ++ hid.hid_collection(hid.CollectionItem.Application)
    ++ hid.hid_report_id(1, .{ @intFromEnum(HID_Report_IDs.keyboard)} )
    ++ hid.hid_usage_page(1, hid.UsageTable.keyboard)
    ++ hid.hid_usage_min(1, .{ @intFromEnum(HID_KeymodifierCodes.left_alt) })
    ++ hid.hid_usage_max(1, .{ @intFromEnum(HID_KeymodifierCodes.right_shift) })
    ++ hid.hid_logical_min(1, "\x00".*)
    ++ hid.hid_logical_max(1, "\x01".*)
    ++ hid.hid_report_size(1, "\x01".*)
    ++ hid.hid_report_count(1, "\x08".*)
    ++ hid.hid_input(hid.HID_DATA | hid.HID_VARIABLE | hid.HID_ABSOLUTE)
    ++ hid.hid_report_count(1, "\x06".*)
    ++ hid.hid_report_size(1, "\x08".*)
    ++ hid.hid_logical_max(1, "\x65".*)
    ++ hid.hid_usage_min(1, "\x00".*)
    ++ hid.hid_usage_max(1, "\x65".*)
    ++ hid.hid_input(hid.HID_DATA | hid.HID_ARRAY | hid.HID_ABSOLUTE)
    ++ hid.hid_collection_end();

var reportBuf: [8]u8 = @splat(0);
const epAddr = rp2xxx.usb.Endpoint.to_address(1, .In);

const usb_packet_size = 8;
const usb_config_len = usb.templates.config_descriptor_len + usb.templates.hid_in_descriptor_len;
const usb_config_descriptor =
    usb.templates.config_descriptor(1, 1, 0, usb_config_len, 0x80, 500) ++
    usb.templates.hid_in_descriptor(0, 0, 0,
        ReportDescriptorPinballController.len,
        usb.Endpoint.to_address(1, .In),
        usb_packet_size, 2);

var driver_hid = usb.hid.HidClassDriver{ .report_descriptor = &ReportDescriptorPinballController };
var drivers = [_]usb.types.UsbClassDriver{ driver_hid.driver() };

// This is our device configuration
pub var DEVICE_CONFIGURATION: usb.DeviceConfiguration = .{
    .device_descriptor = &.{
        .descriptor_type = usb.DescType.Device,
        .bcd_usb = 0x0200,
        .device_class = 0,
        .device_subclass = 0,
        .device_protocol = 0,
        .max_packet_size0 = 64,
        .vendor = 0xFAFA,
        .product = 0x00F0,
        .bcd_device = 0x0100,
        // Those are indices to the descriptor strings
        // Make sure to provide enough string descriptors!
        .manufacturer_s = 1,
        .product_s = 2,
        .serial_s = 3,
        .num_configurations = 1,
    },
    .config_descriptor = &usb_config_descriptor,
    .lang_descriptor = "\x04\x03\x09\x04", // length || string descriptor (0x03) || Engl (0x0409)
    .descriptor_strings = &.{
        &usb.utils.utf8ToUtf16Le("RaspPi"),
        &usb.utils.utf8ToUtf16Le("LedWiz clone"),
        &usb.utils.utf8ToUtf16Le("cafebabe"),
    },
    .drivers = &drivers,
};

pub fn init(usb_dev: type) void {
    // First we initialize the USB clock
    usb_dev.init_clk();

    // Then initialize the USB device using the configuration defined above
    usb_dev.init_device(&DEVICE_CONFIGURATION) catch unreachable;

    // Initialize endpoint for HID device
    usb_dev.callbacks.endpoint_open(epAddr, 512, usb.types.TransferType.Interrupt);

    while (!usb_dev.device_ready()) {
        usb_dev.task(false) catch unreachable;
    }
    std.log.debug("USB configured", .{});
}

pub fn send_joystick_report(usb_dev: type, axis_values: [3]i16) void {
    reportBuf[0] = @intFromEnum(HID_Report_IDs.joystick);
    std.mem.writeInt(i16, reportBuf[1..3], axis_values[0], .big);
    std.mem.writeInt(i16, reportBuf[3..5], axis_values[1], .big);
    std.mem.writeInt(i16, reportBuf[5..7], axis_values[2], .big);
    reportBuf[7] = 0;

    usb_dev.callbacks.usb_start_tx(epAddr, &reportBuf);
}

pub fn send_keyboard_report(usb_dev: type, keycodes: []const u8) void {
    reportBuf = @splat(0);
    reportBuf[0] = @intFromEnum(HID_Report_IDs.keyboard);
    for (keycodes, 2..) |keycode, index| {
        if (index == 8) {
            std.log.warn("keybuf overflow", .{});
            break;
        }
        reportBuf[index] = keycode;
    }

    usb_dev.callbacks.usb_start_tx(epAddr, &reportBuf);
}
