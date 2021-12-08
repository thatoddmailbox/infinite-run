`default_nettype none

module timer(
    input wire clk_in,
    input wire rst_in,
    input wire start_in,
    input wire [5:0] value_in,
    output logic expired_out,
    output logic pulse_100ms_out
    );
    parameter ONEHUNDRED_MS_PERIOD = 25'd6_500_000;
    
    logic [24:0] clk_pulse_count;
    logic [5:0] count;
    logic counting;
    assign pulse_100ms_out = (clk_pulse_count == ONEHUNDRED_MS_PERIOD - 1);

    always_ff @(posedge clk_in) begin
        clk_pulse_count <= clk_pulse_count + 1;
        if (rst_in) begin
            clk_pulse_count <= 0;
            expired_out <= 0;
            count <= 0;
        end else if (start_in) begin
            count <= value_in;
            counting <= 1;
            expired_out <= 0;
        end else begin
            if (pulse_100ms_out) begin
                clk_pulse_count <= 0;
                if (counting) begin
                    count <= count - 1;
                end
                if (count == 0 && counting) begin
                    expired_out <= 1;
                    counting <= 0;
                end else begin
                    expired_out <= 0;
                end
            end
        end
    end
endmodule

`default_nettype wire