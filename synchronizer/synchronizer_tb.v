`timescale 100ps/1ps

module synchronizer_tb();

    localparam DURATION = 500;
    reg clk = 0, rst, in;
    wire rising, falling, out;

    synchronizer #(.SYNC_STAGES(3)) sync(.clk(clk), .rst(rst), .async_in(in), .rise_edge_tick(rising), .fall_edge_tick(falling), .sync_out(out));

    initial begin

        // Create simulation output file
        $dumpfile("synchronizer_tb.vcd");
        $dumpvars(0,synchronizer_tb);

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
        // stream of clock pulses (100 MHz)
        forever begin
            #5
            clk = ~clk;
        end
    end

    always begin

        in = 0;
        #10
        in = 0;
        #10
        in = 1;
        #30
        in = 0;
        #10
        in = 0;
        #10
        in = 0;
    end

endmodule