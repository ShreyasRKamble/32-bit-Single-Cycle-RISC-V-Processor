`timescale 1ns/1ps

// Integration smoke test for the complete single-cycle RV32I datapath.
module single_cycle_cpu_tb;
    reg clk = 1'b0;
    reg reset = 1'b1;
    reg enable = 1'b0;
    reg imem_load_we = 1'b0;
    reg [31:0] imem_load_address = 32'b0;
    reg [31:0] imem_load_instruction = 32'b0;
    wire [31:0] pc;
    wire [31:0] instruction;
    wire illegal_instruction;
    integer failures = 0;
    integer cycle = 0;

    always #5 clk = ~clk;

    single_cycle_cpu #(.IMEM_DEPTH(32), .DMEM_DEPTH(16)) dut (
        .clk(clk), .reset(reset), .enable(enable),
        .imem_load_we(imem_load_we),
        .imem_load_address(imem_load_address),
        .imem_load_instruction(imem_load_instruction),
        .pc(pc), .instruction(instruction),
        .illegal_instruction(illegal_instruction)
    );

    task load_instruction;
        input [31:0] address;
        input [31:0] word;
        begin
            @(negedge clk);
            imem_load_we = 1'b1;
            imem_load_address = address;
            imem_load_instruction = word;
            @(negedge clk);
            imem_load_we = 1'b0;
        end
    endtask

    task step;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task print_trace_header;
        begin
            $display("");
            $display("============================================================================================================================");
            $display(" SINGLE-CYCLE RV32I DATAPATH TRACE");
            $display(" clk edge shows the instruction currently at PC; writes commit on that rising edge.");
            $display("============================================================================================================================");
            $display(" cyc | PC       | instruction | opcode  | rd rs1 rs2 | rs1 value | rs2 value | immediate | ALU result | controls R/M/W B/J | next PC  ");
            $display("-----+----------+-------------+---------+-----------+-----------+-----------+-----------+------------+------------------+----------");
        end
    endtask

    task print_cycle;
        reg [31:0] shown_next_pc;
        begin
            // Predict the PC selected by the current branch/jump instruction.
            shown_next_pc = dut.pc_plus_4;
            if (dut.branch && dut.alu_result[0])
                shown_next_pc = pc + dut.immediate;
            if (dut.jump) begin
                if (dut.jalr)
                    shown_next_pc = (dut.rs1_value + dut.immediate) & 32'hffff_fffe;
                else
                    shown_next_pc = pc + dut.immediate;
            end

            $display(" %3d | %08h | %08h  | %02h    | %02d %02d %02d | %08h  | %08h  | %08h  | %08h   | %b/%b/%b %b/%b  | %08h",
                cycle, pc, instruction, instruction[6:0], instruction[11:7],
                instruction[19:15], instruction[24:20], dut.rs1_value,
                dut.rs2_value, dut.immediate, dut.alu_result,
                dut.reg_write && enable, dut.mem_read,
                dut.mem_write && enable, dut.branch, dut.jump, shown_next_pc);
            $display("     ALU unit=%b function=%b flags={negative:%b zero:%b overflow:%b carry:%b} | memory[address=%08h] read=%08h store_data=%08h | writeback=%08h illegal=%b",
                dut.alu_unit_sel, dut.alu_func_sel, dut.alu_negative,
                dut.alu_zero, dut.alu_overflow, dut.alu_cout, dut.alu_result,
                dut.memory_data, dut.rs2_value, dut.writeback_data,
                illegal_instruction);
            cycle = cycle + 1;
        end
    endtask

    task check_register;
        input [4:0] index;
        input [31:0] expected;
        begin
            if (dut.u_register_file.registers[index] !== expected) begin
                $display("FAIL x%0d expected=%08h actual=%08h", index, expected,
                         dut.u_register_file.registers[index]);
                failures = failures + 1;
            end else begin
                $display("PASS x%0d = %08h", index, expected);
            end
        end
    endtask

    initial begin
        // addi x1,x0,5; addi x2,x1,7; sw x2,0(x0); lw x3,0(x0)
        // beq x2,x3,+8; addi x4,x0,99 (skipped); addi x4,x0,1
        load_instruction(32'd0,  32'h0050_0093);
        load_instruction(32'd4,  32'h0070_8113);
        load_instruction(32'd8,  32'h0020_2023);
        load_instruction(32'd12, 32'h0000_2183);
        load_instruction(32'd16, 32'h0031_0463);
        load_instruction(32'd20, 32'h0630_0213);
        load_instruction(32'd24, 32'h0010_0213);

        // Release reset and let the seven instruction slots execute.
        @(negedge clk);
        reset = 1'b0;
        enable = 1'b1;
        print_trace_header();
        repeat (7) begin
            print_cycle();
            step();
        end

        $display("");
        $display("================ FINAL STATE ================");
        $display("PC=%08h instruction=%08h illegal=%b", pc, instruction, illegal_instruction);
        $display("registers x0-x7:");
        $display(" x0=%08h x1=%08h x2=%08h x3=%08h", dut.u_register_file.registers[0],
                 dut.u_register_file.registers[1], dut.u_register_file.registers[2],
                 dut.u_register_file.registers[3]);
        $display(" x4=%08h x5=%08h x6=%08h x7=%08h", dut.u_register_file.registers[4],
                 dut.u_register_file.registers[5], dut.u_register_file.registers[6],
                 dut.u_register_file.registers[7]);
        $display("data memory words [0..3]:");
        $display(" [0] %08h  [1] %08h  [2] %08h  [3] %08h", dut.u_dmem.memory[0],
                 dut.u_dmem.memory[1], dut.u_dmem.memory[2], dut.u_dmem.memory[3]);

        check_register(5'd1, 32'd5);
        check_register(5'd2, 32'd12);
        check_register(5'd3, 32'd12);
        check_register(5'd4, 32'd1);
        if (dut.u_dmem.memory[0] !== 32'd12) begin
            $display("FAIL memory[0] expected=0000000c actual=%08h", dut.u_dmem.memory[0]);
            failures = failures + 1;
        end else begin
            $display("PASS memory[0] = 0000000c");
        end
        if (illegal_instruction !== 1'b0) begin
            $display("FAIL unexpected illegal instruction at pc=%08h: %08h", pc, instruction);
            failures = failures + 1;
        end

        if (failures == 0)
            $display("RESULT: PASS - all single_cycle_cpu integration checks passed.");
        else
            $display("RESULT: FAIL - %0d single_cycle_cpu integration check(s) failed.", failures);
        $finish;
    end
endmodule
