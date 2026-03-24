module VGA_Display 
    (
     input wire clk,
     output wire [9:0] x_coord, 
     output wire [9:0] y_coord,
     output wire visible, 
     output wire h_sync, 
     output wire v_sync
     );

    reg [1:0] pixel_counter = 0;
    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;

    wire pixel_tick = (pixel_counter == 0);

    assign h_sync = (h_count >= 656 && h_count <= 751) ? 1'b0 : 1'b1;
    assign v_sync = (v_count >= 490 && v_count <= 491) ? 1'b0 : 1'b1;
    assign visible = (h_count <= 639 && v_count <= 479) ? 1'b1 : 1'b0; 
    assign x_coord = h_count;
    assign y_coord = v_count;

    always @(posedge clk) begin
        pixel_counter <= pixel_counter + 1;
        if (pixel_tick) begin
            if (h_count == 799) begin
                h_count <= 0;
                if (v_count == 524)
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
            end else begin
                h_count <= h_count + 1;
            end
        end
    end 
endmodule