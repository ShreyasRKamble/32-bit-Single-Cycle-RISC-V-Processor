`timescale 1ns/1ps

module arithmetic_unit(
    input  [31:0] A,
    input  [31:0] B,
    input  [2:0]  op,
    output [31:0] result,
    output        cout
);

reg [31:0] X;
reg [31:0] Y;
reg        Cin;

localparam ADD   = 3'b000;
localparam SUB   = 3'b001;
localparam INC_A = 3'b010;
localparam DEC_A = 3'b011;
localparam INC_B = 3'b100;
localparam DEC_B = 3'b101;

wire sub_mode;
assign sub_mode = (op == SUB);

wire [31:0] B_mod;
assign B_mod = B ^ {32{sub_mode}};

always @(*) begin
    case(op)

        ADD: begin
            X   = A;
            Y   = B_mod;
            Cin = 1'b0;
        end

        SUB: begin
            X   = A;
            Y   = B_mod;
            Cin = 1'b1;
        end

        INC_A: begin
            X   = A;
            Y   = 32'b0;
            Cin = 1'b1;
        end

        DEC_A: begin
            X   = A;
            Y   = 32'hFFFFFFFF;
            Cin = 1'b0;
        end

        INC_B: begin
            X   = B;
            Y   = 32'b0;
            Cin = 1'b1;
        end

        DEC_B: begin
            X   = B;
            Y   = 32'hFFFFFFFF;
            Cin = 1'b0;
        end

        default: begin
            X   = 32'b0;
            Y   = 32'b0;
            Cin = 1'b0;
        end

    endcase
end

cla_32bit u_cla(
    .A(X),
    .B(Y),
    .Cin(Cin),
    .Sum(result),
    .Cout(cout)
);

endmodule