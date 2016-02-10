module rotation (
    output reg [31:0] O_REG_PRDATA,
    output reg [31:0] O_DMA_HADDR,
    output reg [31:0] O_DMA_HWDATA,
    output reg [1:0] O_HTRANS,
    output reg [2:0] O_HSIZE,
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
wire [7:0] O_PIXEL_IN_ADDR0;
wire [7:0] O_PIXEL_IN_ADDR1;
wire [7:0] O_PIXEL_IN_ADDR2;
wire [7:0] O_PIXEL_IN_ADDR3;
wire [7:0] O_PIXEL_OUT_ADDRB;
wire [7:0] O_PIXEL_OUT_ADDRG;
wire [7:0] O_PIXEL_OUT_ADDRR;
wire [7:0] O_PIXEL_OUT_ADDR0;
wire [7:0] O_PIXEL_OUT_ADDR1;
wire [7:0] O_PIXEL_OUT_ADDR2;
wire [7:0] O_PIXEL_OUT_ADDR3;
wire [7:0] O_PIXEL_IN_ADDRR;
wire [7:0] O_PIXEL_IN_ADDRG;
wire [7:0] O_PIXEL_IN_ADDRB;
wire [31:0] O_ADDR;
wire [2:0] O_SIZE;
wire O_WRITE;
wire O_BUSY;
wire [4:0] O_COUNT;

    apbif REGISTER_FILE (
    .O_PRDATA(O_REG_PRDATA),
    .O_PREADY(O_REG_PREADY),
    .O_DMA_SRC_IMG(O_DMA_SRC_IMG),
    .O_DMA_DST_IMG(O_DMA_DST_IMG),
    .O_ROT_IMG_H(I_HEIGHT),
    .O_ROT_IMG_W(I_WIDTH),
    .O_ROT_IMG_NEW_H(O_ROT_IMG_NEW_H),
    .O_ROT_IMG_NEW_W(O_ROT_IMG_NEW_W),
    .O_ROT_IMG_MODE(I_DEGREES),
    .O_ROT_IMG_DIR(I_DIRECTION),
    .O_CTRL_START(I_START),
    .O_CTRL_RESET(RESET),
    .O_CTRL_INTR_MASK(O_CTRL_INTR_MASK),
    .O_CTRL_BEF_MASK(O_CTRL_BEF_MASK),	
    .O_CTRL_AFT_MASK(O_CTRL_AFT_MASK),	
    .O_CTRL_INTR_CLEAR(O_CTRL_INTR_CLEAR),
    .O_CTRL_BUSY(O_CTRL_BUSY),		
    .I_ROT_IMG_NEW_H(I_ROT_IMG_NEW_H),
    .I_ROT_IMG_NEW_W(I_ROT_IMG_NEW_W),
    .I_CTRL_BEF_MASK(I_CTRL_BEF_MASK),
    .I_CTRL_AFT_MASK(I_CTRL_AFT_MASK),
    .I_CTRL_BUSY(I_CTRL_BUSY),
    .I_PSEL(I_REG_PSEL),
    .I_PENABLE(I_REG_PENABLE),
    .I_PWRITE(I_REG_PWRITE),
    .I_PADDR(I_REG_PADDR),
    .I_PWDATA(I_REG_PWDATA),
    .I_PRESET_N(I_PRESET_N),
    .I_PCLK(I_PCLK)
    );

    core_pixel CORE0 (
    .O_PIXEL_IN_ADDR0(O_PIXEL_IN_ADDR0),
    .O_PIXEL_IN_ADDR1(O_PIXEL_IN_ADDR1),
    .O_PIXEL_IN_ADDR2(O_PIXEL_IN_ADDR2),
    .O_PIXEL_IN_ADDR3(O_PIXEL_IN_ADDR3),
    .O_PIXEL_OUT_ADDRB(O_PIXEL_OUT_ADDRB),
    .O_PIXEL_OUT_ADDRG(O_PIXEL_OUT_ADDRG),
    .O_PIXEL_OUT_ADDRR(O_PIXEL_OUT_ADDRR),
    .O_PIXEL_OUT_ADDR0(O_PIXEL_OUT_ADDR0),
    .O_PIXEL_OUT_ADDR1(O_PIXEL_OUT_ADDR1),
    .O_PIXEL_OUT_ADDR2(O_PIXEL_OUT_ADDR2),
    .O_PIXEL_OUT_ADDR3(O_PIXEL_OUT_ADDR3),
    .O_PIXEL_IN_ADDRR(O_PIXEL_IN_ADDRR),
    .O_PIXEL_IN_ADDRG(O_PIXEL_IN_ADDRG),
    .O_PIXEL_IN_ADDRB(O_PIXEL_IN_ADDRB),
    .I_HEIGHT(I_HEIGHT),	
    .I_WIDTH(I_WIDTH),	
    .I_DIRECTION(I_DIRECTION),
    .I_DEGREES(I_DEGREES),
    .I_DMA_READY(I_DMA_READY),
    .I_START(I_START),
    .I_HRESET_N(I_HRESET_N),
    .I_HCLK(I_HCLK)
    );

    core_set CORE1 (
    .O_ADDR(O_ADDR),
    .O_SIZE(O_SIZE),
    .O_WRITE(O_WRITE),
    .O_BUSY(O_BUSY),
    .O_COUNT(O_COUNT),
    .I_HEIGHT(I_HEIGHT),
    .I_WIDTH(I_WIDTH),
    .I_DIRECTION(I_DIRECTION),
    .I_DEGREES(I_DEGREES),
    .I_DMA_READY(I_DMA_READY),
    .I_START(I_START),
    .I_HRESET_N(I_HRESET_N),
    .I_HCLK(I_HCLK)
    );

    dmac DMA (
    .O_DMA_READY(),
    .O_HBUSREQ(O_HBUSREQ),
    .O_HADDR(),
    .O_HWDATA(),
    .O_HTRANS(),
    .O_HWRITE(),
    .O_HSIZE(),
    .O_HBURST(),
    .I_START(O_START),
    .I_SIZE(O_SIZE),
    .I_ADDR(O_ADDR),
    .I_COUNT(O_COUNT),
    .I_WRITE(I_WRITE),
    .I_BUSY(I_BUSY),
    .I_HRDATA(I_HRDATA),
    .I_PIXEL_OUT_ADDRR(O_PIXEL_OUT_ADDRR),
    .I_PIXEL_OUT_ADDRG(O_PIXEL_OUT_ADDRG),
    .I_PIXEL_OUT_ADDRB(O_PIXEL_OUT_ADDRB),
    .I_PIXEL_IN_ADDRR(O_PIXEL_IN_ADDRR),
    .I_PIXEL_IN_ADDRG(O_PIXEL_IN_ADDRG),
    .I_PIXEL_IN_ADDRB(O_PIXEL_IN_ADDRB),
    .I_PIXEL_OUT_ADDR0(O_PIXEL_OUT_ADDR0),
    .I_PIXEL_OUT_ADDR1(O_PIXEL_OUT_ADDR1),
    .I_PIXEL_OUT_ADDR2(O_PIXEL_OUT_ADDR2),
    .I_PIXEL_OUT_ADDR3(O_PIXEL_OUT_ADDR3),
    .I_PIXEL_IN_ADDR0(O_PIXEL_IN_ADDR0),
    .I_PIXEL_IN_ADDR1(O_PIXEL_IN_ADDR1),
    .I_PIXEL_IN_ADDR2(O_PIXEL_IN_ADDR2),
    .I_PIXEL_IN_ADDR3(O_PIXEL_IN_ADDR3),
    .I_HGRANT(I_DMA_HGRANT),
    .I_HREADY(I_DMA_HREADY),
    .I_HRESET_N(I_HRESET_N),
    .I_HCLK(I_HCLK)
    );

endmodule
