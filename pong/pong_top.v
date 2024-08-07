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
    localparam SCREEN_WIDTH = 400;
    localparam SCREEN_HEIGHT = 600;
    localparam WRES_BITS = $clog2(SCREEN_WIDTH);
    localparam HRES_BITS = $clog2(SCREEN_HEIGHT);

    // Paddle constraints
    localparam PADDLELEFT_XMIN = 10;
    localparam PADDLERIGHT_XMAX = SCREEN_WIDTH - PADDLELEFT_XMIN;
    localparam PADDLE_WIDTH = 7;
    localparam INIT_PADDLE_YMIN = 225;
    localparam PADDLE_HEIGHT = 150;
    localparam PADDLE_YMOVE = 8;

    // Ball constraints
    localparam INIT_BALL_XMIN = 197;
    localparam INIT_BALL_YMIN = 295;
    localparam BALL_WIDTH = 4;
    localparam BALL_HEIGHT = BALL_WIDTH * 2;
    // Ball states
    localparam BALL_XDIR_LEFT = 1'b0;
    localparam BALL_XDIR_RIGHT = 1'b1;
    localparam BALL_YDIR_PARALLEL = 2'b00;
    localparam BALL_YDIR_DOWN = 2'b01;
    localparam BALL_YDIR_UP = 2'b10;

    reg [HRES_BITS-1:0] paddleleft_y, paddleright_y;        // left and right paddle y coordinates
    reg [HRES_BITS-1:0] ball_y;                             // ball y coordinate
    reg [WRES_BITS-1:0] ball_x;                             // ball x coordinate
    reg ball_xdir;                                          // ball x direction
    reg [1:0] ball_ydir;                                    // ball y direction
    reg [1:0] ball_xvel, ball_yvel;                         // ball x and y velocities

    // synchronize raw external reset
    wire rst, rsync;
    synchronizer #(.SYNC_STAGES(2)) reset_synchronizer(.clk(clk), .rst(1'b0), .async_in(rst_n), .sync_out(rsync));

    // initialize button debounce modules
    wire leftup, leftdown, rightup, rightdown;
    debouncer leftup_db(.clk(clk), .rst(rst), .btn(paddleleft_up), .press(leftup));             // paddleleft up button debouncer
    debouncer leftdown_db(.clk(clk), .rst(rst), .btn(paddleleft_down), .press(leftdown));       // paddleleft down button debouncer
    debouncer rightup_db(.clk(clk), .rst(rst), .btn(paddleright_up), .press(rightup));          // paddleright up button debouncer
    debouncer rightdown_db(.clk(clk), .rst(rst), .btn(paddleright_down), .press(rightdown));    // paddleright down button debouncer

    // ball movement timer
    wire update_ball;
    mod #(.MOD(750_000)) updateball_mod(.clk(clk), .rst(rst), .cen(1'b1), .q(), .sync_ovf(update_ball));       // 133 Hz

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
            ball_xdir <= BALL_XDIR_LEFT;
            ball_ydir <= BALL_YDIR_PARALLEL;     
            ball_xvel <= 2'b0;      // ball not moving
            ball_yvel <= 2'b0;      // ball not moving
            newgame_en <= 1'b1;     // wait a little to start new game
        end
        else begin

            paddleleft_y <= paddleleft_y;
            paddleright_y <= paddleright_y;
            ball_xdir <= ball_xdir;
            ball_ydir <= ball_ydir;
            ball_xvel <= ball_xvel;
            ball_yvel <= ball_yvel;

            /***************************************************************************/
            /***********************  Paddle Movement Logic ****************************/
            /***************************************************************************/
            if (leftup && ~leftdown) begin                          // if left paddle moving up
                if (paddleleft_y < PADDLE_YMOVE)                    // if paddle is at top of screen
                    paddleleft_y <= 'b0;                            // stay at top of screen
                else
                    paddleleft_y <= paddleleft_y - PADDLE_YMOVE;    // else, move paddle up
            end

            if (leftdown && ~leftup) begin                                          // if left paddle moving down
                if (paddleleft_y + PADDLE_HEIGHT + PADDLE_YMOVE >= SCREEN_HEIGHT)   // if paddle is at bottom of screen
                    paddleleft_y <= SCREEN_HEIGHT - PADDLE_HEIGHT;                  // stay at bottom of screen
                else
                    paddleleft_y <= paddleleft_y + PADDLE_YMOVE;                    // else, move paddle down
            end

            if (rightup && ~rightdown) begin                        // if right paddle moving up
                if (paddleright_y < PADDLE_YMOVE)                   // if paddle is at top of screen
                    paddleright_y <= 'b0;                           // stay at top of screen
                else
                    paddleright_y <= paddleright_y - PADDLE_YMOVE;  // else, move paddle up
            end

            if (rightdown && ~rightup) begin                                        // if right paddle moving down
                if (paddleright_y + PADDLE_HEIGHT + PADDLE_YMOVE >= SCREEN_HEIGHT)  // if paddle is at bottom of screen
                    paddleright_y <= SCREEN_HEIGHT - PADDLE_HEIGHT;                 // stay at bottom of screen
                else
                    paddleright_y <= paddleright_y + PADDLE_YMOVE;                  // else, move paddle down
            end
            /***************************************************************************/
            /***************************************************************************/
            /***************************************************************************/

            if (~newgame_en) begin
                /***************************************************************************/
                /*********************** Ball Movement Logic *******************************/
                /***************************************************************************/

                if (update_ball) begin

                    // if ball goes past front face of paddle...
                    if (ball_x < PADDLELEFT_XMIN + PADDLE_WIDTH || ball_x > PADDLERIGHT_XMAX - PADDLE_WIDTH) begin
                        // point is scored, start new game and tally point
                        newgame_en <= 1'b1;
                    end
                    
                    
                    if (ball_xdir == BALL_XDIR_LEFT) begin

                        // if ball makes contact with left paddle...
                        if (ball_x - ball_xvel <= PADDLELEFT_XMIN + PADDLE_WIDTH && ball_y + BALL_HEIGHT >= paddleleft_y && ball_y <= paddleleft_y + PADDLE_HEIGHT) begin
                            
                            ball_xdir <= BALL_XDIR_RIGHT;        // change ball direction

                            // if ball hits extreme top or bottom of paddle
                            if (ball_y < paddleleft_y + BALL_HEIGHT || ball_y > paddleleft_y + PADDLE_HEIGHT - BALL_HEIGHT) begin
                                ball_xvel <= 2'b01;            // move slower in x direction
                                ball_yvel <= 2'b11;            // move faster in y direction
                                ball_x <= ball_x + 2'b01;
                                ball_y <= ball_y - 2'b11;

                                // change ball direction off paddle if ball is moving parallel to paddle
                                if (ball_ydir == BALL_YDIR_PARALLEL) begin
                                    if (ball_y < paddleleft_y + BALL_HEIGHT)    // if ball hits top part of paddle, bounce up
                                        ball_ydir <= BALL_YDIR_UP;  
                                    else
                                        ball_ydir <= BALL_YDIR_DOWN;            // if ball hits bottom, bounce down
                                end      
                            end
                            // if ball hits center left or center right of paddle
                            else if (ball_y < paddleleft_y + (PADDLE_HEIGHT >> 1) - BALL_HEIGHT || ball_y > paddleleft_y + (PADDLE_HEIGHT >> 1) + BALL_HEIGHT) begin
                                ball_xvel <= 2'b10;            // move same in x direction
                                ball_yvel <= 2'b10;            // move same in y direction
                                ball_x <= ball_x + 2'b10;
                                ball_y <= ball_y - 2'b10;  

                                // change ball direction off paddle if ball is moving parallel to paddle
                                if (ball_ydir == BALL_YDIR_PARALLEL) begin
                                    if (ball_y < paddleleft_y + (PADDLE_HEIGHT >> 1) - BALL_HEIGHT)
                                        ball_ydir <= BALL_YDIR_UP;      // if ball hits top center half of paddle, bounce up
                                    else
                                        ball_ydir <= BALL_YDIR_DOWN;    // if ball hits bottom center half of paddle, bounce down
                                end      
                            end
                            // ball hits center paddle
                            else begin
                                // move ball parallel
                                ball_xvel <= 2'b11;
                                ball_yvel <= 2'b00;
                                ball_x <= ball_x + 2'b11;
                                ball_y <= ball_y;
                                ball_ydir <= BALL_YDIR_PARALLEL;
                            end
                            
                        end
                        else
                            ball_x <= ball_x - ball_xvel;      // keep moving to the left
                    end
                    else if (ball_xdir == BALL_XDIR_RIGHT) begin
                        // if ball makes contact with right paddle...
                        if (ball_x + BALL_WIDTH + ball_xvel >= PADDLERIGHT_XMAX - PADDLE_WIDTH && ball_y + BALL_HEIGHT >= paddleright_y && ball_y <= paddleright_y + PADDLE_HEIGHT) begin

                            // change direction
                            ball_xdir <= BALL_XDIR_LEFT;
                            
                            // if ball hits extreme top or bottom of paddle
                            if (ball_y < paddleright_y + BALL_HEIGHT || ball_y > paddleright_y + PADDLE_HEIGHT - BALL_HEIGHT) begin
                                ball_xvel <= 2'b01;            // move slower in x direction
                                ball_yvel <= 2'b11;            // move faster in y direction
                                ball_x <= ball_x + 2'b01;
                                ball_y <= ball_y - 2'b11;

                                // change ball direction off paddle if ball is moving parallel to paddle
                                if (ball_ydir == BALL_YDIR_PARALLEL) begin
                                    if (ball_y < paddleright_y + BALL_HEIGHT)    // if ball hits top part of paddle, bounce up
                                        ball_ydir <= BALL_YDIR_UP;  
                                    else
                                        ball_ydir <= BALL_YDIR_DOWN;             // if ball hits bottom , bounce down
                                end      
                            end
                            // if ball hits center left or center right of paddle
                            else if (ball_y < paddleright_y + (PADDLE_HEIGHT >> 1) - BALL_HEIGHT || ball_y > paddleright_y + (PADDLE_HEIGHT >> 1) + BALL_HEIGHT) begin
                                ball_xvel <= 2'b10;            // move same in x direction
                                ball_yvel <= 2'b10;            // move same in y direction
                                ball_x <= ball_x + 2'b10;
                                ball_y <= ball_y - 2'b10;  

                                // change ball direction off paddle if ball is moving parallel to paddle
                                if (ball_ydir == BALL_YDIR_PARALLEL) begin
                                    if (ball_y < paddleright_y + (PADDLE_HEIGHT >> 1) - BALL_HEIGHT)              
                                        ball_ydir <= BALL_YDIR_UP;          // if ball hits top center half of paddle, bounce up
                                    else
                                        ball_ydir <= BALL_YDIR_DOWN;        // if ball hits bottom center half, bounce down
                                end
                            end
                            // ball hits center paddle
                            else begin
                                // move ball parallel
                                ball_xvel <= 2'b11;
                                ball_yvel <= 2'b00;
                                ball_x <= ball_x + 2'b11;
                                ball_y <= ball_y;
                                ball_ydir <= BALL_YDIR_PARALLEL;
                            end
                            ball_x <= ball_x - ball_xvel;
                        end
                        else
                            ball_x <= ball_x + ball_xvel;     // keep moving to the right
                    end

                    if (ball_ydir == BALL_YDIR_DOWN) begin
                        // if ball makes contact with bottom border
                        if (ball_y + BALL_HEIGHT + ball_yvel >= SCREEN_HEIGHT) begin
                            // change direction
                            ball_y <= ball_y - ball_yvel;
                            ball_ydir <= BALL_YDIR_UP;
                        end
                        else
                            ball_y <= ball_y + ball_yvel;     // keep moving down
                    end
                    else if (ball_ydir == BALL_YDIR_UP) begin
                        // if ball makes contact with top border
                        if (ball_y < ball_yvel) begin
                            // change direction
                            ball_y <= ball_y + ball_yvel;
                            ball_ydir <= BALL_YDIR_DOWN;
                        end
                        else
                            ball_y <= ball_y - ball_yvel;     // keep moving up
                    end

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
                ball_ydir <= BALL_YDIR_PARALLEL;
                newgame_en <= newgame_en;
                if (game_ready) begin
                    newgame_en <= 1'b0;     // disable start timer
                    ball_xvel <= 2'b11;     // ball moving parallel to screen to player who lost last point
                    ball_yvel <= 2'b00;
                end 
            end
        end
    end

    assign rst = ~rsync;        // invert reset signal

endmodule