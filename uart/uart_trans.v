module uart_tx #(

    parameter BAUD = 9600
)(

    input clk,
    input rst,
    input wr_en,                // write enable
    input [7:0] byte,           // data input
    output busy,                // uart busy line
    output tx                   // uart data out line
);

    localparam FREQ = 32'd100_000_000;      // 100 MHz
    localparam UART_TICK = FREQ / BAUD;     // ticks per serial bit

    // FSM states
    localparam MODE_IDLE = 2'b00;
    localparam MODE_START = 2'b01;
    localparam MODE_DATA = 2'b10;
    localparam MODE_STOP = 2'b11;

    reg [1:0] mode, mode_next;              // FSM current and next state
    reg [31:0] tim, tim_next;               // timer
    reg [2:0] data_cnt, data_cnt_next;      // data bits transmitted
    reg [7:0] data_latch, data_latch_next;  // data to be sent
    reg tx_reg, tx_next, busy_reg, busy_next;
    
    assign tx = tx_reg;
    assign busy = busy_reg;

    // current state
    always @(posedge clk or posedge rst) begin

        if (rst) begin
            // reset
            mode <= MODE_IDLE;
            data_cnt <= 3'b000;
            tim <= 32'b0;
            tx_reg <= 1'b1;
            busy_reg <= 1'b0;
            data_latch <= 8'b0;
        end
        else begin
            // update regs
            mode <= mode_next;
            data_cnt <= data_cnt_next;
            tim <= tim_next;
            tx_reg <= tx_next;
            busy_reg <= busy_next;
            data_latch <= data_latch_next;
        end
    end

    // next state (combinational) logic
    always @(*) begin

        // default next state
        tim_next = tim + 32'b1;
        mode_next = mode;
        tx_next = tx_reg;
        data_cnt_next = data_cnt;
        busy_next = busy_reg;
        data_latch_next = data_latch;

        case (mode) 
            MODE_IDLE:
            begin
                // if writing...
                if (wr_en) begin
                    tx_next = 1'b0;         // start bit    
                    tim_next = 32'b0;       // reset timer
                    mode_next = MODE_START; // go to start state
                    busy_next = 1'b1;       // uart is busy...
                    data_latch_next = byte; // latch data
                end
            end
            MODE_START:
            begin
                if (tim == UART_TICK) begin // start bit complete, first data bit
                    tx_next = data_latch[0];      // lsb first
                    tim_next = 32'b0;
                    mode_next = MODE_DATA;
                end
            end
            MODE_DATA:
            begin
                if (tim == UART_TICK) begin // data bit complete, next data bit or stop
                    tim_next = 32'b0;
                    mode_next = MODE_DATA;
                    data_cnt_next = data_cnt + 3'b1;

                    if (data_cnt_next == 3'b000) begin      // all 8 bits have been transmitted...
                        mode_next = MODE_STOP;
                        tx_next = 1'b1;     // stop bit
                    end
                    else
                        tx_next = data_latch[data_cnt_next];      // still sending data
                end
            end
            MODE_STOP:
            begin
                if (tim == UART_TICK) begin // stop bit complete
                    mode_next = MODE_IDLE;
                    tim_next = 32'b0;
                    busy_next = 1'b0;       // uart free now
                end
            end
        endcase
    end





endmodule