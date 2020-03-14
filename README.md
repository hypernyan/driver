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
Before driving actual transistors, 
## Customizing logic
...
## Building project
...
## Communication via USB
The p10 protocol is an ASCII-based protocol for controlling an FPGA. Currently, user controls the driver via USB VCOM. Any terminal capable of VCOM should do.
p10 stands for "protocol decimal" because it operates with decimal numbers.
p10 is a request-reply protocol with no track of incoming packets. However, it will reply with an error if command is not valid. The list of errors that may occur:
- "bad command". No valid command was found
- "bad data". Data is not integer or otherwise incorrect
- "bad parameter". No valid was found
- "read-only". Attempt to set a read-only parameter
- parameter not found
- value too low
- value too high
- timeout

A p10 request always starts with a start symbol "`". It is then followed by a "command". Depending on the command, further data varies.

### Commands
Supported commands are:
- set. sets a "parameter" to a "value". Ex: `set-freq:10.2k; will set frequency to 10200 Hz. Reply should be: >freq: parameter set;
- get. reads a "parameter". Ex: `get-freq; Reply should be >freq:10000Hz;