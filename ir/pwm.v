module pwm #(

    parameter FREQ = 10,
    parameter DUTY = 50
)(
    input clk,
    input rst,
    input en,
    output wave
);

    localparam F_CLK = 100_000_000;
    localparam PERIOD_CYCLES = F_CLK / FREQ;
    localparam DUTY_CYCLES = PERIOD_CYCLES * DUTY / 100;

    localparam CNT_W = $clog2(PERIOD_CYCLES);
    
    reg wave_reg;
    reg [CNT_W-1:0] tim;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tim <= {CNT_W{1'b0}};
            wave_reg <= 1'b1;
        end
        else begin

            wave_reg <= wave_reg;
            tim <= tim + 'b1;

            if (tim == DUTY_CYCLES - 1) begin
                wave_reg <= 1'b0;
            end
            else if (tim == PERIOD_CYCLES - 1) begin
                tim <= {CNT_W{1'b0}};
                wave_reg <= 1'b1;
            end
        end
    end

    assign wave = (en) ? wave_reg : 1'b0;

endmodule