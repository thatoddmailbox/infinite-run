module vision_debouncer(
    input wire system_clock_in,
    input wire system_reset,

    input wire pixel_clock_in,
    input wire [1:0] lane_raw,
    input wire jump_raw,
    input wire vision_data_valid_raw,
    input wire quadrants_raw,

    output logic lane_raw_synced,
    output logic jump_raw_synced,
    output logic vision_data_valid_synced,
    output logic [8:0] quadrants_synced,

    output logic [1:0] lane,
    output logic jump
);

    // clock is at 65 MHz, t = 15.38 ns
    parameter TIME_DELAY = 30'd32_500_000;
    logic [29:0] timer;

    // sync registers, since vision data comes in on a different clock doamin
    logic [1:0] lane_raw_sync1;
    logic jump_raw_sync1;
    logic vision_data_valid_sync1;
    logic quadrants_sync1;

    always_ff @(posedge pixel_clock_in) begin
        lane_raw_sync1 <= lane_raw;
        jump_raw_sync1 <= jump_raw;
        vision_data_valid_sync1 <= vision_data_valid_raw;
        quadrants_sync1 <= quadrants_raw;

        lane_raw_synced <= lane_raw_sync1;
        jump_raw_synced <= jump_raw_sync1;
        vision_data_valid_synced <= vision_data_valid_sync1;
        quadrants_synced <= quadrants_sync1;
    end

    always_ff @(posedge system_clock_in) begin
        if (system_reset) begin
            timer <= 30'b0;
            jump <= 1'b0;
        end else if (vision_data_valid_synced) begin
            // pass data through
            lane <= lane_raw_synced;

            // jump debouncing
            if (timer == 30'b1) begin
                // almost done with timer
                if (!jump_raw_synced) begin
                    // if we're on the ground, we're done
                    timer <= 30'b0;
                    jump <= 1'b0;
                end
                // if we're still in the air, just wait for them to land
            end if (timer > 30'b0) begin
                // timer is active, keep ticking down
                timer <= timer - 30'b1;
            end else if (jump_raw_synced) begin
                // we jumped! start timer
                timer <= TIME_DELAY;
                jump <= 1'b1;
            end else begin
                jump <= 1'b0;
            end
        end
    end

endmodule
