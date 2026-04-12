// Minimal test case for Yosys BRAM inference bug
//
// Structure matches the failing design exactly:
// - Two read ports in separate always @(posedge clk) blocks
// - One write port in a state machine always @(posedge clk) block
// - FETCH -> WAIT -> COMPUTE pipeline
// - Both read values used in computation (forces Yosys to serve both ports)
//
// Computation:
//   1. Initialise: mem[i] = i for i = 0..255
//   2. Main pass:  for pos = 0..254, mem[pos] <= mem[pos] + mem[pos+1]
//   3. Sum:        accumulate all 256 entries
//
// After main pass:
//   mem[i] = 2i + 1  for i = 0..254
//   mem[255] = 255    (unchanged)
//
// Expected sum = sum(2i+1, i=0..254) + 255 = 65025 + 255 = 65280
//
// To test: synthesise with and without (* ram_style = "distributed" *)
// If both give 65280, BRAM inference is correct.
// If distributed gives 65280 but BRAM gives something else, bug confirmed.

module bram_rdw_test (
    input wire clk,
    input wire start,
    output reg [31:0] result = 0,
    output reg done = 0
);

    // ----- Memory: 256 entries x 16 bits -----
    // Uncomment the next line to force distributed RAM (workaround):
    // (* ram_style = "distributed" *)
    reg [15:0] mem [0:255];

    // ----- Two read ports in separate always blocks (matches original) -----
    reg [7:0] rd_addr_a;
    reg [7:0] rd_addr_b;
    reg [15:0] rd_data_a;
    reg [15:0] rd_data_b;

    always @(posedge clk) begin
        rd_data_a <= mem[rd_addr_a];
    end

    always @(posedge clk) begin
        rd_data_b <= mem[rd_addr_b];
    end

    // ----- State machine with write port (matches original) -----
    localparam IDLE    = 3'd0;
    localparam INIT    = 3'd1;
    localparam FETCH   = 3'd2;
    localparam WAIT_ST = 3'd3;
    localparam COMPUTE = 3'd4;
    localparam SUM_F   = 3'd5;
    localparam SUM_W   = 3'd6;
    localparam SUM_R   = 3'd7;

    reg [2:0] state = IDLE;
    reg [8:0] pos;  // 9 bits to hold values up to 255 and detect overflow
    reg [15:0] prev;
    reg [31:0] accumulator;

    always @(posedge clk) begin
        if (start) begin
            pos <= 0;
            done <= 0;
            accumulator <= 0;
            prev <= 0;
            rd_addr_a <= 0;
            rd_addr_b <= 0;
            state <= INIT;
        end else begin
            case (state)
                // Initialise memory: mem[i] = i
                INIT: begin
                    mem[pos[7:0]] <= {8'd0, pos[7:0]};
                    if (pos == 255) begin
                        pos <= 0;
                        state <= FETCH;
                    end else begin
                        pos <= pos + 1;
                    end
                end

                // Set up read addresses (matches original FETCH)
                FETCH: begin
                    rd_addr_a <= pos[7:0];
                    rd_addr_b <= pos[7:0] + 1;
                    state <= WAIT_ST;
                end

                // One cycle latency for BRAM read (matches original WAIT)
                WAIT_ST: begin
                    state <= COMPUTE;
                end

                // Use both read values and write back (matches original COMPUTE)
                COMPUTE: begin
                    prev <= rd_data_a;
                    mem[pos[7:0]] <= rd_data_a + rd_data_b;
                    if (pos == 254) begin
                        pos <= 0;
                        state <= SUM_F;
                    end else begin
                        pos <= pos + 1;
                        state <= FETCH;
                    end
                end

                // Sum phase: read each entry and accumulate
                SUM_F: begin
                    rd_addr_a <= pos[7:0];
                    state <= SUM_W;
                end

                SUM_W: begin
                    state <= SUM_R;
                end

                SUM_R: begin
                    accumulator <= accumulator + {16'd0, rd_data_a};
                    if (pos == 255) begin
                        result <= accumulator + {16'd0, rd_data_a};
                        done <= 1;
                        state <= IDLE;
                    end else begin
                        pos <= pos + 1;
                        state <= SUM_F;
                    end
                end

                IDLE: begin
                    // stay here
                end
            endcase
        end
    end

endmodule