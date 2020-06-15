module vfd #(
  parameter NCO_LUT_ADDR_BITS  = 8,  
  parameter NCO_LUT_DATA_BITS  = 8,  
  parameter NCO_PHASE_ACC_BITS = 24,
  parameter VFD_MOD_FREQ_BITS  = 8,
  parameter MOD_BITS           = 10,
  parameter REF_CLK_HZ         = 200000000,
  parameter LUT_FILENAME = "nco_lut.txt"

)
(
  input logic clk,
  input logic rst,

  input [VFD_MOD_FREQ_BITS-1:0] mod_freq,
  
  output logic [1:0] drv
);


logic signed [MOD_BITS:0] mod_tc;
logic signed [MOD_BITS-1:0] mod;



nco #(
  .LUT_ADDR_BITS  (8),  // Time precision
  .LUT_DATA_BITS  (MOD_BITS),  // Amplitude precision ( half wave )
  .PHASE_ACC_BITS (24),  // Phase accumulator size
  .LUT_FILENAME   (LUT_FILENAME)

) nco_inst (
  .clk (clk),
  .rst (rst),

  .phase_inc (10),

  .I (mod_tc),
  .Q (),
  .phase_acc () // phase accumulator stores 2 bits to determine sine quarter period number
);
 
assign pos = ~mod_tc[MOD_BITS];
assign neg = mod_tc[MOD_BITS];

assign mod = mod_tc[MOD_BITS] ? ~mod_tc[MOD_BITS-1:0] + 1 : mod_tc[MOD_BITS-1:0];

localparam UPDATE_TICKS = 1000;
logic recalc;
logic [$clog2(UPDATE_TICKS+1)-1:0] upd_ctr;

always @ (posedge clk) begin
  if (rst) begin
    upd_ctr <= 0;
    recalc <= 0;
  end
  else begin
    upd_ctr <= (upd_ctr == 0) ? UPDATE_TICKS : upd_ctr + 1;
    recalc <= (upd_ctr == 0);
  end
end

fixed_driver #(
	.REF_CLK_HZ  (REF_CLK_HZ),
	.MIN_FREQ_HZ (1),
	.MAX_FREQ_HZ (1000000),
	.DUTY_BITS   (MOD_BITS),
	.DUTY_SCALE  (2**(MOD_BITS)),
	.PHASE_SCALE (360)
) driver_inst (
	.clk     (clk),
	.rst     (rst),

	.freq    (10000),
	.duty    (mod),
	.phase   (180),
  .recalc_all (recalc),
  .recalc_ph_dc (1'b0),
	.pos     (pos),
	.neg     (neg),

	.drv0_en (drv0_en),
	.drv0    (drv0),

	.drv1_en (drv1_en),
	.drv1    (drv1)
);

endmodule