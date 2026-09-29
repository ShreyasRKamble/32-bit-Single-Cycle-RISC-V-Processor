`timescale 1ns/1ps

module imm_gen_tb;

    reg  [31:0] instruction;
    wire [31:0] immediate;

    integer pass_count;
    integer fail_count;

    // =====================================================
    // DUT
    // =====================================================

    imm_gen dut (
        .instruction(instruction),
        .immediate(immediate)
    );


    // =====================================================
    // CHECK TASK
    // =====================================================

    task check_immediate;
        input [31:0] expected;
        input [127:0] test_name;

        begin

            #1;

            if (immediate === expected) begin

                $display("PASS: %s | Expected = %h | Actual = %h",
                         test_name, expected, immediate);

                pass_count = pass_count + 1;

            end
            else begin

                $display("FAIL: %s | Expected = %h | Actual = %h",
                         test_name, expected, immediate);

                fail_count = fail_count + 1;

            end

        end

    endtask


    // =====================================================
    // TEST SEQUENCE
    // =====================================================

    initial begin

        pass_count = 0;
        fail_count = 0;

        instruction = 32'b0;


        // =================================================
        // TEST 1: I-TYPE +10
        // ADDI
        // =================================================

        instruction = 32'h00A00093;

        check_immediate(
            32'h0000000A,
            "I-TYPE +10"
        );


        // =================================================
        // TEST 2: I-TYPE -10
        // ADDI
        // =================================================

        instruction = 32'hFF600093;

        check_immediate(
            32'hFFFFFFF6,
            "I-TYPE -10"
        );


        // =================================================
        // TEST 3: S-TYPE +20
        // SW
        //
        // imm = 20
        // imm[11:5] = 0000000
        // imm[4:0]  = 10100
        // =================================================

        instruction = 32'h00000A23;

        check_immediate(
            32'h00000014,
            "S-TYPE +20"
        );


        // =================================================
        // TEST 4: S-TYPE -20
        // SW
        //
        // -20 = 12-bit two's complement
        //       111111101100
        // =================================================

        instruction = 32'hFE000623;

        check_immediate(
            32'hFFFFFFEC,
            "S-TYPE -20"
        );


        // =================================================
        // TEST 5: B-TYPE +16
        // BEQ
        // =================================================

        instruction = 32'h00628863;

        check_immediate(
            32'h00000010,
            "B-TYPE +16"
        );


        // =================================================
        // TEST 6: B-TYPE -16
        // BEQ
        // =================================================

        instruction = 32'hFE6288E3;

        check_immediate(
            32'hFFFFFFF0,
            "B-TYPE -16"
        );


        // =================================================
        // TEST 7: U-TYPE
        // LUI
        //
        // Upper immediate = 0x12345
        // =================================================

        instruction = 32'h12345037;

        check_immediate(
            32'h12345000,
            "U-TYPE LUI"
        );


        // =================================================
        // TEST 8: J-TYPE +2048
        // JAL
        // =================================================

        instruction = 32'h001000EF;

        check_immediate(
            32'h00000800,
            "J-TYPE +2048"
        );


        // =================================================
        // TEST 9: INVALID OPCODE
        // =================================================

        instruction = 32'hFFFFFFFF;

        check_immediate(
            32'h00000000,
            "INVALID OPCODE"
        );


        // =================================================
        // FINAL RESULT
        // =================================================

        $display("");
        $display("========================================");
        $display("   IMMEDIATE GENERATOR VERIFICATION     ");
        $display("========================================");

        $display("PASSED TESTS : %0d", pass_count);
        $display("FAILED TESTS : %0d", fail_count);

        if (fail_count == 0)
            $display("RESULT       : ALL TESTS PASSED");
        else
            $display("RESULT       : VERIFICATION FAILED");

        $display("========================================");

        #10;

        $stop;

    end

endmodule