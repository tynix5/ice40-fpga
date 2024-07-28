`timescale 100ps/10ps


module uart_tb();

    localparam DURATION = 1100000;
    reg clk, rst;
    wire serial;
    reg wr_en;
    reg [7:0] data_in;
    wire [7:0] data_out;
    wire tx_empty, rx_full;

    uart_tx #(.BAUD(9600)) uart_t(.clk(clk), .rst(rst), .wr_en(wr_en), .byte(data_in), .tx_empty(tx_empty), .tx(serial));
    uart_rx #(.BAUD(9600)) uart_r(.clk(clk), .rst(rst), .rx(serial), .rx_full(rx_full), .byte(data_out));

    initial begin
        // Create simulation output file
        $dumpfile("uart_tb.vcd");
        $dumpvars(0,uart_tb);

        // Run for DURATION
        #(DURATION)

        // Simulation complete
        $display("\ndata_in: %d\t\tdata_out: %d", 8'b11110000, data_out);
        $display("Done");
        $finish;
    end


    initial begin

        // initialize
        data_in = 8'b11110010;
        #5
        rst = 1;
        #5
        rst = 0;

        #25
        wr_en = 1;
        #10
        wr_en = 0;
        data_in = 0;
        #DURATION
        wr_en = 0;
    end

    always begin

        // 100 MHz
        #5
        clk = 1;
        #5
        clk = 0;
    end

endmodule