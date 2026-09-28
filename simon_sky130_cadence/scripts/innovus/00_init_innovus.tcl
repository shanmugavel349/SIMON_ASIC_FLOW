# ==============================================================================
# File: 00_init_innovus.tcl
# Description: Stage 0 - Design Initialization, MMMC View Setup & Technology Loading.
# Tool: Cadence Innovus Implementation System
# Target: Configurable SIMON Core on SkyWater 130nm (sky130_fd_sc_hd)
# ==============================================================================

set SCRIPT_DIR [file dirname [file normalize [info script]]]
source "${SCRIPT_DIR}/../env_setup.tcl"

set TOP_MODULE "simon_top"

puts "=========================================================================="
puts "  INNOVUS STAGE 0: DESIGN INITIALIZATION & MMMC SETUP"
puts "=========================================================================="

# ------------------------------------------------------------------------------
# 1. Multi-Mode Multi-Corner (MMMC) Setup
# ------------------------------------------------------------------------------
# Create Library Sets
create_library_set -name libs_typical -timing [list $LIB_TT]
create_library_set -name libs_slow    -timing [list $LIB_SS]
create_library_set -name libs_fast    -timing [list $LIB_FF]

# Create RC Corners
create_rc_corner -name rc_typical -T 25  -cap_table $CAP_TABLE
create_rc_corner -name rc_slow    -T 100 -cap_table $CAP_TABLE
create_rc_corner -name rc_fast    -T -40 -cap_table $CAP_TABLE

# Create Delay Corners
create_delay_corner -name delay_corner_slow -library_set libs_slow -rc_corner rc_slow
create_delay_corner -name delay_corner_fast -library_set libs_fast -rc_corner rc_fast
create_delay_corner -name delay_corner_typ  -library_set libs_typical -rc_corner rc_typical

# Create Constraint Modes
create_constraint_mode -name constr_func -sdc_files [list "${SDC_DIR}/simon_core.sdc"]

# Create Analysis Views (Setup and Hold)
create_analysis_view -name view_func_setup -constraint_mode constr_func -delay_corner delay_corner_slow
create_analysis_view -name view_func_hold  -constraint_mode constr_func -delay_corner delay_corner_fast
create_analysis_view -name view_func_typ   -constraint_mode constr_func -delay_corner delay_corner_typ

# Set Active Analysis Views
set_analysis_view -setup [list view_func_setup view_func_typ] -hold [list view_func_hold]

# ------------------------------------------------------------------------------
# 2. Design Initialization Globals
# ------------------------------------------------------------------------------
set init_top_cell        $TOP_MODULE
set init_verilog         "${OUTPUT_DIR}/simon_top_synth.v"
set init_lef_file        [list $TECH_LEF $CELL_LEF]
set init_gnd_net         $GROUND_NET
set init_pwr_net         $POWER_NET

# Initialize Design Database
init_design

# ------------------------------------------------------------------------------
# 3. Global Power & Ground Pin Connections
# ------------------------------------------------------------------------------
clearGlobalNets
globalNetConnect $POWER_NET  -type pgpin -pin $POWER_PIN  -inst * -verbose
globalNetConnect $GROUND_NET -type pgpin -pin $GROUND_PIN -inst * -verbose
globalNetConnect $POWER_NET  -type tiehi -inst * -verbose
globalNetConnect $GROUND_NET -type tielo -inst * -verbose

puts "--- Stage 0 Completed Successfully ---"
