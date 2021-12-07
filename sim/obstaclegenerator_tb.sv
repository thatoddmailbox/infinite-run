`timescale 1ns / 1ps

module obstaclegenerator_tb;
    // Inputs
    logic clock;
    logic reset;
    logic jump;
    logic [1:0] lane;
    logic [11:0] time_alive;
    logic [3:0] rand_num;
    logic [1:0] rand_lane;
    logic [1:0] rand_sprite;
    logic expired;
    // Outputs
    logic [149:0] obstacles;
    logic [1:0] player_lane;
    logic player_jump;
    logic start_timer;
    logic [3:0] time_to_wait;
    
    obstacle_generator uut(
.clk_in(clock),
        .rst_in(reset),
        .jump_in(jump),
        .lane_in(lane),
        .time_alive(time_alive),
        .random_num(rand_num),
        .random_lane(rand_lane),
        .random_sprite(rand_sprite),
        .expired_in(expired),
        .obstacles_out(obstacles),
        .player_lane(player_lane),
        .player_jump(player_jump),
        .start_timer(start_timer),
        .time_to_wait(time_to_wait)
    );
    
    always #5 clock = !clock;
    
    initial begin
        clock = 0;
        rand_num = 4'b1100;
        rand_lane = 2'b10;
        rand_sprite = 2'b0;
        expired = 0;
        jump = 0;
        lane = 2'b0;
        reset = 1;
        #10;
        reset = 0;
        #15;
        time_alive = 400;
        #20;
        expired = 1;
        #10;
        expired = 0;
        #200;
        time_alive = 800;
        #20;
        expired = 1;
        #10;
        expired = 0;
    end
endmodule
