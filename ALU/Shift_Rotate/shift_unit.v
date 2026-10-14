`timescale 1ns/1ps

module shift_unit(
    input  [31:0] A,
    input  [4:0]  shift_amt,
    input  [3:0]  op,

    output reg [31:0] result
);

localparam SLL1 = 4'b0000;
localparam SRL1 = 4'b0001;
localparam SRA1 = 4'b0010;
localparam ROL1 = 4'b0011;
localparam ROR1 = 4'b0100;

localparam BSLL = 4'b0101;
localparam BSRL = 4'b0110;
localparam BSRA = 4'b0111;
localparam BROL = 4'b1000;
localparam BROR = 4'b1001;

always @(*) begin

    result = 32'b0;

    case(op)

        // 1-bit shifts
        SLL1 : result = A << 1;
        SRL1 : result = A >> 1;
        SRA1 : result = $signed(A) >>> 1;

        // 1-bit rotates
        ROL1 : result = {A[30:0], A[31]};
        ROR1 : result = {A[0], A[31:1]};

        // Barrel shifts
        BSLL : result = A << shift_amt;
        BSRL : result = A >> shift_amt;
        BSRA : result = $signed(A) >>> shift_amt;

        // Barrel rotates
        BROL : begin
            if(shift_amt == 0)
                result = A;
            else
                result = (A << shift_amt) |
                         (A >> (32 - shift_amt));
        end

        BROR : begin
            if(shift_amt == 0)
                result = A;
            else
                result = (A >> shift_amt) |
                         (A << (32 - shift_amt));
        end

        default : result = 32'b0;

    endcase

end

endmodule
