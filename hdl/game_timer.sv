`default_nettype none

module game_timer(
    input wire system_clock_in,

    input wire reset_game,
    input wire playing,

    output logic [6:0] ca, cb, cc, cd, ce, cf, cg,
    output logic [7:0] an_out
);

    display_8hex display(
        .clk_in(system_clock_in),
        .data_in(elapsed_time),
        .seg_out({cg, cf, ce, cd, cc, cb, ca}),
        .strobe_out(an_out)
    );

    logic [27:0] elapsed_time;
    logic [23:0] elapsed_time_counter;

    always @(posedge system_clock_in) begin
        if (reset_game) begin
            elapsed_time <= 0;
            elapsed_time_counter <= 0;
        end else if (playing) begin
            elapsed_time_counter = elapsed_time_counter + 1;

            // when the counter hits 65,000,000 (65 million divided by 100), increment counter
            if (elapsed_time_counter == 65_000_000) begin
                // this will be fired at a rate of 1 Hz

                // increment counter
                elapsed_time_counter = 0;
                elapsed_time = elapsed_time + 1;

                // adjust digits for bcd
                // this is a bit of a mess
                // i tried to use generation here, but it seemed to not work inside of the always block
                if (elapsed_time[3:0] > 9) begin
                    elapsed_time = elapsed_time + 6;
                end
                if (elapsed_time[7:4] > 9) begin
                    elapsed_time = elapsed_time + (6 << 4);
                end
                if (elapsed_time[11:8] > 9) begin
                    elapsed_time = elapsed_time + (6 << 8);
                end
                if (elapsed_time[15:12] > 9) begin
                    elapsed_time = elapsed_time + (6 << 12);
                end
                if (elapsed_time[19:16] > 9) begin
                    elapsed_time = elapsed_time + (6 << 16);
                end
                if (elapsed_time[23:20] > 9) begin
                    elapsed_time = elapsed_time + (6 << 20);
                end
                if (elapsed_time[27:24] > 9) begin
                    elapsed_time = elapsed_time + (6 << 24);
                end
            end
        end
    end
endmodule

`default_nettype wire