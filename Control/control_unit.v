`timescale 1ns/1ps

// Combinational RV32I instruction decoder for the single-cycle datapath.
// alu_unit_sel/alu_func_sel use the encodings consumed by alu_top.v.
module control_unit (
    input  wire [31:0] instruction,

    output reg         reg_write,
    output reg         mem_read,
    output reg         mem_write,
    output reg         mem_to_reg,
    output reg         alu_src,
    output reg         branch,
    output reg         jump,
    output reg  [1:0]  alu_unit_sel,
    output reg  [3:0]  alu_func_sel,
    output reg  [1:0]  writeback_sel,
    output reg  [2:0]  branch_funct3,
    output reg         illegal_instruction
);

    localparam [1:0] UNIT_ARITH = 2'b00;
    localparam [1:0] UNIT_LOGIC = 2'b01;
    localparam [1:0] UNIT_SHIFT = 2'b10;
    localparam [1:0] UNIT_CMP   = 2'b11;

    // writeback_sel: 00=ALU, 01=memory, 10=PC+4, 11=immediate.
    localparam [1:0] WB_ALU  = 2'b00;
    localparam [1:0] WB_MEM  = 2'b01;
    localparam [1:0] WB_PC4  = 2'b10;
    localparam [1:0] WB_IMM  = 2'b11;

    wire [6:0] opcode = instruction[6:0];
    wire [2:0] funct3 = instruction[14:12];
    wire [6:0] funct7 = instruction[31:25];

    // ALU operation encodings from arithmetic_unit, logic_unit,
    // shift_unit and compare_unit.
    localparam [3:0] ALU_ADD = 4'b0000;
    localparam [3:0] ALU_SUB = 4'b0001;
    localparam [3:0] ALU_AND = 4'b0000;
    localparam [3:0] ALU_OR  = 4'b0001;
    localparam [3:0] ALU_XOR = 4'b0010;
    localparam [3:0] ALU_SLL = 4'b0101;
    localparam [3:0] ALU_SRL = 4'b0110;
    localparam [3:0] ALU_SRA = 4'b0111;
    localparam [3:0] CMP_EQ  = 4'b0000;
    localparam [3:0] CMP_NE  = 4'b0001;
    localparam [3:0] CMP_UGT = 4'b0010;
    localparam [3:0] CMP_ULT = 4'b0011;
    localparam [3:0] CMP_UGE = 4'b0100;
    localparam [3:0] CMP_ULE = 4'b0101;
    localparam [3:0] CMP_SGT = 4'b0110;
    localparam [3:0] CMP_SLT = 4'b0111;
    localparam [3:0] CMP_SGE = 4'b1000;
    localparam [3:0] CMP_SLE = 4'b1001;

    always @(*) begin
        reg_write          = 1'b0;
        mem_read           = 1'b0;
        mem_write          = 1'b0;
        mem_to_reg         = 1'b0;
        alu_src            = 1'b0;
        branch             = 1'b0;
        jump               = 1'b0;
        alu_unit_sel       = UNIT_ARITH;
        alu_func_sel       = ALU_ADD;
        writeback_sel      = WB_ALU;
        branch_funct3      = funct3;
        illegal_instruction = 1'b0;

        case (opcode)
            // R-type integer register-register operations.
            7'b0110011: begin
                reg_write = 1'b1;
                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0000000)
                            alu_func_sel = ALU_ADD;
                        else if (funct7 == 7'b0100000)
                            alu_func_sel = ALU_SUB;
                        else illegal_instruction = 1'b1;
                    end
                    3'b111: begin
                        alu_unit_sel = UNIT_LOGIC;
                        alu_func_sel = ALU_AND;
                        if (funct7 != 7'b0000000) illegal_instruction = 1'b1;
                    end
                    3'b110: begin
                        alu_unit_sel = UNIT_LOGIC;
                        alu_func_sel = ALU_OR;
                        if (funct7 != 7'b0000000) illegal_instruction = 1'b1;
                    end
                    3'b100: begin
                        alu_unit_sel = UNIT_LOGIC;
                        alu_func_sel = ALU_XOR;
                        if (funct7 != 7'b0000000) illegal_instruction = 1'b1;
                    end
                    3'b001: begin
                        alu_unit_sel = UNIT_SHIFT;
                        alu_func_sel = ALU_SLL;
                        if (funct7 != 7'b0000000) illegal_instruction = 1'b1;
                    end
                    3'b101: begin
                        alu_unit_sel = UNIT_SHIFT;
                        if (funct7 == 7'b0000000) alu_func_sel = ALU_SRL;
                        else if (funct7 == 7'b0100000) alu_func_sel = ALU_SRA;
                        else illegal_instruction = 1'b1;
                    end
                    3'b010: begin
                        alu_unit_sel = UNIT_CMP;
                        alu_func_sel = CMP_SLT;
                        if (funct7 != 7'b0000000) illegal_instruction = 1'b1;
                    end
                    3'b011: begin
                        alu_unit_sel = UNIT_CMP;
                        alu_func_sel = CMP_ULT;
                        if (funct7 != 7'b0000000) illegal_instruction = 1'b1;
                    end
                    default: illegal_instruction = 1'b1;
                endcase
            end

            // I-type ALU operations.
            7'b0010011: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                case (funct3)
                    3'b000: alu_func_sel = ALU_ADD; // ADDI
                    3'b111: begin alu_unit_sel = UNIT_LOGIC; alu_func_sel = ALU_AND; end
                    3'b110: begin alu_unit_sel = UNIT_LOGIC; alu_func_sel = ALU_OR;  end
                    3'b100: begin alu_unit_sel = UNIT_LOGIC; alu_func_sel = ALU_XOR; end
                    3'b001: begin // SLLI
                        alu_unit_sel = UNIT_SHIFT;
                        alu_func_sel = ALU_SLL;
                        if (instruction[31:25] != 7'b0000000) illegal_instruction = 1'b1;
                    end
                    3'b101: begin // SRLI / SRAI
                        alu_unit_sel = UNIT_SHIFT;
                        if (instruction[31:25] == 7'b0000000) alu_func_sel = ALU_SRL;
                        else if (instruction[31:25] == 7'b0100000) alu_func_sel = ALU_SRA;
                        else illegal_instruction = 1'b1;
                    end
                    3'b010: begin alu_unit_sel = UNIT_CMP; alu_func_sel = CMP_SLT; end // SLTI
                    3'b011: begin alu_unit_sel = UNIT_CMP; alu_func_sel = CMP_ULT; end // SLTIU
                    default: illegal_instruction = 1'b1;
                endcase
            end

            // RV32I byte, halfword, and word loads/stores.
            7'b0000011: begin
                if (funct3 == 3'b000 || funct3 == 3'b001 ||
                    funct3 == 3'b010 || funct3 == 3'b100 ||
                    funct3 == 3'b101) begin
                    reg_write = 1'b1;
                    mem_read = 1'b1;
                    mem_to_reg = 1'b1;
                    alu_src = 1'b1;
                    writeback_sel = WB_MEM;
                end else illegal_instruction = 1'b1;
            end
            7'b0100011: begin
                if (funct3 == 3'b000 || funct3 == 3'b001 ||
                    funct3 == 3'b010) begin
                    mem_write = 1'b1;
                    alu_src = 1'b1;
                end else illegal_instruction = 1'b1;
            end

            // Conditional branches; the compare operation follows funct3.
            7'b1100011: begin
                branch = 1'b1;
                alu_unit_sel = UNIT_CMP;
                case (funct3)
                    3'b000: alu_func_sel = CMP_EQ; // BEQ
                    3'b001: alu_func_sel = CMP_NE; // BNE
                    3'b100: alu_func_sel = CMP_SLT; // BLT
                    3'b101: alu_func_sel = CMP_SGE; // BGE
                    3'b110: alu_func_sel = CMP_ULT; // BLTU
                    3'b111: alu_func_sel = CMP_UGE; // BGEU
                    default: begin branch = 1'b0; illegal_instruction = 1'b1; end
                endcase
            end

            // Jumps and upper-immediate instructions.
            7'b1101111: begin // JAL
                reg_write = 1'b1;
                jump = 1'b1;
                writeback_sel = WB_PC4;
            end
            7'b1100111: begin // JALR
                if (funct3 == 3'b000) begin
                    reg_write = 1'b1;
                    alu_src = 1'b1;
                    jump = 1'b1;
                    writeback_sel = WB_PC4;
                end else illegal_instruction = 1'b1;
            end
            7'b0110111: begin // LUI
                reg_write = 1'b1;
                writeback_sel = WB_IMM;
            end
            7'b0010111: begin // AUIPC
                reg_write = 1'b1;
                alu_src = 1'b1;
                writeback_sel = WB_ALU;
            end

            default: illegal_instruction = 1'b1;
        endcase

        // An illegal encoding must not trigger an architectural state update.
        if (illegal_instruction) begin
            reg_write = 1'b0;
            mem_read = 1'b0;
            mem_write = 1'b0;
            branch = 1'b0;
            jump = 1'b0;
        end
    end

endmodule
