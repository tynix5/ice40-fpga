`timescale 1ns/1ps 

module debouncer_tb();

    localparam DURATION = 1000000;

    reg clk = 0, rst, in;
    wire out;

    debouncer db_uut(.clk(clk), .rst(rst), .btn(in), .press(out));

    initial begin

        // Create simulation output file
        $dumpfile("debouncer_tb.vcd");
        $dumpvars(0,debouncer_tb);

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

        forever begin
            #5
            clk = ~clk;
        end
    end

    initial begin

        in = 0;
        @(negedge rst);         // wait for reset to deassert
        
        #20
        in = 1;                 // simulate button press
        #5
        in = 0;                 // button release
        repeat(5) begin         // simulate bounce
            #1
            in = ~in;
        end
        #100
        in = 1;
    end

endmodule