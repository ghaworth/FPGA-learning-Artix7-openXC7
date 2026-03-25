module Day_07_Capture (
	input wire clk,
	input wire start, 
	input wire [2:0] state,
    input wire [140:0] active,
	output reg [6:0] address,
	output reg [140:0] data,
	output reg write_en = 0
);

	reg [2:0] prev_state;
	wire row_done = (state == 1) && (prev_state != 1);
	reg [6:0] row_count = 0;

	always @(posedge clk) begin
    prev_state <= state;
    write_en <= 0;
    if (start) begin
    	row_count <= 0;
    end else if (row_done) begin
		data <= active;
		address <= row_count;
		row_count <= row_count + 1;
		write_en <= 1;
	end 
end

endmodule