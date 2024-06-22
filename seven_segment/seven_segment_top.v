
module seven_segment_top (

    // inputs
    input clk,
    input rst_btn,

    // outputs
    output [7:0] segments,
    output [3:0] sel
);

// seven segment 
wire            sel_flag;
wire            cnt_flag;
wire            rst;


// counter keeps track of digit currently on
wire  [1:0]             sel_cnt;

// counter keeps track of digit and # on digit
wire [3:0]              ones_cnt;
wire [3:0]              tens_cnt;
wire [3:0]              hund_cnt;
wire [3:0]              thou_cnt;

reg  [3:0]              dig_curr;    

// carry flags for ones, tens, hundreds
wire o_c, t_c, h_c;


// reset button is active low
assign rst = ~rst_btn;



// 1 kHz for multiplexing seven segment display
// 100 MHz / 100000 = 1 kHz
clk_div #(.NUM_FF(32), .TOP(100000 - 1)) select_clk (

    .clk(clk),
    .rst(rst),

    .sig(sel_flag)
);


// 20 Hz for counting upwards
// 100 MHz / 5000000 = 20 Hz
clk_div #(.NUM_FF(32), .TOP(5000000 - 1)) count_clk (

    .clk(clk),
    .rst(rst),

    .sig(cnt_flag)
);

// active-low decoder selects which display is currently on
al_decoder2_4 decoder (

    .in(sel_cnt),
    .z(sel)
);

// controls which segments are on for which number
segments io_seg (

    .in(dig_curr),
    .segs(segments)
);

/**********************************************************************************/
/******************************* Digit counters ***********************************/
/**********************************************************************************/
mod_counter #(.MOD(10)) ones (

    .clk(cnt_flag),
    .rst(rst),

    .cnt(ones_cnt),
    .ovf(o_c)
);

mod_counter #(.MOD(10)) tens (

    .clk(o_c),
    .rst(rst),

    .cnt(tens_cnt),
    .ovf(t_c)
);

mod_counter #(.MOD(10)) hund (

    .clk(t_c),
    .rst(rst),

    .cnt(hund_cnt),
    .ovf(h_c)
);

mod_counter #(.MOD(10)) thou (

    .clk(h_c),
    .rst(rst),

    .cnt(thou_cnt),
    .ovf()
);
/**********************************************************************************/
/***************************** End Digit counters *********************************/
/**********************************************************************************/


mod_counter #(.MOD(4)) mod4 (

    .clk(sel_flag),
    .rst(rst),

    .cnt(sel_cnt),
    .ovf()
);


always @(*) begin

    case (sel_cnt) 

        2'b00:          dig_curr <= ones_cnt;
        2'b01:          dig_curr <= tens_cnt;
        2'b10:          dig_curr <= hund_cnt;
        2'b11:          dig_curr <= thou_cnt;
        default:        dig_curr <= 0;
    endcase
end




endmodule