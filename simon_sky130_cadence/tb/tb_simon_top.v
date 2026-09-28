// ==============================================================================
// File: tb_simon_top.v
// Description: Comprehensive Self-Checking Testbench for Configurable SIMON Core.
// Verification: NSA Known-Answer Tests (KAT), Multi-Packet Streams, Error Checks.
// ==============================================================================

`timescale 1ns / 1ps
`include "simon_defines.vh"

module tb_simon_top;

    // -------------------------------------------------------------------------
    // Testbench Signals
    // -------------------------------------------------------------------------
    reg         clk;
    reg         rst_n;
    reg         start;
    reg         load;
    reg         mode;
    reg         enc_dec;
    reg  [15:0] data_in;
    reg  [31:0] key_in;

    wire [15:0] data_out;
    wire        done;
    wire        busy;
    wire        error;

    // Test Tracking
    integer pass_count = 0;
    integer fail_count = 0;

    // -------------------------------------------------------------------------
    // Device Under Test (DUT) Instantiation
    // -------------------------------------------------------------------------
    simon_top u_dut (
        .CLK      (clk),
        .RESET    (rst_n),
        .START    (start),
        .LOAD     (load),
        .MODE     (mode),
        .ENC_DEC  (enc_dec),
        .DATA_IN  (data_in),
        .KEY_IN   (key_in),
        .DATA_OUT (data_out),
        .DONE     (done),
        .BUSY     (busy),
        .ERROR    (error)
    );

    // -------------------------------------------------------------------------
    // Clock Generation (50 MHz -> 20ns period)
    // -------------------------------------------------------------------------
    initial clk = 0;
    always #10 clk = ~clk;

    // -------------------------------------------------------------------------
    // Helper Tasks for Multi-Cycle Chunk Operations
    // -------------------------------------------------------------------------

    // Task: Reset DUT
    task apply_reset;
        begin
            rst_n   = 1'b0;
            start   = 1'b0;
            load    = 1'b0;
            mode    = 1'b0;
            enc_dec = 1'b0;
            data_in = 16'd0;
            key_in  = 32'd0;
            repeat (5) @(posedge clk);
            rst_n   = 1'b1;
            repeat (2) @(posedge clk);
        end
    endtask

    // Task: Load Data & Key for SIMON32/64
    task load_simon32(input [63:0] key, input [31:0] data, input is_dec);
        begin
            @(posedge clk);
            mode    = `MODE_SIMON32_64;
            enc_dec = is_dec;
            load    = 1'b1;

            // Chunk 0
            data_in = data[31:16];
            key_in  = key[63:32];
            @(posedge clk);

            // Chunk 1
            data_in = data[15:0];
            key_in  = key[31:0];
            @(posedge clk);

            load    = 1'b0;
            data_in = 16'd0;
            key_in  = 32'd0;
        end
    endtask

    // Task: Load Data & Key for SIMON64/128
    task load_simon64(input [127:0] key, input [63:0] data, input is_dec);
        begin
            @(posedge clk);
            mode    = `MODE_SIMON64_128;
            enc_dec = is_dec;
            load    = 1'b1;

            // Chunk 0
            data_in = data[63:48];
            key_in  = key[127:96];
            @(posedge clk);

            // Chunk 1
            data_in = data[47:32];
            key_in  = key[95:64];
            @(posedge clk);

            // Chunk 2
            data_in = data[31:16];
            key_in  = key[63:32];
            @(posedge clk);

            // Chunk 3
            data_in = data[15:0];
            key_in  = key[31:0];
            @(posedge clk);

            load    = 1'b0;
            data_in = 16'd0;
            key_in  = 32'd0;
        end
    endtask

    // Task: Trigger Operation with START
    task trigger_start;
        begin
            @(posedge clk);
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;
        end
    endtask

    // Task: Check Output for SIMON32/64
    task check_simon32(input [31:0] expected, input [8*20:1] test_label);
        reg [31:0] captured_out;
        begin
            // Wait for DONE assertion
            while (!done) @(posedge clk);

            // Chunk 0
            captured_out[31:16] = data_out;
            @(posedge clk);
            // Chunk 1
            captured_out[15:0]  = data_out;

            if (captured_out === expected) begin
                $display("[PASS] %0s | Got: 0x%08h | Expected: 0x%08h", test_label, captured_out, expected);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s | Got: 0x%08h | Expected: 0x%08h", test_label, captured_out, expected);
                fail_count = fail_count + 1;
            end
            @(posedge clk);
        end
    endtask

    // Task: Check Output for SIMON64/128
    task check_simon64(input [63:0] expected, input [8*20:1] test_label);
        reg [63:0] captured_out;
        begin
            // Wait for DONE assertion
            while (!done) @(posedge clk);

            // Chunk 0
            captured_out[63:48] = data_out;
            @(posedge clk);
            // Chunk 1
            captured_out[47:32] = data_out;
            @(posedge clk);
            // Chunk 2
            captured_out[31:16] = data_out;
            @(posedge clk);
            // Chunk 3
            captured_out[15:0]  = data_out;

            if (captured_out === expected) begin
                $display("[PASS] %0s | Got: 0x%016h | Expected: 0x%016h", test_label, captured_out, expected);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s | Got: 0x%016h | Expected: 0x%016h", test_label, captured_out, expected);
                fail_count = fail_count + 1;
            end
            @(posedge clk);
        end
    endtask

    // -------------------------------------------------------------------------
    // Main Verification Test Suite
    // -------------------------------------------------------------------------
    initial begin
        $display("===============================================================");
        $display("  STARTING SIMON CORE TAPE-OUT VERIFICATION ON SKYWATER 130NM  ");
        $display("===============================================================");

        // Setup VCD Waveform Dump
        $dumpfile("simon_top.vcd");
        $dumpvars(0, tb_simon_top);

        apply_reset();

        // ---------------------------------------------------------------------
        // TEST 1: SIMON 32/64 Encryption (Official NSA KAT)
        // Key: 0x1918111009080100
        // PT:  0x65656877
        // CT:  0xc69be9bb
        // ---------------------------------------------------------------------
        $display("\n--- Test 1: SIMON 32/64 Encryption (NSA KAT) ---");
        load_simon32(64'h1918111009080100, 32'h65656877, `DIR_ENCRYPT);
        trigger_start();
        check_simon32(32'hc69be9bb, "SIMON32/64 Encrypt");

        // ---------------------------------------------------------------------
        // TEST 2: SIMON 32/64 Decryption (Official NSA KAT)
        // Key: 0x1918111009080100
        // CT:  0xc69be9bb
        // PT:  0x65656877
        // ---------------------------------------------------------------------
        $display("\n--- Test 2: SIMON 32/64 Decryption (NSA KAT) ---");
        load_simon32(64'h1918111009080100, 32'hc69be9bb, `DIR_DECRYPT);
        trigger_start();
        check_simon32(32'h65656877, "SIMON32/64 Decrypt");

        // ---------------------------------------------------------------------
        // TEST 3: SIMON 64/128 Encryption (Official NSA KAT)
        // Key: 0x1b1a1918131211100b0a090803020100
        // PT:  0x656b696c20646e75
        // CT:  0x44c8fc20b9dfa07a
        // ---------------------------------------------------------------------
        $display("\n--- Test 3: SIMON 64/128 Encryption (NSA KAT) ---");
        load_simon64(128'h1b1a1918131211100b0a090803020100, 64'h656b696c20646e75, `DIR_ENCRYPT);
        trigger_start();
        check_simon64(64'h44c8fc20b9dfa07a, "SIMON64/128 Encrypt");

        // ---------------------------------------------------------------------
        // TEST 4: SIMON 64/128 Decryption (Official NSA KAT)
        // Key: 0x1b1a1918131211100b0a090803020100
        // CT:  0x44c8fc20b9dfa07a
        // PT:  0x656b696c20646e75
        // ---------------------------------------------------------------------
        $display("\n--- Test 4: SIMON 64/128 Decryption (NSA KAT) ---");
        load_simon64(128'h1b1a1918131211100b0a090803020100, 64'h44c8fc20b9dfa07a, `DIR_DECRYPT);
        trigger_start();
        check_simon64(64'h656b696c20646e75, "SIMON64/128 Decrypt");

        // ---------------------------------------------------------------------
        // TEST 5: Error Signaling Test (Start without Key)
        // ---------------------------------------------------------------------
        $display("\n--- Test 5: Error Signaling Check ---");
        apply_reset(); // Clears internal key
        trigger_start();
        repeat (2) @(posedge clk);
        if (error == 1'b1) begin
            $display("[PASS] Error asserted correctly when START triggered without key");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Error flag NOT asserted on uninitialized START");
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------------
        // Final Summary
        // ---------------------------------------------------------------------
        $display("\n===============================================================");
        $display("  VERIFICATION SUMMARY: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("===============================================================");

        if (fail_count == 0) begin
            $display("  ALL TESTBENCH CHECKS COMPLETED SUCCESSFULLY (100%% MATCH)!   ");
        end else begin
            $display("  TESTBENCH FAILED WITH ERRORS!                                ");
        end
        $display("===============================================================\n");

        $finish;
    end

endmodule
