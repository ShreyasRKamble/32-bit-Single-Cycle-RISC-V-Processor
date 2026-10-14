`timescale 1ns/1ps

// Combinational, word-addressed instruction ROM for an RV32I datapath.
// pc is a byte address; the low two bits are ignored (RV32I, no C extension).
// Initialize contents with $readmemh using INIT_FILE, or write words via the
// optional simulation/bring-up loader port. Reads outside DEPTH return NOP.
module instruction_memory #(
    parameter integer DEPTH = 256,
    parameter INIT_FILE = ""
) (
    input  wire        clk,
    input  wire [31:0] pc,
    output reg  [31:0] instruction,
    input  wire        load_we,
    input  wire [31:0] load_address,
    input  wire [31:0] load_instruction
);

    localparam [31:0] NOP = 32'h0000_0013; // ADDI x0, x0, 0
    localparam integer ADDR_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH);

    reg [31:0] memory [0:DEPTH-1];
    integer i;
    wire [31:0] word_index = pc >> 2;
    wire [31:0] load_word_index = load_address >> 2;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            memory[i] = NOP;
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, memory);
    end

    // Asynchronous fetch keeps this ROM compatible with a single-cycle CPU.
    always @(*) begin
        if ((^pc[31:2]) === 1'bx)
            instruction = 32'hxxxx_xxxx;
        else if (word_index < DEPTH)
            instruction = memory[word_index[ADDR_WIDTH-1:0]];
        else
            instruction = NOP;
    end

    // Loader is intended for simulation and FPGA bring-up; tie load_we low
    // when the memory is used as a pure ROM.
    always @(posedge clk) begin
        if (load_we && (load_address[1:0] == 2'b00) &&
            (load_word_index < DEPTH))
            memory[load_word_index[ADDR_WIDTH-1:0]] <= load_instruction;
    end

endmodule
