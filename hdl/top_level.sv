`default_nettype none

`include "data.sv"

module top_level(
    input wire clk_100mhz,
    input wire btnc,

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
    
    logic reset;
    debounce db(.reset_in(reset),.clock_in(clk_65mhz),.noisy_in(btnc),.clean_out(reset));

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
    // [15:14] [13:3] [2:1] [0]
    obstacle obstacles [9:0];
    wire [11:0] track_rgb;

    always_ff @(posedge clk_65mhz) begin
//        if (vcount == 1 && hcount == 1) begin
//            if (obstacles[2].position <= sw[3:1]) begin
//                // reset
//                obstacles[2].position <= 10'd1023;
//            end else begin
//                // normal
//                obstacles[2].position <= obstacles[2].position - sw[3:1];
//            end
//        end
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
    
    wire reset_game;
    wire playing;
    wire game_over;
    wire [11:0] time_alive;
    wire pulse;
    wire timer_expired;
    wire timer_start;
    wire [3:0] time_to_wait;
    wire [1:0] lane2;
    wire jump2;
    wire [1:0] lane3;
    wire jump3;
    wire died;
    assign died = 0;
    
    timer timer(
        .clk_in(clk_65mhz),
        .rst_in(reset),
        .start_in(timer_start),
        .value_in(time_to_wait),
        .expired_out(timer_expired),
        .pulse_100ms_out(pulse));

    gamefsm gamefsm(
        .clk_in(clk_65mhz),
        .rst_in(reset),
        .pulse(pulse),
        .died(died),
        .lane(lane),
        .jump(jump),
        .playing(playing),
        .game_over(game_over),
        .time_alive(time_alive),
        .reset_game(reset_game),
        .lane_out(lane2),
        .jump_out(jump2));

    wire [3:0] random_num;
    randomizer randomizer(
        .clk_in(clk_65mhz),
        .rst_in(reset),
        .value(random_num));

    wire [3:0] random_num2;
    randomizer randomizer2(
        .clk_in(clk_65mhz),
        .rst_in(reset),
        .value(random_num2));

    obstacle_generator obstacle_generator(
        .clk_in(clk_65mhz),
        .rst_in(reset),
        .game_reset(reset_game),
        .jump_in(jump2),
        .lane_in(lane2),
        .time_alive(time_alive),
        .random_num(random_num),
        .random_lane(random_num2[3:2]),
        .random_sprite(random_num2[1:0]),
        .expired_in(timer_expired),
        .obstacles_out(obstacles),
        .player_lane(lane3),
        .player_jump(jump3),
        .start_timer(timer_start),
        .time_to_wait(time_to_wait));

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