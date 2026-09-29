module register_file (
    input  wire        clk,
    input  wire        rst,
    input  wire        reg_write,

    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,

    input  wire [31:0] write_data,

    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

    // 32 registers, each 32 bits wide
    reg [31:0] registers [0:31];

    integer i;

    // Write operation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end
        else begin
            // x0 must always remain zero
            if (reg_write && (rd != 5'b00000))
                registers[rd] <= write_data;

            registers[0] <= 32'b0;
        end
    end

    // Asynchronous read
    assign read_data1 = (rs1 == 5'b00000) ? 32'b0 : registers[rs1];
    assign read_data2 = (rs2 == 5'b00000) ? 32'b0 : registers[rs2];

endmodule