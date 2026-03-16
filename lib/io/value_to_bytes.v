module Value_To_Bytes 
    #(parameter VALUE_WIDTH = 32)
    (
     input clk,
     input send_data_now,
     input next_byte_please,
     input [VALUE_WIDTH-1:0] data_in,
     output reg [7:0] byte_out = 0,
     output reg byte_sent = 0,
     output reg all_bytes_sent = 0
     );

    localparam NUM_BYTES = (VALUE_WIDTH + 7) / 8;
    reg [VALUE_WIDTH-1:0] shift_reg = 0;
    reg [NUM_BYTES+1:0] byte_index = 1;  

    always @(posedge clk) begin
        byte_sent <= 0;
        if (send_data_now) begin
            byte_index <= 1;
            all_bytes_sent <= 0;
            shift_reg <= data_in >> 8;
            byte_out <= data_in[7:0];
            byte_sent <= 1;

        end else if (next_byte_please) begin
            if (byte_index < NUM_BYTES) begin
                shift_reg <= shift_reg >> 8;
                byte_out <= shift_reg[7:0];
                byte_index <= byte_index + 1;
                byte_sent <= 1;
            end else begin
                all_bytes_sent <= 1;
                byte_index <= 1; //reset for next time                
            end
        end
    end
endmodule