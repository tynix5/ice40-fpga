
module segments (

    input       [3:0]   in,

    output reg  [7:0]   segs
);


always @(*) begin

    case (in)
        0:          segs <= ~8'b0111111;
        1:          segs <= ~8'b0000110;
        2:          segs <= ~8'b1011011;
        3:          segs <= ~8'b1001111;
        4:          segs <= ~8'b1100110;
        5:          segs <= ~8'b1101101;
        6:          segs <= ~8'b1111101;
        7:          segs <= ~8'b0000111;
        8:          segs <= ~8'b1111111;
        9:          segs <= ~8'b1100111;
        default:    segs <= ~8'b00000000;
    endcase
end


endmodule