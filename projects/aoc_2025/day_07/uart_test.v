module uart_test (
    input clk,
    output RsTx,
    output led
);
    wire tx_serial;
    wire tx_done;
    wire tx_active;
    
    uart_tx #(.CLKS_PER_BIT(868)) uart_trans (
        .i_Clock(clk),
        .i_Tx_DV(tx_done || !tx_active),
        .i_Tx_Byte(8'h42),
        .o_Tx_Active(tx_active),
        .o_Tx_Serial(tx_serial),
        .o_Tx_Done(tx_done)
    );
    
    assign RsTx = tx_serial;
    assign led = tx_active;
endmodule