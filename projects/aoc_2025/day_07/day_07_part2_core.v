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

	// Synchronous read from block RAM
	reg [15:0] splitter_data;
	always @(posedge clk) begin
		splitter_data <= splitters[ram_addr];
	end

endmodule