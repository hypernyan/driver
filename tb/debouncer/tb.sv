module tb ();

parameter integer WIDTH     = 12;

logic clk = 1;
logic rst = 1;

logic i;
logic o;

always #1 clk <= !clk;

debouncer #(
	.TICKS (10000)
) dut
(
	.clk (clk),
	.rst (rst),

	.i   (i),
	.o   (o)
);

initial begin
#100000 i = 0;
#1000 i = 1;
#1003 i = 0;
#2213 i = 1;
#2031 i = 0;
#1013 i = 1;
#3032 i = 0;
#1013 i = 1;
#1400 i = 0;
#1054 i = 1;
#4234 i = 0;
#1337 i = 1;
#75607 i = 0;
#4304 i = 0;
#1054 i = 1;
#1020 i = 0;
#1043 i = 1;
#1030 i = 0;
end

endmodule
