
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
//	`ifdef TARGET_CYC1000
//	(* chip_pin = "M2" *) input  logic clk_12m,
	//(* chip_pin = "H5" *) input  logic ext_rstn,

//	output logic [3:0] drv, // J5.7

	//input  logic uart_rxd, // FTDI
	//output logic uart_txd,

//	(* chip_pin = "T15, R14, P14, T14, R13, T13, R12, P11" *) input  logic [7:0] adc,
//	(* chip_pin = "T12" *) output logic adc_clk, // 100 MHz ADC sampling clock
//
//	(* chip_pin = "J14" *) output logic spi_csn, // AGC pot SPI
//	(* chip_pin = "K16" *) output logic spi_sda,
//	(* chip_pin = "K15" *) output logic spi_scl,
//
//	(* chip_pin = "F13" *) inout  logic i2c_sda, // ina219
//	(* chip_pin = "D15" *) output logic i2c_scl,
//
//	(* chip_pin = "F15" *) output logic mdc,  // PHY
//	(* chip_pin = "C15" *) inout  logic mdio,
//
//	(* chip_pin = "L2, P1" *) input logic [1:0] mii_rx_dat,
//	(* chip_pin = "R1" *)     input logic       mii_rx_val,
//	(* chip_pin = "K2" *)     input logic       mii_rx_clk,
//
//	(* chip_pin = "L2, P1" *) output logic [1:0] mii_tx_data,
//	(* chip_pin = "R1" *)     output logic       mii_tx_valid,
//	(* chip_pin = "K2" *)     output logic       mii_tx_clk,

//	(* chip_pin = "T7" *) output logic uart_txd,  // fsdi
//	(* chip_pin = "R7" *) input  logic uart_rxd,  // clk
//	(* chip_pin = "R6" *) input  logic rtsn, // fsdo
//	(* chip_pin = "T6" *) output logic ctsn, // 
//	(* chip_pin = "R5" *) input  logic DTR,  // 
//	(* chip_pin = "T5" *) output logic DSR,   // 
//	(* chip_pin = "C16" *) output logic drv0, // 
//	(* chip_pin = "B16" *) output logic drv1 // 
//	`endif // TARGET_CYC1000
//	`ifdef TARGET_DE0_NANO
//	(* chip_pin = "M2" *) input  logic clk_50m

//	`endif // TARGET_DE0_NANO
 
	// Ethernet
	(* chip_pin = "J22" *) output logic phy_gtx_clk,
	(* chip_pin = "D22" *) input  logic phy_rx_clk, 

	(* chip_pin = "W22" *) output logic phy_tx_err, 
	(* chip_pin = "M21" *) output logic phy_tx_val, 
	(* chip_pin = "W21, V22, V21, U22, R22, R21, P22, M22" *) output logic [7:0] phy_tx_dat, 

	(* chip_pin = "H21" *) input  logic phy_rx_err, 
	(* chip_pin = "B21" *) input  logic phy_rx_val,
	(* chip_pin = "F22, F21, E22, E21, D21, C22, C21, B22" *) input logic [7:0] phy_rx_dat,

	(* chip_pin = "Y21" *) output logic mdc,
	(* chip_pin = "Y22" *) output logic mdio,

	(* chip_pin = "P3" *)  output logic reset_n,
	(* chip_pin = "P21" *) output logic phy_rst_n,
    // Ethernet connections
    (* chip_pin = "W17, Y17" *) output logic [1:0] led,
    // RHD SPI
    (* chip_pin = "B8" *)  output logic drv0,
    (* chip_pin = "B9" *)  output logic drv1
);

parameter int NCO_LUT_ADDR_BITS  = 8;  
parameter int NCO_LUT_DATA_BITS  = 8; 
parameter int NCO_PHASE_ACC_BITS = 24;
parameter int VFD_MOD_FREQ_BITS  = 8;
parameter int MOD_BITS           = 10;
parameter int REF_CLK_HZ         = 125000000;
parameter int FREQ_BITS          = 16;
parameter int REFCLK_HZ          = 200000000;
parameter int ADC_BITS           = 8;
parameter bit DEFAULT_STATE      = 0;

`include "../../src/verilog/p10_reg_defines.sv"


ram_if_sp #(.AW(8), .DW(32)) ram (.*);
settings_t settings;
exec #(.PRM_COUNT(P10_PRM_COUNT)) exec_if(.*);
rhd_cmd_if commands (.*);

assign clk = phy_rx_clk;
assign ram.clk = clk;

////////////
// Driver //
////////////

fixed_driver #(
	.FREQ_STEP_HZ (1),
	.REF_CLK_HZ   (100000000),
	.MIN_FREQ_HZ  (1000),
	.MAX_FREQ_HZ  (500000),
	.DUTY_SCALE   (100),
	.PHASE_SCALE  (360) // Don't exceed PHASE_SCALE - 1 on phase input (E.g. don't assert more then 359 when PHASE_SCALE is 360)
) fixed_driver_inst (
	.clk     (clk),
	.rst     (rst),

	.settings (settings),
	.commands (commands),

	.drv({drv1, drv0})
);

/*
vfd #(
  .NCO_LUT_ADDR_BITS   (NCO_LUT_ADDR_BITS),  
  .NCO_LUT_DATA_BITS   (NCO_LUT_DATA_BITS),  
  .NCO_PHASE_ACC_BITS  (NCO_PHASE_ACC_BITS),
  .VFD_MOD_FREQ_BITS   (VFD_MOD_FREQ_BITS),
  .MOD_BITS            (MOD_BITS),
  .REF_CLK_HZ          (REF_CLK_HZ),
  .LUT_FILENAME        ("../../src/verilog/nco_lut.txt")
) vfd_inst (
  .clk (clk),
  .rst (rst_100m),

  .mod_freq (mod_freq),
  
  .drv ()
);
*/

//////////////
// Ethernet //
//////////////

eth_vlg #(
  .MAC_ADDR             (48'h107b444fd012),
  .IPV4_ADDR            (32'hc0a800d5),
  .N_TCP                (1),
  .MTU                  (32'd1500),
  .TCP_RETRANSMIT_TICKS (32'd1000000),
  .TCP_RETRANSMIT_TRIES (32'd5),
  .TCP_RAM_DEPTH        (32'd12),
  .TCP_PACKET_DEPTH     (32'd4),
  .TCP_WAIT_TICKS       (32'd200))
eth_vlg_inst (
	.phy_rx (phy_rx),
	.phy_tx (phy_tx),

	.clk    (clk),
	.rst    (rst),

	.tcp_din (tcp_din),
	.tcp_vin (tcp_vin),
	.tcp_snd (tcp_snd),
	.tcp_cts (tcp_cts),

	.tcp_dout (tcp_dout),
	.tcp_vout (tcp_vout),

	.connect   (1'b0),
	.connected (connected),
	.listen    (1'b1),
	.loc_port  (16'd1000),
	.rem_ipv4  (32'b0),
	.rem_port  (16'b0)
);

assign phy_rx.d = phy_rx_dat;
assign phy_rx.v = phy_rx_val;
assign phy_rx.e = phy_rx_err;

assign phy_tx_dat  = phy_tx.d;
assign phy_tx_val  = phy_tx.v;
assign phy_tx_err  = phy_tx.e;
assign phy_gtx_clk = phy_rx_clk;

//////////////////
// P10 instance //
//////////////////

p10 p10_inst (
  .clk (clk),
  .rst (rst),

  .rxd (tcp_dout0),
  .rxv (tcp_vout0),

  .txd (tcp_din0),
  .txv (tcp_vin0),
  .cts (tcp_cts0),
 
  .ram     (ram),
  .exec_if (exec_if)
);

// Convert "parameter ram contents" to "settings" and "executive interface"
// to "commands" understandable by "module rhd ();"

p10_ctrl p10_ctrl_inst (
  .clk (clk),
  .rst (rst),

  .ram       (ram),
  .exec_if   (exec_if),   // req-> <-rsp
  .connected (connected),  // <-in

  .settings (settings), // out->
  .commands (commands)  // out->
);

endmodule
