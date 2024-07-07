module encoder(

    input [3:0] in,
    output [1:0] out
);

    reg [1:0] out_reg;
    assign out = out_reg;
    // 4 to 2 line priority encoder logic
    always @* begin
        casex (in)
            4'b1???:    out_reg = 2'b11;
            4'b01??:    out_reg = 2'b10;
            4'b001?:    out_reg = 2'b01;
            default:    out_reg = 2'b00;
        endcase
    end

endmodule