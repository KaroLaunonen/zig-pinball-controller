const std = @import("std");
const microzig = @import("microzig");

const rp2xxx = microzig.hal;
const flash = rp2xxx.flash;
const time = rp2xxx.time;
const gpio = rp2xxx.gpio;
const clocks = rp2xxx.clocks;
const usb = rp2xxx.usb;

const DUMP_DESCRIPTORS = true;

// HID
const hid = usb.hid;
const hid_usage = usb.hid.hid_usage;
const hid_usage_page = usb.hid.hid_usage_page;
const hid_usage_min = usb.hid.hid_usage_min;
const hid_collection = usb.hid.hid_collection;
const hid_collection_end = usb.hid.hid_collection_end;
const hid_logical_min = usb.hid.hid_logical_min;
const hid_logical_max = usb.hid.hid_logical_max;
const hid_physical_min = usb.hid.hid_physical_min;
const hid_physical_max = usb.hid.hid_physical_max;
const hid_report_id = usb.hid.hid_report_id;
const hid_report_size = usb.hid.hid_report_size;
const hid_report_count = usb.hid.hid_report_count;
const hid_input = usb.hid.hid_input;
const UsageTable = usb.hid.UsageTable;
const CollectionItem = usb.hid.CollectionItem;

const ReportDescriptorPinballController = hid_usage_page(1, UsageTable.desktop) //
    ++ hid_usage(1, "\x04".*) //
    ++ hid_collection(CollectionItem.Application) //
    ++ hid_collection(CollectionItem.Logical)   // Usage Data In

    ++ hid_logical_min(2, "\x00\x80".*) // -32767
    ++ hid_logical_max(2, "\xff\x7f".*) // 32767
    ++ hid_report_size(1, "\x10".*)     // 16 bits
    ++ hid_report_count(1, "\x03".*)    // 3 reports
    ++ hid_usage(1, "\x30".*)           // X axis
    ++ hid_usage(1, "\x31".*)           // Y axis
    ++ hid_usage(1, "\x32".*)           // Z axis
    ++ hid_input(hid.HID_DATA | hid.HID_VARIABLE | hid.HID_ABSOLUTE | hid.HID_WRAP_NO | hid.HID_LINEAR | hid.HID_PREFERRED_STATE | hid.HID_NO_NULL_POSITION) //
                                                                                                                                                             //
    ++ hid_usage_page(1, UsageTable.button)     // Have to have a button, otherwise won't be interpreted as a joystick
    ++ hid_usage(1, "\x01".*)           // Usage Buttons
    ++ hid_report_size(1, "\x01".*)     // 1 bit
    ++ hid_report_count(1, "\x01".*)    // 1 report
    ++ hid_input(hid.HID_DATA | hid.HID_VARIABLE | hid.HID_ABSOLUTE)
    ++ hid_report_count(1, "\x07".*)    // 7 bits padding
    ++ hid_input(hid.HID_CONSTANT | hid.HID_VARIABLE | hid.HID_ABSOLUTE)
    // End
    ++ hid_collection_end()
    ++ hid_collection_end();

const usb_packet_size = 8;
const usb_config_len = usb.templates.config_descriptor_len + usb.templates.hid_in_descriptor_len;
const usb_config_descriptor =
    usb.templates.config_descriptor(1, 1, 0, usb_config_len, 0x80, 500) ++
    usb.templates.hid_in_descriptor(0, 0, 0,
        ReportDescriptorPinballController.len,
        usb.Endpoint.to_address(1, .In),
        usb_packet_size, 10);

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

    // Initialize endpoint for joystick
    const ep_addr = rp2xxx.usb.Endpoint.to_address(1, .In);
    usb_dev.callbacks.endpoint_open(ep_addr, 64, usb.types.TransferType.Interrupt);

    while (!usb_dev.device_ready()) {
        usb_dev.task(false) catch unreachable;
    }
    std.log.debug("USB configured", .{});
}

pub fn send_joystick_report(usb_dev: type, endpoint_addr: u8, data: []const u8) void {
    usb_dev.callbacks.usb_start_tx(endpoint_addr, data);
}
