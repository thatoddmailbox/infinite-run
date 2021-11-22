`default_nettype none

module camera_read(
    input wire pixel_clock_in,

    input wire vsync_in,
    input wire href_in,
    input wire [7:0] pixel_data_in,
    
    output logic [15:0] pixel_data_out,
    output logic pixel_valid_out,
    output logic frame_done_out
);

	logic [1:0] FSM_state = 0;
    logic pixel_half = 0;

	localparam WAIT_FRAME_START = 0;
	localparam ROW_CAPTURE = 1;

	always_ff @(posedge pixel_clock_in) begin 
        case (FSM_state)        
            WAIT_FRAME_START: begin //wait for VSYNC
               FSM_state <= (!vsync_in) ? ROW_CAPTURE : WAIT_FRAME_START;
               frame_done_out <= 0;
               pixel_half <= 0;
            end

            ROW_CAPTURE: begin 
               FSM_state <= vsync_in ? WAIT_FRAME_START : ROW_CAPTURE;
               frame_done_out <= vsync_in ? 1 : 0;
               pixel_valid_out <= (href_in && pixel_half) ? 1 : 0; 
               if (href_in) begin
                   pixel_half <= ~ pixel_half;
                   if (pixel_half) pixel_data_out[7:0] <= pixel_data_in;
                   else pixel_data_out[15:8] <= pixel_data_in;
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