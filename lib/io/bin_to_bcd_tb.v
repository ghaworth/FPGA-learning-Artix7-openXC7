`timescale 1ns/1ps

module bin_to_bcd_tb;
    reg clk;
    reg start;
    reg [49:0] bin_num;
    wire [63:0] bcd_num;
    wire done;

    bin_to_bcd uut (
        .clk(clk),
        .start(start),
        .bin_num(bin_num),
        .bcd_num(bcd_num),
        .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        start = 0;
        bin_num = 50'd1158;  // your AoC answer
        #20;
        start = 1;
        #10;
        start = 0;
        wait(done);
        $display("Input:  %d", 1158);
        $display("Output: %h", bcd_num);
        $display("Expected: 0x1158");
        if (bcd_num == 64'h1158)
            $display("PASS");
        else
            $display("FAIL");
        $finish;
    end
endmodule