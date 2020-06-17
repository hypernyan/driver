
/*             _________________________________
 *    ADC_D0  | GPIO_0  | P11      R1 | GPIO_22 | RMII_RXV
 *    ADC_CLK | GPIO_23 | T12      P1 | GPIO_21 | RMII_RXD0
 *    ADC_D1  | GPIO_1  | R12      L2 | GPIO_20 | RMII_RXD1
 *    ADC_D2  | GPIO_2  | T13      K2 | GPIO_19 | RMII_RXC
 *    ------  | GPIO_24 |          J2 | GPIO_18 | PHY_REF_CLK
 *    ADC_D3  | GPIO_3  | R13      J1 | GPIO_17 | RMII_TXV
 *    ADC_D4  | GPIO_4  | T14      P2 | GPIO_16 | RMII_TXD1
 *    ADC_D5  | GPIO_5  | P14      N1 | GPIO_15 | RMII_TXD0
 *    ADC_D6  | GPIO_6  | R14      N2 | GPIO_14 | RMII_TXC
 *    ADC_D7  | GPIO_7  | T15         |_________|
 *            |_________|             |         |
 *            |         |          C16| PIO_08  | FPGA_D
 *    POT_CSn | GPIO_8  | N16      D16| PIO_04  | FPGA_C
 *    POT_SDA | GPIO_9  | L15      B16| PIO_07  | FPGA_B
 *    POT_SCK | GPIO_10 | L16      F16| PIO_03  | FPGA_A
 *    SPI_CLK | GPIO_11 | K15      C15| PIO_06  | MDIO
 *    SPI_DAT | GPIO_12 | K16      F15| PIO_02  | MDC
 *    SPI_CS  | GPIO_13 | J14      D15| PIO_05  | INA_SCL
 *            |         |          F13| PIO_01  | INA_SDA
 *            |_________|_____________|_________|
 */


`define SIMULATION

module top (
	(* chip_pin = "M2" *) input  logic clk_12m,
	//(* chip_pin = "H5" *) input  logic ext_rstn,

	output logic [3:0] drv, // J5.7

	//input  logic uart_rxd, // FTDI
	//output logic uart_txd,

	(* chip_pin = "T15, R14, P14, T14, R13, T13, R12, P11" *) input  logic [7:0] adc,
	(* chip_pin = "T12" *) output logic adc_clk, // 100 MHz ADC sampling clock

	(* chip_pin = "J14" *) output logic spi_csn, // AGC pot SPI
	(* chip_pin = "K16" *) output logic spi_sda,
	(* chip_pin = "K15" *) output logic spi_scl,

	(* chip_pin = "F13" *) inout  logic i2c_sda, // ina219
	(* chip_pin = "D15" *) output logic i2c_scl,

	(* chip_pin = "F15" *) output logic mdc,  // PHY
	(* chip_pin = "C15" *) inout  logic mdio,

//	(* chip_pin = "L2, P1" *) input logic [1:0] mii_rx_dat,
//	(* chip_pin = "R1" *)     input logic       mii_rx_val,
//	(* chip_pin = "K2" *)     input logic       mii_rx_clk,
//
//	(* chip_pin = "L2, P1" *) output logic [1:0] mii_tx_data,
//	(* chip_pin = "R1" *)     output logic       mii_tx_valid,
//	(* chip_pin = "K2" *)     output logic       mii_tx_clk,

	(* chip_pin = "T7" *) output logic uart_txd,  // fsdi
	(* chip_pin = "R7" *) input  logic uart_rxd,  // clk
	(* chip_pin = "R6" *) input  logic rtsn, // fsdo
	(* chip_pin = "T6" *) output logic ctsn, // 
	(* chip_pin = "R5" *) input  logic DTR,  // 
	(* chip_pin = "T5" *) output logic DSR,   // 
	(* chip_pin = "C16" *) output logic drv0, // 
	(* chip_pin = "B16" *) output logic drv1 // 
);

`include "../../src/verilog/p10_reg_defines.sv"

parameter int FREQ_BITS = 16;
parameter int REFCLK_HZ = 200000000;
parameter int ADC_BITS  = 8;
parameter bit DEFAULT_STATE = 0;
/*
reset_controller reset_controller_inst(
	.rstn     (1'b1),
	.clk_in   (clk_12m),
	.clk_out  (clk_100m),
	.rst_out  (rst)
);
*/

assign clk_100m = clk_12m;

logic rx_val;
logic [7:0] rx_dat;

logic [7:0] prm_addr, cur_addr;
logic [31:0] prm_ram_d;
logic [31:0] prm_ram_q;
logic [31:0] prm_ram_w;

p10_serial #(
   .REFCLK_MHZ   (100),
   .BAUDRATE     (57600),
   .PARITY_EN    (0),
   .PARITY_EVEN  (1)
) p10_serial_inst
(
   .clk (clk_100m),
   .rst (rst),
   .rx  (uart_rxd),
   .tx  (uart_txd),
 
    .prm_addr  (prm_addr),
    .prm_ram_d (prm_ram_d),
    .prm_ram_q (prm_ram_q),
    .prm_ram_w (prm_ram_w)   
);

logic [31:0] freq, duty, phase;
/*
fixed_driver #(
	.FREQ_STEP_HZ (1),
	.REF_CLK_HZ   (100000000),
	.MIN_FREQ_HZ  (1000),
	.MAX_FREQ_HZ  (500000),
	.DUTY_SCALE   (100),
	.PHASE_SCALE  (360) // Don't exceed PHASE_SCALE - 1 on phase input (E.g. don't assert more then 359 when PHASE_SCALE is 360)
) fixed_driver_inst (
	.clk     (clk_100m),
	.rst     (rst),

	.freq    (freq),
	.duty    (duty),
	.phase   (phase),

	.drv0_en (),
	.drv0    (drv0),

	.drv1_en (),
	.drv1    (drv1)
);
*/

parameter NCO_LUT_ADDR_BITS  = 8;  
parameter NCO_LUT_DATA_BITS  = 8; 
parameter NCO_PHASE_ACC_BITS = 24;
parameter VFD_MOD_FREQ_BITS  = 8;
parameter MOD_BITS           = 10;
parameter REF_CLK_HZ         = 100000000;

vfd #(
  .NCO_LUT_ADDR_BITS   (NCO_LUT_ADDR_BITS),  
  .NCO_LUT_DATA_BITS   (NCO_LUT_DATA_BITS),  
  .NCO_PHASE_ACC_BITS  (NCO_PHASE_ACC_BITS),
  .VFD_MOD_FREQ_BITS   (VFD_MOD_FREQ_BITS),
  .MOD_BITS            (MOD_BITS),
  .REF_CLK_HZ          (REF_CLK_HZ),
  .LUT_FILENAME        ("../../src/verilog/nco_lut.txt")
) vfd_inst (
  .clk (clk_100m),
  .rst (rst_100m),

  .mod_freq (mod_freq),
  
  .drv ()
);


// monitor p10 output 
// user input is reflected via ram interface

always @ (posedge clk_100m) begin
	prm_addr <= (prm_addr == ADDR_STOP) ? 0 : prm_addr + 1;
	cur_addr <= prm_addr;
	case (cur_addr)
		ADDR_MOD_FREQ : begin
			mod_freq <= prm_ram_q;
		end
		ADDR_FREQ : begin
			freq <= prm_ram_q;
		end
		ADDR_DUTY : begin
			duty <= prm_ram_q;
		end
		ADDR_PHASE : begin
			phase <= prm_ram_q;
		end
		ADDR_OCD : begin

		end
		ADDR_DEADTIME : begin

		end
		ADDR_CURRENT : begin

		end
	endcase
end

endmodule
