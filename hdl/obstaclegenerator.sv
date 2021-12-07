`default_nettype none
`include "data.sv"

module obstacle_generator(
    input wire clk_in,
    input wire rst_in,
    input wire jump_in,
    input wire game_reset,
    input wire [1:0] lane_in,
    input wire [11:0] time_alive,
    input wire [3:0] random_num,
    input wire [1:0] random_lane,
    input wire [1:0] random_sprite,
    input wire expired_in,
    output obstacle obstacles_out [9:0],    // do i need logic here?
    output logic [1:0] player_lane,
    output logic player_jump,
    output logic start_timer,
    output logic [3:0] time_to_wait
    );

    logic [3:0] curr_active;
    logic [3:0] should_be_active;
    logic is_counting;
    // The two following indices keep track of what interval the active obstacles are in in the obstacles_out array.
    logic [3:0] start_index;
    logic [3:0] end_index;
    logic [2:0] speed;

    // just passing player position on
    assign player_jump = jump_in;
    assign player_lane = lane_in;
    
    always_ff @(posedge clk_in) begin
        if (rst_in || game_reset) begin
            obstacles_out <= '{
                16'b0,
                16'b0,
                16'b0,
                16'b0,
                16'b0,
                16'b0,
                16'b00_00111000000_00_1,
                16'b00_00000000000_01_1,
                16'b00_00000000000_00_1,
                16'b00_00001101000_10_1
            };
            curr_active <= 0;
            should_be_active <= 0;
            is_counting <= 0;
            start_index <= 0;
            end_index <= 0;
            speed <= 3'b1;
        end else begin
            if (time_alive >= 300) begin
                should_be_active <= 4'd1;
                speed <= 3'd2;
            end
            if (time_alive >= 600) begin
                should_be_active <= 4'd2;
                speed <= 3'd3;
            end
            if (time_alive >= 1200) begin
                should_be_active <= 4'd3;
                speed <= 3'd4;
            end
            if (time_alive >= 1500) begin
                should_be_active <= 4'd4;
                speed <= 3'd5;
            end
            if (time_alive >= 1800) begin
                should_be_active <= 4'd5;
            end
            if (time_alive >= 2100) begin
                should_be_active <= 4'd6;
                speed <= 3'd6;
            end
            if (time_alive >= 2400) begin
                should_be_active <= 4'd7;
            end
            if (time_alive >= 2700) begin
                should_be_active <= 4'd8;
                speed <= 3'd7;
            end
            if (time_alive >= 3000) begin
                should_be_active <= 4'd9;
            end
            if (time_alive >= 3300) begin
                should_be_active <= 4'd10;
            end
            
            // Check if index is in range of actives, also for 0 case since we start at start = end = 0 just check theres actually an obstacle
            // Update all positions/active status as necessary
            if (curr_active && ((0 >= start_index && end_index >= 0) || (start_index >= end_index && end_index >= 0 && start_index >= 0))) begin
                if (speed >= obstacles_out[0].position) begin
                    // obstacle moving off screen, no longer active.
                    obstacles_out[0].active <= 0;
                    obstacles_out[0].position <= 11'd1023 + OBSTACLE_WIDTH;
                    curr_active <= curr_active - 1;
                    if (curr_active > 0) begin
                        start_index <= start_index + 1;
                    end
                end else if (obstacles_out[0].active) begin
                    // update position.
                    obstacles_out[0].position <= obstacles_out[0].position - speed;
                end
            end
            if (curr_active && ((1 >= start_index && end_index >= 1) || (start_index >= end_index && end_index >= 1 && start_index >= 1))) begin
                if (speed >= obstacles_out[1].position) begin
                    // obstacle moving off screen, no longer active.
                    obstacles_out[1].active <= 0;
                    obstacles_out[1].position <= 11'd1023 + OBSTACLE_WIDTH;
                    curr_active <= curr_active - 1;
                    if (curr_active > 0) begin
                        start_index <= start_index + 1;
                    end
                end else if (obstacles_out[1].active) begin
                    // update position.
                    obstacles_out[1].position <= obstacles_out[1].position - speed;
                end
            end
            if (curr_active && ((2 >= start_index && end_index >= 2) || (start_index >= end_index && end_index >= 2 && start_index >= 2))) begin
                if (speed >= obstacles_out[2].position) begin
                    // obstacle moving off screen, no longer active.
                    obstacles_out[2].active <= 0;
                    obstacles_out[2].position <= 11'd1023 + OBSTACLE_WIDTH;
                    curr_active <= curr_active - 1;
                    if (curr_active > 0) begin
                        start_index <= start_index + 1;
                    end
                end else if (obstacles_out[2].active) begin
                    // update position.
                    obstacles_out[2].position <= obstacles_out[2] - speed;
                end
            end
            if (curr_active && ((3 >= start_index && end_index >= 3) || (start_index >= end_index && end_index >= 3 && start_index >= 3))) begin
                if (speed >= obstacles_out[3].position) begin
                    // obstacle moving off screen, no longer active.
                    obstacles_out[3].active <= 0;
                    obstacles_out[3].position <= 11'd1023 + OBSTACLE_WIDTH;
                    curr_active <= curr_active - 1;
                    if (curr_active > 0) begin
                        start_index <= start_index + 1;
                    end
                end else if (obstacles_out[3].active) begin
                    // update position.
                    obstacles_out[3].position <= obstacles_out[3].position - speed;
                end
            end
            if (curr_active && ((4 >= start_index && end_index >= 4) || (start_index >= end_index && end_index >= 4 && start_index >= 4))) begin
                if (speed >= obstacles_out[4].position) begin
                    // obstacle moving off screen, no longer active.
                    obstacles_out[4].active <= 0;
                    obstacles_out[4].position <= 11'd1023 + OBSTACLE_WIDTH;
                    curr_active <= curr_active - 1;
                    if (curr_active > 0) begin
                        start_index <= start_index + 1;
                    end
                end else if (obstacles_out[4].active) begin
                    // update position.
                    obstacles_out[4].position <= obstacles_out[4].position - speed;
                end
            end
            if (curr_active && ((5 >= start_index && end_index >= 5) || (start_index >= end_index && end_index >= 5 && start_index >= 5))) begin
                if (speed >= obstacles_out[5].position) begin
                    // obstacle moving off screen, no longer active.
                    obstacles_out[5].active <= 0;
                    obstacles_out[5].position <= 11'd1023 + OBSTACLE_WIDTH;
                    curr_active <= curr_active - 1;
                    if (curr_active > 0) begin
                        start_index <= start_index + 1;
                    end
                end else if (obstacles_out[5].active) begin
                    // update position.
                    obstacles_out[5].position <= obstacles_out[5].position - speed;
                end
            end
            if (curr_active && ((6 >= start_index && end_index >= 6) || (start_index >= end_index && end_index >= 6 && start_index >= 6))) begin
                if (speed >= obstacles_out[6].position) begin
                    // obstacle moving off screen, no longer active.
                    obstacles_out[6].active <= 0;
                    obstacles_out[6].position <= 11'd1023 + OBSTACLE_WIDTH;
                    curr_active <= curr_active - 1;
                    if (curr_active > 0) begin
                        start_index <= start_index + 1;
                    end
                end else if (obstacles_out[6].active) begin
                    // update position.
                    obstacles_out[6].position <= obstacles_out[6].position - speed;
                end
            end
            if (curr_active && ((7 >= start_index && end_index >= 7) || (start_index >= end_index && end_index >= 7 && start_index >= 7))) begin
                if (speed >= obstacles_out[7].position) begin
                    // obstacle moving off screen, no longer active.
                    obstacles_out[7].active <= 0;
                    obstacles_out[7].position <= 11'd1023 + OBSTACLE_WIDTH;
                    curr_active <= curr_active - 1;
                    if (curr_active > 0) begin
                        start_index <= start_index + 1;
                    end
                end else if (obstacles_out[7].active) begin
                    // update position.
                    obstacles_out[7].position <= obstacles_out[7].position - speed;
                end
            end
            if (curr_active && ((8 >= start_index && end_index >= 8) || (start_index >= end_index && end_index >= 8 && start_index >= 8))) begin
                if (speed >= obstacles_out[8].position) begin
                    // obstacle moving off screen, no longer active.
                    obstacles_out[8].active <= 0;
                    obstacles_out[8].position <= 11'd1023 + OBSTACLE_WIDTH;
                    curr_active <= curr_active - 1;
                    if (curr_active > 0) begin
                        start_index <= start_index + 1;
                    end
                end else if (obstacles_out[8].active) begin
                    // update position.
                    obstacles_out[8].position <= obstacles_out[8].position - speed;
                end
            end
            if (curr_active && ((9 >= start_index && end_index >= 9) || (start_index >= end_index && end_index >= 9 && start_index >= 9))) begin
                if (speed >= obstacles_out[9].position) begin
                    // obstacle moving off screen, no longer active.
                    obstacles_out[9].active <= 0;
                    obstacles_out[9].position <= 11'd1023 + OBSTACLE_WIDTH;
                    curr_active <= curr_active - 1;
                    if (curr_active > 0) begin
                        start_index <= start_index + 1;
                    end
                end else if (obstacles_out[9].active) begin
                    // update position.
                    obstacles_out[9].position <= obstacles_out[9].position - speed;
                end
            end
            
            if (curr_active < should_be_active && !is_counting) begin
                time_to_wait <= random_num;
                start_timer <= 1;
                is_counting <= 1;
            end else if (is_counting && expired_in && curr_active < 10) begin
                // Only generate if we don't already have max amount of obstacles
                start_timer <= 0;
                is_counting <= 0;
                // generate new obstacle
                if (end_index == 9) begin
                    obstacles_out[0].active <= 1;
                    obstacles_out[0].lane <= random_lane;
                    obstacles_out[0].position <= 11'd1023 + OBSTACLE_WIDTH;
                    obstacles_out[0].sprite_type <= random_sprite;
                    end_index <= 0;
                end else if (end_index == start_index && !curr_active) begin
                    obstacles_out[end_index].active <= 1;
                    obstacles_out[end_index].lane <= random_lane;
                    obstacles_out[end_index].position <= 11'd1023 + OBSTACLE_WIDTH;
                    obstacles_out[end_index].sprite_type <= random_sprite;
                end else begin
                    obstacles_out[end_index+1].active <= 1;
                    obstacles_out[end_index+1].lane <= random_lane;
                    obstacles_out[end_index+1].position <= 11'd1023 + OBSTACLE_WIDTH;
                    obstacles_out[end_index+1].sprite_type <= random_sprite;
                    end_index <= end_index + 1;
                end
                curr_active <= curr_active + 1;
            end else begin
                start_timer <= 0;
            end
        end
    end
endmodule

`default_nettype wire