
module agc #(
	parameter ADC_BITS     = 8,
	parameter AGC_BITS     = 8,
	parameter TARGET_LEVEL = 0.25,
	parameter AGC_SETTLE_TICKS = 1000
)
(
	input  logic clk,
	input  logic rst,
	input  logic [ADC_BITS-1:0] in,
	output logic [AGC_BITS-1:0] agc, // 0 AGC means zero attenuation, '1 AGC means infinite attenuation
	output logic                upd
);

localparam TARGET_LEVEL_BITS = (2**ADC_BITS)*TARGET_LEVEL;

logic ovfl;

logic zc_np;
logic zc_pn;
logic zc;

logic rst_peak;
logic [ADC_BITS-1:0] peak;
logic [ADC_BITS-1:0] peak_prev;
logic [ADC_BITS-1:0] cur_peak;

zc_detector zc_detector_inst (
	.clk   (clk),
	.rst   (rst),
	.in    (in),
	.zc_np (zc_np),
	.zc_pn (zc_pn),
	.peak  (peak_prev)
);

peak_hold #(
	.BITS (ADC_BITS)	
) peak_hold_inst (
	.clk  (clk),
	.rst  (rst_peak),
	.zc   (zc_np || zc_pn),
	.in   (in),
	.peak (peak),
	.peak_prev (peak_prev),
	.ovfl (peak_ovfl)
);

assign zc = (zc_np || zc_pn);

assign ovfl = (in == 'b0) || (in == 'b1);

always @ (posedge clk) begin
	if (rst) begin
		agc <= 0;
		cur_peak <= 0;
		upd <= 0;
		rst_peak <= 1;		
	end
	else begin
		if (zc) begin // Adjust AGC at zero switching to avoid noise
			if (peak_ovfl) agc <= {AGC_BITS{1'b1}}-10; // Min attenuation
			else begin
				cur_peak <= peak; // latch peak value for current half-period
				if      (peak < TARGET_LEVEL_BITS) agc <= (agc == '0) ? '0 : agc - 1;
				else if (peak > TARGET_LEVEL_BITS) agc <= (agc == '1) ? '1 : agc + 1;
				else agc <= agc;
			end
			upd <= 1;
			rst_peak <= 1;
		end
		else begin
			upd <= 0;
			rst_peak <= 0;
		end
	end
end

endmodule
