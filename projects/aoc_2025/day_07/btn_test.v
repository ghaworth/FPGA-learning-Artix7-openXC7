module btn_test (
    input clk,
    input btnC,
    output led
);
    assign led = btnC;
endmodule