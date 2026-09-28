# ==============================================================================
# File: 03_place.tcl
# Description: Stage 3 - Standard Cell Placement & Pre-CTS Optimization.
# Tool: Cadence Innovus Implementation System
# Target: Configurable SIMON Core on SkyWater 130nm (sky130_fd_sc_hd)
# ==============================================================================

puts "=========================================================================="
puts "  INNOVUS STAGE 3: STANDARD CELL PLACEMENT & PRE-CTS OPTIMIZATION"
puts "=========================================================================="

# ------------------------------------------------------------------------------
# 1. Placement Mode & Engine Configuration
# ------------------------------------------------------------------------------
setPlaceMode -prerouteResourceBudget true \
             -timingDriven true           \
             -congEffort high             \
             -modulePlan true

# Set Tie-High / Tie-Low Insertion Mode
setTieHiLoMode -cell [list $TIE_HI_CELL] \
               -maxDistance 20           \
               -maxFanout 8

# ------------------------------------------------------------------------------
# 2. Execute Placement & Pre-CTS Timing Optimization
# ------------------------------------------------------------------------------
place_opt_design

# Add Tie-High and Tie-Low Cells
addTieHiLo -cell [list $TIE_HI_CELL] -prefix TIEHILO

# ------------------------------------------------------------------------------
# 3. Placement Quality & Timing Verification
# ------------------------------------------------------------------------------
checkPlace "${REPORT_DIR}/innovus_place_check.rpt"
reportCongestion -hotSpot

# Pre-CTS Timing Analysis
timeDesign -preCTS -expandedViews -outDir "${REPORT_DIR}/time_preCTS"

puts "--- Stage 3 Completed Successfully ---"
