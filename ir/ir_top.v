module ir_top(

    input clk,
    input rst_n,
    input rcv,
    output [7:0] led
);

    // synchronize raw external reset
    wire rst, rsync;
    synchronizer #(.SYNC_STAGES(2)) reset_synchronizer(.clk(clk), .rst(1'b0), .async_in(rst_n), .sync_out(rsync));

    wire rdy;
    wire [31:0] burst;
    ir_rcv ir(.clk(clk), .rst(rst), .ir_in(rcv), .burst(burst), .ready(rdy));

    reg [7:0] led_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            led_reg <= 8'b0;
        end
        else begin
            if (rdy) begin
                led_reg <= led_reg ^ {8{1'b1}};
            end
        end
    end

    assign led = led_reg;
    assign rst = ~rsync;

endmodule