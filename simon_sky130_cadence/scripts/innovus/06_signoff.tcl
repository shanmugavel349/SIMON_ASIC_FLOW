# ==============================================================================
# File: 06_signoff.tcl
# Description: Stage 6 - Filler Insertion, Physical Verification (DRC/LVS/Antenna),
#              Parasitic Extraction (SPEF), and GDSII Stream-Out.
# Tool: Cadence Innovus Implementation System
# Target: Configurable SIMON Core on SkyWater 130nm (sky130_fd_sc_hd)
# ==============================================================================

puts "=========================================================================="
puts "  INNOVUS STAGE 6: PHYSICAL VERIFICATION & TAPE-OUT SIGNOFF"
puts "=========================================================================="

# ------------------------------------------------------------------------------
# 1. Standard Cell Filler Insertion for DRC Density Closure
# ------------------------------------------------------------------------------
puts "\n--- Inserting Standard Cell Fillers ---"
addFiller -cell $FILLER_CELLS -prefix FILLER

# ------------------------------------------------------------------------------
# 2. Comprehensive Physical Verification Suite
# ------------------------------------------------------------------------------
puts "\n--- Running Physical Verification Checks ---"

# Design Rule Check (DRC)
verifyGeometry -report "${REPORT_DIR}/innovus_signoff_drc.rpt" \
               -error 1000

# Layout Versus Schematic (LVS Connectivity)
verifyConnectivity -type all \
                   -report "${REPORT_DIR}/innovus_signoff_lvs.rpt" \
                   -error 1000

# Process Antenna Rules
verifyProcessAntenna -report "${REPORT_DIR}/innovus_signoff_antenna.rpt" \
                     -error 1000

# Metal Density Verification
verifyMetalDensity -report "${REPORT_DIR}/innovus_signoff_density.rpt"

# ------------------------------------------------------------------------------
# 3. Final Sign-Off Timing Analysis
# ------------------------------------------------------------------------------
puts "\n--- Final Sign-Off Timing Analysis ---"
timeDesign -postRoute -expandedViews -outDir "${REPORT_DIR}/time_signoff"
timeDesign -postRoute -hold -expandedViews -outDir "${REPORT_DIR}/time_signoff_hold"

# Generate Area & Summary Reports
report_area -detail > "${REPORT_DIR}/innovus_final_area.rpt"
report_power        > "${REPORT_DIR}/innovus_final_power.rpt"
summaryReport       -outFile "${REPORT_DIR}/innovus_summary.rpt"

# ------------------------------------------------------------------------------
# 4. Parasitic RC Extraction (SPEF Generation)
# ------------------------------------------------------------------------------
puts "\n--- Extracting Parasitics (SPEF) ---"
extractRC
rcOut -spef "${OUTPUT_DIR}/simon_top.spef"

# ------------------------------------------------------------------------------
# 5. Export Gate-Level Netlist & DEF
# ------------------------------------------------------------------------------
puts "\n--- Exporting Final Physical & Logical Netlists ---"
# Physical Netlist (includes power/ground and physical cells)
saveNetlist "${OUTPUT_DIR}/simon_top_pnr_phys.v" -includePhysInst -includePowerGround

# Logical Netlist (for gate-level simulation)
saveNetlist "${OUTPUT_DIR}/simon_top_pnr.v"

# Design Exchange Format (DEF)
defOut -floorplan -netlist -routing "${OUTPUT_DIR}/simon_top.def"

# ------------------------------------------------------------------------------
# 6. Stream-Out Final GDSII Layout
# ------------------------------------------------------------------------------
puts "\n--- Streaming Out GDSII Layout ---"
set CELL_GDS "${SC_DIR}/gds/${LIB_NAME}.gds"

if {[file exists $GDS_MAP] && [file exists $CELL_GDS]} {
    streamOut "${OUTPUT_DIR}/simon_top.gds" \
              -mapFile $GDS_MAP \
              -merge [list $CELL_GDS] \
              -units 1000 \
              -mode ALL
} else {
    streamOut "${OUTPUT_DIR}/simon_top.gds" \
              -units 1000 \
              -mode ALL
}

# ------------------------------------------------------------------------------
# 7. Save Final Design Database Checkpoint
# ------------------------------------------------------------------------------
puts "\n--- Saving Final Innovus Database ---"
saveDesign "${OUTPUT_DIR}/simon_top_final.enc"

puts "=========================================================================="
puts "  CADENCE INNOVUS PHYSICAL IMPLEMENTATION COMPLETED SUCCESSFULLY!"
puts "  GDSII Layout:     ${OUTPUT_DIR}/simon_top.gds"
puts "  DEF File:         ${OUTPUT_DIR}/simon_top.def"
puts "  SPEF Parasitics:  ${OUTPUT_DIR}/simon_top.spef"
puts "  Post-PnR Netlist: ${OUTPUT_DIR}/simon_top_pnr.v"
puts "  Sign-Off Reports: ${REPORT_DIR}/innovus_*.rpt"
puts "=========================================================================="

exit
