module p10_ctrl #(
  parameter PARAMETER_COUNT = 3,
  parameter DEFAULT_DRIVER_FREQ_HZ = 50000,
  parameter DEFAULT_DUTY_PERCENT   = 33,
  parameter DEFAULT_PHASE_DEGREE   = 180 
)(
  input logic clk,
  input logic rst,
  input logic connected,
  ram_if_sp.sys ram,
  output settings_t settings,
  exec.in exec_if,
  rhd_cmd_if.out commands
);

typedef struct packed {
  freq_t freq;
  
} settings_t;

`include "../../src/verilog/p10_reg_defines.sv"

logic ram_r_nw;
logic ram_v_i, ram_v_o;
logic [7:0]  ram_a_i, ram_a_o;
logic [31:0] ram_d_i, ram_d_o;

// ram_if_sp #(.AW (AW), .DW (DW)) ram

mem_arb # (
  .AW (8),
  .DW (32),
  .N  (1),
  .DC (0),
  .D  (4)) 
mem_arb_inst (
  .ram_clk (clk),
  .ram_rst (rst),

  .in_clk (clk),
  .in_rst (rst),

  .r_nw (ram_r_nw),
  .v_i  (ram_v_i),
  .a_i  (ram_a_i),
  .d_i  (ram_d_i),

  .v_o (ram_v_o),
  .a_o (ram_a_o), 
  .d_o (ram_d_o), 

  .ram (ram)
);

enum logic {upd_idle_s, upd_seq_s} upd_fsm;

logic [$clog2(PARAMETER_COUNT+2)-1:0] upd_seq;
parameter P10_RAM_UPD_TICKS = 1000;

logic [$clog2(P10_RAM_UPD_TICKS+1)-1:0] p10_ram_upd_ctr;
logic [7:0] upd_ctr;

logic [15:0] ctr;

assign ram_r_nw = connected;

always @ (posedge clk) begin
  if (rst) begin
    upd_fsm <= upd_idle_s;
    upd_seq <= 0;
    upd_ctr <= 0;
   // ram_r_nw <= 0;
  end
  else begin
    case (upd_fsm)
      upd_idle_s : begin
        p10_ram_upd_ctr <= p10_ram_upd_ctr + 1;
        if (p10_ram_upd_ctr == P10_RAM_UPD_TICKS) upd_fsm <= upd_seq_s;
        upd_seq <= 0;
      end
      upd_seq_s : begin
        p10_ram_upd_ctr <= 0;
        upd_seq <= upd_seq + 1;
        if (upd_seq == PARAMETER_COUNT + 1) begin
          upd_ctr <= upd_ctr + 1;
          upd_fsm <= upd_idle_s;
          ram_v_i <= 0;
        end
        else ram_v_i <= 1;
        case (upd_seq)
          // Read current values to pass them to rhd
          // Write these values only once. Initialize RAM with defaults
          0 : begin ram_a_i <= ADDR_FREQ_HZ     ;  ram_d_i <= DEFAULT_DRIVER_FREQ_HZ;  end
          1 : begin ram_a_i <= ADDR_DUTY_PERCENT;  ram_d_i <= DEFAULT_DUTY_PERCENT  ;  end
          2 : begin ram_a_i <= ADDR_PHASE_DEGREE;  ram_d_i <= DEFAULT_PHASE_DEGREE  ;  end
          default : begin ram_a_i <= '1; ram_d_i <= 0; end
        endcase
      end
    endcase
  end
end

assign settings.ch_count = 16;

always @ (posedge clk) begin
  if (ram_v_o) begin
    case (ram_a_o)
      ADDR_DRIVER_FREQ_HZ  : settings.samplerate_hz <= ram_d_o;
      ADDR_DUTY_PERCENT    : settings.low_bw_milhz  <= ram_d_o;
      ADDR_PHASE_DEGREE    : settings.high_bw_hz    <= ram_d_o;
    endcase
  end
end

// p10 executables -> rhd commands
always @ (posedge clk) begin
  if (exec_if.val) begin
    case (exec_if.addr)
      ADDR_APPLY             : begin commands.apply <= 1; exec_if.ok <= commands.apply_ok; exec_if.err <= commands.apply_err; end
      ADDR_STREAM_ON         : begin commands.start <= 1; exec_if.ok <= commands.start_ok; exec_if.err <= commands.start_err; end
      ADDR_STREAM_OFF        : begin commands.stop  <= 1; exec_if.ok <= commands.stop_ok;  exec_if.err <= commands.stop_err;  end   
    // ADDR_ENABLE_HPF        :        
    // ADDR_DISABLE_HPF       :       
    // ADDR_ENABLE_LPF        :        
    // ADDR_DISABLE_LPF       :       
    // ADDR_CALIBRATE         :         
    // ADDR_MEASURE_IMPEDANCE : 
      default : exec_if.err <= 1'b1;
    endcase 
  end
  else begin
    commands.apply <= 0;
    commands.start <= 0;
    commands.stop <= 0; 
    exec_if.ok <= 0;
    exec_if.err <= 0;
  end
end

endmodule