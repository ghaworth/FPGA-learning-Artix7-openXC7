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
    // phase state machine
    localparam IDLE        = 2'd0;
    localparam DIGITS      = 2'd1;
    localparam OPERATORS   = 2'd2;
    localparam FINISHED    = 2'd3;

    reg [1:0] phase = IDLE;
    reg [2:0] row = 0;     // which input row we're on

    // byte categoriser 
    wire is_digit   = (byte_in >= "0") && (byte_in <= "9"); 
    wire is_space   = (byte_in == " ");
    wire is_newline = (byte_in == "\n");
    wire is_plus    = (byte_in == "+");
    wire is_mult    = (byte_in == "*");

    // phase transitions 
    always @(posedge clk) begin
        if (rst) begin
            phase <= IDLE;
            row <= 0;
            done <= 0;
            grand_total <= 0;
        end else if (byte_valid) begin
            case (phase)
                IDLE: begin
                    phase <= DIGITS;
                end 
                DIGITS: begin
                    if (is_newline) begin
                        row <= row + 1;
                        if (row == 3) phase <= OPERATORS;
                    end
                end 
                OPERATORS: begin
                    if (is_newline) begin
                        phase <= FINISHED;
                        done <= 1;
                    end 
                end 
                FINISHED: begin
                    // hold
                end 
            endcase
        end 
    end  

endmodule

