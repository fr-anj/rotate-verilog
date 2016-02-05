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

//AHB interface =========== from ahbif to OUT
wire HBUSREQ;		
wire HWRITE;   	 	
wire HGRANT;		
wire HREADY;
wire HRESETN_N;
wire HCLK;	   
wire [31:0] HADDR;	
wire [1:0] HTRANS;   
wire [2:0] HSIZE;	   
wire [2:0] HBURST;   
wire [31:0] HWDATA;  
wire [31:0] RDATA;  
wire [31:0] HRDATA; 

//control wires
wire START; 
wire WRITE;  
wire BUSY;   
wire [2:0] SIZE; 
wire [31:0] ADDR;  
wire [31:0] WDATA;  
wire [5:0] COUNT;  

ahbif AHBIF0 (
O_PRDATA,
O_PREADY,
O_INTERRUPT,
O_DMA_SRC_IMG,
O_DMA_DST_IMG,
O_ROT_IMG_H,
O_ROT_IMG_W,
O_ROT_IMG_NEW_H,
O_ROT_IMG_NEW_W,
O_ROT_IMG_MODE,
O_ROT_IMG_DIR,
O_CTRL_START,
O_CTRL_RESET,
O_CTRL_INTR_MASK,
O_CTRL_BEF_MASK,	
O_CTRL_AFT_MASK,	
O_CTRL_INTR_CLEAR,
O_CTRL_BUSY,		
I_ROT_IMG_NEW_H,
I_ROT_IMG_NEW_W,
I_CTRL_BEF_MASK,
I_CTRL_AFT_MASK,
I_CTRL_BUSY,
I_PSEL,
I_PENABLE,
I_PWRITE,
I_PADDR,
I_PWDATA,
I_PRESET_N,
I_PCLK
);		

endmodule 
