`timescale 1ns/1ps

module alu_top(
    input  [31:0] A,
    input  [31:0] B,

    input  [1:0]  unit_sel,
    input  [3:0]  func_sel,

    input  [4:0]  shift_amt,

    output reg [31:0] result,
    output cout,

    output zero,
    output negative,
    output overflow
);


//----------------------------------------------------
// Internal Results
//----------------------------------------------------

wire [31:0] arith_result;
wire [31:0] logic_result;
wire [31:0] shift_result;
wire [31:0] compare_result;

wire arith_cout;

wire add_overflow;
wire sub_overflow;


//----------------------------------------------------
// Arithmetic Unit
//----------------------------------------------------

arithmetic_unit u_arithmetic (
    .A(A),
    .B(B),
    .op(func_sel[2:0]),
    .result(arith_result),
    .cout(arith_cout)
);


// Signed Addition Overflow
assign add_overflow =
       (func_sel == 4'b0000) &&
       (A[31] == B[31]) &&
       (arith_result[31] != A[31]);


// Signed Subtraction Overflow
assign sub_overflow =
       (func_sel == 4'b0001) &&
       (A[31] != B[31]) &&
       (arith_result[31] != A[31]);


// Overflow is valid only for Arithmetic Unit
assign overflow =
       (unit_sel == 2'b00) &&
       (add_overflow || sub_overflow);


//----------------------------------------------------
// Logic Unit
//----------------------------------------------------

logic_unit u_logic (
    .A(A),
    .B(B),
    .op(func_sel[2:0]),
    .result(logic_result)
);


//----------------------------------------------------
// Shift Unit
//----------------------------------------------------

shift_unit u_shift (
    .A(A),
    .shift_amt(shift_amt),
    .op(func_sel),
    .result(shift_result)
);


//----------------------------------------------------
// Compare Unit
//----------------------------------------------------

compare_unit u_compare (
    .A(A),
    .B(B),
    .op(func_sel[2:0]),
    .result(compare_result)
);


//----------------------------------------------------
// Final ALU Result MUX
//----------------------------------------------------

always @(*) begin

    case(unit_sel)

        2'b00: result = arith_result;

        2'b01: result = logic_result;

        2'b10: result = shift_result;

        2'b11: result = compare_result;

        default: result = 32'b0;

    endcase

end


//----------------------------------------------------
// Carry Output
//----------------------------------------------------

assign cout =
       (unit_sel == 2'b00) ? arith_cout : 1'b0;


//----------------------------------------------------
// Status Flags
//----------------------------------------------------

assign zero     = (result == 32'b0);

assign negative = result[31];

endmodule
