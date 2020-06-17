
import p10_pkg_common::*;

module p10_rom #(
    parameter PRM_COUNT = 8
)
(
    input logic                     clk,
    input [$clog2(PRM_COUNT+1)-1:0] addr,
    output prm_entry_t entry
);
 
prm_entry_t prm_rom [0:PRM_COUNT-1];

`include "../../src/verilog/p10_reg_defines.sv"

initial begin
    prm_rom[ADDR_FREQ].prm     = "freq";
    prm_rom[ADDR_FREQ].min     = 0;
    prm_rom[ADDR_FREQ].max     = 500000;
    prm_rom[ADDR_FREQ].units   = "hz";
    prm_rom[ADDR_FREQ].rights  = rw;
    prm_rom[ADDR_FREQ].is_exec = 0;

    prm_rom[ADDR_DUTY].prm     = "duty";
    prm_rom[ADDR_DUTY].min     = 0;
    prm_rom[ADDR_DUTY].max     = 50;
    prm_rom[ADDR_DUTY].units   = "%";
    prm_rom[ADDR_DUTY].rights  = rw;
    prm_rom[ADDR_DUTY].is_exec = 0;

    prm_rom[ADDR_PHASE].prm     = "phase";
    prm_rom[ADDR_PHASE].min     = 0;
    prm_rom[ADDR_PHASE].max     = 360;
    prm_rom[ADDR_PHASE].units   = "deg";
    prm_rom[ADDR_PHASE].rights  = rw;
    prm_rom[ADDR_PHASE].is_exec = 0;
end

always @ (posedge clk) entry <= prm_rom[addr]; // readout ROM entry containing info about current parameter

endmodule
