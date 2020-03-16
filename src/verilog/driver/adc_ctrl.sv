/*
module adc_ctrl #(
	parameter SPI_PRESCALER     = 10,  
	parameter TARGET_LEVEL      = 0.25, // Set target AGC value with respect to ADC pk-pk
	parameter AGC_BITS          = 8,    // Input data bits
	parameter ADC_BITS          = 8,    // AGC bits
	parameter LOAD_RESISTOR_OHM = 5,     // Load resistor for current transformer
	parameter CURRENT_MAX_AMP   = 1     // Maximum rated current on CT's secondary 
)
(
	input  logic clk,
	input  logic rst,

	input  logic [7:0] adc,
	output logic [7:0] gain,

	zc.out       zc,
	ocd.out      ocd,

	output logic csn,
	output logic sda,
	output logic scl,

	ram_if.sys   ram_if
);

logic [AGC_BITS-1:0] agc;
logic agc_upd;

agc #(
	.ADC_BITS     (ADC_BITS),
	.AGC_BITS     (AGC_BITS),
	.TARGET_LEVEL (TARGET_LEVEL)
) agc_inst (
	.clk  (clk),
	.rst  (rst),
	.in   (adc),
	.gain (gain), // Note that 0 AGC means zero attenuation, '1 AGC means infinite attenuation
	.upd  (agc_upd)
);

spi #(
	.PRESCALER   (SPI_PRESCALER), 
	.WRITE_WIDTH (16),
	.READ_WIDTH  (0)
) spi_inst (
	.clk  (clk),
	.rst  (rst),

	.SDA  (sda),
	.SCL  (scl),

	.din  ({2'b00, 2'b01, 2'b00, 2'b01, gain}),
	.vin  (agc_upd),
	.r_nw (1'b0),
	.busy (busy)
);

assign csn = !busy;

endmodule
*/