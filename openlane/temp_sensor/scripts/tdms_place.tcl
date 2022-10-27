source $::env(DESIGN_DIR)/load.tcl
load_design $::env(CURRENT_DB) $::env(CURRENT_SDC) "Starting TDMS placement"

proc find_macros {} {
  set macros ""

  set db [::ord::get_db]
  set block [[$db getChip] getBlock]
  foreach inst [$block getInsts] {
    set inst_master [$inst getMaster]

    # BLOCK means MACRO cells
    if { [string match [$inst_master getType] "BLOCK"] } {
      append macros " " $inst
    }
  }
  return $macros
}

set_dont_use $::env(DONT_USE_CELLS)

if {[find_macros] != ""} {
  if {[info exists ::env(RTLMP_FLOW)]} {
    puts "RTLMP flow enabled. Skipping tdms place."
  } else {
    puts "Dinesh-A: Placement Denisty: $::env(PLACE_DENSITY)"
    puts "Dinesh-A: CELL_PAD_IN_SITES_GLOBAL_PLACEMENT: $::env(CELL_PAD_IN_SITES_GLOBAL_PLACEMENT)"
    puts "Dinesh-A: CELL_PAD_IN_SITES_GLOBAL_PLACEMENT: $::env(CELL_PAD_IN_SITES_GLOBAL_PLACEMENT)"
    global_placement -density $::env(PLACE_DENSITY) \
                   -pad_left $::env(CELL_PAD_IN_SITES_GLOBAL_PLACEMENT) \
                   -pad_right $::env(CELL_PAD_IN_SITES_GLOBAL_PLACEMENT)
  }
} else {
  puts "No macros found: Skipping global_placement"
}

write_def $::env(SAVE_DEF)
write_db $::env(SAVE_DB)
write_sdc $::env(SAVE_SDC)
