`timescale 1ns/1ps
module day_07_part2_core_tb;
    reg clk = 0;
    reg start = 0;
    wire [69:0] result;
    wire [2:0] state;
    wire done;

    always #5 clk = ~clk;

    Day_07_Part2_Core uut (
        .clk(clk),
        .start(start),
        .result(result),
        .state(state),
        .done(done)
    );

initial begin
    $dumpfile("day_07_part2.vcd");
    $dumpvars(0, day_07_part2_core_tb);
    #20;
    start = 1;
    #10;
    start = 0;
    wait(done);
    #10;
    $display("Run 1 Result: %d", result);
    
    #100;
    start = 1;
    #10;
    start = 0;
    wait(done);
    #10;
    $display("Run 2 Result: %d", result);
    $finish;
end
endmodule