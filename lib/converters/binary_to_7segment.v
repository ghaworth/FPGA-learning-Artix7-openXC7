///////////////////////////////////////////////////////////////////////////////
// Module: Binary_To_7Segment
// Purpose: Converts a 4-bit binary number (0-15) to 7-segment display format
// Supports decimal digits (0-9) and hex digits (A-F)
//
// 7-segment layout:
//    aaa
//   f   b
//   f   b
//    ggg
//   e   c
//   e   c
//    ddd
//
// Output format: {g, f, e, d, c, b, a}
///////////////////////////////////////////////////////////////////////////////

module Binary_To_7Segment (
  input i_Clk,
  input [4:0] i_Binary_Num,
  output o_Segment_A,
  output o_Segment_B,
  output o_Segment_C,
  output o_Segment_D,
  output o_Segment_E,
  output o_Segment_F,
  output o_Segment_G
);

  reg [6:0] r_Segments;

  always @(posedge i_Clk)
  begin
    case (i_Binary_Num)
      4'b0000: r_Segments <= 7'b0111111;  // 0: a,b,c,d,e,f
      4'b0001: r_Segments <= 7'b0000110;  // 1: b,c
      4'b0010: r_Segments <= 7'b1011011;  // 2: a,b,d,e,g
      4'b0011: r_Segments <= 7'b1001111;  // 3: a,b,c,d,g
      4'b0100: r_Segments <= 7'b1100110;  // 4: b,c,f,g
      4'b0101: r_Segments <= 7'b1101101;  // 5: a,c,d,f,g
      4'b0110: r_Segments <= 7'b1111101;  // 6: a,c,d,e,f,g
      4'b0111: r_Segments <= 7'b0000111;  // 7: a,b,c
      4'b1000: r_Segments <= 7'b1111111;  // 8: a,b,c,d,e,f,g
      4'b1001: r_Segments <= 7'b1101111;  // 9: a,b,c,d,f,g
      4'b1010: r_Segments <= 7'b1110111;  // A: a,b,c,e,f,g
      4'b1011: r_Segments <= 7'b1111100;  // B: c,d,e,f,g
      4'b1100: r_Segments <= 7'b0111001;  // C: a,d,e,f
      4'b1101: r_Segments <= 7'b1011110;  // D: b,c,d,e,g
      4'b1110: r_Segments <= 7'b1111001;  // E: a,d,e,f,g
      4'b1111: r_Segments <= 7'b1110001;  // F: a,e,f,g
      5'b10000: r_Segments <= 7'b0000000; // blank: all off
      5'b10001: r_Segments <= 7'b0001000; // dot: segment d only
      default: r_Segments <= 7'b0000000;  // All off
    endcase
  end

  // Output format: {g, f, e, d, c, b, a} from MSB to LSB
  assign o_Segment_A = ~r_Segments[0];
  assign o_Segment_B = ~r_Segments[1];
  assign o_Segment_C = ~r_Segments[2];
  assign o_Segment_D = ~r_Segments[3];
  assign o_Segment_E = ~r_Segments[4];
  assign o_Segment_F = ~r_Segments[5];
  assign o_Segment_G = ~r_Segments[6];

endmodule
