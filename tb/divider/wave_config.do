
onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -divider -height 20 {TESTBENCH}

add wave -noupdate -format Logic -radix unsigned tb/rst
add wave -noupdate -format Logic -radix unsigned tb/clk

add wave -noupdate -format Logic -radix unsigned tb/dut/fsm
add wave -noupdate -format Logic -radix binary tb/dut/dvd
add wave -noupdate -format Logic -radix binary tb/dut/dvs
add wave -noupdate -format Logic -radix binary tb/dut/quo
add wave -noupdate -format Logic -radix binary tb/dut/cmp
add wave -noupdate -format Logic -radix binary tb/dut/dvd_reg


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
