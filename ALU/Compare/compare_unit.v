`timescale 1ns/1ps

module compare_unit(
    input  [31:0] A,
    input  [31:0] B,
    input  [3:0]  op,

    output reg [31:0] result
);

localparam EQ  = 4'b0000;
localparam NE  = 4'b0001;
localparam UGT = 4'b0010;
localparam ULT = 4'b0011;
localparam UGE = 4'b0100;
localparam ULE = 4'b0101;
localparam SGT = 4'b0110;
localparam SLT = 4'b0111;
localparam SGE = 4'b1000;
localparam SLE = 4'b1001;

always @(*) begin

    case(op)

        EQ  : result = (A == B) ? 32'd1 : 32'd0;
        NE  : result = (A != B) ? 32'd1 : 32'd0;
        UGT : result = (A >  B) ? 32'd1 : 32'd0;
        ULT : result = (A <  B) ? 32'd1 : 32'd0;
        UGE : result = (A >= B) ? 32'd1 : 32'd0;
        ULE : result = (A <= B) ? 32'd1 : 32'd0;
        SGT : result = ($signed(A) >  $signed(B)) ? 32'd1 : 32'd0;
        SLT : result = ($signed(A) <  $signed(B)) ? 32'd1 : 32'd0;
        SGE : result = ($signed(A) >= $signed(B)) ? 32'd1 : 32'd0;
        SLE : result = ($signed(A) <= $signed(B)) ? 32'd1 : 32'd0;

        default : result = 32'd0;

    endcase

end

endmodule
