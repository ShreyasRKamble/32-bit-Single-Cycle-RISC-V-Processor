module cla_32bit(
    input  [31:0] A,
    input  [31:0] B,
    input         Cin,

    output [31:0] Sum,
    output        Cout
);

wire C8;
wire C16;
wire C24;
wire C32;

cla_8bit CLA0(
    .A(A[7:0]),
    .B(B[7:0]),
    .Cin(Cin),
    .Sum(Sum[7:0]),
    .Cout(C8)
);

cla_8bit CLA1(
    .A(A[15:8]),
    .B(B[15:8]),
    .Cin(C8),
    .Sum(Sum[15:8]),
    .Cout(C16)
);

cla_8bit CLA2(
    .A(A[23:16]),
    .B(B[23:16]),
    .Cin(C16),
    .Sum(Sum[23:16]),
    .Cout(C24)
);

cla_8bit CLA3(
    .A(A[31:24]),
    .B(B[31:24]),
    .Cin(C24),
    .Sum(Sum[31:24]),
    .Cout(C32)
);

assign Cout = C32;

endmodule