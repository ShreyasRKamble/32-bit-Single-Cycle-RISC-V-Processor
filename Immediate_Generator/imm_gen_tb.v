`timescale 1ns/1ps

module imm_gen_tb;

    reg  [31:0] instruction;
    wire [31:0] immediate;

    integer pass_count;
    integer fail_count;
    integer i;

    reg [11:0] random_imm12;
    reg [12:0] random_imm13;
    reg [19:0] random_imm20;
    reg [20:0] random_imm21;

    reg [31:0] expected;


    // =====================================================
    // DUT
    // =====================================================

    imm_gen dut (
        .instruction(instruction),
        .immediate(immediate)
    );


    // =====================================================
    // MAIN TEST
    // =====================================================

    initial begin

        pass_count = 0;
        fail_count = 0;

        instruction = 32'b0;


        // =================================================
        // I-TYPE TEST
        // =================================================

        $display("");
        $display("========== I-TYPE TEST ==========");

        for (i = 0; i < 20; i = i + 1) begin

            // Generate random 12-bit immediate
            random_imm12 = $random;

            // Create I-type instruction
            //
            // imm[11:0] | rs1 | funct3 | rd | opcode
            //
            instruction = {
                random_imm12,
                5'b00000,
                3'b000,
                5'b00001,
                7'b0010011
            };

            // Expected result
            expected = {{20{random_imm12[11]}}, random_imm12};

            #1;

            if (immediate === expected) begin

                $display("PASS | Random = %h | Expected = %h | Actual = %h",
                         random_imm12,
                         expected,
                         immediate);

                pass_count = pass_count + 1;

            end
            else begin

                $display("FAIL | Random = %h | Expected = %h | Actual = %h",
                         random_imm12,
                         expected,
                         immediate);

                fail_count = fail_count + 1;

            end

        end


        // =================================================
        // S-TYPE TEST
        // =================================================

        $display("");
        $display("========== S-TYPE TEST ==========");

        for (i = 0; i < 20; i = i + 1) begin

            // Generate random 12-bit immediate
            random_imm12 = $random;

            // Create S-type instruction
            //
            // imm[11:5] | rs2 | rs1 | funct3 |
            // imm[4:0]  | opcode

            instruction = {
                random_imm12[11:5],
                5'b00001,
                5'b00000,
                3'b010,
                random_imm12[4:0],
                7'b0100011
            };

            // Expected result
            expected = {{20{random_imm12[11]}}, random_imm12};

            #1;

            if (immediate === expected) begin

                $display("PASS | Random = %h | Expected = %h | Actual = %h",
                         random_imm12,
                         expected,
                         immediate);

                pass_count = pass_count + 1;

            end
            else begin

                $display("FAIL | Random = %h | Expected = %h | Actual = %h",
                         random_imm12,
                         expected,
                         immediate);

                fail_count = fail_count + 1;

            end

        end


        // =================================================
        // B-TYPE TEST
        // =================================================

        $display("");
        $display("========== B-TYPE TEST ==========");

        for (i = 0; i < 20; i = i + 1) begin

            // Generate random 13-bit immediate
            random_imm13 = $random;

            // Branch immediate must have bit 0 = 0
            random_imm13[0] = 1'b0;

            // Create B-type instruction
            //
            // imm[12] | imm[10:5] | rs2 | rs1 |
            // funct3 | imm[4:1] | imm[11] | opcode

            instruction = {
                random_imm13[12],
                random_imm13[10:5],
                5'b00000,
                5'b00000,
                3'b000,
                random_imm13[4:1],
                random_imm13[11],
                7'b1100011
            };

            // Expected result
            expected = {{19{random_imm13[12]}}, random_imm13};

            #1;

            if (immediate === expected) begin

                $display("PASS | Random = %h | Expected = %h | Actual = %h",
                         random_imm13,
                         expected,
                         immediate);

                pass_count = pass_count + 1;

            end
            else begin

                $display("FAIL | Random = %h | Expected = %h | Actual = %h",
                         random_imm13,
                         expected,
                         immediate);

                fail_count = fail_count + 1;

            end

        end


        // =================================================
        // U-TYPE TEST
        // =================================================

        $display("");
        $display("========== U-TYPE TEST ==========");

        for (i = 0; i < 20; i = i + 1) begin

            // Generate random 20-bit immediate
            random_imm20 = $random;

            // Create U-type instruction
            //
            // imm[31:12] | rd | opcode

            instruction = {
                random_imm20,
                5'b00001,
                7'b0110111
            };

            // Expected result
            expected = {random_imm20, 12'b0};

            #1;

            if (immediate === expected) begin

                $display("PASS | Random = %h | Expected = %h | Actual = %h",
                         random_imm20,
                         expected,
                         immediate);

                pass_count = pass_count + 1;

            end
            else begin

                $display("FAIL | Random = %h | Expected = %h | Actual = %h",
                         random_imm20,
                         expected,
                         immediate);

                fail_count = fail_count + 1;

            end

        end


        // =================================================
        // J-TYPE TEST
        // =================================================

        $display("");
        $display("========== J-TYPE TEST ==========");

        for (i = 0; i < 20; i = i + 1) begin

            // Generate random 21-bit immediate
            random_imm21 = $random;

            // Jump immediate must have bit 0 = 0
            random_imm21[0] = 1'b0;

            // Create J-type instruction
            //
            // imm[20] | imm[10:1] | imm[11] |
            // imm[19:12] | rd | opcode

            instruction = {
                random_imm21[20],
                random_imm21[10:1],
                random_imm21[11],
                random_imm21[19:12],
                5'b00001,
                7'b1101111
            };

            // Expected result
            expected = {{11{random_imm21[20]}}, random_imm21};

            #1;

            if (immediate === expected) begin

                $display("PASS | Random = %h | Expected = %h | Actual = %h",
                         random_imm21,
                         expected,
                         immediate);

                pass_count = pass_count + 1;

            end
            else begin

                $display("FAIL | Random = %h | Expected = %h | Actual = %h",
                         random_imm21,
                         expected,
                         immediate);

                fail_count = fail_count + 1;

            end

        end


        // =================================================
        // FINAL RESULT
        // =================================================

        $display("");
        $display("==========================================");
        $display("       IMMEDIATE GENERATOR TEST");
        $display("==========================================");

        $display("TOTAL TESTS : %0d",
                 pass_count + fail_count);

        $display("PASSED      : %0d",
                 pass_count);

        $display("FAILED      : %0d",
                 fail_count);

        if (fail_count == 0)
            $display("RESULT      : ALL TESTS PASSED");
        else
            $display("RESULT      : VERIFICATION FAILED");

        $display("==========================================");

        #10;

        $finish;

    end

endmodule
