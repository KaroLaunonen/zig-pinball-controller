# Raspberry Pi Pico Pinball Controller

A Raspberry Pi Pico-based pinball controller for use with Visual Pinball X that uses MicroZig
and the Raspberry Pi Pico's USB HID, as well as I2C and GPIO input/output. The main goal of this
project is to provide a customizable and extensible pinball controller using Zig programming language.

Note, this project is for personal need and for learning Zig and MicroZig. After coding this for a while I found a
proper Pinball controller project for Pico. Check out [Pinscape Pico](https://github.com/mjrgh/PinscapePico) for a
proper controller. If you still rather learn Zig, then welcome!

## Features

- USB HID implementation with joystick and keyboard interfaces.
- Accelerometer (LSM6DS33) data processing for nudges.
- Debounced GPIO button input for pinball buttons.

TODO
- physical pinball plunger reading using two photosensors/slotted optical switches in a row (such as Omron EE-SX1081
  or CNY36 or similar). A comb is mounted inside the machine on the plunger mount. The sensors that move on the comb 
  are mounted on the plunger rod. The comb movement can be read with rotary encoder algorithm.
- [LedWiz](https://groovygamegear.com/webstore/index.php?main_page=product_info&products_id=239) compatible led control.
- maybe rotary encoder for volume knob.

## Prerequisites

To build and run this project, you need the following:

- [Zig](https://ziglang.org/) programming language.
- [MicroZig](https://microzig.github.io/microzig/) framework for embedded development.
- A Raspberry Pi Pico board.
- An LSM6DS33 accelerometer and gyroscope module.

## Hardware Setup

Connect I²C LSM6DS33 board to pins GPIO4 (SDA) and GPIO5 (SCL).

Connect the flipper button to a GPIO pin on your Raspberry Pi Pico board. In this project, it's connected to GP15 (Pin 20).

## Building and Running

1. Clone this repository:

   ```sh
   git clone https://github.com/KaroLaunonen/zig-pinball-controller.git
   cd zig-pinball-controller

2. Build the project using Zig:

    ```sh
    zig build -Dtarget=microzig-rp2040

## Author
Karo Launonen - karo.launonen@boogiesoftware.com

## Contributing

Contributions are welcome! If you have any ideas, suggestions, or bug reports, please open an issue on GitHub.
Pull requests are also encouraged.

## License
This project is licensed under the GPL v3 License — see the LICENSE file for details.
