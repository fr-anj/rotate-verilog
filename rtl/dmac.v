module dmac (
    output 		O_DMA_READY,
    output 		O_HBUSREQ,
    output [31:0] 	O_HADDR,
    output [31:0] 	O_HWDATA,
    output [1:0] 	O_HTRANS,
    output 		O_HWRITE,
    output [2:0] 	O_HSIZE,
    output [2:0] 	O_HBURST,
    
    input 		I_START,
    input 		I_SIZE,
    input [31:0] 	I_ADDR,
    input 		I_COUNT,
    input [31:0] 	I_PS_COUNT,
    input 		I_WRITE,
    input 		I_BUSY,
    input [7:0]		I_PIXEL_OUT_R,
    input [7:0]		I_PIXEL_OUT_G,
    input [7:0] 	I_PIXEL_OUT_B,
    input [7:0]		I_PIXEL_IN_R,
    input [7:0] 	I_PIXEL_IN_G,
    input [7:0] 	I_PIXEL_IN_B,
    input [7:0] 	I_PIXEL_OUT_0,
    input [7:0] 	I_PIXEL_OUT_1,
    input [7:0] 	I_PIXEL_OUT_2,
    input [7:0] 	I_PIXEL_OUT_3,
    input [7:0] 	I_PIXEL_IN_0,
    input [7:0] 	I_PIXEL_IN_1,
    input [7:0] 	I_PIXEL_IN_2,
    input [7:0] 	I_PIXEL_IN_3,
    

    input I_HRESET_N,
    input I_HCLK
);

endmodule 
