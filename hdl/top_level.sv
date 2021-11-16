`default_nettype none

module top_level(
    input wire clk_100mhz,

    // Camera signals
    input wire [7:0] ja, // pixel data from camera
    input wire [2:0] jb, // other data from camera
    output wire jbclk, // camera clock, driven by FPGA

    // VGA output
    output logic [3:0] vga_r,
    output logic [3:0] vga_g,
    output logic [3:0] vga_b,
    output logic vga_hs,
    output logic vga_vs
);

    logic clk_65mhz;
    clk_wiz_65mhz divider(.clk_in1(clk_100mhz), .clk_out1(clk_65mhz));

    wire [10:0] hcount;
    wire [9:0] vcount;
    wire hsync, vsync, blank;
    wire [11:0] pixel;
    reg [11:0] rgb;
    xvga vga_timing(
        .vclock_in(clk_65mhz),
        .hcount_out(hcount),
        .vcount_out(vcount),
        .hsync_out(hsync),
        .vsync_out(vsync),
        .blank_out(blank)
    );

    reg b,hs,vs;
    always_ff @(posedge clk_65mhz) begin
        // TODO: this is where we would switch the vga circuit's input, based on the game FSM
        hs <= hsync;
        vs <= vsync;
        b <= blank;
        // rgb <= cam;
        rgb <= 12'hFFF;
    end

    assign vga_r = ~b ? rgb[11:8]: 0;
    assign vga_g = ~b ? rgb[7:4] : 0;
    assign vga_b = ~b ? rgb[3:0] : 0;

    assign vga_hs = ~hs;
    assign vga_vs = ~vs;

endmodule

`default_nettype wire