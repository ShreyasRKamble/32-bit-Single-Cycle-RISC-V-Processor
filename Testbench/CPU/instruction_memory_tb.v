`timescale 1ns/1ps

module instruction_memory_tb;
    reg clk;
    reg [31:0] pc;
    wire [31:0] instruction;
    reg load_we;
    reg [31:0] load_address;
    reg [31:0] load_instruction;
    integer failures;

    instruction_memory #(.DEPTH(4)) dut (
        .clk(clk), .pc(pc), .instruction(instruction),
        .load_we(load_we), .load_address(load_address),
        .load_instruction(load_instruction)
    );

    always #5 clk = ~clk;

    task check;
        input [31:0] addr;
        input [31:0] expected;
        input [8*32-1:0] label;
        begin
            pc = addr;
            #1;
            if (instruction !== expected) begin
                $display("FAIL %0s pc=%08h expected=%08h got=%08h", label, addr, expected, instruction);
                failures = failures + 1;
            end else $display("PASS %0s pc=%08h instruction=%08h", label, addr, instruction);
        end
    endtask

    initial begin
        clk = 0; pc = 0; load_we = 0; load_address = 0;
        load_instruction = 0; failures = 0;
        check(0, 32'h00000013, "initialized NOP");
        check(4, 32'h00000013, "next word NOP");

        // Load a four-instruction program, one word per rising edge.
        @(negedge clk); load_we = 1; load_address = 0;  load_instruction = 32'h00500093;
        @(posedge clk); #1;
        @(negedge clk); load_address = 4;  load_instruction = 32'h00700113;
        @(posedge clk); #1;
        @(negedge clk); load_address = 8;  load_instruction = 32'h002081b3;
        @(posedge clk); #1;
        @(negedge clk); load_address = 12; load_instruction = 32'h00302023;
        @(posedge clk); #1; load_we = 0;

        check(0, 32'h00500093, "program word 0");
        check(4, 32'h00700113, "program word 1");
        check(8, 32'h002081b3, "program word 2");
        check(12, 32'h00302023, "program word 3");
        check(1, 32'h00500093, "low PC bits ignored");
        check(16, 32'h00000013, "out of range returns NOP");

        @(negedge clk); load_we = 1; load_address = 2; load_instruction = 32'hffffffff;
        @(posedge clk); #1; load_we = 0;
        check(0, 32'h00500093, "unaligned load ignored");

        if (failures == 0) $display("All instruction_memory tests passed.");
        else $display("%0d instruction_memory test(s) failed.", failures);
        $finish;
    end
endmodule
