interface cmd_if ();
  logic on;
  logic on_ok;
  logic on_err;

  logic off;
  logic off_ok;
  logic off_err;

  logic apply;
  logic apply_ok;
  logic apply_err;

  modport in        (input on, off, apply, output on_ok, off_ok, apply_ok, on_err, off_err, apply_err);
  modport out       (output on, off, apply, input on_ok, off_ok, apply_ok, on_err, off_err, apply_err);
  modport on_in     (input on, output on_ok, on_err);
  modport on_out    (output on, input on_ok, on_err);
  modport off_in    (input off, output off_ok, off_err);
  modport off_out   (output off, input off_ok, off_err);
  modport apply_in  (input apply, output apply_ok, apply_err);
  modport apply_out (output apply, input apply_ok, apply_err);
endinterface

package drv_pkg;
  parameter MAX_FREQ   = 200000;
  parameter MAX_DUTY   = 50;
  parameter DUTY_SCALE = 100;
  parameter MAX_PHASE  = 359;
  parameter FREQ_BITS  = $clog2(MAX_FREQ+1);
  parameter DUTY_BITS  = $clog2(DUTY_SCALE+1);
  parameter PHASE_BITS = $clog2(MAX_PHASE+1);
typedef struct packed {
  bit [FREQ_BITS-1:0]  freq;
  bit [DUTY_BITS-1:0]  duty;
  bit [PHASE_BITS-1:0] phase;
} settings_t;

endpackage

import drv_pkg::*;

module p10_ctrl #(
  parameter PARAMETER_COUNT = 3,
  parameter DEFAULT_DRIVER_FREQ_HZ = 50000,
  parameter DEFAULT_DUTY_PERCENT   = 33,
  parameter DEFAULT_PHASE_DEGREE   = 180,
  parameter MAX_FREQ_HZ  = 200000,
  parameter MAX_DUTY_HZ  = 50,
  parameter MAX_PHASE_HZ = 359,
  parameter FREQ_BITS  = $clog2(MAX_FREQ_HZ +1),
  parameter DUTY_BITS  = $clog2(MAX_DUTY_HZ +1),
  parameter PHASE_BITS = $clog2(MAX_PHASE_HZ+1)
)(
  input logic clk,
  input logic rst,
  input logic connected,
  ram_if_sp.sys ram,
  output settings_t settings,
  exec.in exec_if,
  cmd_if.out cmd
);


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

always @ (posedge clk) begin
  if (ram_v_o) begin
    case (ram_a_o)
      ADDR_FREQ_HZ      : settings.freq  <= ram_d_o;
      ADDR_DUTY_PERCENT : settings.duty  <= ram_d_o;
      ADDR_PHASE_DEGREE : settings.phase <= ram_d_o;
    endcase
  end
end

// p10 executables -> cmd
always @ (posedge clk) begin
  if (exec_if.val) begin
    case (exec_if.addr)
      ADDR_APPLY   : begin cmd.apply <= 1; exec_if.ok <= cmd.apply_ok; exec_if.err <= cmd.apply_err; end
      ADDR_ENABLE  : begin cmd.on    <= 1; exec_if.ok <= cmd.on_ok;    exec_if.err <= cmd.on_err;    end
      ADDR_DISABLE : begin cmd.off   <= 1; exec_if.ok <= cmd.off_ok;   exec_if.err <= cmd.off_err;   end   
      default : exec_if.err <= 1'b1;
    endcase 
  end
  else begin
    cmd.apply <= 0;
    cmd.on <= 0;
    cmd.off <= 0; 
    exec_if.ok <= 0;
    exec_if.err <= 0;
  end
end

endmodule