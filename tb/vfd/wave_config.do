
onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -divider -height 20 {TESTBENCH}

add wave -noupdate -format Logic -radix unsigned tb/*

add wave -noupdate -divider -height 20 {DUT}

add wave -noupdate -format Logic -radix unsigned tb/dut/*

add wave -noupdate -divider -height 20 {NCO}

add wave -noupdate -format analog-step -radix decimal -min -1024.0 -max +1024.0 -height 64 -color "Azure"  tb/dut/nco_inst/I

add wave -noupdate -divider -height 20 {driver}

add wave -noupdate -format Logic -radix unsigned tb/dut/driver_inst/*



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
