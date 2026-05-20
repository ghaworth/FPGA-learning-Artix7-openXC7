// AoC 2025 Day 6: Trash Compactor (cephalopod maths)
//
// Streams a byte-at-a-time worksheet of column-organised arithmetic problems
// and computes the grand total of all problem answers.
//
// Input shape:
//   - 5 rows of ASCII, each 3768 chars wide, separated by newlines
//   - Rows 1-4: digit fields representing operands, separated by spaces
//   - Row 5:    operator field, '+' or '*' aligned under each problem column
//
// Approach: single-pass ingestion with concurrent ASCII-to-integer
// accumulation and problem-boundary detection.

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

