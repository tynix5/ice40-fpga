`timescale 100ps/100ps

module ir_tb();

    localparam DURATION = 50000;

    reg clk, rst, rcv;

    wire [31:0] burst;
    wire rdy;

    ir_rcv ir_uut(.clk(clk), .rst(rst), .rcv(rcv), .burst(burst), .ready(rdy));

    initial begin

        // Create simulation output file
        $dumpfile("ir_tb.vcd");
        $dumpvars(0,ir_tb);

        // Run for DURATION
        #(DURATION)

        // Simulation complete
        $display("Done");
        $finish;
    end

    initial begin
        // reset
        rst = 1;
        #10
        rst = 0;
        clk = 0;

        // stream of clock pulses (100 MHz)
        forever begin
            #5
            clk = ~clk;
        end
    end 

    always begin

        // @(negedge rst);
        // rcv = 0;
        // #90000000


    end

endmodule