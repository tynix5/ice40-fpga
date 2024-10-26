module ir_rcv (

    input clk,
    input rst,
    input ir_in,
    output [31:0] burst,
    output ready
);

    localparam F_CLK = 100_000_000;

    /***********************************************************/
    /***************** NEC Timing Protocol *********************/
    /***********************************************************/
    localparam [31:0]  AGC_BURST_MS = 9;
    localparam [31:0]  AGC_BURST_MIN_CYCLES = 850_000;
    localparam [31:0]  AGC_BURST_MAX_CYCLES = 950_000;

    localparam [31:0]  SPACE_MS = 4.5;
    localparam [31:0]  SPACE_MIN_CYCLES = 400_000;
    localparam [31:0]  SPACE_MAX_CYCLES = 500_000;

    localparam [31:0]  REPEAT_SPACE_MS = 2.25;
    localparam [31:0]  REPEAT_SPACE_MIN_CYCLES = 175_000;
    localparam [31:0]  REPEAT_SPACE_MAX_CYCLES = 275_000;

    localparam [31:0]  CARRIER_US = 560;
    localparam [31:0]  CARRIER_MIN_CYCLES = 51_000;
    localparam [31:0]  CARRIER_MAX_CYCLES = 61_000;

    localparam [31:0]  ONE_PULSE_DISTANCE_MS = 2.25;
    localparam [31:0]  ONE_PULSE_DISTANCE_MIN_CYCLES = 200_000;
    localparam [31:0]  ONE_PULSE_DISTANCE_MAX_CYCLES = 250_000;

    localparam [31:0]  ZERO_PULSE_DISTANCE_MS = 1.12;
    localparam [31:0]  ZERO_PULSE_DISTANCE_MIN_CYCLES = 87_000;
    localparam [31:0]  ZERO_PULSE_DISTANCE_MAX_CYCLES = 137_000;

    localparam [31:0]  TIMEOUT = 1_000_000;     // 10ms
    /***********************************************************/
    /***********************************************************/
    /***********************************************************/

    // FSM states
    localparam S_IDLE = 3'b000;         // idle
    localparam S_AGC = 3'b001;          // AGC burst 
    localparam S_SPACE = 3'b010;        // space between AGC burst and data
    localparam S_DATA = 3'b011;         // carrier burst + one/zero space
    localparam S_DONE = 3'b100;         // done

    reg [2:0] state;                    // FSM state register

    reg [31:0] burst_latch, burst_reg;  // address + cmd (+ inversion) registers  
    reg [4:0] burst_cnt;                // burst bit pointer

    reg [31:0] tim;                     // timer

    reg rdy_reg;                        // new data available

    wire ir_rising_edge, ir_falling_edge;
    synchronizer #(.SYNC_STAGES(2)) ir_rcv_synch(.clk(clk), .rst(rst), .async_in(ir_in), .rise_edge_tick(ir_rising_edge), .fall_edge_tick(ir_falling_edge));

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tim <= 32'b0;
        end
        else begin

            case (state)
                S_IDLE, S_DONE: begin
                    tim <= 32'b0;       // reset timer
                end
                S_AGC: begin
                    // count up until valid AGC burst detected
                    tim <= tim + 32'b1;
                    if (ir_rising_edge && tim >= AGC_BURST_MIN_CYCLES && tim <= AGC_BURST_MAX_CYCLES)
                        tim <= 32'b0;
                end
                S_SPACE: begin
                    // count up until valid SPACE detected
                    tim <= tim + 32'b1;
                    if (ir_falling_edge && tim >= SPACE_MIN_CYCLES && tim <= SPACE_MAX_CYCLES)
                        tim <= 32'b0;
                    else if (ir_falling_edge && tim >= REPEAT_SPACE_MIN_CYCLES && tim <= REPEAT_SPACE_MAX_CYCLES)       // repeat space is 2.25ms
                        tim <= 32'b0;
                end
                S_DATA: begin
                    // count up until valid carrier burst received and valid 1/0 pulse period
                    tim <= tim + 32'b1;

                    if (ir_falling_edge && tim >= ZERO_PULSE_DISTANCE_MIN_CYCLES && tim <= ZERO_PULSE_DISTANCE_MAX_CYCLES)
                        tim <= 32'b0;
                    else if (ir_falling_edge && tim >= ONE_PULSE_DISTANCE_MIN_CYCLES && tim <= ONE_PULSE_DISTANCE_MAX_CYCLES)
                        tim <= 32'b0;
                end
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            burst_cnt <= 5'b0;
        end
        else begin
            case (state)
                S_IDLE, S_AGC, S_SPACE, S_DONE: begin
                    // reset burst bit pointer
                    burst_cnt <= 5'b0;      
                end
                S_DATA: begin
                    // increment bit counter when next carrier burst is starting
                    burst_cnt <= burst_cnt;

                    if (ir_falling_edge)
                        burst_cnt <= burst_cnt + 5'b1;
                end
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            burst_reg <= 32'b0;
            burst_latch <= 32'b0;
            rdy_reg <= 1'b0;
        end
        else begin

            case (state)
                S_IDLE, S_AGC, S_SPACE: begin
                    // data not ready, keep burst reg and latch the same for repeats
                    burst_reg <= burst_reg;
                    burst_latch <= burst_latch;
                    rdy_reg <= 1'b0;
                end
                S_DATA: begin
                    // update burst reg when new valid 1/0 detected
                    burst_reg <= burst_reg;
                    burst_latch <= burst_latch;
                    rdy_reg <= 1'b0;

                    if (ir_falling_edge && tim >= ZERO_PULSE_DISTANCE_MIN_CYCLES && tim <= ZERO_PULSE_DISTANCE_MAX_CYCLES)
                        burst_reg[burst_cnt] <= 1'b0;
                    else if (ir_falling_edge && tim >= ONE_PULSE_DISTANCE_MIN_CYCLES && tim <= ONE_PULSE_DISTANCE_MAX_CYCLES)
                        burst_reg[burst_cnt] <= 1'b1;
                end
                S_DONE: begin
                    // latch in received data and signal new data available
                    burst_reg <= burst_reg;
                    burst_latch <= {burst_reg[7:0], burst_reg[15:8], burst_reg[23:16], burst_reg[31:24]};   // lsb first
                    rdy_reg <= 1'b1;
                end
            endcase
        end
    end


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
        end
        else begin

            state <= state;

            case (state)
                S_IDLE: begin
                    // when AGC burst detected, move to AGC
                    if (ir_falling_edge)        
                        state <= S_AGC;
                end
                S_AGC: begin
                    // if AGC burst ends and valid, move to SPACE, else IDLE
                    if (ir_rising_edge) begin
                        if (tim >= AGC_BURST_MIN_CYCLES && tim <= AGC_BURST_MAX_CYCLES)
                            state <= S_SPACE;
                        else
                            state <= S_IDLE;
                    end
                    else if (tim >= TIMEOUT)
                        state <= S_IDLE;
                end
                S_SPACE: begin
                    // if first carrier burst starts and SPACE is valid, move to data (or done for repeat), else IDLE
                    if (ir_falling_edge) begin
                        if (tim >= SPACE_MIN_CYCLES && tim <= SPACE_MAX_CYCLES)
                            state <= S_DATA;
                        else if (tim >= REPEAT_SPACE_MIN_CYCLES && tim <= REPEAT_SPACE_MAX_CYCLES)      // if repeat, signal ready and done
                            state <= S_DONE;
                        else
                            state <= S_IDLE;
                    end
                    else if (tim >= TIMEOUT)
                        state <= S_IDLE;
                end
                S_DATA: begin
                    // if carrier burst is over and valid, wait in this state until next carrier burst starts in order to receive data
                    // if burst counter is full, all bits have been received, move to DONE
                    state <= state;

                    if (ir_rising_edge) begin      // wait for 560us carrier burst to be over
                        if (!(tim >= CARRIER_MIN_CYCLES && tim <= CARRIER_MAX_CYCLES))
                            state <= S_IDLE;
                    end
                    else if (ir_falling_edge) begin     // wait for next carrier burst to begin, then check previous space to determine '1' or '0' bit
                        if ((tim >= ZERO_PULSE_DISTANCE_MIN_CYCLES && tim <= ZERO_PULSE_DISTANCE_MAX_CYCLES) || (tim >= ONE_PULSE_DISTANCE_MIN_CYCLES && tim <= ONE_PULSE_DISTANCE_MAX_CYCLES)) begin
                            if (burst_cnt == 5'b11111)
                                state <= S_DONE;
                        end
                        else
                            state <= S_IDLE;
                    end
                    else if (tim >= TIMEOUT)
                        state <= S_IDLE;
                end
                S_DONE: begin
                    // idle after final carrier burst
                    state <= S_IDLE;
                end
            endcase
        end
    end

    assign burst = burst_latch;
    assign ready = rdy_reg;

endmodule