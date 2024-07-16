module uart_tx #(

    parameter BAUD = 9600
)(

    input clk,
    input rst,
    input wen,
    input [7:0] byte,
    output tx
);

    localparam FREQ = 32'd100_000_000;      // 100 MHz
    localparam UART_TICK = FREQ / BAUD;     // ticks per serial bit

    // FSM states
    localparam MODE_IDLE = 2'b00;
    localparam MODE_START = 2'b01;
    localparam MODE_DATA = 2'b10;
    localparam MODE_STOP = 2'b11;


    reg [1:0] mode, mode_next;
    reg [31:0] tim, tim_next;
    reg [2:0] data_cnt, data_cnt_next;
    reg tx_next;
    

    // current state
    always @(posedge clk or posedge rst) begin

        if (rst) begin
            mode <= MODE_IDLE;
            data_cnt <= 3'b000;
            tim <= 32'b0;
            tx <= 1'b1;
        end
        else begin
            mode <= mode_next;
            data_cnt <= data_cnt_next;
            tim <= tim_next;
            tx <= tx_next;
        end
    end

    // next state (combinational) logic
    always @(*) begin

        tim_next = tim + 32'b1;
        mode_next = mode;
        tx_next = tx;
        data_cnt_next = data_cnt;

        case (mode) 
            MODE_IDLE:
            begin
                if (wen) begin
                    tx_next = 1'b0;
                    tim_next = 32'b0;
                    mode_next = MODE_START;
                end
                else 
                    tx_next = 1'b1;
            end
            MODE_START:
            begin
                if (tim == UART_TICK) begin
                    tx_next = data[0];      // lsb first
                    tim_next = 32'b0;
                    mode_next = MODE_DATA;
                end
            end
            MODE_DATA:
            begin
                if (tim == UART_TICK) begin
                    tim_next = 32'b0;
                    mode_next = MODE_DATA;
                    data_cnt_next = data_cnt + 3'b1;

                    if (data_cnt_next == 3'b000) begin
                        mode_next = MODE_STOP;
                        tx_next = 1'b1;
                    end
                    else
                        tx_next = data[data_cnt_next];
                end
            end
            MODE_STOP:
            begin
                if (tim == UART_TICK) begin
                    mode_next = MODE_IDLE;
                    tim_next = 32'b0;
                end
            end
        endcase
    end





endmodule