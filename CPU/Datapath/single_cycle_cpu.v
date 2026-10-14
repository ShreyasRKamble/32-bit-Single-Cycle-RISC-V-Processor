`timescale 1ns/1ps

// Complete single-cycle RV32I datapath (R/I arithmetic, byte/half/word memory,
// JAL/JALR, LUI and AUIPC). Each instruction retires on one rising edge.
module single_cycle_cpu #(
    parameter integer IMEM_DEPTH = 256,
    parameter integer DMEM_DEPTH = 256,
    parameter IMEM_INIT_FILE = "",
    parameter DMEM_INIT_FILE = ""
) (
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire        imem_load_we,
    input  wire [31:0] imem_load_address,
    input  wire [31:0] imem_load_instruction,
    output wire [31:0] pc,
    output wire [31:0] instruction,
    output wire        illegal_instruction
);
    wire [31:0] pc_plus_4, immediate;
    wire reg_write, mem_read, mem_write;
    wire alu_src, branch, jump;
    wire [1:0] alu_unit_sel, writeback_sel;
    wire [3:0] alu_func_sel;
    wire [31:0] rs1_value, rs2_value, alu_a, alu_b;
    wire memory_access_aligned;
    wire [4:0] alu_shift_amt;
    wire [31:0] alu_result, memory_data, writeback_data;
    wire alu_zero, alu_negative, alu_overflow, alu_cout;
    wire branch_taken = branch && (alu_result[0] == 1'b1);
    wire jalr = (instruction[6:0] == 7'b1100111);
    assign memory_access_aligned = (instruction[14:12] == 3'b000 ||
                                    instruction[14:12] == 3'b100) ? 1'b1 :
                                   (instruction[14:12] == 3'b001 ||
                                    instruction[14:12] == 3'b101) ? !alu_result[0] :
                                   (instruction[14:12] == 3'b010) ?
                                       (alu_result[1:0] == 2'b00) : 1'b0;

    program_counter u_pc (
        .clk(clk), .reset(reset), .enable(enable),
        .branch(branch), .branch_taken(branch_taken), .jump(jump), .jalr(jalr),
        .immediate(immediate), .rs1_value(rs1_value), .pc(pc), .pc_plus_4(pc_plus_4)
    );

    instruction_memory #(.DEPTH(IMEM_DEPTH), .INIT_FILE(IMEM_INIT_FILE)) u_imem (
        .clk(clk), .pc(pc), .instruction(instruction),
        .load_we(imem_load_we), .load_address(imem_load_address),
        .load_instruction(imem_load_instruction)
    );

    control_unit u_control (
        .instruction(instruction), .reg_write(reg_write), .mem_read(mem_read),
        .mem_write(mem_write), .mem_to_reg(), .alu_src(alu_src),
        .branch(branch), .jump(jump), .alu_unit_sel(alu_unit_sel),
        .alu_func_sel(alu_func_sel), .writeback_sel(writeback_sel),
        .branch_funct3(), .illegal_instruction(illegal_instruction)
    );

    imm_gen u_imm_gen (.instruction(instruction), .immediate(immediate));

    register_file u_register_file (
        .clk(clk), .rst(reset),
        .reg_write(reg_write && enable &&
                   (!(mem_read || mem_write) || memory_access_aligned)),
        .rs1(instruction[19:15]), .rs2(instruction[24:20]),
        .rd(instruction[11:7]), .write_data(writeback_data),
        .read_data1(rs1_value), .read_data2(rs2_value)
    );

    // AUIPC adds the PC to its U-immediate; all other ALU operations use rs1.
    assign alu_a = (instruction[6:0] == 7'b0010111) ? pc : rs1_value;
    assign alu_b = alu_src ? immediate : rs2_value;
    // Register shifts use rs2's value; immediate shifts use shamt[4:0].
    assign alu_shift_amt = alu_src ? instruction[24:20] : rs2_value[4:0];

    alu_top u_alu (
        .A(alu_a), .B(alu_b), .unit_sel(alu_unit_sel), .func_sel(alu_func_sel),
        .shift_amt(alu_shift_amt), .result(alu_result), .cout(alu_cout),
        .zero(alu_zero), .negative(alu_negative), .overflow(alu_overflow)
    );

    data_memory #(.DEPTH(DMEM_DEPTH), .INIT_FILE(DMEM_INIT_FILE)) u_dmem (
        .clk(clk), .read_enable(mem_read && memory_access_aligned),
        .write_enable(mem_write && enable && memory_access_aligned),
        .address(alu_result), .funct3(instruction[14:12]),
        .write_data(rs2_value), .read_data(memory_data)
    );

    // Compare results are Boolean words, so bit zero drives all branch types.
    assign writeback_data = (writeback_sel == 2'b01) ? memory_data :
                            (writeback_sel == 2'b10) ? pc_plus_4 :
                            (writeback_sel == 2'b11) ? immediate : alu_result;

    // With no trap path, misaligned memory operations are ignored.
endmodule
