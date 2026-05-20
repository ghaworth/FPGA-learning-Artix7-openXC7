module Day_06_Core (
    input wire clk,
    input wire rst,
    input wire [7:0] byte_in,
    input wire byte_valid,
    output reg [63:0] grand_total,
    output reg done
);
    // ...
endmodule