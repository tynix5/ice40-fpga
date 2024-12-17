`timescale 1ns/1ps


module dds_tb();

    reg clk, rst;
    wire [9:0] dac_out;

    dds_sig_gen dds_uut(.clk(clk), .rst(rst), .dac_out(dac_out));

    localparam DURATION = 100000;

    initial begin
        // Create simulation output file
        $dumpfile("dds_tb.vcd");
        $dumpvars(0,dds_tb);

        // Run for DURATION
        #(DURATION)

        // Simulation complete
        $display("Done");
        $finish;
    end

    initial begin

        rst = 1;
        #10
        rst = 0;

    end

    always begin

        clk = 0;
        #5
        clk = 1;
        #5;
    end

endmodule