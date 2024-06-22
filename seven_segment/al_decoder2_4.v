
module al_decoder2_4 (

    input       [1:0]     in,

    output reg  [3:0]     z
);


always @(*) begin

    /* select lines on seven segment are active low */
    case (in)
        2'b00:      z <= ~4'b0001;
        2'b01:      z <= ~4'b0010;
        2'b10:      z <= ~4'b0100;
        2'b11:      z <= ~4'b1000;
        default:    z <= ~4'b0000;
    endcase
end

endmodule