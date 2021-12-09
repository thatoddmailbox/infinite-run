`default_nettype none

`include "data.sv"

module track_draw(
    input wire system_clock_in,

    input wire [10:0] hcount,
    input wire [9:0] vcount,
    input wire hsync,
    input wire vsync,
    input wire blank,

    input wire obstacle obstacles [9:0],

    input wire [3:0] lives,

    input wire [1:0] lane,
    input wire jump,

    output logic [11:0] rgb
);

    wire [1:0] current_lane;
    assign current_lane = (vcount < LANE_HEIGHT) ? 2'd0 :
                          (vcount < LANE_HEIGHT*2) ? 2'd1 : 2'd2;

    wire in_lane_margin;
    assign in_lane_margin = (
        // lane 0 top
        (vcount < OBSTACLE_MARGIN) ||

        // lane 0 bottom, lane 1 top
        ((vcount > (LANE_HEIGHT*1) - OBSTACLE_MARGIN) && (vcount < (LANE_HEIGHT*1) + OBSTACLE_MARGIN)) ||

        // lane 1 bottom, lane 2 top
        ((vcount > (LANE_HEIGHT*2) - OBSTACLE_MARGIN) && (vcount < (LANE_HEIGHT*2) + OBSTACLE_MARGIN)) ||

        // lane 2 bottom
        (vcount > (LANE_HEIGHT*3) - OBSTACLE_MARGIN)
    );

    wire in_lane_margin_powerup;
    assign in_lane_margin_powerup = (
        // lane 0 top
        (vcount < POWERUP_MARGIN) ||

        // lane 0 bottom, lane 1 top
        ((vcount > (LANE_HEIGHT*1) - POWERUP_MARGIN) && (vcount < (LANE_HEIGHT*1) + POWERUP_MARGIN)) ||

        // lane 1 bottom, lane 2 top
        ((vcount > (LANE_HEIGHT*2) - POWERUP_MARGIN) && (vcount < (LANE_HEIGHT*2) + POWERUP_MARGIN)) ||

        // lane 2 bottom
        (vcount > (LANE_HEIGHT*3) - POWERUP_MARGIN)
    );

    wire in_lane_indicator;
    assign in_lane_indicator = (
        (hcount < 16)
    );

    wire obstacle_active [9:0];
    genvar i;
    generate
        for (i = 0; i < 10; i++) begin
            assign obstacle_active[i] = (
                // is active?
                obstacles[i].active &&

                // is in current lane?
                obstacles[i].lane == current_lane &&

                // is it a powerup?
                (obstacles[i].sprite_type == POWERUP_OBSTACLE_TYPE ?
                (
                    // does hcount intersect?
                    (
                        // normal check
                        (
                            (hcount > (obstacles[i].position - POWERUP_WIDTH)) &&
                            (hcount < obstacles[i].position)
                        ) ||

                        // special case: we're on the edge
                        (
                            obstacles[i].position < POWERUP_WIDTH &&
                            hcount < obstacles[i].position
                        )
                    )
                ) :
                (
                    // does hcount intersect?
                    (
                        // normal check
                        (
                            (hcount > (obstacles[i].position - OBSTACLE_WIDTH)) &&
                            (hcount < obstacles[i].position)
                        ) ||

                        // special case: we're on the edge
                        (
                            obstacles[i].position < OBSTACLE_WIDTH &&
                            hcount < obstacles[i].position
                        )
                    )
                ))
            );
        end
    endgenerate

    // TODO: is this ok?
    wire [3:0] obstacle_index = (
        (obstacle_active[0]) ? 4'd0 :
        (obstacle_active[1]) ? 4'd1 :
        (obstacle_active[2]) ? 4'd2 :
        (obstacle_active[3]) ? 4'd3 :
        (obstacle_active[4]) ? 4'd4 :
        (obstacle_active[5]) ? 4'd5 :
        (obstacle_active[6]) ? 4'd6 :
        (obstacle_active[7]) ? 4'd7 :
        (obstacle_active[8]) ? 4'd8 :
        (obstacle_active[9]) ? 4'd9 : 4'hF
    );
    wire [11:0] obstacle_color = (
        (obstacle_active[0]) ? 12'hF00 :
        (obstacle_active[1]) ? 12'h0F0 :
        (obstacle_active[2]) ? 12'hFF0 :
        (obstacle_active[3]) ? 12'hFFF :
        (obstacle_active[4]) ? 12'hFFF :
        (obstacle_active[5]) ? 12'hFFF :
        (obstacle_active[6]) ? 12'hFFF :
        (obstacle_active[7]) ? 12'hFFF :
        (obstacle_active[8]) ? 12'hFFF :
        (obstacle_active[9]) ? 12'hFFF : 12'hFFF
    );
    wire obstacle_is_powerup = (obstacles[obstacle_index].sprite_type == POWERUP_OBSTACLE_TYPE);

    wire displaying_lives = (hcount > SCREEN_WIDTH - LIVES_BAR_WIDTH);
    wire [9:0] current_life_index = (vcount >> 6);
    wire [9:0] current_life_edge = current_life_index << 6;
    wire [9:0] next_life_edge = (current_life_index + 1) << 6;
    wire displaying_life = (vcount > current_life_edge + 8 && vcount < next_life_edge - 8) && (hcount > 8 && hcount < (8 - LIVES_BAR_WIDTH));
    wire life_exists = current_life_index < lives;

    always_ff @(posedge system_clock_in) begin
        rgb <= (displaying_lives ? (
                (displaying_life && life_exists) ? 12'hFFF : 12'h000
            ): (in_lane_indicator ? (
                current_lane == lane ? (jump ? 12'h0F0 : 12'hF00) : 12'hFFF
            ) : ((!(obstacle_is_powerup ? in_lane_margin_powerup : in_lane_margin) && obstacle_index != 4'hF) ?
            // obstacle
            obstacle_color :

            // lane background
            (current_lane << 12'd2)
        )));
    end

endmodule

`default_nettype wire
