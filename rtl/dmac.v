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
.HBUSREQ,
.HADDR,	
.HTRANS,   
.HWRITE,   
.HSIZE,	   
.HBURST,   
.HWDATA,   
.O_RDATA,  
.HRDATA,  
.I_START, 
.I_SIZE, 
.I_ADDR,   
.I_WDATA,  
.I_COUNT,  
.I_WRITE,  
.I_BUSY,   
.HGRANT,
.HREADY,
.HRESETN_N,
.HCLK
);		

endmodule 
