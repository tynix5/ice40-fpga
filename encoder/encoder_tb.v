`timescale 1ns/10ps


module encoder_tb();

    localparam DURATION = 10000;            // 10000 * 1ns = 10us

    reg [3:0] in;
    wire [1:0] out;

    encoder enc(.in(in), .out(out));  


    initial begin

        // Create simulation output file
        $dumpfile("encoder_tb.vcd");
        $dumpvars(0,encoder_tb);

        // Run for DURATION
        #(DURATION)

        // Simulation complete
        $display("Done");
        $finish;
    end

    initial begin

        in = 4'b0000;

    end

    always begin

        #5
        in = 4'b0001;
        #5
        in = 4'b0010;
        #5
        in = 4'b0100;
        #5
        in = 4'b1000;
        #5
        in = 4'b1010;
        #5
        in = 4'b0111;
        #5
        in = 4'b0011;
        #5
        in = 4'bxxxx;
        #5
        in = 4'b01zx;

    end

endmodule