module ps2_to_ascii(

    input [7:0] char_in,
    input shift,
    output [7:0] ascii
);

    always @(*) begin

        case ({shift, char_in})

            // digits 0-9
            9'h016:     ascii = 8'h31;
            9'h01e:     ascii = 8'h32;
            9'h026:     ascii = 8'h33;
            9'h025:     ascii = 8'h34;
            9'h02e:     ascii = 8'h35;
            9'h036:     ascii = 8'h36;
            9'h03d:     ascii = 8'h37;
            9'h03e:     ascii = 8'h38;
            9'h046:     ascii = 8'h39;
            9'h045:     ascii = 8'h30;
            // letters a-z
            // special characters !-)
            // capital letters A-Z

            default:    ascii = 8'h00;

        endcase
    end


endmodule