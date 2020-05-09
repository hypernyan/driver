// An ASCII-based decimal protocol for interfacing FPGAs from various command lines over COM port, UDP, TCP, etc.
// p10 supports multimple "commands":
// - "help" lists a help string
// - "list" lists commands
// - "set" sets a "parameter" to a val
// - "read" reads out a "parameter"
// - "mon" monitors a "parameter"

// Common package for p10. Normally shouldn't be modified
`define VERSION "p10: 1.1; drv: 0.1; 03.15.2020"
package p10_pkg_common;
  // define maximum lengths of fields
  localparam int CMD_LEN = 8;
  localparam int PRM_LEN = 8;
  localparam int DAT_LEN = 8;
  localparam int DAT_LEN_BITS = $clog2(10**DAT_LEN);
  localparam int UNITS_LEN = 4;
  localparam int PRM_COUNT = 6;

  // ASCII definitions
  localparam byte START_RX = "`"; // start symbol
  localparam byte START_TX = ">"; // start symbol
  localparam byte CMD_DLM  = "-"; // command delimiter
  localparam byte PRM_DLM  = ":"; // parameter delimiter
  localparam byte DAT_DLM  = ";"; // data delimiter
  localparam byte K_MOD  = "k"; // x1000 modfier
  localparam byte DOT    = "."; // dot symbol

  typedef enum byte {
    type_decimal,
    type_fixed,
    type_string,
    type_nodata
  } cmd_data_type_t;

  typedef logic [CMD_LEN-1:0][7:0] cmd_t;
  typedef logic [PRM_LEN-1:0][7:0] prm_t;

  typedef struct packed {
    cmd_t cmd;
    byte  cmd_len;
    prm_t prm;
    byte  prm_len;
    logic [DAT_LEN-1:0][3:0] dat_bcd;
    logic [DAT_LEN-1:0][7:0] dat_str;
  } op_t;

  // Errors
  
  typedef enum logic [9:0] {
    none      = 10'b0000000001,
    rx_cmd_bad    = 10'b0000000010,
    rx_data_bad   = 10'b0000000100,
    rx_prm_bad    = 10'b0000001000,
    rx_data_not_int = 10'b0000010000,
    prm_read_only   = 10'b0000100000,
    prm_not_found   = 10'b0001000000,
    prm_low     = 10'b0010000000,
    prm_high    = 10'b0100000000,
    rx_timeout    = 10'b1000000000
  } err_t;

  typedef enum logic [4:0] {
    rx_ok    = 5'b00001,
    cmd_bad    = 5'b00010,
    data_bad   = 5'b00100, 
    prm_bad    = 5'b01000,
    data_not_int = 5'b10000
  } err_rx_t;

  typedef enum logic [4:0] {
     prm_ok  = 5'b00001,
     not_found = 5'b00010,
     read_only = 5'b00100, 
     low     = 5'b01000,
     high    = 5'b10000
  } err_prm_t;

  // FSMs

  typedef enum logic [8:0] {
    rx_idle_s,
    rx_wait_start_s,
    rx_cmd_s,
    rx_prm_s,
    rx_dat_s,
    rx_err_s,
    rx_wait_rst_s
  } fsm_rx_t;

  typedef enum logic [3:0] {
    bcd_idle_s,
    bcd_shift_s,
    bcd_conv_s,
    bcd_wait_rst_s
  } fsm_bcd_t;

  typedef enum logic [8:0] {
    tx_idle_s,
    tx_cmd_s,
    tx_prm_s,
    tx_prm_dlm_s,
    tx_dat_s,
    tx_stop_s,
    tx_string_s,
    tx_units_s,
    tx_cr_s,
    tx_lf_s,
    tx_wait_rst_s
  } fsm_tx_t;

  typedef enum logic [5:0] {
    prm_idle_s,
    prm_scan_s,
    prm_check_s,
    prm_write_s,
    prm_conv_s,
    prm_read_s,
    prm_wait_rst_s
  } prm_fsm_t;

  typedef enum logic {
    r,
    rw
  } rights_t;

  typedef struct packed {
    prm_t            prm;
    logic [DAT_LEN_BITS-1:0]   min;
    logic [DAT_LEN_BITS-1:0]   max;
    logic [UNITS_LEN-1:0][7:0] units;
    rights_t           rights;
  } prm_entry_t;

  function [3:0] ascii2bcd;
    input [7:0] in;
    case (in)
      "0" : ascii2bcd = 0;
      "1" : ascii2bcd = 1;
      "2" : ascii2bcd = 2;
      "3" : ascii2bcd = 3;
      "4" : ascii2bcd = 4;
      "5" : ascii2bcd = 5;
      "6" : ascii2bcd = 6;
      "7" : ascii2bcd = 7;
      "8" : ascii2bcd = 8;
      "9" : ascii2bcd = 9;
      ".", "k", DAT_DLM : ascii2bcd = 11; // exclude to avoid error
      default : ascii2bcd = 4'hf;
    endcase  
  endfunction : ascii2bcd

  function [7:0] bcd2ascii;
    input [3:0] in;
    case (in)
      0 : bcd2ascii = 8'h30;
      1 : bcd2ascii = 8'h31;
      2 : bcd2ascii = 8'h32;
      3 : bcd2ascii = 8'h33;
      4 : bcd2ascii = 8'h34;
      5 : bcd2ascii = 8'h35;
      6 : bcd2ascii = 8'h36;
      7 : bcd2ascii = 8'h37;
      8 : bcd2ascii = 8'h38;
      9 : bcd2ascii = 8'h39;
    endcase  
  endfunction : bcd2ascii

endpackage

import p10_pkg_common::*;

interface cmd;
  logic v;
  logic on;
  logic off;
  prm_t prm;
   // val_t val;
  logic ok;
  logic err;
  err_t err_type;
  //  modport out (output v, on, off, prm, val, input ok, err, err_type);
  //  modport in  (input v, on, off, prm, val, output ok, err, err_type);
endinterface

module p10 (
  input  logic clk,
  input  logic rst,

  input  logic [7:0] rxd,
  input  logic     rxv,

  output logic [7:0] txd,
  output logic     txv,
  input  logic     cts,

  input  logic [$clog2(PRM_COUNT+1)-1:0] prm_addr,
  input  logic [DAT_LEN_BITS-1:0]    prm_ram_d,
  output logic [DAT_LEN_BITS-1:0]    prm_ram_q,
  input  logic               prm_ram_w
);

`include "driver_reg_map.sv"

parameter integer BIN_W = $clog2(10**DAT_LEN);
parameter integer TIMEOUT_TICKS = 50000000;
parameter integer INPUT_FIFO_DEPTH = 5;
parameter integer OUTPUT_FIFO_DEPTH = 5;

// Command definitions
cmd_t set   = "set";   // Set val for a parameter. ex: "set.freq:10.25k;"
cmd_t get   = "get";   // Get current val of a parameter. ex: "get.freq;"
cmd_t mon   = "mon";   // Monitor a parameter. ex: "mon.current;"
cmd_t start = "start"; // start operation
cmd_t stop  = "stop";  // stop operation
cmd_t save  = "save";
cmd_t ver   = "ver";
// Parameter definitions
prm_t freq    = "freq";
prm_t duty    = "duty";
prm_t mode    = "mode";
prm_t ocd     = "ocd";
prm_t ocd_div = "ocd_div";
prm_t current = "current";

prm_entry_t prm_rom [0:PRM_COUNT-1];
logic [DAT_LEN_BITS-1:0] prm_ram [0:PRM_COUNT-1];

initial begin
  prm_rom[ADDR_FREQ].prm    = "freq";
  prm_rom[ADDR_FREQ].min    = 100;
  prm_rom[ADDR_FREQ].max    = 500000;
  prm_rom[ADDR_FREQ].units  = "Hz";
  prm_rom[ADDR_FREQ].rights = rw;
  prm_ram[ADDR_FREQ]        = 10000;
  
  prm_rom[ADDR_DUTY].prm    = "duty";
  prm_rom[ADDR_DUTY].min    = 0;
  prm_rom[ADDR_DUTY].max    = 50;
  prm_rom[ADDR_DUTY].units  = "%";
  prm_rom[ADDR_DUTY].rights = rw;
  prm_ram[ADDR_DUTY]        = 33;
  
  prm_rom[ADDR_PHASE].prm    = "phase";
  prm_rom[ADDR_PHASE].min    = 0;
  prm_rom[ADDR_PHASE].max    = 359;
  prm_rom[ADDR_PHASE].units  = "deg";
  prm_rom[ADDR_PHASE].rights = rw;
  prm_ram[ADDR_PHASE]        = 180;

  prm_rom[ADDR_OCD].prm    = "ocd";
  prm_rom[ADDR_OCD].min    = 1;
  prm_rom[ADDR_OCD].max    = 1000;
  prm_rom[ADDR_OCD].units  = "A";
  prm_rom[ADDR_OCD].rights = rw;
  prm_ram[ADDR_OCD]        = 100;

  prm_rom[ADDR_DEADTIME].prm    = "deadtim";
  prm_rom[ADDR_DEADTIME].min    = 2;
  prm_rom[ADDR_DEADTIME].max    = 1000;
  prm_rom[ADDR_DEADTIME].units  = "ns";
  prm_rom[ADDR_DEADTIME].rights = rw;
  prm_ram[ADDR_DEADTIME]        = 2;

  prm_rom[ADDR_CURRENT].prm    = "current";
  prm_rom[ADDR_CURRENT].min    = 0;
  prm_rom[ADDR_CURRENT].max    = 100;
  prm_rom[ADDR_CURRENT].units  = "A";
  prm_rom[ADDR_CURRENT].rights = r;
  prm_ram[ADDR_CURRENT]        = 0;
end

fsm_rx_t fsm_rx;
fsm_tx_t fsm_tx;
fsm_bcd_t fsm_bcd;

logic fsm_rst;
err_t err;
op_t cur_rx, cur_tx;

logic dot_pres; 
logic k_mod_pres;
logic bcd2bin_rdy;
logic check_prm;

logic [$clog2(CMD_LEN+1)-1:0] cmd_ctr_rx, cmd_ctr_tx;
logic [$clog2(PRM_LEN+1)-1:0] prm_ctr_rx, prm_ctr_tx;
logic [$clog2(DAT_LEN+1)-1:0] dat_ctr_rx, dat_ctr_tx, dot_pos;

logic [2:0] shift;
logic [BIN_W-1:0] cur_rx_bin, cur_tx_bin;
logic [DAT_LEN-1:0][3:0] tx_bcd, cur_tx_bcd, rx_bcd, rx_bcd_shifted = 0;
logic conv_bcd2bin, conv_bin2bcd;

// input buffer
fifo_sc_if #(INPUT_FIFO_DEPTH, 8) rx_buf(.*);
fifo_sc #(INPUT_FIFO_DEPTH, 8) rx_buf_inst (.fifo (rx_buf));

assign rx_buf.rst = rst;
assign rx_buf.clk = clk;

assign rx_buf.write = rxv;
assign rx_buf.data_in = rxd;

// output buffer
fifo_sc_if #(OUTPUT_FIFO_DEPTH, 8) tx_buf(.*);
fifo_sc #(OUTPUT_FIFO_DEPTH, 8) tx_buf_inst (.fifo (tx_buf));

assign tx_buf.rst = rst;
assign tx_buf.clk = clk;

// parameter ram

logic [$clog2(PRM_COUNT+2)-1:0] prm_rom_addr_int, prm_ram_scan_addr;

prm_entry_t prm_rom_q;
logic prm_ram_w_int;
logic [DAT_LEN_BITS-1:0] prm_ram_q_int, prm_ram_d_int;
logic [$clog2(PRM_COUNT+1)-1:0] prm_addr_int, prm_addr_prev;

// timeout

logic rsp_err, rsp_ok, timeout;

logic conv_bcd, rx_buf_valid_out;
logic scan_prm, stop_read;

err_prm_t err_prm;
prm_fsm_t prm_fsm;

logic rx_fsm_rdy, rx_fifo_req, rx_buf_q_v, tx_done;

err_rx_t err_rx;

logic [$clog2(TIMEOUT_TICKS+1)-1:0] to_ctr;
always @ (posedge clk) begin
  if (fsm_rst) begin
    to_ctr <= 0;
    timeout <= 0;
  end
  else begin
    to_ctr <= (fsm_rx == rx_idle_s) ? 0 : to_ctr + 1;
    if (to_ctr == TIMEOUT_TICKS) timeout <= 1;    
  end
end

// ram/rom logic

always @ (posedge clk) begin
  prm_rom_q <= prm_rom[prm_addr_int]; // transmit only ram contents
end

// internal port
always @ (posedge clk) begin
  if (prm_ram_w_int) prm_ram[prm_addr_int] <= cur_rx_bin; // can write only cur_rx_bcd
  else cur_tx_bin <= prm_ram[prm_addr_int]; // transmit only ram contents

end

// external port
always @ (posedge clk) begin
  if (prm_ram_w)   prm_ram[prm_addr] <= prm_ram_d;
  else prm_ram_q <=  prm_ram[prm_addr];
end

always @ (posedge clk) begin
  if (rst) begin
    fsm_rst <= 1;
  end
  else begin
    fsm_rst <= tx_done;
    rx_buf.read <= rx_fsm_rdy && !rx_buf.empty;
    rx_buf_q_v <= rx_buf.read;
  end
end

assign rx_fsm_rdy = (fsm_rx != rx_wait_rst_s);
logic rsp_ver;
always @ (posedge clk) begin
  if (fsm_rst) begin
    fsm_rx     <= rx_idle_s;
    cmd_ctr_rx <= 0;
    prm_ctr_rx <= 0;
    dat_ctr_rx <= 0;
    cur_rx     <= 0;
    dot_pos    <= 0;
    dot_pres   <= 0;
    k_mod_pres <= 0;
    conv_bcd   <= 0;
    scan_prm   <= 0;
    stop_read  <= 0;
    err_rx     <= rx_ok;
	  rsp_ver    <= 0;
  end
  else if (rx_buf.valid_out) begin
    case (fsm_rx)
      rx_idle_s : begin
        if (rx_buf.data_out == START_RX) fsm_rx <= rx_cmd_s;
      end
      rx_cmd_s : begin
        if (cmd_ctr_rx == CMD_LEN) begin
          err_rx <= cmd_bad;
          $display("cmd too long");
        end
        if (rx_buf.data_out == CMD_DLM) begin // "-"
          $display("-> cmd: %s", cur_rx.cmd);
          cur_rx.cmd_len = cmd_ctr_rx; // latch cmd len for correct response
          case (cur_rx.cmd)
            set, get, mon : begin
              fsm_rx <= rx_prm_s;
            end
            start : begin

            end
            stop : begin

            end
            // load, save  : begin
            //   fsm_rx <= done_s;
            // end
            endcase
          end
        else if (rx_buf.data_out == DAT_DLM) begin
		    if (cur_rx.cmd == ver) begin
            rsp_ver <= 1;
			   fsm_rx <= rx_wait_rst_s;	  
          end
		  end
		  else begin
          cmd_ctr_rx <= cmd_ctr_rx + 1;
          cur_rx.cmd[CMD_LEN-1:1] <= cur_rx.cmd[CMD_LEN-2:0];
          cur_rx.cmd[0] <= rx_buf.data_out;
        end
      end
      rx_prm_s : begin
        if (prm_ctr_rx == PRM_LEN) begin
          err_rx <= prm_bad;
          $display("prm too long");
        end 
        if (rx_buf.data_out == PRM_DLM && cur_rx.cmd == set) begin
          cur_rx.prm_len = prm_ctr_rx;
          $display("-> prm: %s", cur_rx.prm);
          fsm_rx <= rx_dat_s;
        end
        else if (rx_buf.data_out == DAT_DLM && cur_rx.cmd == get) begin
          cur_rx.prm_len = prm_ctr_rx;
          $display("-> prm: %s", cur_rx.prm);
          fsm_rx <= rx_wait_rst_s;
          scan_prm <= 1;
        end
        else begin
          prm_ctr_rx <= prm_ctr_rx + 1;
          cur_rx.prm[PRM_LEN-1:1] <= cur_rx.prm[PRM_LEN-2:0];
          cur_rx.prm[0] <= rx_buf.data_out;
        end
      end
      rx_dat_s : begin
        if (dat_ctr_rx == DAT_LEN || 
          dot_pos == 5 || 
          ascii2bcd(rx_buf.data_out) == 4'hf || 
          (rx_buf.data_out != DAT_DLM && k_mod_pres) || 
          (rx_buf.data_out == DAT_DLM && !k_mod_pres && dot_pres)
        ) begin
          err_rx <= data_bad;
          $display("data too long");
        end
        if (rx_buf.data_out == K_MOD) k_mod_pres <= 1;
        if (rx_buf.data_out == DOT) dot_pres <= 1;
        if (rx_buf.data_out == DAT_DLM) begin
          $display("-> dat: %h", cur_rx.dat_bcd);
          conv_bcd <= 1;
          fsm_rx <= rx_wait_rst_s;
        end
        else begin
          dat_ctr_rx <= dat_ctr_rx + 1;
          if (rx_buf.data_out != "." && rx_buf.data_out != "k") begin
            cur_rx.dat_bcd[DAT_LEN-1:1] <= cur_rx.dat_bcd[DAT_LEN-2:0];
            cur_rx.dat_bcd[0] <= ascii2bcd(rx_buf.data_out);
            if (dot_pres) dot_pos <= dot_pos + 1;
          end
        end
      end
      rx_wait_rst_s : begin
      end
    endcase
  end
end
/*
 * Shift data 
 */
always @ (posedge clk) begin
  if (fsm_rst) begin
    fsm_bcd <= bcd_idle_s;
    shift <= 0;
    rx_bcd <= 0;
    check_prm <= 0;
    conv_bcd2bin <= 0;
  end
  else begin
    case (fsm_bcd)
      bcd_idle_s : begin
        if (conv_bcd) begin
          shift   <= (dot_pres) ? 3 - dot_pos : 3;
          fsm_bcd <= bcd_shift_s;
	  			rx_bcd  <= cur_rx.dat_bcd;
        end
      end
      bcd_shift_s : begin // shift bcd to account for k modifier
        shift <= shift - 1;
        if (shift == 0 || !k_mod_pres) begin
          fsm_bcd <= bcd_conv_s;
          conv_bcd2bin <= 1;
        end
        else rx_bcd[DAT_LEN-1:0] <= {rx_bcd[DAT_LEN-2:0], 4'h0};
      end
      bcd_conv_s : begin
        conv_bcd2bin <= 0;
        if (bcd2bin_rdy && !conv_bcd2bin) begin
          check_prm <= 1;
          $display("shifted real val. result: %h", rx_bcd);
        end
      end
    endcase
  end
end

/*
 * BCD to binary conversion when receiving
 * Vice versa when replying
 */

bcd2bin #(
	.DEC_W (DAT_LEN)
) bcd2bin_inst (
	.clk  (clk),
	.rst  (rst),
	.in   (rx_bcd),
	.out  (cur_rx_bin),
	.conv (conv_bcd2bin),
	.rdy  (bcd2bin_rdy)
);
bin2bcd #(
	.DEC_W (DAT_LEN)
) bin2bcd_inst (
	.clk  (clk),
	.rst  (rst),
	.in   (cur_tx_bin),
	.out  (tx_bcd),
	.conv (conv_bin2bcd),
	.rdy  (bin2bcd_rdy)
);

/////////////////////
// Parameter check //
/////////////////////

always @ (posedge clk) begin
  if (fsm_rst) begin
    prm_addr_int <= 0;
    prm_addr_prev <= 0;
    prm_fsm <= prm_idle_s;
    rsp_ok <= 0;
    conv_bin2bcd <= 0;
    prm_ram_w_int <= 0;
    err_prm <= prm_ok;
  end
  else begin
    case (prm_fsm)
      prm_idle_s : begin
        if (check_prm || scan_prm) prm_fsm <= prm_scan_s;
      end
      prm_scan_s : begin
        if (prm_rom_q.prm == cur_rx.prm) begin
          prm_addr_int <= prm_addr_prev;
          $display ("Found parameter %s, val %d", prm_rom_q.prm, prm_ram_q);
          if (cur_rx.cmd == set) prm_fsm <= prm_check_s;
          else if (cur_rx.cmd == get) prm_fsm <= prm_conv_s;
        end
        else begin
          prm_addr_int <= prm_addr_int + 1;
        end
        prm_addr_prev <= prm_addr_int;
        if (prm_addr_int == PRM_COUNT + 1) begin 
          $display ("Parameter not found");
          err_prm <= not_found;
        end
      end
      prm_check_s : begin
        if (prm_rom_q.rights == r) begin
          err_prm <= read_only;
          prm_fsm <= prm_wait_rst_s;
          $display ("Cannot write to a read only parameter");
        end
        else if (cur_rx_bin < prm_rom_q.min) begin
          $display ("Received val %d less than minimum %d", cur_rx_bin, prm_rom_q.min);
          err_prm <= low;
          prm_fsm <= prm_wait_rst_s;
        end
        else if (cur_rx_bin > prm_rom_q.max) begin
          $display ("Received val %d more than maximum %d", cur_rx_bin, prm_rom_q.max);
          err_prm <= high;
          prm_fsm <= prm_wait_rst_s;
        end
        else begin
          rsp_ok <= 1;
          $display ("Received val %d within limits: [%d..%d]", cur_rx_bin, prm_rom_q.min, prm_rom_q.max);
          prm_fsm <= prm_write_s;
        end
      end
      prm_write_s : begin
        rsp_ok    <= 1;
        prm_ram_w_int <= 1;
        prm_ram_d_int <= cur_rx_bin;
        prm_fsm     <= prm_wait_rst_s;
      end
      prm_conv_s : begin
        conv_bin2bcd <= 1;
        prm_fsm <= prm_read_s;
      end
      prm_read_s : begin
        conv_bin2bcd <= 0;
        if (bin2bcd_rdy && !conv_bin2bcd) begin
          prm_fsm <= prm_wait_rst_s;
          rsp_ok <= 1;
        end
      end
      prm_wait_rst_s : begin
        prm_ram_w_int <= 0;
      end
    endcase
  end
end


always @ (posedge clk) begin
  if (fsm_rst) begin
    err <= none;
    rsp_err <= 0;
  end
  else begin
    rsp_err <= (err != none);
    if (timeout) err <= rx_timeout;
    else if (err_rx != rx_ok) begin
      case (err_rx)
        rx_ok    : err <= none;
        cmd_bad    : err <= rx_cmd_bad;
        data_bad   : err <= rx_data_bad;
        prm_bad    : err <= rx_prm_bad;
        data_not_int : err <= rx_data_not_int;
        default : err <= none;
      endcase
    end
    else if (err_prm != prm_ok) begin
      case (err_prm)
        prm_ok  : err <= none;
        not_found : err <= prm_not_found;
        read_only : err <= prm_read_only;
        low     : err <= prm_low ;
        high    : err <= prm_high;
        default : err <= none;
      endcase
    end
  end
end

//////////////
// Response //
//////////////

logic cmd_tx_len;
logic prm_tx_len;
logic value_tx_len;
logic tx_bcd_val;
logic [7:0] cur_dig;

parameter integer STRING_LEN = 32;
parameter integer NUM_ERRORS = 9;

typedef struct packed {
  logic [0:STRING_LEN-1][7:0] val;
  err_t err;
} rsp_err_t;

rsp_err_t rsp_rom [NUM_ERRORS-1:0];
rsp_err_t rsp_rom_q;

logic [$clog2(NUM_ERRORS+1)-1:0] rsp_rom_addr;

always @ (posedge clk) begin
  rsp_rom_q <= rsp_rom[rsp_rom_addr];
end

logic [0:STRING_LEN-1][7:0] cur_rsp_string, param_set_str, ver_string;
logic [7:0] cur_rsp_ctr;

initial begin
  rsp_rom[0].val = "bad command";
  rsp_rom[0].err = rx_cmd_bad;

  rsp_rom[1].val = "bad data";
  rsp_rom[1].err = rx_data_bad;

  rsp_rom[2].val = "bad parameter";
  rsp_rom[2].err = rx_prm_bad;

  rsp_rom[3].val = "data not int";
  rsp_rom[3].err = rx_data_not_int;

  rsp_rom[4].val = "read-only";
  rsp_rom[4].err = prm_read_only;   

  rsp_rom[5].val = "parameter not found";
  rsp_rom[5].err = prm_not_found;   

  rsp_rom[6].val = "value too low";
  rsp_rom[6].err = prm_low;   

  rsp_rom[7].val = "value too high";
  rsp_rom[7].err = prm_high;

  rsp_rom[8].val = "timeout";
  rsp_rom[8].err = rx_timeout;

  param_set_str = ": parameter set";
  ver_string = `VERSION;
end

logic [$clog2(UNITS_LEN+1)-1:0] units_rsp_ctr;
logic [UNITS_LEN-1:0][7:0] cur_tx_units;
always @ (posedge clk) begin
  if (fsm_rst) begin
    tx_buf.data_in <= 0;
    tx_buf.write   <= 0;
    cmd_ctr_tx     <= 0;
    prm_ctr_tx     <= 0;
    dat_ctr_tx     <= 0;
    cur_tx_bcd     <= 0;
    fsm_tx         <= tx_idle_s;
    tx_bcd_val     <= 0;
    cur_dig        <= 0;
    tx_done        <= 0;
    rsp_rom_addr   <= 0;
    cur_rsp_string <= 0;
    cur_rsp_ctr    <= 0;
    units_rsp_ctr  <= 0;
    cur_tx_units   <= 0;
  end
  else begin
    case (fsm_tx)
      tx_idle_s : begin
        tx_buf.data_in <= ">";
        cur_tx <= cur_rx;
        if (rsp_ver) begin
          cur_rsp_string <= ver_string;
          fsm_tx <= tx_string_s;
        end
        if (rsp_ok) begin
          tx_buf.write <= 1;
          cmd_ctr_tx <= 0;
          prm_ctr_tx <= 0;
          dat_ctr_tx <= 0;
          cur_tx_bcd <= tx_bcd;
          cur_tx_units <= prm_rom_q.units;
          cur_rsp_string <= param_set_str;
          fsm_tx <= tx_prm_s;
        end
        else if (rsp_err) begin
          rsp_rom_addr <= rsp_rom_addr + 1;
          if (rsp_rom_q.err == err) begin
            fsm_tx <= tx_string_s;
            cur_rsp_string <= rsp_rom_q.val;
          end
        end
      end
      tx_cmd_s : begin
        cur_tx.cmd[CMD_LEN-1:1] <= cur_tx.cmd[CMD_LEN-2:0];
        tx_buf.write <= (cur_tx.cmd[CMD_LEN-1] != "");
        tx_buf.data_in <= cur_tx.cmd[CMD_LEN-1];
        cmd_ctr_tx <= cmd_ctr_tx + 1;
        if (cmd_ctr_tx == CMD_LEN - 1) fsm_tx <= tx_prm_s;
      end
      tx_prm_s : begin
        cur_tx.prm[PRM_LEN-1:1] <= cur_tx.prm[PRM_LEN-2:0];
        tx_buf.write <= (cur_tx.prm[PRM_LEN-1] != "");
        tx_buf.data_in <= cur_tx.prm[PRM_LEN-1];
        prm_ctr_tx <= prm_ctr_tx + 1;
        if (prm_ctr_tx == PRM_LEN - 1) begin
          case (cur_rx.cmd)     
            set : fsm_tx <= tx_string_s;
            get : fsm_tx <= tx_prm_dlm_s;
            default : fsm_tx <= tx_stop_s;
          endcase
        end
      end
      tx_prm_dlm_s : begin
        tx_buf.data_in <= PRM_DLM;
        tx_buf.write <= 1;
        fsm_tx <= tx_dat_s;
      end
      tx_dat_s : begin
        dat_ctr_tx <= dat_ctr_tx + 1;
        if (cur_tx_bcd[DAT_LEN-1] != 0 || (dat_ctr_tx == DAT_LEN-1)) tx_bcd_val <= 1; // append last symbol (zero) anyway
        cur_tx_bcd[DAT_LEN-1:1] <= cur_tx_bcd[DAT_LEN-2:0];
        cur_dig <= bcd2ascii(cur_tx_bcd[DAT_LEN-1]);
        tx_buf.data_in <= cur_dig;
        tx_buf.write <= tx_bcd_val;
        if (dat_ctr_tx == DAT_LEN) fsm_tx <= tx_units_s;
      end
      tx_units_s : begin
        units_rsp_ctr <= units_rsp_ctr + 1;
        cur_tx_units[UNITS_LEN-1:1] <= cur_tx_units[UNITS_LEN-2:0];
        if (units_rsp_ctr == UNITS_LEN-1) fsm_tx <= tx_stop_s;
        tx_buf.write <= (cur_tx_units[UNITS_LEN-1] != "");
        tx_buf.data_in <= cur_tx_units[UNITS_LEN-1];
      end      
      tx_stop_s : begin
        tx_buf.data_in <= DAT_DLM;
        tx_buf.write <= 1;
        fsm_tx <= tx_cr_s;
      end
      tx_cr_s : begin
        tx_buf.data_in <= "\r";
        tx_buf.write <= 1;
        fsm_tx <= tx_lf_s;
      end
      tx_lf_s : begin
        tx_buf.data_in <= "\n";
        tx_buf.write <= 1;
        fsm_tx <= tx_wait_rst_s;
      end
      tx_string_s : begin // transmit response string
        cur_rsp_ctr <= cur_rsp_ctr + 1;
        if (cur_rsp_ctr == STRING_LEN-1) fsm_tx <= tx_stop_s;
        if (cur_rsp_string[0] != 0) tx_buf.write <= 1;
        else if (cur_rsp_ctr == 0) tx_buf.write <= 0;
        cur_rsp_string[0:STRING_LEN-2] <= cur_rsp_string[1:STRING_LEN-1];
        tx_buf.data_in <= cur_rsp_string[0];
      end
      tx_wait_rst_s : begin
        tx_buf.write <= 0;
        tx_buf.data_in <= 0;
        tx_done <= 1;
      end
      default fsm_tx <= tx_idle_s;
    endcase
  end
end


always @ (posedge clk) begin
  if (rst) begin
    tx_buf.read <= 0;
  end
  else begin
    tx_buf.read <= (!tx_buf.empty && cts && !tx_buf.read); // readout bytes by one if clear to send
    txv <= tx_buf.read;
  end
end
assign txd = tx_buf.data_out;

endmodule : p10
