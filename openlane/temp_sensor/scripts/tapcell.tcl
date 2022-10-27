source $::env(DESIGN_DIR)/load.tcl
load_design $::env(CURRENT_DB) $::env(CURRENT_SDC) "Starting tapcell"

source $::env(DESIGN_DIR)/sky130hd/tapcell.tcl

write_def $::env(SAVE_DEF)
write_db $::env(SAVE_DB)
write_sdc $::env(SAVE_SDC)
