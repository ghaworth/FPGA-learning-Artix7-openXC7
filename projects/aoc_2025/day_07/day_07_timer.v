module Day_07_Timer (
    input wire clk,
    input wire start,
    input wire stop,
    output reg [31:0] result = 0,
    output reg done = 0
);
    reg [31:0] clock_count = 0;
    reg running = 0;
    
    always @(posedge clk) begin
        if (start) begin
            clock_count <= 0;
            done <= 0;
            running <= 1;
        end else if (stop) begin 
            result <= clock_count;     
            done <= 1;
            running <= 0;
        end else if (running) begin
            clock_count <= clock_count + 1;
        end
    end             
endmodule
