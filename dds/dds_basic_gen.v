module dds_basic_gen(

    input clk,
    input rst,
    output [9:0] dac_out_tri,
    output [9:0] dac_out_saw,
    output [9:0] dac_out_square
);

    reg [15:0] phase_acc;
    reg [4:0] phase_step;

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            phase_acc <= 16'b0;
            phase_step <= 5'b1;
        end
        else begin

            phase_acc <= phase_acc + phase_step;

        end
    end

assign dac_out_tri = phase_acc[15] ? ~phase_acc[14:5] : phase_acc[14:5];
assign dac_out_saw = phase_acc[14:5];
assign dac_out_square = {10{phase_acc[15]}};

endmodule