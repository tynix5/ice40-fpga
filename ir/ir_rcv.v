module ir_rcv (

    input clk,
    input rst,
    input ir_in,
    output [31:0] burst,
    output ready
);

    localparam F_CLK = 100_000_000;

    /*********************************************************/
    /***************** Testbench parameters ******************/
    /*********************************************************/
    // localparam AGC_BURST_CYCLES = 900;
    // localparam AGC_BURST_MIN_CYCLES = 850;
    // localparam AGC_BURST_MAX_CYCLES = 950;
    // localparam SPACE_CYCLES = 450;
    // localparam SPACE_MIN_CYCLES = 400;
    // localparam SPACE_MAX_CYCLES = 500;
    // localparam CARRIER_CYCLES = 56;
    // localparam CARRIER_MIN_CYCLES = 51;
    // localparam CARRIER_MAX_CYCLES = 61;
    // localparam ONE_PULSE_DISTANCE_CYCLES = 225;
    // localparam ONE_PULSE_DISTANCE_MIN_CYCLES = 200;
    // localparam ONE_PULSE_DISTANCE_MAX_CYCLES = 250;
    // localparam ZERO_PULSE_DISTANCE_CYCLES = 112;
    // localparam ZERO_PULSE_DISTANCE_MIN_CYCLES = 87;
    // localparam ZERO_PULSE_DISTANCE_MAX_CYCLES = 137;
    /*********************************************************/
    /*********************************************************/
    /*********************************************************/

    localparam [31:0]  AGC_BURST_MS = 9;
    localparam [31:0]  AGC_BURST_MIN_CYCLES = 850_000;
    localparam [31:0]  AGC_BURST_MAX_CYCLES = 950_000;

    localparam [31:0]  SPACE_MS = 4.5;
    localparam [31:0]  SPACE_MIN_CYCLES = 400_000;
    localparam [31:0]  SPACE_MAX_CYCLES = 500_000;

    localparam [31:0]  CARRIER_US = 560;
    localparam [31:0]  CARRIER_MIN_CYCLES = 51_000;
    localparam [31:0]  CARRIER_MAX_CYCLES = 61_000;

    localparam [31:0]  ONE_PULSE_DISTANCE_MS = 2.25;
    localparam [31:0]  ONE_PULSE_DISTANCE_MIN_CYCLES = 200_000;
    localparam [31:0]  ONE_PULSE_DISTANCE_MAX_CYCLES = 250_000;

    localparam [31:0]  ZERO_PULSE_DISTANCE_MS = 1.12;
    localparam [31:0]  ZERO_PULSE_DISTANCE_MIN_CYCLES = 87_000;
    localparam [31:0]  ZERO_PULSE_DISTANCE_MAX_CYCLES = 137_000;

    // FSM states
    localparam S_IDLE = 3'b000;         // idle
    localparam S_AGC = 3'b001;          // AGC burst 
    localparam S_SPACE = 3'b010;        // space between AGC burst and data
    localparam S_DATA = 3'b011;
    localparam S_DATA_CARRIER = 3'b011; // address + command carrier burst
    localparam S_DATA_SPACE = 3'b100;   // address + command space
    localparam S_DONE = 3'b101;         // done

    reg [2:0] state;                        // FSM state register

    reg [31:0] burst_latch, burst_reg;
    reg [4:0] burst_cnt;

    reg [31:0] tim;

    reg rdy_reg;

    reg last_ir_in;
    wire ir_rising_edge, ir_falling_edge;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            last_ir_in <= 1'b1;
        end
        else begin
            last_ir_in <= ir_in;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tim <= 32'b0;
        end
        else begin

            case (state)
                S_IDLE, S_DONE: begin
                    tim <= 32'b0;
                end
                S_AGC: begin
                    tim <= tim + 32'b1;
                    if (ir_rising_edge && tim >= AGC_BURST_MIN_CYCLES && tim <= AGC_BURST_MAX_CYCLES)
                        tim <= 32'b0;
                end
                S_SPACE: begin
                    tim <= tim + 32'b1;
                    if (ir_falling_edge && tim >= SPACE_MIN_CYCLES && tim <= SPACE_MAX_CYCLES)
                        tim <= 32'b0;
                end
                S_DATA: begin
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
                    burst_cnt <= 5'b0;
                end
                S_DATA: begin
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
                    burst_reg <= burst_reg;
                    burst_latch <= burst_latch;
                    rdy_reg <= 1'b0;
                end
                S_DATA: begin
                    burst_reg <= burst_reg;
                    burst_latch <= burst_latch;
                    rdy_reg <= 1'b0;

                    if (ir_falling_edge && tim >= ZERO_PULSE_DISTANCE_MIN_CYCLES && tim <= ZERO_PULSE_DISTANCE_MAX_CYCLES)
                        burst_reg[burst_cnt] <= 1'b0;
                    else if (ir_falling_edge && tim >= ONE_PULSE_DISTANCE_MIN_CYCLES && tim <= ONE_PULSE_DISTANCE_MAX_CYCLES)
                        burst_reg[burst_cnt] <= 1'b1;
                end
                S_DONE: begin
                    burst_reg <= burst_reg;
                    burst_latch <= {burst_reg[7:0], burst_reg[15:8], burst_reg[23:16], burst_reg[31:24]};
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
                    if (ir_falling_edge)
                        state <= S_AGC;
                end
                S_AGC: begin
                    if (ir_rising_edge) begin
                        if (tim >= AGC_BURST_MIN_CYCLES && tim <= AGC_BURST_MAX_CYCLES)
                            state <= S_SPACE;
                        else
                            state <= S_IDLE;
                    end
                end
                S_SPACE: begin
                    if (ir_falling_edge) begin
                        if (tim >= SPACE_MIN_CYCLES && tim <= SPACE_MAX_CYCLES)
                            state <= S_DATA_CARRIER;
                        else
                            state <= S_IDLE;
                    end
                end
                S_DATA: begin
                    state <= state;

                    if (ir_rising_edge) begin      // wait for 560us carrier burst to be over
                        if (!(tim >= CARRIER_MIN_CYCLES && tim <= CARRIER_MAX_CYCLES))
                            state <= S_IDLE;
                    end
                    else if (ir_falling_edge) begin
                        if ((tim >= ZERO_PULSE_DISTANCE_MIN_CYCLES && tim <= ZERO_PULSE_DISTANCE_MAX_CYCLES) || (tim >= ONE_PULSE_DISTANCE_MIN_CYCLES && tim <= ONE_PULSE_DISTANCE_MAX_CYCLES)) begin
                            if (burst_cnt == 5'b11111)
                                state <= S_DONE;
                        end
                        else
                            state <= S_IDLE;
                    end
                end
                S_DONE: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

    assign ir_rising_edge = (ir_in == 1'b1 && last_ir_in == 1'b0) ? 1'b1 : 1'b0;
    assign ir_falling_edge = (ir_in == 1'b0 && last_ir_in == 1'b1) ? 1'b1 : 1'b0;
    assign burst = burst_latch;
    assign ready = rdy_reg;

endmodule