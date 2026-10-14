`timescale 1ns/1ps

// Small word-addressed RAM for the LW/SW subset used by the RV32I core.
// Addresses are byte addresses; the low two bits are ignored.
module data_memory #(
    parameter integer DEPTH = 256,
    parameter INIT_FILE = ""
) (
    input  wire        clk,
    input  wire        read_enable,
    input  wire        write_enable,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);
    localparam integer ADDR_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
    reg [31:0] memory [0:DEPTH-1];
    wire [31:0] word_index = address >> 2;
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            memory[i] = 32'b0;
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, memory);
    end

    // Combinational read keeps load instructions single-cycle.
    always @(*) begin
        if (!read_enable)
            read_data = 32'b0;
        else if ((^address[31:2]) === 1'bx)
            read_data = 32'hxxxx_xxxx;
        else if (word_index < DEPTH)
            read_data = memory[word_index[ADDR_WIDTH-1:0]];
        else
            read_data = 32'b0;
    end

    // Stores commit at the active clock edge.
    always @(posedge clk) begin
        if (write_enable && (address[1:0] == 2'b00) &&
            (word_index < DEPTH))
            memory[word_index[ADDR_WIDTH-1:0]] <= write_data;
    end
endmodule
