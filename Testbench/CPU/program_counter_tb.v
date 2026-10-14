`timescale 1ns/1ps

module program_counter_tb;

    reg clk;
    reg reset;
    reg enable;
    reg branch;
    reg branch_taken;
    reg jump;
    reg jalr;
    reg [31:0] immediate;
    reg [31:0] rs1_value;
    wire [31:0] pc;
    wire [31:0] pc_plus_4;

    integer failures;

    program_counter dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .branch(branch),
        .branch_taken(branch_taken),
        .jump(jump),
        .jalr(jalr),
        .immediate(immediate),
        .rs1_value(rs1_value),
        .pc(pc),
        .pc_plus_4(pc_plus_4)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task check_pc;
        input [31:0] expected_pc;
        input [8*40-1:0] test_name;
        begin
            if (pc !== expected_pc) begin
                $display("FAIL: %0s expected=%08h actual=%08h", test_name, expected_pc, pc);
                failures = failures + 1;
            end else begin
                $display("PASS: %0s pc=%08h", test_name, pc);
            end
            if (pc_plus_4 !== (expected_pc + 32'd4)) begin
                $display("FAIL: %0s expected pc_plus_4=%08h actual=%08h",
                         test_name, expected_pc + 32'd4, pc_plus_4);
                failures = failures + 1;
            end
        end
    endtask

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        failures = 0;
        reset = 1'b1;
        enable = 1'b1;
        branch = 1'b0;
        branch_taken = 1'b0;
        jump = 1'b0;
        jalr = 1'b0;
        immediate = 32'b0;
        rs1_value = 32'b0;

        tick();
        check_pc(32'h0000_0000, "synchronous reset");

        reset = 1'b0;
        tick();
        check_pc(32'h0000_0004, "sequential increment");

        branch = 1'b1;
        branch_taken = 1'b0;
        immediate = 32'd16;
        tick();
        check_pc(32'h0000_0008, "untaken branch");

        branch_taken = 1'b1;
        tick();
        check_pc(32'h0000_0018, "taken forward branch");

        immediate = -32'sd8;
        tick();
        check_pc(32'h0000_0010, "taken backward branch");

        branch = 1'b0;
        jump = 1'b1;
        jalr = 1'b0;
        immediate = 32'd32;
        tick();
        check_pc(32'h0000_0030, "JAL PC-relative target");

        jalr = 1'b1;
        rs1_value = 32'h0000_0101;
        immediate = 32'd6;
        tick();
        check_pc(32'h0000_0106, "JALR clears target bit zero");

        jump = 1'b0;
        enable = 1'b0;
        tick();
        check_pc(32'h0000_0106, "disabled PC holds value");

        reset = 1'b1;
        tick();
        check_pc(32'h0000_0000, "reset overrides disabled enable");

        if (failures == 0)
            $display("All program_counter tests passed.");
        else
            $display("%0d program_counter test(s) failed.", failures);
        $finish;
    end

endmodule
