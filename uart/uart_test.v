module uart_test(

    input clk,
    input rst,
    output tx
);


    reg wr_en;
    reg [20:0] delay_cnt;

    wire rst_n, empty;
    assign rst_n = ~rst;

    uart_tx #(.BAUD(115200)) test(.clk(clk), .rst(rst_n), .wr_en(wr_en), .byte(8'b01011001), .empty(empty), .tx(tx));

    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            wr_en <= 1'b0;
            delay_cnt <= 21'b0;
        end
        else begin
            delay_cnt <= delay_cnt + 21'b1;
            if (delay_cnt == {21{1'b1}} && empty) begin
                wr_en <= 1'b1;
            end
            else begin
                wr_en = 1'b0;
            end
        end
    end

endmodule