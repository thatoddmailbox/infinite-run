`timescale 1ns / 1ps

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

    parameter FRAME_WIDTH = 10'd320;
    parameter FRAME_HEIGHT = 9'd240;

    parameter GREEN_THRESHOLD = 6'd60;

    localparam FRAME_WIDTH_DIVIDER = FRAME_WIDTH / 3;
    localparam FRAME_HEIGHT_DIVIDER = FRAME_HEIGHT / 3;

    wire frame_start = (frame_x_count == 10'd0 && frame_y_count == 9'd0);

    // nine quadrants of each frame
    // +-----------------+
    // |  0  |  1  |  2  |
    // |  3  |  4  |  5  |
    // |  6  |  7  |  8  |
    // +-----------------+
    logic [8:0] quadrant_state;

    wire [1:0] quadrant_col = (
        frame_x_count < FRAME_WIDTH_DIVIDER ?
            2'd0 :
            (frame_x_count < 2*FRAME_WIDTH_DIVIDER ?
                2'd1 : 2'd2
            )
    );
    wire [1:0] quadrant_row = (
        frame_y_count < FRAME_HEIGHT_DIVIDER ?
            2'd0 :
            (frame_y_count < 2*FRAME_HEIGHT_DIVIDER ?
                2'd1 : 2'd2
            )
    );
    // TODO: this is weird, can we do better? does it synthesize well?
    // (maybe do addition instead?
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

    always_ff @(posedge pixel_clock_in) begin
        if (frame_start && !pixel_valid) begin
            // start of a frame
            // (we cheat a little bit and use the first, non-valid-pixel clock cycle)
            // (that way we still process the first pixel correctly)

            // set lane and jump
            // TODO

            // clear quadrants (and send them out for debugging)
            quadrants <= quadrant_state;
            quadrant_state <= 9'b0;

            // set data valid
            data_valid <= 1'b1;
        end else if (pixel_valid) begin
            // clear data flag
            data_valid <= 1'b0;

            // compare the green channel with the threshold
            // it's rgb565, which looks like:
            // 15 11 | 10   5 | 4   0
            // rrrrr | gggggg | bbbbb
            // so we want [10:5]
            if (pixel_data[10:5] < GREEN_THRESHOLD) begin
                // a "green-ness" below the threshold indicates that we are NOT looking at the green screen
                // and therefore this is the player (or I guess some other blob lol)
                quadrant_state[quadrant] <= 1'b1;
            end
        end
    end

endmodule
