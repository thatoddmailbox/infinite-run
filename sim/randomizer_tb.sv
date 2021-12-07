`timescale 1ns / 1ps

module randomizer_tb;
    // Inputs
    logic clock;
    logic reset;
    // Outputs
    logic [3:0] out;
    
    randomizer uut(.clk_in(clock), .rst_in(reset), .value(out));
    
    always #5 clock = !clock;
    
    initial begin
        clock = 0;
        reset = 1;
        #10;
        reset = 0;
        #15;
    end
endmodule
