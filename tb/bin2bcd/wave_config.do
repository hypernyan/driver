
onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -divider -height 40 {TB}
add wave -noupdate -format Logic -radix hexadecimal tb/*
add wave -noupdate -divider -height 40 {BIN -> BCD}
add wave -noupdate -format Logic -radix hexadecimal tb/dut_bin2bcd/*

add wave -noupdate -divider -height 40 {BCD -> BIN}
add wave -noupdate -format Logic -radix hexadecimal tb/dut_bcd2bin/*

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
