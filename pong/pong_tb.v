`timescale 1ns/100ps

module pong_tb();

    localparam DURATION = 1000000;

    localparam CLK_PERIOD = 1 / 100_000_000;
    // VGA parameters
    localparam VGA_PERIOD = 1 / 40_000_000;

    localparam H_VISIBLE_AREA_PX = 800 / 2;     // since using 20MHz instead of 40 MHz
    localparam H_FRONT_PORCH_PX = 40 / 2;
    localparam H_SYNC_PULSE_PX = 128 / 2;
    localparam H_BACK_PORCH_PX = 88 / 2;
    localparam H_LINE_PX = H_VISIBLE_AREA_PX + H_FRONT_PORCH_PX + H_SYNC_PULSE_PX + H_BACK_PORCH_PX;
    localparam H_TICKS = H_LINE_PX * VGA_PERIOD / CLK_PERIOD;
    localparam H_BITS = $clog2(H_TICKS);

    // Vertical sync constraints
    localparam V_VISIBLE_AREA_LN = 600;
    localparam V_FRONT_PORCH_LN = 1;
    localparam V_SYNC_PULSE_LN = 4;
    localparam V_BACK_PORCH_LN = 23;
    localparam V_LINE = V_VISIBLE_AREA_LN + V_FRONT_PORCH_LN + V_SYNC_PULSE_LN + V_BACK_PORCH_LN;
    localparam V_TICKS = V_LINE * VGA_PERIOD / CLK_PERIOD;
    localparam V_BITS = $clog2(V_TICKS);
    parameter V_BITS2 = 32;
    parameter H_BITS2 = 32;


    wire h, v;
    reg clk = 0, rst;
    wire [34:0] segments;


    wire [5:0] left_count;
    reg left_en;
    // pong_score left_uut(.clk(clk), .rst(rst), .score(scoreleft), .state(leftdata));
    mod #(.MOD(35)) left_score_mod(.clk(clk), .rst(rst), .cen(left_en), .q(left_count));

    pong_score score_uut(.clk(clk), .rst(rst), .score(4'd0), .state(segments));

    // pong_vga vga_uut(
    // .clk(clk), 
    // .rst(rst),
    // .sprite1_xmin(10),
    // .sprite1_xmax(20),
    // .sprite1_ymin(100),
    // .sprite1_ymax(200),
    // .sprite2_xmin(380),
    // .sprite2_xmax(390),
    // .sprite2_ymin(100),
    // .sprite2_ymax(200),
    // .sprite3_x(0),
    // .sprite3_y(0),
    // .sprite3_rad(0),
    // .blank(),
    // .hsync(h),
    // .vsync(v),
    // .r(r),
    // .g(g),
    // .b(b));

    initial begin

        // Create simulation output file
        $dumpfile("pong_tb.vcd");
        $dumpvars(0,pong_tb);

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
        left_en = 1;
        // stream of clock pulses (100 MHz)
        forever begin
            #5
            clk = ~clk;
        end
    end
endmodule