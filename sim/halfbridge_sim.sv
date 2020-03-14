`include "../../sim/timescale.v"

module halfbridge_sim (
	input  logic [1:0] gate,
	input  real u_in,
	output real u_out,
	output bit short
);

always_comb begin
	case (gate)
		2'b00 : begin
			short = 0;
			u_out = 0;
		end
		2'b10 : begin
			short = 0;
			u_out = u_in/2; 
		end
		2'b01 : begin
			short = 0;
			u_out = -u_in/2; 
		end
		2'b11 : begin
			short = 1;
			u_out = 0;
		end
	endcase
end

endmodule

