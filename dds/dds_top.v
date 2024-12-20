module dds_top (

    input clk,
    input rst_n,
    output sclk,
    output mosi,
    output cs
);

    /************* MCP4012 DAC commands *****************/
    localparam DAC_CHANNEL_A = 4'b0000;
    localparam DAC_CHANNEL_B = 4'b1000;
    localparam DAC_GAIN_1X = 4'b0010;
    localparam DAC_GAIN_2X = 4'b0000;
    localparam DAC_SHUTDOWN = 4'b0000;
    localparam DAC_ON = 4'b0001;
    /****************************************************/

    wire rst, rst_n_sync;
    synchronizer rst_synch(.clk(clk), .rst(1'b0), .async_in(rst_n), .sync_out(rst_n_sync));

    wire start, done;
    wire [15:0] spi_data;        // raw SPI data sent to DAC
    wire [9:0] dac_in;           // 10-bit DAC value
    reg [4:0] start_delay;       // delay from last SPI transaction complete to start of next transaction (5 clock cycles) --> DAC needs at least 15ns

    spi_master #(.F_SPI(10_000_000), .CPOL(1'b0), .CPHA(1'b0), .N(16)) dac_spi(
        .clk(clk), 
        .rst(rst), 
        .start(start), 
        .data_in(spi_data), 
        .miso(1'b0), 
        .sclk(sclk), 
        .mosi(mosi), 
        .cs(cs), 
        .done(done),
        .data_out());


    reg dac_channel;
    wire [9:0] dac_in_sin, dac_in_basic;

    dds_sin_gen sin_wave(.clk(clk), .rst(rst), .dac_out(dac_in_sin));       // output on channel A
    dds_basic_gen basic_wave(.clk(clk), .rst(rst), .dac_out_square(dac_in_basic));      // output on channel B

    integer i;

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            start_delay <= 5'b00001;        // start first transaction 5 clock cycles after reset
            dac_channel <= 1'b0;
        end
        else begin
            
            if (done) begin
                start_delay[0] <= 1'b1;         // load enable for next transaction
                dac_channel <= ~dac_channel;    // switch channels
            end
            else        
                start_delay[0] <= 1'b0;

            // shift start down pipeline
            for (i = 1; i < 5; i = i + 1)
                start_delay[i] <= start_delay[i-1];

        end
    end

    assign rst = ~rst_n_sync;
    assign start = start_delay[4];
    // select spi burst based on current channel
    assign spi_data = dac_channel ? {DAC_CHANNEL_A | DAC_GAIN_2X | DAC_ON, dac_in_sin, 2'b00} : {DAC_CHANNEL_B | DAC_GAIN_2X | DAC_ON, dac_in_basic, 2'b00};

endmodule