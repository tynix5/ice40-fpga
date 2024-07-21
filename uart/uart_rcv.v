module uart_rx #(

    parameter BAUD = 9600
)(

    input clk,
    input rst,
    input rx,                  // uart data in line
    output rx_full,             // rx register full
    output [7:0] byte          // rx data output
);

    // state machine
    localparam MODE_IDLE = 2'b00;
    localparam MODE_START = 2'b01;
    localparam MODE_DATA = 2'b10;
    localparam MODE_STOP = 2'b11;

    // timing constants
    localparam FREQ = 32'd100_000_000;               // 100 MHz
    localparam UART_TICK = FREQ / BAUD;              // ticks per serial bit
    localparam SAMPLE_TICK = UART_TICK / 2;          // sample in middle of serial bit


    reg [1:0] mode, mode_next;
    reg [7:0] data, data_next, out, out_next;
    reg [2:0] data_cnt, data_cnt_next;
    reg rx_full_reg, rx_full_next;

    // very large timer to be safe...
    // ex. 100 MHz clock / 9600 baud = 10416 clock ticks per uart sample
    reg [31:0] tim, tim_next;

    assign byte = out;
    assign rx_full = rx_full_reg;

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            mode <= MODE_IDLE;
            data <= 8'b0;
            out <= 8'b0;
            data_cnt <= 3'b0;
            tim <= 32'b0;
            rx_full_reg <= 1'b0;
        end
        else begin
            // update state
            tim <= tim_next;
            mode <= mode_next;
            data_cnt <= data_cnt_next;
            data <= data_next;
            out <= out_next;
            rx_full_reg <= rx_full_next;
        end
    end

    always @(*) begin

        // default next state logic
        tim_next = tim + 32'b1;
        mode_next = mode;
        data_next = data;
        out_next = out;
        data_cnt_next = data_cnt;
        rx_full_next = rx_full_reg;

        case (mode)

            MODE_IDLE:
            begin
                if (!rx) begin
                    tim_next = 32'b0;           // reset timer...
                    mode_next = MODE_START;     // start bit detected
                    rx_full_next = 1'b0;        // new byte to be received
                end
            end

            MODE_START:
            begin
                // if sampling tick...
                if (tim == SAMPLE_TICK) begin
                    if (rx) begin
                        tim_next = 32'b0;
                        mode_next = MODE_IDLE;  // if start bit not valid, fail
                    end
                end
                // if start bit valid and serial bit has elapsed...
                else if (tim == UART_TICK) begin  
                    tim_next = 32'b0;           // reset timer
                    mode_next = MODE_DATA;      // expect data
                end
            end

            MODE_DATA:
            begin
                // if sampling tick...
                if (tim == SAMPLE_TICK) begin
                    data_next = {rx, data_next[7:1]};          // lsb first
                    data_cnt_next = data_cnt + 3'b1;           // one more bit read in...
                end
                // else if serial bit time has elapsed...
                else if (tim == UART_TICK) begin     
                    tim_next = 32'b0;
                    // if all data bits are read in...
                    if (data_cnt_next == 3'b000)
                        mode_next = MODE_STOP;      // expect stop bit
                end
            end

            MODE_STOP:
            begin
                // if sampling tick...
                if (tim == SAMPLE_TICK) begin
                    // assert that it is a stop bit (1)
                    if (!rx)
                        data_next = {8{1'bx}};         // if stop bit not read, mark all data as don't cares (for testing)
                end
                // if timer has elapsed one serial bit...
                else if (tim == UART_TICK) begin
                    tim_next = 32'b0;
                    out_next = data_next;           // latch received data
                    mode_next = MODE_IDLE;          // end of transmission, idle
                    rx_full_next = 1'b1;            // byte received
                end
            end

        endcase
    end


endmodule