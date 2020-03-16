/*
// Configuration RAM
localparam int MEM_BITS         = 32;
localparam int DUTY_RW_ADDR     = 1;
localparam int MODE_RW_ADDR     = 2;
localparam int OCD_WARN_RW_ADDR = 3;
localparam int OCD_RW_ADDR      = 4;
localparam int CURRENT_RW_ADDR  = 5;

// Driver parameters
parameter MIN_FREQ_HZ = 1000;
parameter MAX_FREQ_HZ = 1000000;

parameter MIN_DUTY       = 0;
parameter MAX_DUTY       = 100;
parameter DUTY_P10_SHIFT = 2;

parameter MIN_PHASE   = 0;
parameter MAX_PHASE   = 360;

parameter FREQ_BITS   = $clog2(MAX_FREQ_HZ+1);
parameter DUTY_BITS   = $clog2(DUTY_SCALE+1);
parameter PHASE_BITS  = $clog2(PHASE_SCALE+1);

// Start-up defaults

// p10 parameters
parameter P10_CMD_NUM = 5;
parameter P10_CMD_SET = 0;
parameter P10_CMD_GET = 1;
parameter P10_CMD_HELP = 2;
parameter P10_CMD_MON = 3;
*/