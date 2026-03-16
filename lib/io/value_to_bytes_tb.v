`timescale 1ns/1ps

module value_to_bytes_tb;
    reg clk;
    reg start;
    reg next;
    reg [31:0] data;
    wire [7:0] bytes;
    wire one_byte_sent;
    wire done;
    integer failures = 0;

    Value_To_Bytes #(.VALUE_WIDTH(32)) uut (
        .clk(clk),
        .send_data_now(start),
        .next_byte_please(next),
        .data_in(data),
        .byte_out(bytes),
        .byte_sent(one_byte_sent),
        .all_bytes_sent(done)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        start = 0;
        next = 0;
        data = 32'h01234567;

        #20;
        start = 1;
        #10;
        start = 0;
        wait(one_byte_sent); 
        if (bytes == 8'h67)
            $display("PASS: byte 0 = %h", bytes);
        else begin
            $display("FAIL: byte 0 expected 67, got %h", bytes);
            failures = failures + 1;            
        end

        #20;
        next = 1;
        #10;
        next = 0;
        wait(one_byte_sent); 
        if (bytes == 8'h45)
            $display("PASS: byte 1 = %h", bytes);
        else begin
            $display("FAIL: byte 1 expected 45, got %h", bytes);
            failures = failures + 1;            
        end

        #20;
        next = 1;
        #10;
        next = 0;
        wait(one_byte_sent); 
        if (bytes == 8'h23)
            $display("PASS: byte 2 = %h", bytes);
        else begin
            $display("FAIL: byte 2 expected 23, got %h", bytes);
            failures = failures + 1;
        end

        #20;
        next = 1;
        #10;
        next = 0;
        wait(one_byte_sent); 
        if (bytes == 8'h01)
            $display("PASS: byte 3 = %h", bytes);
        else begin
            $display("FAIL: byte 3 expected 01, got %h", bytes);
            failures = failures + 1;            
        end

        #20;
        next = 1;
        #10;
        next = 0;
        wait(done);
            $display("PASS: done pulse received");

        if (failures == 0) 
        $display("PASS: all bytes correct");
        else begin
            $display("FAIL: %0d bytes wrong", failures);
        end
        $finish;
    end

    initial begin
      #10000;
      $display("TIMEOUT");
      $finish;
    end
endmodule