//`define SIMULATION
`ifdef SIMULATION

`endif
module display #(
    parameter FREQ_BITS = 10,
    parameter DUTY_BITS = 10,
    parameter STAT_BITS = 10,
    parameter PRESCALER = 100
)
(
    input logic  clk,
	input logic  rst,

	input logic [FREQ_BITS:0] freq,
	input logic [DUTY_BITS:0] duty,
	input logic [STAT_BITS:0] stat,
	
    output logic sdo,
	output logic scl,
	output logic csn
);

localparam RAM_LEN   = 45;
localparam RAM_WIDTH = 10;
localparam SEND_INTERVAL_TICKS = PRESCALER * 50;


// Bits and commands definitions
localparam bit incr_on  = 1;
localparam bit shift_on = 0;
localparam bit dspl_on  = 1;
localparam bit curs_on  = 1;
localparam bit blink_on = 1;
localparam bit shift_displ = 0;
localparam bit shift_right = 1;

// Symbols
localparam [9:0] 
SYMBOL_0 = 10'b1000110000,
SYMBOL_1 = 10'b1000110001,
SYMBOL_2 = 10'b1000110010,
SYMBOL_3 = 10'b1000110011,
SYMBOL_4 = 10'b1000110100,
SYMBOL_5 = 10'b1000110101,
SYMBOL_6 = 10'b1000110110,
SYMBOL_7 = 10'b1000110111,
SYMBOL_8 = 10'b1000111000,
SYMBOL_9 = 10'b1000111001,
SYMBOL_a = 10'b1001100001,
SYMBOL_b = 10'b1001100010,
SYMBOL_c = 10'b1001100011,
SYMBOL_d = 10'b1001100100,
SYMBOL_e = 10'b1001100101,
SYMBOL_f = 10'b1001100110,
SYMBOL_g = 10'b1001100111,
SYMBOL_h = 10'b1001101000,
SYMBOL_i = 10'b1001101001,
SYMBOL_j = 10'b1001101010,
SYMBOL_k = 10'b1001101011,
SYMBOL_l = 10'b1001101100,
SYMBOL_m = 10'b1001101101,
SYMBOL_n = 10'b1001101110,
SYMBOL_o = 10'b1001101111,
SYMBOL_p = 10'b1001110000,
SYMBOL_q = 10'b1001110001,
SYMBOL_r = 10'b1001110010,
SYMBOL_s = 10'b1001110011,
SYMBOL_t = 10'b1001110100,
SYMBOL_u = 10'b1001110101,
SYMBOL_v = 10'b1001110110,
SYMBOL_w = 10'b1001110111,
SYMBOL_x = 10'b1001111000,
SYMBOL_y = 10'b1001111001,
SYMBOL_z = 10'b1001111010,
SYMBOL_COLON   = 10'b1000111010,
SYMBOL_SPACE   = 10'b1000100000,
SYMBOL_DOT     = 10'b1000101110,
SYMBOL_PERCENT = 10'b1000100101,
SYMBOL_DEGREE  = 10'b1011011111;


localparam [9:0] clr_dspl = 10'b0000000001;
localparam [9:0] home     = 10'b0000000010;
localparam [9:0] line_2   = 10'b0011000000;
localparam [9:0] entry    = {8'b00000001, incr_on, shift_on};
localparam [9:0] onoff    = {7'b0000001, dspl_on, curs_on, blink_on};
localparam       cur_displ_shift = {6'b000001, shift_displ, shift_right};

logic [$clog2(SEND_INTERVAL_TICKS+1)-1:0] ctr;
logic [$clog2(RAM_LEN+1)-1:0] ram_addr;
logic [RAM_WIDTH-1:0] ram_data;
logic busy;
logic send;
logic vin;

logic [RAM_WIDTH-1:0] cfg     [0:RAM_LEN-1];

// Generic RAM declaration
logic [RAM_WIDTH-1:0] cfg_ram [0:RAM_LEN-1];
always @ (posedge clk) ram_data <= cfg_ram[ram_addr];

initial begin
	cfg[0] = clr_dspl;
	cfg[1] = home;
	cfg[2] = entry;
	cfg[3] = onoff;

	cfg[4] = SYMBOL_f;
	cfg[5] = SYMBOL_COLON;
	cfg[6] = SYMBOL_1;
	cfg[7] = SYMBOL_2;
	cfg[8] = SYMBOL_0;

	cfg[9] = SYMBOL_DOT;
	cfg[10] = SYMBOL_7;
	cfg[11] = SYMBOL_k;
	cfg[12] = SYMBOL_h;
	cfg[13] = SYMBOL_z;

	cfg[14] = SYMBOL_SPACE;
	cfg[15] = SYMBOL_d;
	cfg[16] = SYMBOL_c;
	cfg[17] = SYMBOL_COLON;
	cfg[18] = SYMBOL_3;

	cfg[19] = SYMBOL_2;
	cfg[20] = SYMBOL_DOT;
	cfg[21] = SYMBOL_2;
	cfg[22] = SYMBOL_PERCENT;
	cfg[23] = SYMBOL_SPACE;

	cfg[24] = line_2;

	cfg[25] = SYMBOL_v;
	cfg[26] = SYMBOL_COLON;
	cfg[27] = SYMBOL_3;
	cfg[28] = SYMBOL_2;
	cfg[29] = SYMBOL_2;

	cfg[30] = SYMBOL_SPACE;
	cfg[31] = SYMBOL_i;
	cfg[32] = SYMBOL_COLON;
	cfg[33] = SYMBOL_1;
	cfg[34] = SYMBOL_0;

	cfg[35] = SYMBOL_DOT;
	cfg[36] = SYMBOL_6;
	cfg[37] = SYMBOL_SPACE;
	cfg[38] = SYMBOL_t;
	cfg[39] = SYMBOL_COLON;

	cfg[40] = SYMBOL_4;
	cfg[41] = SYMBOL_5;
	cfg[42] = SYMBOL_DEGREE;
	cfg[43] = SYMBOL_c;
	cfg[44] = SYMBOL_SPACE;
end

int i;
int f;

initial begin
`ifdef SIMULATION
	f = $fopen("../src/verilog/cfg_init.txt", "w");
	for (i = 0; i < RAM_LEN; i = i + 1) begin
		$fwrite(f, "%b\n", cfg[i]);
	end
	$fclose(f);
$readmemb ("../src/verilog/cfg_init.txt", cfg_ram);
`endif // SIMULATION
`ifndef SIMULATION
$readmemb ("cfg_init.txt", cfg_ram);
`endif
end

assign csn = !busy;

always @ (posedge clk) begin
	if (rst) begin
		ctr <= 0; 
		ram_addr <= 0;
	end
	else if (ram_addr != RAM_LEN) begin
		ctr <= (ctr == SEND_INTERVAL_TICKS) ? 0 : ctr + 1;
		ram_addr <= (ctr == SEND_INTERVAL_TICKS) ? ram_addr + 1 : ram_addr;
	end
end


spi #(
	.PRESCALER (PRESCALER),
	.WIDTH     (17))
spi_inst(
	.clk  (clk),
	.rst  (rst),

	.SDA  (sdo),
	.SCL  (scl),

	.din  ({6'b111110, ram_data, 1'b1}),
	.vin  ((ctr == SEND_INTERVAL_TICKS)),
	.busy (busy)
);

endmodule
