
module mod_counter #(

    parameter   MOD         = 10
) (

    input       clk,
    input       rst,


    output reg [$clog2(MOD)-1:0] cnt,
    output reg                 ovf
);

always @ (posedge clk or posedge rst) begin

    if (rst == 1'b1) begin
        cnt <= 0;
        ovf <= 0;
    end else if (cnt == MOD - 1) begin
        cnt <= 0;
        ovf <= 1;
    end else begin
        cnt <= cnt + 1;
        ovf <= 0;
    end
end

endmodule