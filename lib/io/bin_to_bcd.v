module bin_to_bcd (
	input wire clk,
	input wire start,
	input wire [49:0] bin_num,
	output reg [63:0] bcd_num,
	output reg done
);

	reg [113:0] register;
	reg [5:0] shift_count;
	reg [1:0] module_state;
	wire [113:0] corrected;

	assign corrected[49:0] = register[49:0];

	genvar i;
	generate
		for (i = 0; i < 16; i = i + 1) begin : bcd_correct
			assign corrected[50 + i*4 +: 4] = (register[50 + i*4 +: 4] >= 5)
				? register[50 + i*4 +: 4] + 3 : register[50 + i*4 +: 4];
		end
	endgenerate


	localparam IDLE       = 2'd0;
	localparam CONVERTING = 2'd1;
	localparam DONE       = 2'd2;

	initial begin
		module_state = IDLE;
		done = 0;
	end
	
	always @(posedge clk) begin 
		case (module_state)
			IDLE: begin
				// wait for start
				if (start) begin
					register[0 +: 50] <= bin_num;
					register[50 +: 64] <= 0;
					shift_count <= 0;
					module_state <= CONVERTING;
					done <= 0;
				end
			end

			CONVERTING: begin
				// do the work	
				register <= corrected << 1;
				shift_count <= shift_count + 1;
				if (shift_count == 49) begin
					module_state <= DONE;
				end
			end

			DONE: begin
				// output result
				bcd_num <= register[50 +: 64];
				done <= 1;
				module_state <= IDLE;
			end
		endcase
	end
endmodule