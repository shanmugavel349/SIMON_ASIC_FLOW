# ==============================================================================
# File: env_setup.tcl
# Description: Central Environment & Technology Configuration Script for Cadence
#              Genus (Synthesis) and Cadence Innovus (Place & Route).
# Target: SkyWater 130nm Standard Cell Library (sky130_fd_sc_hd)
#
# LAB SERVER PORTABILITY GUIDE:
# ------------------------------------------------------------------------------
# Set the PDK_ROOT environment variable in your shell or override the default below:
#   export PDK_ROOT=/eda/cadence/pdks/sky130A
#   export CADENCE_DIR=/eda/cadence
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. PDK Directory Paths & Library Variants
# ------------------------------------------------------------------------------
if {[info exists env(PDK_ROOT)]} {
    set PDK_ROOT $env(PDK_ROOT)
} else {
    # Default open-source / university lab fallback path
    set PDK_ROOT "/foss/pdks/sky130A"
}

set LIB_NAME       "sky130_fd_sc_hd"
set SC_DIR         "${PDK_ROOT}/libs.ref/${LIB_NAME}"
set TECH_DIR       "${PDK_ROOT}/libs.tech"

# ------------------------------------------------------------------------------
# 2. Timing Libraries (.lib) for Multi-Mode Multi-Corner (MMMC) Analysis
# ------------------------------------------------------------------------------
set LIB_TT         "${SC_DIR}/lib/${LIB_NAME}__tt_025C_1v80.lib"
set LIB_SS         "${SC_DIR}/lib/${LIB_NAME}__ss_100C_1v60.lib"
set LIB_FF         "${SC_DIR}/lib/${LIB_NAME}__ff_n40C_1v95.lib"

# Default Target Synthesis Library (Typical Corner)
set TARGET_LIB     $LIB_TT
set LINK_LIBS      [list $LIB_TT]

# ------------------------------------------------------------------------------
# 3. Physical Layout Files (LEF, Tech LEF, Captable, GDS Layer Map)
# ------------------------------------------------------------------------------
set TECH_LEF       "${TECH_DIR}/openlane/${LIB_NAME}/tech.tlef"
if {![file exists $TECH_LEF]} {
    set TECH_LEF   "${SC_DIR}/techlef/${LIB_NAME}.tlef"
}

set CELL_LEF       "${SC_DIR}/lef/${LIB_NAME}.lef"
set GDS_MAP        "${TECH_DIR}/openlane/${LIB_NAME}/gds.map"
set CAP_TABLE      "${TECH_DIR}/captables/${LIB_NAME}.captable"

# ------------------------------------------------------------------------------
# 4. Standard Cell Special Function Definitions
# ------------------------------------------------------------------------------
# Well-tap and Endcap Cells
set WELLTAP_CELL   "sky130_fd_sc_hd__tapvpwrvgnd_1"
set ENDCAP_CELL    "sky130_fd_sc_hd__decap_3"

# Filler Cells for DRC Closure
set FILLER_CELLS   [list \
    sky130_fd_sc_hd__fill_8 \
    sky130_fd_sc_hd__fill_4 \
    sky130_fd_sc_hd__fill_2 \
    sky130_fd_sc_hd__fill_1 \
]

# Tie High / Tie Low Cells
set TIE_HI_CELL    "sky130_fd_sc_hd__conb_1"
set TIE_HI_PIN     "HI"
set TIE_LO_CELL    "sky130_fd_sc_hd__conb_1"
set TIE_LO_PIN     "LO"

# Clock Tree Buffer & Inverter Library
set CTS_CELLS      [list \
    sky130_fd_sc_hd__clkbuf_16 \
    sky130_fd_sc_hd__clkbuf_8  \
    sky130_fd_sc_hd__clkbuf_4  \
    sky130_fd_sc_hd__clkbuf_2  \
    sky130_fd_sc_hd__clkbuf_1  \
    sky130_fd_sc_hd__clkinv_16 \
    sky130_fd_sc_hd__clkinv_8  \
    sky130_fd_sc_hd__clkinv_4  \
    sky130_fd_sc_hd__clkinv_2  \
    sky130_fd_sc_hd__clkinv_1  \
]

# ------------------------------------------------------------------------------
# 5. Global Power and Ground Nets
# ------------------------------------------------------------------------------
set POWER_NET      "VDD"
set GROUND_NET     "VSS"
set POWER_PIN      "VPWR"
set GROUND_PIN     "VGND"

# ------------------------------------------------------------------------------
# 6. Project Directory Hierarchy
# ------------------------------------------------------------------------------
set PROJECT_DIR    [file normalize "[file dirname [info script]]/.."]
set RTL_DIR        "${PROJECT_DIR}/rtl"
set SDC_DIR        "${PROJECT_DIR}/constraints"
set REPORT_DIR     "${PROJECT_DIR}/reports"
set OUTPUT_DIR     "${PROJECT_DIR}/outputs"
set LOG_DIR        "${PROJECT_DIR}/logs"

file mkdir $REPORT_DIR
file mkdir $OUTPUT_DIR
file mkdir $LOG_DIR

puts "=========================================================================="
puts "  SIMON CORE ASIC FLOW - ENVIRONMENT SETUP INITIALIZED"
puts "  PDK Root:    $PDK_ROOT"
puts "  Library:     $LIB_NAME"
puts "  Target Lib:  $TARGET_LIB"
puts "  Tech LEF:    $TECH_LEF"
puts "  Cell LEF:    $CELL_LEF"
puts "=========================================================================="
