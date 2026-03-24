module Day_07_Top (
  input clk,
  input btnC,
  output RsTx, 
  output [3:0] vgaRed,
  output [3:0] vgaGreen,
  output [3:0] vgaBlue,
  output Hsync,
  output Vsync
);

  localparam IDLE = 0;
  localparam SEND_SYNC1 = 1;
  localparam SEND_SYNC2 = 2;
  localparam SEND_RESULT = 3;
  localparam SEND_TIMER = 4;
  reg [2:0] current_state = 0;
  reg [2:0] prev_state = 0;
  wire enter_send_result = (current_state == SEND_RESULT) && (prev_state != SEND_RESULT);
  wire enter_send_timer = (current_state == SEND_TIMER) && (prev_state != SEND_TIMER);
  wire cc_next = (current_state == SEND_TIMER) ? tx_done_edge : 1'b0;
  wire enter_sync1 = (current_state == SEND_SYNC1) && (prev_state != SEND_SYNC1);
  wire enter_sync2 = (current_state == SEND_SYNC2) && (prev_state != SEND_SYNC2);

  reg [7:0] mux_byte_out;
  reg mux_byte_sent;
  wire result_next = (current_state == SEND_RESULT) ? tx_done_edge : 1'b0;

  // block RAM for VGA framebuffer
  reg [140:0] framebuffer [0:69];

  wire [7:0] fb_col = x_coord[9:2];  // divide by 4
  wire [6:0] fb_row = y_coord[9:2];  // divide by 4
  
  // write port (caputure module)
  always @(posedge clk) begin
    if(capture_write_en) 
      framebuffer[capture_address] <= capture_data;
  end

  // framebuffer read port (for VGA)
  reg [140:0] fb_row_data;
  always @(posedge clk)
      fb_row_data <= framebuffer[fb_row];

  wire fb_pixel = (fb_col < 141) ? fb_row_data[fb_col] : 1'b0;

  assign vgaRed   = 4'b0000;
  assign vgaGreen  = (visible && fb_pixel) ? 4'b1111 : 4'b0000;
  assign vgaBlue   = 4'b0000;

  always @(*) begin
    case (current_state)
      SEND_SYNC1: begin
        mux_byte_out = 8'hAA;
        mux_byte_sent = enter_sync1;
      end
      SEND_SYNC2: begin
        mux_byte_out = 8'h55;
        mux_byte_sent = enter_sync2;
      end
      SEND_RESULT: begin
        mux_byte_out = result_out;
        mux_byte_sent = result_sent;
      end
      SEND_TIMER: begin
        mux_byte_out = timer_out;
        mux_byte_sent = timer_sent;
      end      
      default: begin
        mux_byte_out = 8'h00;
        mux_byte_sent = 1'b0;
      end
    endcase
  end

  always @(posedge clk) begin
    prev_state <= current_state;
    case (current_state)
      IDLE: begin
        if (core_done_edge)
          current_state <= SEND_SYNC1;
      end
      SEND_SYNC1: begin
        if (tx_done_edge)
          current_state <= SEND_SYNC2;
      end
      SEND_SYNC2: begin
        if (tx_done_edge)
          current_state <= SEND_RESULT;
      end
      SEND_RESULT: begin
        if (result_done)
          current_state <= SEND_TIMER;
      end
      SEND_TIMER: begin
        if (timer_done)
          current_state <= IDLE;
      end  
    endcase
  end

  wire [10:0] core_result;
  wire core_done;
  wire [7:0] result_out;
  wire result_sent;
  wire result_done;
  wire [7:0] timer_out;
  wire timer_sent;
  wire timer_done;
  wire [31:0] tmr_result;
  wire tmr_done; 
  wire tx_done;
  reg  tx_done_prev = 0;
  wire tx_done_edge = tx_done && !tx_done_prev;
  always @(posedge clk)
      tx_done_prev <= tx_done;  

  wire btn_debounced;
  reg button_prev = 0;
  wire button_edge = btn_debounced && !button_prev;
  wire start_core = button_edge && (current_state == IDLE);
  reg core_done_prev = 1;
  wire core_done_edge = core_done && !core_done_prev;
  always @(posedge clk) begin
    button_prev <= btn_debounced;
    core_done_prev <= core_done;
  end

  Debounce_Switch #(.c_DEBOUNCE_LIMIT(1000000)) debounce_reset (
    .i_Clk(clk),
    .i_Switch(btnC),
    .o_Switch(btn_debounced)
  );

  wire [2:0] core_state; 
  wire [140:0] core_active;
  
  Day_07_Core core (
    .clk(clk),
    .result(core_result),
    .done(core_done),
    .start(start_core), 
    .state(core_state),
    .active(core_active)
  );

  uart_tx #(.CLKS_PER_BIT(868)) uart_trans (
    .i_Clock(clk),
    .i_Tx_DV(mux_byte_sent),
    .i_Tx_Byte(mux_byte_out),
    .o_Tx_Active(),
    .o_Tx_Serial(RsTx),
    .o_Tx_Done(tx_done)
  );

  Day_07_Timer timer (
    .clk(clk),
    .start(start_core),
    .stop(core_done),
    .result(tmr_result),
    .done(tmr_done)
  );

  Value_To_Bytes #(.VALUE_WIDTH(16)) result_ser (
    .clk(clk),
    .send_data_now(enter_send_result),
    .next_byte_please(result_next),
    .data_in(core_result),
    .byte_out(result_out),
    .byte_sent(result_sent),
    .all_bytes_sent(result_done)
  );

  Value_To_Bytes #(.VALUE_WIDTH(32)) cycle_count (
    .clk(clk),
    .send_data_now(enter_send_timer),
    .next_byte_please(cc_next),
    .data_in(tmr_result),
    .byte_out(timer_out),
    .byte_sent(timer_sent),
    .all_bytes_sent(timer_done)
  );

  wire capture_write_en;
  wire [6:0] capture_address;
  wire [140:0] capture_data; 

  Day_07_Capture capture (
    .clk(clk),
    .state(core_state),
    .active(core_active), 
    .address(capture_address),    
    .data(capture_data),
    .write_en(capture_write_en)
    );

endmodule