# SPDX-FileCopyrightText: 2020 Efabless Corporation
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
# SPDX-License-Identifier: Apache-2.0

set script_dir [file dirname [file normalize [info script]]]

set lef_root $::env(DESIGN_DIR)/../../lef/
set gds_root $::env(DESIGN_DIR)/../../gds/

set ::env(DESIGN_NAME) temp_sensor
set ::env(DESIGN_IS_CORE) 0

set ::env(VERILOG_FILES) "$::env(DESIGN_DIR)/../../verilog/rtl/temp_sensor/src/TEMP_ANALOG_hv.nl.v \
                          $::env(DESIGN_DIR)/../../verilog/rtl/temp_sensor/src/TEMP_ANALOG_lv.nl.v \
                          $::env(DESIGN_DIR)/../../verilog/rtl/temp_sensor/src/TEMP_AUTO_def.v \
                          $::env(DESIGN_DIR)/../../verilog/rtl/temp_sensor/src/counter.v \
                          $::env(DESIGN_DIR)/../../verilog/rtl/temp_sensor/src/temp_sensor.v \
                          $::env(DESIGN_DIR)/../../verilog/rtl/temp_sensor/src/temp_sensor.blackbox.v \
                          $::env(DESIGN_DIR)/../../verilog/rtl/lib/cells_clkgate_hd.v \
                         "


set ::env(EXTRA_LEFS) "\
	$lef_root/HEADER.lef \
	$lef_root/SLC.lef \
	"

set ::env(CLOCK_PORT) ""
set ::env(CLOCK_TREE_SYNTH) 0

# Synthesis
set ::env(SYNTH_READ_BLACKBOX_LIB) 1
set ::env(SYNTH_MAX_FANOUT) 6
set ::env(SYNTH_BUFFERING) 0
set ::env(SYNTH_SIZING) 0

# Timing configuration
set ::env(BASE_SDC_FILE) $::env(DESIGN_DIR)/base.sdc 

## Floorplan
#set ::env(FP_PIN_ORDER_CFG) $::env(DESIGN_DIR)/pin_order.cfg

#set ::env(MACRO_PLACEMENT_CFG) $::env(DESIGN_DIR)/macro.cfg

set ::env(FP_SIZING) absolute
set ::env(DIE_AREA) "0 0 155.48 146.88"
set ::env(CORE_AREA) "18.4 16.32 137.08 130.56"
set ::env(VD1_AREA) "33.58 32.64 64.86 62.56"

set ::env(SC_LEF) $::env(DESIGN_DIR)/sky130hd/lef/sky130_fd_sc_hd_merged.lef

set ::env(FP_PDN_ENABLE_MACROS_GRID) {1}
set ::env(FP_PDN_ENABLE_GLOBAL_CONNECTIONS) "1"
set ::env(VDD_PIN) {VDD}
set ::env(GND_PIN) {VSS}
set ::env(FP_PDN_CHECK_NODES) {0}
set ::env(FP_PDN_MACRO_HOOKS) " \
    temp_analog_0    VIN VSS VPWR  VGND, \
    temp_analog_0    VIN VSS VPB   VNB, \
	temp_analog_1    VDD VSS VPWR  VGND,\
	temp_analog_1    VDD VSS VPB   VNB,\
    "

#set ::env(TOP_MARGIN_MULT) 2
#set ::env(BOTTOM_MARGIN_MULT) 2

#LVS Issue - DEF Base looks to having issue
#set ::env(MAGIC_EXT_USE_GDS) {1}

set ::env(CELL_PAD)  0

set ::env(VDD_PIN) [list {VDD}]
set ::env(GND_PIN) [list {VSS}]


## Placement
set ::env(PL_TARGET_DENSITY) 0.82

## Routing 
#set ::env(GLB_RESIZER_TIMING_OPTIMIZATIONS) 0
#set ::env(GLB_RT_ADJUSTMENT) 0

set ::env(GLB_RT_MINLAYER) 2
set ::env(GLB_RT_MAXLAYER) 6

set ::env(PL_RESIZER_DESIGN_OPTIMIZATIONS) 0
set ::env(PL_RESIZER_TIMING_OPTIMIZATIONS) 0
set ::env(PL_RESIZER_BUFFER_INPUT_PORTS) 0
set ::env(PL_RESIZER_BUFFER_OUTPUT_PORTS) 0
set ::env(DIODE_INSERTION_STRATEGY) 0
#set ::env(FILL_INSERTION) 0
#set ::env(TAP_DECAP_INSERTION) 0
set ::env(CLOCK_TREE_SYNTH) 0

## Diode Insertion
#set ::env(DIODE_INSERTION_STRATEGY) "4"

## PDN 
set ::env(PDN_CFG) $::env(DESIGN_DIR)/pdn_cfg.tcl
set ::env(FP_PDN_VOFFSET) "5"
set ::env(FP_PDN_VPITCH) "40"
set ::env(FP_PDN_HOFFSET) "5"
set ::env(FP_PDN_HPITCH) "40"
set ::env(FP_PDN_HWIDTH) {6.2}
set ::env(FP_PDN_VWIDTH) {6.2}
set ::env(FP_PDN_HSPACING) {15}
set ::env(FP_PDN_VSPACING) {15}



set ::env(HAS_IO_CONSTRAINTS) {1}
set ::env(PLACE_PINS_ARGS)  {-random}

