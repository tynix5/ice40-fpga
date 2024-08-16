// Returns XOR'd input byte on next byte exchange 
module spi_slave #(

    parameter F_SPI = 1_000_000,   
    parameter CPOL = 1'b0,      // clock polarity
    parameter CPHA = 1'b0       // clock phase
)(
    input clk,
    input rst,
    input sclk,
    input mosi,
    input cs,
    output miso
);

    localparam F_CLK = 100_000_000;

    // FSM states
    localparam STATE_IDLE = 1'b0;
    localparam STATE_BUSY = 1'b1;
    // SPI modes
    localparam SPI_MODE0 = 2'b00;
    localparam SPI_MODE1 = 2'b01;
    localparam SPI_MODE2 = 2'b10;
    localparam SPI_MODE3 = 2'b11;

    reg state;                  // FSM state register
    wire [1:0] spi_mode;        // CPOL and CPHA state

    reg [7:0] di_reg, xor_out;  // data in register and xor register

    reg miso_reg;               // slave output line
    reg last_sclk;              // last sclk state

    reg next_en;                // bit counter enable
    wire done;                  // bit counter overflow
    wire [2:0] spi_bit;         // current bit count

    reg [5:0] edge_cnt;         // sclk edge counter

    mod #(.MOD(8)) spi_bit_mod(.clk(clk), .rst(rst), .cen(next_en), .q(spi_bit), .sync_ovf(done));         // bit position counter

    reg [2:0] bit_cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // initialize slave on reset
            last_sclk <= CPOL;
            next_en <= 1'b0;
            di_reg <= 8'b0;
            xor_out <= 8'b0;
            state <= STATE_IDLE;
            miso_reg <= 1'bz;       // tri state

            edge_cnt <= 5'b0;
            bit_cnt <= 3'b0;
        end
        else begin

            // default states
            last_sclk <= sclk;
            next_en <= 1'b0;                     
            edge_cnt <= edge_cnt;
            miso_reg <= 1'bz;

            case (state)
                STATE_IDLE: begin
                    if (~cs) begin                  
                        edge_cnt <= 5'b0;
                        state <= STATE_BUSY;    // if device is selected, transmission in progress
                    end
                end
                STATE_BUSY: begin


                    case (spi_mode)
                        SPI_MODE0: begin        // data sample on rising edge and shifted on falling edge
                            miso_reg <= xor_out[3'b111 - spi_bit];      // Update MISO line when bit shifts on falling edge (MSb first)

                            if (last_sclk && ~sclk)             // if falling edge...
                                next_en <= 1'b1;                // shift to next bit
                            else if (~last_sclk && sclk)        // if rising edge...
                                di_reg <= {di_reg[6:0], mosi};  // sample bit
                            
                            if (done) begin               // when all bits have been transferred
                                xor_out <= di_reg ^ {8{1'b1}};  // xor received data for next transmission
                                state <= STATE_IDLE;            // idle
                            end
                        end
                        SPI_MODE1: begin        // data sampled on falling edge and shifted on rising edge
                            miso_reg <= xor_out[3'b111 - bit_cnt];      // Update MISO line when bit shifts on falling edge (MSb first)

                            bit_cnt <= bit_cnt;

                            if (last_sclk && ~sclk) begin             // if falling edge...
                                edge_cnt <= edge_cnt + 5'b1;
                                di_reg <= {di_reg[6:0], mosi};  // sample bit
                            end
                            else if (~last_sclk && sclk && edge_cnt != 5'b0)        // if rising edge..
                                bit_cnt <= bit_cnt + 1'b1;                // shift to next bit

                            if (cs) begin
                                bit_cnt <= 3'b0;
                                xor_out <= di_reg ^ {8{1'b1}};  // xor received data for next transmission
                                state <= STATE_IDLE;
                            end
                        end
                        SPI_MODE2: begin        // data sampled on falling edge and shifted on rising edge

                        end
                        SPI_MODE3: begin        // data sample on rising edge and shifted on falling edge

                        end
                    endcase

                end
            endcase
        end
    end

    assign miso = miso_reg;
    assign spi_mode = {CPOL, CPHA};

endmodule