module ps2_dev_to_host(

    input clk,
    input rst,
    input ps2_clk,
    input ps2_data,
    output [7:0] data,
    output ready
);

    localparam F_CLK = 100_000_000;
    localparam SAMPLE_TIME_US = 20;
    localparam SAMPLE_CNT = SAMPLE_TIME_US * 100;   // sample data line 20us after falling edge
    localparam TIMEOUT_US = 100;                    // clock high/low max period
    localparam TIMEOUT_CNT = TIMEOUT_US * 100;

    localparam PACKET_LEN = 11;             // 1 start, 8 data, 1 parity, 1 stop
    localparam PACKET_N = $clog2(PACKET_LEN);

    reg [PACKET_N-1:0] bit_cnt;         // number of bits sampled
    reg [PACKET_LEN-1:0] packet;        // raw data from PS/2
    reg [7:0] data_reg;                 // data bits from raw packet
    reg ready_reg;                      // data ready


    reg sample_tim_en, timeout_rst;
    wire sample, timeout;
    mod #(.MOD(SAMPLE_CNT)) sample_mod(.clk(clk), .rst(rst), .cen(sample_tim_en), .q(), .sync_ovf(sample));
    mod #(.MOD(TIMEOUT_CNT)) timeout_mod(.clk(clk), .rst(timeout_rst), .cen(1'b1), .q(), .sync_ovf(timeout));
    

    wire ps2_data_sync;
    wire ps2_clk_rising_edge, ps2_clk_falling_edge;

    synchronizer #(.SYNC_STAGES(2)) ps2_clk_synch(
        .clk(clk), 
        .rst(rst), 
        .async_in(ps2_clk), 
        .rise_edge_tick(ps2_clk_rising_edge), 
        .fall_edge_tick(ps2_clk_falling_edge), 
        .sync_out());

    synchronizer #(.SYNC_STAGES(2)) ps2_data_synch(
        .clk(clk), 
        .rst(rst), 
        .async_in(ps2_data), 
        .rise_edge_tick(), 
        .fall_edge_tick(), 
        .sync_out(ps2_data_sync));

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            timeout_rst <= 1'b1;
        end
        else begin

            if (ps2_clk_falling_edge | ps2_clk_rising_edge)     // on clock edge, reset watchdog
                timeout_rst <= 1'b1;
            else                                                // count clock high/low period
                timeout_rst <= 1'b0;

            if (timeout)                                        // if timeout, disable watchdog until next edge
                timeout_rst <= 1'b1;
        end
    end

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            sample_tim_en <= 1'b0;
        end
        else begin

            if (ps2_clk_falling_edge)       // on falling edge, count ticks until sample time
                sample_tim_en <= 1'b1;
            
            if (sample)                     // disable tick counter when sample time is reached
                sample_tim_en <= 1'b0;
        end
    end

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            bit_cnt <= {PACKET_N{1'b0}};
            packet <= {PACKET_LEN{1'b0}};
            data_reg <= 8'b0;
            ready_reg <= 1'b0;
        end
        else begin
            
            ready_reg <= 1'b0;

            if (sample) begin

                packet[bit_cnt] <= ps2_data_sync;       // sample data line
                bit_cnt <= bit_cnt + 'b1;               // move to next bit
            end

            if (timeout) begin                          // on timeout, reset bit counter and packet data

                bit_cnt <= {PACKET_N{1'b0}};
                packet <= {PACKET_LEN{1'b0}};
            end

            // if end of PS/2 transaction
            if (ps2_clk_rising_edge && bit_cnt == PACKET_LEN) begin

                bit_cnt <= {PACKET_N{1'b0}};        // reset bit counter
                packet <= {PACKET_LEN{1'b0}};
                
                // check for 0 start bit, 1 start bit, and odd parity
                if (packet[0] == 1'b0 && packet[PACKET_LEN-1] == 1 && ^packet[PACKET_LEN-2:0]) begin
                    data_reg <= packet[8:1];            // extract data from packet
                    ready_reg <= 1'b1;                  // signal ready
                end
            end
        end
    end

    assign data = data_reg;
    assign ready = ready_reg;

endmodule
