`timescale 1ns/10ps


module fifo_tb();

wire out;

    reg clk = 0;
    reg rst = 0;
    reg wr = 0;
    reg rd = 0;
    wire empty;
    wire full;
    reg [7:0] w_data;
    wire [7:0] r_data;

    localparam DURATION = 10000;            // 10000 * 1ns = 10us

    fifo #(.D_WIDTH(8), .A_WIDTH(3)) fifo_uut(.clk(clk), .rst(rst), .wr(wr), .rd(rd), .w_data(w_data), .empty(empty), .full(full), .r_data(r_data));        // 5MHz output signal


    initial begin

        // Create simulation output file
        $dumpfile("fifo_tb.vcd");
        $dumpvars(0,fifo_tb);

        // Run for DURATION
        #(DURATION)

        // Simulation complete
        $display("Done");
        $finish;
    end


    initial begin

        // Reset counter
        #1
        rst = 1'b1;
        #1
        rst = 1'b0;
    end

    always begin
        #5
        clk = 0;
        #5
        clk = 1;
    end
    
    always begin

        w_data = 8'hff;
        rd = 0;
        wr = 1;
        #75
        wr = 0;
        rd = 1;
        #75;
    end

endmodule
