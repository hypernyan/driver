
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
    prm_rom[ADDR_FREQ_HZ].prm     = "freq";
    prm_rom[ADDR_FREQ_HZ].min     = 0;
    prm_rom[ADDR_FREQ_HZ].max     = 500000;
    prm_rom[ADDR_FREQ_HZ].units   = "hz";
    prm_rom[ADDR_FREQ_HZ].rights  = rw;
    prm_rom[ADDR_FREQ_HZ].is_exec = 0;

    prm_rom[ADDR_DUTY_PERCENT].prm     = "duty";
    prm_rom[ADDR_DUTY_PERCENT].min     = 0;
    prm_rom[ADDR_DUTY_PERCENT].max     = 50;
    prm_rom[ADDR_DUTY_PERCENT].units   = "%";
    prm_rom[ADDR_DUTY_PERCENT].rights  = rw;
    prm_rom[ADDR_DUTY_PERCENT].is_exec = 0;

    prm_rom[ADDR_PHASE_DEGREE].prm     = "phase";
    prm_rom[ADDR_PHASE_DEGREE].min     = 0;
    prm_rom[ADDR_PHASE_DEGREE].max     = 359;
    prm_rom[ADDR_PHASE_DEGREE].units   = "deg";
    prm_rom[ADDR_PHASE_DEGREE].rights  = rw;
    prm_rom[ADDR_PHASE_DEGREE].is_exec = 0;

    prm_rom[ADDR_APPLY].prm     = "apply";
    prm_rom[ADDR_APPLY].min     = 0;
    prm_rom[ADDR_APPLY].max     = 1;
    prm_rom[ADDR_APPLY].units   = "";
    prm_rom[ADDR_APPLY].rights  = rw;
    prm_rom[ADDR_APPLY].is_exec = 1;

    prm_rom[ADDR_ENABLE].prm     = "enable";
    prm_rom[ADDR_ENABLE].min     = 0;
    prm_rom[ADDR_ENABLE].max     = 1;
    prm_rom[ADDR_ENABLE].units   = "";
    prm_rom[ADDR_ENABLE].rights  = rw;
    prm_rom[ADDR_ENABLE].is_exec = 1;

    prm_rom[ADDR_DISABLE].prm     = "disable";
    prm_rom[ADDR_DISABLE].min     = 0;
    prm_rom[ADDR_DISABLE].max     = 1;
    prm_rom[ADDR_DISABLE].units   = "";
    prm_rom[ADDR_DISABLE].rights  = rw;
    prm_rom[ADDR_DISABLE].is_exec = 1;
end

always @ (posedge clk) entry <= prm_rom[addr]; // readout ROM entry containing info about current parameter

endmodule
