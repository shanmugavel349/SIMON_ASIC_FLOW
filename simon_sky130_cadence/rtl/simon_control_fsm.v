// ==============================================================================
// File: simon_control_fsm.v
// Description: Central Control Unit & Finite State Machine (FSM) for the
//              Configurable SIMON Cryptographic Core.
// ==============================================================================

`include "simon_defines.vh"

module simon_control_fsm (
    input  wire        clk,
    input  wire        rst_n,

    // External Control Handshake
    input  wire        start,
    input  wire        load,
    input  wire        mode,        // 0: SIMON32/64, 1: SIMON64/128
    input  wire        enc_dec,     // 0: Encryption, 1: Decryption

    // Control Outputs to Submodules
    output reg  [2:0]  current_state,
    output reg  [1:0]  load_cnt,
    output reg  [1:0]  out_cnt,
    output reg  [6:0]  round_cnt,
    output wire        data_load_en,
    output wire        key_load_en,
    output reg         round_init,
    output reg         round_en,
    output reg         out_format_en,

    // External Status Signals
    output reg         done,
    output reg         busy,
    output reg         error
);

    reg [2:0] next_state;
    reg       key_is_ready;

    wire [1:0] max_chunks = (mode == `MODE_SIMON32_64) ? 2'd1 : 2'd3;
    wire [6:0] max_rounds = (mode == `MODE_SIMON32_64) ? 7'd32 : 7'd44;

    assign data_load_en = load;
    assign key_load_en  = load;

    // -------------------------------------------------------------------------
    // Sequential State Register & Counters
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= `ST_IDLE;
            load_cnt      <= 2'b00;
            out_cnt       <= 2'b00;
            round_cnt     <= 7'd0;
            key_is_ready  <= 1'b0;
            error         <= 1'b0;
        end else begin
            current_state <= next_state;

            // Error Flag Tracking
            if (current_state == `ST_IDLE && start && !key_is_ready) begin
                error <= 1'b1;
            end else if (load || (start && key_is_ready)) begin
                error <= 1'b0;
            end

            // Chunk Load Counter
            if (load) begin
                if (load_cnt == max_chunks) begin
                    load_cnt     <= 2'b00;
                    key_is_ready <= 1'b1;
                end else begin
                    load_cnt <= load_cnt + 1'b1;
                end
            end else begin
                load_cnt <= 2'b00;
            end

            // Round Execution Counter
            if (current_state == `ST_EXEC_ROUNDS) begin
                round_cnt <= round_cnt + 1'b1;
            end else begin
                round_cnt <= 7'd0;
            end

            // Output Serialization Counter
            if (current_state == `ST_OUT_FORMAT) begin
                if (out_cnt == max_chunks)
                    out_cnt <= 2'b00;
                else
                    out_cnt <= out_cnt + 1'b1;
            end else begin
                out_cnt <= 2'b00;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Next State Combinational Logic
    // -------------------------------------------------------------------------
    always @(*) begin
        next_state = current_state;

        case (current_state)
            `ST_IDLE: begin
                if (start && key_is_ready) begin
                    next_state = `ST_EXEC_ROUNDS;
                end
            end

            `ST_EXEC_ROUNDS: begin
                if (round_cnt == (max_rounds - 1'b1)) begin
                    next_state = `ST_OUT_FORMAT;
                end
            end

            `ST_OUT_FORMAT: begin
                if (out_cnt == max_chunks) begin
                    next_state = `ST_IDLE;
                end
            end

            default: next_state = `ST_IDLE;
        endcase
    end

    // -------------------------------------------------------------------------
    // Control Outputs & Status Signals
    // -------------------------------------------------------------------------
    always @(*) begin
        round_init    = 1'b0;
        round_en      = 1'b0;
        out_format_en = 1'b0;
        done          = 1'b0;
        busy          = 1'b0;

        case (current_state)
            `ST_IDLE: begin
                busy = 1'b0;
                if (start && key_is_ready) begin
                    round_init = 1'b1;
                end
            end

            `ST_EXEC_ROUNDS: begin
                busy     = 1'b1;
                round_en = 1'b1;
            end

            `ST_OUT_FORMAT: begin
                busy          = 1'b1;
                out_format_en = 1'b1;
                done          = 1'b1;
            end

            default: ;
        endcase
    end

endmodule
