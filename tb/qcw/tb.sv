`include "../../sim/timescale.v"

module tb ();
localparam real U_VOLT     = 5;
localparam real L_HENRY    = 0.000014;
localparam real C_FARAD    = 0.00000002; // 20n
localparam real R_LOAD_OHM = 0.1;
localparam real R_CT_OHM   = 1;

localparam integer ADC_BITS = 8;

// Clocking
logic clk = 1;
logic rst = 1;
always #5 clk <= !clk;
initial #1000 rst <= 0;
logic [1:0] gate;
real u, u_load, u_r, u_c, u_l, i, u_ct;
logic [ADC_BITS-1:0] adc_code;
logic ovfl_pos, ovfl_neg;
assign u = U_VOLT;

qcw #(
	.ADC_BITS      (8        ),
	.TARGET_LEVEL  (0.75     ), // target magnitude of signal with respect to ADC pk-pk voltage
	.LOCK_VARIANCE (0.01     ),  // Consider feedback locked if zero-cross variance is less
	.REF_CLK_HZ    (100000000)
) qcw_inst
(
	.clk       (clk), 
	.rst       (rst), 
	.in        (adc_code),
	.gate      (gate)
);

adc_sim #(
	.BITS (8),
	.VPP  (10),
	.PIPE (5),
	.TYPE ("unsigned")
) adc_sim_inst (
	.clk      (clk),
	.in       (u_ct),
	.code     (adc_code),
	.ovfl_pos (ovfl_pos),
	.ovfl_neg (ovfl_neg)
);

halfbridge_sim halfbridge_sim_inst (
    .gate  (gate),
    .u_in  (u),
    .u_out (u_load)
);

rlc_sim #(
    .dt (0.000000001), // 1ns
    .L  (L_HENRY),
    .C  (C_FARAD),
    .R  (R_LOAD_OHM)
) rlc_sim (
    .u     (u_load),

    .u_r   (u_r),
    .u_c   (u_c),
    .u_l   (u_l),

    .i     (i),
    .u_err ()
);

assign u_ct = R_CT_OHM * i;


endmodule
