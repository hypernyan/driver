import p10_pkg_common::*;

module p10_serial #(
    parameter integer REFCLK_MHZ   = 100,
    parameter integer BAUDRATE     = 115200,
    parameter integer PARITY_EN    = 0,
    parameter integer PARITY_EVEN  = 1
)
(
    input  logic clk,
    input  logic rst,
    input  logic rx,
    output logic tx,

    input  logic [$clog2(PRM_COUNT+1)-1:0] prm_addr,
    input  prm_entry_t prm_ram_d,
    output prm_entry_t prm_ram_q,
    input  logic       prm_ram_w
);

logic [7:0] rxd, txd;
logic rxv, txv;

p10 p10_inst (
    .clk (clk),
    .rst (rst),

    .rxd (rxd),
    .rxv (rxv),

    .txd (txd),
    .txv (txv),
    .cts (cts),
 
    .prm_addr  (prm_addr),
    .prm_ram_d     (prm_ram_d),
    .prm_ram_q     (prm_ram_q),
    .prm_ram_w     (prm_ram_w)   
);

uart #(                            
    .DATA_WIDTH      (8),
    .STOP_BITS       (1),
    .PARITY          (PARITY_EN),
    .EVEN            (PARITY_EVEN),
    .PRESCALER       (REFCLK_MHZ*1000000/BAUDRATE),
    .LATCH_TOLERANCE (REFCLK_MHZ*200000/BAUDRATE)
) uart_inst (
    .clk_rx (clk),
    .clk_tx (clk),
    .rst    (rst),

	.rx     (rx),
	.tx     (tx),

	.txd    (txd),
	.txv    (txv),

	.rxd    (rxd),
	.rxv    (rxv),

	.rdy       (cts),
	.tx_active (tx_en)
);

endmodule
