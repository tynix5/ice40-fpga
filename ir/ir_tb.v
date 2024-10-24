`timescale 1ns/100ps

module ir_tb();

    localparam DURATION = 300000000;         // 300ms

    reg clk, rst, rcv;

    wire [31:0] burst;
    wire rdy;

    integer i = 0;
    localparam [7:0] ADDR = 8'b00010000;
    localparam [7:0] DATA = 8'b11011000;

    reg [15:0] addr_burst = {ADDR ^ {8{1'b1}}, ADDR};
    reg [15:0] data_burst = {DATA ^ {8{1'b1}}, DATA};

    reg ir_en;
    wire ir_out;

    // simulate receiever and sender communication
    ir_rcv ir_uut(.clk(clk), .rst(rst), .ir_in(rcv), .burst(burst), .ready(rdy));
    ir_send ir_send_uut(.clk(clk), .rst(rst), .addr(ADDR), .cmd(DATA), .ir_send(ir_en), .ir_led(ir_out));

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

        ir_en = 1'b1;
        #10;

        // ir_en = 0;
        // rcv = 1;
        // @(negedge rst);
        // #10
        // ir_en = 1;  // start transmitter

        // // AGC burst with space
        // rcv = 0;
        // #9000000
        // rcv = 1;
        // #4500000

        // // address
        // i = 0;
        // repeat(16) begin
        //     rcv = 0;
        //     #560000
        //     rcv = 1;
        //     if (addr_burst[i]) #1690000;
        //     else #560000;
        //     i = i + 1;
        // end

        // // data
        // i = 0;
        // repeat(16) begin
        //     rcv = 0;
        //     #560000
        //     rcv = 1;
        //     if (data_burst[i]) #1690000;
        //     else #560000;
        //     i = i + 1;
        // end

        // rcv = 0;
        // #560000      // final carrier burst to determine last bit
        // rcv = 1;
    end

endmodule