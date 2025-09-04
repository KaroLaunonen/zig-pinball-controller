const microzig = @import("microzig");
const rp2xxx = microzig.hal;

pub var uart_writer: rp2xxx.uart.UART.Writer = undefined;

pub fn init() rp2xxx.uart.UART.Writer {
    // Init UART0 and logging
    const uart0 = rp2xxx.uart.instance.UART0;

    rp2xxx.uart.UART.apply(uart0, .{
        .baud_rate = 115200,
        .clock_config = rp2xxx.clock_config,
    });

    rp2xxx.uart.init_logger(uart0);

    uart_writer = uart0.writer();
    return uart0.writer();
}
