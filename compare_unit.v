`timescale 1ns/1ps

module compare_unit(
    input  [31:0] A,
    input  [31:0] B,
    input  [2:0]  op,

    output reg [31:0] result
);

localparam EQ  = 3'b000;
localparam NE  = 3'b001;
localparam GT  = 3'b010;
localparam LT  = 3'b011;
localparam GTE = 3'b100;
localparam LTE = 3'b101;

always @(*) begin

    case(op)

        EQ  : result = (A == B) ? 32'd1 : 32'd0;
        NE  : result = (A != B) ? 32'd1 : 32'd0;
        GT  : result = (A >  B) ? 32'd1 : 32'd0;
        LT  : result = (A <  B) ? 32'd1 : 32'd0;
        GTE : result = (A >= B) ? 32'd1 : 32'd0;
        LTE : result = (A <= B) ? 32'd1 : 32'd0;

        default : result = 32'd0;

    endcase

end

endmodule
