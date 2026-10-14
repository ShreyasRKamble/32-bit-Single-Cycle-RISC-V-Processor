`timescale 1ns/1ps

// Byte-addressed RV32I data RAM with byte, halfword, and word accesses.
module data_memory #(
    parameter integer DEPTH = 256,
    parameter INIT_FILE = ""
) (
    input  wire        clk,
    input  wire        read_enable,
    input  wire        write_enable,
    input  wire [31:0] address,
    input  wire [2:0]  funct3,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);
    localparam integer ADDR_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
    reg [31:0] memory [0:DEPTH-1];
    wire [31:0] word_index = address >> 2;
    wire access_aligned = (funct3 == 3'b000 || funct3 == 3'b100) ? 1'b1 :
                          (funct3 == 3'b001 || funct3 == 3'b101) ? !address[0] :
                          (funct3 == 3'b010) ? (address[1:0] == 2'b00) : 1'b0;
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            memory[i] = 32'b0;
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, memory);
    end

    reg [31:0] selected_word;
    reg [7:0] selected_byte;
    reg [15:0] selected_half;
    integer lane;

    // Combinational read keeps load instructions single-cycle.
    always @(*) begin
        selected_word = 32'b0;
        selected_byte = 8'b0;
        selected_half = 16'b0;
        lane = address[1:0];
        if (!read_enable)
            read_data = 32'b0;
        else if ((^address[31:2]) === 1'bx)
            read_data = 32'hxxxx_xxxx;
        else if (!access_aligned || word_index >= DEPTH)
            read_data = 32'b0;
        else begin
            selected_word = memory[word_index[ADDR_WIDTH-1:0]];
            selected_byte = selected_word[lane*8 +: 8];
            selected_half = selected_word[{address[1],4'b0} +: 16];
            case (funct3)
                3'b000: read_data = {{24{selected_byte[7]}}, selected_byte}; // LB
                3'b100: read_data = {24'b0, selected_byte};                  // LBU
                3'b001: read_data = {{16{selected_half[15]}}, selected_half};// LH
                3'b101: read_data = {16'b0, selected_half};                  // LHU
                3'b010: read_data = selected_word;                            // LW
                default: read_data = 32'b0;
            endcase
        end
    end

    // Stores commit at the active clock edge.
    always @(posedge clk) begin
        if (write_enable && (word_index < DEPTH)) begin
            case (funct3)
                3'b000: begin // SB
                    case (address[1:0])
                        2'd0: memory[word_index[ADDR_WIDTH-1:0]][7:0] <= write_data[7:0];
                        2'd1: memory[word_index[ADDR_WIDTH-1:0]][15:8] <= write_data[7:0];
                        2'd2: memory[word_index[ADDR_WIDTH-1:0]][23:16] <= write_data[7:0];
                        2'd3: memory[word_index[ADDR_WIDTH-1:0]][31:24] <= write_data[7:0];
                    endcase
                end
                3'b001: if (!address[0]) begin // SH
                    if (!address[1]) memory[word_index[ADDR_WIDTH-1:0]][15:0] <= write_data[15:0];
                    else memory[word_index[ADDR_WIDTH-1:0]][31:16] <= write_data[15:0];
                end
                3'b010: if (address[1:0] == 2'b00) // SW
                    memory[word_index[ADDR_WIDTH-1:0]] <= write_data;
                default: ;
            endcase
        end
    end
endmodule
