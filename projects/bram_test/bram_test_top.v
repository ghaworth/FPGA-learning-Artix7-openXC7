module bram_test_top (
    input wire clk,
    input wire btnL,
    output wire [6:0] seg,
    output wire dp,
    output wire [3:0] an,
    output wire [0:0] led
);

    wire btnL_debounced;
    reg btnL_prev = 0;
    wire btnL_edge = btnL_debounced && !btnL_prev;

    always @(posedge clk)
        btnL_prev <= btnL_debounced;

    Debounce_Switch #(.c_DEBOUNCE_LIMIT(1000000)) debounce (
        .i_Clk(clk),
        .i_Switch(btnL),
        .o_Switch(btnL_debounced)
    );

    wire [31:0] result;
    wire done;

wire [69:0] result;
    wire done;

    Day_07_Part2_Core uut (
        .clk(clk),
        .start(btnL_edge),
        .result(result),
        .done(done),
        .state()
    );

    assign led[0] = done;

    // Show result[15:0] in hex
    // Wrong answer (8995) = 0x2323
    seg7_mux display (
        .clk(clk),
        .digit0(result[3:0]),
        .digit1(result[7:4]),
        .digit2(result[11:8]),
        .digit3(result[15:12]),
        .seg(seg),
        .dp(dp),
        .an(an)
    );
    
    assign led[0] = done;

    // Show result[15:0] in hex on 4 digits
    // Expected: FF00 (65280 decimal)
    seg7_mux display (
        .clk(clk),
        .digit0(result[3:0]),
        .digit1(result[7:4]),
        .digit2(result[11:8]),
        .digit3(result[15:12]),
        .seg(seg),
        .dp(dp),
        .an(an)
    );

endmodule
