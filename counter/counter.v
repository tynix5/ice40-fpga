
module counter (

    // Inputs
    input clk,
    input rst,

    // Outputs
    output reg [3:0] led
);


    wire out;


    // 100 MHz clock * 12500000 cycles = 1/8 s
    // log base 2 (12500000) = 24 flip flops needed
    clk_div #(.NUM_FF(25), .TOP(12499999)) div (

        .clk(clk),
        .rst(rst),

        .sig(out)
    );


    always @ (posedge clk) begin

        case (rst)
            0:
                if (out == 1'b1) begin
                    led <= led + 4'b1;          // increment LEDs after counter overflows
                end
            1:
                led <= 4'b0;                    // turn off LEDs on reset
        endcase
        
    end


endmodule