source $::env(DESIGN_DIR)/load.tcl
load_design $::env(CURRENT_DB) $::env(CURRENT_SDC) "Starting global placement"

if {[info exists ::env(HAS_IO_CONSTRAINTS)] && $::env(HAS_IO_CONSTRAINTS) != 0} {
  puts "Has top down IO Constraints. Skip global placement without IOs"
} else {
# check the lower boundary of the PLACE_DENSITY and add PLACE_DENSITY_LB_ADDON if it exists
  if {[info exist ::env(PLACE_DENSITY_LB_ADDON)]} {
    set place_density_lb [gpl::get_global_placement_uniform_density \
    -pad_left $::env(CELL_PAD_IN_SITES_GLOBAL_PLACEMENT) \
    -pad_right $::env(CELL_PAD_IN_SITES_GLOBAL_PLACEMENT)]
    set place_density [expr $place_density_lb + $::env(PLACE_DENSITY_LB_ADDON) + 0.01]
    if {$place_density > 1.0} {
      set place_density 1.0
    }
  } else {
    set place_density $::env(PLACE_DENSITY)
  }

  if { 0 != [llength [array get ::env GLOBAL_PLACEMENT_ARGS]] } {
  global_placement -skip_io -density $place_density \
      -pad_left $::env(CELL_PAD_IN_SITES_GLOBAL_PLACEMENT) \
      -pad_right $::env(CELL_PAD_IN_SITES_GLOBAL_PLACEMENT) \
      $::env(GLOBAL_PLACEMENT_ARGS)
  } else {
  global_placement -skip_io -density $place_density \
      -pad_left $::env(CELL_PAD_IN_SITES_GLOBAL_PLACEMENT) \
      -pad_right $::env(CELL_PAD_IN_SITES_GLOBAL_PLACEMENT)
  }
}

write_def $::env(SAVE_DEF)
write_db $::env(SAVE_DB)
write_sdc $::env(SAVE_SDC)
