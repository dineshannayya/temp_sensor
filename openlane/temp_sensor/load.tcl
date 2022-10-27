proc load_design {design_file sdc_file msg} {
  if {![info exists standalone] || $standalone} {
    # Read liberty files
    source $::env(DESIGN_DIR)/scripts/read_liberty.tcl

    # Read design files
    set ext [file extension $design_file]
    if {$ext == ".v"} {
      read_lef $::env(TECH_LEF)
      puts "Dinesh-A: Tech LEF : $::env(TECH_LEF)"
      read_lef $::env(SC_LEF)
      puts "Dinesh-A: SC LEF : $::env(SC_LEF)"
      if {[info exist ::env(EXTRA_LEFS)]} {
        foreach lef $::env(EXTRA_LEFS) {
          puts "Dinesh-A: Additional Lef : $lef"
          read_lef $lef
        }
      }
      read_verilog $design_file
      link_design $::env(DESIGN_NAME)
    } elseif {$ext == ".odb"} {
        #read_db $design_file
        if {[catch {read_lef $::env(MERGED_LEF)} errmsg]} {
           puts stderr $errmsg
           exit 1
        }
        if {[catch {read_def $::env(CURRENT_DEF)} errmsg]} {
            puts stderr $errmsg
            exit 1
        }

    } else {
      error "Unrecognized input file $design_file"
    }

    # Read SDC file
    read_sdc $sdc_file

    if [file exists $::env(DESIGN_DIR)/sky130hd/derate.tcl] {
      source $::env(DESIGN_DIR)/sky130hd/derate.tcl
    }

    source $::env(DESIGN_DIR)/sky130hd/setRC.tcl
  } else {
    puts $msg
  }
}
