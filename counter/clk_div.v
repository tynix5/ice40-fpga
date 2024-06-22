module clk_div #(

    // # of flip flops for clock division
    parameter   NUM_FF        = 20,

    // max count of flip flops before reset
    parameter   TOP           = 20

) (

    // Inputs
    input clk,
    input rst,

    // Outputs
    output reg sig
);

    reg [NUM_FF - 1: 0] count;              // registers for storing current count

    always @ (posedge clk or posedge rst) begin
        
        if (rst == 1'b1) begin
            count <= 0;                      // on rising edge of rst, reset counter
            sig <= 1'b0;                      // on rising edge of rst, reset signal
        end else if (count == TOP) begin
            count <= 0;                      // if counter reaches TOP, reset
            sig <= 1'b1;                     // if counter reaches max count, indicate output signal for one clock period
        end else begin
            count <= count + 1;              // else, on rising edge of clock, increment counter
            sig <= 1'b0;                     // if counter is not at max count, keep sig low
        end        
    end


endmodule