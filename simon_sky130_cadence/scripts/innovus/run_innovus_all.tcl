# ==============================================================================
# File: run_innovus_all.tcl
# Description: Master Cadence Innovus Automation Script (Runs Stages 0-6 in Batch).
# Tool: Cadence Innovus Implementation System
# Target: Configurable SIMON Core on SkyWater 130nm (sky130_fd_sc_hd)
# ==============================================================================

set SCRIPT_DIR [file dirname [file normalize [info script]]]

puts "=========================================================================="
puts "  STARTING COMPLETE CADENCE INNOVUS PnR FLOW FOR SIMON TOP"
puts "=========================================================================="

# Stage 0: Design Init & MMMC
source "${SCRIPT_DIR}/00_init_innovus.tcl"

# Stage 1: Floorplanning
source "${SCRIPT_DIR}/01_floorplan.tcl"

# Stage 2: Power Planning & SRoute
source "${SCRIPT_DIR}/02_powerplan.tcl"

# Stage 3: Standard Cell Placement
source "${SCRIPT_DIR}/03_place.tcl"

# Stage 4: Clock Tree Synthesis (CCOpt)
source "${SCRIPT_DIR}/04_cts.tcl"

# Stage 5: NanoRoute Detail Routing
source "${SCRIPT_DIR}/05_route.tcl"

# Stage 6: Physical Verification & Tape-Out Signoff
source "${SCRIPT_DIR}/06_signoff.tcl"
