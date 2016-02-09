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
    input [2:0]		I_SIZE,
    input [31:0] 	I_ADDR,
    input [4:0]		I_COUNT,
    //input [31:0] 	I_PS_COUNT,
    input 		I_WRITE,
    input 		I_BUSY,
    input [31:0] 	I_WDATA,
    input [31:0] 	I_HRDATA,
    input [7:0]		I_PIXEL_OUT_ADDRR,
    input [7:0]		I_PIXEL_OUT_ADDRG,
    input [7:0] 	I_PIXEL_OUT_ADDRB,
    input [7:0]		I_PIXEL_IN_ADDRR,
    input [7:0] 	I_PIXEL_IN_ADDRG,
    input [7:0] 	I_PIXEL_IN_ADDRB,
    input [7:0] 	I_PIXEL_OUT_ADDR0,
    input [7:0] 	I_PIXEL_OUT_ADDR1,
    input [7:0] 	I_PIXEL_OUT_ADDR2,
    input [7:0] 	I_PIXEL_OUT_ADDR3,
    input [7:0] 	I_PIXEL_IN_ADDR0,
    input [7:0] 	I_PIXEL_IN_ADDR1,
    input [7:0] 	I_PIXEL_IN_ADDR2,
    input [7:0] 	I_PIXEL_IN_ADDR3,
    
    input I_HGRANT,
    input I_HREADY,
    input I_HRESET_N,
    input I_HCLK
);

wire [7:0] PIXEL_R;
wire [7:0] PIXEL_G;
wire [7:0] PIXEL_B;

wire [31:0] DATA_READ_FROM_AHB;

    ahbif AHB (
    .O_HBUSREQ(O_HBUSREQ),
    .O_HADDR(O_HADDR),  
    .O_HTRANS(O_HTRANS), 
    .O_HWRITE(O_HWRITE), 
    .O_HSIZE(O_HSIZE),  
    .O_HBURST(O_HBURST), 
    .O_HWDATA(O_HWDATA), 
    .O_RDATA(DATA_READ_FROM_AHB),  
    .I_HRDATA(I_HRDATA),   
    .I_START(I_START),  
    .I_SIZE(I_SIZE), 
    .I_ADDR(I_ADDR),   
    .I_WDATA(I_WDATA),  
    .I_COUNT(I_COUNT),  
    .I_WRITE(I_WRITE),  
    .I_BUSY(I_BUSY),   
    .I_HGRANT(I_HGRANT),   
    .I_HREADY(I_HREADY),   
    .I_HRESET_N(I_HRESET_N),	
    .I_HCLK(I_HCLK)
    );		

    output_mem OUTBUFF (
    .O_WDATA(O_HWDATA),
    .I_PIXEL_B(PIXEL_B),
    .I_PIXEL_G(PIXEL_G),
    .I_PIXEL_R(PIXEL_R),
    .I_PIXEL_IN_ADDRB(I_PIXEL_IN_ADDRB),
    .I_PIXEL_IN_ADDRG(I_PIXEL_IN_ADDRG),
    .I_PIXEL_IN_ADDRR(I_PIXEL_IN_ADDRR),
    .I_PIXEL_OUT_ADDR0(I_PIXEL_OUT_ADDR0),
    .I_PIXEL_OUT_ADDR1(I_PIXEL_OUT_ADDR1),
    .I_PIXEL_OUT_ADDR2(I_PIXEL_OUT_ADDR2),
    .I_PIXEL_OUT_ADDR3(I_PIXEL_OUT_ADDR3),
    .I_HRESET_N(I_HRESET_N),
    .I_HCLK(I_HCLK)
    );

    input_mem INBUFF(
    .O_PIXEL_B(PIXEL_B),
    .O_PIXEL_G(PIXEL_G),
    .O_PIXEL_R(PIXEL_R),
    .I_HWDATA(DATA_READ_FROM_AHB),
    .I_PIXEL_IN_ADDR0(I_PIXEL_IN_ADDR0),
    .I_PIXEL_IN_ADDR1(I_PIXEL_IN_ADDR1),
    .I_PIXEL_IN_ADDR2(I_PIXEL_IN_ADDR2),
    .I_PIXEL_IN_ADDR3(I_PIXEL_IN_ADDR3),
    .I_PIXEL_OUT_ADDRB(I_PIXEL_OUT_ADDRB),
    .I_PIXEL_OUT_ADDRG(I_PIXEL_OUT_ADDRG),
    .I_PIXEL_OUT_ADDRR(I_PIXEL_OUT_ADDRR),
    .I_HRESET_N(I_HRESET_N),
    .I_HCLK(I_HCLK)
    );

endmodule 
