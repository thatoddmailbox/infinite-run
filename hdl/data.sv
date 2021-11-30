`ifndef DATA_SV
`define DATA_SV

// obstacle: type, position, lane, active
// ttpppppppppplla
// [14:13] [12:3] [2:1] [0]
typedef struct packed {
    logic [1:0] sprite_type;
    logic [9:0] position;
    logic [1:0] lane;
    logic active;
} obstacle;

`endif