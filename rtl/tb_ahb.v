`timescale 1ns/1ps

module tb_ahb;

	wire 		HBUSREQ;
	wire [31:0]	HADDR;
	wire [1:0]	HTRANS;
    wire        HWRITE;
    wire [2:0]  HSIZE;
    wire [2:0]  HBURST;
    wire [31:0] HWDATA;
    wire [31:0] O_RDATA;

    reg [31:0] 	HRDATA;

	reg 		I_START;
	reg [2:0]	I_SIZE;
	reg [31:0]	I_ADDR;
	reg [31:0]	I_WDATA;
	reg [4:0]	I_COUNT;
	reg 		I_WRITE;
	reg 		I_BUSY;
	reg 		HGRANT;
	reg 		HREADY;
	reg 		HRESETN;
	reg 		HCLK;

	ahbif U0 (
	.HBUSREQ(HBUSREQ),
	.HADDR(HADDR),
	.HTRANS(HTRANS),
    .HWRITE(HWRITE),
    .HSIZE(HSIZE),
    .HBURST(HBURST),
    .HWDATA(HWDATA),
    .O_RDATA(O_RDATA),
    .HRDATA(HRDATA),
	.I_START(I_START),
	.I_SIZE(I_SIZE),
	.I_ADDR(I_ADDR),
	.I_WDATA(I_WDATA),
	.I_COUNT(I_COUNT),
	.I_WRITE(I_WRITE),
	.I_BUSY(I_BUSY),
	.HGRANT(HGRANT),
	.HREADY(HREADY),
	.HRESETN_N(HRESETN),
	.HCLK(HCLK)
	);

	integer i;

	parameter 	SINGLE 	= 3'b000,
				INCR 	= 3'b001,
				INCR4	= 3'b011,
				INCR8	= 3'b101,
				INCR16	= 3'b111;

	parameter 	B8 	= 3'b000,
				B16	= 3'b001,
				B32 = 3'b010;

	//initialize inputs
	initial begin
		HCLK 	= 0;
		I_START	= 0;
		I_SIZE	= 0;
		I_ADDR	= 0;
		I_WDATA	= 0;
		I_COUNT	= 0;
		I_WRITE	= 0;
		I_BUSY	= 0;
		HGRANT	= 0;
		HREADY	= 0;
		HRESETN	= 0;
	end

	always @(posedge HCLK)
		if (!HWRITE && (HTRANS != 0))
			HRDATA <= $random;
		else 
			HRDATA <= 32'h00000000;

	always 
		#10 HCLK = ~HCLK;

	initial begin
		$vcdpluson;

//---------------------------------initialize
//-------------------------------------------

		@(posedge HCLK)
			HRESETN <= 0;
		repeat(5) @(posedge HCLK);

		@(posedge HCLK)
			HRESETN <= 1;
			I_START <= 1;
		repeat(2) @(posedge HCLK);

		@(posedge HCLK)
			HREADY <= 1;
		repeat(2) @(posedge HCLK);

//-------------------------single-transaction
//-------------------------------------------

		@(posedge HCLK)
			HGRANT <= 1;
			I_SIZE <= B8;
			I_ADDR <= 1024; 
			I_COUNT <= 1;
			I_WRITE <= 1;
			I_BUSY <= 0;
		@(posedge HCLK)
			I_WDATA <= 64;
		@(posedge HCLK);

//--------------------------1kb-address-limit
//-----------------------------8-bit-transfer
//-------------------------------------------

		@(posedge HCLK)
			HGRANT 	<= 1;
			I_SIZE 	<= B8;
			I_ADDR 	<= 1022; 
			I_COUNT <= 4;
			I_WRITE <= 1;
			I_BUSY 	<= 0;
		@(posedge HCLK)
			I_WDATA <= 32'h00000012;
		repeat(4)
			begin
				@(posedge HCLK)
					I_WDATA <= I_WDATA + 4;
			end
	
//--------------------------1kb-address-limit
//----------------------------16-bit-transfer
//-------------------------------------------

		@(posedge HCLK)
			HGRANT 	<= 1;
			I_SIZE 	<= B16;
			I_ADDR 	<= 32'h000003fc; 
			I_COUNT <= 4;
			I_WRITE <= 1;
			I_BUSY 	<= 0;
		@(posedge HCLK)
			I_WDATA <= 4;
		repeat(4)
			begin
				@(posedge HCLK)
					I_WDATA <= I_WDATA + 4;
			end

//--------------------------1kb-address-limit
//----------------------------32-bit-transfer
//-------------------------------------------

		@(posedge HCLK)
			HGRANT 	<= 1;
			I_SIZE 	<= B32;
			I_ADDR 	<= 32'h000003fc; 
			I_COUNT <= 4;
			I_WRITE <= 1;
			I_BUSY 	<= 0;
		@(posedge HCLK)
			I_WDATA <= 4;
		repeat(4)
			begin
				@(posedge HCLK)
					I_WDATA <= I_WDATA + 4;
			end

//--------------------------1kb-address-limit
//---------------------------INCR-transaction
//-------------------------------------------

		@(posedge HCLK)
			HGRANT 	<= 1;
			I_SIZE 	<= B32;
			I_ADDR 	<= 32'h000003fc; 
			I_COUNT <= 6;
			I_WRITE <= 1;
			I_BUSY 	<= 0;
		@(posedge HCLK)
			I_WDATA <= 4;
		repeat(6)
			begin
				@(posedge HCLK)
					I_WDATA <= I_WDATA + 4;
			end

//--------------------------wrong-hsize-given
//-------------------------single-transaction
//-------------------------------------------

		@(posedge HCLK)
			HGRANT <= 1;
			I_SIZE <= 3;
			I_ADDR <= 12;
			I_COUNT <= 1;
			I_WRITE <= 1;
			I_BUSY <= 0;
		@(posedge HCLK)
			I_WDATA <= 255;
		@(posedge HCLK);

//--------------------------wrong-hsize-given
//------------------------------INC4-transfer
//-------------------------------------------

		@(posedge HCLK)
			HGRANT <= 1;
			I_SIZE <= 3;
			I_ADDR <= 12;
			I_COUNT <= 4;
			I_WRITE <= 1;
			I_BUSY <= 0;
		@(posedge HCLK)
			I_WDATA <= 255;
		repeat(4) 
			begin
				@(posedge HCLK)	
					I_WDATA <= I_WDATA + 4;
			end	

//--------------------------wrong-hsize-given
//------------------------------INC8-transfer
//-------------------------------------------

		@(posedge HCLK)
			HGRANT <= 1;
			I_SIZE <= 3;
			I_ADDR <= 12;
			I_COUNT <= 8;
			I_WRITE <= 1;
			I_BUSY <= 0;
		@(posedge HCLK)
			I_WDATA <= 255;
		repeat(8) 
			begin
				@(posedge HCLK)	
					I_WDATA <= I_WDATA + 4;
			end	

//--------------------------wrong-hsize-given
//-----------------------------INC16-transfer
//-------------------------------------------

		@(posedge HCLK)
			HGRANT <= 1;
			I_SIZE <= 3;
			I_ADDR <= 12;
			I_COUNT <= 16;
			I_WRITE <= 1;
			I_BUSY <= 0;
		@(posedge HCLK)
			I_WDATA <= 255;
		repeat(16) 
			begin
				@(posedge HCLK)
					I_WDATA <= I_WDATA + 4;
			end

//--------------------------wrong-hsize-given
//------------------------------INCR-transfer
//-------------------------------------------

		@(posedge HCLK)
			HGRANT <= 1;
			I_SIZE <= 3;
			I_ADDR <= 12;
			I_COUNT <= 6;
			I_WRITE <= 1;
			I_BUSY <= 0;
		@(posedge HCLK)
			I_WDATA <= 255;
		repeat(6) 
			begin
				@(posedge HCLK)
					I_WDATA <= I_WDATA + 4;
			end

//------------------------------busy-asserted
//-------------------------will-not-cross-1kb
//-------------------------------------------

		@(posedge HCLK)
			HGRANT 	<= 1;
			I_SIZE 	<= B32;
			I_ADDR 	<= 32'h00000000; 
			I_COUNT <= 4;
			I_WRITE <= 1;
			I_BUSY 	<= 0;
		@(posedge HCLK)
			I_WDATA <= 4;
		@(posedge HCLK)
			I_BUSY <= 1;
		@(posedge HCLK)
			I_BUSY <= 0;
		repeat(2)
			begin
				@(posedge HCLK)
					I_WDATA <= I_WDATA + 4;
			end

//------------------------------busy-asserted
//-----------------------------will-cross-1kb
//-------------------------------------------

		@(posedge HCLK)
			HGRANT 	<= 1;
			I_SIZE 	<= B32;
			I_ADDR 	<= 32'h000003fc; 
			I_COUNT <= 4;
			I_WRITE <= 1;
			I_BUSY 	<= 0;
		@(posedge HCLK)
			I_WDATA <= 4;
		@(posedge HCLK)
			I_BUSY <= 1;
		@(posedge HCLK)
			I_BUSY <= 0;
		@(posedge HCLK);
		repeat(2)
			begin
				@(posedge HCLK)
					I_WDATA <= I_WDATA + 4;
			end

//------------------------------busy-asserted
//-----------------------------will-cross-1kb
//-------------------------------------------

		@(posedge HCLK)
			HGRANT 	<= 1;
			I_SIZE 	<= B32;
			I_ADDR 	<= 32'h000003fc; 
			I_COUNT <= 4;
			I_WRITE <= 1;
			I_BUSY 	<= 0;
		@(posedge HCLK)
			I_WDATA <= 4;
		@(posedge HCLK)
			HREADY <= 0;
		@(posedge HCLK)
			HREADY <= 1;

//-------------------------------------HGRANT
//---------------------------------not-HREADY
//-------------------------------------------

		@(posedge HCLK)
			HREADY 	<= 0;
			HGRANT 	<= 1;
			I_SIZE 	<= B32;
			I_ADDR 	<= 32'h000003fc; 
			I_COUNT <= 4;
			I_WRITE <= 1;
			I_BUSY 	<= 0;
		@(posedge HCLK)
			I_WDATA <= 4;
		repeat (4) @(posedge HCLK)

//---------------------------------not-HGRANT
//-------------------------------------HREADY
//-------------------------------------------

		@(posedge HCLK)
			HREADY 	<= 1;
			HGRANT 	<= 0;
			I_SIZE 	<= B32;
			I_ADDR 	<= 32'h000003fc; 
			I_COUNT <= 4;
			I_WRITE <= 1;
			I_BUSY 	<= 0;
		@(posedge HCLK)
			I_WDATA <= 4;
		repeat (4) @(posedge HCLK)

//############################################
//############################################

//---------------------------------------READ
//-----------------------------8-bit-transfer
//-------------------------------------------

		@(posedge HCLK)
			HGRANT 	<= 1;
			I_SIZE 	<= B8;
			I_ADDR 	<= 1022; 
			I_COUNT <= 4;
			I_WRITE <= 0;
			I_BUSY 	<= 0;
		@(posedge HCLK)
			I_WDATA <= 32'h00000012;
		repeat(4)
			begin
				@(posedge HCLK)
					I_WDATA <= I_WDATA + 4;
			end
	
//--------------------------------------WRITE
//----------------------------16-bit-transfer
//-------------------------------------------

		@(posedge HCLK)
			HGRANT 	<= 1;
			I_SIZE 	<= B16;
			I_ADDR 	<= 32'h000003fc; 
			I_COUNT <= 4;
			I_WRITE <= 1;
			I_BUSY 	<= 0;
		@(posedge HCLK)
			I_WDATA <= 4;
		repeat(4)
			begin
				@(posedge HCLK)
					I_WDATA <= I_WDATA + 4;
			end

//---------------------------------------READ
//----------------------------32-bit-transfer
//-------------------------------------------

		@(posedge HCLK)
			HGRANT 	<= 1;
			I_SIZE 	<= B32;
			I_ADDR 	<= 32'h000003fc; 
			I_COUNT <= 4;
			I_WRITE <= 0;
			I_BUSY 	<= 0;
		@(posedge HCLK)
			I_WDATA <= 4;
		repeat(4)
			begin
				@(posedge HCLK)
					I_WDATA <= I_WDATA + 4;
			end

//--------------------------------------WRITE
//---------------------------INCR-transaction
//-------------------------------------------

		@(posedge HCLK)
			HGRANT 	<= 1;
			I_SIZE 	<= B32;
			I_ADDR 	<= 32'h000003fc; 
			I_COUNT <= 6;
			I_WRITE <= 1;
			I_BUSY 	<= 0;
		@(posedge HCLK)
			I_WDATA <= 4;
		repeat(6)
			begin
				@(posedge HCLK)
					I_WDATA <= I_WDATA + 4;
			end

//############################################
//############################################

//---------------------------end-transmission
//-------------------------------------------

		//repeat(3) @(posedge HCLK);

		@(posedge HCLK)
			HRESETN <= 0;
		#3000 $finish;
	end
endmodule