module vision_process_tb;
    logic clock;

    logic [9:0] frame_x_count;
    logic [8:0] frame_y_count;
    logic [15:0] pixel_data;
    logic pixel_valid;

    logic [1:0] lane;
    logic jump;
    logic [8:0] quadrants;
    logic data_valid;

    logic [15:0] frame [16*12];

    always #5 clock = !clock;

    vision_process #(
        .FRAME_WIDTH(16),
        .FRAME_HEIGHT(12)
    ) uut(
        .pixel_clock_in(clock),

        .frame_x_count(frame_x_count),
        .frame_y_count(frame_y_count),
        .pixel_data(pixel_data),
        .pixel_valid(pixel_valid),

        .lane(lane),
        .jump(jump),
        .quadrants(quadrants),
        .data_valid(data_valid)
    );

    task send_frame();
        // reset everything
        frame_x_count = 10'd0;
        frame_y_count = 9'd0;
        pixel_data = 16'd0;
        pixel_valid = 1'd0;

        for (int i = 0; i < 16*12; i++) begin
            // load the pixel
            // first half (invalid data)
            pixel_data = 16'hFFFF;
            pixel_valid = 1'd0;

            #10;

            // second half (valid data)
            pixel_data = frame[(frame_y_count * 16) + frame_x_count];
            pixel_valid = 1'd1;

            #10;

            // update counters
            frame_x_count = frame_x_count + 10'd1;
            if (frame_x_count == 16) begin
                frame_x_count = 10'd0;
                frame_y_count = frame_y_count + 9'd1;
            end
        end
    endtask

    localparam GREEN = {5'h00, 6'h3F, 5'h00};
    localparam BLACK = {5'h00, 6'h00, 5'h00};

    initial begin
        clock = 0;

        frame = '{
            GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, BLACK, BLACK, BLACK, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN,
            GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, BLACK, BLACK, BLACK, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN,
            GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN,
            GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, BLACK, GREEN,
            GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN,
            GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN,
            GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN,
            GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN,
            GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN,
            GREEN, GREEN, GREEN, BLACK, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN,
            GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, BLACK, BLACK, BLACK,
            GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, GREEN, BLACK, GREEN, BLACK
        };
        send_frame();

        frame_x_count = 10'd0;
        frame_y_count = 9'd0;
        pixel_data = 16'hFFFF;
        pixel_valid = 1'd0;

        #10;
    end
endmodule