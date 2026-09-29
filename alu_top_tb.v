`timescale 1ns/1ps

module alu_top_tb;

    //================================================
    // DUT Inputs
    //================================================

    reg [31:0] A;
    reg [31:0] B;

    reg [1:0]  unit_sel;
    reg [3:0]  func_sel;

    reg [4:0]  shift_amt;


    //================================================
    // DUT Outputs
    //================================================

    wire [31:0] result;
    wire        cout;
    wire        zero;
    wire        negative;
    wire        overflow;


    //================================================
    // Instantiate DUT
    //================================================

    alu_top dut (

        .A(A),
        .B(B),

        .unit_sel(unit_sel),
        .func_sel(func_sel),

        .shift_amt(shift_amt),

        .result(result),
        .cout(cout),

        .zero(zero),
        .negative(negative),
        .overflow(overflow)

    );


    //================================================
    // Test Counter
    //================================================

    integer test_count;
    integer pass_count;
    integer fail_count;


    //================================================
    // Test Task
    //================================================

    task check_result;

        input [31:0] expected;

        begin

            #10;

            test_count = test_count + 1;

            if (result === expected) begin

                pass_count = pass_count + 1;

                $display(
                    "PASS | UNIT=%b FUNC=%b A=%h B=%h SHIFT=%d RESULT=%h",
                    unit_sel,
                    func_sel,
                    A,
                    B,
                    shift_amt,
                    result
                );

            end
            else begin

                fail_count = fail_count + 1;

                $display(
                    "FAIL | UNIT=%b FUNC=%b A=%h B=%h SHIFT=%d RESULT=%h EXPECTED=%h",
                    unit_sel,
                    func_sel,
                    A,
                    B,
                    shift_amt,
                    result,
                    expected
                );

            end

        end

    endtask


    //================================================
    // Test Sequence
    //================================================

    initial begin

        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        A = 32'b0;
        B = 32'b0;
        unit_sel = 2'b00;
        func_sel = 4'b0000;
        shift_amt = 5'b0;

        $display("==============================================");
        $display("        32-BIT ALU VERIFICATION START");
        $display("==============================================");


        //================================================
        // ARITHMETIC UNIT
        // unit_sel = 00
        //================================================

        $display("");
        $display("------------ ARITHMETIC UNIT ------------");


        // ADD
        A = 32'd10;
        B = 32'd20;
        unit_sel = 2'b00;
        func_sel = 4'b0000;

        check_result(32'd30);


        // SUB
        A = 32'd50;
        B = 32'd20;
        unit_sel = 2'b00;
        func_sel = 4'b0001;

        check_result(32'd30);


        // INC_A
        A = 32'd100;
        B = 32'd0;
        unit_sel = 2'b00;
        func_sel = 4'b0010;

        check_result(32'd101);


        // DEC_A
        A = 32'd100;
        B = 32'd0;
        unit_sel = 2'b00;
        func_sel = 4'b0011;

        check_result(32'd99);


        // INC_B
        A = 32'd0;
        B = 32'd200;
        unit_sel = 2'b00;
        func_sel = 4'b0100;

        check_result(32'd201);


        // DEC_B
        A = 32'd0;
        B = 32'd200;
        unit_sel = 2'b00;
        func_sel = 4'b0101;

        check_result(32'd199);


        //================================================
        // ARITHMETIC EDGE CASES
        //================================================

        // FFFFFFFF + 1 = 00000000
        A = 32'hFFFFFFFF;
        B = 32'h00000001;
        unit_sel = 2'b00;
        func_sel = 4'b0000;

        check_result(32'h00000000);


        // 0 - 1 = FFFFFFFF
        A = 32'h00000000;
        B = 32'h00000001;
        unit_sel = 2'b00;
        func_sel = 4'b0001;

        check_result(32'hFFFFFFFF);


        //================================================
        // LOGIC UNIT
        // unit_sel = 01
        //================================================

        $display("");
        $display("------------ LOGIC UNIT ------------");


        // AND
        A = 32'hFFFF0000;
        B = 32'h0F0F0F0F;
        unit_sel = 2'b01;
        func_sel = 4'b0000;

        check_result(32'h0F0F0000);


        // OR
        A = 32'hFFFF0000;
        B = 32'h0F0F0F0F;
        unit_sel = 2'b01;
        func_sel = 4'b0001;

        check_result(32'hFFFF0F0F);


        // XOR
        A = 32'hFFFF0000;
        B = 32'h0F0F0F0F;
        unit_sel = 2'b01;
        func_sel = 4'b0010;

        check_result(32'hF0F00F0F);


        // NOT A
        A = 32'hAAAAAAAA;
        B = 32'h00000000;
        unit_sel = 2'b01;
        func_sel = 4'b0011;

        check_result(32'h55555555);


        // NOT B
        A = 32'h00000000;
        B = 32'hAAAAAAAA;
        unit_sel = 2'b01;
        func_sel = 4'b0100;

        check_result(32'h55555555);


        //================================================
        // SHIFT UNIT
        // unit_sel = 10
        //================================================

        $display("");
        $display("------------ SHIFT UNIT ------------");


        // SLL1
        A = 32'h00000001;
        unit_sel = 2'b10;
        func_sel = 4'b0000;

        check_result(32'h00000002);


        // SRL1
        A = 32'h00000010;
        unit_sel = 2'b10;
        func_sel = 4'b0001;

        check_result(32'h00000008);


        // SRA1
        A = 32'h80000010;
        unit_sel = 2'b10;
        func_sel = 4'b0010;

        check_result(32'hC0000008);


        // ROL1
        A = 32'h80000001;
        unit_sel = 2'b10;
        func_sel = 4'b0011;

        check_result(32'h00000003);


        // ROR1
        A = 32'h00000001;
        unit_sel = 2'b10;
        func_sel = 4'b0100;

        check_result(32'h80000000);


        //================================================
        // BARREL SHIFTS
        //================================================

        // BSLL
        A = 32'h00000001;
        shift_amt = 5'd4;
        unit_sel = 2'b10;
        func_sel = 4'b0101;

        check_result(32'h00000010);


        // BSRL
        A = 32'h00000010;
        shift_amt = 5'd2;
        unit_sel = 2'b10;
        func_sel = 4'b0110;

        check_result(32'h00000004);


        // BSRA
        A = 32'h80000010;
        shift_amt = 5'd2;
        unit_sel = 2'b10;
        func_sel = 4'b0111;

        check_result(32'hE0000004);


        //================================================
        // BARREL ROTATES
        //================================================

        // BROL
        A = 32'h80000001;
        shift_amt = 5'd1;
        unit_sel = 2'b10;
        func_sel = 4'b1000;

        check_result(32'h00000003);


        // BROR
        A = 32'h00000001;
        shift_amt = 5'd1;
        unit_sel = 2'b10;
        func_sel = 4'b1001;

        check_result(32'h80000000);


        //================================================
        // COMPARE UNIT
        // unit_sel = 11
        //================================================

        $display("");
        $display("------------ COMPARE UNIT ------------");


        // EQ
        A = 32'd100;
        B = 32'd100;
        unit_sel = 2'b11;
        func_sel = 4'b0000;

        check_result(32'd1);


        // NE
        A = 32'd100;
        B = 32'd200;
        unit_sel = 2'b11;
        func_sel = 4'b0001;

        check_result(32'd1);


        // GT
        A = 32'd200;
        B = 32'd100;
        unit_sel = 2'b11;
        func_sel = 4'b0010;

        check_result(32'd1);


        // LT
        A = 32'd100;
        B = 32'd200;
        unit_sel = 2'b11;
        func_sel = 4'b0011;

        check_result(32'd1);


        // GTE
        A = 32'd200;
        B = 32'd200;
        unit_sel = 2'b11;
        func_sel = 4'b0100;

        check_result(32'd1);


        // LTE
        A = 32'd100;
        B = 32'd200;
        unit_sel = 2'b11;
        func_sel = 4'b0101;

        check_result(32'd1);


        //================================================
        // ZERO RESULT
        //================================================

        $display("");
        $display("------------ ZERO FLAG ------------");

        A = 32'd10;
        B = 32'd10;
        unit_sel = 2'b00;
        func_sel = 4'b0001;

        #10;

        if (zero === 1'b1) begin
            pass_count = pass_count + 1;
            $display("PASS | ZERO FLAG");
        end
        else begin
            fail_count = fail_count + 1;
            $display("FAIL | ZERO FLAG");
        end

        test_count = test_count + 1;


        //================================================
        // NEGATIVE FLAG
        //================================================

        //================================================
// NEGATIVE FLAG
//================================================

$display("");
$display("------------ NEGATIVE FLAG ------------");

A = 32'h80000000;
B = 32'h00000000;
unit_sel = 2'b00;
func_sel = 4'b0000;       // ADD

#10;

if (negative === 1'b1) begin
    pass_count = pass_count + 1;
    $display("PASS | NEGATIVE FLAG");
end
else begin
    fail_count = fail_count + 1;
    $display("FAIL | NEGATIVE FLAG");
end

test_count = test_count + 1;

//================================================
// CARRY FLAG
//================================================

$display("");
$display("------------ CARRY FLAG ------------");

A = 32'hFFFFFFFF;
B = 32'h00000001;
unit_sel = 2'b00;
func_sel = 4'b0000;       // ADD

#10;

if (cout === 1'b1 && result === 32'h00000000) begin
    pass_count = pass_count + 1;
    $display("PASS | CARRY FLAG | RESULT=%h COUT=%b",
             result, cout);
end
else begin
    fail_count = fail_count + 1;
    $display("FAIL | CARRY FLAG | RESULT=%h COUT=%b",
             result, cout);
end

test_count = test_count + 1;

//================================================
// OVERFLOW FLAG
//================================================

$display("");
$display("------------ OVERFLOW FLAG ------------");

A = 32'h7FFFFFFF;
B = 32'h00000001;
unit_sel = 2'b00;
func_sel = 4'b0000;       // ADD

#10;

if (overflow === 1'b1 && result === 32'h80000000) begin
    pass_count = pass_count + 1;
    $display("PASS | OVERFLOW FLAG | RESULT=%h OVERFLOW=%b",
             result, overflow);
end
else begin
    fail_count = fail_count + 1;
    $display("FAIL | OVERFLOW FLAG | RESULT=%h OVERFLOW=%b",
             result, overflow);
end

test_count = test_count + 1;

//================================================
// SUBTRACTION OVERFLOW
//================================================

$display("");
$display("------------ SUB OVERFLOW ------------");

A = 32'h80000000;
B = 32'h00000001;
unit_sel = 2'b00;
func_sel = 4'b0001;       // SUB

#10;

if (overflow === 1'b1 && result === 32'h7FFFFFFF) begin
    pass_count = pass_count + 1;
    $display("PASS | SUB OVERFLOW | RESULT=%h OVERFLOW=%b",
             result, overflow);
end
else begin
    fail_count = fail_count + 1;
    $display("FAIL | SUB OVERFLOW | RESULT=%h OVERFLOW=%b",
             result, overflow);
end

test_count = test_count + 1;


        //================================================
        // FINAL SUMMARY
        //================================================

        #10;

        $display("");
        $display("==============================================");
        $display("             VERIFICATION SUMMARY");
        $display("==============================================");

        $display("TOTAL TESTS : %0d", test_count);
        $display("PASSED      : %0d", pass_count);
        $display("FAILED      : %0d", fail_count);

        if (fail_count == 0)
            $display("STATUS      : ALL TESTS PASSED");
        else
            $display("STATUS      : TESTS FAILED");

        $display("==============================================");

        $finish;

    end

endmodule
