`timescale 1ns/1ps

// RV32 program counter with sequential, branch, JAL, and JALR targets.
module program_counter (
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire        branch,
    input  wire        branch_taken,
    input  wire        jump,
    input  wire        jalr,
    input  wire [31:0] immediate,
    input  wire [31:0] rs1_value,
    output reg  [31:0] pc,
    output wire [31:0] pc_plus_4
);

    wire [31:0] branch_addr = pc + immediate;
    wire [31:0] jalr_addr   = (rs1_value + immediate) & 32'hffff_fffe;

    assign pc_plus_4 = pc + 32'd4;

    reg [31:0] next_pc;

    always @(*) begin
        next_pc = pc_plus_4;

        if (branch && branch_taken)
            next_pc = branch_addr;

        // JALR selects its register-relative target; other jumps use PC-relative.
        if (jump) begin
            if (jalr)
                next_pc = jalr_addr;
            else
                next_pc = branch_addr;
        end
    end

    always @(posedge clk) begin
        if (reset)
            pc <= 32'b0;
        else if (enable)
            pc <= next_pc;
    end

endmodule
