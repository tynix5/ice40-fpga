module ir_top(

    input clk,
    input rst_n,
    input rcv,
    output ir_led,
    output [7:0] led
);

    // synchronize raw external reset
    wire rst, rsync;
    synchronizer #(.SYNC_STAGES(2)) reset_synchronizer(.clk(clk), .rst(1'b0), .async_in(rst_n), .sync_out(rsync));

    // Receiver
    wire rdy;
    wire [31:0] burst;
    ir_rcv ir_rx(.clk(clk), .rst(rst), .ir_in(rcv), .burst(burst), .ready(rdy));

    // Transmitter
    reg send_reg;
    wire send;
    wire [7:0] cmd;
    reg [7:0] cmd_reg;
    ir_send ir_tx(.clk(clk), .rst(rst), .addr(8'h10), .cmd(cmd), .ir_en(send), .ir_led(ir_led));

    reg [7:0] led_reg;
    reg [31:0] tim;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            send_reg <= 1'b0;
            led_reg <= 8'b0;
            tim <= 32'b0;
            cmd_reg <= 8'b1;
        end
        else begin
            tim <= tim + 32'b1;
            send_reg <= 1'b0;

            // send every 500ms
            if (tim == 32'd50_000_000) begin
                tim <= 32'b0;
                send_reg <= 1'b1;
                cmd_reg <= cmd_reg << 1;
                if (cmd_reg == 8'b10000000)
                    cmd_reg <= 8'b1;
            end

            if (rdy) begin
                led_reg <= burst[15:8];     // display data byte
            end
        end
    end

    assign cmd = cmd_reg;
    assign send = send_reg;
    assign led = led_reg;
    assign rst = ~rsync;

endmodule