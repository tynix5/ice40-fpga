`timescale 1ns/100ps

module spi_tb();

    localparam DURATION = 50000;

    reg clk, rst, start;
    reg [7:0] di;

    wire sclk, mosi, miso, cs;
    wire [7:0] do;

    spi_master #(.F_SPI(1_000_000), .CPOL(1'b0), .CPHA(1'b1)) 
    master_uut(
        .clk(clk), 
        .rst(rst), 
        .start(start), 
        .data_in(di), 
        .miso(miso), 
        .sclk(sclk), 
        .mosi(mosi), 
        .cs(cs), 
        .data_out(do));

    spi_slave #(.CPOL(1'b0), .CPHA(1'b1))
    slave_uut(
        .clk(clk),
        .rst(rst),
        .sclk(sclk),
        .mosi(mosi),
        .cs(cs),
        .miso(miso));

    initial begin

        // Create simulation output file
        $dumpfile("spi_tb.vcd");
        $dumpvars(0,spi_tb);

        // Run for DURATION
        #(DURATION)

        // Simulation complete
        $display("Done");
        $finish;
    end

    initial begin
        // reset
        start = 0;
        di = 8'b00101011;
        rst = 1;
        #10
        rst = 0;
        clk = 0;
        start = 1;

        // stream of clock pulses (100 MHz)
        forever begin
            #5
            clk = ~clk;
        end
    end

endmodule