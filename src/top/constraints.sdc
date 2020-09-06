# create_clock -period 83.333 -name clk_12m -waveform {0 41.667} [get_ports clk_12m]
create_clock -period 20MHz -name clk_50m -waveform {0 25.000} [get_ports clk_50m]
derive_pll_clocks