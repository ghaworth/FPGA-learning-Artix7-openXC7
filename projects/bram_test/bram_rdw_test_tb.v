`timescale 1ns/1ps

module bram_rdw_test_tb;
    reg clk = 0;
    reg start = 0;
    wire [31:0] result;
    wire done;

    always #5 clk = ~clk;

    bram_rdw_test uut (
        .clk(clk),
        .start(start),
        .result(result),
        .done(done)
    );

    initial begin
        $dumpfile("bram_rdw_test.vcd");
        $dumpvars(0, bram_rdw_test_tb);

        #20;
        start = 1;
        #10;
        start = 0;

        wait(done);
        #10;
        $display("Result: %0d", result);
        if (result == 65280)
            $display("PASS: result matches expected value");
        else
            $display("FAIL: expected 65280, got %0d", result);

        $finish;
    end

    // Timeout
    initial begin
        #1000000;
        $display("TIMEOUT");
        $finish;
    end
endmodule