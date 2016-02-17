`timescale 1ns/1ps

module rotation (
    output reg [31:0] O_REG_PRDATA,
    output reg [31:0] O_DMA_HADDR,
    output reg [31:0] O_DMA_HWDATA,
    output reg [1:0] O_DMA_HTRANS,
    output reg [2:0] O_DMA_HSIZE,
    output reg [3:0] O_DMA_HBURST,
    output reg O_DMA_HBUSREQ,
    output reg O_DMA_HWRITE,
    output reg O_INTR_DONE,

    input [31:0] I_REG_PADDR,
    input [31:0] I_REG_PWDATA,
    input [31:0] I_DMA_HRDATA,
    input I_REG_PSEL,
    input I_REG_PENABLE,
    input I_REG_PWRITE,
    input I_DMA_HGRANT,
    input I_DMA_HREADY,
    input I_PRESET_N,
    input I_HRESET_N,
    input I_PCLK,
    input I_HCLK
);

wire RESET;

//register file to core
wire SRC_IMG;
wire DST_IMG;
wire IMG_H;
wire IMG_W;
wire IMG_NEW_H;
wire IMG_NEW_W;
wire IMG_MODE;
wire IMG_DIR;
wire START; //also to DMA
wire RESET; //also to DMA
wire INTR_MASK;
wire BEF_MASK; 
wire AFT_MASK;  
wire INTR_CLEAR;

//core to dma
wire [31:0] ADDR;
wire [7:0] PIXEL_IN_ADDR0;
wire [7:0] PIXEL_IN_ADDR1;
wire [7:0] PIXEL_IN_ADDR2;
wire [7:0] PIXEL_IN_ADDR3;
wire [7:0] PIXEL_OUT_ADDRB;
wire [7:0] PIXEL_OUT_ADDRG;
wire [7:0] PIXEL_OUT_ADDRR;
wire [7:0] PIXEL_OUT_ADDR0;
wire [7:0] PIXEL_OUT_ADDR1;
wire [7:0] PIXEL_OUT_ADDR2;
wire [7:0] PIXEL_OUT_ADDR3;
wire [7:0] PIXEL_IN_ADDRR;
wire [7:0] PIXEL_IN_ADDRG;
wire [7:0] PIXEL_IN_ADDRB;
wire [4:0] COUNT;
wire [2:0] SIZE;
wire WRITE;

    apbif REGISTER_FILE (
    .O_APBIF_PRDATA(O_REG_PRDATA), //module output
    .O_APBIF_PREADY(O_REG_PREADY), //module output 
    .O_APBIF_DMA_SRC_IMG(SRC_IMG),
    .O_APBIF_DMA_DST_IMG(DST_IMG),
    .O_APBIF_ROT_IMG_H(IMG_H),
    .O_APBIF_ROT_IMG_W(IMG_W),
    .O_APBIF_ROT_IMG_NEW_H(IMG_NEW_H),
    .O_APBIF_ROT_IMG_NEW_W(IMG_NEW_W),
    .O_APBIF_ROT_IMG_MODE(IMG_MODE),
    .O_APBIF_ROT_IMG_DIR(IMG_DIR),
    .O_APBIF_CTRL_START(START),
    .O_APBIF_CTRL_RESET(RESET),
    .I_APBIF_PADDR(I_REG_PADDR), //module input 
    .I_APBIF_PWDATA(I_REG_PWDATA), //module input 
    .I_APBIF_ROT_IMG_NEW_H, 
    .I_APBIF_ROT_IMG_NEW_W,
    .I_APBIF_CTRL_BEF_MASK,
    .I_APBIF_CTRL_AFT_MASK,
    .I_APBIF_PSEL(I_REG_PSEL), //module input 
    .I_APBIF_PENABLE(I_REG_PENABLE), //module input 
    .I_APBIF_PWRITE(I_REG_PWRITE), // module input 
    .I_APBIF_PRESET_N(I_PRESET_N), //module input HARD RESET
    .I_APBIF_PCLK(I_PCLK) // module input 
    );

    core_pixel CORE0 (
    .O_CP_PIXEL_IN_ADDR0(PIXEL_IN_ADDR0), //from core pixel
    .O_CP_PIXEL_IN_ADDR1(PIXEL_IN_ADDR1), //from core pixel
    .O_CP_PIXEL_IN_ADDR2(PIXEL_IN_ADDR2), //from core pixel
    .O_CP_PIXEL_IN_ADDR3(PIXEL_IN_ADDR3), //from core pixel
    .O_CP_PIXEL_OUT_ADDRB(PIXEL_OUT_ADDRB), //from core pixel
    .O_CP_PIXEL_OUT_ADDRG(PIXEL_OUT_ADDRG), //from core pixel
    .O_CP_PIXEL_OUT_ADDRR(PIXEL_OUT_ADDRR), //from core pixel
    .O_CP_PIXEL_OUT_ADDR0(PIXEL_OUT_ADDR0), //from core pixel
    .O_CP_PIXEL_OUT_ADDR1(PIXEL_OUT_ADDR1), //from core pixel
    .O_CP_PIXEL_OUT_ADDR2(PIXEL_OUT_ADDR2), //from core pixel
    .O_CP_PIXEL_OUT_ADDR3(PIXEL_OUT_ADDR3), //from core pixel
    .O_CP_PIXEL_IN_ADDRR(PIXEL_IN_ADDRR), //from core pixel
    .O_CP_PIXEL_IN_ADDRG(PIXEL_IN_ADDRG), //from core pixel
    .O_CP_PIXEL_IN_ADDRB(PIXEL_IN_ADDRB), //from core pixel
    .I_CP_HEIGHT(IMG_H), //from REGF
    .I_CP_WIDTH(IMG_W), //from REGF
    .I_CP_DEGREES(IMG_MODE), //from REGF
    .I_CP_DIRECTION(IMG_DIR), //from REGF
    .I_CP_START(START),
    .I_CP_HRESET_N(I_HRESET_N), //module input HARD RESET
    .I_CP_HCLK(I_HCLK) //module input 
    );

    core_set CORE1 (
    .O_CS_ADDR(ADDR), //to DMA
    .O_CS_COUNT(COUNT), //to DMA
    .O_CS_SIZE(SIZE), //to DMA
    .O_CS_WRITE(WRITE), //to DMA
    .I_CS_HEIGHT(IMG_H), //from REGF
    .I_CS_WIDTH(IMG_W), //from REGF
    .I_CS_DEGREES(IMG_MODE), //from REGF
    .I_CS_DIRECTION(IMG_DIR), //from REGF
    .I_CS_START(START), //from REGF
    .I_CS_HRESET_N(I_HRESET_N), //module input HARD RESET
    .I_CS_HCLK(I_HCLK) //module input 
    );

    dmac DMA (
    .O_DMA_HADDR(O_DMA_HADDR), //module output
    .O_DMA_HWDATA(O_DMA_HWDATA), //module output
    .O_DMA_HTRANS(O_DMA_HTRANS), //module output
    .O_DMA_HSIZE(O_DMA_HSIZE), //module output
    .O_DMA_HBURST(O_DMA_HBURST), //module output
    .O_DMA_HBUSREQ(O_DMA_HBUSREQ), //module output
    .O_DMA_HWRITE(O_DMA_HWRITE), //module output
    .I_DMA_ADDR(I_DMA_ADDR)(ADDR), //from core set
    .I_DMA_HRDATA(I_DMA_HRDATA), // module input 
    .I_DMA_PIXEL_OUT_ADDRR(PIXEL_OUT_ADDRR), //from core pixel
    .I_DMA_PIXEL_OUT_ADDRG(PIXEL_OUT_ADDRG), //from core pixel
    .I_DMA_PIXEL_OUT_ADDRB(PIXEL_OUT_ADDRB), //from core pixel
    .I_DMA_PIXEL_IN_ADDRR(PIXEL_IN_ADDRR), //from core pixel
    .I_DMA_PIXEL_IN_ADDRG(PIXEL_IN_ADDRG), //from core pixel
    .I_DMA_PIXEL_IN_ADDRB(PIXEL_IN_ADDRB), //from core pixel
    .I_DMA_PIXEL_OUT_ADDR0(PIXEL_OUT_ADDR0), //from core pixel
    .I_DMA_PIXEL_OUT_ADDR1(PIXEL_OUT_ADDR1), //from core pixel
    .I_DMA_PIXEL_OUT_ADDR2(PIXEL_OUT_ADDR2), //from core pixel
    .I_DMA_PIXEL_OUT_ADDR3(PIXEL_OUT_ADDR3), //from core pixel
    .I_DMA_PIXEL_IN_ADDR0(PIXEL_IN_ADDR0), //from core pixel
    .I_DMA_PIXEL_IN_ADDR1(PIXEL_IN_ADDR1), //from core pixel
    .I_DMA_PIXEL_IN_ADDR2(PIXEL_IN_ADDR2), //from core pixel
    .I_DMA_PIXEL_IN_ADDR3(PIXEL_IN_ADDR3), //from core pixel
    .I_DMA_COUNT(COUNT), //from core set
    .I_DMA_SIZE(SIZE), //from core set
    .I_DMA_WRITE(WRITE), //from core set
    .I_DMA_START(I_DMA_START), //from REGF
    .I_DMA_HGRANT(I_DMA_HGRANT), //module input 
    .I_DMA_HREADY(I_DMA_HREADY), //module input 
    .I_DMA_HRESET_N(I_HRESET_N), //module input
    .I_DMA_HCLK (I_HCLK )// module input
    );

endmodule
