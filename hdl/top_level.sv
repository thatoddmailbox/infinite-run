`default_nettype none

`include "data.sv"

module top_level(
    input wire clk_100mhz,

    // Switches
    input wire [15:0] sw,

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
    // Track draw
    //

    // obstacle: type, position, lane, active
    // ttpppppppppplla
    // [14:13] [12:3] [2:1] [0]
    obstacle obstacles [9:0] = '{
        15'b0,
        15'b0,
        15'b0,
        15'b0,
        15'b0,
        15'b0,
        15'b00_0111000000_00_1,
        15'b00_0000000000_01_1,
        15'b00_0000000000_00_1,
        15'b00_0001101000_10_1
    };
    wire [11:0] track_rgb;

    always_ff @(posedge clk_65mhz) begin
        if (vcount == 1 && hcount == 1) begin
            obstacles[2].position <= obstacles[2].position - sw[3:1];
        end
    end

    track_draw track_drawer(
        .system_clock_in(clk_65mhz),

        .hcount(hcount),
        .vcount(vcount),
        .hsync(hsync),
        .vsync(vsync),
        .blank(blank),

        .obstacles(obstacles),

        .rgb(track_rgb)
    );

    //
    // Camera timing and input buffering
    //
    // TODO: this might need to be moved into its own module?

    logic xclk;
    logic [1:0] xclk_count;
    assign xclk = (xclk_count > 2'b01);
    assign jbclk = xclk;

    logic pclk_buff, pclk_in;
    logic vsync_buff, vsync_in;
    logic href_buff, href_in;
    logic [7:0] pixel_buff, pixel_in;

    logic [15:0] pixel_data;
    logic pixel_valid;
    logic frame_done;

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
    end

    //
    // Camera frame read and processing
    //
    wire [9:0] frame_x_count;
    wire [8:0] frame_y_count;
    wire [1:0] lane;
    wire jump;
    wire [8:0] quadrants;
    wire vision_data_valid;

    wire [11:0] camera_debug_rgb;

    camera_read camera_reader(
        .pixel_clock_in(pclk_in),

        .vsync_in(vsync_in),
        .href_in(href_in),
        .pixel_data_in(pixel_in),

        .frame_x_count_out(frame_x_count),
        .frame_y_count_out(frame_y_count),
        .pixel_data_out(pixel_data),
        .pixel_valid_out(pixel_valid),
        .frame_done_out(frame_done)
    );

    vision_process process(
        .pixel_clock_in(pclk_in),

        .frame_x_count(frame_x_count),
        .frame_y_count(frame_y_count),
        .pixel_data(pixel_data),
        .pixel_valid(pixel_valid),

        .lane(lane),
        .jump(jump),
        .quadrants(quadrants),
        .data_valid(vision_data_valid)
    );

    camera_debug_draw debug_draw(
        .system_clock_in(clk_65mhz),

        .hcount(hcount),
        .vcount(vcount),
        .hsync(hsync),
        .vsync(vsync),
        .blank(blank),

        .rgb(camera_debug_rgb),

        .pixel_clock_in(pclk_in),

        .pixel_data(pixel_data),
        .pixel_valid(pixel_valid),
        .frame_done(frame_done),

        .lane(lane),
        .jump(jump),
        .quadrants(quadrants),
        .vision_data_valid(vision_data_valid)
    );

    //
    // VGA signal switching
    //

    wire b,hs,vs;
    assign hs = hsync;
    assign vs = vsync;
    assign b = blank;

    // TODO: this is where we would switch the vga circuit's input, based on the game FSM
    assign rgb = (sw[0] ? track_rgb : camera_debug_rgb);

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