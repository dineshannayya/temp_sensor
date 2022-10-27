utl::set_metrics_stage "floorplan__{}"
puts "Dinesh-A: Step-1: Loading Start "
source $::env(DESIGN_DIR)/load.tcl
puts "Dinesh-A: Step-2: Loading End "
load_design $::env(CURRENT_NETLIST) $::env(CURRENT_SDC) "Starting floorplan"

set num_instances [llength [get_cells -hier *]]
puts "number instances in verilog is $num_instances"

# Initialize floorplan using ICeWall FOOTPRINT
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
  puts "Dinesh-A: Step-3: TEMP ANALOG "
  create_voltage_domain TEMP_ANALOG -area $::env(VD1_AREA)

  initialize_floorplan -die_area $::env(DIE_AREA) \
                       -core_area $::env(CORE_AREA) \
                       -site $::env(PLACE_SITE)

  source $::env(DESIGN_DIR)/read_domain_instances.tcl
  read_domain_instances TEMP_ANALOG $::env(DESIGN_DIR)/tempsenseInst_domain_insts.txt

  puts "Dinesh-A: Step-5: MAKE TRACKS tcl "
  source $::env(DESIGN_DIR)/sky130hd/make_tracks.tcl

# remove buffers inserted by yosys/abc
remove_buffers

puts "Default units for flow"
report_units
report_units_metric
source $::env(DESIGN_DIR)/report_metrics.tcl
report_metrics "floorplan final" false


write_def $::env(SAVE_DEF)
write_db $::env(SAVE_DB)
write_sdc $::env(SAVE_SDC)
