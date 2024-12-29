module ps2_top(

    input clk,
    input rst_n,
    input ps2_c,
    input ps2_d,
    output tx
);

    wire rst_n_sync, rst;
    synchronizer #(.SYNC_STAGES(2)) rst_synchronizer(.clk(clk), .rst(1'b0), .async_in(rst_n), .rise_edge_tick(), .fall_edge_tick(), .sync_out(rst_n_sync));     // synchronize reset button

    wire uart_empty, buff_empty;
    wire [7:0] char;
    reg uart_wr_en, buff_rd_en;

    ps2_handler ps2_kb(.clk(clk), .rst(rst), .ps2_clk(ps2_c), .ps2_data(ps2_d), .rd(buff_rd_en), .ascii(char), .empty(buff_empty), .full());        // connect PS/2 keyboard
    uart_tx #(.BAUD(9600)) uart(.clk(clk), .rst(rst), .wr_en(uart_wr_en), .byte(char), .empty(uart_empty), .tx(tx));        // connect slow speed serial (so PS/2 buffer will fill)


    always @* begin

        uart_wr_en = 1'b0;
        buff_rd_en = 1'b0;

        if (~buff_empty && uart_empty) begin          // if data is in buffer, write it to uart and move to next location
            uart_wr_en = 1'b1;
            buff_rd_en = 1'b1;
        end
    end

    
    assign rst = ~rst_n_sync;

endmodule