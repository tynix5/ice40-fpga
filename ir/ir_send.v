module ir_send(

    input clk,
    input rst,
    input [7:0] addr,
    input [7:0] cmd,
    input ir_send,
    output ir_led
);


    /***********************************************************/
    /***************** NEC Timing Protocol *********************/
    /***********************************************************/
    localparam AGC_BURST_CYCLES = 900_000;  // 9ms
    localparam SPACE_CYCLES = 450_000;      // 4.5ms
    localparam REPEAT_SPACE_CYCLES = 225_000;   // 2.25ms
    localparam CARRIER_CYCLES = 56_000;     // 560us
    localparam ONE_PERIOD = 225_000;        // 2.25ms
    localparam ZERO_PERIOD = 112_500;       // 1.125ms
    localparam REPEAT_PERIOD = 11_000_000;    // 110ms
    localparam CARRIER_FREQ = 38_000;       // 38 kHz
    /***********************************************************/
    /***********************************************************/
    /***********************************************************/

    // FSM states
    localparam S_IDLE = 3'b000;
    localparam S_AGC = 3'b001;
    localparam S_SPACE = 3'b010;
    localparam S_DATA = 3'b011;
    localparam S_DONE = 3'b100;

    reg [2:0] state;                        // FSM state

    reg [31:0] tim;                         // timer

    reg [31:0] burst;                       // address + inverted address + cmd + cmd inverted
    reg [4:0] burst_ptr;                    // burst bit pointer

    reg ir_mod_en;                          // enable IR LED modulation
    pwm #(.FREQ(CARRIER_FREQ), .DUTY(30)) ir_pwm(.clk(clk), .rst(rst), .en(ir_mod_en), .wave(ir_led));        // 38kHz between 25% and 33% duty cycle

    reg last_ir_send;                         // last enabled state
    wire ir_send_rising_edge;                 // rising edge of ir_send

    reg [23:0] hold_tim;                      // timer large enough to hold a count of 110ms at 100MHz (for repeat)
    reg ir_send_repeat;                       // detect if button is being held...

    /*****************************************************/
    /************* Previous State Logic ******************/
    /*****************************************************/
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            last_ir_send <= 1'b0;
        end
        else begin
            last_ir_send <= ir_send;            // update input
        end
    end
    /*****************************************************/
    /*****************************************************/
    /*****************************************************/


    /*****************************************************/
    /****************** Repeat Logic *********************/
    /*****************************************************/
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hold_tim <= 24'b0;
            ir_send_repeat <= 1'b0;
        end
        else begin

            if (~ir_send)
                hold_tim <= 24'b0;
            else begin

                hold_tim <= hold_tim + 24'b1;            // increment while send is held
                if (hold_tim == REPEAT_PERIOD) begin     // if timer is held enough for a repeat
                    ir_send_repeat <= 1'b1;
                    hold_tim <= 24'b0;
                end
            end

            if (state == S_DONE && ir_send_repeat)      // if done with repeat burst, wait until next repeat or data
                ir_send_repeat <= 1'b0;
        end
    end
    /*****************************************************/
    /*****************************************************/
    /*****************************************************/

    /*****************************************************/
    /****************** Timer Logic **********************/
    /*****************************************************/
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tim <= 32'b0;
        end
        else begin

            case (state)
                S_IDLE: begin
                    // reset timer
                    tim <= 32'b0;
                end
                S_AGC: begin
                    // count up until AGC burst ends
                    tim <= tim + 32'b1;     
                    if (tim == AGC_BURST_CYCLES)
                        tim <= 32'b0;
                end
                S_SPACE: begin
                    // count until SPACE ends
                    tim <= tim + 32'b1;
                    if (tim == SPACE_CYCLES)
                        tim <= 32'b0;
                    else if (tim == REPEAT_SPACE_CYCLES && ir_send_repeat)      // if repeat space
                        tim <= 32'b0;
                end
                S_DATA: begin
                    // count up until 1/0 clock period is over, then repeat for 32 bits
                    tim <= tim + 32'b1;
                    if ((burst[burst_ptr] && tim == ONE_PERIOD) || (~burst[burst_ptr] && tim == ZERO_PERIOD))
                        tim <= 32'b0;
                end
                S_DONE: begin
                    // count until final carrier burst
                    tim <= tim + 32'b1;
                end
            endcase
        end
    end
    /*****************************************************/
    /*****************************************************/
    /*****************************************************/

    /*****************************************************/
    /****************** Burst Data Logic *****************/
    /*****************************************************/
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            burst <= 32'b0;
        end
        else begin
            burst <= burst;
            case (state)
                S_IDLE: begin
                    if (ir_send_rising_edge)
                        burst <= {cmd ^ {8{1'b1}}, cmd, addr ^ {8{1'b1}}, addr};        // latch address and command (+ inversions) on enable
                end
                S_AGC, S_SPACE, S_DATA, S_DONE: begin
                    
                end
            endcase
        end
    end
    /*****************************************************/
    /*****************************************************/
    /*****************************************************/

    /*****************************************************/
    /*************** Burst Pointer Logic *****************/
    /*****************************************************/
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            burst_ptr <= 5'b0;
        end
        else begin
            burst_ptr <= burst_ptr;
            case (state)
                S_IDLE, S_AGC, S_SPACE, S_DONE: begin
                    burst_ptr <= 5'b0;              // reset burst pointer before data frame
                end
                S_DATA: begin
                    if ((burst[burst_ptr] && tim == ONE_PERIOD) || (~burst[burst_ptr] && tim == ZERO_PERIOD))   // update burst pointer after a '1' pulse period or '0' pulse period
                        burst_ptr <= burst_ptr + 5'b1;
                end
            endcase
        end
    end
    /*****************************************************/
    /*****************************************************/
    /*****************************************************/

    /*****************************************************/
    /****************** PWM Enable Logic *****************/
    /*****************************************************/
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ir_mod_en <= 1'b0;
        end
        else begin

            ir_mod_en <= ir_mod_en;

            case (state)
                S_IDLE: begin
                    if (ir_send_rising_edge || ir_send_repeat)        // begin AGC modulation on enable
                        ir_mod_en <= 1'b1;
                end
                S_AGC: begin
                    if (tim == AGC_BURST_CYCLES)    // stop AGC modulation when going to SPACE
                        ir_mod_en <= 1'b0;
                end
                S_SPACE: begin
                    if (tim == SPACE_CYCLES)        // start carrier burst
                        ir_mod_en <= 1'b1;
                    else if (tim == REPEAT_SPACE_CYCLES && ir_send_repeat)      // if repeat, also start carrier burst after 2.25ms
                        ir_mod_en <= 1'b1;
                end
                S_DATA: begin
                    if (tim == CARRIER_CYCLES)      // stop carrier burst
                        ir_mod_en <= 1'b0;
                    else if ((burst[burst_ptr] && tim == ONE_PERIOD) || (~burst[burst_ptr] && tim == ZERO_PERIOD))      // start carrier burst again after 1/0 pulse period
                        ir_mod_en <= 1'b1;
                end
                S_DONE: begin
                    if (tim == CARRIER_CYCLES)      // final carrier burst
                        ir_mod_en <= 1'b0;
                end
            endcase
        end
    end
    /*****************************************************/
    /*****************************************************/
    /*****************************************************/

    /*****************************************************/
    /******************** FSM Logic **********************/
    /*****************************************************/
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
        end
        else begin

            state <= state;

            case (state)
                S_IDLE: begin
                    if (ir_send_rising_edge || ir_send_repeat)          // move to AGC state on enable or repeat
                        state <= S_AGC;
                end
                S_AGC: begin
                    if (tim == AGC_BURST_CYCLES) begin    // move to SPACE state after AGC burst done
                        state <= S_SPACE;
                    end
                end
                S_SPACE: begin
                    if (tim == SPACE_CYCLES)        // move to carrier + bit after SPACE
                        state <= S_DATA;
                    else if (tim == REPEAT_SPACE_CYCLES && ir_send_repeat)  // send final carrier burst after repeat space
                        state <= S_DONE;
                end
                S_DATA: begin
                    // repeat DATA for 32 bits (carrier + data = 1 bit), then move to detect final carrier burst
                    if ((burst[burst_ptr] && tim == ONE_PERIOD) || (~burst[burst_ptr] && tim == ZERO_PERIOD)) begin
                        if (burst_ptr == 5'b11111)
                            state <= S_DONE;
                    end
                end
                S_DONE: begin
                    if (tim == CARRIER_CYCLES)      // after final carrier burst, idle
                        state <= S_IDLE;
                end
            endcase
        end
    end
    /*****************************************************/
    /*****************************************************/
    /*****************************************************/


    assign ir_send_rising_edge = (last_ir_send == 1'b0 && ir_send == 1'b1) ? 1'b1 : 1'b0;     // rising edge detection on ir enable

endmodule