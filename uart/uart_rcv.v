module uart_rx #(

    parameter BAUD = 9600
)(

    input clk,
    input rst,
    input rx,           
    output byte         // rx data output
);

    // state machine
    localparam MODE_IDLE = 2'b00;
    localparam MODE_START = 2'b01;
    localparam MODE_DATA = 2'b10;
    localparam MODE_STOP = 2'b11;

    // maximum and minimum allowable baud rates
    localparam MAX_BAUD = BAUD + 200;
    localparam MIN_BAUD = BAUD - 200;

    // lower the freq., more ticks
    localparam MIN_TICK = 32'd100_000_000 / MAX_BAUD;
    localparam MAX_TICK = 32'd100_000_000 / MIN_BAUD;

    reg [1:0] mode, mode_next;
    reg [7:0] data, data_next;
    reg [2:0] data_cnt, data_cnt_next;

    // very large timer to be safe...
    // ex. 100 MHz clock / 9600 baud = 10416 clock ticks per uart sample
    reg [31:0] tim;

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            mode <= MODE_IDLE;
            data <= 8'b0;
            data_next <= 8'b0;
            data_cnt <= 3'b0;
            data_cnt_next <= 3'b0;
        end
        else begin
            // update state
            tim <= tim + 1'b1;
            mode <= mode_next;
            data_cnt <= data_cnt_next;
            data <= data_next;
        end
    end

    always @(posedge clk) begin

        // default next state logic
        mode_next <= mode;
        data_next <= data;
        data_cnt_next <= data_cnt;

        case (mode)

            MODE_IDLE:
            begin
                if (!rx) begin
                    tim <= 32'b0;           // reset timer...
                    mode_next <= MODE_START;     // start bit detected
                end
            end

            MODE_START:
            begin
                // if timer has elapsed one serial bit...
                if (tim > MIN_TICK && tim < MAX_TICK) begin
                    tim <= 32'b0;           // reset timer...
                    if (!rx)
                        mode_next <= MODE_DATA;     // start bit valid
                    else           
                        mode_next <= MODE_IDLE;      // if start bit not valid, fail
                end
            end

            MODE_DATA:
            begin
                // if timer has elapsed one serial bit...
                if (tim > MIN_TICK && tim < MAX_TICK) begin

                    tim <= 32'b0;
                    data_next <= {rx, data_next[7:1]};          // lsb first
                    data_cnt_next <= data_cnt + 3'b1;           // one more bit read in...

                    // if all data bits are read in...
                    if (data_cnt == 3'b111) begin
                        data_cnt_next <= 3'b0;
                        mode_next <= MODE_STOP;
                    end
                end

            end

            MODE_STOP:
            begin
                // if timer has elapsed one serial bit...
                if (tim > MIN_TICK && tim < MAX_TICK) begin

                    tim <= 32'b0;
                    mode_next <= MODE_IDLE;

                    if (!rx)
                        data_next <= {8{1'bx}};         // if stop bit not read, mark all data as don't cares (for testing)
                end
            end

        endcase
    end


endmodule