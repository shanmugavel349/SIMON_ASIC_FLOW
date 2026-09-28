// ==============================================================================
// File: simon_datapath.v
// Description: Data Assembly (SIPO), Iterative Round Engine, and Output
//              Formatter (PISO) for the Configurable SIMON Core.
// ==============================================================================

`include "simon_defines.vh"

module simon_datapath (
    input  wire        clk,
    input  wire        rst_n,

    // External Data Input (16-bit time-multiplexed)
    input  wire [15:0] data_in,
    input  wire        data_load_en,
    input  wire [1:0]  load_cnt,

    // Configuration & Control
    input  wire        mode,         // 0: SIMON32/64, 1: SIMON64/128
    input  wire        enc_dec,      // 0: Encryption, 1: Decryption
    input  wire        round_init,   // Initializes L, R registers from data_reg
    input  wire        round_en,     // Enables round calculation register update
    input  wire [31:0] current_round_key,
    input  wire        out_format_en,
    input  wire [1:0]  out_cnt,

    // Output Formatted Data (16-bit)
    output reg  [15:0] data_out
);

    // -------------------------------------------------------------------------
    // 64-bit Data Input Assembly Register (SIPO)
    // -------------------------------------------------------------------------
    reg [63:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 64'd0;
        end else if (data_load_en) begin
            if (mode == `MODE_SIMON32_64) begin
                case (load_cnt)
                    2'b00: data_reg[31:16] <= data_in; // Left word
                    2'b01: data_reg[15:0]  <= data_in; // Right word
                    default: ;
                endcase
            end else begin
                case (load_cnt)
                    2'b00: data_reg[63:48] <= data_in; // Left word [31:16]
                    2'b01: data_reg[47:32] <= data_in; // Left word [15:0]
                    2'b10: data_reg[31:16] <= data_in; // Right word [31:16]
                    2'b11: data_reg[15:0]  <= data_in; // Right word [15:0]
                endcase
            end
        end
    end

    // -------------------------------------------------------------------------
    // Round Working Registers (L and R)
    // -------------------------------------------------------------------------
    reg [31:0] reg_L;
    reg [31:0] reg_R;

    // -------------------------------------------------------------------------
    // SIMON Non-Linear Feistel Function F(x) = (S^1(x) & S^8(x)) ^ S^2(x)
    // -------------------------------------------------------------------------
    // For n=16 (SIMON32/64)
    function [15:0] f_function_16(input [15:0] x);
        reg [15:0] rot1;
        reg [15:0] rot8;
        reg [15:0] rot2;
        begin
            rot1 = {x[14:0], x[15]};
            rot8 = {x[7:0],  x[15:8]};
            rot2 = {x[13:0], x[15:14]};
            f_function_16 = (rot1 & rot8) ^ rot2;
        end
    endfunction

    // For n=32 (SIMON64/128)
    function [31:0] f_function_32(input [31:0] x);
        reg [31:0] rot1;
        reg [31:0] rot8;
        reg [31:0] rot2;
        begin
            rot1 = {x[30:0], x[31]};
            rot8 = {x[23:0], x[31:24]};
            rot2 = {x[29:0], x[31:30]};
            f_function_32 = (rot1 & rot8) ^ rot2;
        end
    endfunction

    // -------------------------------------------------------------------------
    // Feistel Step Combinational Logic
    // -------------------------------------------------------------------------
    reg [31:0] next_L;
    reg [31:0] next_R;

    always @(*) begin
        if (mode == `MODE_SIMON32_64) begin
            if (enc_dec == `DIR_ENCRYPT) begin
                // Encrypt: L_next = R ^ F(L) ^ k, R_next = L
                next_L = {16'b0, reg_R[15:0] ^ f_function_16(reg_L[15:0]) ^ current_round_key[15:0]};
                next_R = {16'b0, reg_L[15:0]};
            end else begin
                // Decrypt: R_next = L ^ F(R) ^ k, L_next = R
                next_L = {16'b0, reg_R[15:0]};
                next_R = {16'b0, reg_L[15:0] ^ f_function_16(reg_R[15:0]) ^ current_round_key[15:0]};
            end
        end else begin
            if (enc_dec == `DIR_ENCRYPT) begin
                // Encrypt: L_next = R ^ F(L) ^ k, R_next = L
                next_L = reg_R ^ f_function_32(reg_L) ^ current_round_key;
                next_R = reg_L;
            end else begin
                // Decrypt: R_next = L ^ F(R) ^ k, L_next = R
                next_L = reg_R;
                next_R = reg_L ^ f_function_32(reg_R) ^ current_round_key;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Sequential Round Register Updates
    // -------------------------------------------------------------------------
    reg [63:0] result_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_L      <= 32'd0;
            reg_R      <= 32'd0;
            result_reg <= 64'd0;
        end else if (round_init) begin
            if (mode == `MODE_SIMON32_64) begin
                reg_L <= {16'b0, data_reg[31:16]};
                reg_R <= {16'b0, data_reg[15:0]};
            end else begin
                reg_L <= data_reg[63:32];
                reg_R <= data_reg[31:0];
            end
        end else if (round_en) begin
            reg_L <= next_L;
            reg_R <= next_R;

            // Latch current round output into result register
            if (mode == `MODE_SIMON32_64) begin
                result_reg[31:0] <= {next_L[15:0], next_R[15:0]};
            end else begin
                result_reg <= {next_L, next_R};
            end
        end
    end

    // -------------------------------------------------------------------------
    // Output Formatter & PISO Serialization
    // -------------------------------------------------------------------------
    always @(*) begin
        if (mode == `MODE_SIMON32_64) begin
            case (out_cnt)
                2'b00:   data_out = result_reg[31:16];
                2'b01:   data_out = result_reg[15:0];
                default: data_out = 16'd0;
            endcase
        end else begin
            case (out_cnt)
                2'b00:   data_out = result_reg[63:48];
                2'b01:   data_out = result_reg[47:32];
                2'b10:   data_out = result_reg[31:16];
                2'b11:   data_out = result_reg[15:0];
                default: data_out = 16'd0;
            endcase
        end
    end

endmodule
