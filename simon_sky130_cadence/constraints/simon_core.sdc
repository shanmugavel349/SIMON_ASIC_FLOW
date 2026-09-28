# ==============================================================================
# File: simon_core.sdc
# Description: Synopsys Design Constraints (SDC) for Configurable SIMON Core.
# Target Technology: SkyWater 130nm Standard Cell Library (sky130_fd_sc_hd)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Unit Definitions & Hierarchy Setup
# ------------------------------------------------------------------------------
current_design simon_top

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA

# ------------------------------------------------------------------------------
# 2. Master Clock Definition
# Target Frequency: 50.0 MHz (Period: 20.0 ns)
# High-Performance Corner Target: 100.0 MHz (Period: 10.0 ns)
# ------------------------------------------------------------------------------
set CLK_PERIOD 20.0
set CLK_PORT   [get_ports CLK]

create_clock -name sys_clk -period $CLK_PERIOD -waveform [list 0.0 [expr $CLK_PERIOD / 2.0]] $CLK_PORT

# Clock Uncertainty (Jitter + Margin)
set_clock_uncertainty -setup 0.300 [get_clocks sys_clk]
set_clock_uncertainty -hold  0.100 [get_clocks sys_clk]

# Clock Transition / Slew
set_clock_transition 0.150 [get_clocks sys_clk]

# ------------------------------------------------------------------------------
# 3. Input Port Constraints
# ------------------------------------------------------------------------------
set INPUT_PORTS [remove_from_collection [all_inputs] $CLK_PORT]

# Budget: 25% of clock period external delay (5.0 ns)
set IN_DELAY [expr 0.25 * $CLK_PERIOD]

set_input_delay -clock sys_clk -max $IN_DELAY $INPUT_PORTS
set_input_delay -clock sys_clk -min 0.500     $INPUT_PORTS

# Input Transition & Driving Cell Model
set_input_transition 0.150 $INPUT_PORTS

# ------------------------------------------------------------------------------
# 4. Output Port Constraints
# ------------------------------------------------------------------------------
set OUTPUT_PORTS [all_outputs]

# Budget: 25% of clock period external delay (5.0 ns)
set OUT_DELAY [expr 0.25 * $CLK_PERIOD]

set_output_delay -clock sys_clk -max $OUT_DELAY $OUTPUT_PORTS
set_output_delay -clock sys_clk -min 0.500      $OUTPUT_PORTS

# Output Load Capacitance (50 fF standard cell loading)
set_load -pin_load 0.050 $OUTPUT_PORTS

# ------------------------------------------------------------------------------
# 5. Design Rule Constraints (DRC Limits)
# ------------------------------------------------------------------------------
set_max_fanout 16 [current_design]
set_max_transition 1.500 [current_design]
set_max_capacitance 0.500 [current_design]

# ------------------------------------------------------------------------------
# 6. False Paths (Asynchronous Reset De-assertion)
# ------------------------------------------------------------------------------
set_false_path -from [get_ports RESET]
