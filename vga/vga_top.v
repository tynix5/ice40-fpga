module vga (

    input clk,              // 100 MHz clock
    input rst,              // global reset
    output blank,           // blanking period
    output hsync,           // horizontal sync signal
    output vsync,           // vertical sync signal 
    output r,               // red
    output g,               // green
    output b                // blue
);

    // Horizontal sync constraints
    // pixels are divided by 2 since using 20 MHz clock instead of typical 40 MHz
    localparam H_VISIBLE_AREA_PX = 800 / 2;
    localparam H_FRONT_PORCH_PX = 40 / 2;
    localparam H_SYNC_PULSE_PX = 128 / 2;
    localparam H_BACK_PORCH_PX = 88 / 2;
    localparam H_LINE_PX = H_VISIBLE_AREA_PX + H_FRONT_PORCH_PX + H_SYNC_PULSE_PX + H_BACK_PORCH_PX;
    localparam H_BITS = $clog2(H_LINE_PX);

    localparam H_START_BLANK = H_VISIBLE_AREA_PX - 1;
    localparam H_END_BLANK = H_LINE_PX - 1;
    localparam H_START_SYNC = H_VISIBLE_AREA_PX + H_FRONT_PORCH_PX - 1;
    localparam H_END_SYNC = H_VISIBLE_AREA_PX + H_FRONT_PORCH_PX + H_SYNC_PULSE_PX - 1;


    // Vertical sync constraints
    localparam V_VISIBLE_AREA_LN = 600;
    localparam V_FRONT_PORCH_LN = 1;
    localparam V_SYNC_PULSE_LN = 4;
    localparam V_BACK_PORCH_LN = 23;
    localparam V_LINE = V_VISIBLE_AREA_LN + V_FRONT_PORCH_LN + V_SYNC_PULSE_LN + V_BACK_PORCH_LN;
    localparam V_BITS = $clog2(V_LINE);

    localparam V_START_BLANK = V_VISIBLE_AREA_LN - 1;
    localparam V_END_BLANK = V_LINE - 1;
    localparam V_START_SYNC = V_VISIBLE_AREA_LN + V_FRONT_PORCH_LN - 1;
    localparam V_END_SYNC = V_VISIBLE_AREA_LN + V_FRONT_PORCH_LN + V_SYNC_PULSE_LN - 1;
    

    wire rst_n, rsync;

    wire [H_BITS-1:0] px;               // horizontal (pixel) counter
    wire [V_BITS-1:0] line;             // vertical (line) counter
              
    reg hsync_reg, vsync_reg;           // horizontal and vertical sync registers
    wire htrans_edge, vtrans_edge;      // horizontal and vertical transition edges
    reg hblank, vblank;                 // horizontal and vertical blanking

    mod #(.MOD(5)) div5_mod(.clk(clk), .rst(rst_n), .cen(1'b1), .q(), .sync_ovf(htrans_edge));                    // divides 100 MHz signal into 20 MHz
    mod #(.MOD(H_LINE_PX)) px_mod(.clk(clk), .rst(rst_n), .cen(htrans_edge), .q(px), .sync_ovf(vtrans_edge));     // pixel counter updated at 20 MHz
    mod #(.MOD(V_LINE)) line_mod(.clk(clk), .rst(rst_n), .cen(vtrans_edge), .q(line), .sync_ovf());               // line counter updated at every pixel overflow

    synchronizer #(.SYNC_STAGES(2)) reset_synchronizer(.clk(clk), .rst(1'b0), .async_in(rst), .rise_edge_tick(), .fall_edge_tick(), .sync_out(rsync));

    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            // initialize vga lines
            hsync_reg <= 1'b1;
            vsync_reg <= 1'b1;
            hblank <= 1'b0;
            vblank <= 1'b0;
        end
        else begin

            // default states
            hblank <= hblank;
            vblank <= vblank;
            hsync_reg <= hsync_reg;
            vsync_reg <= vsync_reg;


            if (htrans_edge) begin          // when px_mod is about to change...
                case (px)                   // update horizontal state according to pixel location
                    H_START_BLANK:      hblank <= 1'b1;
                    H_START_SYNC:       hsync_reg <= 1'b0;
                    H_END_SYNC:         hsync_reg <= 1'b1;
                    H_END_BLANK:        hblank <= 1'b0;
                endcase
            end
            if (vtrans_edge) begin          // when line_mod is about to change
                case (line)                 // update vertical state according to line
                    V_START_BLANK:      vblank <= 1'b1;
                    V_START_SYNC:       vsync_reg <= 1'b0;
                    V_END_SYNC:         vsync_reg <= 1'b1;
                    V_END_BLANK:        vblank <= 1'b0;
                endcase
            end

        end
    end

    assign rst_n = ~rsync;
    assign hsync = hsync_reg;
    assign vsync = vsync_reg;
    assign blank = hblank | vblank;     // blanking period whenever horizontal or vertical is in blank

    // make cool pattern
    assign r = blank ? 1'b0 : line[0];
    assign g = blank ? 1'b0 : line[1];
    assign b = blank ? 1'b0 : line[2];

endmodule