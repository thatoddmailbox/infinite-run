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

        if (vision_data_valid) begin
            quadrants_buffer <= quadrants;
        end
        quadrants_buffer2 <= quadrants_buffer;
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

    assign rgb = ((hcount<320) && (vcount<240)) ? frame_buff_out :
                 ((hcount<640) && (vcount<240)) ? (
                    (quadrants_buffer2[current_quadrant] == 1'b1) ? 12'h00F : 12'h000
//                      (current_quadrant << 5'd1)
                 ) : 12'hFFF;

endmodule

`default_nettype wire