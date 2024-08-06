module async_fifo #(
    parameter DATA_WIDTH = 8,           // width in bits of FIFO
    parameter ADDR_WIDTH = 16           // # of FIFO cells
)(
    input wrst,                         // write reset
    input wclk,                         // transmit clock
    input wen,                          // write enable
    input rrst,                         // read reset
    input rclk,                         // receiver clock 
    input ren,                          // read enable
    output full,                        // full status
    output empty,                       // empty status
    output almost_full,                 // almost full status
    output almost_empty,                // almost empty status
    input [DATA_WIDTH-1:0] wdata,       // write data
    output reg [DATA_WIDTH-1:0] rdata   // read data
);

    localparam ADDR_BITS = $clog2(ADDR_WIDTH);       // # of bits needed for address

    reg wcnt_en, rcnt_en;     // counter enables
    reg full_reg, empty_reg;
 
    wire [ADDR_BITS-1:0] bin_wptr, bin_rptr;         // binary read and write pointers (relative to their clock domain)
    wire [ADDR_BITS-1:0] gray_wptr, gray_rptr;       // gray code read and write pointers (relative to their clock domain)
    reg [ADDR_BITS-1:0] cdc_wptr, cdc_rptr;          // synchronized gray code read and write pointers (clock domain crossed)

    
    reg [ADDR_WIDTH-1:0] queue[DATA_WIDTH-1:0];     // FIFO buffer

    // synchronize read pointer for writing clock domain
    pipeline #(.SYNC_STAGES(2), .DATA_WIDTH(ADDR_BITS)) synchronizer_rptr(.clk(wclk), .rst(wrst), .async_in(gray_rptr), .sync_out(cdc_rptr));
    // synchronize write pointer for reading clock domain
    pipeline #(.SYNC_STAGES(2), .DATA_WIDTH(ADDR_BITS)) synchronizer_wptr(.clk(rclk), .rst(rrst), .async_in(gray_wptr), .sync_out(cdc_wptr));

    gray #(.MOD(ADDR_WIDTH)) ptr_write(.clk(wclk), .rst(wrst), .en(wcnt_en), .bin_out(bin_wptr), .gray_out(gray_wptr));
    gray #(.MOD(ADDR_WIDTH)) ptr_read(.clk(rclk), .rst(rrst), .en(rcnt_en), .bin_out(bin_rptr), .gray_out(gray_rptr));


    assign full = full_reg;
    assign empty = empty_reg;

    integer i;

    always @(posedge wclk) begin
        if (wrst) begin
            wcnt_en <= 1'b0;
        end
        else begin
            if (wen && ~full_reg) begin
                queue[bin_wptr] <= wdata;
                wcnt_en <= 1'b1;
                // empty_reg <= 1'b0;

                // if (gray_wptr + 1'b1 == cdc_rptr)
                //     full_reg <= 1'b1;
                // else
                //     full_reg <= 1'b0;
            end
        end    
    end

    always @(posedge rclk) begin
        if (rrst) begin
            rcnt_en <= 1'b0;
            rdata <= {DATA_WIDTH{1'b0}};
        end
        else begin
            if (ren && ~empty_reg) begin
                rdata <= queue[bin_rptr];
                rcnt_en <= 1'b1;
                // full_reg <= 1'b0;

                // if (rptr + 1'b1 == cdc_wptr)
                //     empty_reg <= 1'b1;
                // else
                //     empty_reg <= 1'b0;
            end
        end
    end

endmodule