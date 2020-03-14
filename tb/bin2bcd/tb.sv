module tb ();

parameter integer DEC_W = 8;
parameter integer BIN_W = $clog2(10**DEC_W);
logic clk = 1;
logic rst = 1;

always #1 clk <= !clk;
logic rdy;
logic ena;

logic bin2bcd_rdy;
logic bcd2bin_rdy;

logic [DEC_W-1:0][3:0] bcd;
logic [BIN_W-1:0]      test_bin = 0;
logic [BIN_W-1:0]      result_bin;

initial begin
	#10 rst <= 0;

end

bin2bcd #(
    .DEC_W  (DEC_W))
dut_bin2bcd (
	.clk (clk),
	.rst (rst),
	.in  (test_bin),
	.out (bcd),
	.rdy (bin2bcd_rdy)
);

bcd2bin #(
    .DEC_W  (DEC_W))
dut_bcd2bin (
	.clk (clk),
	.rst (rst),
	.in  (bcd),
	.out (result_bin),
	.rdy (bcd2bin_rdy)
);

always #400 test_bin <= test_bin + 1;
endmodule