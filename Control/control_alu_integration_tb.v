`timescale 1ns/1ps

module control_alu_integration_tb;

    reg  [31:0] instruction;
    reg  [31:0] rs1_value;
    reg  [31:0] rs2_value;

    wire        reg_write;
    wire        mem_read;
    wire        mem_write;
    wire        mem_to_reg;
    wire        alu_src;
    wire        branch;
    wire        jump;
    wire [1:0]  alu_unit_sel;
    wire [3:0]  alu_func_sel;
    wire [1:0]  writeback_sel;
    wire [2:0]  branch_funct3;
    wire        illegal_instruction;
    wire [31:0] immediate;
    wire [31:0] alu_result;
    wire        cout;
    wire        zero;
    wire        negative;
    wire        overflow;

    wire [31:0] alu_b = alu_src ? immediate : rs2_value;

    integer tests_run;

    control_unit u_control (
        .instruction(instruction),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .alu_src(alu_src),
        .branch(branch),
        .jump(jump),
        .alu_unit_sel(alu_unit_sel),
        .alu_func_sel(alu_func_sel),
        .writeback_sel(writeback_sel),
        .branch_funct3(branch_funct3),
        .illegal_instruction(illegal_instruction)
    );

    imm_gen u_imm_gen (
        .instruction(instruction),
        .immediate(immediate)
    );

    alu_top u_alu (
        .A(rs1_value),
        .B(alu_b),
        .unit_sel(alu_unit_sel),
        .func_sel(alu_func_sel),
        .shift_amt(5'b0),
        .result(alu_result),
        .cout(cout),
        .zero(zero),
        .negative(negative),
        .overflow(overflow)
    );

    task check_instruction;
        input [31:0] encoded_instruction;
        input [31:0] a_value;
        input [31:0] b_value;
        input [3:0] expected_func;
        input [31:0] expected_result;
        input expected_reg_write;
        input expected_branch;
        begin
            instruction = encoded_instruction;
            rs1_value = a_value;
            rs2_value = b_value;
            #1;
            tests_run = tests_run + 1;
            if (illegal_instruction !== 1'b0 ||
                alu_unit_sel !== 2'b11 ||
                alu_func_sel !== expected_func ||
                alu_result !== expected_result ||
                reg_write !== expected_reg_write ||
                branch !== expected_branch) begin
                $display("FAIL test %0d instruction=%08h", tests_run,
                         encoded_instruction);
                $display("  func=%b result=%08h reg_write=%b branch=%b illegal=%b",
                         alu_func_sel, alu_result, reg_write, branch,
                         illegal_instruction);
                $display("  expected func=%b result=%08h reg_write=%b branch=%b",
                         expected_func, expected_result, expected_reg_write,
                         expected_branch);
                $fatal(1, "Control-to-ALU comparison mismatch");
            end
        end
    endtask

    initial begin
        instruction = 32'b0;
        rs1_value = 32'b0;
        rs2_value = 32'b0;
        tests_run = 0;

        // -1 is less than 1 when signed, but larger than 1 when unsigned.
        check_instruction(32'h0020A1B3, 32'hFFFFFFFF, 32'd1,
                          4'b0111, 32'd1, 1'b1, 1'b0); // SLT
        check_instruction(32'h0020B1B3, 32'hFFFFFFFF, 32'd1,
                          4'b0011, 32'd0, 1'b1, 1'b0); // SLTU

        // The immediate is sign-extended and selected by alu_src.
        check_instruction(32'h0010A193, 32'hFFFFFFFF, 32'b0,
                          4'b0111, 32'd1, 1'b1, 1'b0); // SLTI
        check_instruction(32'h0010B193, 32'hFFFFFFFF, 32'b0,
                          4'b0011, 32'd0, 1'b1, 1'b0); // SLTIU

        // Branch comparisons use the register operands directly.
        check_instruction(32'h0020C463, 32'hFFFFFFFF, 32'd1,
                          4'b0111, 32'd1, 1'b0, 1'b1); // BLT
        check_instruction(32'h0020D463, 32'hFFFFFFFF, 32'd1,
                          4'b1000, 32'd0, 1'b0, 1'b1); // BGE
        check_instruction(32'h0020E463, 32'hFFFFFFFF, 32'd1,
                          4'b0011, 32'd0, 1'b0, 1'b1); // BLTU
        check_instruction(32'h0020F463, 32'hFFFFFFFF, 32'd1,
                          4'b0100, 32'd1, 1'b0, 1'b1); // BGEU

        $display("PASS: all %0d control-to-ALU integration checks passed",
                 tests_run);
        $finish;
    end

endmodule
