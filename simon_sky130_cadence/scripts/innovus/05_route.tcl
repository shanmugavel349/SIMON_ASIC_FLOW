# ==============================================================================
# File: 05_route.tcl
# Description: Stage 5 - Global & Detailed Routing with NanoRoute, Antenna Fixing.
# Tool: Cadence Innovus Implementation System
# Target: Configurable SIMON Core on SkyWater 130nm (sky130_fd_sc_hd)
# ==============================================================================

puts "=========================================================================="
puts "  INNOVUS STAGE 5: NANOROUTE GLOBAL & DETAIL ROUTING"
puts "=========================================================================="

# ------------------------------------------------------------------------------
# 1. NanoRoute Configuration & Technology Layer Setup
# ------------------------------------------------------------------------------
setNanoRouteMode -quiet -routeBottomRoutingLayer 1 ;# met1
setNanoRouteMode -quiet -routeTopRoutingLayer    5 ;# met5

setNanoRouteMode -quiet -routeWithSiDriven        true
setNanoRouteMode -quiet -routeWithTimingDriven    true
setNanoRouteMode -quiet -routeWithSiPostRouteFix  true
setNanoRouteMode -quiet -routeAutoStop            false
setNanoRouteMode -quiet -drouteFixAntenna         true
setNanoRouteMode -quiet -routeInsertAntennaDiode  true

# ------------------------------------------------------------------------------
# 2. Execute Detail Routing
# ------------------------------------------------------------------------------
routeDesign

# ------------------------------------------------------------------------------
# 3. Post-Route Physical & Timing Optimization
# ------------------------------------------------------------------------------
optDesign -postRoute -setup -hold

# ------------------------------------------------------------------------------
# 4. Post-Route Timing Sign-Off
# ------------------------------------------------------------------------------
timeDesign -postRoute       -expandedViews -outDir "${REPORT_DIR}/time_postRoute"
timeDesign -postRoute -hold -expandedViews -outDir "${REPORT_DIR}/time_postRoute_hold"

puts "--- Stage 5 Completed Successfully ---"
