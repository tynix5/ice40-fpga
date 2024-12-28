`timescale 1ns/100ps

module ps2_tb();

    localparam DURATION = 2000000;
    localparam PS2_CLK_HL_PER = 50 * 1000;       // 50us clock high/low period
    localparam TIMEOUT_TICKS = 125 * 1000;

    reg clk, rst, ps2_clk, ps2_data;
    wire [7:0] data;
    wire done;

    ps2_dev_to_host ps2_uut(.clk(clk), .rst(rst), .ps2_clk(ps2_clk), .ps2_data(ps2_data), .data(data), .rdy(done));

    initial begin

        $dumpfile("ps2_tb.vcd");
        $dumpvars(0, ps2_tb);

        #(DURATION);

        $display("Done.");
        $finish;
    end

    initial begin

        #1
        rst = 1;
        #1
        rst = 0;
    end

    always begin

        #5
        clk = 0;
        #5
        clk = 1;
    end

    always begin
        
        ps2_data = 0;
        ps2_clk = 1;
        #20
        // start bit
        ps2_clk = 0;
        ps2_data = 0;
        #PS2_CLK_HL_PER;

        // timeout test
        ps2_clk = 1;
        ps2_data = 1;
        #PS2_CLK_HL_PER;
        ps2_clk = 0;
        ps2_data = 1;
        #TIMEOUT_TICKS;

        // idle
        ps2_clk = 1;
        ps2_data = 1;
        #TIMEOUT_TICKS;

        // start
        ps2_clk = 0;
        ps2_data = 0;
        #PS2_CLK_HL_PER;

        // data
        // 0
        ps2_clk = 1;
        ps2_data = 0;
        #PS2_CLK_HL_PER;
        ps2_clk = 0;
        ps2_data = 0;
        #PS2_CLK_HL_PER;
        // 1
        ps2_clk = 1;
        ps2_data = 1;
        #PS2_CLK_HL_PER;
        ps2_clk = 0;
        ps2_data = 1;
        #PS2_CLK_HL_PER;
        // 1
        ps2_clk = 1;
        ps2_data = 1;
        #PS2_CLK_HL_PER;
        ps2_clk = 0;
        ps2_data = 1;
        #PS2_CLK_HL_PER;
        // 1
        ps2_clk = 1;
        ps2_data = 1;
        #PS2_CLK_HL_PER;
        ps2_clk = 0;
        ps2_data = 1;
        #PS2_CLK_HL_PER;
        // 0
        ps2_clk = 1;
        ps2_data = 0;
        #PS2_CLK_HL_PER;
        ps2_clk = 0;
        ps2_data = 0;
        #PS2_CLK_HL_PER;
        // 1
        ps2_clk = 1;
        ps2_data = 1;
        #PS2_CLK_HL_PER;
        ps2_clk = 0;
        ps2_data = 1;
        #PS2_CLK_HL_PER;
        // 1
        ps2_clk = 1;
        ps2_data = 1;
        #PS2_CLK_HL_PER;
        ps2_clk = 0;
        ps2_data = 1;
        #PS2_CLK_HL_PER;
        // 1
        ps2_clk = 1;
        ps2_data = 1;
        #PS2_CLK_HL_PER;
        ps2_clk = 0;
        ps2_data = 1;
        #PS2_CLK_HL_PER;
        // 1 (parity)
        ps2_clk = 1;
        ps2_data = 1;
        #PS2_CLK_HL_PER;
        ps2_clk = 0;
        ps2_data = 1;
        #PS2_CLK_HL_PER;
        // 1 stop
        ps2_clk = 1;
        ps2_data = 1;
        #PS2_CLK_HL_PER;
        ps2_clk = 0;
        ps2_data = 1;
        #PS2_CLK_HL_PER;

    end

endmodule