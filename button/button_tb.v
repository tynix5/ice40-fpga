module button_tb();

wire SWITCH;
wire LED;

button test(.switch(SWITCH), .led(LED));


initial
 begin
    $dumpfile("button_tb.vcd");
    $dumpvars(0,button_tb);
 end


initial begin

    $display("Switch State: %b ... LED State: %b", SWITCH, LED);

end

always begin

    LED = SWITCH;
    #10
end



endmodule