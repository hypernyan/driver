module spi #(
	parameter integer PRESCALER   = 10, 
	parameter integer WRITE_WIDTH = 16,
	parameter integer READ_WIDTH  = 0,
	parameter integer WIDTH       = WRITE_WIDTH + READ_WIDTH
)
(
	input  logic             clk,
	input  logic             rst,

	output logic             SDA,
	output logic             SCL,

	input  logic [WIDTH-1:0] din,
	input  logic             vin,
	input  logic             r_nw,
	output logic             busy
);

parameter integer PRESCALER_HALF = integer'(PRESCALER/2);

logic [$clog2(PRESCALER+1)-1:0] ctr;
logic [WRITE_WIDTH-1:0] txd;
logic busy_r;
logic oe;
logic [READ_WIDTH-1:0] rxd;
logic scl_pos;
logic scl_neg;
logic [$clog2(WIDTH+1)-1:0] bit_ctr;

assign busy = busy_r || vin;

always @ (posedge clk) begin
	if (rst) ctr <= 0;
	else begin
		if (vin) ctr <= PRESCALER_HALF;
		else if (busy) ctr <= (ctr == PRESCALER-1) ? 0 : ctr + 1;
	end
end

assign scl_pos = (ctr == PRESCALER-1);
assign scl_neg = (ctr == PRESCALER_HALF-1);

// Generate SCL
always @ (posedge clk) begin
	if (rst) SCL <= 0;
	else begin
		if (ctr == PRESCALER-1 && (bit_ctr != WIDTH)) SCL <= 1;
		if (ctr == PRESCALER_HALF-1) SCL <= 0;
	end
end

// Tx and rx
always @ (posedge clk) begin
	if (rst) begin
		busy_r  <= 0;
		txd     <= 0;
		bit_ctr <= 0;
		oe      <= 0;
	end
	else begin
		if (vin) begin
			busy_r <= 1;
			txd <= din;
			bit_ctr <= 0;
			oe <= 1;
		end
		else begin
			if (scl_pos) begin
				if (bit_ctr == WIDTH) busy_r <= 0;
				if (bit_ctr != WIDTH) bit_ctr <= bit_ctr + 1;
				if (bit_ctr == WRITE_WIDTH) oe <= 0;
				if (!oe) rxd[READ_WIDTH-1:1] <= rxd[READ_WIDTH-2:0];
			end
			if (scl_neg && busy_r) begin
				txd[WRITE_WIDTH-1:1] <= txd[WRITE_WIDTH-2:0];
			end
		end
	end
end

assign SDA = txd[WIDTH-1];
endmodule
