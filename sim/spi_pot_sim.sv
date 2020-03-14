`include "../../sim/timescale.v"

module spi_pot_sim (
	input  logic scl,
	input  logic sda,
	input  logic csn,
	input  real  in,
	output real  out   
);

logic [15:0] cur_data;
logic [15:0] data;
real  res;
real         gain;

initial begin
	data = 0;
	cur_data = 0;
end

always @ (posedge scl or posedge csn) begin
	if (csn) cur_data <= '0;
	if (!csn) begin
		cur_data[0] <= sda;
		cur_data[15:1] <= cur_data[14:0];
	end
end

always @ (posedge csn) data <= cur_data;

assign res = data[7:0];
assign gain = ((255 - res)/(255));
assign out = in * gain;

endmodule
