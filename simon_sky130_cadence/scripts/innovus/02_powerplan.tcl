# ==============================================================================
# File: 02_powerplan.tcl
# Description: Stage 2 - Power Network Synthesis (PNS), Rings, Stripes & SRoute.
# Tool: Cadence Innovus Implementation System
# Target: Configurable SIMON Core on SkyWater 130nm (sky130_fd_sc_hd)
# ==============================================================================

puts "=========================================================================="
puts "  INNOVUS STAGE 2: POWER NETWORK SYNTHESIS & SPECIAL ROUTING"
puts "=========================================================================="

# ------------------------------------------------------------------------------
# 1. Power & Ground Core Rings
# Top / Bottom: met5 (Horizontal)
# Left / Right: met4 (Vertical)
# ------------------------------------------------------------------------------
addRing -nets [list $POWER_NET $GROUND_NET] \
        -type core_rings \
        -follow core \
        -layer {top met5 bottom met5 left met4 right met4} \
        -width {top 2.4 bottom 2.4 left 2.4 right 2.4} \
        -spacing {top 1.0 bottom 1.0 left 1.0 right 1.0} \
        -offset {top 1.0 bottom 1.0 left 1.0 right 1.0}

# ------------------------------------------------------------------------------
# 2. Power & Ground Mesh Stripes
# Vertical Stripes on met4, Horizontal Stripes on met5
# ------------------------------------------------------------------------------
# Vertical Power & Ground Stripes (met4)
addStripe -nets [list $GROUND_NET $POWER_NET] \
          -layer met4 \
          -direction vertical \
          -width 1.2 \
          -spacing 1.0 \
          -set_to_set_distance 25.0 \
          -start_offset 10.0

# Horizontal Power & Ground Stripes (met5)
addStripe -nets [list $GROUND_NET $POWER_NET] \
          -layer met5 \
          -direction horizontal \
          -width 1.2 \
          -spacing 1.0 \
          -set_to_set_distance 25.0 \
          -start_offset 10.0

# ------------------------------------------------------------------------------
# 3. Special Routing (sroute) - Standard Cell Rail Connections
# Connects standard cell VPWR/VGND pins on met1 to power grid
# ------------------------------------------------------------------------------
sroute -connect { corePin } \
       -layerChangeRange { met1 met5 } \
       -blockPinTarget { nearestTarget } \
       -corePinTarget { firstAfterRowEnd } \
       -allowJogging 1 \
       -crossoverViaLayerRange { met1 met5 } \
       -nets [list $POWER_NET $GROUND_NET]

# ------------------------------------------------------------------------------
# 4. Power Grid Verification
# ------------------------------------------------------------------------------
verify_drc -geometry_only -report "${REPORT_DIR}/innovus_pns_drc.rpt"
verifyConnectivity -type special -report "${REPORT_DIR}/innovus_pns_conn.rpt"

puts "--- Stage 2 Completed Successfully ---"
