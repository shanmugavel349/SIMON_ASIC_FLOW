# ==============================================================================
# Makefile: Production-Grade SIMON Core Tapeout Flow on SkyWater 130nm
# Tools: Icarus Verilog (Simulation), Cadence Genus (Synthesis), Cadence Innovus (PnR)
# ==============================================================================

# Project Directories
RTL_DIR      = rtl
TB_DIR       = tb
SCRIPTS_DIR  = scripts
CONSTR_DIR   = constraints
REPORTS_DIR  = reports
OUTPUTS_DIR  = outputs
LOGS_DIR     = logs

# Source Files
RTL_SRCS     = $(RTL_DIR)/simon_defines.vh \
               $(RTL_DIR)/simon_control_fsm.v \
               $(RTL_DIR)/simon_key_schedule.v \
               $(RTL_DIR)/simon_datapath.v \
               $(RTL_DIR)/simon_top.v

TB_SRCS      = $(TB_DIR)/tb_simon_top.v

# EDA Executables
IVERILOG     = iverilog
VVP          = vvp
GTKWAVE      = gtkwave
GENUS        = genus
INNOVUS      = innovus

.PHONY: all sim wave synth innovus clean distclean help

# Default Target
all: sim

# ------------------------------------------------------------------------------
# 1. RTL Simulation with Icarus Verilog & VVP
# ------------------------------------------------------------------------------
sim: sim_simon_top
	@echo ">>> Running RTL Verification Testbench..."
	@$(VVP) sim_simon_top

sim_simon_top: $(RTL_SRCS) $(TB_SRCS)
	@echo ">>> Compiling RTL and Testbench with Icarus Verilog..."
	@$(IVERILOG) -I $(RTL_DIR) -o sim_simon_top $(RTL_SRCS) $(TB_SRCS)

# ------------------------------------------------------------------------------
# 2. Waveform Viewing with GTKWave
# ------------------------------------------------------------------------------
wave: simon_top.vcd
	@echo ">>> Launching GTKWave on simon_top.vcd..."
	@$(GTKWAVE) simon_top.vcd &

# ------------------------------------------------------------------------------
# 3. Logic Synthesis with Cadence Genus
# ------------------------------------------------------------------------------
synth:
	@echo ">>> Starting Cadence Genus Logic Synthesis..."
	@mkdir -p $(LOGS_DIR) $(REPORTS_DIR) $(OUTPUTS_DIR)
	@$(GENUS) -f $(SCRIPTS_DIR)/synth_genus.tcl -log $(LOGS_DIR)/genus.log -overwrite

# ------------------------------------------------------------------------------
# 4. Place & Route with Cadence Innovus
# ------------------------------------------------------------------------------
innovus:
	@echo ">>> Starting Cadence Innovus Physical Implementation..."
	@mkdir -p $(LOGS_DIR) $(REPORTS_DIR) $(OUTPUTS_DIR)
	@$(INNOVUS) -nowin -files $(SCRIPTS_DIR)/innovus/run_innovus_all.tcl -log $(LOGS_DIR)/innovus.log -overwrite

# ------------------------------------------------------------------------------
# 5. Cleanups
# ------------------------------------------------------------------------------
clean:
	@echo ">>> Cleaning simulation artifacts and waveforms..."
	@rm -f sim_simon_top simon_top.vcd

distclean: clean
	@echo ">>> Cleaning all generated reports, outputs, logs, and checkpoints..."
	@rm -rf $(REPORTS_DIR)/* $(OUTPUTS_DIR)/* $(LOGS_DIR)/*
	@rm -rf genus.cmd* genus.log* innovus.cmd* innovus.log*

# ------------------------------------------------------------------------------
# 6. Help Menu
# ------------------------------------------------------------------------------
help:
	@echo "=========================================================================="
	@echo "  SIMON CRYPTOGRAPHIC CORE ASIC FLOW - MAKEFILE COMMANDS"
	@echo "=========================================================================="
	@echo "  make sim        : Compile and run self-checking testbench with iverilog"
	@echo "  make wave       : Open generated VCD waveform in GTKWave"
	@echo "  make synth      : Execute Cadence Genus logic synthesis"
	@echo "  make innovus    : Execute Cadence Innovus PnR tape-out flow"
	@echo "  make clean      : Remove simulation binary and waveform files"
	@echo "  make distclean  : Remove all synthesis & PnR generated files"
	@echo "=========================================================================="
