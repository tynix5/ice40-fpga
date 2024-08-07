module pong_vga (

    input clk,
    input rst,
    input [WRES_BITS-1:0] paddleleft_xmin,
    input [WRES_BITS-1:0] paddleleft_xmax,
    input [HRES_BITS-1:0] paddleleft_ymin,
    input [HRES_BITS-1:0] paddleleft_ymax,
    input [WRES_BITS-1:0] paddleright_xmin,
    input [WRES_BITS-1:0] paddleright_xmax,
    input [HRES_BITS-1:0] paddleright_ymin,
    input [HRES_BITS-1:0] paddleright_ymax,
    input [WRES_BITS-1:0] ball_xmin,
    input [WRES_BITS-1:0] ball_xmax,
    input [HRES_BITS-1:0] ball_ymin,
    input [HRES_BITS-1:0] ball_ymax,
    output blank,
    output hsync,
    output vsync,
    output r,
    output g,
    output b
);

    // VGA resolution 400x600
    localparam SCREEN_WIDTH = 400;
    localparam SCREEN_HEIGHT = 600;
    localparam WRES_BITS = $clog2(SCREEN_WIDTH);
    localparam HRES_BITS = $clog2(SCREEN_HEIGHT);

    // Horizontal sync constraints (in pixels)
    // pixels are divided by 2 since using 20 MHz clock instead of typical 40 MHz
    localparam H_VISIBLE_AREA_PX = 800 / 2;
    localparam H_FRONT_PORCH_PX = 40 / 2;
    localparam H_SYNC_PULSE_PX = 128 / 2;
    localparam H_BACK_PORCH_PX = 88 / 2;
    localparam H_LINE_PX = H_VISIBLE_AREA_PX + H_FRONT_PORCH_PX + H_SYNC_PULSE_PX + H_BACK_PORCH_PX;
    localparam H_BITS = $clog2(H_LINE_PX);
    // Constraints used for comparison
    localparam H_START_BLANK = H_VISIBLE_AREA_PX - 1;
    localparam H_END_BLANK = H_LINE_PX - 1;
    localparam H_START_SYNC = H_VISIBLE_AREA_PX + H_FRONT_PORCH_PX - 1;
    localparam H_END_SYNC = H_VISIBLE_AREA_PX + H_FRONT_PORCH_PX + H_SYNC_PULSE_PX - 1;


    // Vertical sync constraints (in lines)
    localparam V_VISIBLE_AREA_LN = 600;
    localparam V_FRONT_PORCH_LN = 1;
    localparam V_SYNC_PULSE_LN = 4;
    localparam V_BACK_PORCH_LN = 23;
    localparam V_LINE = V_VISIBLE_AREA_LN + V_FRONT_PORCH_LN + V_SYNC_PULSE_LN + V_BACK_PORCH_LN;
    localparam V_BITS = $clog2(V_LINE);
    // Constraints used for comparison
    localparam V_START_BLANK = V_VISIBLE_AREA_LN - 1;
    localparam V_END_BLANK = V_LINE - 1;
    localparam V_START_SYNC = V_VISIBLE_AREA_LN + V_FRONT_PORCH_LN - 1;
    localparam V_END_SYNC = V_VISIBLE_AREA_LN + V_FRONT_PORCH_LN + V_SYNC_PULSE_LN - 1;

    localparam NET_WIDTH = 2;
    localparam NET_START = SCREEN_WIDTH / 2 - NET_WIDTH / 2 - 1;
    localparam NET_END = SCREEN_WIDTH / 2 + NET_WIDTH / 2 - 1;
    

    reg px_state;                       // pixel state

    wire [H_BITS-1:0] px;               // horizontal (pixel) counter
    wire [V_BITS-1:0] line;             // vertical (line) counter
              
    reg hsync_reg, vsync_reg;           // horizontal and vertical sync registers
    wire htrans_edge, vtrans_edge;      // horizontal and vertical transition edges
    reg hblank, vblank;                 // horizontal and vertical blanking

    mod #(.MOD(5)) div5_mod(.clk(clk), .rst(rst), .cen(1'b1), .q(), .sync_ovf(htrans_edge));                    // divides 100 MHz signal into 20 MHz
    mod #(.MOD(H_LINE_PX)) px_mod(.clk(clk), .rst(rst), .cen(htrans_edge), .q(px), .sync_ovf(vtrans_edge));     // pixel counter updated at 20 MHz
    mod #(.MOD(V_LINE)) line_mod(.clk(clk), .rst(rst), .cen(vtrans_edge), .q(line), .sync_ovf());               // line counter updated at every pixel counter overflow


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // initialize vga lines
            hsync_reg <= 1'b1;
            vsync_reg <= 1'b1;
            hblank <= 1'b0;
            vblank <= 1'b0;
            px_state <= 1'b0;
        end
        else begin

            // default states
            hblank <= hblank;
            vblank <= vblank;
            hsync_reg <= hsync_reg;
            vsync_reg <= vsync_reg;
            px_state <= px_state;

            if (htrans_edge) begin          // when pixel is about to change, setup next pixel state

                px_state <= 1'b0;           // initialize pixel off

                // generate net (every 8 lines)
                if (px >= NET_START && px <= NET_END && ~line[3])
                    px_state <= 1'b1;

                // generate pixels for left paddle
                if (px >= paddleleft_xmin && px <= paddleleft_xmax && line >= paddleleft_ymin && line <= paddleleft_ymax)
                    px_state <= 1'b1;

                // generate pixels for right paddle
                if (px >= paddleright_xmin && px <= paddleright_xmax && line >= paddleright_ymin && line <= paddleright_ymax)
                    px_state <= 1'b1;

                // generate pixels for ball
                if (px >= ball_xmin && px <= ball_xmax && line >= ball_ymin && line <= ball_ymax)
                    px_state <= 1'b1;

                // setup blank and sync lines
                case (px)
                    H_START_BLANK:      hblank <= 1'b1;
                    H_START_SYNC:      hsync_reg <= 1'b0;
                    H_END_SYNC:         hsync_reg <= 1'b1;
                    H_END_BLANK:        hblank <= 1'b0;
                endcase
               
            end
            if (vtrans_edge) begin          // when line is about to change
                case (line)                 // setup blank and sync lines
                    V_START_BLANK:      vblank <= 1'b1;
                    V_START_SYNC:       vsync_reg <= 1'b0;
                    V_END_SYNC:         vsync_reg <= 1'b1;
                    V_END_BLANK:        vblank <= 1'b0;
                endcase
            end

        end
    end

    assign hsync = hsync_reg;
    assign vsync = vsync_reg;
    assign blank = hblank | vblank;     // blanking period whenever horizontal or vertical is in blank

    // all white pixels
    assign r = blank ? 1'b0 : px_state;
    assign g = blank ? 1'b0 : px_state;
    assign b = blank ? 1'b0 : px_state;

endmodule