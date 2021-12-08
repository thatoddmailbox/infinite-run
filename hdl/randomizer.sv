`default_nettype none

module randomizer(
    input wire clk_in,
    input wire rst_in,
    output logic [7:0] value
    );
    
    logic feedback;
    assign feedback = value[7] ~^ value[5] ~^ value[4] ~^ value[3];

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            value <= 8'b0;
        end else begin
            value <= {value[6:0], feedback};
        end
    end
endmodule

`default_nettype wire