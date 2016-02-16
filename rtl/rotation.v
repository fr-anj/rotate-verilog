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
wire I_START;
wire I_DIRECTION;
wire [1:0] I_DEGREES;
wire [15:0] I_HEIGHT;
wire [15:0] I_WIDTH;

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
wire [4:0] O_COUNT;
wire [2:0] SIZE;
wire WRITE;
wire BUSY;

    apbif REGISTER_FILE (

    );

    core_pixel CORE0 (
    );

    core_set CORE1 (
    );

    dmac DMA (
    );

endmodule
