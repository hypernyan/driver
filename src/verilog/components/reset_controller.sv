module reset_controller (
	input logic  rstn,
    input logic  clk_in,

	output logic clk_out,
	output logic rst_out
);

pll pll_inst (
	.areset (1'b0),
	.inclk0 (clk_in),
	.c0     (clk_out),
	.locked (locked)
);

logic rst_reg;
assign arst = !locked || !rstn;

always @ (posedge clk_out or posedge arst) begin
	if (arst) {rst_out, rst_reg} <= 2'b11;
	else      {rst_out, rst_reg} <= {rst_reg, 1'b0};
end

endmodule
