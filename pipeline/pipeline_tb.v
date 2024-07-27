`timescale 1ns/100ps

module pipeline_tb();

    localparam DURATION = 200;

    reg clk, rst;
    reg [3:0] in;
    wire [3:0] out;

    pipeline #(.SYNC_STAGES(4), .DATA_WIDTH(4)) pipe(.clk(clk), .rst(rst), .async_in(in), .sync_out(out));

    initial begin

        // Create simulation output file
        $dumpfile("pipeline_tb.vcd");
        $dumpvars(0,pipeline_tb);

        // Run for DURATION
        #(DURATION)

        // Simulation complete
        $display("Done");
        $finish;
    end

    initial begin
        // reset
        clk = 0;
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
        #10
        in = 4'b1001;
        #10
        in = 4'b0000;
        #10
        in = 4'b1010;
        #10
        in = 4'b0010;
    end


endmodule