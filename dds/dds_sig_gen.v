
module dds_sig_gen #(
    
    parameter DAC_N = 10,
    parameter SIN_RES = 256
) (
    input clk,
    input rst,
    output [DAC_N-1:0] dac_out
);


    reg [15:0] quarter_sine_lut[SIN_RES-1:0];        // instantiate RAM block (256x16) for sine table

    initial
        $readmemh("sine.txt", quarter_sine_lut);    // read sine wave contents from file and store in RAM

    reg [31:0] phase_acc;         // 32 bit phase accumulator
    reg [31:0] phase_step;        // step size for accumulator
    wire [7:0] phase_angle;       // angle used for sine lut

    wire sine_sign;     // sine wave angle above/below middle threshold (between pi and 2pi)
    wire sine_axis;     // sine wave between pi/2 and pi or 3pi/2 and 2pi

    reg [DAC_N-1:0] dac_raw;      // raw value from lut

    always @(posedge clk) begin

        if (rst) begin
            phase_acc <= 32'b0;         // reset at beginning of sine wave
            phase_step <= 32'h100;      // step size is proportional to output frequency

            dac_raw <= 'b0;
        end
        else begin
            phase_acc <= phase_acc + phase_step;

            dac_raw <= quarter_sine_lut[phase_angle];
        end
    end

    assign sine_sign = phase_acc[31];
    assign sine_axis = phase_acc[30];

    assign phase_angle = sine_axis ? (8'hff - phase_acc[29:22]) : (phase_acc[29:22]);
    assign dac_out = sine_sign ? (10'h3ff - dac_raw) : (dac_raw);


endmodule