`default_nettype none

module track_draw(
    input wire system_clock_in,

    input wire [10:0] hcount,
    input wire [9:0] vcount,
    input wire hsync,
    input wire vsync,
    input wire blank,

    input wire [14:0] obstacles [9:0],

    output logic [11:0] rgb
);

    // obstacle: type, position, lane, active
    // ttpppppppppplla
    // [14:13] [12:3] [2:1] [0]
    // is there a way to name these? structs???

    parameter SCREEN_WIDTH = 1024;
    parameter SCREEN_HEIGHT = 768;

    localparam LANE_HEIGHT = SCREEN_HEIGHT / 3;

    localparam OBSTACLE_MARGIN = 16;
    localparam OBSTACLE_HEIGHT = LANE_HEIGHT - 2*OBSTACLE_MARGIN;
    localparam OBSTACLE_WIDTH = OBSTACLE_HEIGHT;

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

    wire obstacle_active [9:0];
    genvar i;
    generate
        for (i = 0; i < 10; i++) begin
            assign obstacle_active[i] = (
                // is active?
                obstacles[i][0] &&

                // is in current lane?
                obstacles[i][2:1] == current_lane &&

                // does hcount intersect?
                (
                    (hcount > obstacles[i][12:3]) &&
                    (hcount < (obstacles[i][12:3] + OBSTACLE_WIDTH))
                )
            );
        end
    endgenerate

    always_ff @(posedge system_clock_in) begin
        rgb <= (!in_lane_margin && (obstacle_active[0] || obstacle_active[1] || obstacle_active[2]) ? 12'hFFF :
            (current_lane << 12'd2)
        );
    end

endmodule

`default_nettype wire
