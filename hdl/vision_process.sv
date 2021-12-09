`default_nettype none
`include "data.sv"

module vision_process(
    input wire pixel_clock_in,

    input wire [9:0] frame_x_count,
    input wire [8:0] frame_y_count,
    input wire [15:0] pixel_data,
    input wire pixel_valid,

    output logic [1:0] lane,
    output logic jump,
    output logic [8:0] quadrants,
    output logic data_valid
);

    parameter GREEN_THRESHOLD = 6'd12;

    wire frame_start = (frame_x_count == 10'd0 && frame_y_count == 9'd0);

    // nine quadrants of each frame
    // (i realize that quadrants is technically the wrong term since there's more than four of them)
    // +-----------------+
    // |  0  |  1  |  2  |
    // |  3  |  4  |  5  |
    // |  6  |  7  |  8  |
    // +-----------------+

    logic [2:0] quadrant_votes [8:0];

    wire [1:0] quadrant_col = (
        frame_x_count < CAMERA_SIDE_LANE_WIDTH ?
            2'd0 :
            (frame_x_count < CAMERA_RIGHT_LANE_X ?
                2'd1 : 2'd2
            )
    );
    wire [1:0] quadrant_row = (
        frame_y_count < CAMERA_TOP_ROW_HEIGHT ?
            2'd0 :
            (frame_y_count < CAMERA_MIDDLE_ROW_Y ?
                2'd1 : 2'd2
            )
    );
    wire [3:0] quadrant =
        (quadrant_col == 2'd0 && quadrant_row == 2'd0) ? 4'd0 :
        (quadrant_col == 2'd1 && quadrant_row == 2'd0) ? 4'd1 :
        (quadrant_col == 2'd2 && quadrant_row == 2'd0) ? 4'd2 :
        (quadrant_col == 2'd0 && quadrant_row == 2'd1) ? 4'd3 :
        (quadrant_col == 2'd1 && quadrant_row == 2'd1) ? 4'd4 :
        (quadrant_col == 2'd2 && quadrant_row == 2'd1) ? 4'd5 :
        (quadrant_col == 2'd0 && quadrant_row == 2'd2) ? 4'd6 :
        (quadrant_col == 2'd1 && quadrant_row == 2'd2) ? 4'd7 :
        (quadrant_col == 2'd2 && quadrant_row == 2'd2) ? 4'd8 : 4'd0;

    wire [2:0] lane_0_quadrants = quadrants[0] + quadrants[3] + quadrants[6];
    wire [2:0] lane_1_quadrants = quadrants[1] + quadrants[4] + quadrants[7];
    wire [2:0] lane_2_quadrants = quadrants[2] + quadrants[5] + quadrants[8];
    wire [3:0] total_quadrants = lane_0_quadrants + lane_1_quadrants + lane_2_quadrants;

    always_ff @(posedge pixel_clock_in) begin
        if (frame_start && !pixel_valid) begin
            // start of a frame
            // (we cheat a little bit and use the first, non-valid-pixel clock cycle)
            // (that way we still process the first pixel correctly)

            // set lane and jump
            if (total_quadrants < 2) begin
                // if there's only zero or one active quadrants, we don't really have enough data
                // (user's probably offscreen?)
                // so, put them in the non-existent lane 3, and force them to be on the ground.
                // that way, the game doesn't start reacting to random inputs by itself
                lane <= 2'd3;
                jump <= 1'd0;
            end else begin
                lane <= (
                    (lane_2_quadrants >= lane_0_quadrants && lane_2_quadrants >= lane_1_quadrants) ? 2'd2 :
                    (lane_1_quadrants >= lane_0_quadrants && lane_1_quadrants >= lane_2_quadrants) ? 2'd1 :
                    (lane_0_quadrants >= lane_1_quadrants && lane_0_quadrants >= lane_2_quadrants) ? 2'd0 : 2'd3
                );
                jump <= ~(quadrants[6] || quadrants[7] || quadrants[8]);
            end

            // set data valid
            data_valid <= 1'b1;
        end else if (pixel_valid) begin
            if (data_valid) begin
                // clear data flag and data
                data_valid <= 1'b0;
                quadrants <= 9'b0;

                quadrant_votes[0] <= 3'b0;
                quadrant_votes[1] <= 3'b0;
                quadrant_votes[2] <= 3'b0;
                quadrant_votes[3] <= 3'b0;
                quadrant_votes[4] <= 3'b0;
                quadrant_votes[5] <= 3'b0;
                quadrant_votes[6] <= 3'b0;
                quadrant_votes[7] <= 3'b0;
                quadrant_votes[8] <= 3'b0;
            end

            // compare the green channel with the threshold
            // it's rgb565, which looks like:
            // 15 11 | 10   5 | 4   0
            // rrrrr | gggggg | bbbbb
            // so we want [10:5]
            // HACK: workaround for pipelining issue
            if (pixel_data[10:5] < GREEN_THRESHOLD && frame_x_count > 10) begin
                // a "green-ness" below the threshold indicates that we are NOT looking at the green screen
                // and therefore this is the player (or I guess some other blob lol)
                quadrant_votes[quadrant] <= quadrant_votes[quadrant] + 1'b1;
                if (quadrant_votes[quadrant] == 3'b111) begin
                    quadrants[quadrant] <= 1'b1;
                end
            end
        end
    end

endmodule

`default_nettype wire