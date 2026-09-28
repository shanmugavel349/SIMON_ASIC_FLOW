// ==============================================================================
// File: simon_defines.vh
// Description: Global parameters, mode encodings, and constants for the
//              Configurable SIMON Cryptographic Core.
// Architecture: Dual-mode SIMON32/64 and SIMON64/128 on SkyWater 130nm
// ==============================================================================

`ifndef SIMON_DEFINES_VH
`define SIMON_DEFINES_VH

// -----------------------------------------------------------------------------
// Mode Encodings
// -----------------------------------------------------------------------------
`define MODE_SIMON32_64    1'b0  // SIMON 32-bit Block / 64-bit Key
`define MODE_SIMON64_128   1'b1  // SIMON 64-bit Block / 128-bit Key

`define DIR_ENCRYPT        1'b0  // Encryption direction
`define DIR_DECRYPT        1'b1  // Decryption direction

// -----------------------------------------------------------------------------
// Datapath & Key Schedule Dimensional Constants
// -----------------------------------------------------------------------------
`define SIMON32_WORD_W     16    // Word size n = 16
`define SIMON32_BLOCK_W    32    // 2 * n = 32 bits
`define SIMON32_KEY_W      64    // 4 * n = 64 bits
`define SIMON32_ROUNDS     32    // 32 rounds for SIMON32/64
`define SIMON32_CHUNKS_DATA 2    // 2 x 16-bit chunks = 32 bits
`define SIMON32_CHUNKS_KEY  2    // 2 x 32-bit chunks = 64 bits

`define SIMON64_WORD_W     32    // Word size n = 32
`define SIMON64_BLOCK_W    64    // 2 * n = 64 bits
`define SIMON64_KEY_W      128   // 4 * n = 128 bits
`define SIMON64_ROUNDS     44    // 44 rounds for SIMON64/128 (NSA Standard)
`define SIMON64_CHUNKS_DATA 4    // 4 x 16-bit chunks = 64 bits
`define SIMON64_CHUNKS_KEY  4    // 4 x 32-bit chunks = 128 bits

`define MAX_ROUNDS         44    // Maximum round limit
`define MAX_KEY_EXP_WORDS  44    // Number of expanded key words

// -----------------------------------------------------------------------------
// I/O Interface Chunk Widths
// -----------------------------------------------------------------------------
`define DATA_BUS_W         16    // 16-bit data interface
`define KEY_BUS_W          32    // 32-bit key interface

// -----------------------------------------------------------------------------
// FSM States
// -----------------------------------------------------------------------------
`define ST_IDLE            3'd0  // Waiting for LOAD or START
`define ST_LOAD_DATA_KEY   3'd1  // Ingesting time-multiplexed chunks
`define ST_EXEC_ROUNDS     3'd2  // Iterative Feistel round execution
`define ST_OUT_FORMAT      3'd3  // Slicing result into 16-bit output stream
`define ST_DONE_ASSERT     3'd4  // Strobe completion flag and return

`endif // SIMON_DEFINES_VH
