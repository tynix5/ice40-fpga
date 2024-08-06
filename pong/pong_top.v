module pong_top (

    input clk,                  // clock
    input rst_n,                // inverted reset (from FPGA)
    input paddleleft_up,        // left paddle up button
    input paddleleft_down,      // left paddle down button
    input paddleright_up,       // right paddle up button
    input paddleright_down,     // right paddle down button
    output hsync,               // horizontal sync signal to VGA
    output vsync,               // vertical sync signal to VGA
    output r,                   // red pixel    
    output g,                   // green pixel
    output b                    // blue pixel
);

    // VGA resolution 400x600
    localparam VGA_W = 400;
    localparam VGA_H = 600;
    localparam W_BITS = $clog2(VGA_W);
    localparam H_BITS = $clog2(VGA_H);

    localparam PADDLELEFT_XMIN = 10;
    localparam PADDLERIGHT_XMAX = 390;
    localparam PADDLE_WIDTH = 7;
    localparam INIT_PADDLE_YMIN = 225;
    localparam PADDLE_HEIGHT = 150;
    localparam PADDLE_YMOVE = 10;
    localparam INIT_BALL_XMIN = 197;
    localparam INIT_BALL_YMIN = 295;
    localparam BALL_WIDTH = 4;
    localparam BALL_HEIGHT = BALL_WIDTH * 2;
    // localparam BALL_XVEL = 8;
    localparam BALL_YVEL = 1;
    localparam BALL_VEL = 1;
    localparam BALL_DIR_LEFT = 1'b0;
    localparam BALL_DIR_RIGHT = 1'b1;
    localparam BALL_DIR_DOWN = 1'b0;
    localparam BALL_DIR_UP = 1'b1;

    reg [H_BITS-1:0] paddleleft_y, paddleright_y;
    reg [H_BITS-1:0] ball_y;
    reg [W_BITS-1:0] ball_x;
    reg ball_xdir, ball_ydir;
    reg [1:0] ball_xvel, ball_yvel;

    // synchronize raw external reset
    wire rst, rsync;
    synchronizer #(.SYNC_STAGES(2)) reset_synchronizer(.clk(clk), .rst(1'b0), .async_in(rst_n), .rise_edge_tick(), .fall_edge_tick(), .sync_out(rsync));

    // initialize button debounce modules
    wire leftup, leftdown, rightup, rightdown;
    debouncer plu(.clk(clk), .rst(rst), .btn(paddleleft_up), .press(leftup));           // paddleleft up button debouncer
    debouncer pld(.clk(clk), .rst(rst), .btn(paddleleft_down), .press(leftdown));       // paddleleft down button debouncer
    debouncer pru(.clk(clk), .rst(rst), .btn(paddleright_up), .press(rightup));         // paddleright up button debouncer
    debouncer prd(.clk(clk), .rst(rst), .btn(paddleright_down), .press(rightdown));     // paddleright down button debouncer

    // ball movement timer
    wire update_ball;
    mod #(.MOD(750_000)) ball_mod(.clk(clk), .rst(rst), .cen(1'b1), .q(), .sync_ovf(update_ball));       // 133 Hz

    reg newgame_en;
    wire game_ready;
    mod #(.MOD(300_000_000)) newgame_mod(.clk(clk), .rst(rst), .cen(newgame_en), .q(), .sync_ovf(game_ready));      // 3 seconds between games

    // initialize screen
    pong_vga screen(
        .clk(clk), 
        .rst(rst), 
        .paddleleft_xmin(PADDLELEFT_XMIN),
        .paddleleft_xmax(PADDLELEFT_XMIN + PADDLE_WIDTH),
        .paddleleft_ymin(paddleleft_y),
        .paddleleft_ymax(paddleleft_y + PADDLE_HEIGHT),
        .paddleright_xmin(PADDLERIGHT_XMAX - PADDLE_WIDTH),
        .paddleright_xmax(PADDLERIGHT_XMAX),
        .paddleright_ymin(paddleright_y),
        .paddleright_ymax(paddleright_y + PADDLE_HEIGHT),
        .ball_xmin(ball_x),
        .ball_xmax(ball_x + BALL_WIDTH),
        .ball_ymin(ball_y),
        .ball_ymax(ball_y + BALL_HEIGHT),
        .blank(),
        .hsync(hsync),
        .vsync(vsync),
        .r(r),
        .g(g),
        .b(b));

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // initialize game
            paddleleft_y <= INIT_PADDLE_YMIN;
            paddleright_y <= INIT_PADDLE_YMIN;
            ball_x <= INIT_BALL_XMIN;
            ball_y <= INIT_BALL_YMIN;
            ball_xdir <= BALL_DIR_LEFT;
            ball_ydir <= BALL_DIR_DOWN;     
            ball_xvel <= 2'b0;      // ball not moving
            ball_yvel <= 2'b0;      // ball not moving
            newgame_en <= 1'b1;     // wait a little to start new game
        end
        else begin

            /***************************************************************************/
            /***********************  Paddle Movement Logic ****************************/
            /***************************************************************************/
            if (leftup && ~leftdown) begin
                if (paddleleft_y < PADDLE_YMOVE)
                    paddleleft_y <= 'b0;
                else
                    paddleleft_y <= paddleleft_y - PADDLE_YMOVE;
            end
            if (leftdown && ~leftup) begin   
                if (paddleleft_y + PADDLE_HEIGHT + PADDLE_YMOVE >= VGA_H)
                    paddleleft_y <= VGA_H - PADDLE_HEIGHT;
                else
                    paddleleft_y <= paddleleft_y + PADDLE_YMOVE;
            end
            if (rightup && ~rightdown) begin
                if (paddleright_y < PADDLE_YMOVE)
                    paddleright_y <= 'b0;
                else
                    paddleright_y <= paddleright_y - PADDLE_YMOVE;
            end
            if (rightdown && ~rightup) begin
                if (paddleright_y + PADDLE_HEIGHT + PADDLE_YMOVE >= VGA_H)
                    paddleright_y <= VGA_H - PADDLE_HEIGHT;
                else
                    paddleright_y <= paddleright_y + PADDLE_YMOVE;
            end
            /***************************************************************************/
            /***************************************************************************/
            /***************************************************************************/

            if (~newgame_en) begin
                /***************************************************************************/
                /*********************** Ball Movement Logic *******************************/
                /***************************************************************************/
                ball_xdir <= ball_xdir;
                ball_ydir <= ball_ydir;
                ball_xvel <= ball_xvel;
                ball_yvel <= ball_yvel;

                if (update_ball) begin

                    // if ball goes past front face of paddle...
                    if (ball_x < PADDLELEFT_XMIN + PADDLE_WIDTH || ball_x > PADDLERIGHT_XMAX - PADDLE_WIDTH) begin
                        // point is scored, start new game and tally point
                        newgame_en <= 1'b1;
                    end
                    else if (ball_xdir == BALL_DIR_LEFT) begin

                        // if ball makes contact with left paddle...
                        if (ball_x - ball_xvel <= PADDLELEFT_XMIN + PADDLE_WIDTH && ball_y + BALL_HEIGHT >= paddleleft_y && ball_y <= paddleleft_y + PADDLE_HEIGHT) begin
                            
                            ball_xdir <= BALL_DIR_RIGHT;        // change ball direction

                            // if ball hits top or bottom of paddle
                            if (ball_y < paddleleft_y || ball_y - BALL_HEIGHT > paddleleft_y + PADDLE_HEIGHT) begin
                                ball_xvel <= 2'b01;            // move slower in x direction
                                ball_yvel <= 2'b11;            // move faster in y direction
                                ball_x <= ball_x + 2'b01;
                                ball_y <= ball_y - 2'b11;      
                            end
                            // if ball hits center left or center right of paddle
                            else if (ball_y < paddleleft_y + (PADDLE_HEIGHT >> 1) - BALL_HEIGHT || ball_y > paddleleft_y + (PADDLE_HEIGHT >> 1) + BALL_HEIGHT) begin
                                ball_xvel <= 2'b10;            // move same in x direction
                                ball_yvel <= 2'b10;            // move same in y direction
                                ball_x <= ball_x + 2'b10;
                                ball_y <= ball_y - 2'b10;  
                            end
                            // ball hits center paddle
                            else begin
                                // move ball parallel
                                ball_xvel <= 2'b11;
                                ball_yvel <= 2'b00;
                                ball_x <= ball_x + 2'b11;
                                ball_y <= ball_y;
                            end
                            
                        end
                        else
                            ball_x <= ball_x - ball_xvel;      // keep moving to the left
                    end
                    else if (ball_xdir == BALL_DIR_RIGHT) begin
                        // if ball makes contact with right paddle...
                        if (ball_x + BALL_WIDTH + ball_xvel >= PADDLERIGHT_XMAX - PADDLE_WIDTH && ball_y + BALL_HEIGHT >= paddleright_y && ball_y <= paddleright_y + PADDLE_HEIGHT) begin

                            // change direction
                            ball_xdir <= BALL_DIR_LEFT;
                            
                            // if ball hits top or bottom of paddle
                            if (ball_y < paddleright_y || ball_y - BALL_HEIGHT > paddleright_y + PADDLE_HEIGHT) begin
                                ball_xvel <= 2'b01;            // move slower in x direction
                                ball_yvel <= 2'b11;            // move faster in y direction
                                ball_x <= ball_x + 2'b01;
                                ball_y <= ball_y - 2'b11;      
                            end
                            // if ball hits center left or center right of paddle
                            else if (ball_y < paddleright_y + (PADDLE_HEIGHT >> 1) - BALL_HEIGHT || ball_y > paddleright_y + (PADDLE_HEIGHT >> 1) + BALL_HEIGHT) begin
                                ball_xvel <= 2'b10;            // move same in x direction
                                ball_yvel <= 2'b10;            // move same in y direction
                                ball_x <= ball_x + 2'b10;
                                ball_y <= ball_y - 2'b10;  
                            end
                            // ball hits center paddle
                            else begin
                                // move ball parallel
                                ball_xvel <= 2'b11;
                                ball_yvel <= 2'b00;
                                ball_x <= ball_x + 2'b11;
                                ball_y <= ball_y;
                            end
                            ball_x <= ball_x - ball_xvel;
                        end
                        else
                            ball_x <= ball_x + ball_xvel;     // keep moving to the right
                    end

                    if (ball_ydir == BALL_DIR_DOWN) begin
                        // if ball makes contact with bottom border
                        if (ball_y + BALL_HEIGHT + ball_yvel >= VGA_H) begin
                            // change direction
                            ball_y <= ball_y - ball_yvel;
                            ball_ydir <= BALL_DIR_UP;
                        end
                        else
                            ball_y <= ball_y + ball_yvel;     // keep moving down
                    end
                    else if (ball_ydir == BALL_DIR_UP) begin
                        // if ball makes contact with top border
                        if (ball_y < ball_yvel) begin
                            // change direction
                            ball_y <= ball_y + ball_yvel;
                            ball_ydir <= BALL_DIR_DOWN;
                        end
                        else
                            ball_y <= ball_y - ball_yvel;     // keep moving up
                    end

                    // if ball makes contact with bottom border
                    if (ball_ydir == BALL_DIR_DOWN && ball_y + BALL_HEIGHT + ball_yvel >= VGA_H) begin
                        // change direction
                        ball_y <= ball_y - ball_yvel;
                        ball_ydir <= BALL_DIR_UP;
                    end
                    // if ball makes contact with top border
                    else if (ball_ydir == BALL_DIR_UP && ball_y < ball_yvel) begin
                        // change direction
                        ball_y <= ball_y + ball_yvel;
                        ball_ydir <= BALL_DIR_DOWN;
                    end
                    else
                        // keep moving in same direction
                        ball_y <= (ball_ydir == BALL_DIR_DOWN) ? ball_y + ball_yvel : ball_y - ball_yvel;


                end
                /***************************************************************************/
                /***************************************************************************/
                /***************************************************************************/
            end
            else begin
                ball_x <= INIT_BALL_XMIN;    // initialize ball x
                ball_y <= INIT_BALL_YMIN;    // initialize ball y
                ball_xvel <= 2'b0;              // stationary ball
                ball_yvel <= 2'b0;
                newgame_en <= newgame_en;
                if (game_ready) begin
                    newgame_en <= 1'b0;     // disable start timer
                    ball_xvel <= 2'b11;     // ball moving parallel to screen
                    ball_yvel <= 2'b00;
                end 
            end
        end
    end

    assign rst = ~rsync;        // invert reset signal

endmodule