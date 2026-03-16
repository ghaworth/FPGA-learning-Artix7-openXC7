module blinky (
    input  wire clk,
    output wire led
);

    reg [25:0] counter = 0;

    always @(posedge clk)
        counter <= counter + 1;

    assign led = counter[25];

endmodule
