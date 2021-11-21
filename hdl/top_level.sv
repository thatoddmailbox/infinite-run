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

    //
    // VGA timing
    //

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

    //
    // Camera timing
    //
    // TODO: probably this needs to be moved into its own module

    logic xclk;
    logic [1:0] xclk_count;
    assign xclk = (xclk_count > 2'b01);
    assign jbclk = xclk;

    //
    // Camera frame read
    //
    // TODO: this def needs to be moved into its own module

    logic pclk_buff, pclk_in;
    logic vsync_buff, vsync_in;
    logic href_buff, href_in;
    logic [7:0] pixel_buff, pixel_in;
    logic [15:0] output_pixels;
    logic [11:0] processed_pixels;
    logic valid_pixel;
    logic frame_done_out;

    logic [16:0] pixel_addr_in;
    logic [16:0] pixel_addr_out;

    logic [11:0] cam;
    logic [11:0] frame_buff_out;

    always_ff @(posedge pclk_in) begin
        if (frame_done_out) begin
            pixel_addr_in <= 17'b0;
        end else if (valid_pixel) begin
            pixel_addr_in <= pixel_addr_in + 1;
        end
    end

    always_ff @(posedge clk_65mhz) begin
        xclk_count <= xclk_count + 2'b01;

        pclk_buff <= jb[0];
        vsync_buff <= jb[1];
        href_buff <= jb[2];
        pixel_buff <= ja;

        pclk_in <= pclk_buff;
        vsync_in <= vsync_buff;
        href_in <= href_buff;
        pixel_in <= pixel_buff;

        processed_pixels = {output_pixels[15:12], output_pixels[10:7], output_pixels[4:1]};
    end

    blk_mem_camera_frame framebuffer(
        .addra(pixel_addr_in),
        .clka(pclk_in),
        .dina(processed_pixels),
        .wea(valid_pixel),

        .addrb(pixel_addr_out),
        .clkb(clk_65mhz),
        .doutb(frame_buff_out)
    );

    camera_read camera_reader(
        .pixel_clock_in(pclk_in),

        .vsync_in(vsync_in),
        .href_in(href_in),
        .pixel_data_in(pixel_in),

        .pixel_data_out(output_pixels),
        .pixel_valid_out(valid_pixel),
        .frame_done_out(frame_done_out)
    );

    assign pixel_addr_out = hcount+vcount*32'd320;
    assign cam = ((hcount<320) && (vcount<240)) ? frame_buff_out : 12'hFFF;

    //
    // VGA signal switching
    //

    reg b,hs,vs;
    always_ff @(posedge clk_65mhz) begin
        // TODO: this is where we would switch the vga circuit's input, based on the game FSM
        hs <= hsync;
        vs <= vsync;
        b <= blank;
        rgb <= cam;
//       rgb <= 12'hFFF;
    end

    //
    // VGA wiring
    //

    assign vga_r = ~b ? rgb[11:8]: 0;
    assign vga_g = ~b ? rgb[7:4] : 0;
    assign vga_b = ~b ? rgb[3:0] : 0;

    assign vga_hs = ~hs;
    assign vga_vs = ~vs;

endmodule

`default_nettype wire