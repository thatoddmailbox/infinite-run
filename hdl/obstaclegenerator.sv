`default_nettype none
`include "data.sv"

module obstacle_generator(
    input wire clk_in,
    input wire rst_in,
    input wire jump_in,
    input wire game_reset,
    input wire frame_trigger,
    input wire [1:0] lane_in,
    input wire [11:0] time_alive,
    input wire [3:0] random_num,
    input wire [1:0] random_lane,
    input wire [1:0] random_sprite,
    input wire expired_in,
    output obstacle obstacles_out [9:0],
    output logic start_timer,
    output logic [5:0] time_to_wait
    );

    wire [3:0] curr_active = (
        obstacles_out[0].active +
        obstacles_out[1].active +
        obstacles_out[2].active +
        obstacles_out[3].active +
        obstacles_out[4].active +
        obstacles_out[5].active +
        obstacles_out[6].active +
        obstacles_out[7].active +
        obstacles_out[8].active +
        obstacles_out[9].active
    );
    logic [3:0] should_be_active;
    logic is_counting;

    logic [2:0] speed;
    
    wire [3:0] next_free_slot = (!obstacles_out[0].active) ? 4'd0 :
                                (!obstacles_out[1].active) ? 4'd1 :
                                (!obstacles_out[2].active) ? 4'd2 :
                                (!obstacles_out[3].active) ? 4'd3 :
                                (!obstacles_out[4].active) ? 4'd4 :
                                (!obstacles_out[5].active) ? 4'd5 :
                                (!obstacles_out[6].active) ? 4'd6:
                                (!obstacles_out[7].active) ? 4'd7 :
                                (!obstacles_out[8].active) ? 4'd8 :
                                (!obstacles_out[9].active) ? 4'd9 : 4'hF;

    always_ff @(posedge clk_in) begin
        if (rst_in || game_reset) begin
            obstacles_out <= '{
                16'b0,
                16'b0,
                16'b0,
                16'b0,
                16'b0,
                16'b0,
                16'b0,
                16'b0,
                16'b0,
                16'b0
            };
            should_be_active <= 0;
            is_counting <= 0;
            speed <= 3'b1;
        end else begin
            if (time_alive >= 30) begin
                should_be_active <= 4'd1;
                speed <= 3'd2;
            end
            if (time_alive >= 60) begin
                should_be_active <= 4'd2;
                speed <= 3'd3;
            end
            if (time_alive >= 120) begin
                should_be_active <= 4'd3;
                speed <= 3'd4;
            end
            if (time_alive >= 150) begin
                should_be_active <= 4'd4;
                speed <= 3'd5;
            end
            if (time_alive >= 180) begin
                should_be_active <= 4'd5;
            end
            if (time_alive >= 210) begin
                should_be_active <= 4'd6;
                speed <= 3'd6;
            end
            if (time_alive >= 240) begin
                should_be_active <= 4'd7;
            end
            if (time_alive >= 270) begin
                should_be_active <= 4'd8;
                speed <= 3'd7;
            end
            if (time_alive >= 300) begin
                should_be_active <= 4'd9;
            end
            if (time_alive >= 330) begin
                should_be_active <= 4'd10;
            end

            for (integer i = 0; i < 10; i++) begin
                if (frame_trigger && obstacles_out[i].active) begin
                    if (speed >= obstacles_out[i].position) begin
                        // obstacle moving off screen, no longer active.
                        obstacles_out[i].active <= 0;
                        obstacles_out[i].position <= 11'd1023 + OBSTACLE_WIDTH;
                    end else begin
                        // update position.
                        obstacles_out[i].position <= obstacles_out[i].position - speed;
                    end
                end
            end
            
            if (curr_active < should_be_active && !is_counting) begin
                time_to_wait <= (random_num << 2);
                start_timer <= 1;
                is_counting <= 1;
            end else if (is_counting && expired_in && curr_active < 10) begin
                // Only generate if we don't already have max amount of obstacles
                start_timer <= 0;
                is_counting <= 0;

                // generate new obstacle
                obstacles_out[next_free_slot].active <= 1;
                obstacles_out[next_free_slot].lane <= (random_lane == 2'd3 ? 2'd0 : random_lane);
                obstacles_out[next_free_slot].position <= 11'd1023 + OBSTACLE_WIDTH;
                obstacles_out[next_free_slot].sprite_type <= random_sprite;
            end else begin
                start_timer <= 0;
            end
        end
    end
endmodule

`default_nettype wire