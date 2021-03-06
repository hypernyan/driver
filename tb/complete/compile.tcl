puts {
  ModelSimSE general compile script version 1.1
  Copyright (c) Doulos June 2004, SD
}

# Simply change the project settings in this section
# for each new project. There should be no need to
# modify the rest of the script.

set library_file_list {
		design_library {

		}
		test_library {
			../../src/verilog/comp/true_dpram_sclk.sv
			../../src/verilog/comp/onehot.sv
      		../../src/verilog/comp/bin2bcd.sv
			../../src/verilog/comp/fifo.sv
			../../src/verilog/comp/int_divider.sv
			../../src/verilog/comp/mem_arb.sv
			../../src/verilog/comp/reset_controller.sv
			../../src/verilog/comp/spi.sv


			../../sim/adc_sim.sv
			../../sim/config_serial_sim.sv
			../../sim/rlc_sim.sv
			../../sim/spi_pot_sim.sv
			../../src/verilog/com/p10.sv
			../../src/verilog/com/p10_serial.sv
			../../src/verilog/com/uart_rx.v
			../../src/verilog/com/uart_tx.v
			../../src/verilog/com/uart.v

			../../src/verilog/drv/adc_ctrl.sv
			../../src/verilog/drv/agc.sv
			../../src/verilog/drv/dig_pll.sv
			../../src/verilog/drv/fixed_driver.sv
			../../src/verilog/drv/hilbert_transform.sv
			../../src/verilog/drv/manual_control.sv
			../../src/top/hdl.sv
			tb.sv
		}
}

set dut_wave_do wave_config.do

set top_level test_library.tb

set wave_patterns {
	/*
}

set wave_radices {
	/*
}

set waveWinName [ view wave -undock ]
set waveTopLevel [winfo toplevel $waveWinName]
puts $library_file_list

# After sourcing the script from ModelSim for the
# first time use these commands to recompile.

proc r  {} {uplevel #0 source compile.tcl}
proc rr {} {global last_compile_time
            set last_compile_time 0
            r                            }
proc q  {} {quit -force                  }

#Does this installation support Tk?
set tk_ok 1
if [catch {package require Tk}] {set tk_ok 0}

# Prefer a fixed point font for the transcript
set PrefMain(font) {Courier 10 roman normal}

# Compile out of date files
set time_now [clock seconds]
if [catch {set last_compile_time}] {
  set last_compile_time 0
}
foreach {library file_list} $library_file_list {
  vlib $library
  vmap work $library
  foreach file $file_list {
    if { $last_compile_time < [file mtime $file] } {
      if [regexp {.vhdl?$} $file] {
        vcom -93 $file
      } else {
        vlog $file
      }
      set last_compile_time 0
    }
  }
}
set last_compile_time $time_now

# Load the simulation
eval vsim -novopt  $top_level

# If waves are required
#if [llength $wave_patterns] {
#  noview wave
#  foreach pattern $wave_patterns {
#    add wave $pattern
#  }
#  configure wave -signalnamewidth 1
#  foreach {radix signals} $wave_radices {
#    foreach signal $signals {
#      catch {property wave -radix $radix $signal}
#    }
#  }
#  if $tk_ok {wm geometry $waveTopLevel [winfo screenwidth .]x[winfo screenheight .]+0+0}
#}

do $dut_wave_do

# Run the simulation
run 20000000

# If waves are required

if [llength $wave_patterns] {
  if $tk_ok {wave zoom full}
}


