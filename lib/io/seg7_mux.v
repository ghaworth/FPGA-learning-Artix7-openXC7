module seg7_mux (
  input wire clk,
  input wire [4:0] digit0,
  input wire [4:0] digit1,  
  input wire [4:0] digit2,
  input wire [4:0] digit3,  
  output reg [6:0] seg,
  output wire dp,
  output reg [3:0] an 
);
  localparam DIG0 = 2'b00;
  localparam DIG1 = 2'b01;
  localparam DIG2 = 2'b10;
  localparam DIG3 = 2'b11;  

  reg [17:0] counter = 0; 
  reg [4:0] current_digit;
    
  always @(posedge clk) begin
    counter <= counter + 1;
  end 

  always @(*) begin
    case (counter[17:16])
      DIG0: begin
        an = 4'b1110;
        current_digit = digit0;
      end
      DIG1: begin
        an = 4'b1101;
        current_digit = digit1;
      end
      DIG2: begin
        an = 4'b1011;
        current_digit = digit2;
      end
      DIG3: begin
        an = 4'b0111;
        current_digit = digit3;
      end
      default: begin
        an = 4'b1111;
        current_digit = digit0;
      end
    endcase

    case (current_digit)
      4'b0000: seg = ~7'b0111111;  // 0: a,b,c,d,e,f
      4'b0001: seg = ~7'b0000110;  // 1: b,c
      4'b0010: seg = ~7'b1011011;  // 2: a,b,d,e,g
      4'b0011: seg = ~7'b1001111;  // 3: a,b,c,d,g
      4'b0100: seg = ~7'b1100110;  // 4: b,c,f,g
      4'b0101: seg = ~7'b1101101;  // 5: a,c,d,f,g
      4'b0110: seg = ~7'b1111101;  // 6: a,c,d,e,f,g
      4'b0111: seg = ~7'b0000111;  // 7: a,b,c
      4'b1000: seg = ~7'b1111111;  // 8: a,b,c,d,e,f,g
      4'b1001: seg = ~7'b1101111;  // 9: a,b,c,d,f,g
      4'b1010: seg = ~7'b1110111;  // A: a,b,c,e,f,g
      4'b1011: seg = ~7'b1111100;  // B: c,d,e,f,g
      4'b1100: seg = ~7'b0111001;  // C: a,d,e,f
      4'b1101: seg = ~7'b1011110;  // D: b,c,d,e,g
      4'b1110: seg = ~7'b1111001;  // E: a,d,e,f,g
      4'b1111: seg = ~7'b1110001;  // F: a,e,f,g
      5'b10000: seg = ~7'b0000000; // blank: all off
      5'b10001: seg = ~7'b0001000; // dot: segment d only
      default: seg = ~7'b0000000;  // All off
    endcase
  end
  assign dp = 1'b1;
endmodule