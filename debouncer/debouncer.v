module debouncer (

    input clk,              // clock
    input rst,              // reset
    input btn,              // button
    output press            // debounced button
);

    wire btn_sync;  // synchronous button output
    wire db_ovf;    // debounce timer overflow
    reg tim_en;     // debounce timer enable
    reg press_reg;  // button tick

    synchronizer #(.SYNC_STAGES(2)) btn_synchronizer(.clk(clk), .rst(rst), .async_in(btn), .sync_out(btn_sync)); // synchronize input for cdc reasons
    mod #(.MOD(10)) db_tim(.clk(clk), .rst(rst), .cen(tim_en), .q(), .sync_ovf(db_ovf));                        // 10 clock cycles for debouncing


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tim_en <= 1'b0;             // disable timer
            press_reg <= 1'b0;          // button not pressed initially
        end
        else begin
            
            press_reg <= 1'b0;          // clear press tick

            if (btn_sync && ~tim_en) begin      // if new press and button is high...
                tim_en <= 1'b1;                 // start timer
                press_reg <= 1'b1;              // one clock tick on press output
            end

            if (db_ovf)                 // if timer is about to overflow...
                tim_en <= 1'b0;         // disable timer when it overflows

        end
    end

    assign press = press_reg;

endmodule