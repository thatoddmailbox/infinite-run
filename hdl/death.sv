`default_nettype none

`include "data.sv"

module death(
    input wire system_clock_in,
    input wire reset,

    input wire obstacle obstacles [9:0],
    input wire [1:0] lane,
    input wire jump,

    output logic died
);

    wire obstacle_hit [9:0];
    genvar i;
    generate
        for (i = 0; i < 10; i++) begin
            assign obstacle_hit[i] = (
                // is active?
                obstacles[i].active &&

                // is in our lane?
                obstacles[i].lane == lane &&

                // we're not jumping?
                !jump &&

                // intersects with edge?
                obstacles[i].position > (OBSTACLE_WIDTH/4) && obstacles[i].position < OBSTACLE_WIDTH
            );
        end
    endgenerate

    wire [3:0] obstacle_index = (
        (obstacle_hit[0]) ? 4'd0 :
        (obstacle_hit[1]) ? 4'd1 :
        (obstacle_hit[2]) ? 4'd2 :
        (obstacle_hit[3]) ? 4'd3 :
        (obstacle_hit[4]) ? 4'd4 :
        (obstacle_hit[5]) ? 4'd5 :
        (obstacle_hit[6]) ? 4'd6 :
        (obstacle_hit[7]) ? 4'd7 :
        (obstacle_hit[8]) ? 4'd8 :
        (obstacle_hit[9]) ? 4'd9 : 4'hF
    );

    always_ff @(posedge system_clock_in) begin
        if (reset) begin
            died <= 1'b0;
        end else if (!died) begin
            if (obstacle_index != 4'hF) begin
                died <= 1'b1;
            end
        end
    end

endmodule

`default_nettype wire
