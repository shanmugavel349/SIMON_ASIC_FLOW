# ==============================================================================
# File: 01_floorplan.tcl
# Description: Stage 1 - Floorplanning, Core Utilization, Margin Setup & Pin Placement.
# Tool: Cadence Innovus Implementation System
# Target: Configurable SIMON Core on SkyWater 130nm (sky130_fd_sc_hd)
# ==============================================================================

puts "=========================================================================="
puts "  INNOVUS STAGE 1: FLOORPLANNING & PHYSICAL MARGINS"
puts "=========================================================================="

# ------------------------------------------------------------------------------
# 1. Define Core Area, Utilization & Margins
# Target Utilization: 65% (balanced for congestion & routability)
# Aspect Ratio: 1.0 (Square Die)
# Margins: 10.0 um on all 4 boundaries (Left, Bottom, Right, Top)
# ------------------------------------------------------------------------------
floorPlan -site unithd -r 1.0 0.65 10.0 10.0 10.0 10.0

# ------------------------------------------------------------------------------
# 2. IO Pin Placement Strategy
# Distribute input and output buses evenly across die perimeter
# ------------------------------------------------------------------------------
# Left Edge: Clock, Reset, Control Inputs (START, LOAD, MODE, ENC_DEC)
# Bottom Edge: 16-bit DATA_IN Bus
# Top Edge: 32-bit KEY_IN Bus
# Right Edge: 16-bit DATA_OUT Bus & Status Flags (DONE, BUSY, ERROR)

editPin -layer met3 -pin {CLK RESET START LOAD MODE ENC_DEC} -edge 0 -spreadType CENTER
editPin -layer met3 -pin {DATA_IN[*]}                        -edge 1 -spreadType CENTER
editPin -layer met3 -pin {DATA_OUT[*] DONE BUSY ERROR}       -edge 2 -spreadType CENTER
editPin -layer met3 -pin {KEY_IN[*]}                         -edge 3 -spreadType CENTER

# ------------------------------------------------------------------------------
# 3. Add Well-Tap and Endcap Physical Cells
# ------------------------------------------------------------------------------
# Endcap cells around core rows
addEndCap -preCap  $ENDCAP_CELL \
          -postCap $ENDCAP_CELL \
          -prefix  ENDCAP

# Well-tap cells placed in a checkerboard pattern every 20 um (Sky130 DRC rule)
addWellTap -cell          $WELLTAP_CELL \
           -cellInterval  20.0          \
           -prefix        WELLTAP

# ------------------------------------------------------------------------------
# 4. Check Floorplan Quality
# ------------------------------------------------------------------------------
checkFloorplan
checkPinAssignment

puts "--- Stage 1 Completed Successfully ---"
