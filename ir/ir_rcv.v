module ir_rcv (

    input clk,
    input rst,
    input rcv,
    output [31:0] burst,
    output ready
);

    localparam F_CLK = 100_000_000;

    localparam AGC_BURST_MS = 9;
    localparam AGC_BURST_CYCLES = AGC_BURST_MS * 1_000_000;
    localparam AGC_BURST_MIN_CYCLES = 8_500_000;
    localparam AGC_BURST_MAX_CYCLES = 9_500_000;

    // localparam SPACE_MS = 4.5;
    localparam SPACE_CYCLES = 4_500_000;
    localparam SPACE_MIN_CYCLES = 4_000_000;
    localparam SPACE_MAX_CYCLES = 5_000_000;

    localparam CARRIER_CYCLES = 560_000;
    localparam CARRIER_MIN_CYCLES = 510_000;
    localparam CARRIER_MAX_CYCLES = 610_000;

    localparam ONE_PULSE_DISTANCE_CYCLES = 2_250_000;
    localparam ONE_PULSE_DISTANCE_MIN_CYCLES = 2_000_000;
    localparam ONE_PULSE_DISTANCE_MAX_CYCLES = 2_500_000;

    localparam ZERO_PULSE_DISTANCE_CYCLES = 1_120_000;
    localparam ZERO_PULSE_DISTANCE_MIN_CYCLES = 800_000;
    localparam ZERO_PULSE_DISTANCE_MAX_CYCLES = 1_500_000;

    // localparam CNT_W = $clog2(AGC_BURST_CYCLES);
    localparam CNT_W = 32;

    localparam STATE_IDLE = 3'b000;         // idle
    localparam STATE_AGC = 3'b001;          // AGC burst 
    localparam STATE_SPACE = 3'b010;        // space between AGC burst and data
    // data consists of address + command     
    localparam STATE_DATA_CARRIER = 3'b101; // data carrier burst
    localparam STATE_DATA_SPACE = 3'b110;   // data space
    localparam STATE_DONE = 3'b111;         // done

    reg [2:0] state;

    reg [31:0] burst_reg, burst_latch;
    reg [4:0] data_bit_cnt;

    reg [CNT_W-1:0] tim;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tim <= {CNT_W{1'b0}};
            burst_reg <= 32'b0;
            burst_latch <= 32'b0;
            data_bit_cnt <= 5'b0;
            state <= STATE_IDLE;
        end
        else begin

            // default values
            tim <= tim;
            burst_reg <= burst_reg;
            burst_latch <= burst_latch;
            data_bit_cnt <= data_bit_cnt;
            state <= state;

            case (state)
                STATE_IDLE: begin
                    if (~rcv) begin
                        tim <= {CNT_W{1'b0}};       // reset timer
                        state <= STATE_AGC;
                    end
                end
                STATE_AGC: begin
                    tim <= tim + 32'b1;
                    if (rcv) begin
                        if (tim >= AGC_BURST_MIN_CYCLES && tim <= AGC_BURST_MAX_CYCLES) begin
                            tim <= {CNT_W{1'b0}};
                            state <= STATE_SPACE;
                        end
                        else
                            state <= STATE_IDLE;
                    end
                end
                STATE_SPACE: begin
                    tim <= tim + 32'b1;
                    if (~rcv) begin
                        if (tim >= SPACE_MIN_CYCLES && tim <= SPACE_MAX_CYCLES) begin
                            tim <= {CNT_W{1'b0}};
                            data_bit_cnt <= 5'b0;
                            state <= STATE_DATA_CARRIER;
                        end
                        else
                            state <= STATE_IDLE;
                    end
                end
                STATE_DATA_CARRIER: begin
                    tim <= tim + 32'b1;
                    if (rcv) begin      // wait for 560us carrier burst to be over
                        if (tim >= CARRIER_MIN_CYCLES && tim <= CARRIER_MAX_CYCLES)
                            state <= STATE_DATA_SPACE;
                        else
                            state <= STATE_IDLE;
                    end
                end
                STATE_DATA_SPACE: begin
                    tim <= tim + 32'b1;
                    data_bit_cnt <= data_bit_cnt;

                    if (~rcv) begin
                        data_bit_cnt <= data_bit_cnt + 4'b1;
                        if (tim >= ZERO_PULSE_DISTANCE_MIN_CYCLES && tim <= ZERO_PULSE_DISTANCE_MAX_CYCLES) begin
                            burst_reg <= {1'b0, burst_reg[31:1]};     // shift in data (lsb first)
                            if (data_bit_cnt == 5'b11111) begin
                                tim <= {CNT_W{1'b0}};
                                state <= STATE_DONE;
                            end
                            else begin
                                tim <= {CNT_W{1'b0}};
                                state <= STATE_DATA_CARRIER;
                            end
                        end
                        else if (tim >= ONE_PULSE_DISTANCE_MIN_CYCLES && tim <= ONE_PULSE_DISTANCE_MAX_CYCLES) begin
                            burst_reg <= {1'b1, burst_reg[31:1]};     // shift in data (lsb first)
                            if (data_bit_cnt == 5'b11111) begin
                                tim <= {CNT_W{1'b0}};
                                state <= STATE_DONE;
                            end
                            else begin
                                tim <= {CNT_W{1'b0}};
                                state <= STATE_DATA_CARRIER;
                            end
                        end
                        else begin
                            state <= STATE_IDLE;
                        end
                    end
                end
                STATE_DONE: begin
                    burst_latch <= burst_reg;
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

    assign burst = burst_latch;

endmodule