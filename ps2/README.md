
Connecting a PS/2 keyboard to the iCE40HX8K will require a level shifter as the keyboard's lines are 5V, while the FPGA is 3.3V tolerant.

Connect the clock and data lines to the high side of the level shifter, and the output (low level) will connect to the FPGA's PS/2 clock and data lines

Since UART is also 5V, the TX line from the FPGA must be connected to the low side of the level shifter, and the output (high side) will connect to the host computer's RX line.