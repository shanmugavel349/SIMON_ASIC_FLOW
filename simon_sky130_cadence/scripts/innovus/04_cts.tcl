# ==============================================================================
# File: 04_cts.tcl
# Description: Stage 4 - Clock Tree Synthesis (CCOpt), Buffer Insertion & Skew Balancing.
# Tool: Cadence Innovus Implementation System (Concurrent Clock Optimization)
# Target: Configurable SIMON Core on SkyWater 130nm (sky130_fd_sc_hd)
# ==============================================================================

puts "=========================================================================="
puts "  INNOVUS STAGE 4: CLOCK TREE SYNTHESIS (CCOPT)"
puts "=========================================================================="

# ------------------------------------------------------------------------------
# 1. CCOpt Tree Specification & Property Setup
# ------------------------------------------------------------------------------
create_ccopt_clock_tree_spec

# Define CTS Buffers and Inverters from Sky130 HD Library
set_ccopt_property buffer_cells   $CTS_CELLS
set_ccopt_property inverter_cells $CTS_CELLS

# Skew and Transition Targets for 50 MHz - 100 MHz
set_ccopt_property target_skew       0.100 ;# 100 ps max skew
set_ccopt_property target_max_trans  0.300 ;# 300 ps max transition

# Clock Routing Rules
set_ccopt_property route_type_top_preferred_layer    met4
set_ccopt_property route_type_trunk_preferred_layer  met3
set_ccopt_property route_type_leaf_preferred_layer   met2

# ------------------------------------------------------------------------------
# 2. Execute Clock Tree Synthesis
# ------------------------------------------------------------------------------
ccopt_design

# ------------------------------------------------------------------------------
# 3. Post-CTS Timing & Hold Optimization
# ------------------------------------------------------------------------------
optDesign -postCTS -hold

# ------------------------------------------------------------------------------
# 4. Post-CTS Sign-Off Reports
# ------------------------------------------------------------------------------
report_ccopt_clock_trees -filename "${REPORT_DIR}/innovus_ccopt_clock_trees.rpt"
report_ccopt_skew_groups -filename "${REPORT_DIR}/innovus_ccopt_skew_groups.rpt"

# Post-CTS Setup and Hold Timing Verification
timeDesign -postCTS       -expandedViews -outDir "${REPORT_DIR}/time_postCTS"
timeDesign -postCTS -hold -expandedViews -outDir "${REPORT_DIR}/time_postCTS_hold"

puts "--- Stage 4 Completed Successfully ---"
