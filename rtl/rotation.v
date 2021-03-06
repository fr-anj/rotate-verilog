`timescale 1ns/1ps

module rotation (
    output [31:0] O_REG_PRDATA,
    output [31:0] O_DMA_HADDR,
    output [31:0] O_DMA_HWDATA,
    output [1:0] O_DMA_HTRANS,
    output [2:0] O_DMA_HSIZE,
    output [2:0] O_DMA_HBURST,
    output O_REG_PREADY,
    output O_DMA_HBUSREQ,
    output O_DMA_HWRITE,
    output O_INTR_DONE,

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

//register file to core
wire [31:0] DST_IMG;
wire [15:0] IMG_H;
wire [15:0] IMG_W;
wire [15:0] IMG_NEW_H;
wire [15:0] IMG_NEW_W;
wire [1:0] IMG_MODE;
wire IMG_DIR;
wire START; //also to DMA
wire RESET; //also to DMA

//dma to core
wire DMA_READY;

//core to dma
wire [31:0] ADDR;
wire [7:0] PIXEL_IN_ADDR0;
wire [7:0] PIXEL_IN_ADDR1;
wire [7:0] PIXEL_IN_ADDR2;
wire [7:0] PIXEL_IN_ADDR3;
wire [7:0] PIXEL_OUT_ADDR0;
wire [7:0] PIXEL_OUT_ADDR1;
wire [7:0] PIXEL_OUT_ADDR2;
wire [7:0] PIXEL_OUT_ADDR3;
wire [4:0] COUNT;
wire [2:0] SIZE;
wire WRITE;

    apbif REGISTER_FILE (
    .O_APBIF_PRDATA(O_REG_PRDATA), //module output
    .O_APBIF_PREADY(O_REG_PREADY), //module output 
    .O_APBIF_ROT_IMG_H(IMG_H), //to core set 
    .O_APBIF_ROT_IMG_W(IMG_W), //to core set 
    .O_APBIF_ROT_IMG_MODE(IMG_MODE), //to core set and core pixel
    .O_APBIF_ROT_IMG_DIR(IMG_DIR), //to core set and core pixel
    .O_APBIF_CTRL_START(START), //to core and dma
    .O_APBIF_CTRL_RESET(RESET), //SOFT RESET
    .I_APBIF_PADDR(I_REG_PADDR), //module input 
    .I_APBIF_PWDATA(I_REG_PWDATA), //module input 
    .I_APBIF_DMA_DST_IMG(DST_IMG),
    .I_APBIF_ROT_IMG_NEW_H(IMG_NEW_H), //from core set
    .I_APBIF_ROT_IMG_NEW_W(IMG_NEW_W), //from core set
    .I_APBIF_PSEL(I_REG_PSEL), //module input 
    .I_APBIF_PENABLE(I_REG_PENABLE), //module input 
    .I_APBIF_PWRITE(I_REG_PWRITE), // module input 
    .I_APBIF_PRESET_N(I_PRESET_N), //module input HARD RESET
    .I_APBIF_PCLK(I_PCLK) // module input PCLK
    );

    core_pixel CORE0 (
    .O_CP_PIXEL_IN_ADDR0(PIXEL_IN_ADDR0), //from core pixel
    .O_CP_PIXEL_IN_ADDR1(PIXEL_IN_ADDR1), //from core pixel
    .O_CP_PIXEL_IN_ADDR2(PIXEL_IN_ADDR2), //from core pixel
    .O_CP_PIXEL_IN_ADDR3(PIXEL_IN_ADDR3), //from core pixel
    .O_CP_PIXEL_OUT_ADDR0(PIXEL_OUT_ADDR0), //from core pixel
    .O_CP_PIXEL_OUT_ADDR1(PIXEL_OUT_ADDR1), //from core pixel
    .O_CP_PIXEL_OUT_ADDR2(PIXEL_OUT_ADDR2), //from core pixel
    .O_CP_PIXEL_OUT_ADDR3(PIXEL_OUT_ADDR3), //from core pixel
    .I_CP_STOP(O_INTR_DONE),
    .I_CP_DMA_READY(DMA_READY), //from DMA
    .I_CP_DEGREES(IMG_MODE), //from REGF
    .I_CP_DIRECTION(IMG_DIR), //from REGF
    .I_CP_HRESET_N(I_HRESET_N), //module input HARD RESET
    .I_CP_RESET(RESET),
    .I_CP_HCLK(I_HCLK) //module input HCLK
    );

    core_set CORE1 (
    .O_CS_ADDR(ADDR), //to DMA
    .O_CS_COUNT(COUNT), //to DMA
    .O_CS_SIZE(SIZE), //to DMA
    .O_CS_WRITE(WRITE), //to DMA
    .O_CS_NEW_H(IMG_NEW_H), //to REGF
    .O_CS_NEW_W(IMG_NEW_W), //to REGF
    .O_CS_INTR_DONE(O_INTR_DONE),
    .O_CS_DST_IMG(DST_IMG),
    .I_CS_DMA_READY(DMA_READY), //from DMA
    .I_CS_HEIGHT(IMG_H), //from REGF
    .I_CS_WIDTH(IMG_W), //from REGF
    .I_CS_DEGREES(IMG_MODE), //from REGF
    .I_CS_DIRECTION(IMG_DIR), //from REGF
    .I_CS_HRESET_N(I_HRESET_N), //module input HARD RESET
    .I_CS_RESET(RESET), //from REGF SOFT RESET
    .I_CS_HCLK(I_HCLK) //module input HCLK
    );

    dma DMA ( //TODO: output DMA_READY after HGRANT
    .O_DMA_HADDR(O_DMA_HADDR), //module output
    .O_DMA_HWDATA(O_DMA_HWDATA), //module output
    .O_DMA_HTRANS(O_DMA_HTRANS), //module output
    .O_DMA_HSIZE(O_DMA_HSIZE), //module output
    .O_DMA_HBURST(O_DMA_HBURST), //module output
    .O_DMA_HBUSREQ(O_DMA_HBUSREQ), //module output
    .O_DMA_HWRITE(O_DMA_HWRITE), //module output
    .O_DMA_READY(DMA_READY), //to core
    .I_DMA_STOP(O_INTR_DONE),
    .I_DMA_ADDR(ADDR), //from core set
    .I_DMA_HRDATA(I_DMA_HRDATA), // module input 
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
    .I_DMA_START(START), //from REGF
    .I_DMA_HGRANT(I_DMA_HGRANT), //module input 
    .I_DMA_HREADY(I_DMA_HREADY), //module input 
    .I_DMA_HRESET_N(I_HRESET_N), //module input HARD RESET
    .I_DMA_RESET(RESET), //from REGF SOFT RESET
    .I_DMA_HCLK (I_HCLK )// module input HCLK
    );

endmodule
