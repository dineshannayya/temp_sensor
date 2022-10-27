source $::env(DESIGN_DIR)/load.tcl
load_design $::env(CURRENT_DB) $::env(CURRENT_SDC) "Starting random IO placement"

if {[info exists ::env(IO_CONSTRAINTS)]} {
  source $::env(IO_CONSTRAINTS)
}
place_pins -hor_layer $::env(FP_IO_HLAYER) \
           -ver_layer $::env(FP_IO_VLAYER) \
           -random \
           {*}$::env(PLACE_PINS_ARGS)

write_def $::env(SAVE_DEF)
write_db $::env(SAVE_DB)
write_sdc $::env(SAVE_SDC)
