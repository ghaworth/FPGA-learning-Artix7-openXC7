module Day_07_Top (
  input clk,
  input btnC,
  output RsTx
);
  // state machine definitions
  localparam IDLE = 0;
  localparam SEND_SYNC1 = 1;
  localparam SEND_SYNC2 = 2;
  localparam SEND_RESULT = 3;
  localparam SEND_TIMER = 4;
  reg [2:0] current_state = 0;
  wire sending_result = (current_state == SEND_RESULT);
  reg [2:0] prev_state = 0;
  wire enter_send_result = (current_state == SEND_RESULT) && (prev_state != SEND_RESULT);
  wire enter_send_timer = (current_state == SEND_TIMER) && (prev_state != SEND_TIMER);
  wire enter_sync1 = (current_state == SEND_SYNC1) && (prev_state != SEND_SYNC1);
  wire enter_sync2 = (current_state == SEND_SYNC2) && (prev_state != SEND_SYNC2);
  // muxed signals
  reg [7:0] mux_byte_out;
  reg mux_byte_sent;
  wire result_next = (current_state == SEND_RESULT) ? tx_done : 1'b0;
  wire cc_next = (current_state == SEND_TIMER) ? tx_done : 1'b0;
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
      default: begin
        mux_byte_out = cc_byte_out;
        mux_byte_sent = cc_sent;
      end
    endcase 
  end
  always @(posedge clk) begin
    prev_state <= current_state;
    case (current_state) 
      IDLE: begin 
        if (core_done_edge) begin
          current_state <= SEND_SYNC1;
        end
      end
      SEND_SYNC1: begin 
        if (tx_done) begin
          current_state <= SEND_SYNC2;
        end
      end        
      SEND_SYNC2: begin
        if (tx_done) begin
          current_state <= SEND_RESULT;
        end
      end
      SEND_RESULT: begin 
        if (result_done) begin
          current_state <= SEND_TIMER;
        end
      end
      SEND_TIMER: begin 
        if (cc_done) begin
          current_state <= IDLE;
        end
      end
    endcase
  end
  // core outputs
  wire [10:0] core_result;
  wire core_done;
  // timer outputs
  wire [31:0] tmr_result;
  wire tmr_done;
  // cycle count outputs
  wire [7:0] cc_byte_out;
  wire cc_sent;
  wire cc_done;
  // result outputs
  wire [7:0] result_out;
  wire result_sent;
  wire result_done;
  // uart transmitter outputs
  wire tx_active;
  wire tx_done;
  // debounced switch
  wire btn_debounced;
  reg button_prev = 0;
  wire button_edge;
  assign button_edge = btn_debounced && !button_prev;
  wire start_core = button_edge && (current_state == IDLE);
  reg core_done_prev = 1;
  wire core_done_edge;
  assign core_done_edge = core_done && !core_done_prev;
  always @(posedge clk) begin
    button_prev <= btn_debounced;
    core_done_prev <= core_done;
  end  
  Debounce_Switch #(.c_DEBOUNCE_LIMIT(1000000)) debounce_reset (
    .i_Clk(clk),
    .i_Switch(btnC),
    .o_Switch(btn_debounced)
  );
  Day_07_Core core (
    .clk(clk),
    .result(core_result),
    .done(core_done),
    .start(start_core)
  ); 
  uart_tx #(.CLKS_PER_BIT(868)) uart_trans (
    .i_Clock    (clk),
    .i_Tx_DV    (mux_byte_sent),
    .i_Tx_Byte  (mux_byte_out),
    .o_Tx_Active(tx_active),
    .o_Tx_Serial(RsTx),
    .o_Tx_Done  (tx_done)
  );
  Day_07_Timer tmr (
    .clk   (clk),
    .start (start_core),
    .stop  (core_done),
    .result(tmr_result),
    .done  (tmr_done)
  );
  Value_To_Bytes #(.VALUE_WIDTH(32)) cycle_count (
    .clk             (clk),
    .send_data_now   (enter_send_timer),
    .next_byte_please(cc_next),
    .data_in         (tmr_result),
    .byte_out        (cc_byte_out),
    .byte_sent       (cc_sent),
    .all_bytes_sent  (cc_done)
  );
  Value_To_Bytes #(.VALUE_WIDTH(16)) result (
    .clk             (clk),
    .send_data_now   (enter_send_result),
    .next_byte_please(result_next),
    .data_in         (core_result),
    .byte_out        (result_out),
    .byte_sent       (result_sent),
    .all_bytes_sent  (result_done)
  );
endmodule