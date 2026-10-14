`timescale 1ns/1ps

module control_unit_tb;

    reg  [31:0] instruction;
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

    integer tests_run;

    control_unit dut (
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

    // Packed order matches the control outputs checked below.
    task check_decode;
        input [31:0] encoded_instruction;
        input [18:0] expected_controls;
        begin
            instruction = encoded_instruction;
            #1;
            tests_run = tests_run + 1;
            if ({reg_write, mem_read, mem_write, mem_to_reg, alu_src,
                 branch, jump, alu_unit_sel, alu_func_sel, writeback_sel,
                 branch_funct3, illegal_instruction} !== expected_controls) begin
                $display("FAIL test %0d instruction=%08h", tests_run, encoded_instruction);
                $display("  expected controls=%019b", expected_controls);
                $display("  actual   controls=%019b",
                         {reg_write, mem_read, mem_write, mem_to_reg, alu_src,
                          branch, jump, alu_unit_sel, alu_func_sel, writeback_sel,
                          branch_funct3, illegal_instruction});
                $fatal(1, "Control unit decode mismatch");
            end
        end
    endtask

    initial begin
        instruction = 32'b0;
        tests_run = 0;

        // R-type arithmetic, logical, shift, and compare instructions.
        check_decode(32'h002081B3,
            {1'b1, 6'b0, 2'b00, 4'b0000, 2'b00, 3'b000, 1'b0}); // ADD
        check_decode(32'h402081B3,
            {1'b1, 6'b0, 2'b00, 4'b0001, 2'b00, 3'b000, 1'b0}); // SUB
        check_decode(32'h0020F1B3,
            {1'b1, 6'b0, 2'b01, 4'b0000, 2'b00, 3'b111, 1'b0}); // AND
        check_decode(32'h002091B3,
            {1'b1, 6'b0, 2'b10, 4'b0101, 2'b00, 3'b001, 1'b0}); // SLL
        check_decode(32'h0020D1B3,
            {1'b1, 6'b0, 2'b10, 4'b0110, 2'b00, 3'b101, 1'b0}); // SRL
        check_decode(32'h4020D1B3,
            {1'b1, 6'b0, 2'b10, 4'b0111, 2'b00, 3'b101, 1'b0}); // SRA
        check_decode(32'h0020B1B3,
            {1'b1, 6'b0, 2'b11, 4'b0011, 2'b00, 3'b011, 1'b0}); // SLTU decode

        // Immediate ALU operations.
        check_decode(32'h00508193,
            {1'b1, 3'b0, 1'b1, 2'b0, 2'b00, 4'b0000, 2'b00, 3'b000, 1'b0}); // ADDI
        check_decode(32'h00309193,
            {1'b1, 3'b0, 1'b1, 2'b0, 2'b10, 4'b0101, 2'b00, 3'b001, 1'b0}); // SLLI

        // Word load and store controls.
        check_decode(32'h0040A183,
            {1'b1, 1'b1, 1'b0, 1'b1, 1'b1, 2'b0, 2'b00, 4'b0000,
             2'b01, 3'b010, 1'b0}); // LW
        check_decode(32'h0020A223,
            {1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 2'b0, 2'b00, 4'b0000,
             2'b00, 3'b010, 1'b0}); // SW

        // Branch condition and funct3 pass-through.
        check_decode(32'h00208463,
            {1'b0, 4'b0, 1'b1, 1'b0, 2'b11, 4'b0000, 2'b00, 3'b000, 1'b0}); // BEQ
        check_decode(32'h00209463,
            {1'b0, 4'b0, 1'b1, 1'b0, 2'b11, 4'b0001, 2'b00, 3'b001, 1'b0}); // BNE
        check_decode(32'h0020C463,
            {1'b0, 4'b0, 1'b1, 1'b0, 2'b11, 4'b0111, 2'b00, 3'b100, 1'b0}); // BLT
        check_decode(32'h0020D463,
            {1'b0, 4'b0, 1'b1, 1'b0, 2'b11, 4'b1000, 2'b00, 3'b101, 1'b0}); // BGE
        check_decode(32'h0020E463,
            {1'b0, 4'b0, 1'b1, 1'b0, 2'b11, 4'b0011, 2'b00, 3'b110, 1'b0}); // BLTU
        check_decode(32'h0020F463,
            {1'b0, 4'b0, 1'b1, 1'b0, 2'b11, 4'b0100, 2'b00, 3'b111, 1'b0}); // BGEU

        // Jumps and upper-immediate instructions.
        check_decode(32'h000000EF,
            {1'b1, 4'b0, 1'b0, 1'b1, 2'b00, 4'b0000, 2'b10, 3'b000, 1'b0}); // JAL
        check_decode(32'h000100E7,
            {1'b1, 3'b0, 1'b1, 1'b0, 1'b1, 2'b00, 4'b0000, 2'b10, 3'b000, 1'b0}); // JALR
        check_decode(32'h000010B7,
            {1'b1, 6'b0, 2'b00, 4'b0000, 2'b11, 3'b001, 1'b0}); // LUI
        check_decode(32'h00001097,
            {1'b1, 3'b0, 1'b1, 2'b0, 2'b00, 4'b0000, 2'b00, 3'b001, 1'b0}); // AUIPC

        // Unsupported encodings must not write registers or memory.
        check_decode(32'h022081B3,
            {1'b0, 6'b0, 2'b00, 4'b0000, 2'b00, 3'b000, 1'b1}); // Illegal R funct7
        check_decode(32'h00008083,
            {1'b0, 6'b0, 2'b00, 4'b0000, 2'b00, 3'b000, 1'b1}); // LB is not supported
        check_decode(32'hFFFFFFFF,
            {1'b0, 6'b0, 2'b00, 4'b0000, 2'b00, 3'b111, 1'b1}); // Unknown opcode

        $display("PASS: all %0d control unit decode checks passed", tests_run);
        $finish;
    end

endmodule
