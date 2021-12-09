`ifndef DATA_SV
`define DATA_SV

// obstacle: type, position, lane, active
// ttpppppppppplla
// [15:14] [13:3] [2:1] [0]
typedef struct packed {
    logic [1:0] sprite_type;
    logic [10:0] position;
    logic [1:0] lane;
    logic active;
} obstacle;

parameter SCREEN_WIDTH = 1024;
parameter SCREEN_HEIGHT = 768;

parameter LIVES_BAR_WIDTH = 32+16;
parameter LIFE_WIDTH = 32;
parameter LIFE_HEIGHT = 32;
parameter LIFE_Y = 8;
parameter LIFE_MARGIN = 8;

parameter CAMERA_WIDTH = 320;
parameter CAMERA_HEIGHT = 240;

parameter CAMERA_SIDE_LANE_WIDTH = 320 / 4;
localparam CAMERA_MIDDLE_LANE_WIDTH = CAMERA_WIDTH - (2 * CAMERA_SIDE_LANE_WIDTH);
localparam CAMERA_RIGHT_LANE_X = CAMERA_SIDE_LANE_WIDTH + CAMERA_MIDDLE_LANE_WIDTH;

localparam CAMERA_TOP_ROW_HEIGHT = CAMERA_HEIGHT / 3;
localparam CAMERA_BOTTOM_ROW_HEIGHT = CAMERA_HEIGHT / 8;
localparam CAMERA_MIDDLE_ROW_HEIGHT = CAMERA_HEIGHT - CAMERA_TOP_ROW_HEIGHT - CAMERA_BOTTOM_ROW_HEIGHT;
localparam CAMERA_MIDDLE_ROW_Y = CAMERA_TOP_ROW_HEIGHT + CAMERA_MIDDLE_ROW_HEIGHT;

localparam LANE_HEIGHT = SCREEN_HEIGHT / 3;

localparam OBSTACLE_MARGIN = 16;
localparam OBSTACLE_HEIGHT = LANE_HEIGHT - 2*OBSTACLE_MARGIN;
localparam OBSTACLE_WIDTH = OBSTACLE_HEIGHT; // 224

localparam POWERUP_OBSTACLE_TYPE = 3;
localparam POWERUP_HEIGHT = 32;
localparam POWERUP_WIDTH = 32;
localparam POWERUP_MARGIN = (LANE_HEIGHT - POWERUP_HEIGHT) / 2;

`endif