`timescale 1ns/1ps

module logic_unit(
    input  [31:0] A,
    input  [31:0] B,
    input  [2:0]  op,

    output reg [31:0] result
);

localparam AND_OP = 3'b000;
localparam OR_OP  = 3'b001;
localparam XOR_OP = 3'b010;
localparam NOT_A  = 3'b011;
localparam NOT_B  = 3'b100;

always @(*) begin

    case(op)

        AND_OP: result = A & B;

        OR_OP : result = A | B;

        XOR_OP: result = A ^ B;

        NOT_A : result = ~A;

        NOT_B : result = ~B;

        default: result = 32'b0;

    endcase

end

endmodule