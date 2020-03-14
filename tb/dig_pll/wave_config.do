
onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -divider -height 20 {TESTBENCH}

add wave -noupdate -format analog-step -radix decimal -min -10.0 -max +10.0 -height 64 -color "Azure"  tb/u_load
add wave -noupdate -format analog-step -radix decimal -min -10.0 -max +10.0 -height 64 -color "Azure"  tb/u_ct
add wave -noupdate -format analog-step -radix decimal -min -10.0 -max +10.0 -height 64 -color "Azure"  tb/i
add wave -noupdate -format Logic -radix unsigned tb/adc_code
add wave -noupdate -format Logic -radix binary   tb/gate

add wave -noupdate -divider -height 20 {PLL}

add wave -noupdate -format Logic -radix unsigned tb/dig_pll_inst/*
add wave -noupdate -divider -height 20 {Peak and zero-cross}

add wave -noupdate -format Logic -radix unsigned tb/dig_pll_inst/zcpk_det_inst/*

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 201
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
update
WaveRestoreZoom {0 ps} {20 us}
