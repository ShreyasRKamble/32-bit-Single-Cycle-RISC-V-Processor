`timescale 1ns/1ps

module data_memory_tb;
    reg clk = 1'b0;
    reg read_enable = 1'b0;
    reg write_enable = 1'b0;
    reg [31:0] address = 0;
    reg [31:0] write_data = 0;
    wire [31:0] read_data;
    integer failures = 0;

    always #5 clk = ~clk;

    data_memory #(.DEPTH(4)) dut (
        .clk(clk), .read_enable(read_enable), .write_enable(write_enable),
        .address(address), .write_data(write_data), .read_data(read_data)
    );

    task check;
        input [31:0] expected;
        input [8*40-1:0] label_text;
        begin
            #1;
            if (read_data !== expected) begin
                $display("FAIL %0s expected=%08h actual=%08h", label_text, expected, read_data);
                failures = failures + 1;
            end else $display("PASS %0s data=%08h", label_text, read_data);
        end
    endtask

    initial begin
        $display("\n=== DATA MEMORY TEST ===");
        address = 0; read_enable = 1;
        check(0, "initialized word zero");

        // Store at byte address 4, then read the same word combinationally.
        @(negedge clk); address = 4; write_data = 32'hdeed_beef; write_enable = 1;
        @(posedge clk); #1; write_enable = 0; read_enable = 1;
        check(32'hdeed_beef, "write/read word one");

        // Writes to unaligned and out-of-range addresses must not corrupt RAM.
        @(negedge clk); address = 6; write_data = 32'h1234_5678; write_enable = 1;
        @(posedge clk); #1; write_enable = 0; address = 4;
        check(32'hdeed_beef, "unaligned write ignored");
        @(negedge clk); address = 16; write_enable = 1; write_data = 32'hffff_ffff;
        @(posedge clk); #1; write_enable = 0; read_enable = 1;
        check(0, "out-of-range read returns zero");

        read_enable = 0;
        check(0, "disabled read returns zero");
        if (dut.memory[1] !== 32'hdeed_beef) begin
            $display("FAIL memory word one changed unexpectedly: %08h", dut.memory[1]);
            failures = failures + 1;
        end

        if (failures == 0)
            $display("DATA MEMORY TEST: PASS");
        else
            $display("DATA MEMORY TEST: FAIL (%0d checks)", failures);
        $finish;
    end
endmodule
