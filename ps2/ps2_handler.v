module ps2_handler(

    input clk,
    input rst,
    input ps2_clk,
    input ps2_data,
    input rd,
    output [7:0] ascii,
    output empty,
    output full
);

    localparam BREAK = 8'hf0;
    localparam LEFT_SHIFT = 8'h12;
    localparam RIGHT_SHIFT = 8'h59;
    localparam CAPS_LOCK = 8'h58;

    reg case_shift;         // is shift key being held
    reg wr_buff;


    reg prev;
    wire [7:0] ps2_char;
    wire [7:0] ascii_char;
    wire rdy;

    fifo #(.D_WIDTH(8), .A_WIDTH(5)) char_buff(.clk(clk), .rst(rst), .wr(wr_buff), .rd(rd), .w_data(ascii_char), .empty(empty), .full(full), .r_data(ascii));      // character buffer after processing (32 bytes x 1 byte)

    ps2_dev_to_host ps2_module(.clk(clk), .rst(rst), .ps2_clk(ps2_clk), .ps2_data(ps2_data), .data(ps2_char), .rdy(rdy));          // PS/2 keyboard protocol handler
    ps2_to_ascii conversion_table(.char_in(ps2_char), .shift(case_shift), .ascii(ascii_char));

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            prev <= 8'b0;
            case_shift <= 1'b0;
        end
        else begin

            wr_buff <= 1'b0;    // do not write to buffer until valid new key is received

            if (rdy) begin      // new data received

                prev <= ps2_char;   // save data

                if (ps2_char == LEFT_SHIFT || ps2_char == RIGHT_SHIFT || ps2_char == CAPS_LOCK) begin       // if key results in a shift

                    if (prev == BREAK)      
                        case_shift <= 1'b0;     // clear shift if key was released
                    else
                        case_shift <= 1'b1;     // set shift is key was pressed
                end
                else begin

                    if (prev != BREAK && ps2_char != BREAK)      // if key was pressed or held down
                        wr_buff <= 1'b1;        // write converted PS/2 to ASCII character to buffer
                end
            end
        end
    end
    

endmodule