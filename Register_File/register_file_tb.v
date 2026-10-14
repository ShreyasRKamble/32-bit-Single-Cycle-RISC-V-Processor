`timescale 1ns/1ps

module register_file_tb;

    reg         clk;
    reg         rst;
    reg         reg_write;

    reg  [4:0]  rs1;
    reg  [4:0]  rs2;
    reg  [4:0]  rd;

    reg  [31:0] write_data;

    wire [31:0] read_data1;
    wire [31:0] read_data2;

    integer pass_count;
    integer fail_count;

    // DUT
    register_file dut (
        .clk(clk),
        .rst(rst),
        .reg_write(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // Clock: 10 ns period
    always #5 clk = ~clk;


    // =====================================================
    // TASK: CHECK REGISTER VALUE
    // =====================================================

    task check_register;
        input [31:0] actual;
        input [31:0] expected;
        input [127:0] test_name;

        begin
            if (actual === expected) begin
                $display("PASS: %s | Expected = %0d | Actual = %0d",
                         test_name, expected, actual);
                pass_count = pass_count + 1;
            end
            else begin
                $display("FAIL: %s | Expected = %0d | Actual = %0d",
                         test_name, expected, actual);
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

        clk        = 0;
        rst        = 1;
        reg_write  = 0;
        rs1        = 0;
        rs2        = 0;
        rd         = 0;
        write_data = 0;


        // =================================================
        // TEST 1: RESET
        // =================================================

        #10;
        rst = 0;

        rs1 = 5;
        rs2 = 10;

        #2;

        check_register(read_data1, 32'd0, "RESET x5");
        check_register(read_data2, 32'd0, "RESET x10");


        // =================================================
        // TEST 2: WRITE x5 = 100
        // =================================================

        @(negedge clk);

        reg_write  = 1;
        rd         = 5;
        write_data = 100;

        @(posedge clk);

        #1;

        reg_write = 0;

        rs1 = 5;

        #1;

        check_register(read_data1, 32'd100, "WRITE x5 = 100");


        // =================================================
        // TEST 3: WRITE x10 = 200
        // =================================================

        @(negedge clk);

        reg_write  = 1;
        rd         = 10;
        write_data = 200;

        @(posedge clk);

        #1;

        reg_write = 0;

        rs1 = 10;

        #1;

        check_register(read_data1, 32'd200, "WRITE x10 = 200");


        // =================================================
        // TEST 4: DUAL READ
        // =================================================

        rs1 = 5;
        rs2 = 10;

        #1;

        check_register(read_data1, 32'd100, "READ x5");
        check_register(read_data2, 32'd200, "READ x10");


        // =================================================
        // TEST 5: x0 MUST ALWAYS BE ZERO
        // =================================================

        @(negedge clk);

        reg_write  = 1;
        rd         = 0;
        write_data = 999;

        @(posedge clk);

        #1;

        reg_write = 0;

        rs1 = 0;

        #1;

        check_register(read_data1, 32'd0, "x0 PROTECTION");


        // =================================================
        // TEST 6: OVERWRITE x5
        // =================================================

        @(negedge clk);

        reg_write  = 1;
        rd         = 5;
        write_data = 1234;

        @(posedge clk);

        #1;

        reg_write = 0;

        rs1 = 5;

        #1;

        check_register(read_data1, 32'd1234, "OVERWRITE x5");


        // =================================================
        // FINAL RESULT
        // =================================================

        $display("");
        $display("========================================");
        $display("       REGISTER FILE VERIFICATION       ");
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