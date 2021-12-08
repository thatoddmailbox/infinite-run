`default_nettype none

module seven_seg_controller(input wire         clk_in,
                            input wire         rst_in,
                            input wire [31:0]  val_in,
                            output logic[6:0]   cat_out,
                            output logic[7:0]   an_out
    );

    logic[7:0]      segment_state;
    logic[31:0]     segment_counter;
    logic [3:0]     routed_vals;
    logic [6:0]     led_out;

    binary_to_seven_seg my_converter ( .val_in(routed_vals), .led_out(led_out));
    assign cat_out = ~led_out;
    assign an_out = ~segment_state;


    always_comb begin
        case(segment_state)
            8'b0000_0001:   routed_vals = val_in[3:0];
            8'b0000_0010:   routed_vals = val_in[7:4];
            8'b0000_0100:   routed_vals = val_in[11:8];
            8'b0000_1000:   routed_vals = val_in[15:12];
            8'b0001_0000:   routed_vals = val_in[19:16];
            8'b0010_0000:   routed_vals = val_in[23:20];
            8'b0100_0000:   routed_vals = val_in[27:24];
            8'b1000_0000:   routed_vals = val_in[31:28];
            default:        routed_vals = val_in[3:0];
        endcase
    end

    always_ff @(posedge clk_in)begin
        if (rst_in)begin
            segment_state <= 8'b0000_0001;
            segment_counter <= 32'b0;
        end else begin
            if (segment_counter == 32'd25_000)begin
                segment_counter <= 32'd0;
                segment_state <= {segment_state[6:0],segment_state[7]};
            end else begin
                segment_counter <= segment_counter +1;
            end
        end
    end

endmodule //seven_seg_controller


module binary_to_seven_seg ( input wire [3:0] val_in, output logic [6:0] led_out);
    always_comb begin
        case(val_in)
            4'b0000: led_out = 7'b0111111;
            4'b0001: led_out = 7'b0000110;
            4'b0010: led_out = 7'b1011011;
            4'b0011: led_out = 7'b1001111;
            4'b0100: led_out = 7'b1100110;
            4'b0101: led_out = 7'b1101101;
            4'b0110: led_out = 7'b1111101;
            4'b0111: led_out = 7'b0000111;
            4'b1000: led_out = 7'b1111111;
            4'b1001: led_out = 7'b1101111;
            4'b1010: led_out = 7'b1110111;
            4'b1011: led_out = 7'b1111100;
            4'b1100: led_out = 7'b0111001;
            4'b1101: led_out = 7'b1011110;
            4'b1110: led_out = 7'b1111001;
            4'b1111: led_out = 7'b1110001;
        endcase
    end
endmodule // binary_to_seven_seg
`default_nettype wire
