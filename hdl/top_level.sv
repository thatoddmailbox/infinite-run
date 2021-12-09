`default_nettype none

`include "data.sv"

module top_level(
    input wire clk_100mhz,
    input wire btnc,

    // Switches
    input wire [15:0] sw,

    // LEDs
    output wire [3:0] led,
    output wire ca, cb, cc, cd, ce, cf, cg,
    output wire [7:0] an,

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

    wire reset = btnc;
//    logic reset;
//    debounce db(.reset_in(reset),.clock_in(clk_65mhz),.noisy_in(btnc),.clean_out(reset));

    //
    // VGA timing
    //

    wire [10:0] hcount;
    wire [9:0] vcount;
    wire hsync, vsync, blank;
    wire [11:0] pixel;
    reg [11:0] rgb;
    wire frame_trigger = (hcount == 1 && vcount == 1);
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

//    always_ff @(posedge clk_65mhz) begin
//        if (vcount == 1 && hcount == 1) begin
//            if (obstacles[2].position <= sw[3:1]) begin
//                // reset
//                obstacles[2].position <= 10'd1023;
//            end else begin
//                // normal
//                obstacles[2].position <= obstacles[2].position - sw[3:1];
//            end
//        end
//    end

    track_draw track_drawer(
        .system_clock_in(clk_65mhz),

        .hcount(hcount),
        .vcount(vcount),
        .hsync(hsync),
        .vsync(vsync),
        .blank(blank),

        .obstacles(obstacles),
        .lives(lives),

        .lane(lane),
        .jump(jump),

        .rgb(track_rgb)
    );

    wire [11:0] start_rgb;
    wire [11:0] death_rgb;
    screen_draw #(.WIDTH(240), .HEIGHT(256))
        screen_drawer(.system_clock_in(clk_65mhz),
        .hcount(hcount),
        .vcount(vcount),
        .hsync(hsync),
        .vsync(vsync),
        .blank(blank),
        .rgb(start_rgb));
        
    gameover_draw #(.WIDTH(80), .HEIGHT(256))
        gameover_drawer(.system_clock_in(clk_65mhz),
        .hcount(hcount),
        .vcount(vcount),
        .hsync(hsync),
        .vsync(vsync),
        .blank(blank),
        .rgb(death_rgb));
    //
    // Game logic
    //
    wire died;
    wire got_powerup;
    death d(
        .system_clock_in(clk_65mhz),
        .reset(reset_game),

        .obstacles(obstacles),
        .lane(lane),
        .jump(jump),

        .died(died),
        .got_powerup(got_powerup)
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
    wire [1:0] lane_raw;
    wire jump_raw;
    wire [1:0] lane_raw_synced;
    wire jump_raw_synced;
    wire [1:0] lane;
    wire jump;
    wire [8:0] quadrants_raw;
    wire [8:0] quadrants;
    wire vision_data_valid_raw;

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

        .lane(lane_raw),
        .jump(jump_raw),
        .quadrants(quadrants_raw),
        .data_valid(vision_data_valid_raw)
    );

    vision_debouncer vision_debounce(
        .system_clock_in(clk_65mhz),
        .system_reset(reset),

        .pixel_clock_in(pclk_in),
        .lane_raw(lane_raw),
        .jump_raw(jump_raw),
        .quadrants_raw(quadrants_raw),
        .vision_data_valid_raw(vision_data_valid_raw),

        .lane_raw_synced(lane_raw_synced),
        .jump_raw_synced(jump_raw_synced),

        .lane(lane),
        .jump(jump),
        .quadrants(quadrants)
    );

    camera_debug_draw debug_draw(
        .system_clock_in(clk_65mhz),

        .hcount(hcount),
        .vcount(vcount),
        .hsync(hsync),
        .vsync(vsync),
        .blank(blank),

        .show_outline(sw[1]),

        .rgb(camera_debug_rgb),

        .pixel_clock_in(pclk_in),

        .pixel_data(pixel_data),
        .pixel_valid(pixel_valid),
        .frame_done(frame_done),

        .lane((sw[2] ? lane : lane_raw_synced)),
        .jump((sw[2] ? jump : jump_raw_synced)),
        .quadrants(quadrants),
        .vision_data_valid(1'b1)
    );
    
    wire reset_game;
    wire playing;
    wire game_over;
    wire [11:0] time_alive;
    wire pulse;
    wire timer_expired;
    wire timer_start;
    wire [5:0] time_to_wait;
    wire [3:0] lives;

    assign led[3] = reset_game;
    assign led[2] = game_over;
    assign led[1] = playing;
    assign led[0] = pulse;
//    wire died = 0;
    
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
        .jump(jump_raw_synced),
        .playing(playing),
        .game_over(game_over),
        .time_alive(time_alive),
        .reset_game(reset_game),
        .num_lives(lives),
        .got_powerup(got_powerup)
    );

    game_timer t(
        .system_clock_in(clk_65mhz),
        .reset_game(reset_game),
        .playing(playing),

        .ca(ca),
        .cb(cb),
        .cc(cc),
        .cd(cd),
        .ce(ce),
        .cf(cf),
        .cg(cg),
        .an_out(an)
    );

    wire [7:0] random_num;
    randomizer randomizer(
        .clk_in(clk_65mhz),
        .rst_in(reset),
        .value(random_num));

    wire [7:0] random_num2;
    randomizer randomizer2(
        .clk_in(clk_65mhz),
        .rst_in(reset),
        .value(random_num2));

    stuff_ila ila(
        .clk(clk_65mhz),
        .probe0(reset),
        .probe1(random_num),
        .probe2(random_num2)
    );

    obstacle_generator obstacle_generator(
        .clk_in(clk_65mhz),
        .rst_in(reset),
        .game_reset(reset_game),
        .frame_trigger(frame_trigger),
        .time_alive(time_alive),
        .random_num(random_num[3:0]),
        .random_lane(random_num2[3:2]),
        .random_sprite(random_num2[1:0]),
        .expired_in(timer_expired),
        .obstacles_out(obstacles),
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
    assign rgb = (sw[0] ? camera_debug_rgb : (reset_game ? start_rgb : (game_over ? death_rgb : track_rgb)));

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