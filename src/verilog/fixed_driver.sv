
//`define SIMULATION
`ifdef SIMULATION
`endif
module fixed_driver #(
  parameter longint FREQ_STEP_HZ = 1,
  parameter longint REF_CLK_HZ   = 100000000,
  parameter longint MIN_FREQ_HZ  = 1000,
  parameter longint MAX_FREQ_HZ  = 500000,
  parameter longint FREQ_BITS    = $clog2(((MAX_FREQ_HZ - MIN_FREQ_HZ)/FREQ_STEP_HZ)+1), // Calculate bits needed to encode driver's output frequency
  parameter longint DUTY_SCALE   = 100,
  parameter longint DUTY_BITS    = $clog2(DUTY_SCALE+1),
  parameter longint PHASE_SCALE  = 360, // Don't exceed PHASE_SCALE - 1 on phase input (E.g. don't assert more then 359 when PHASE_SCALE is 360)
  parameter longint PHASE_BITS   = $clog2(PHASE_SCALE+1), // 0.1 deg resolution
  parameter longint DEADTIME_BITS = 100
)
(
  input logic  clk,
  input logic  rst,

  // Parameters for fixed operation
  input logic [FREQ_BITS-1:0]  freq,
  input logic [DUTY_BITS-1:0]  duty,
  input logic [PHASE_BITS-1:0] phase,
  input logic [DEADTIME_BITS-1:0] deadtime,
  input logic pos,
  input logic neg,

  output logic drv0_en,
  output logic drv0,

  output logic drv1_en,
  output logic drv1
);

localparam integer PHASE_ACC_BITS = $clog2((REF_CLK_HZ/FREQ_STEP_HZ)+1);

logic [PHASE_ACC_BITS-1:0] phase_acc_drv0;
logic [PHASE_ACC_BITS-1:0] phase_acc_drv1;
logic [PHASE_ACC_BITS-1:0] period, period_prev;
logic [PHASE_ACC_BITS-1:0] phase_shift;
logic [$clog2(DUTY_SCALE*REF_CLK_HZ/FREQ_STEP_HZ+1)-1:0] on_time;

logic [PHASE_ACC_BITS+DUTY_BITS-1:0]  period_duty, period_duty_calc;
logic [PHASE_ACC_BITS+PHASE_BITS-1:0] period_phase, period_phase_calc;

logic [DUTY_BITS-1:0]  duty_prev;
logic [PHASE_BITS-1:0] phase_prev;
logic [DUTY_BITS-1:0]  duty_calc_ctr;
logic [PHASE_BITS-1:0] phase_calc_ctr;
logic calc_pend;

enum logic [2:0] {idle_s, calc_s, upd_s} calc_fsm;

always @ (posedge clk) begin
  if (rst) begin
	  calc_fsm          <= idle_s;
    calc_pend         <= 0;
	  period_prev       <= 0;
    duty_prev         <= 0;
    phase_prev        <= 0;
	  duty_calc_ctr     <= 0;
    phase_calc_ctr    <= 0;
	  period_phase_calc <= 0;
	  period_duty_calc  <= 0;
  end
  case (calc_fsm)
    idle_s : begin
      if (!calc_pend) begin
        period_prev <= period;
        duty_prev   <= duty;
        phase_prev  <= phase;
      end
      if (period != period_prev || duty != duty_prev || phase != phase_prev) calc_pend <= 1;
      if (calc_pend && phase_acc_drv0 == 0) begin
        duty_calc_ctr <= duty;
        phase_calc_ctr <= phase;
        period_duty_calc <= 0;
        period_phase_calc <= 0;
        calc_fsm <= calc_s;
      end
    end
    calc_s : begin
      calc_pend <= 0;
      if (duty_calc_ctr != 0) begin
        period_duty_calc <= period_duty_calc + period; 
        duty_calc_ctr <= duty_calc_ctr - 1;
      end
      if (phase_calc_ctr != 0) begin
        period_phase_calc <= period_phase_calc + period; 
        phase_calc_ctr <= phase_calc_ctr - 1;
      end
      if (duty_calc_ctr == 0 && phase_calc_ctr == 0) begin
        period_duty <= period_duty_calc;
        period_phase <= period_phase_calc;
        calc_fsm <= idle_s;
      end
    end
	  upd_s : begin
      
    end
  endcase
end

int_divider #(PHASE_ACC_BITS) period_calc_inst (   
  .clk (clk),
  .rst (rst),
  .dvd (REF_CLK_HZ/FREQ_STEP_HZ), // divident
  .dvs ({{(PHASE_ACC_BITS-FREQ_BITS){1'b0}}, freq}), // divisor
  .quo (period),
  .rdy (period_rdy)
);

int_divider #(PHASE_ACC_BITS+DUTY_BITS) on_time_calc_inst (   
  .clk (clk),
  .rst (rst),
  .dvd (period_duty), // divident
  .dvs (DUTY_SCALE), // divisor
  .quo (on_time),
  .rdy (on_time_rdy)
);

int_divider #(PHASE_ACC_BITS+PHASE_BITS) phase_calc_inst (   
  .clk (clk),
  .rst (rst),
  .dvd (period_phase), // divident
  .dvs (PHASE_SCALE), // divisor
  .quo (phase_shift),
  .rdy (phase_rdy)
);

logic all_rdy;
assign all_rdy = period_rdy && on_time_rdy && phase_rdy;

always @ (posedge clk) begin
  if (rst || !all_rdy) begin
    phase_acc_drv0 <= 0;
    phase_acc_drv1 <= 0;
  end
  else begin
    // drv0 has zero phase. reset it when phase_acc counts to current period
    phase_acc_drv0 <= (phase_acc_drv0 == period) ? 0 : phase_acc_drv0 + 1;
    // drv1 is shifted by calculated number of ticks
    phase_acc_drv1 <= (phase_acc_drv0 == phase_shift) ? 0 : phase_acc_drv1 + 1;
  end
end

logic drv0_reg;
logic drv1_reg;

always @ (posedge clk) begin
  if (rst || !all_rdy) begin
    drv0_reg <= 0;
    drv1_reg <= 0;
  end
  else begin
    if (phase_acc_drv0 == 0) drv0_reg <= pos;
    if (phase_acc_drv1 == 0) drv1_reg <= neg;
    if (phase_acc_drv0 == on_time) drv0_reg <= 0;
    if (phase_acc_drv1 == on_time) drv1_reg <= 0;
  end
end

assign drv0 = drv0_reg && all_rdy;
assign drv1 = drv1_reg && all_rdy;

endmodule
