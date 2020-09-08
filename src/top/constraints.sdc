# create_clock -period 83.333 -name clk_12m -waveform {0 41.667} [get_ports clk_12m]
create_clock -period 125MHz -name phy_rx_clk -waveform {0 4} [get_ports phy_rx_clk]
derive_pll_clocks