
//`define SIMULATION
`ifdef SIMULATION
`endif
module fixed_driver #(
  parameter longint FREQ_STEP_HZ  = 1,
  parameter longint REF_CLK_HZ    = 100000000,
  parameter longint MIN_FREQ_HZ   = 1000,
  parameter longint MAX_FREQ_HZ   = 500000,
  parameter longint DUTY_SCALE    = 100,
  parameter longint PHASE_SCALE   = 360, // Don't exceed PHASE_SCALE - 1 on phase input (E.g. don't assert more then 359 when PHASE_SCALE is 360)
  parameter longint DEADTIME_BITS = 100,
  parameter longint FREQ_BITS     = $clog2(((MAX_FREQ_HZ-MIN_FREQ_HZ)/FREQ_STEP_HZ)+1), // Calculate bits needed to encode driver's output frequency
  parameter longint DUTY_BITS     = $clog2(DUTY_SCALE+1),
  parameter longint PHASE_BITS    = $clog2(PHASE_SCALE+1) // 0.1 deg resolution
)
(
  input logic  clk,
  input logic  rst,

  // Parameters for fixed operation
  input logic [FREQ_BITS-1:0]  freq,
  input logic [DUTY_BITS-1:0]  duty,
  input logic [PHASE_BITS-1:0] phase,
  input logic [DEADTIME_BITS-1:0] deadtime,
  input logic recalc_all, 
  input logic recalc_ph_dc, 

  input logic pos,
  input logic neg,

  output logic drv0_en,
  output logic drv0,

  output logic drv1_en,
  output logic drv1
);

localparam integer PHASE_ACC_BITS = $clog2((REF_CLK_HZ/FREQ_STEP_HZ)+1);
localparam integer COMMON_BIW_W   = (PHASE_ACC_BITS >= ((DUTY_BITS >= PHASE_BITS) ? DUTY_BITS : PHASE_BITS)) ? PHASE_ACC_BITS : ((DUTY_BITS >= PHASE_BITS) ? DUTY_BITS : PHASE_BITS);

logic [PHASE_ACC_BITS-1:0] 
  phase_acc_drv0, phase_acc_drv1,
  period, cur_period,
  phase_shift, cur_phase_shift;

logic [$clog2(DUTY_SCALE*REF_CLK_HZ/FREQ_STEP_HZ+1)-1:0] on_time, cur_on_time;

logic [PHASE_ACC_BITS+DUTY_BITS-1:0]  period_duty;
logic [PHASE_ACC_BITS+PHASE_BITS-1:0] period_phase;

logic [DUTY_BITS-1:0]  duty_prev;
logic [PHASE_BITS-1:0] phase_prev;

logic  mult_cal,
  period_duty_rdy,
  phase_rdy,
  period_phase_rdy,
  on_time_rdy,
  updated,
  period_cal,
  period_rdy,
  div_cal;

enum logic [3:0] {idle_s, calc_period_s, calc_mult_s, calc_scale_s} fsm;

always_ff @ (posedge clk) begin
  if (rst) begin
	  fsm               <= idle_s;
	  mult_cal          <= 0;
	  period_cal        <= 0;
    updated <= 0;
  end
  else begin
    case (fsm)
      idle_s : begin
        updated <= 0;
        if (recalc_all) begin
          fsm <= calc_period_s;
          period_cal <= 1;
        end
        else if (recalc_ph_dc) begin
          fsm <= calc_mult_s;
          mult_cal <= 1;
        end
        else begin
          mult_cal <= 0;
          period_cal <= 0;
        end
      end
      calc_period_s : begin
        period_cal <= 0;
        if (period_rdy) begin
          fsm <= calc_mult_s;
          mult_cal <= 1;
        end
      end
      calc_mult_s : begin
        mult_cal <= 0;
        if (period_duty_rdy && period_phase_rdy) begin
          fsm <= calc_scale_s;
          div_cal <= 1;
        end
      end
      calc_scale_s : begin
          div_cal <= 0;
          if (on_time_rdy && phase_rdy) begin
            fsm <= idle_s;
            updated <= 1;
          end
      end
    endcase
  end
end


// STEP 1a:
// Compute period from reference clock frequency and target driver freqency

int_divider #(PHASE_ACC_BITS) period_calc_inst (   
  .clk (clk),
  .rst (rst),
  .cal (period_cal),
  .dvd (REF_CLK_HZ/FREQ_STEP_HZ), // divident
  .dvs ({{(PHASE_ACC_BITS-FREQ_BITS){1'b0}}, freq}), // divisor
  .quo (period),
  .rdy (period_rdy)
);

// STEP 1b:
// Compute period*phase to shift phase by a number of clock ticks

mult #(
  .W (COMMON_BIW_W)
) period_phase_mult_inst (
  .clk  (clk),
  .rst  (rst),
  .cal  (mult_cal),
  .a    ({{(COMMON_BIW_W-DUTY_BITS){1'b0}}, period}),
  .b    ({{(COMMON_BIW_W-PHASE_BITS){1'b0}}, phase}),
  .q    (period_phase),
  .rdy  (period_phase_rdy)
);

// STEP 1c:
// Compute period*duty 

mult #(
  .W (COMMON_BIW_W)
) period_duty_mult_inst (
  .clk  (clk),
  .rst  (rst),
  .cal  (mult_cal),
  .a    ({{(COMMON_BIW_W-PHASE_ACC_BITS){1'b0}}, period}),
  .b    ({{(COMMON_BIW_W-DUTY_BITS){1'b0}}, duty}),
  .q    (period_duty),
  .rdy  (period_duty_rdy)
);

// STEP 3a, 3b:
// Scale 2b and 2c results. Acquire actual values in clock ticks

int_divider #(PHASE_ACC_BITS+DUTY_BITS) on_time_calc_inst (   
  .clk (clk),
  .rst (rst),
  .cal (div_cal),
  .dvd (period_duty), // divident
  .dvs (DUTY_SCALE), // divisor
  .quo (on_time),
  .rdy (on_time_rdy)
);

int_divider #(PHASE_ACC_BITS+PHASE_BITS) phase_calc_inst (   
  .clk (clk),
  .rst (rst),
  .cal (div_cal),
  .dvd (period_phase), // divident
  .dvs (PHASE_SCALE),  // divisor
  .quo (phase_shift),
  .rdy (phase_rdy)
);

always @ (posedge clk) begin
  if (rst) begin
    cur_on_time <= 0;
    cur_phase_shift <= 0;
    cur_period <= 0;
    phase_acc_drv0 <= 0;
    phase_acc_drv1 <= 0;
    drv0 <= 0;
    drv1 <= 0;
  end
  else begin
    if (updated) begin
      cur_on_time <= on_time;
      cur_phase_shift <= phase_shift;
      cur_period <= period;
    end
    // drv0 has zero phase. reset it when phase_acc counts to current period
    phase_acc_drv0 <= (phase_acc_drv0 == cur_period) ? 0 : phase_acc_drv0 + 1;
    // drv1 is shifted by calculated number of ticks
    phase_acc_drv1 <= (phase_acc_drv0 == cur_phase_shift) ? 0 : phase_acc_drv1 + 1;
    if (phase_acc_drv0 >= cur_on_time) drv0 <= 0; else drv0 <= pos;
    if (phase_acc_drv1 >= cur_on_time) drv1 <= 0; else drv1 <= neg;
  end
end

endmodule
