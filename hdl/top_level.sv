module top_level(
    input clk_100mhz,

    // Camera signals
    input [7:0] ja, // pixel data from camera
    input [2:0] jb, // other data from camera
    output jbclk, // camera clock, driven by FPGA

    // VGA output
    output[3:0] vga_r,
    output[3:0] vga_g,
    output[3:0] vga_b,
    output vga_hs,
    output vga_vs
);



endmodule