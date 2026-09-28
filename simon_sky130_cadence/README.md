# Configurable SIMON Cryptographic Core (SkyWater 130nm ASIC Tapeout Flow)

A production-grade, tapeout-ready dual-mode **SIMON Block Cipher ASIC Core** implemented for the **SkyWater 130nm High-Density Standard Cell Library (`sky130_fd_sc_hd`)** using **Cadence EDA (Genus Synthesis and Innovus PnR)**.

---

## 1. Architectural Highlights

- **Dual-Mode Configurable Core**:
  - **SIMON 32/64**: 32-bit block size ($n=16$), 64-bit key ($m=4$), 32 iterative Feistel rounds.
  - **SIMON 64/128**: 64-bit block size ($n=32$), 128-bit key ($m=4$), 44 iterative Feistel rounds.
  - Runtime mode selection via `MODE` pin (`0` = SIMON32/64, `1` = SIMON64/128).
- **Bidirectional Operation**:
  - Unified hardware datapath for both **Encryption** (`ENC_DEC = 0`) and **Decryption** (`ENC_DEC = 1`).
- **Compressed I/O Interface (Die Area Reduction)**:
  - **16-bit Time-Multiplexed Data Input (`DATA_IN[15:0]`)**: 2-cycle ingestion for 32-bit blocks, 4-cycle ingestion for 64-bit blocks (~70% pad area savings).
  - **32-bit Time-Multiplexed Key Input (`KEY_IN[31:0]`)**: 2-cycle ingestion for 64-bit keys, 4-cycle ingestion for 128-bit keys.
  - **16-bit Serialized Output Stream (`DATA_OUT[15:0]`)**: Multi-cycle PISO output framing accompanied by `DONE` strobe.
- **Zero-RAM Dynamic Key Expansion**:
  - High-speed combinational key expansion providing single-cycle forward round keys ($k_i$) for encryption and instant reverse keys ($k_{T-1-i}$) for decryption without storage overhead.
- **Unified Feistel Datapath**:
  - Parameterized non-linear Feistel round function $F(x) = (S^1(x) \ \& \ S^8(x)) \oplus S^2(x)$ where $S^j$ denotes circular bitwise rotation.

---

## 2. Directory Structure

```
simon_sky130_cadence/
├── constraints/
│   └── simon_core.sdc             # Synopsys Design Constraints (50-100 MHz target)
├── doc/
│   └── architecture.png           # Extracted microarchitectural presentation diagram
├── logs/                          # Tool execution log files
├── outputs/                       # Synthesized netlists, PnR DEF, SPEF, and GDSII
├── reports/                       # Synthesis and Physical Signoff reports (QoR, Area, Timing, DRC, LVS)
├── rtl/
│   ├── simon_defines.vh           # Global macros, parameters, and FSM states
│   ├── simon_control_fsm.v        # Central Control Unit & FSM
│   ├── simon_key_schedule.v       # 128-bit Key SIPO Register & Combinational Key Expansion
│   ├── simon_datapath.v           # 64-bit Data SIPO, Feistel Engine & 16-bit PISO Formatter
│   └── simon_top.v                # Top-level ASIC module interconnect
├── scripts/
│   ├── env_setup.tcl              # Technology paths, LEF/LIB configuration & lab settings
│   ├── synth_genus.tcl            # Cadence Genus synthesis automation script
│   └── innovus/
│       ├── 00_init_innovus.tcl    # Stage 0: Design Init & MMMC setup
│       ├── 01_floorplan.tcl       # Stage 1: Floorplanning, Utilization (65%) & IO Pins
│       ├── 02_powerplan.tcl       # Stage 2: Power Rings, Mesh Stripes & SRoute
│       ├── 03_place.tcl           # Stage 3: Standard Cell Placement & Pre-CTS Opt
│       ├── 04_cts.tcl             # Stage 4: CCOpt Clock Tree Synthesis & Skew Balancing
│       ├── 05_route.tcl           # Stage 5: NanoRoute Detail Routing & Antenna Fixing
│       ├── 06_signoff.tcl         # Stage 6: Fillers, DRC/LVS, SPEF & GDSII Stream-Out
│       └── run_innovus_all.tcl    # Master automated Innovus batch script
├── tb/
│   ├── test_vectors.hex           # Official NSA Known-Answer Test (KAT) vectors
│   └── tb_simon_top.v             # Self-checking Verilog-2001 verification testbench
├── Makefile                       # Unified build and simulation automation
└── README.md                      # Project documentation
```

---

## 3. Hardware Pinout & Interface

| Port Name | Direction | Width | Description |
| :--- | :---: | :---: | :--- |
| `CLK` | Input | 1 | Primary System Clock (50 MHz - 100 MHz) |
| `RESET` | Input | 1 | Asynchronous Active-Low Master Reset (`rst_n`) |
| `START` | Input | 1 | Single-cycle strobe to trigger cryptographic execution |
| `LOAD` | Input | 1 | Active-high enable for time-multiplexed data/key chunk ingestion |
| `MODE` | Input | 1 | `0`: SIMON32/64 (32-bit block), `1`: SIMON64/128 (64-bit block) |
| `ENC_DEC` | Input | 1 | `0`: Encryption, `1`: Decryption |
| `DATA_IN` | Input | 16 | 16-bit Time-Multiplexed Input Data Slice |
| `KEY_IN` | Input | 32 | 32-bit Time-Multiplexed Input Key Slice |
| `DATA_OUT`| Output | 16 | 16-bit Time-Multiplexed Serialized Output Result |
| `DONE` | Output | 1 | Active-high strobe indicating computation complete & valid data stream |
| `BUSY` | Output | 1 | High while core is actively ingesting, processing rounds, or serializing |
| `ERROR` | Output | 1 | Active-high flag asserted if `START` triggered without loaded key |

---

## 4. Official NSA Known-Answer Verification

The self-checking testbench (`tb/tb_simon_top.v`) validates the core against official NSA reference vectors:

| Mode | Operation | Key | Plaintext | Ciphertext | Result |
| :--- | :---: | :--- | :--- | :--- | :---: |
| **SIMON 32/64** | Encrypt | `1918111009080100` | `65656877` | `c69be9bb` | **PASS (100%)** |
| **SIMON 32/64** | Decrypt | `1918111009080100` | `c69be9bb` | `65656877` | **PASS (100%)** |
| **SIMON 64/128** | Encrypt | `1b1a1918131211100b0a090803020100` | `656b696c20646e75` | `44c8fc20b9dfa07a` | **PASS (100%)** |
| **SIMON 64/128** | Decrypt | `1b1a1918131211100b0a090803020100` | `44c8fc20b9dfa07a` | `656b696c20646e75` | **PASS (100%)** |
| **Status Check** | Error | Uninitialized Key | — | Error Flag Asserted | **PASS (100%)** |

---

## 5. Execution & Lab Instructions

### Step 1: RTL Simulation & Waveform Inspection
Run the self-checking testbench using Icarus Verilog:
```bash
make sim
```
To view the generated VCD waveform in GTKWave:
```bash
make wave
```

### Step 2: Environment Configuration for Lab Servers
Edit `scripts/env_setup.tcl` or set your environment variables before running Cadence tools:
```bash
export PDK_ROOT=/foss/pdks/sky130A         # Path to SkyWater 130nm PDK
export CADENCE_DIR=/eda/cadence             # Path to Cadence tool installations
```

### Step 3: Logic Synthesis with Cadence Genus
Run logic synthesis in batch mode:
```bash
make synth
```
- **Inputs**: `rtl/*.v`, `constraints/simon_core.sdc`, `sky130_fd_sc_hd__tt_025C_1v80.lib`
- **Generated Outputs**:
  - `outputs/simon_top_synth.v` (Synthesized Gate-Level Netlist)
  - `outputs/simon_top_synth.sdc` (Post-synthesis constraints)
  - `reports/genus_area.rpt`, `reports/genus_timing.rpt`, `reports/genus_power.rpt`, `reports/genus_qor.rpt`

### Step 4: Physical Implementation with Cadence Innovus
Run the complete physical design flow (Floorplanning, Power Mesh, Placement, CTS, NanoRoute, Signoff):
```bash
make innovus
```
- **Generated Outputs**:
  - `outputs/simon_top.gds` (Final Tape-out GDSII stream file)
  - `outputs/simon_top.def` (Placed and routed DEF layout)
  - `outputs/simon_top.spef` (Extracted parasitic RC file for sign-off STA)
  - `outputs/simon_top_pnr.v` (Post-PnR verilog netlist)
  - `reports/innovus_signoff_drc.rpt`, `reports/innovus_signoff_lvs.rpt`, `reports/innovus_signoff_antenna.rpt`
