`timescale 1ps / 1ps
module tb ();
localparam ADC_BITS = 8;
localparam ADC_VPP  = 2; // ADC Vpk-pk
localparam ADC_PIPE = 5; // Pipeline delay
logic rst = 1;
logic clk = 1;
always #5000 clk <= ~clk; // 100 MHz (1ps time step)

real u;
real u_r; // resistor voltage
real u_c; // capacitor voltage
real u_l; // inductance voltage
real i;   // current
real u_err;

logic adc_ovfl_pos;
logic adc_ovfl_neg;

logic signed [ADC_BITS-1:0] adc_code;

logic [3:0] gate_vect;

assign adc_clk = clk;

// series RLC circuit
rlc_sim #(
	.dt (0.000000000001), // 1ps
	.L  (10 *0.000000001),
	.C  (50000000 *0.000000000001), // pF
	.R  (0.001) // nH
) rlc_sim_inst (
    .u    (u),

    .u_r  (u_r), 
    .u_c  (u_c), 
    .u_l  (u_l), 

    .i    (i),
	.u_err (u_err)
);

// Generic ADC simulation
adc_sim #(
	.BITS (ADC_BITS),
	.VPP  (ADC_VPP),
	.PIPE (ADC_PIPE),
	.TYPE ("unsigned")
) adc_sim_inst (
	.clk  (adc_clk),
	.in   (i),
	.code (adc_code),
	
	.ovfl_pos (adc_ovfl_pos),
	.ovfl_neg (adc_ovfl_neg)
);
/*
spi_pot_sim #() spi_pot_sim_inst (
	.sda (spi_sda),
	.scl (spi_scl),
	.csn (spi_csn),
	.in  (),
	.out ()
);

hdl dut (
	.clk_in  (clk),
	.rst     (),

	.xtal_en (),
	.drv     (drv), // J5.7

	.rxd     (rxd),
	.txd     (txd),

	.adc     (adc_code),

	.spi_sda (spi_sda),
	.spi_scl (spi_scl),
	.spi_csn (spi_csn)
);
*/
logic [11:0] phase;
initial begin
	phase = 20;
	#500000 phase = 180;
end
fixed_driver #(
	.FREQ_STEP_HZ  (1),
	.REF_CLK_HZ    (100000000),
	.MIN_FREQ_HZ   (1000),
	.MAX_FREQ_HZ   (1000000),
	.DUTY_SCALE    (100),
	.PHASE_SCALE   (360), // Don't exceed PHASE_SCALE - 1 on phase input (E.g. don't assert more then 359 when PHASE_SCALE is 360)
	.DEADTIME_BITS (100)
) fixed_driver_inst
(
	.clk      (clk),
	.rst      (rst),
	.freq     (225000),
	.duty     (25),
	.phase    (phase),
	.deadtime (),

	.drv0_en  (),
	.drv0     (drv0),

	.drv1_en  (),
	.drv1     (drv1)
);
initial begin
	#100000 rst = 0;
//	#200000 u = 200;
//	#500000 u = 0;
end

always_comb begin
	case ({drv0, drv1})
		2'b00, 2'b11: u = 0;
		2'b10 : u =  20;
		2'b01 : u = -20;
	endcase	
end


endmodule

