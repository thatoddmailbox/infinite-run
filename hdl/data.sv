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

localparam LANE_HEIGHT = SCREEN_HEIGHT / 3;

localparam OBSTACLE_MARGIN = 16;
localparam OBSTACLE_HEIGHT = LANE_HEIGHT - 2*OBSTACLE_MARGIN;
localparam OBSTACLE_WIDTH = OBSTACLE_HEIGHT;

`endif