# igbt.io fpga transistor driver
FPGA-based driver for controlling MOSFETs and IGBTs. The driver provides gate drive signal with parameters set by user via USB with a convinient protocol. Currently, the driver based on a low-cost CYC1000 dev board.
## Features
- Controlled via USB
- Low cost, easy to build
- GDT-based
- Full digital gate drive
- Variable frequency, duty cycle/dead time
## Quick start
1. Plug in your CYC1000 from Trenz Electronic.
2. Open driver.qpf with Quartus from Intel FPGA.
3. Go to Tools, choose Programmer.
4. Delete driver.sof from the list as .sof files only configure the FPGA, not rewrtining configuration memory.
5. Add File... output_file.jic.
6. Press Start, wait for programmer to finish, replug the CYC1000.
## Testing
This is FPGA's direct output captured with a 200 MHz scope:

![Sample Scope](https://github.com/hypernyan/driver/blob/master/pic/tek_200kHz.BMP)

About 2.5 nS rise/fall time:

![Sample Scope Rise](https://github.com/hypernyan/driver/blob/master/pic/tek_200kHz_rise.BMP)

## Customizing logic
If needed, basic parameters such as FPGA operating frequency and VCOM settings are edited with top module parameters. Default (startup) values for driver can be edited in /src/comm/p10.sv: e.g.: `prm_ram[ADDR_FREQ] = 10000;`

## Building project
Build is automated by tcl script create_prj.tcl. Run it with complete_flow.bat. Quartus executable must be in PATH.
## Communication via USB
The p10 protocol is an ASCII-based protocol for controlling an FPGA. Currently, p10 is working over USB VCOM. Any terminal capable of VCOM should do. Default settings: 57600 baud 8N1.
p10 stands for "protocol decimal" because it operates with decimal numbers. Vaules are written and read with ASCII symbols 0 to 9. 
p10 is a request-reply protocol with no track of incoming packets. However, it will reply with an error if command is not valid. The list of errors that may occur:
- "bad command". No valid command was found
- "bad data". Data is not integer or otherwise incorrect
- "bad parameter". No valid was found
- "read-only". Attempt to set a read-only parameter
- "parameter not found"
- value too low"
- "value too high"
- "timeout". No correct command ending was detected

A p10 request always starts with a start symbol "\`". It is then followed by a "command". Depending on the command, further data varies.

### Commands
Supported commands are:
- set. sets a "parameter" to a "value". Ex: \`set-freq:10.2k; will set frequency to 10200 Hz. Reply should be: >freq: parameter set;
- get. reads a "parameter". Ex: \`get-freq; Reply should be >freq:10000Hz;
- ver. Returns a string containing version and build date.

Sample configuration with p10:

![Sample Output](https://github.com/hypernyan/driver/blob/master/pic/p10_sample_termite.jpg)
