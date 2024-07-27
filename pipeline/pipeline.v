module pipeline #(
    parameter SYNC_STAGES = 2,
    parameter DATA_WIDTH = 4
)(

    input clk,
    input rst,
    input [DATA_WIDTH-1:0] async_in,        // asynchronous input
    output reg [DATA_WIDTH-1:0] sync_out    // synchronous output
);

    reg [SYNC_STAGES-1:0] pipe[DATA_WIDTH-1:0];

    integer i;

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            sync_out <= 1'b0;
            for (i=0; i<SYNC_STAGES; i=i+1)     // empty pipeline
                pipe[i] <= {DATA_WIDTH{1'b0}}; 
        end
        else begin
            pipe[SYNC_STAGES-1] <= async_in;    // shift asynchronous data into beginning of pipeline
            for (i=SYNC_STAGES-1; i>0; i=i-1)   // shift data down pipeline
                pipe[i-1] <= pipe[i];
            sync_out <= pipe[0];                // pipe out synchronized data
        end
    end

endmodule