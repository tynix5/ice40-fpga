`timescale 1ns/1ps

module button_tb();

reg switch;
wire out;

button test(.switch(switch), .led(out));


initial
 begin
    $dumpfile("button_tb.vcd");
    $dumpvars(0,button_tb);
    #50
    $display("Done.");
    $finish;
 end


always begin

    #5
    $display("tick %d: Switch State: %b ... LED State: %b", $time, switch, out);
end

always begin

    switch = 0;
    #10
    switch = 1;
    #10
    switch = 0;
end



endmodule