module tb ();

parameter integer WIDTH     = 12;

logic clk = 1;
logic rst = 1;

always #1 clk <= !clk;

logic [WIDTH-1:0] dvd; // divident
logic [WIDTH-1:0] dvs; // divisor
logic [WIDTH-1:0] quo;
logic rdy;

initial begin
	#10 rst <= 0;
	#20 
	dvd <= 255;
	dvs <= 3;
	#20
	dvs <= 5;
end

int_divider #(
    .WIDTH (12)
) dut (
    .clk (clk),
    .rst (rst),
    .dvd (dvd), // divident
    .dvs (dvs), // divisor
    .quo (quo),
    .rdy (rdy)
);

endmodule
