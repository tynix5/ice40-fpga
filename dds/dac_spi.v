module dac_spi #(

    parameter F_SPI = 1_000_000
)(

    input clk,
    input rst,
    input start,
    input [15:0] data,
    output sclk,
    output mosi,
    output cs
);

    localparam F_CLK = 100_000_000;
    localparam SPI_TICK = F_CLK / F_SPI / 2;        // frequency spi clock should be toggled

    reg spi_state;
    reg sclk_reg, mosi_reg, cs_reg;

    reg spi_en;
    reg [3:0] data_bit;
    wire sclk_edge;

    localparam S_IDLE = 1'b0;
    localparam S_BUSY = 1'b1;

    reg [15:0] data_latch;

    mod #(.MOD(SPI_TICK)) spi_sclk_mod(.clk(clk), .rst(rst), .cen(spi_en), .q(), .sync_ovf(sclk_edge));

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            spi_state <= S_IDLE;
            sclk_reg <= 1'b0;
            mosi_reg <= 1'b0;
            cs_reg <= 1'b1;         // device inactive

            spi_en <= 1'b0;

        end
        else begin

            case (spi_state)

                S_IDLE: begin

                    sclk_reg <= 1'b0;
                    mosi_reg <= 1'b0;
                    cs_reg <= 1'b1;

                    spi_en <= 1'b0;

                    if (start) begin
                        cs_reg <= 1'b0;         // activate slave
                        data_latch <= data;     // latch data
                        spi_en <= 1'b1;         // enable counter

                        spi_state <= S_BUSY;    // move to wait state
                    end
                end
                S_BUSY: begin

                    if (sclk_edge) begin
                        sclk_reg <= ~sclk_reg;      // toggle spi clock

                        if (sclk_reg) begin            // falling edge, set up new data
                            data_bit <= data_bit + 4'b1;

                            if (data_bit == 4'b1111)    // if all data has been sent, idle
                                spi_state <= S_IDLE;
                        end
                    end

                    if (~sclk_reg)
                        mosi_reg <= data_latch[4'b1111 - data_bit];
                end
            endcase


        end
    end

    assign sclk = sclk_reg;
    assign mosi = mosi_reg;
    assign cs = cs_reg;

endmodule