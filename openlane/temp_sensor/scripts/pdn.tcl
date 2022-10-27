source $::env(DESIGN_DIR)/load.tcl
load_design $::env(CURRENT_DB) $::env(CURRENT_SDC) "Starting PDN generation"


# load the grid definitions
if {[catch {source $::env(PDN_CFG)} errmsg]} {
    puts stderr $errmsg
    exit 1
}

# run PDNGEN
if {[catch {pdngen} errmsg]} {
    puts stderr $errmsg
    exit 1
}



# Check all supply nets
#set block [ord::get_db_block]
#foreach net [$block getNets] {
#    set type [$net getSigType]
#    if {$type == "POWER" || $type == "GROUND"} {
## Temporarily disable due to CI issues
#        puts "Check supply: [$net getName]"
#        check_power_grid -net [$net getName]
#    }
#}

write_def $::env(SAVE_DEF)
write_db $::env(SAVE_DB)
write_sdc $::env(SAVE_SDC)
