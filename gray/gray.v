module gray #(
    parameter MOD = 16
)(
    input clk,
    input rst,
    input en,
    output [$clog2(MOD)-1:0] bin_out,
    output [$clog2(MOD)-1:0] gray_out
);

    localparam GRAY_BITS = $clog2(MOD);         // number of bits needed to reach MOD

    reg [GRAY_BITS-1:0] bin_reg, bin_next, gray_reg, gray_next;

    assign bin_out = bin_reg;
    assign gray_out = gray_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // reset counters
            gray_reg <= {GRAY_BITS{1'b0}};
            bin_reg <= {GRAY_BITS{1'b0}};
        end
        else begin
            // update state
            bin_reg <= bin_next;
            gray_reg <= gray_next;
        end
    end

    always @(*) begin
        // default next state
        bin_next = bin_reg;
        gray_next = gray_reg;

        if (en) begin
            bin_next = bin_reg + 1'b1;      // increment binary counter
            gray_next = bin_next ^ (bin_next >> 1);     // increment gray counter
        end
    end


endmodule