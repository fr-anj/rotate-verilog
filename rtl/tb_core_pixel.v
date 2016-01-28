`timescale 1ns/1ps

module tb_core_pixel ();

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
    wire [7:0] O_PIXEL_IN_ADDRB;
    wire [7:0] O_PIXEL_IN_ADDRG;
    wire [7:0] O_PIXEL_IN_ADDRR;

    reg [15:0] I_HEIGHT;
    reg [15:0] I_WIDTH;
    reg 	 I_DIRECTION;
    reg [1:0]	 I_DEGREES;
    reg 	 I_DMA_READY;
    reg 	 I_START;

    reg 	 I_HRESET_N;
    reg 	 I_HCLK;

core_pixel U0 (
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
.O_PIXEL_IN_ADDRB(O_PIXEL_IN_ADDRB),
.O_PIXEL_IN_ADDRG(O_PIXEL_IN_ADDRG),
.O_PIXEL_IN_ADDRR(O_PIXEL_IN_ADDRR),

.I_HEIGHT(I_HEIGHT),
.I_WIDTH(I_WIDTH),
.I_DIRECTION(I_DIRECTION),
.I_DEGREES(I_DEGREES),
.I_DMA_READY(I_DMA_READY),
.I_START(I_START),
.I_HRESET_N(I_HRESET_N),
.I_HCLK(I_HCLK)
  );

always 
    #1 I_HCLK <= ~I_HCLK;

initial begin
    //TODO: write initialization here..
    I_HEIGHT = 0;
    I_WIDTH = 0;
    I_DIRECTION = 0;
    I_DEGREES = 0;
    I_DMA_READY = 0;
    I_START = 0;
    I_HRESET_N = 1;
    I_HCLK = 0;
end

initial begin
    $vcdpluson;
    //TODO: write test here..

    //SET UP-----------------
    //SQUARE IMAGE, H & W DIVISIBLE BY 8
    I_HEIGHT = 8;
    I_WIDTH = 8;
    I_DEGREES = 1; //90
    I_DIRECTION = 0; //CW

    //start sequence
    @(posedge I_HCLK)
	I_HRESET_N <= 0;

    @(posedge I_HCLK)
	I_HRESET_N <= 1;

    @(posedge I_HCLK)
	    I_START <= 1;
    
    @(posedge I_HCLK)
	I_START <= 0;

    @(posedge I_HCLK)
	I_DMA_READY <= 1;
    
    #3000;
    $finish;
end

endmodule
