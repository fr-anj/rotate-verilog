`timescale 1ns/1ps

module tb_apb;

    wire [31:0] O_PRDATA;
    wire 	O_PREADY;
    
    reg 	I_PSEL;
    reg 	I_PENABLE;
    reg 	I_PWRITE;
    reg [31:0] 	I_PADDR;
    reg [31:0] 	I_PWDATA;
    reg 	I_PRESET_N;
    reg 	I_PCLK;

    wire [31:0]	O_DMA_SRC_IMG;
    wire [31:0]	O_DMA_DST_IMG;
    wire [15:0]	O_ROT_IMG_H;
    wire [15:0]	O_ROT_IMG_W;
    wire [15:0]	O_ROT_IMG_NEW_H;	// TODO: make input from core
    wire [15:0]	O_ROT_IMG_NEW_W;	// TODO: make input from core
    wire [1:0] 	O_ROT_IMG_MODE;
    wire       	O_ROT_IMG_DIR;
    wire       	O_CTRL_START;
    wire       	O_CTRL_RESET;
    wire       	O_CTRL_INTR_MASK;
    wire       	O_CTRL_BEF_MASK;	// TODO: confirm if read by core
    wire       	O_CTRL_AFT_MASK;	// TODO: confirm if read by core
    wire       	O_CTRL_INTR_CLEAR;
    wire       	O_CTRL_BUSY;		// TODO: make input from core 
   
    reg [15:0] I_ROT_IMG_NEW_H;
    reg [15:0] I_ROT_IMG_NEW_W;
    reg I_CTRL_BEF_MASK;
    reg I_CTRL_AFT_MASK;
    reg I_CTRL_BUSY;

    apbif APB0 (
    .O_DMA_SRC_IMG(O_DMA_SRC_IMG),
    .O_DMA_DST_IMG(O_DMA_DST_IMG),
    .O_ROT_IMG_H(O_ROT_IMG_H),
    .O_ROT_IMG_W(O_ROT_IMG_W),
    .O_ROT_IMG_NEW_H(O_ROT_IMG_NEW_H),
    .O_ROT_IMG_NEW_W(O_ROT_IMG_NEW_W),
    .O_ROT_IMG_MODE(O_ROT_IMG_MODE),
    .O_ROT_IMG_DIR(O_ROT_IMG_DIR),
    .O_CTRL_START(O_CTRL_START),
    .O_CTRL_RESET(O_CTRL_RESET),
    .O_CTRL_INTR_MASK(O_CTRL_INTR_MASK),
    .O_CTRL_BEF_MASK(O_CTRL_BEF_MASK),
    .O_CTRL_AFT_MASK(O_CTRL_AFT_MASK),
    .O_CTRL_INTR_CLEAR(O_CTRL_INTR_CLEAR),
    .O_CTRL_BUSY(O_CTRL_BUSY),
    .O_PRDATA(O_PRDATA),
    .O_PREADY(O_PREADY),

    .I_ROT_IMG_NEW_H(I_ROT_IMG_NEW_H),
    .I_ROT_IMG_NEW_W(I_ROT_IMG_NEW_W),
    .I_CTRL_BEF_MASK(I_CTRL_BEF_MASK),
    .I_CTRL_AFT_MASK(I_CTRL_AFT_MASK),
    .I_CTRL_BUSY(I_CTRL_BUSY),

    .I_PSEL(I_PSEL),
    .I_PENABLE(I_PENABLE),
    .I_PWRITE(I_PWRITE),
    .I_PADDR(I_PADDR),
    .I_PWDATA(I_PWDATA),
    .I_PRESET_N(I_PRESET_N),
    .I_PCLK(I_PCLK)
    );

    initial begin
	I_PCLK = 0; 
	I_PRESET_N = 1;
	I_PSEL = 0;
	I_PENABLE = 0;
	I_PWRITE = 0;
	I_PADDR = 0;
	I_PWDATA = 0;
    end

    always 
	#1 I_PCLK = ~I_PCLK;

    always 
	repeat(10) @(posedge I_PCLK)
	    I_PSEL <= ~ I_PSEL;

    initial begin
	$vcdpluson;
	$vcdplusmemon;

    //initalize bus#########
	@(posedge I_PCLK)
	    I_PRESET_N <= 0;

	@(posedge I_PCLK)
	    I_PENABLE <= 1;
    //######################

    //DMA_SRC_IMG###########
	@(posedge I_PCLK)
	    begin
	    I_PADDR <= 0;
	    I_PWDATA <= 20;
	    I_PWRITE <= 1;
	    end
    //######################

    //DMA_DST_IMG###########
	@(posedge I_PCLK)
	    begin
	    I_PADDR <= 4;
	    I_PADDR <= 7000;
	    I_PADDR <= 1;
	    end
    //######################

	#500 $finish;
    end

endmodule
