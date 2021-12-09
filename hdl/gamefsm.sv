`default_nettype none

module gamefsm(
    input wire clk_in,
    input wire rst_in,
    input wire pulse,
    input wire died,
    input wire [1:0] lane,
    input wire jump,
    input wire got_powerup,
    output logic playing,
    output logic game_over,
    output logic [11:0] time_alive,
    output logic reset_game,
    output logic [3:0] num_lives
    );
    parameter START = 3'b0;
    parameter WAIT_FOR_FALL1 = 3'b1;
    parameter PLAYING = 3'b10;
    parameter GAMEOVER = 3'b11;
    parameter WAIT_FOR_FALL2 = 3'b100;
    
    logic [2:0] state;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            state <= START;
            time_alive <= 0;
            playing <= 0;
            game_over <= 0;
            reset_game <= 1;
            num_lives <= 1;
        end else begin
            case(state)
                START: begin
                    reset_game <= 1;
                    num_lives <= 1;
                    if (jump) begin
                        state <= WAIT_FOR_FALL1;
                    end
                end
                WAIT_FOR_FALL1: begin
                    reset_game <= 0;
                    if (!jump) begin
                        state <= PLAYING;
                        playing <= 1;
                    end
                end
                PLAYING: begin
                    if (pulse) begin
                        time_alive <= time_alive + 1;
                    end
                    if (got_powerup && !died) begin
                        num_lives <= num_lives + 1;
                    end else if (died && !got_powerup) begin
                        if (num_lives == 1) begin
                            state <= GAMEOVER;
                            game_over <= 1;
                            playing <= 0;
                            time_alive <= 0;
                        end else if (num_lives >= 1) begin
                            num_lives <= num_lives - 1;
                        end
                    end
                end
                GAMEOVER: begin
                    if (jump) begin
                        state <= WAIT_FOR_FALL2;
                    end
                end
                WAIT_FOR_FALL2: begin
                    if (!jump) begin
                        state <= START;
                        game_over <= 0;
                    end
                end
                default: begin
                    state <= START;
                end
            endcase
        end
    end
endmodule

`default_nettype wire