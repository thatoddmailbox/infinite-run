`default_nettype none

module camera_read(
    input wire pixel_clock_in,

    input wire vsync_in,
    input wire href_in,
    input wire [7:0] pixel_data_in,

    output logic [9:0] frame_x_count_out,
    output logic [8:0] frame_y_count_out,
    output logic [15:0] pixel_data_out,
    output logic pixel_valid_out,
    output logic frame_done_out
);

	logic [1:0] FSM_state = 0;
    logic pixel_half = 0;
    logic href_was_on = 1'b0;

	localparam WAIT_FRAME_START = 0;
	localparam ROW_CAPTURE = 1;

	always_ff @(posedge pixel_clock_in) begin 
        case (FSM_state)        
            WAIT_FRAME_START: begin //wait for VSYNC
                FSM_state <= (!vsync_in) ? ROW_CAPTURE : WAIT_FRAME_START;
                frame_done_out <= 0;
                frame_x_count_out <= 10'b0;
                frame_y_count_out <= 9'b0;
                pixel_half <= 0;
                href_was_on <= 1'b0;
            end

            ROW_CAPTURE: begin
                FSM_state <= vsync_in ? WAIT_FRAME_START : ROW_CAPTURE;
                frame_done_out <= vsync_in ? 1 : 0;
                pixel_valid_out <= (href_in && pixel_half) ? 1 : 0;
                if (href_in) begin
                    pixel_half <= ~ pixel_half;
                    href_was_on <= 1'b1;

                    if (pixel_half) begin
                        pixel_data_out[7:0] <= pixel_data_in;
                        frame_x_count_out <= frame_x_count_out + 10'b1;
                    end else begin
                        pixel_data_out[15:8] <= pixel_data_in;
                    end
                end else if (href_was_on) begin
                    // we are on the falling edge of href
                    // this indicates that we finished the row
                    // reset our x, y counters
                    frame_x_count_out <= 10'b0;
                    frame_y_count_out <= frame_y_count_out + 9'b1;
                    href_was_on <= 1'b0;
                end
            end

            default: begin
                // this shouldn't happen
                FSM_state <= WAIT_FRAME_START;
            end
        endcase
	end

endmodule

`default_nettype wire