
`timescale 1 ns / 1 ps

// synopsys sync_set_reset "rsn_n"
// synopsys sync_set_reset "rsn"

module reset_controller (
	input wire clk_50m,
	input wire ext_rst,  // external async reset
	
	output wire clk_100m,
	output wire rst,
	output wire arst
);

logic rst_100m, arst_n;

logic_pll logic_pll_inst(
	.inclk0   ( clk_25m ),
	.areset   ( ext_rst ),
	.c0 ( clk_125m ),
	.locked   ( arst_n )
);

always_ff @ (posedge clk_100m or negedge arst_n) begin
	if (!arst_n) {rst_100m, rst} <= 2'b00;
	else {rst_100m, rst} <= {rst, 1'b1};
end

assign arst = !arst_n;

endmodule