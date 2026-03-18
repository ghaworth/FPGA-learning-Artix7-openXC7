module Day_07_Core (
	input wire clk,
	input wire start,
	output reg [10:0] result = 0,
	output reg done = 0
);
	// Block RAM for splitter data
	reg [15:0] splitters [0:629];
	initial $readmemh("splitters.hex", splitters);

	localparam DONE = 0;
	localparam LOAD = 1;
	localparam PROCESS = 2;
	localparam COUNT = 3;

	reg [9:0] ram_addr;
	reg [3:0] words_read;
	reg [140:0] active = 141'b0;
	reg [140:0] bitmask;
	reg [140:0] hits;
	reg [7:0] bitshifts = 0;
	reg [10:0] splits;
	reg [2:0] state;
	reg [6:0] row_count;
	reg data_valid = 0;
	reg started = 0;

	// Synchronous read from block RAM
	reg [15:0] splitter_data;
	always @(posedge clk) begin
		splitter_data <= splitters[ram_addr];
	end

	always @(posedge clk) begin
		if (start) begin
			row_count <= 0;
			active <= 1 << 70;
			ram_addr <= 0;
			words_read <= 0;
			bitshifts <= 0;
			splits <= 0;
			done <= 0;
			data_valid <= 0;
			state <= LOAD;
			started <= 1;
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
				hits <= active & bitmask;
				active <= (active & ~bitmask) | ((active & bitmask) << 1) | ((active & bitmask) >> 1);
				state <= COUNT;
			end

			COUNT: begin
				splits <= splits + hits[0];
				hits <= hits >> 1;
				bitshifts <= bitshifts + 1;
				if (bitshifts >= 140) begin
					bitshifts <= 0;
					if (row_count < 69) begin
						// loop back to LOAD next row
						row_count <= row_count + 1;
						state <= LOAD;
						words_read <= 0;
						data_valid <= 0;
					end else begin
						row_count <= 0;
						state <= DONE;
					end 

				end 
			end
			
			DONE: begin
				if (started) begin
					done <= 1;
					result <= splits;
				end
			end
		endcase
			
		end

	end
endmodule