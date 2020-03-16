`define PI 3.14159

module hilbert_transform #(
	parameter BITS_COEFF = 8,
	parameter BITS_DATA  = 8,
	parameter BITS_MAC   = 16,
	parameter TAPS       = 16,
	parameter SIM        = 1,
	parameter DECIMATION = 1
)
(
	input  logic                 clk,
	input  logic [BITS_DATA-1:0] in,
	output logic [BITS_DATA-1:0] out,
	output logic                 en
);

localparam TAPS_HALF = $ceil(TAPS/2);
localparam BITS_HALF = $ceil(BITS_DATA/2);

localparam BIAS = 2**(BITS_DATA-1)-1;

function signed [BITS_DATA-1:0] conv; // Convert 0..+Vpp to -Vpp/2..+Vpp/2
	input [BITS_DATA-1:0] in;
	static int bias = 2**(BITS_DATA-1)-1;
	logic signed [BITS_DATA-1:0] value;
	value[BITS_DATA-1]   = (bias > in);
	value[BITS_DATA-2:0] = (bias > in) ? ~(bias-in) - 1 : (in-bias);
	conv = value;
endfunction

logic [$clog2(DECIMATION):0] ctr = 0;

logic signed [TAPS-1:0] [BITS_COEFF-1:0]      coeff;
logic signed [TAPS-1:0] [BITS_DATA-1:0]       pipe;
logic signed                  [BITS_DATA-1:0] in_delay;
logic signed [TAPS-1:0] [BITS_DATA+BITS_COEFF-1:0]   prod;

logic signed [15:0] ampl;
logic signed [BITS_DATA*2:0] square_sum;

logic signed [BITS_DATA*2-1:0] square_in, square_out;
logic signed [TAPS:0] [BITS_COEFF+BITS_DATA+TAPS-1:0] mac;
assign mac[0] = 0;
genvar i;

generate
	for (i = 0; i < TAPS; i++) begin : gen
		assign coeff[i] = (i%2) ? 0 : (i > (TAPS-1)/2) ? (-1)*2**BITS_COEFF/(`PI*((TAPS-1)/2-i)) : 2**BITS_COEFF/(`PI*(i-(TAPS-1)/2));
		assign prod[i]  = $signed(coeff[i])*$signed(pipe[i]);
		assign mac[i+1] = $signed(mac[i]) + $signed(prod[i]);
	end
endgenerate

always @ (posedge clk) ctr <= (ctr == DECIMATION-1) ? 0 : ctr + 1;
assign en = (ctr == DECIMATION-1);

always @ (posedge clk) if (en) pipe[TAPS-1:1] <= pipe[TAPS-2:0];

assign pipe[0] = conv(in);

assign in_delay = pipe[TAPS_HALF-1];

assign square_in  = $signed(in_delay)*$signed(in_delay);
assign square_out = $signed(out)*$signed(out); //*(out-BIAS);
assign square_sum = square_in + square_out;

assign out = mac[TAPS][BITS_MAC-1-:BITS_DATA];

endmodule
