`timescale 1ns/10ps


module usr_tb();

    localparam DURATION = 10000;        // 10us
    localparam BITS = 8;
    integer i;

    reg clk = 0;
    reg rst = 0;
    reg ld = 0;
    reg en = 0;
    reg ser_in = 0;
    reg [7:0] par_in = 8'b0;
    wire ser_out;
    wire [7:0] par_out;

    usr #(.WIDTH(BITS)) universal_shift(.clk(clk), .rst(rst), .ld(ld), .en(en), .ser_in(ser_in), 
                                    .par_in(par_in), .ser_out(ser_out), .par_out(par_out));

    initial begin
        // Create simulation output file
        $dumpfile("usr_tb.vcd");
        $dumpvars(0,usr_tb);

        // Run for DURATION
        #(DURATION)

        // Simulation complete
        $display("Done");
        $finish;
    end


    initial begin

        #1
        rst = 1;
        #1
        rst = 0;
    end

    always begin

        #5
        /*****************************************************/
        /*load shift reg with all 1's then transfer to output*/
        /*****************************************************/
        ser_in = 1;
        en = 0;
        for (i = 0; i < BITS; i=i+1) begin
            #1
            clk = 1;
            #1
            clk = 0;
        end
        en = 1;
        /*****************************************************/
        /*****************************************************/
        /*****************************************************/

        /*****************************************************/
        /*******parallel load and transfer to output**********/
        /*****************************************************/
        #2
        ld = 1;
        par_in = 8'b0101_1100;
        clk = 1;
        #1
        clk = 0;
        #1
        ld = 0;
        en = 1;
        /*****************************************************/
        /*****************************************************/
        /*****************************************************/

        /*****************************************************/
        /*************Shift parallel data out*****************/
        /*****************************************************/
        ser_in = 0;
        for (i = 0; i < BITS; i=i+1) begin
            #1
            clk = 1;
            #1
            clk = 0;
        end
        en = 0;
        /*****************************************************/
        /*****************************************************/
        /*****************************************************/

    
    end


endmodule