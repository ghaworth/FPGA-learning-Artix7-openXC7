`timescale 1ns/1ps

module scroll_display_tb;
    reg clk;
    reg start;
    reg [63:0] bcd_num;
    reg [4:0] num_digits;
    wire [4:0] left_digit;
    wire [4:0] right_digit;

    scroll_display #(.COUNTER_BITS(4)) uut (
        .clk(clk),
        .start(start),
        .bcd_num(bcd_num),
        .num_digits(num_digits),
        .left_digit(left_digit),
        .right_digit(right_digit)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        start = 0;
        bcd_num = 64'h1158;  // 1158 in BCD
        num_digits = 4;
        
        #20;
        start = 1;
        #10;
        start = 0;
        
        // Watch scroll positions
        repeat(8) begin
            // Wait for counter to wrap (16 cycles with 4-bit counter)
            #160;
            $display("left=%d right=%d", left_digit, right_digit);
        end
        
        $finish;
    end
endmodule