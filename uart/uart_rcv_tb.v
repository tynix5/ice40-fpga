`timescale 1ns/10ps

module uart_rcv_tb();

    localparam DURATION = 110000;
    reg clk, rst;
    reg tx;
    wire [7:0] out;

    uart_rx #(.BAUD(9600)) uart(.clk(clk), .rst(rst), .rx(tx), .byte(out));

    initial begin
        // Create simulation output file
        $dumpfile("uart_rcv_tb.vcd");
        $dumpvars(0,uart_rcv_tb);

        // Run for DURATION
        #(DURATION)

        // Simulation complete
        $display("Done");
        $finish;
    end

    initial begin

        #1
        tx = 1;
        rst = 1;
        #1
        rst = 0;
    end

    always begin

        #1
        clk = 1;
        #1
        clk = 0;
    end

    always begin

        // start
        #20
        tx = 0;
        // data
        #10416
        tx = 1;
        #10416
        tx = 0;
        #10416
        tx = 1;
        #10416
        tx = 0;
        #10416
        tx = 1;
        #10416
        tx = 0;
        #10416
        tx = 0;
        #10416
        tx = 1;
        #10416
        // stop
        tx = 1;
        #100000
        tx = 0;

    end

endmodule