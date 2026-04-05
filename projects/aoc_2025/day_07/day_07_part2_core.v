module Day_07_Part2_Core (
	input wire clk,
	input wire start,
	output reg [69:0] result = 0,
	output reg [2:0] state,
	output reg done = 0
);
	// Block RAM for splitter data
	reg [15:0] splitters [0:629];
	initial $readmemh("splitters.hex", splitters);

	localparam DONE = 0;
	localparam LOAD = 1;
	localparam PROCESS = 2;
	localparam SUM = 3;

	reg [69:0] count [0:140];
	reg [9:0] ram_addr;
	reg [3:0] words_read;
	reg [140:0] bitmask;
	reg [6:0] row_count;
	reg data_valid = 0;
	reg started = 0;
	reg [69:0] accumulator;
	integer j;
	integer k;
	reg [7:0] sum_index;
	reg [7:0] pos = 0;
	reg [69:0] prev;
	reg [69:0] left;
	reg [69:0] self;
	reg [69:0] right;

	// Synchronous read from block RAM
	reg [15:0] splitter_data;
	always @(posedge clk) begin
		splitter_data <= splitters[ram_addr];
	end

	always @(posedge clk) begin
	if (start) begin
		row_count <= 0;
		ram_addr <= 0;
		words_read <= 0;
		accumulator <= 0;
		done <= 0;
		data_valid <= 0;
		state <= LOAD;
		started <= 1;
		sum_index <= 0;
		for (j = 0; j <= 140; j = j + 1)
			count[j] <= 0;
		count [70] <= 1;

	end else begin
		case(state)
		LOAD: begin
			if (!data_valid) begin
				// wait one cycle for RAM read
				data_valid <= 1;
			end else begin
				bitmask[words_read*16 +: 16] <= splitter_data;
				words_read <= words_read + 1;
				ram_addr <= ram_addr + 1;
				data_valid <= 0;
				pos <= 0;
				if (words_read >= 8) begin
					state <= PROCESS;
				end
			end
		end 

		PROCESS: begin
			left = (pos > 0 && bitmask[pos-1]) ? prev : 70'd0;
			self = bitmask[pos] ? 70'd0 : count[pos];
			right = (pos < 140 && bitmask[pos+1]) ? count[pos+1] : 70'd0;

			if (pos <= 140) begin
			prev <= count[pos];
			count[pos] <= self + left + right;
			pos <= pos + 1;
				if (pos == 0 && bitmask[0]) 
					accumulator <= accumulator + count[0];
				if (pos == 140 && bitmask[140])
					accumulator <= accumulator + count[140];
 			end else begin
	 			if (row_count < 69) begin
	 				// loop back to load next row
	 				row_count <= row_count + 1;
					state <= LOAD;
					words_read <= 0;
		 			data_valid <= 0;
		 			end else begin
		 				row_count <= 0;
		 				state <= SUM;
		 				pos <= 0;
		 			end  
				end 
 			end 


		SUM: begin 
			accumulator <= accumulator + count[sum_index];
			sum_index <= sum_index + 1;
			if (sum_index == 140)
				state <= DONE;					
			end 

		DONE: begin
			if (started) begin 
				done <= 1;
				result <= accumulator;
			end 
		end 
		endcase
	end 
	end
endmodule