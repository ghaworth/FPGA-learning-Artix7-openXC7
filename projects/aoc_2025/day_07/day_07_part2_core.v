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

	reg [7:0] count_addr_a;
	reg [7:0] count_addr_b;
	reg [69:0] count_rdata_a;
	reg [69:0] count_rdata_b;

	always @(posedge clk) begin
	    count_rdata_a <= count[count_addr_a];
	end

	always @(posedge clk) begin
	    count_rdata_b <= count[count_addr_b];
	end

	localparam DONE = 0;
	localparam INIT = 1;
	localparam LOAD = 2;
	localparam FETCH = 3;
	localparam COMPUTE = 4;
	localparam SUM = 5;
	localparam WAIT = 6;

	(* ram_style = "distributed" *)
	reg [69:0] count [0:140];
	reg [9:0] ram_addr;
	reg [3:0] words_read;
	reg [140:0] bitmask;
	reg [6:0] row_count;
	reg data_valid = 0;
	reg started = 0;
	reg [69:0] accumulator;
	reg [7:0] sum_index;
	reg [7:0] pos = 0;
	reg [69:0] prev;
	reg [69:0] left;
	reg [69:0] self;
	reg [69:0] right;
	reg [1:0] phase = 0;

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
		state <= INIT;
		started <= 1;
		sum_index <= 0;
		pos <= 0;
		phase <= 0;
		count_addr_a <= 0;
		count_addr_b <= 0;

	end else begin
		case(state)
		INIT: begin
			count[pos] <= (pos == 70) ? 70'd1 : 70'd0;
			pos <= pos + 1;
			if (pos == 140) begin
				pos <= 0;
				state <= LOAD;
			end
		end	

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
					state <= FETCH;
				end
			end
		end 

		FETCH: begin  // set BRAM addresses 
			count_addr_a <= pos;
			count_addr_b <= pos+1;
			state <= WAIT;
		end 

		WAIT: begin 
			state <= COMPUTE;
		end 

		COMPUTE: begin
			left = (pos > 0 && bitmask[pos-1]) ? prev : 70'd0;
			self = bitmask[pos] ? 70'd0 : count_rdata_a;
			right = (pos < 140 && bitmask[pos+1]) ? count_rdata_b : 70'd0;
			
			if (pos <= 140) begin
			prev <= count_rdata_a;
			count[pos] <= self + left + right;
			pos <= pos + 1;
				if (pos == 0 && bitmask[0]) 
					accumulator <= accumulator + count_rdata_a;
				if (pos == 140 && bitmask[140])
					accumulator <= accumulator + count_rdata_a;
			state <= FETCH;
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
			if (phase == 0) begin
				count_addr_a <= sum_index;
				phase <= 1;
			end	else if (phase == 1) begin
				phase <= 2;
			end else begin
				accumulator <= accumulator + count_rdata_a;		
				sum_index <= sum_index + 1;
				phase <= 0;
				if (sum_index == 140)
					state <= DONE;					
			end 
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
