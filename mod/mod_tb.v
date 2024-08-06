`timescale 100ps/1ps

module mod_tb();

    localparam DURATION = 200;
    reg clk = 0, rst, en = 1;
    wire [3:0] bin, bin2;
    wire ovf;

    mod #(.MOD(16)) mod_cnt(.clk(clk), .rst(rst), .cen(en), .q(bin), .sync_ovf(ovf));
    mod #(.MOD(16)) mod_ovf(.clk(clk), .rst(rst), .cen(ovf), .q(bin2), .sync_ovf());

    initial begin

        // Create simulation output file
        $dumpfile("mod_tb.vcd");
        $dumpvars(0,mod_tb);

        // Run for DURATION
        #(DURATION)

        // Simulation complete
        $display("Done");
        $finish;
    end

    integer i;
    initial begin
        // reset
        rst = 1;
        #10
        rst = 0;

        for (i=0;i<15;i++) begin
            #5
            clk = 1;
            #5
            clk = 0;
        end

        en = 0;
        #5
        clk = 1;
        #5
        clk = 0;
        en = 1;

        // stream of clock pulses (100 MHz)
        forever begin
            #5
            clk = ~clk;
        end
    end

endmodule