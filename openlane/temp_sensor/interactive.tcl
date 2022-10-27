#!/usr/bin/env tclsh
# Copyright 2020-2022 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
package require openlane; # provides the utils as well

proc run_placement_step {args} {

    global_placement_or

   if { [info exists ::env(PL_TARGET_DENSITY_CELLS)] } {
        set ::env(PL_TARGET_DENSITY) $old_pl_target_density
    }

    run_resizer_design
    remove_buffers_from_nets

    detailed_placement_or -def $::env(placement_results)/$::env(DESIGN_NAME).def -log $::env(placement_logs)/detailed.log

    scrot_klayout -layout $::env(CURRENT_DEF) -log $::env(placement_logs)/screenshot.log

#   
#    # |----------------------------------------------------|
#    # |----------------   3.8 global_place          -------|
#    # |----------------------------------------------------|
#    set ::env(CURRENT_STAGE) placement
#    increment_index
#    TIMER::timer_start
#    set log [index_file $::env(placement_logs)/global_place.log]
#:
#    set ::env(SAVE_DEF) [index_file $::env(placement_tmpfiles)/global_place.def]
#    set ::env(SAVE_DB) [index_file $::env(placement_tmpfiles)/global_place.odb]
#    set ::env(SAVE_SDC) [index_file $::env(placement_tmpfiles)/global_place.sdc]
#    set ::env(report_prefix) [index_file $::env(placement_reports)/global_place]
#
#    run_openroad_script ./scripts/global_place.tcl 
#
#    TIMER::timer_stop
#    exec echo "[TIMER::get_runtime]" | python3 $::env(SCRIPTS_DIR)/write_runtime.py "PDN - openroad"
#    set_def $::env(SAVE_DEF)
#    set ::env(CURRENT_SDC) $::env(SAVE_SDC)
#    set ::env(CURRENT_DB) $::env(SAVE_DB)
#
#Run_openroad_script ./scripts/detail_place.tcl


}


proc global_placement_or {args} {
    increment_index
    TIMER::timer_start
    set log [index_file $::env(placement_logs)/global.log]
    puts_info "Running Global Placement (log: [relpath . $log])..."

    set ::env(SAVE_DEF) [index_file $::env(placement_tmpfiles)/global.def]

    # random initial placement
    if { $::env(PL_RANDOM_INITIAL_PLACEMENT) } {
        random_global_placement
        set ::env(PL_SKIP_INITIAL_PLACEMENT) 1
    }

    run_openroad_script $::env(SCRIPTS_DIR)/openroad/gpl.tcl -indexed_log $log

    # sometimes replace fails with a ZERO exit code; the following is a workaround
    # until the cause is found and fixed
    if { ! [file exists $::env(SAVE_DEF)] } {
        puts_err "Global placement has failed to produce a DEF file."
        flow_fail
    }

    check_replace_divergence

    TIMER::timer_stop
    exec echo "[TIMER::get_runtime]" | python3 $::env(SCRIPTS_DIR)/write_runtime.py "global placement - openroad"
    set_def $::env(SAVE_DEF)
}



proc run_cts_step {args} {
    if { ! [ info exists ::env(CTS_CURRENT_DEF) ] } {
        set ::env(CTS_CURRENT_DEF) $::env(CURRENT_DEF)
    } else {
        set ::env(CURRENT_DEF) $::env(CTS_CURRENT_DEF)
    }

    run_cts
    run_resizer_timing
}

proc run_routing_step {args} {
    if { ! [ info exists ::env(ROUTING_CURRENT_DEF) ] } {
        set ::env(ROUTING_CURRENT_DEF) $::env(CURRENT_DEF)
    } else {
        set ::env(CURRENT_DEF) $::env(ROUTING_CURRENT_DEF)
    }
    if { $::env(ECO_ENABLE) == 0 } {
        run_routing
    }
}

proc run_parasitics_sta_step {args} {
    if { ! [ info exists ::env(PARSITICS_CURRENT_DEF) ] } {
        set ::env(PARSITICS_CURRENT_DEF) $::env(CURRENT_DEF)
    } else {
        set ::env(CURRENT_DEF) $::env(PARSITICS_CURRENT_DEF)
    }

    if { $::env(RUN_SPEF_EXTRACTION) && ($::env(ECO_ENABLE) == 0)} {
        run_parasitics_sta
    }
}

proc run_diode_insertion_2_5_step {args} {
    if { ! [ info exists ::env(DIODE_INSERTION_CURRENT_DEF) ] } {
        set ::env(DIODE_INSERTION_CURRENT_DEF) $::env(CURRENT_DEF)
    } else {
        set ::env(CURRENT_DEF) $::env(DIODE_INSERTION_CURRENT_DEF)
    }
    if { ($::env(DIODE_INSERTION_STRATEGY) == 2) || ($::env(DIODE_INSERTION_STRATEGY) == 5) } {
        run_antenna_check
        heal_antenna_violators; # modifies the routed DEF
    }

}

proc run_irdrop_report_step {args} {
    #if { $::env(RUN_IRDROP_REPORT) } {
    #    run_irdrop_report
    #}
}

proc run_lvs_step {{ lvs_enabled 1 }} {
    if { ! [ info exists ::env(LVS_CURRENT_DEF) ] } {
        set ::env(LVS_CURRENT_DEF) $::env(CURRENT_DEF)
    } else {
        set ::env(CURRENT_DEF) $::env(LVS_CURRENT_DEF)
    }

    if { $lvs_enabled && $::env(RUN_LVS) } {
        run_magic_spice_export;
        run_lvs; # requires run_magic_spice_export
    }

}

proc run_drc_step {{ drc_enabled 1 }} {
    if { ! [ info exists ::env(DRC_CURRENT_DEF) ] } {
        set ::env(DRC_CURRENT_DEF) $::env(CURRENT_DEF)
    } else {
        set ::env(CURRENT_DEF) $::env(DRC_CURRENT_DEF)
    }
    if { $drc_enabled } {
        if { $::env(RUN_MAGIC_DRC) } {
            run_magic_drc
        }
        if {$::env(RUN_KLAYOUT_DRC)} {
            run_klayout_drc
        }
    }
}

proc run_antenna_check_step {{ antenna_check_enabled 1 }} {
    if { ! [ info exists ::env(ANTENNA_CHECK_CURRENT_DEF) ] } {
        set ::env(ANTENNA_CHECK_CURRENT_DEF) $::env(CURRENT_DEF)
    } else {
        set ::env(CURRENT_DEF) $::env(ANTENNA_CHECK_CURRENT_DEF)
    }
    if { $antenna_check_enabled } {
        run_antenna_check
    }
}

proc run_eco_step {args} {
    if { $::env(ECO_ENABLE) == 1 } {
        run_eco_flow
    }
}

proc run_magic_step {args} {
    if {$::env(RUN_MAGIC)} {
        run_magic
    }
}

proc run_klayout_step {args} {
    if {$::env(RUN_KLAYOUT)} {
        run_klayout
    }
    if {$::env(RUN_KLAYOUT_XOR)} {
        run_klayout_gds_xor
    }
}

proc run_post_run_hooks {} {
    if { [file exists $::env(DESIGN_DIR)/hooks/post_run.py]} {
        puts_info "Running post run hook"
        set result [exec $::env(OPENROAD_BIN) -python $::env(DESIGN_DIR)/hooks/post_run.py]
        puts_info "$result"
    } else {
        puts_info "hooks/post_run.py not found, skipping"
    }
}

proc run_magic_drc_batch {args} {
    set options {
        {-magicrc optional}
        {-tech optional}
        {-report required}
        {-design required}
        {-gds required}
    }
    set flags {}
    parse_key_args "run_magic_drc_batch" args arg_values $options flags_mag $flags
    if { [info exists arg_values(-magicrc)] } {
        set magicrc [file normalize $arg_values(-magicrc)]
    }
    if { [info exists arg_values(-tech)] } {
        set ::env(TECH) [file normalize $arg_values(-tech)]
    }
    set ::env(GDS_INPUT) [file normalize $arg_values(-gds)]
    set ::env(REPORT_OUTPUT) [file normalize $arg_values(-report)]
    set ::env(DESIGN_NAME) $arg_values(-design)

    if { [info exists magicrc] } {
        exec magic \
            -noconsole \
            -dnull \
            -rcfile $magicrc \
            $::env(OPENLANE_ROOT)/scripts/magic/drc_batch.tcl \
            </dev/null |& tee /dev/tty
    } else {
        exec magic \
            -noconsole \
            -dnull \
            $::env(OPENLANE_ROOT)/scripts/magic/drc_batch.tcl \
            </dev/null |& tee /dev/tty
    }
}

proc run_lvs_batch {args} {
    # runs device level lvs on -gds/CURRENT_GDS and -net/CURRENT_NETLIST
    # extracts gds only if EXT_NETLIST does not exist
    set options {
        {-design required}
        {-gds optional}
        {-net optional}
    }
    set flags {}
    parse_key_args "run_lvs_batch" args arg_values $options flags_lvs $flags -no_consume

    prep {*}$args

    if { [info exists arg_values(-gds)] } {
        set ::env(CURRENT_GDS) [file normalize $arg_values(-gds)]
    } else {
        set ::env(CURRENT_GDS) $::env(signoff_results)/$::env(DESIGN_NAME).gds
    }
    if { [info exists arg_values(-net)] } {
        set ::env(CURRENT_NETLIST) [file normalize $arg_values(-net)]
    }

    assert_files_exist "$::env(CURRENT_GDS) $::env(CURRENT_NETLIST)"

    set ::env(MAGIC_EXT_USE_GDS) 1
    set ::env(EXT_NETLIST) $::env(signoff_results)/$::env(DESIGN_NAME).gds.spice
    if { [file exists $::env(EXT_NETLIST)] } {
        puts_warn "The file $::env(EXT_NETLIST) will be used. If you would like the file re-exported, please delete it."
    } else {
        run_magic_spice_export
    }

    run_lvs
}


proc run_file {args} {
    set ::env(TCLLIBPATH) $::auto_path
    exec tclsh {*}$args >&@stdout
}

proc run_floorplan {args} {

    # |----------------------------------------------------|
    # |----------------   2. FLOORPLAN   ------------------|
    # |----------------------------------------------------|
    increment_index
    puts_info "Starting Floor Plan..."

    TIMER::timer_start
    set log [index_file $::env(floorplan_logs)/floorplan.log]

    set ::env(SAVE_DEF) [index_file $::env(floorplan_tmpfiles)/initial_fp.def]
    set ::env(SAVE_DB) [index_file $::env(floorplan_tmpfiles)/initial_fp.odb]
    set ::env(SAVE_SDC) [index_file $::env(floorplan_tmpfiles)/initial_fp.sdc]
    set ::env(fp_report_prefix) [index_file $::env(floorplan_reports)/initial_fp]

    run_openroad_script $::env(DESIGN_DIR)/floorplan.tcl -metrics $::env(DESIGN_DIR)/2_1_floorplan.json -indexed_log $log

    TIMER::timer_stop
    exec echo "[TIMER::get_runtime]" | python3 $::env(SCRIPTS_DIR)/write_runtime.py "floorplan initialization - openroad"
    set_def $::env(SAVE_DEF)
    set ::env(CURRENT_SDC) $::env(SAVE_SDC)
    set ::env(CURRENT_DB) $::env(SAVE_DB)

    # |----------------------------------------------------|
    # |----------------   3.1 IP Placement ----------------|
    # |----------------------------------------------------|
    increment_index
    puts_info "Starting IO Placement..."
    
    TIMER::timer_start
    set log [index_file $::env(floorplan_logs)/io_placement.log]
    
    set ::env(SAVE_DEF) [index_file $::env(floorplan_tmpfiles)/io_placement.def]
    set ::env(SAVE_DB) [index_file $::env(floorplan_tmpfiles)/io_placement.odb]
    set ::env(SAVE_SDC) [index_file $::env(floorplan_tmpfiles)/io_placement.sdc]
    set ::env(fp_report_prefix) [index_file $::env(floorplan_reports)/io_placement]

    run_openroad_script $::env(DESIGN_DIR)/scripts/io_placement_random.tcl -indexed_log $log
    
    TIMER::timer_stop
    exec echo "[TIMER::get_runtime]" | python3 $::env(SCRIPTS_DIR)/write_runtime.py " IO Placement - openroad"
    set_def $::env(SAVE_DEF)
    set ::env(CURRENT_SDC) $::env(SAVE_SDC)
    set ::env(CURRENT_DB) $::env(SAVE_DB)


    # |----------------------------------------------------|
    # |----------------   3.2 TDMS placement  -------------|
    # |----------------------------------------------------|
    set ::env(CURRENT_STAGE) placement
    increment_index
    puts_info "Starting TDMS placement ...."
    TIMER::timer_start
    set log [index_file $::env(placement_logs)/tdms_place.log]

    set ::env(SAVE_DEF) [index_file $::env(placement_tmpfiles)/tdms_place.def]
    set ::env(SAVE_DB) [index_file $::env(placement_tmpfiles)/tdms_place.odb]
    set ::env(SAVE_SDC) [index_file $::env(placement_tmpfiles)/tdms_place.sdc]
    set ::env(report_prefix) [index_file $::env(placement_reports)/tdms_place]

    run_openroad_script  $::env(DESIGN_DIR)/scripts/tdms_place.tcl  -indexed_log $log

    TIMER::timer_stop
    exec echo "[TIMER::get_runtime]" | python3 $::env(SCRIPTS_DIR)/write_runtime.py "Placement - openroad"
    set_def $::env(SAVE_DEF)
    set ::env(CURRENT_SDC) $::env(SAVE_SDC)
    set ::env(CURRENT_DB) $::env(SAVE_DB)
    
    # |----------------------------------------------------|
    # |----------------   3.3 MACRO placement  ------------|
    # |----------------------------------------------------|
    set ::env(CURRENT_STAGE) placement
    increment_index
    puts_info "Starting MACRO placement ...."
    TIMER::timer_start
    set log [index_file $::env(placement_logs)/macro_place.log]

    set ::env(SAVE_DEF) [index_file $::env(placement_tmpfiles)/macro_place.def]
    set ::env(SAVE_DB) [index_file $::env(placement_tmpfiles)/macro_place.odb]
    set ::env(SAVE_SDC) [index_file $::env(placement_tmpfiles)/macro_place.sdc]
    set ::env(report_prefix) [index_file $::env(placement_reports)/macro_place]

    run_openroad_script  $::env(DESIGN_DIR)/scripts/macro_place.tcl  -indexed_log $log

    TIMER::timer_stop
    exec echo "[TIMER::get_runtime]" | python3 $::env(SCRIPTS_DIR)/write_runtime.py "Placement - openroad"
    set_def $::env(SAVE_DEF)
    set ::env(CURRENT_SDC) $::env(SAVE_SDC)
    set ::env(CURRENT_DB) $::env(SAVE_DB)

    # |----------------------------------------------------|
    # |----------------   3.4 tapcell  --------------------|
    # |----------------------------------------------------|
    tap_decap_or

    # |----------------------------------------------------|
    # |----------------   3.5 PDN      --------------------|
    # |----------------------------------------------------|
    set ::env(CURRENT_STAGE) placement
    increment_index
    puts_info "Starting PDN ...."
    TIMER::timer_start
    set log [index_file $::env(placement_logs)/pdn.log]

    set ::env(SAVE_DEF) [index_file $::env(placement_tmpfiles)/pdn.def]
    set ::env(SAVE_DB) [index_file $::env(placement_tmpfiles)/pdn.odb]
    set ::env(SAVE_SDC) [index_file $::env(placement_tmpfiles)/pdn.sdc]
    set ::env(report_prefix) [index_file $::env(placement_reports)/pdn]

    run_openroad_script  $::env(DESIGN_DIR)/scripts/pdn.tcl  -indexed_log $log

    TIMER::timer_stop
    exec echo "[TIMER::get_runtime]" | python3 $::env(SCRIPTS_DIR)/write_runtime.py "PDN - openroad"
    set_def $::env(SAVE_DEF)
    set ::env(CURRENT_SDC) $::env(SAVE_SDC)
    set ::env(CURRENT_DB) $::env(SAVE_DB)


    #run_power_grid_generation

    # |----------------------------------------------------|
    # |----------------   3.7 io_placement          -------|
    # |----------------------------------------------------|
    # place io
    if { [info exists ::env(FP_PIN_ORDER_CFG)] } {
        place_io_ol
    } else {
        if { [info exists ::env(FP_CONTEXT_DEF)] && [info exists ::env(FP_CONTEXT_LEF)] } {
            place_io
            global_placement_or
            place_contextualized_io \
                -lef $::env(FP_CONTEXT_LEF) \
                -def $::env(FP_CONTEXT_DEF)
        } else {
            place_io
        }
    }

    #init_floorplan

    ## check for deprecated io variables
    #if { [info exists ::env(FP_IO_HMETAL)]} {
    #    set ::env(FP_IO_HLAYER) [lindex $::env(TECH_METAL_LAYERS) [expr {$::env(FP_IO_HMETAL) - 1}]]
    #    puts_warn "You're using FP_IO_HMETAL in your configuration, which is a deprecated variable that will be removed in the future."
    #    puts_warn "We recommend you update your configuration as follows:"
    #    puts_warn "\tset ::env(FP_IO_HLAYER) {$::env(FP_IO_HLAYER)}"
    #}

    #if { [info exists ::env(FP_IO_VMETAL)]} {
    #    set ::env(FP_IO_VLAYER) [lindex $::env(TECH_METAL_LAYERS) [expr {$::env(FP_IO_VMETAL) - 1}]]
    #    puts_warn "You're using FP_IO_VMETAL in your configuration, which is a deprecated variable that will be removed in the future."
    #    puts_warn "We recommend you update your configuration as follows:"
    #    puts_warn "\tset ::env(FP_IO_VLAYER) {$::env(FP_IO_VLAYER)}"
    #}


    #apply_def_template

    #if { [info exist ::env(EXTRA_LEFS)] } {
    #    if { [info exist ::env(MACRO_PLACEMENT_CFG)] } {
    #        file copy -force $::env(MACRO_PLACEMENT_CFG) $::env(placement_tmpfiles)/macro_placement.cfg
    #        manual_macro_placement -f
    #    } else {
    #        global_placement_or
    #        basic_macro_placement
    #    }
    #}


    scrot_klayout -layout $::env(CURRENT_DEF) -log $::env(floorplan_logs)/screenshot.log

    #run_power_grid_generation



}




proc run_flow {args} {
    set options {
        {-design optional}
        {-from optional}
        {-to optional}
        {-save_path optional}
        {-override_env optional}
    }
    set flags {-save -run_hooks -no_lvs -no_drc -no_antennacheck -gui}
    parse_key_args "run_non_interactive_mode" args arg_values $options flags_map $flags -no_consume

    prep {*}$args
    # signal trap SIGINT save_state;

    if { [info exists flags_map(-gui)] } {
        or_gui
        return
    }
    if { [info exists arg_values(-override_env)] } {
        load_overrides $arg_values(-override_env)
    }

    set LVS_ENABLED 1
    set DRC_ENABLED 1

    set ANTENNACHECK_ENABLED [expr ![info exists flags_map(-no_antennacheck)] ]

    set steps [dict create \
        "synthesis" "run_synthesis" \
        "floorplan" "run_floorplan"  \
        "placement" "run_placement_step" \
        "cts" "run_cts_step" \
        "routing" "run_routing_step" \
        "parasitics_sta" "run_parasitics_sta_step" \
        "eco" "run_eco_step" \
        "diode_insertion" "run_diode_insertion_2_5_step" \
        "irdrop" "run_irdrop_report_step" \
        "gds_magic" "run_magic_step" \
        "gds_klayout" "run_klayout_step" \
        "lvs" "run_lvs_step $LVS_ENABLED "
        #"drc" "run_drc_step $DRC_ENABLED " \
        #"antenna_check" "run_antenna_check_step $ANTENNACHECK_ENABLED " \
        #"cvc" "run_lef_cvc"
    ]

    if { [info exists arg_values(-from) ]} {
        puts_info "Starting flow at $arg_values(-from)..."
        set ::env(CURRENT_STEP) $arg_values(-from)
    } elseif {  [info exists ::env(CURRENT_STEP) ] } {
        puts_info "Resuming flow from $::env(CURRENT_STEP)..."
    } else {
        set ::env(CURRENT_STEP) "synthesis"
    }

    set_if_unset arg_values(-from) $::env(CURRENT_STEP)
    set_if_unset arg_values(-to) "cvc"

    set exe 0;
    dict for {step_name step_exe} $steps {
        if { [ string equal $arg_values(-from) $step_name ] } {
            set exe 1;
        }

        if { $exe } {
            # For when it fails
            set ::env(CURRENT_STEP) $step_name
            [lindex $step_exe 0] [lindex $step_exe 1] ;
        }

        if { [ string equal $arg_values(-to) $step_name ] } {
            set exe 0:
            break;
        }

    }

    # for when it resumes
    set steps_as_list [dict keys $steps]
    set next_idx [expr [lsearch $steps_as_list $::env(CURRENT_STEP)] + 1]
    set ::env(CURRENT_STEP) [lindex $steps_as_list $next_idx]

    # Saves to <RUN_DIR>/results/final
    save_final_views

    # Saves to design directory or custom
    if {  [info exists flags_map(-save) ] } {
        if { ! [info exists arg_values(-save_path)] } {
            set arg_values(-save_path) $::env(DESIGN_DIR)
        }
        save_final_views\
            -save_path $arg_values(-save_path)\
            -tag $::env(RUN_TAG)
    }
    calc_total_runtime
    save_state
    generate_final_summary_report

    check_timing_violations

    if { [info exists arg_values(-save_path)]\
        && $arg_values(-save_path) != "" } {
        set ::env(HOOK_OUTPUT_PATH) "[file normalize $arg_values(-save_path)]"
    } else {
        set ::env(HOOK_OUTPUT_PATH) $::env(RESULTS_DIR)/final
    }

    if {[info exists flags_map(-run_hooks)]} {
        run_post_run_hooks
    }

    puts_success "Flow complete."

    show_warnings "Note that the following warnings have been generated:"
}

run_flow {*}$argv
