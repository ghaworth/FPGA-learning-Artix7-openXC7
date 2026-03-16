module scroll_display #(
	parameter COUNTER_BITS = 25
	)(
	input wire clk,
	input wire start,
	input wire [63:0] bcd_num,
	input wire [4:0] num_digits,	
	output reg [4:0] left_digit,
	output reg [4:0] right_digit
);

	reg [COUNTER_BITS-1:0] counter = 0; 
	reg [4:0] scroll_pos = 0;
	reg running = 0; 
	reg start_prev = 0;
	wire start_edge = start && !start_prev;

	always @(posedge clk) begin
		start_prev <= start;

		if (start_edge) begin
			running <= 1;
			scroll_pos <= 0;
			counter <= 1;
		end else if (running) begin
			counter <= counter + 1;
			if (counter == 0) begin
				scroll_pos <= scroll_pos + 1;
				if (scroll_pos == num_digits + 2) begin
					running <= 0;
				end	
			end
		end
	end

	always @(*) begin
		// set left_digit and right_digit based on scroll_pos
		if (scroll_pos == 0) begin
			left_digit = 5'd16;
			right_digit = 5'd16;
		end else if (scroll_pos <= num_digits) begin
			// right always valid in this range
			right_digit = bcd_num[(num_digits - scroll_pos) * 4 +: 4];
			// left only valid if scroll >= 2
			if (scroll_pos >= 2)
				left_digit = bcd_num[(num_digits - scroll_pos + 1) * 4 +: 4];
			else
				left_digit = 5'd16;
		end else if (scroll_pos == num_digits + 1) begin
			left_digit = bcd_num[0 +: 4];   // digit 0
			right_digit = 5'd17;			// dot 				
		end else if (scroll_pos == num_digits + 2) begin
			left_digit = 5'd17;			    // dot
			right_digit = 5'd16;			// blank 							
		end else begin
			left_digit = 5'd16;			    // blank 
			right_digit = 5'd16;			// blank 
		end
	end
endmodule