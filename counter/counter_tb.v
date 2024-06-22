// Defines timescale for simulation: <time_unit> / <time_precision>
`timescale 1ns / 10ps

module counter_tb();

    wire out;

    reg     clk = 0;
    reg     rst = 0;

    localparam DURATION = 10000;            // 10000 * 1ns = 10us

    clk_div #(.NUM_FF(10), .TOP(19)) uut(.clk(clk), .rst(rst), .sig(out));        // 5MHz output signal


    initial begin

        // Create simulation output file
        $dumpfile("counter_tb.vcd");
        $dumpvars(0,counter_tb);

        // Run for DURATION
        #(DURATION)

        // Simulation complete
        $display("Done");
        $finish;
    end


    initial begin

        // Reset counter
        #5
        rst = 1'b1;
        #1
        rst = 1'b0;
    end


    
    always begin

        #5
        clk = ~clk;         // 100 MHz clock
    end



endmodule