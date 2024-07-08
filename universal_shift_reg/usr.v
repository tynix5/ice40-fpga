module usr #(

    parameter WIDTH = 8

)(

    input clk,                      // clock
    input rst,                      // reset
    input ld,                       // load (parallel)
    input en,                       // output enable
    input ser_in,                   // serial input
    input [WIDTH-1:0] par_in,       // parallel input
    output ser_out,                 // serial output
    output [WIDTH-1:0] par_out      // parallel output
);

    reg [WIDTH-1:0] buff;           // shift register memory

    reg [WIDTH-1:0] par_out_buff;
    reg ser_out_reg;

    assign par_out = par_out_buff;
    assign ser_out = ser_out_reg;

    always @* begin

        par_out_buff = {WIDTH{1'bz}};            // high impedance by default

        if (en)
            par_out_buff = buff;         // transfer contents of buffer to output
    end

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            buff <= 'b0;
            ser_out_reg <= 1'b0;
        end
        else begin
            buff <= {buff[WIDTH-2:0], ser_in};      // shift data 1 bit every clock, load in serial input (by default)
            ser_out_reg <= buff[WIDTH-1];           // shift out last bit of data

            if (ld)                                 // if parallel load...
                buff <= par_in;                     // load parallel data
            
        end
    end



endmodule
