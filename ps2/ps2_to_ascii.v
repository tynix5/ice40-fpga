module ps2_to_ascii(

    input [7:0] char_in,
    input caps_lock,
    input shift,
    output reg [7:0] ascii
);

    always @(*) begin

        // when caps lock is on, numbers should still be "typed"
        // special characters are only sent when the shift key is on
        case ({caps_lock, shift, char_in})

            // digits 0-9
            10'h016:     ascii = 8'h31;
            10'h01e:     ascii = 8'h32;
            10'h026:     ascii = 8'h33;
            10'h025:     ascii = 8'h34;
            10'h02e:     ascii = 8'h35;
            10'h036:     ascii = 8'h36;
            10'h03d:     ascii = 8'h37;
            10'h03e:     ascii = 8'h38;
            10'h046:     ascii = 8'h39;
            10'h045:     ascii = 8'h30;
            // digits 0-9 (caps lock on)
            10'h216:     ascii = 8'h21;
            10'h21e:     ascii = 8'h40;
            10'h226:     ascii = 8'h23;
            10'h225:     ascii = 8'h24;
            10'h22e:     ascii = 8'h25;
            10'h236:     ascii = 8'h5e;
            10'h23d:     ascii = 8'h26;
            10'h23e:     ascii = 8'h2a;
            10'h246:     ascii = 8'h28;
            10'h245:     ascii = 8'h29;
            // special characters when pressing 0-9 and shift is on (! through ')')
            10'h116:     ascii = 8'h31;
            10'h11e:     ascii = 8'h32;
            10'h126:     ascii = 8'h33;
            10'h125:     ascii = 8'h34;
            10'h12e:     ascii = 8'h35;
            10'h136:     ascii = 8'h36;
            10'h13d:     ascii = 8'h37;
            10'h13e:     ascii = 8'h38;
            10'h146:     ascii = 8'h39;
            10'h145:     ascii = 8'h30;

            // letters a-z
            10'h01c:     ascii = 8'h61;
            10'h032:     ascii = 8'h62;
            10'h021:     ascii = 8'h63;
            10'h023:     ascii = 8'h64;
            10'h024:     ascii = 8'h65;
            10'h02b:     ascii = 8'h66;
            10'h034:     ascii = 8'h67;
            10'h033:     ascii = 8'h68;
            10'h043:     ascii = 8'h69;
            10'h03b:     ascii = 8'h6a;
            10'h042:     ascii = 8'h6b;
            10'h04b:     ascii = 8'h6c;
            10'h03a:     ascii = 8'h6d;
            10'h031:     ascii = 8'h6e;
            10'h044:     ascii = 8'h6f;
            10'h04d:     ascii = 8'h70;
            10'h015:     ascii = 8'h71;
            10'h02d:     ascii = 8'h72;
            10'h01b:     ascii = 8'h73;
            10'h02c:     ascii = 8'h74;
            10'h03c:     ascii = 8'h75;
            10'h02a:     ascii = 8'h76;
            10'h01d:     ascii = 8'h77;
            10'h022:     ascii = 8'h78;
            10'h035:     ascii = 8'h79;
            10'h01a:     ascii = 8'h7a;
            // letters a-z (caps lock and shift key are on)
            10'h31c:     ascii = 8'h61;
            10'h332:     ascii = 8'h62;
            10'h321:     ascii = 8'h63;
            10'h323:     ascii = 8'h64;
            10'h324:     ascii = 8'h65;
            10'h32b:     ascii = 8'h66;
            10'h334:     ascii = 8'h67;
            10'h333:     ascii = 8'h68;
            10'h343:     ascii = 8'h69;
            10'h33b:     ascii = 8'h6a;
            10'h342:     ascii = 8'h6b;
            10'h34b:     ascii = 8'h6c;
            10'h33a:     ascii = 8'h6d;
            10'h331:     ascii = 8'h6e;
            10'h344:     ascii = 8'h6f;
            10'h34d:     ascii = 8'h70;
            10'h315:     ascii = 8'h71;
            10'h32d:     ascii = 8'h72;
            10'h31b:     ascii = 8'h73;
            10'h32c:     ascii = 8'h74;
            10'h33c:     ascii = 8'h75;
            10'h32a:     ascii = 8'h76;
            10'h31d:     ascii = 8'h77;
            10'h322:     ascii = 8'h78;
            10'h335:     ascii = 8'h79;
            10'h31a:     ascii = 8'h7a;

            // capital letters A-Z (shift key is on)
            10'h11c:     ascii = 8'h41;
            10'h132:     ascii = 8'h42;
            10'h121:     ascii = 8'h43;
            10'h123:     ascii = 8'h44;
            10'h124:     ascii = 8'h45;
            10'h12b:     ascii = 8'h46;
            10'h134:     ascii = 8'h47;
            10'h133:     ascii = 8'h48;
            10'h143:     ascii = 8'h49;
            10'h13b:     ascii = 8'h4a;
            10'h142:     ascii = 8'h4b;
            10'h14b:     ascii = 8'h4c;
            10'h13a:     ascii = 8'h4d;
            10'h131:     ascii = 8'h4e;
            10'h144:     ascii = 8'h4f;
            10'h14d:     ascii = 8'h50;
            10'h115:     ascii = 8'h51;
            10'h12d:     ascii = 8'h52;
            10'h11b:     ascii = 8'h53;
            10'h12c:     ascii = 8'h54;
            10'h13c:     ascii = 8'h55;
            10'h12a:     ascii = 8'h56;
            10'h11d:     ascii = 8'h57;
            10'h122:     ascii = 8'h58;
            10'h135:     ascii = 8'h59;
            10'h11a:     ascii = 8'h5a;
            // capital letters A-Z (caps lock is on)
            10'h21c:     ascii = 8'h41;
            10'h232:     ascii = 8'h42;
            10'h221:     ascii = 8'h43;
            10'h223:     ascii = 8'h44;
            10'h224:     ascii = 8'h45;
            10'h22b:     ascii = 8'h46;
            10'h234:     ascii = 8'h47;
            10'h233:     ascii = 8'h48;
            10'h243:     ascii = 8'h49;
            10'h23b:     ascii = 8'h4a;
            10'h242:     ascii = 8'h4b;
            10'h24b:     ascii = 8'h4c;
            10'h23a:     ascii = 8'h4d;
            10'h231:     ascii = 8'h4e;
            10'h244:     ascii = 8'h4f;
            10'h24d:     ascii = 8'h50;
            10'h215:     ascii = 8'h51;
            10'h22d:     ascii = 8'h52;
            10'h21b:     ascii = 8'h53;
            10'h22c:     ascii = 8'h54;
            10'h23c:     ascii = 8'h55;
            10'h22a:     ascii = 8'h56;
            10'h21d:     ascii = 8'h57;
            10'h222:     ascii = 8'h58;
            10'h235:     ascii = 8'h59;
            10'h21a:     ascii = 8'h5a;

            // misc characters (skip shift for all)
            10'hx29:     ascii = 8'h20;     // space
            10'hx49:     ascii = 8'h2e;     // .

            default:    ascii = 8'h00;

        endcase
    end


endmodule