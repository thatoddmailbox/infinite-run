`default_nettype none

module randomizer(
    input wire clk_in,
    input wire rst_in,
    output logic [3:0] value
    );
    
    logic feedback;
    assign feedback = ~(value[3] ^ value[2]);

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            value <= 4'b0;
        end else begin
            value <= {value[2:0], feedback};
        end
    end
endmodule

`default_nettype wire