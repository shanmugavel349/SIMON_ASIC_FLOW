// ==============================================================================
// File: simon_top.v
// Description: Top-Level Module for Configurable SIMON Cryptographic Core.
// Features: 16-bit time-multiplexed data interface, 32-bit key interface,
//           dual-mode runtime configurability (SIMON32/64 & SIMON64/128),
//           unified Feistel iterative datapath, and status handshakes.
// Target: SkyWater 130nm Standard Cell Library (sky130_fd_sc_hd)
// ==============================================================================

`include "simon_defines.vh"

module simon_top (
    // Clock and Reset
    input  wire        CLK,          // Primary System Clock
    input  wire        RESET,        // Asynchronous Active-Low Reset (rst_n)

    // Control & Configuration Inputs
    input  wire        START,        // Strobe to trigger cryptographic operation
    input  wire        LOAD,         // Active-high enable for chunk ingestion
    input  wire        MODE,         // 0: SIMON32/64, 1: SIMON64/128
    input  wire        ENC_DEC,      // 0: Encryption, 1: Decryption

    // Time-Multiplexed Data & Key Input Buses
    input  wire [15:0] DATA_IN,      // 16-bit Data Input Slice
    input  wire [31:0] KEY_IN,       // 32-bit Key Input Slice

    // Output Interface & Status Flags
    output wire [15:0] DATA_OUT,     // 16-bit Serialized Output Data Slice
    output wire        DONE,         // Operation complete / Data valid strobe
    output wire        BUSY,         // Core active processing flag
    output wire        ERROR         // Error flag (e.g. START without valid key)
);

    // Active-low internal reset alias
    wire rst_n = RESET;

    // -------------------------------------------------------------------------
    // Internal Interconnect Wires
    // -------------------------------------------------------------------------
    wire [2:0]  current_state;
    wire [1:0]  load_cnt;
    wire [1:0]  out_cnt;
    wire [6:0]  round_cnt;
    wire        data_load_en;
    wire        key_load_en;
    wire        round_init;
    wire        round_en;
    wire        out_format_en;
    wire [31:0] current_round_key;

    // -------------------------------------------------------------------------
    // Submodule 1: Control Unit & Finite State Machine
    // -------------------------------------------------------------------------
    simon_control_fsm u_control_fsm (
        .clk           (CLK),
        .rst_n         (rst_n),
        .start         (START),
        .load          (LOAD),
        .mode          (MODE),
        .enc_dec       (ENC_DEC),
        .current_state (current_state),
        .load_cnt      (load_cnt),
        .out_cnt       (out_cnt),
        .round_cnt     (round_cnt),
        .data_load_en  (data_load_en),
        .key_load_en   (key_load_en),
        .round_init    (round_init),
        .round_en      (round_en),
        .out_format_en (out_format_en),
        .done          (DONE),
        .busy          (BUSY),
        .error         (ERROR)
    );

    // -------------------------------------------------------------------------
    // Submodule 2: Key Assembly & On-The-Fly Key Expansion Unit
    // -------------------------------------------------------------------------
    simon_key_schedule u_key_schedule (
        .clk               (CLK),
        .rst_n             (rst_n),
        .key_in            (KEY_IN),
        .key_load_en       (key_load_en),
        .load_cnt          (load_cnt),
        .mode              (MODE),
        .enc_dec           (ENC_DEC),
        .round_cnt         (round_cnt),
        .current_round_key (current_round_key)
    );

    // -------------------------------------------------------------------------
    // Submodule 3: Data Assembly, Feistel Datapath & Output Formatter
    // -------------------------------------------------------------------------
    simon_datapath u_datapath (
        .clk               (CLK),
        .rst_n             (rst_n),
        .data_in           (DATA_IN),
        .data_load_en      (data_load_en),
        .load_cnt          (load_cnt),
        .mode              (MODE),
        .enc_dec           (ENC_DEC),
        .round_init        (round_init),
        .round_en          (round_en),
        .current_round_key (current_round_key),
        .out_format_en     (out_format_en),
        .out_cnt           (out_cnt),
        .data_out          (DATA_OUT)
    );

endmodule
