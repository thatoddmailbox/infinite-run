`default_nettype none

module camera_debug_draw(
    input wire system_clock_in,

    input wire [10:0] hcount,
    input wire [9:0] vcount,
    input wire hsync,
    input wire vsync,
    input wire blank,

    output logic [11:0] rgb,

    //
    // Start pixel clock domain
    //
    input wire pixel_clock_in,

    // from camera_read
    input wire [15:0] pixel_data,
    input wire pixel_valid,
    input wire frame_done,

    // from vision_process
    input wire [1:0] lane,
    input wire jump,
    input wire [8:0] quadrants,
    input wire vision_data_valid
    //
    // End pixel clock domain
    //
);

    logic [8:0] quadrants_buffer;
    logic [8:0] quadrants_buffer2;
    logic [8:0] quadrants_buffer3;

    logic vision_data_valid_buffer;
    logic vision_data_valid_buffer2;

    logic [1:0] lane_buffer;
    logic [1:0] lane_buffer2;
    logic [1:0] lane_buffer3;

    logic jump_buffer;
    logic jump_buffer2;
    logic jump_buffer3;

    logic [16:0] pixel_addr_in;
    logic [16:0] pixel_addr_out;

    logic [11:0] frame_buff_out;

    logic [3:0] current_quadrant;

    always_ff @(posedge pixel_clock_in) begin
        if (frame_done) begin
            pixel_addr_in <= 17'b0;
        end else if (pixel_valid) begin
            pixel_addr_in <= pixel_addr_in + 1;
        end

        quadrants_buffer <= quadrants;
        quadrants_buffer2 <= quadrants_buffer;

        vision_data_valid_buffer <= vision_data_valid;
        vision_data_valid_buffer2 <= vision_data_valid_buffer;

        lane_buffer <= lane;
        lane_buffer2 <= lane_buffer;

        jump_buffer <= jump;
        jump_buffer2 <= jump_buffer;

        if (vision_data_valid_buffer2) begin
            quadrants_buffer3 <= quadrants_buffer2;
            lane_buffer3 <= lane_buffer2;
            jump_buffer3 <= jump_buffer2;
        end
    end

    blk_mem_camera_frame framebuffer(
        .addra(pixel_addr_in),
        .clka(pixel_clock_in),
        .dina({pixel_data[15:12], pixel_data[10:7], pixel_data[4:1]}),
        .wea(pixel_valid),

        .addrb(pixel_addr_out),
        .clkb(system_clock_in),
        .doutb(frame_buff_out)
    );

    assign pixel_addr_out = hcount+vcount*32'd320;
    // TODO: jank
    assign current_quadrant =
        ((hcount<320+((320/3)*1)) && (vcount<(240/3)*1)) ? 4'd0 :
        ((hcount<320+((320/3)*2)) && (vcount<(240/3)*1)) ? 4'd1 :
        ((hcount<320+((320/3)*3)) && (vcount<(240/3)*1)) ? 4'd2 :
        ((hcount<320+((320/3)*1)) && (vcount<(240/3)*2)) ? 4'd3 :
        ((hcount<320+((320/3)*2)) && (vcount<(240/3)*2)) ? 4'd4 :
        ((hcount<320+((320/3)*3)) && (vcount<(240/3)*2)) ? 4'd5 :
        ((hcount<320+((320/3)*1)) && (vcount<(240/3)*3)) ? 4'd6 :
        ((hcount<320+((320/3)*2)) && (vcount<(240/3)*3)) ? 4'd7 :
        ((hcount<320+((320/3)*3)) && (vcount<(240/3)*3)) ? 4'd8 : 4'd0;

    wire [1:0] current_lane_index =
        (hcount < 640+((320/3)*1)) ? 2'd0 :
        (hcount < 640+((320/3)*2)) ? 2'd1 :
        (hcount < 640+((320/3)*3)) ? 2'd2 : 2'd3;

    assign rgb = ((hcount<320) && (vcount<240)) ? frame_buff_out :
                 ((hcount<640) && (vcount<240)) ? (
                    (quadrants_buffer3[current_quadrant] == 1'b1) ? 12'h00F : 12'h000
                 ) :
                 ((hcount<960) && (vcount<240)) ? (
                    (current_lane_index == lane_buffer3 ?
                        (jump_buffer3 ? 12'h0F0 : 12'hF00) :
                        12'h000
                    )
                 ) : 12'hFFF;

endmodule

`default_nettype wire