module tb ();

logic clk = 0;
logic rst = 1;

always #1 clk <= ~clk;

initial #100 rst <= 0;

vfd dut (
  .clk (clk),
  .rst (rst)
);

defparam dut.LUT_FILENAME = "../../src/verilog/nco_lut.txt";
//defparam dut.LUT_FILENAME = "../../tb/vfd/nco_lut.txt";

endmodule
