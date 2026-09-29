module cla_8bit(
    input  [7:0] A,
    input  [7:0] B,
    input        Cin,

    output [7:0] Sum,
    output       Cout
);

wire [7:0] P, G;
wire [8:0] C;

assign C[0] = Cin;

// Propagate and Generate
assign P = A ^ B;
assign G = A & B;

// Carry Logic
assign C[1] = G[0] | (P[0] & C[0]);

assign C[2] = G[1]
            | (P[1] & G[0])
            | (P[1] & P[0] & C[0]);

assign C[3] = G[2]
            | (P[2] & G[1])
            | (P[2] & P[1] & G[0])
            | (P[2] & P[1] & P[0] & C[0]);

assign C[4] = G[3]
            | (P[3] & G[2])
            | (P[3] & P[2] & G[1])
            | (P[3] & P[2] & P[1] & G[0])
            | (P[3] & P[2] & P[1] & P[0] & C[0]);

assign C[5] = G[4]
            | (P[4] & G[3])
            | (P[4] & P[3] & G[2])
            | (P[4] & P[3] & P[2] & G[1])
            | (P[4] & P[3] & P[2] & P[1] & G[0])
            | (P[4] & P[3] & P[2] & P[1] & P[0] & C[0]);

assign C[6] = G[5]
            | (P[5] & G[4])
            | (P[5] & P[4] & G[3])
            | (P[5] & P[4] & P[3] & G[2])
            | (P[5] & P[4] & P[3] & P[2] & G[1])
            | (P[5] & P[4] & P[3] & P[2] & P[1] & G[0])
            | (P[5] & P[4] & P[3] & P[2] & P[1] & P[0] & C[0]);

assign C[7] = G[6]
            | (P[6] & G[5])
            | (P[6] & P[5] & G[4])
            | (P[6] & P[5] & P[4] & G[3])
            | (P[6] & P[5] & P[4] & P[3] & G[2])
            | (P[6] & P[5] & P[4] & P[3] & P[2] & G[1])
            | (P[6] & P[5] & P[4] & P[3] & P[2] & P[1] & G[0])
            | (P[6] & P[5] & P[4] & P[3] & P[2] & P[1] & P[0] & C[0]);

assign C[8] = G[7]
            | (P[7] & C[7]);

// Sum
assign Sum[0] = P[0] ^ C[0];
assign Sum[1] = P[1] ^ C[1];
assign Sum[2] = P[2] ^ C[2];
assign Sum[3] = P[3] ^ C[3];
assign Sum[4] = P[4] ^ C[4];
assign Sum[5] = P[5] ^ C[5];
assign Sum[6] = P[6] ^ C[6];
assign Sum[7] = P[7] ^ C[7];

assign Cout = C[8];

endmodule