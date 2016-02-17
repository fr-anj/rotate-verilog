/*=============================================================
*   Copyright (C) Since2015 KYOCERA Document Solutions Inc. All Rights Reserved
*
*   SecurityLevel:A(Can read only in System Devise Developmentdivision)
*   If those who do not belong to the above division find this document, 
*   please inform System Device Development division.
*
*   File Name: core_set.v
*   Author: Angelique Francia
*   Contained module: core_set
*   Abstract: calculates new address of the pixel when rotated 
*   Reference Doc: 
*   Tab letter num: 4
*
*   Version History:
*   Date        Name            Version Description
*   ------------------------------------------------------------
*   2016.02.15    A.Francia       1.0     First Implementation.
*==============================================================*/
`timescale 1ns/1ps

module dma (
    output [31:0] O_DMA_HADDR,
    output [31:0] O_DMA_HWDATA,
    output [1:0] O_DMA_HTRANS,
    output [2:0] O_DMA_HSIZE,
    output [2:0] O_DMA_HBURST,
    output O_DMA_HBUSREQ,
    output O_DMA_HWRITE,
    
    input [31:0] I_DMA_ADDR,
    input [31:0] I_DMA_HRDATA,
    input [7:0]	I_DMA_PIXEL_OUT_ADDRR,
    input [7:0]	I_DMA_PIXEL_OUT_ADDRG,
    input [7:0] I_DMA_PIXEL_OUT_ADDRB,
    input [7:0]	I_DMA_PIXEL_IN_ADDRR,
    input [7:0] I_DMA_PIXEL_IN_ADDRG,
    input [7:0] I_DMA_PIXEL_IN_ADDRB,
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
    input I_DMA_WRITE,
    input I_DMA_START,
    input I_DMA_HGRANT,
    input I_DMA_HREADY,
    input I_DMA_HRESET_N,
    input I_DMA_HCLK
);

wire [7:0] PIXEL_R;
wire [7:0] PIXEL_G;
wire [7:0] PIXEL_B;

wire [31:0] DATA_READ_FROM_AHB;
wire [31:0] DATA_WRITE_TO_AHB;

    ahbif AHB (
    .O_AHB_HBUSREQ(O_DMA_HBUSREQ),
    .O_AHB_HADDR(O_DMA_HADDR),  
    .O_AHB_HTRANS(O_DMA_HTRANS), 
    .O_AHB_HWRITE(O_DMA_HWRITE), 
    .O_AHB_HSIZE(O_DMA_HSIZE),  
    .O_AHB_HBURST(O_DMA_HBURST), 
    .O_AHB_HWDATA(O_DMA_HWDATA), 
    .O_AHB_RDATA(DATA_READ_FROM_AHB),  
    .I_AHB_HRDATA(I_DMA_HRDATA),   
    .I_AHB_START(I_DMA_START),  
    .I_AHB_SIZE(I_DMA_SIZE), 
    .I_AHB_ADDR(I_DMA_ADDR),   
    .I_AHB_WDATA(DATA_WRITE_TO_AHB),  
    .I_AHB_COUNT(I_DMA_COUNT),  
    .I_AHB_WRITE(I_DMA_WRITE),  
    .I_AHB_HGRANT(I_DMA_HGRANT),   
    .I_AHB_HREADY(I_DMA_HREADY),   
    .I_AHB_HRESET_N(I_DMA_HRESET_N),	
    .I_AHB_HCLK(I_DMA_HCLK)
    );		

    output_mem OUTBUFF (
    .O_AHB_WDATA(DATA_WRITE_TO_AHB),
    .I_AHB_PIXEL_B(PIXEL_B),
    .I_AHB_PIXEL_G(PIXEL_G),
    .I_AHB_PIXEL_R(PIXEL_R),
    .I_AHB_PIXEL_IN_ADDRB(I_DMA_PIXEL_IN_ADDRB),
    .I_AHB_PIXEL_IN_ADDRG(I_DMA_PIXEL_IN_ADDRG),
    .I_AHB_PIXEL_IN_ADDRR(I_DMA_PIXEL_IN_ADDRR),
    .I_AHB_PIXEL_OUT_ADDR0(I_DMA_PIXEL_OUT_ADDR0),
    .I_AHB_PIXEL_OUT_ADDR1(I_DMA_PIXEL_OUT_ADDR1),
    .I_AHB_PIXEL_OUT_ADDR2(I_DMA_PIXEL_OUT_ADDR2),
    .I_AHB_PIXEL_OUT_ADDR3(I_DMA_PIXEL_OUT_ADDR3),
    .I_AHB_HRESET_N(I_DMA_HRESET_N),
    .I_AHB_HCLK(I_DMA_HCLK)
    );

    input_mem INBUFF(
    .O_AHB_PIXEL_B(PIXEL_B),
    .O_AHB_PIXEL_G(PIXEL_G),
    .O_AHB_PIXEL_R(PIXEL_R),
    .I_AHB_RDATA(DATA_READ_FROM_AHB),
    .I_AHB_PIXEL_IN_ADDR0(I_DMA_PIXEL_IN_ADDR0),
    .I_AHB_PIXEL_IN_ADDR1(I_DMA_PIXEL_IN_ADDR1),
    .I_AHB_PIXEL_IN_ADDR2(I_DMA_PIXEL_IN_ADDR2),
    .I_AHB_PIXEL_IN_ADDR3(I_DMA_PIXEL_IN_ADDR3),
    .I_AHB_PIXEL_OUT_ADDRB(I_DMA_PIXEL_OUT_ADDRB),
    .I_AHB_PIXEL_OUT_ADDRG(I_DMA_PIXEL_OUT_ADDRG),
    .I_AHB_PIXEL_OUT_ADDRR(I_DMA_PIXEL_OUT_ADDRR),
    .I_AHB_HRESET_N(I_DMA_HRESET_N),
    .I_AHB_HCLK(I_DMA_HCLK)
    );

endmodule 
