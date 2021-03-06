`timescale 1ns/1ps

module dma (
    output [31:0] O_DMA_HADDR,
    output [31:0] O_DMA_HWDATA,
    output [1:0] O_DMA_HTRANS,
    output [2:0] O_DMA_HSIZE,
    output [2:0] O_DMA_HBURST,
    output O_DMA_HBUSREQ,
    output O_DMA_HWRITE,
    output O_DMA_READY,
    
    input [31:0] I_DMA_ADDR,
    input [31:0] I_DMA_HRDATA,
    input [7:0] I_DMA_PIXEL_OUT_ADDR0,
    input [7:0] I_DMA_PIXEL_OUT_ADDR1,
    input [7:0] I_DMA_PIXEL_OUT_ADDR2,
    input [7:0] I_DMA_PIXEL_OUT_ADDR3,
    input [7:0] I_DMA_PIXEL_IN_ADDR0,
    input [7:0] I_DMA_PIXEL_IN_ADDR1,
    input [7:0] I_DMA_PIXEL_IN_ADDR2,
    input [7:0] I_DMA_PIXEL_IN_ADDR3,
    input [4:0] I_DMA_COUNT,
    input [2:0] I_DMA_SIZE,
    input I_DMA_STOP,
    input I_DMA_WRITE,
    input I_DMA_START,
    input I_DMA_HGRANT,
    input I_DMA_HREADY,
    input I_DMA_HRESET_N, //hard reset
    input I_DMA_RESET, //soft reset
    input I_DMA_HCLK
);

wire [31:0] DATA_WRITE_TO_AHB;

    ahbif AHB (
    .O_AHBIF_HBUSREQ(O_DMA_HBUSREQ),
    .O_AHBIF_HADDR(O_DMA_HADDR),  
    .O_AHBIF_HTRANS(O_DMA_HTRANS), 
    .O_AHBIF_HWRITE(O_DMA_HWRITE), 
    .O_AHBIF_HSIZE(O_DMA_HSIZE),  
    .O_AHBIF_HBURST(O_DMA_HBURST), 
    .O_AHBIF_HWDATA(O_DMA_HWDATA), 
    .O_AHBIF_READY(O_DMA_READY), //asserts during first NSEQ state
    .I_AHBIF_STOP(I_DMA_STOP),
    //.I_AHBIF_HRDATA(I_DMA_HRDATA),   
    .I_AHBIF_START(I_DMA_START),  
    .I_AHBIF_SIZE(I_DMA_SIZE), 
    .I_AHBIF_ADDR(I_DMA_ADDR),   
    .I_AHBIF_WDATA(DATA_WRITE_TO_AHB),  
    .I_AHBIF_COUNT(I_DMA_COUNT),  
    .I_AHBIF_WRITE(I_DMA_WRITE),  
    .I_AHBIF_HGRANT(I_DMA_HGRANT),   
    .I_AHBIF_HREADY(I_DMA_HREADY),   
    .I_AHBIF_RESET(I_DMA_RESET),	
    .I_AHBIF_HRESET_N(I_DMA_HRESET_N),	
    .I_AHBIF_HCLK(I_DMA_HCLK)
    );		

    input_mem INBUFF(
    .O_IMEM_WDATA(DATA_WRITE_TO_AHB),
    .I_IMEM_PIXEL_OUT_ADDR0(I_DMA_PIXEL_OUT_ADDR0),
    .I_IMEM_PIXEL_OUT_ADDR1(I_DMA_PIXEL_OUT_ADDR1),
    .I_IMEM_PIXEL_OUT_ADDR2(I_DMA_PIXEL_OUT_ADDR2),
    .I_IMEM_PIXEL_OUT_ADDR3(I_DMA_PIXEL_OUT_ADDR3),
    .I_IMEM_WRITE(~I_DMA_WRITE), //enable input buffer write
    .I_IMEM_RDATA(I_DMA_HRDATA),
    .I_IMEM_PIXEL_IN_ADDR0(I_DMA_PIXEL_IN_ADDR0),
    .I_IMEM_PIXEL_IN_ADDR1(I_DMA_PIXEL_IN_ADDR1),
    .I_IMEM_PIXEL_IN_ADDR2(I_DMA_PIXEL_IN_ADDR2),
    .I_IMEM_PIXEL_IN_ADDR3(I_DMA_PIXEL_IN_ADDR3),
    .I_IMEM_HRESET_N(I_DMA_HRESET_N),
    .I_IMEM_HCLK(I_DMA_HCLK)
    );

endmodule 
