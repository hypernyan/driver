`ifndef P10_ROM
`define P10_ROM
import p10_pkg_common::*;
prm_entry_t prm_rom [0:PRM_COUNT-1];
`endif

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
