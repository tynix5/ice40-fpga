module dds_top (

    input clk,
    input rst_n,
    output sclk,
    output mosi,
    output cs
);

    wire rst, rst_n_sync;
    synchronizer rst_synch(.clk(clk), .rst(1'b0), .async_in(rst_n), .sync_out(rst_n_sync));

    reg start;
    wire [15:0] data;
    reg [9:0] dac_data;

    dac_spi #(.F_SPI(10_000_000)) spi_uut(.clk(clk), .rst(rst), .start(start), .data(data), .sclk(sclk), .mosi(mosi), .cs(cs));
    // dds_sig_gen sin_wave(.clk(clk), .rst(rst), .dac_out)

    reg [31:0] timer, timer2;

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            timer <= 32'b0;
            timer2 <= 32'b0;
            dac_data <= 10'b0;
        end
        else begin
            timer <= timer + 32'b1;
            timer2 <= timer2 + 32'b1;
            start <= 1'b0;

            if (timer == 50) begin

                start <= 1'b1;
                timer <= 32'b0;
            end

            if (timer2 == 500) begin
                dac_data <= dac_data + 10'b1;
                timer2 <= 32'b0;
            end
        end
    end

    assign rst = ~rst_n_sync;
    assign data = {4'b0001, dac_data, 2'b00};
endmodule