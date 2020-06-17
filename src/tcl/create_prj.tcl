proc findFiles { basedir pattern } {
    set fileList {}
    set x {}
    foreach x $basedir {
        set x [string trimright [file join [file normalize $x] { }]]
    
        foreach fileName [glob -nocomplain -type {f r} -path $x $pattern] {
            lappend fileList $fileName
        }	
    
        foreach dirName [glob -nocomplain -type {d  r} -path $x *] {
            set subDirList [findFiles $dirName $pattern]
            if { [llength $subDirList] > 0 } {
                foreach subDirFile $subDirList {
	    			lappend fileList $subDirFile
                }
            }
        }
    }
    return $fileList
}

proc relTo {targetfile currentpath} {
  set cc [file split [file normalize $currentpath]]
  set tt [file split [file normalize $targetfile]]
  if {![string equal [lindex $cc 0] [lindex $tt 0]]} {
      # not on *n*x then
      return -code error "$targetfile not on same volume as $currentpath"
  }
  while {[string equal [lindex $cc 0] [lindex $tt 0]] && [llength $cc] > 0} {
      # discard matching components from the front
      set cc [lreplace $cc 0 0]
      set tt [lreplace $tt 0 0]
  }
  set prefix ""
  if {[llength $cc] == 0} {
      # just the file name, so targetfile is lower down (or in same place)
      set prefix "."
  }
  # step up the tree
  for {set i 0} {$i < [llength $cc]} {incr i} {
      append prefix " .."
  }
  # stick it all together (the eval is to flatten the targetfile list)
  return [eval file join $prefix $tt]
}

set TclPath [file dirname [file normalize [info script]]]
set NewLoc [string range $TclPath 0 [string last / $TclPath]-5]

set FamilyDev "Cyclobn 10 LP"
set PartDev "10CL025YU256C8G"
set MemDev "EPCS64"
set FlashLoadDev "10CL025Y"

set PrjDir  [string range $TclPath 0 [string last / $NewLoc]-1]
puts "Project location is: $PrjDir"

set TopName [string range $NewLoc [string last / $NewLoc]+1 end]
set PrjName $TopName.qpf
set TopDir $PrjDir/$TopName

lappend SrcDir $PrjDir/$TopName/src/top
lappend SrcDir $PrjDir/$TopName/src/verilog
lappend SrcDir $PrjDir/$TopName/p10/src
lappend SrcDir $PrjDir/$TopName/hdl_generics/src

set QuartusNm "quartus"
set SrcIncDir  $PrjDir/$TopName/src/include
set QuartusDir $PrjDir/$TopName/$QuartusNm

cd $PrjDir/$TopName

if {[file exists $QuartusNm] == 1} { file delete -force $QuartusNm }
file mkdir $QuartusNm
cd $QuartusDir

set SrcIncSV [findFiles $SrcIncDir "*.svh" ]
set SrcVHD   [findFiles $SrcDir "*.vhd"]
set SrcV     [findFiles $SrcDir "*.v"  ]
set SrcSV    [findFiles $SrcDir "*.sv" ]
set SrcQIP   [findFiles $SrcDir "*.qip"]
set SrcMIF   [findFiles $SrcDir "*.mif"]
set SrcSDC   [findFiles $SrcDir "*.sdc"]

set SrcIncSV_rel {}
set SrcVHD_rel {}
set SrcV_rel   {}
set SrcSV_rel  {}
set SrcQIP_rel {}
set SrcMIF_rel {}
set SrcSDC_rel {}

set x {}

foreach x $SrcIncSV {
	set x [relTo $x $QuartusDir]
	lappend SrcIncSV_rel $x
}

foreach x $SrcVHD {
	set x [relTo $x $QuartusDir]
	lappend SrcVHD_rel $x
}

foreach x $SrcV {
	set x [relTo $x $QuartusDir]
	lappend SrcV_rel $x
}

foreach x $SrcSV {
	set x [relTo $x $QuartusDir]
	lappend SrcSV_rel $x
}

foreach x $SrcQIP {
	set x [relTo $x $QuartusDir]
	lappend SrcQIP_rel $x
}

foreach x $SrcMIF {
	set x [relTo $x $QuartusDir]
	lappend SrcMIF_rel $x
}

foreach x $SrcSDC {
	set x [relTo $x $QuartusDir]
	lappend SrcSDC_rel $x
}

project_new $TopName -family $FamilyDev -part $PartDev -overwrite
project_open $TopName

set CurrentFile { } 
foreach CurrentFile $SrcIncSV_rel {
	# set_global_assignment -name SYSTEMVERILOG_FILE $CurrentFile
   # set_global_assignment -name SEARCH_PATH $SrcDir/include
	puts "Adding include search path for SV files: $CurrentFile"
}

set CurrentFile { } 
foreach CurrentFile $SrcVHD_rel {
	set_global_assignment -name VHDL_FILE $CurrentFile
	puts "Adding VHDL file: $CurrentFile"
}	
set CurrentFile { } 
foreach CurrentFile $SrcV_rel {
	set_global_assignment -name VERILOG_FILE $CurrentFile
	puts "Adding Verilog file: $CurrentFile"
}	
set CurrentFile { } 
foreach CurrentFile $SrcSV_rel {
	set_global_assignment -name SYSTEMVERILOG_FILE $CurrentFile
	puts "Adding SystemVerilog file: $CurrentFile"
}	
set CurrentFile { } 
foreach CurrentFile $SrcQIP_rel {
	set_global_assignment -name QIP_FILE $CurrentFile
	puts "Adding QIP file: $CurrentFile"
}	
foreach CurrentFile $SrcMIF_rel {
	set_global_assignment -name MIF_FILE $CurrentFile
	puts "Adding MIF file: $CurrentFile"
}
foreach CurrentFile $SrcSDC_rel {
	set_global_assignment -name SDC_FILE $CurrentFile
	puts "Adding SDC file: $CurrentFile"
}

cd $QuartusDir
load_package flow

# QSF settings
set_global_assignment -name FMAX_REQUIREMENT 125MHz
set_global_assignment -name TIMEQUEST_MULTICORNER_ANALYSIS ON
set_global_assignment -name SMART_RECOMPILE ON
set_global_assignment -name NUM_PARALLEL_PROCESSORS 6
set_global_assignment -name TOP_LEVEL_ENTITY top

source $TclPath/pins.tcl

execute_module -tool map
execute_module -tool fit
execute_module -tool asm
execute_module -tool sta

source $TclPath/jic.tcl
