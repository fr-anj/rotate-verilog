`timescale 1ns/1ps

module tb_core_set();

    wire [31:0]	O_ADDR;      
    wire [2:0] 	O_SIZE;
    wire	O_WRITE;
    wire	O_BUSY;
    wire [4:0]	O_COUNT;
    //wire  	O_START;

    reg [15:0] 	I_HEIGHT;
    reg [15:0] 	I_WIDTH;
    reg 	I_DIRECTION;
    reg [2:0] 	I_DEGREES;
    reg       	I_DMA_READY;

    reg 	I_START;
    reg       	I_HRESET_N;
    reg       	I_HCLK;

    core_set U0 (
    .O_ADDR(O_ADDR),     
    .O_SIZE(O_SIZE),
    .O_WRITE(O_WRITE),     
    .O_BUSY(O_BUSY),
    .O_COUNT(O_COUNT),
    .I_START(I_START),
    .I_HEIGHT(I_HEIGHT),
    .I_WIDTH(I_WIDTH),
    .I_DIRECTION(I_DIRECTION),
    .I_DEGREES(I_DEGREES),
    .I_DMA_READY(I_DMA_READY),
    .I_HRESET_N(I_HRESET_N),
    .I_HCLK(I_HCLK)
    );

    //clock
    always 
	#1 I_HCLK <= ~I_HCLK;

    //initialization of inputs
    initial begin
	I_HEIGHT 	= 0;
	I_WIDTH 	= 0;
	I_DIRECTION 	= 0;
	I_DEGREES 	= 0;
	I_DMA_READY 	= 0;
	I_START 	= 0;
	I_HCLK 		= 0;
	I_HRESET_N	= 1;
    end

    //test
    initial begin
	$vcdpluson;
	
	I_WIDTH = 8;
	I_HEIGHT = 8;
	I_DIRECTION = 0;
	I_DEGREES = 1;
	
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

    repeat(500) @(posedge I_HCLK);

    @(posedge I_HCLK)
	begin
	    I_WIDTH = 62;
	    I_HEIGHT = 63;
	    I_DIRECTION = 0;
	    I_DEGREES = 1;
	end

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

    #20000;
    repeat(500) @(posedge I_HCLK);

    @(posedge I_HCLK)
	begin
	    I_WIDTH = 123;
	    I_HEIGHT = 5;
	    I_DIRECTION = 0;
	    I_DEGREES = 1;
	end

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

    #10000;
    repeat(500) @(posedge I_HCLK);

    @(posedge I_HCLK)
	begin
	    I_WIDTH = 32;
	    I_HEIGHT = 24;
	    I_DIRECTION = 0;
	    I_DEGREES = 1;
	end

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

	#10000 $finish;
    end

endmodule
