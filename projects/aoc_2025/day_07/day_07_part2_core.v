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
				if (words_read >= 8) begin
					state <= PROCESS;
				end
			end
		end 

		PROCESS: begin
			count[0] <= (bitmask[0] ? 0:count[0]) + (bitmask[1] ? count[1]:0);
 			for (k = 1; k <= 139; k = k + 1)
 				count[k] <= (bitmask[k] ? 0:count[k]) + (bitmask[k-1] ? count[k-1]:0) + (bitmask[k+1] ? count[k+1]:0);
 			count[140] <= (bitmask[140] ? 0:count[140]) + (bitmask[139] ? count[139]:0);
 			accumulator <= accumulator + (bitmask[0] ? count[0]:0) + (bitmask[140] ? count[140]:0);
			end
		endcase
	end 

endmodule