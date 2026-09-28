// ==============================================================================
// File: simon_key_schedule.v
// Description: Key Assembly (SIPO) and On-The-Fly Key Expansion Unit for the
//              Configurable SIMON Core (SIMON32/64 & SIMON64/128).
// ==============================================================================

`include "simon_defines.vh"

module simon_key_schedule (
    input  wire        clk,
    input  wire        rst_n,

    // Key Input Interface (32-bit time-multiplexed)
    input  wire [31:0] key_in,
    input  wire        key_load_en,
    input  wire [1:0]  load_cnt,

    // Configuration & Control
    input  wire        mode,         // 0: SIMON32/64, 1: SIMON64/128
    input  wire        enc_dec,      // 0: Encryption, 1: Decryption
    input  wire [6:0]  round_cnt,

    // Output Round Key
    output wire [31:0] current_round_key
);

    // -------------------------------------------------------------------------
    // 128-bit Key Assembly Register (SIPO)
    // -------------------------------------------------------------------------
    reg [127:0] master_key_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            master_key_reg <= 128'd0;
        end else if (key_load_en) begin
            if (mode == `MODE_SIMON32_64) begin
                // 64-bit key: 2 x 32-bit chunks
                case (load_cnt)
                    2'b00: master_key_reg[63:32] <= key_in;
                    2'b01: master_key_reg[31:0]  <= key_in;
                    default: ;
                endcase
            end else begin
                // 128-bit key: 4 x 32-bit chunks
                case (load_cnt)
                    2'b00: master_key_reg[127:96] <= key_in;
                    2'b01: master_key_reg[95:64]  <= key_in;
                    2'b10: master_key_reg[63:32]  <= key_in;
                    2'b11: master_key_reg[31:0]   <= key_in;
                endcase
            end
        end
    end

    // -------------------------------------------------------------------------
    // Simon Constant Sequences (z0 for 32/64, z3 for 64/128)
    // -------------------------------------------------------------------------
    wire [61:0] z0_seq = 62'b11111010001001010110000111001101111101000100101011000011100110;
    wire [61:0] z3_seq = 62'b11011011101011000110010111100000010010001010011100110100001111;

    // -------------------------------------------------------------------------
    // Unrolled Key Expansion for SIMON32/64 (32 words of 16-bit)
    // -------------------------------------------------------------------------
    wire [15:0] k16 [0:31];
    assign k16[0] = master_key_reg[15:0];
    assign k16[1] = master_key_reg[31:16];
    assign k16[2] = master_key_reg[47:32];
    assign k16[3] = master_key_reg[63:48];

    genvar g16;
    generate
        for (g16 = 4; g16 < 32; g16 = g16 + 1) begin : gen_simon32_keys
            wire [15:0] ror3_16 = {k16[g16-1][2:0], k16[g16-1][15:3]};
            wire [15:0] tmp1_16 = ror3_16 ^ k16[g16-3];
            wire [15:0] ror1_16 = {tmp1_16[0], tmp1_16[15:1]};
            wire [15:0] tmp2_16 = tmp1_16 ^ ror1_16;
            wire        z0_bit  = z0_seq[61 - ((g16 - 4) % 62)];
            assign k16[g16]     = k16[g16-4] ^ tmp2_16 ^ 16'hFFFC ^ {15'b0, z0_bit};
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Unrolled Key Expansion for SIMON64/128 (44 words of 32-bit)
    // -------------------------------------------------------------------------
    wire [31:0] k32 [0:43];
    assign k32[0] = master_key_reg[31:0];
    assign k32[1] = master_key_reg[63:32];
    assign k32[2] = master_key_reg[95:64];
    assign k32[3] = master_key_reg[127:96];

    genvar g32;
    generate
        for (g32 = 4; g32 < 44; g32 = g32 + 1) begin : gen_simon64_keys
            wire [31:0] ror3_32 = {k32[g32-1][2:0], k32[g32-1][31:3]};
            wire [31:0] tmp1_32 = ror3_32 ^ k32[g32-3];
            wire [31:0] ror1_32 = {tmp1_32[0], tmp1_32[31:1]};
            wire [31:0] tmp2_32 = tmp1_32 ^ ror1_32;
            wire        z3_bit  = z3_seq[61 - ((g32 - 4) % 62)];
            assign k32[g32]     = k32[g32-4] ^ tmp2_32 ^ 32'hFFFFFFFC ^ {31'b0, z3_bit};
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Effective Round Key Selection (Enc = Forward, Dec = Reverse)
    // -------------------------------------------------------------------------
    wire [5:0] idx32 = (enc_dec == `DIR_ENCRYPT) ? round_cnt[5:0] : (6'd31 - round_cnt[5:0]);
    wire [5:0] idx64 = (enc_dec == `DIR_ENCRYPT) ? round_cnt[5:0] : (6'd43 - round_cnt[5:0]);

    assign current_round_key = (mode == `MODE_SIMON32_64) ? {16'b0, k16[idx32[4:0]]} :
                                                            k32[idx64];

endmodule
