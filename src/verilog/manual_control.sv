/*
module manual_control #(
	parameter FREQ_STEP_HZ = `DEFAULT_FREQ_STEP_HZ, // REF_CLK_HZ%FREQ_STEP_HZ should be zero
	parameter REF_CLK_HZ   = `DEFAULT_REF_CLK_HZ,
	parameter MIN_FREQ_HZ  = `DEFAULT_MIN_FREQ_HZ,
	parameter MAX_FREQ_HZ  = `DEFAULT_MAX_FREQ_HZ,
	parameter FREQ_SCALE   = ((MAX_FREQ_HZ - MIN_FREQ_HZ)/FREQ_STEP_HZ),
	parameter FREQ_BITS    = $clog2(((MAX_FREQ_HZ - MIN_FREQ_HZ)/FREQ_STEP_HZ)+1), // Calculate bits needed to encode driver's output frequency
	parameter DUTY_SCALE   = `DEFAULT_DUTY_SCALE,
	parameter DUTY_BITS    = $clog2(DUTY_SCALE+1),
	parameter PHASE_SCALE  = `DEFAULT_PHASE_SCALE, // Don't exceed PHASE_SCALE - 1 on phase input (E.g. don't assert more then 359 when PHASE_SCALE is 360)
	parameter PHASE_BITS   = $clog2(PHASE_SCALE+1) // 0.1 deg resolution
)
(
    input logic  clk,
	input logic  rst,

	input logic mode_enc_a,
	input logic mode_enc_b,
	input logic mode_enc_button,

	input logic select_enc_a,
	input logic select_enc_b,
	input logic select_enc_button,

	input logic value_enc_a,
	input logic value_enc_b,
	input logic value_enc_button,
	//	output logic [FREQ_BITS-1:0]  freq,

	output logic [1:0]  freq,
	output logic [DUTY_BITS-1:0]  duty,
	output logic [PHASE_BITS-1:0] phase
);

logic mode_incr;
logic mode_decr;
logic apply_mode;

logic select_incr;
logic select_decr;
logic insert_value;

logic value_incr;
logic value_decr;
logic set_default_value;

encoder #(
	.ENCODER_DEBOUNCE_TICKS (`ENCODER_DEBOUNCE_TICKS),
	.BUTTON_DEBOUNCE_TICKS  (`BUTTON_DEBOUNCE_TICKS)
)
mode_encoder_inst (
	.clk (clk),
	.rst (rst),
	// Inputs
	.a   (mode_enc_a),
	.b   (mode_enc_b),
	.btn (mode_enc_button),
	// Outputs
	.cw  (mode_incr),
	.ccw (mode_decr),
	.prs (apply_mode)
);

encoder #(
	.ENCODER_DEBOUNCE_TICKS (`ENCODER_DEBOUNCE_TICKS),
	.BUTTON_DEBOUNCE_TICKS  (`BUTTON_DEBOUNCE_TICKS))
sel_encoder_inst (
	.clk (clk),
	.rst (rst),
	// Inputs
	.a   (select_enc_a),
	.b   (select_enc_b),
	.btn (select_enc_button),
	// Outputs
	.cw  (select_incr),
	.ccw (select_decr),
	.prs (insert_value)
);

encoder #(
	.ENCODER_DEBOUNCE_TICKS (`ENCODER_DEBOUNCE_TICKS),
	.BUTTON_DEBOUNCE_TICKS  (`BUTTON_DEBOUNCE_TICKS))
value_encoder_inst (
	.clk (clk),
	.rst (rst),
	// Inputs
	.a   (value_enc_a),
	.b   (value_enc_b),
	.btn (value_enc_button),
	// Outputs
	.cw  (value_incr),
	.ccw (value_decr),
	.prs (set_default_value)
);

typedef enum logic {
	ON,
	OFF
} mode_t;

typedef enum logic [2:0] {
	value_freq,
	value_duty,
	value_phase
} item_t;

item_t item_selected;

always @ (posedge clk) begin
	if (rst) begin
		freq <= 0;
		duty <= `DEFAULT_DUTY;
		phase <= `DEFAULT_PHASE;
		item_selected <= value_freq;
		//cur_val_selected <= VAL_FREQ;
		//cur_mode         <= ON;
	end
	else begin
		if (value_incr) begin // If rotation from "value" encoder detectded
			case (item_selected) // Based on currently selected item
				value_freq  : freq  <= (freq  == FREQ_SCALE)  ? FREQ_SCALE  : freq  + 1;
				value_duty  : duty  <= (duty  == DUTY_SCALE)  ? DUTY_SCALE  : duty  + 1;
				value_phase : phase <= (phase == PHASE_SCALE) ? PHASE_SCALE : phase + 1;
			endcase
		end
		if (value_decr) begin // If rotation from "value" encoder detectded
			case (item_selected) // Based on currently selected item
				value_freq  : freq  <= (freq  == 0) ? 0 : freq - 1; 
				value_duty  : duty  <= (duty  == 0) ? 0 : duty - 1;
				value_phase : phase <= (phase == 0) ? 0 : phase - 1;
			endcase
		end
	end
end

endmodule
*/