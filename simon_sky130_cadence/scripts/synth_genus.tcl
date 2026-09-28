# ==============================================================================
# File: synth_genus.tcl
# Description: Production Logic Synthesis Script for Cadence Genus Synthesis Solution.
# Target: Configurable SIMON Core on SkyWater 130nm (sky130_fd_sc_hd)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Load Environment & Technology Configuration
# ------------------------------------------------------------------------------
set SCRIPT_DIR [file dirname [file normalize [info script]]]
source "${SCRIPT_DIR}/env_setup.tcl"

set TOP_MODULE "simon_top"

puts "=========================================================================="
puts "  STARTING CADENCE GENUS SYNTHESIS FOR: $TOP_MODULE"
puts "=========================================================================="

# ------------------------------------------------------------------------------
# 2. Setup Tool Attributes & Search Paths
# ------------------------------------------------------------------------------
set_db / .information_level 7
set_db / .hdl_error_on_blackbox true
set_db / .hdl_error_on_latch true

set_db init_lib_search_path [list "${SC_DIR}/lib" "${SC_DIR}/lef" "${TECH_DIR}"]
set_db init_hdl_search_path [list $RTL_DIR $SDC_DIR]

set_db target_library $TARGET_LIB
set_db link_library   $LINK_LIBS

if {[file exists $TECH_LEF] && [file exists $CELL_LEF]} {
    set_db lef_library [list $TECH_LEF $CELL_LEF]
}

# ------------------------------------------------------------------------------
# 3. Read & Elaborate RTL Architecture
# ------------------------------------------------------------------------------
puts "\n--- Reading RTL Source Files ---"
read_hdl -language v2001 -include_dir $RTL_DIR [list \
    "${RTL_DIR}/simon_control_fsm.v"  \
    "${RTL_DIR}/simon_key_schedule.v" \
    "${RTL_DIR}/simon_datapath.v"     \
    "${RTL_DIR}/simon_top.v"          \
]

puts "\n--- Elaborating Top Module: $TOP_MODULE ---"
elaborate $TOP_MODULE

# Design Consistency Checks
check_design -unresolved
check_design -all > "${REPORT_DIR}/genus_check_design_pre.rpt"

# ------------------------------------------------------------------------------
# 4. Apply Timing & Design Constraints
# ------------------------------------------------------------------------------
puts "\n--- Applying SDC Constraints ---"
read_sdc "${SDC_DIR}/simon_core.sdc"

check_timing_intent
check_timing_intent -verbose > "${REPORT_DIR}/genus_check_timing_intent.rpt"

# ------------------------------------------------------------------------------
# 5. Three-Stage Synthesis Optimization Flow
# ------------------------------------------------------------------------------
puts "\n--- Stage 1: Generic Synthesis ---"
set_db syn_generic_effort high
syn_generic

puts "\n--- Stage 2: Technology Mapping (sky130_fd_sc_hd) ---"
set_db syn_map_effort high
syn_map

puts "\n--- Stage 3: Incremental Timing & Area Optimization ---"
set_db syn_opt_effort high
syn_opt

# ------------------------------------------------------------------------------
# 6. Generate Comprehensive Sign-Off Reports
# ------------------------------------------------------------------------------
puts "\n--- Generating Synthesis Reports ---"
report_qor                                   > "${REPORT_DIR}/genus_qor.rpt"
report_timing -max_paths 50 -nworst 1       > "${REPORT_DIR}/genus_timing.rpt"
report_timing -lint                          > "${REPORT_DIR}/genus_timing_lint.rpt"
report_area -detail                          > "${REPORT_DIR}/genus_area.rpt"
report_power -detail                         > "${REPORT_DIR}/genus_power.rpt"
report_gates                                 > "${REPORT_DIR}/genus_gates.rpt"
report_hierarchy                             > "${REPORT_DIR}/genus_hierarchy.rpt"

# ------------------------------------------------------------------------------
# 7. Export Gate-Level Netlist & Constraint Checkpoints
# ------------------------------------------------------------------------------
puts "\n--- Exporting Gate-Level Netlist and SDC ---"
write_hdl -mapped                           > "${OUTPUT_DIR}/simon_top_synth.v"
write_sdc                                    > "${OUTPUT_DIR}/simon_top_synth.sdc"
write_db -all_root_attributes "${OUTPUT_DIR}/simon_top_synth.db"

puts "=========================================================================="
puts "  CADENCE GENUS SYNTHESIS COMPLETED SUCCESSFULLY!"
puts "  Gate-Level Netlist: ${OUTPUT_DIR}/simon_top_synth.v"
puts "  SDC Constraints:    ${OUTPUT_DIR}/simon_top_synth.sdc"
puts "  Reports Generated:  ${REPORT_DIR}/genus_*.rpt"
puts "=========================================================================="

exit
