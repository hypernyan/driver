parameter int ADDR_FREQ     = 0;
parameter int ADDR_DUTY     = 1;
parameter int ADDR_PHASE    = 2;
parameter int ADDR_OCD      = 3;
parameter int ADDR_DEADTIME = 4;
parameter int ADDR_CURRENT  = 5;
parameter int ADDR_STOP     = ADDR_CURRENT;

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