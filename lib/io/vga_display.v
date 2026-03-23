module VGA_Display 
    (
     input wire clk,
     output reg [9:0] x_coord, 
     output reg [9:0] y_coord,
     output reg visible, 
     output wire h_sync, 
     output wire v_sync
     );

    reg [1:0] pixel_counter = 0;
    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;

    wire pixel_tick = (pixel_counter == 0);

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
