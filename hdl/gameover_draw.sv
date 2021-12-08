`default_nettype none

module gameover_draw
    #(parameter WIDTH = 80,     // default picture width
                HEIGHT = 256)    // default picture height(
    (input wire system_clock_in,
    input wire [10:0] hcount,
    input wire [9:0] vcount,
    input wire hsync,
    input wire vsync,
    input wire blank,
    output logic [11:0] rgb
);

   logic [14:0] image_addr;   // num of bits for 256*80 ROM
   logic [7:0] image_bits, red_mapped, green_mapped, blue_mapped;

   // calculate rom address and read the location
   assign image_addr = (hcount) + (vcount-HEIGHT) * WIDTH;
   death_screen img_rom(.clka(system_clock_in), .addra(image_addr), .douta(image_bits));

   // use color map to create 4 bits R, 4 bits G, 4 bits B
   // since the image is greyscale, just replicate the red pixels
   // and not bother with the other two color maps.
   colormap_death_rom rcm (.clka(system_clock_in), .addra(image_bits), .douta(red_mapped));
   // note the one clock cycle delay in pixel!
   always_ff @ (posedge system_clock_in) begin
     if ((hcount >= 0 && hcount < WIDTH) &&
          (vcount >= HEIGHT && vcount < (HEIGHT+HEIGHT)))
        // use MSB 4 bits
        rgb <= {red_mapped[7:4], red_mapped[7:4], red_mapped[7:4]}; // greyscale
        //pixel_out <= {red_mapped[7:4], 8h'0}; // only red hues
        else rgb <= 12'hF00;
   end

endmodule

`default_nettype wire
