`timescale 1ns/100ps

module ir_tb();

    localparam DURATION = 1500000;

    reg clk, rst, rcv;

    wire [31:0] burst;
    wire rdy;

    integer i = 0;
    localparam [7:0] ADDR = 8'b00010000;
    localparam [7:0] DATA = 8'b11011000;

    reg [15:0] addr_burst = {ADDR, ADDR ^ {8{1'b1}}};
    reg [15:0] data_burst = {DATA, DATA ^ {8{1'b1}}};

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

        rcv = 1;
        @(negedge rst);
        #10

        // AGC burst with space
        rcv = 0;
        #9000
        rcv = 1;
        #4500

        // address
        i = 0;
        repeat(16) begin
            rcv = 0;
            #560
            rcv = 1;
            if (addr_burst[i]) #1690;
            else #560;
            i = i + 1;
        end

        // data
        i = 0;
        repeat(16) begin
            rcv = 0;
            #560
            rcv = 1;
            if (data_burst[i]) #1690;
            else #560;
            i = i + 1;
        end

        rcv = 0;
        #560      // final carrier burst to determine last bit
        rcv = 1;
    end

endmodule