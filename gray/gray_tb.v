`timescale 100ps/1ps

module gray_tb();

    localparam DURATION = 200;
    reg clk = 0, rst, en;
    wire [3:0] bin, gray;

    gray #(.MOD(16)) gray_cnt(.clk(clk), .rst(rst), .en(en), .bin_out(bin), .gray_out(gray));

    initial begin

        // Create simulation output file
        $dumpfile("gray_tb.vcd");
        $dumpvars(0,gray_tb);

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
        en = 1;
        // stream of clock pulses (100 MHz)
        forever begin
            #5
            clk = ~clk;
            // if (clk)
            //     $display("bin: %b       gray: %b", bin, gray);
        end
    end

endmodule