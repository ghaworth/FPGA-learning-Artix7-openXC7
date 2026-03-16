`timescale 1ns/1ps
module day_07_core_tb;
	reg clk;
	reg start;
	wire [10:0] result;
	wire done;

	Day_07_Core uut (
		.clk(clk),
		.start(start),
		.result(result),
		.done(done)
	);

	always #5 clk = ~clk;

	initial begin
		clk = 0;
		start = 1;
		#10;
		start = 0;
		wait(done);
		if (result == 1672) begin
			$display("PASS: result = %d", result);
		end else begin
			$display("FAIL: expected 1672, got %d", result);
		end
		$finish;
	end

	initial begin
		#5000000;
		$display("TIMEOUT: done never asserted");
		$finish;
	end
endmodule