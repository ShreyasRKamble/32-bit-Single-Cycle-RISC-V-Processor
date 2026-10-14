`timescale 1ns/1ps

// Directed full-datapath regression: arithmetic, immediates, memory,
// all six branch conditions, jumps, reset/enable, and illegal instruction.
module single_cycle_cpu_full_tb;
    reg clk = 1'b0;
    reg reset = 1'b1;
    reg enable = 1'b0;
    reg imem_load_we = 1'b0;
    reg [31:0] imem_load_address = 0;
    reg [31:0] imem_load_instruction = 0;
    wire [31:0] pc, instruction;
    wire illegal_instruction;
    integer failures = 0;
    integer cycle = 0;
    integer illegal_seen = 0;

    always #5 clk = ~clk;

    single_cycle_cpu #(.IMEM_DEPTH(64), .DMEM_DEPTH(8)) dut (
        .clk(clk), .reset(reset), .enable(enable),
        .imem_load_we(imem_load_we), .imem_load_address(imem_load_address),
        .imem_load_instruction(imem_load_instruction), .pc(pc),
        .instruction(instruction), .illegal_instruction(illegal_instruction)
    );

    function [31:0] enc_i;
        input [11:0] imm; input [4:0] rs1; input [2:0] funct3;
        input [4:0] rd; input [6:0] opcode;
        begin enc_i = {imm, rs1, funct3, rd, opcode}; end
    endfunction

    function [31:0] enc_r;
        input [6:0] funct7; input [4:0] rs2; input [4:0] rs1;
        input [2:0] funct3; input [4:0] rd;
        begin enc_r = {funct7, rs2, rs1, funct3, rd, 7'b0110011}; end
    endfunction

    function [31:0] enc_s;
        input [11:0] imm; input [4:0] rs2; input [4:0] rs1;
        input [2:0] funct3;
        begin enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], 7'b0100011}; end
    endfunction

    function [31:0] enc_b;
        input [12:0] imm; input [4:0] rs2; input [4:0] rs1;
        input [2:0] funct3;
        begin enc_b = {imm[12], imm[10:5], rs2, rs1, funct3,
                       imm[4:1], imm[11], 7'b1100011}; end
    endfunction

    function [31:0] enc_u;
        input [19:0] imm; input [4:0] rd; input [6:0] opcode;
        begin enc_u = {imm, rd, opcode}; end
    endfunction

    function [31:0] enc_j;
        input [20:0] imm; input [4:0] rd;
        begin enc_j = {imm[20], imm[10:1], imm[11], imm[19:12],
                       rd, 7'b1101111}; end
    endfunction

    task load_word;
        input [31:0] address; input [31:0] word;
        begin
            @(negedge clk);
            imem_load_we = 1'b1;
            imem_load_address = address;
            imem_load_instruction = word;
            @(negedge clk);
            imem_load_we = 1'b0;
        end
    endtask

    task check_reg;
        input [4:0] index; input [31:0] expected;
        begin
            if (dut.u_register_file.registers[index] !== expected) begin
                $display("FAIL register x%0d expected=%08h actual=%08h", index,
                         expected, dut.u_register_file.registers[index]);
                failures = failures + 1;
            end else $display("PASS register x%0d = %08h", index, expected);
        end
    endtask

    task trace_instruction;
        begin
            $display("%02d | PC=%08h INS=%08h op=%02h rd/rs1/rs2=%0d/%0d/%0d | A=%08h B=%08h IMM=%08h ALU=%08h | R/MR/MW=%b/%b/%b B/J=%b/%b next=%08h | MEM=%08h WB=%08h illegal=%b",
                cycle, pc, instruction, instruction[6:0], instruction[11:7],
                instruction[19:15], instruction[24:20], dut.rs1_value,
                dut.rs2_value, dut.immediate, dut.alu_result,
                dut.reg_write && enable, dut.mem_read,
                dut.mem_write && enable, dut.branch, dut.jump,
                dut.jump ? (dut.jalr ? ((dut.rs1_value + dut.immediate) & 32'hffff_fffe)
                                     : pc + dut.immediate) :
                ((dut.branch && dut.alu_result[0]) ? pc + dut.immediate : dut.pc_plus_4),
                dut.memory_data, dut.writeback_data, illegal_instruction);
            if (illegal_instruction)
                illegal_seen = illegal_seen + 1;
            cycle = cycle + 1;
        end
    endtask

    task check_pc;
        input [31:0] expected;
        input [8*32-1:0] label_text;
        begin
            if (pc !== expected) begin
                $display("FAIL PC %0s expected=%08h actual=%08h", label_text, expected, pc);
                failures = failures + 1;
            end else $display("PASS PC %0s = %08h", label_text, expected);
        end
    endtask

    initial begin
        $display("\n=== FULL SINGLE-CYCLE CPU REGRESSION ===");
        // Integer and immediate operations, upper immediates, and word RAM.
        load_word(0,   enc_i(12'hfff, 0, 3'b000, 1, 7'b0010011)); // addi x1,x0,-1
        load_word(4,   enc_i(12'h001, 0, 3'b000, 2, 7'b0010011)); // addi x2,x0,1
        load_word(8,   enc_r(0, 2, 1, 3'b000, 3));                 // add x3,x1,x2
        load_word(12,  enc_r(7'b0100000, 2, 1, 3'b000, 25));      // sub x25,x1,x2
        load_word(16,  enc_r(0, 2, 1, 3'b111, 26));               // and x26,x1,x2
        load_word(20,  enc_r(0, 2, 1, 3'b110, 27));               // or x27,x1,x2
        load_word(24,  enc_r(0, 2, 1, 3'b100, 28));               // xor x28,x1,x2
        load_word(28,  enc_r(0, 2, 1, 3'b001, 29));               // sll x29,x1,x2
        load_word(32,  enc_r(0, 2, 1, 3'b101, 30));               // srl x30,x1,x2
        load_word(36,  enc_r(0, 2, 1, 3'b010, 4));                // slt x4,x1,x2
        load_word(40,  enc_r(0, 2, 1, 3'b011, 5));                // sltu x5,x1,x2
        load_word(44,  enc_i(12'h401, 1, 3'b101, 6, 7'b0010011)); // srai x6,x1,1
        load_word(48,  enc_i(12'h01f, 2, 3'b001, 7, 7'b0010011)); // slli x7,x2,31
        load_word(52,  enc_u(20'h12345, 8, 7'b0110111));          // lui x8,0x12345
        load_word(56,  enc_u(20'h00001, 9, 7'b0010111));          // auipc x9,1
        load_word(60,  enc_s(12'd4, 8, 0, 3'b010));               // sw x8,4(x0)
        load_word(64,  enc_i(12'd4, 0, 3'b010, 10, 7'b0000011)); // lw x10,4(x0)

        // Both outcomes of BEQ/BNE, and signed/unsigned LT/GE boundaries.
        load_word(68,  enc_b(13'd8, 2, 3, 3'b000));               // beq false
        load_word(72,  enc_i(12'd17, 0, 0, 17, 7'b0010011));     // executes
        load_word(76,  enc_b(13'd8, 0, 3, 3'b001));               // bne false
        load_word(80,  enc_i(12'd18, 0, 0, 18, 7'b0010011));     // executes
        load_word(84,  enc_b(13'd8, 0, 3, 3'b000));               // beq true -> 92
        load_word(88,  enc_i(12'd99, 0, 0, 16, 7'b0010011));     // skipped
        load_word(92,  enc_b(13'd8, 2, 3, 3'b001));               // bne true -> 100
        load_word(96,  enc_i(12'd98, 0, 0, 16, 7'b0010011));     // skipped
        load_word(100, enc_b(13'd8, 2, 1, 3'b100));               // blt true -> 108
        load_word(104, enc_i(12'd97, 0, 0, 16, 7'b0010011));     // skipped
        load_word(108, enc_b(13'd8, 2, 1, 3'b101));               // bge false
        load_word(112, enc_i(12'd19, 0, 0, 19, 7'b0010011));     // executes
        load_word(116, enc_b(13'd8, 2, 1, 3'b110));               // bltu false
        load_word(120, enc_i(12'd20, 0, 0, 20, 7'b0010011));     // executes
        load_word(124, enc_b(13'd8, 2, 1, 3'b111));               // bgeu true -> 132
        load_word(128, enc_i(12'd96, 0, 0, 16, 7'b0010011));     // skipped

        // PC-relative JAL, odd JALR target bit clearing, and illegal opcode.
        load_word(132, enc_j(21'd8, 11));                         // jal x11,+8 -> 140
        load_word(136, enc_i(12'd95, 0, 0, 16, 7'b0010011));     // skipped
        load_word(140, enc_i(12'd21, 0, 0, 21, 7'b0010011));    // executes
        load_word(144, enc_i(12'd149, 0, 0, 15, 7'b0010011));   // odd base
        load_word(148, enc_i(12'd7, 15, 0, 14, 7'b1100111));    // jalr -> 156 (149+7, clear bit 0)
        load_word(152, enc_i(12'd22, 0, 0, 22, 7'b0010011));    // skipped by JALR
        load_word(156, enc_j(21'd8, 23));                        // jal x23,+8 -> 164
        load_word(160, enc_i(12'd94, 0, 0, 24, 7'b0010011));   // skipped
        load_word(164, 32'hffff_ffff);                           // illegal, no state write
        // Immediate logic/compare/shift families and minimum signed imm.
        load_word(168, enc_i(12'd1, 1, 3'b111, 24, 7'b0010011)); // andi x24,x1,1
        load_word(172, enc_i(12'd5, 0, 3'b110, 13, 7'b0010011)); // ori x13,x0,5
        load_word(176, enc_i(12'd5, 1, 3'b100, 12, 7'b0010011)); // xori x12,x1,5
        load_word(180, enc_i(12'd1, 1, 3'b010, 3, 7'b0010011)); // slti x3,x1,1
        load_word(184, enc_i(12'd1, 1, 3'b011, 5, 7'b0010011)); // sltiu x5,x1,1
        load_word(188, enc_i(12'd1, 1, 3'b101, 6, 7'b0010011)); // srli x6,x1,1
        load_word(192, enc_i(12'h800, 0, 3'b000, 2, 7'b0010011));// addi x2,x0,-2048
        load_word(196, enc_r(7'b0100000, 4, 7, 3'b101, 3));     // sra x3,x7,x4

        // Reset is synchronous for PC and asynchronous for the register file.
        @(negedge clk);
        reset = 1'b0;
        enable = 1'b0;
        @(posedge clk); #1;
        check_pc(32'd0, "held while disabled");
        check_reg(5'd0, 32'd0);
        check_reg(5'd1, 32'd0);

        $display("\n--- Instruction-by-instruction execution trace ---");
        enable = 1'b1;
        repeat (44) begin
            @(negedge clk);
            trace_instruction();
            @(posedge clk); #1;
        end

        $display("\n--- Architectural state checks ---");
        check_reg(0, 0);
        check_reg(1, 32'hffff_ffff);
        check_reg(2, 32'hffff_f800);
        check_reg(3, 32'hc000_0000);
        check_reg(4, 1);
        check_reg(5, 0);
        check_reg(6, 32'h7fff_ffff);
        check_reg(7, 32'h8000_0000);
        check_reg(8, 32'h1234_5000);
        check_reg(9, 32'h0000_1038);
        check_reg(10, 32'h1234_5000);
        check_reg(11, 32'd136);
        check_reg(14, 32'd152);
        check_reg(15, 32'd149);
        check_reg(16, 0);
        check_reg(17, 17);
        check_reg(18, 18);
        check_reg(19, 19);
        check_reg(20, 20);
        check_reg(21, 21);
        check_reg(22, 0);
        check_reg(23, 32'd160);
        check_reg(25, 32'hffff_fffe);
        check_reg(26, 1);
        check_reg(27, 32'hffff_ffff);
        check_reg(28, 32'hffff_fffe);
        check_reg(29, 32'hffff_fffe);
        check_reg(30, 32'h7fff_ffff);
        check_reg(12, 32'hffff_fffa);
        check_reg(13, 5);
        check_reg(24, 1);
        check_reg(31, 0);
        if (dut.u_dmem.memory[0] !== 32'd0 ||
            dut.u_dmem.memory[1] !== 32'h1234_5000) begin
            $display("FAIL data memory [0]=%08h [1]=%08h",
                     dut.u_dmem.memory[0], dut.u_dmem.memory[1]);
            failures = failures + 1;
        end else $display("PASS data memory word 1 = 12345000; word 0 unchanged");
        if (illegal_seen != 1) begin
            $display("FAIL expected one illegal instruction, observed %0d", illegal_seen);
            failures = failures + 1;
        end else $display("PASS illegal instruction reported once and caused no register write");

        // Holding enable low must freeze the PC and all state updates.
        enable = 1'b0;
        @(negedge clk);
        begin : hold_check
            reg [31:0] held_pc;
            held_pc = pc;
            @(posedge clk); #1;
            if (pc !== held_pc) begin
                $display("FAIL PC changed while enable=0: %08h -> %08h", held_pc, pc);
                failures = failures + 1;
            end else $display("PASS PC holds while enable=0");
        end

        // Reset clears registers and PC, while RAM contents are retained.
        reset = 1'b1;
        #1;
        check_reg(1, 0);
        @(posedge clk); #1;
        check_pc(0, "reset");
        if (dut.u_dmem.memory[1] !== 32'h1234_5000) begin
            $display("FAIL data RAM did not retain value across CPU reset");
            failures = failures + 1;
        end else $display("PASS data RAM retained contents across CPU reset");

        $display("\n==============================================");
        if (failures == 0)
            $display("FULL CPU REGRESSION: PASS");
        else
            $display("FULL CPU REGRESSION: FAIL (%0d checks)", failures);
        $display("==============================================");
        $finish;
    end
endmodule
