module dds_top (

    input clk,
    input rst_n,
    output sclk,
    output mosi,
    output cs
);

    wire rst, rst_n_sync;
    synchronizer rst_synch(.clk(clk), .rst(1'b0), .async_in(rst_n), .sync_out(rst_n_sync));

    wire start, done;
    wire [15:0] spi_data;        // raw SPI data sent to DAC
    wire [9:0] dac_in;           // 10-bit DAC value
    reg [4:0] start_delay;       // delay from last SPI transaction complete to start of next transaction (5 clock cycles) --> DAC needs at least 15ns

    dac_spi #(.F_SPI(10_000_000)) spi_uut(.clk(clk), .rst(rst), .start(start), .data(spi_data), .sclk(sclk), .mosi(mosi), .cs(cs), .done(done));
    dds_sig_gen sin_wave(.clk(clk), .rst(rst), .dac_out(dac_in));

    integer i;

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            start_delay <= 5'b00001;        // start first transaction 5 clock cycles after reset
        end
        else begin
            
            if (done)   start_delay[0] <= 1'b1;         // load enable for next transaction
            else        start_delay[0] <= 1'b0;

            // shift start down pipeline
            for (i = 1; i < 5; i = i + 1)
                start_delay[i] <= start_delay[i-1];

        end
    end

    assign rst = ~rst_n_sync;
    assign start = start_delay[4];
    assign spi_data = {4'b0001, dac_in, 2'b00};
    
endmodule