`include "../../sim/timescale.v"
/* Notations:
 * zc - zero cross
 * pn - positive to negative
 * pk - peak
 * 
 */
module qcw #(
	parameter integer ADC_BITS       = 8,
	parameter real    TARGET_LEVEL   = 0.75, // target magnitude of signal with respect to ADC pk-pk voltage
	parameter real    LOCK_VARIANCE  = 0.01,  // Consider feedback locked if zero-cross variance is less
	parameter integer REF_CLK_HZ     = 100000000,
	parameter integer RAMP_PAUSE_MS  = 1,   // 10 Hz
	parameter integer RAMP_LENGTH_US = 10000, // 10 ms
	parameter integer FLAT_LENGTH_US = 2000,
	parameter real    FLAT_POWER     = 0.1,
	parameter real    MAX_POWER      = 1,
	parameter longint FREQ_STEP_HZ   = 1,
	parameter longint MIN_FREQ_HZ    = 1000,
	parameter longint MAX_FREQ_HZ    = 500000,
	parameter longint FREQ_BITS      = $clog2(((MAX_FREQ_HZ - MIN_FREQ_HZ)/FREQ_STEP_HZ)+1), // Calculate bits needed to encode driver's output frequency
	parameter longint DUTY_SCALE     = 100,
	parameter longint DUTY_BITS      = $clog2(DUTY_SCALE+1),
	parameter longint PHASE_SCALE    = 360, // Don't exceed PHASE_SCALE - 1 on phase input (E.g. don't assert more then 359 when PHASE_SCALE is 360)
	parameter longint PHASE_BITS     = $clog2(PHASE_SCALE+1), // 0.1 deg resolution
	parameter longint DEADTIME_BITS  = 100
)
(
	input  logic clk,
	input  logic rst,
	input  logic [ADC_BITS-1:0] in,   
	output logic [3:0] gate
);

// Express timing parameters in in clock ticks
localparam integer RAMP_PAUSE_TICKS  = (REF_CLK_HZ/1000)*RAMP_PAUSE_MS;
localparam integer RAMP_LENGTH_TICKS = (REF_CLK_HZ/1000000)*RAMP_LENGTH_US;
localparam integer FLAT_LENGTH_TICKS  = (REF_CLK_HZ/1000000)*FLAT_LENGTH_US;

localparam TARGET_LEVEL_VALUE = (2**ADC_BITS)*TARGET_LEVEL;

enum logic [2:0] {
	idle_s,
	flat_s,
	ramp_s
} fsm;

enum logic [2:0] {
	off,
	internal,
	feedback
} drv_mux;

logic [$clog2(RAMP_PAUSE_TICKS+1)-1:0] pause_ctr;
logic [$clog2(FLAT_LENGTH_TICKS+1)-1:0] flat_ctr;
logic [$clog2(RAMP_LENGTH_US+1)-1:0] ramp_ctr;

logic zc_np, zc_pn, ampl_ok;
logic [ADC_BITS-1:0] pk;

logic [31:0] next_period, period_ctr, cur_period;
logic driver_rst_req;
logic zc_timeout;

// Main FSM for ramp generation

always_ff @ (posedge clk) begin
	if (rst) begin
		fsm <= idle_s;
		pause_ctr <= 0;
		flat_ctr <= 0;
		ramp_ctr <= 0;
	end 
	else begin
		case (fsm)
			idle_s : begin
			pause_ctr <= pause_ctr + 1; 
				if (pause_ctr == RAMP_PAUSE_TICKS) fsm <= flat_s;
			end
			flat_s : begin
				drv_mux <= (ampl_ok) ? feedback : internal;
				flat_ctr <= flat_ctr + 1;
			end
			ramp_s : begin

			end
		endcase
	end
end

zcpk_det #(
	.BITS            (ADC_BITS),
	.ZC_IGNORE_TICKS (10),
	.MIN_ADC_LVL       (0.05)
) zcpk_det_inst (
	.clk     (clk),
	.rst     (rst),
	.in      (in),
	.zc_np   (zc_np),
	.zc_pn   (zc_pn),
	.pk      (pk),
	.ampl_ok (ampl_ok),
	.ovfl    ()
);

// calculate next cycle period
always_ff @ (posedge clk) begin
	if (rst) begin
		next_period <= 0;
	end 

	else begin
		if (zc_pn || zc_np) begin
			period_ctr <= 0;
			cur_period <= period_ctr;
		end
		else if (zc_timeout) driver_rst_req <= 1;
	end
end

fixed_driver #(
	.REF_CLK_HZ   (REF_CLK_HZ),
	.MIN_FREQ_HZ  (MIN_FREQ_HZ),
	.MAX_FREQ_HZ  (MAX_FREQ_HZ),
	.FREQ_BITS    (FREQ_BITS),
	.DUTY_SCALE   (DUTY_SCALE),
	.DUTY_BITS    (DUTY_BITS),
	.PHASE_SCALE  (PHASE_SCALE),
	.PHASE_BITS   (PHASE_BITS)
) driver_inst (
	.clk     (clk),
	.rst     (rst),

	// Parameters for fixed operation
	//.freq    (freq),
	//.duty    (duty),
	//.phase   (phase),

	.freq    (300000),
	.duty    (48),
	.phase   (180),

	.drv0_en (drv0_en),
	.drv0    (drv0),

	.drv1_en (drv1_en),
	.drv1    (drv1)
);

assign gate[0] = drv0;
assign gate[1] = drv1;
assign gate[2] = drv0;
assign gate[3] = drv1;

endmodule

// Detects zero-cross and peak value from ADC, checks if ADC signal is strong enough
module zcpk_det #(
	parameter BITS             = 8,  // ADC data bits
	parameter ZC_IGNORE_TICKS  = 10,
	parameter real MIN_ADC_LVL = 0.2
)
(
	input  logic            clk,
	input  logic            rst,
	input  logic [BITS-1:0] in,

	output logic            zc_np,
	output logic            zc_pn,
	output logic [BITS-2:0] pk,

	output logic            ampl_ok,
	output logic            ovfl
);

localparam MIN_ADC_BITS = (2**BITS)*MIN_ADC_LVL;
localparam [BITS-1:0] ZERO_VAULE = (2**(BITS-1));

logic [$clog2(ZC_IGNORE_TICKS+1)-1:0] zc_ignore_ctr;
logic [BITS-2:0] cur_peak, in_us; // 
logic [BITS-1:0] in_prev;
assign in_us = (in[BITS-1]) ? in[BITS-2:0] : ~in[BITS-2:0];

always_ff @ (posedge clk) begin
	if (rst) begin
		zc_ignore_ctr <= 0;
		cur_peak <= 0;
		ampl_ok <= 0;
	end
	else begin
		in_prev <= in;
		if (zc_np || zc_pn) begin
			cur_peak <= 0;
			pk <= cur_peak;
			if (cur_peak >= MIN_ADC_BITS) ampl_ok <= 1;
			else ampl_ok <= 0;
			zc_ignore_ctr <= ZC_IGNORE_TICKS;
		end
		else begin
			zc_ignore_ctr <= (zc_ignore_ctr == 0) ? 0 : zc_ignore_ctr - 1;
			if (cur_peak < in_us) cur_peak <= in_us;
		end
		if (in == '0 || in == '1) ovfl <= 1;
	end
end

assign zc_pn = (zc_ignore_ctr == 0) && (in <= ZERO_VAULE) && (in_prev > ZERO_VAULE);
assign zc_np = (zc_ignore_ctr == 0) && (in >= ZERO_VAULE) && (in_prev < ZERO_VAULE);

endmodule // zcpk_det
