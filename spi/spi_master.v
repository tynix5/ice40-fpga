module spi_master #(

    parameter F_SPI = 1_000_000,   
    parameter CPOL = 1'b0,      // clock polarity
    parameter CPHA = 1'b0       // clock phase
)(

    input clk,                  // clock
    input rst,                  // reset
    input start,                // initiate transmission
    input [7:0] data_in,        // data to be sent
    input miso,                 // spi line
    output sclk,                // spi clock
    output mosi,                // spi line
    output cs,                  // chip select
    output [7:0] data_out       // data received
);

    localparam F_CLK = 100_000_000;
    localparam SPI_TICK = F_CLK / F_SPI / 2;        // frequency spi clock should be toggled

    // FSM states
    localparam STATE_IDLE = 1'b0;
    localparam STATE_BUSY = 1'b1;
    // SPI modes
    localparam SPI_MODE0 = 2'b00;
    localparam SPI_MODE1 = 2'b01;
    localparam SPI_MODE2 = 2'b10;
    localparam SPI_MODE3 = 2'b11;

    reg state;              // FSM state reg
    wire [1:0] spi_mode;    // CPOL and CPHA state

    reg sclk_reg, mosi_reg, cs_reg; // spi output lines

    reg [7:0] do_reg, do_latch;     // data out register and latch
    reg [7:0] di_latch;             // data in latch

    reg spi_en;                 // spi clock enable
    reg next_en;                // bit counter enable
    wire sclk_edge;             // spi clock edge detection (transitions)
    wire done;                  // bit counter overflow

    wire [2:0] spi_bit;         // current bit
    wire [4:0] edge_cnt;        // current count of clock edges
    wire edge_rst;
    reg edge_rst_reg;

    mod #(.MOD(SPI_TICK)) spi_sclk_mod(.clk(clk), .rst(rst), .cen(spi_en), .sync_ovf(sclk_edge));
    mod #(.MOD(8)) spi_bit_mod(.clk(clk), .rst(rst), .cen(next_en), .q(spi_bit), .sync_ovf(done));
    mod #(.MOD(32)) spi_edge_mod(.clk(clk), .rst(edge_rst), .cen(sclk_edge), .q(edge_cnt));      // need >4 bits
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // initialize master
            sclk_reg <= CPOL;
            mosi_reg <= 1'b0;
            cs_reg <= 1'b1;         // device not selected
            spi_en <= 1'b0;         // disable spi clock
            do_reg <= 8'b0;
            do_latch <= 8'b0;
            state <= STATE_IDLE;    // default idle state

        end
        else begin

            case (state)
                STATE_IDLE: begin

                    next_en <= 1'b0;

                    if (start) begin            // start transmission...
                        spi_en <= 1'b1;         // enable spi clock
                        cs_reg <= 1'b0;         // device selected
                        di_latch <= data_in;    // latch data
                        state <= STATE_BUSY;    // transition states
                    end
                    else begin
                        
                        sclk_reg <= CPOL;       // clock idle
                        spi_en <= 1'b0;         // disable spi clock
                        cs_reg <= 1'b1;         // device not selected
                        state <= STATE_IDLE;    // transition states
                    end
                end
                STATE_BUSY: begin
                    case (spi_mode)
                        SPI_MODE0: begin        // data sample on rising edge and shifted on falling edge
                            next_en <= 1'b0;

                            if (sclk_edge)      sclk_reg <= ~sclk_reg;      // toggle clock on edge
                            else                sclk_reg <= sclk_reg;

                            mosi_reg <= di_latch[3'b111 - spi_bit];         // put current bit onto line (MSb first)

                            if (sclk_edge && sclk_reg)          // if transitioning to falling edge...
                                next_en <= 1'b1;                // move to next bit
                            else if (sclk_edge && ~sclk_reg)    // if transitioning to rising edge...
                                do_reg <= {do_reg[6:0], miso};  // sample miso line


                            if (done) begin             // when all bits have been exchanged
                                sclk_reg <= CPOL;       // clock idle
                                spi_en <= 1'b0;         // disable spi clock
                                cs_reg <= 1'b1;         // deselect device
                                do_latch <= do_reg;     // latch output data
                                state <= STATE_IDLE;    // idle
                            end
                        end
                        SPI_MODE1: begin        // data sampled on falling edge and shifted on rising edge
                            
                            edge_rst_reg <= 1'b0;
                            next_en <= 1'b0;

                            if (sclk_edge)      sclk_reg <= ~sclk_reg;      // toggle clock on edge
                            else                sclk_reg <= sclk_reg;

                            mosi_reg <= di_latch[3'b111 - spi_bit];         // put current bit onto line (MSb first)

                            if (sclk_edge && sclk_reg)          // if transitioning to falling edge...
                                do_reg <= {do_reg[6:0], miso};  // sample miso line
                            else if (sclk_edge && ~sclk_reg && edge_cnt != 5'b0000)    // if transitioning to rising edge...
                                next_en <= 1'b1;                // move to next bit (only when not first rising edge)

                            if (edge_cnt == 5'b10000 && sclk_edge) begin

                                edge_rst_reg <= 1'b1;   // reset clock edge counter
                                sclk_reg <= CPOL;
                                spi_en <= 1'b0;
                                cs_reg <= 1'b1;
                                do_latch <= do_reg;
                                state <= STATE_IDLE;
                            end

                        end
                        SPI_MODE2: begin        // data sampled on falling edge and shifted on rising edge

                        end
                        SPI_MODE3: begin        // data sampled on rising edge and shifted on falling edge

                        end
                    endcase

                end

            endcase
        end
    end

    assign sclk = sclk_reg;
    assign mosi = mosi_reg;
    assign cs = cs_reg;
    assign data_out = do_latch;
    assign edge_rst = edge_rst_reg | rst;
    assign spi_mode = {CPOL, CPHA};
endmodule