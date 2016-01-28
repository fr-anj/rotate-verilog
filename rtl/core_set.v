/*
* TODO: check if input is invalid
*	heigh limit = 32787 or 
*
* */

`timescale 1ns/1ps

module core_set (
    output reg [31:0] 	O_ADDR,
    output reg [2:0] 	O_SIZE,
    output reg	 	O_WRITE,
    output reg	 	O_BUSY,
    output reg [4:0] 	O_COUNT,

    input [14:0] 	I_HEIGHT,
    input [13:0] 	I_WIDTH,
    input 		I_DIRECTION,
    input [2:0] 	I_DEGREES,
    input 		I_DMA_READY,

    input 		I_START,
    input 		I_HRESET_N,
    input 		I_HCLK
);

//state
reg [1:0] curr_state;
reg [1:0] next_state;

parameter 	IDLE 	= 2'h0,
		READ 	= 2'h1,
		WRITE 	= 2'h2; 

parameter 	DEG_0 	= 2'h0,
		DEG_90 	= 2'h1,
		DEG_180 = 2'h2,
		DEG_270 = 2'h3;

//counters
reg [5:0] set_count; 	//count to 64 
reg [2:0] burst_count; 	//count to 8	
reg [15:0] height_count; //count to (I_HEIGHT - 1)

//image registers
reg [15:0] new_height;
reg [15:0] new_width;
wire [15:0] deficit_h;
wire [15:0] deficit_w;

//address manipulation
reg [15:0] col_address;
reg [15:0] row_address;
/*
reg [15:0] col_write_address;
reg [15:0] row_write_address;
reg [15:0] col_write_start;
reg [15:0] row_write_start;
reg [15:0] y_address;
reg [15:0] x_address;
*/

reg [15:0] col_0;
reg [30:0] col_90;
reg [30:0] col_180;
reg [30:0] col_270;
reg [30:0] row_0;
reg [30:0] row_90;
reg [30:0] row_180;
reg [30:0] row_270;

wire [30:0] col_90_start;
wire [30:0] col_180_start;
wire [30:0] col_270_start;
wire [30:0] row_90_start;
wire [30:0] row_180_start;
wire [30:0] row_270_start;

wire [31:0] out_0;
wire [31:0] out_90;
wire [31:0] out_180;
wire [31:0] out_270;

reg LAST_WRITE;

//flags
wire LAST;
wire ROW_DONE;
wire Y_DONE;

//arithmetic
wire [31:0] CHECK_LAST;
wire [31:0] TOTAL;
wire [15:0] REM; 
wire [14:0] HDIV;
wire [13:0] WDIV;
wire [2:0] HMOD;
wire [2:0] WMOD;
wire [15:0] WIDTH;

//wire assign
assign 	HDIV		= {I_HEIGHT[14:3],3'h0};

assign 	WDIV 		= {I_WIDTH[13:3],3'h0};

assign 	HMOD		= I_HEIGHT[2:0];

assign 	WMOD		= I_WIDTH[2:0];

assign 	deficit_h 	= 16'h0008 - {13'h0000,I_HEIGHT[2:0]};

assign 	deficit_w 	= 16'h0008 - {13'h0000,I_WIDTH[2:0]};

//2016-01-25
//assign 	ROW_DONE 	= (height_count == (I_HEIGHT - 1))? 1 : 0;
assign 	ROW_DONE 	=  (height_count == (new_height - 1))? 1 : 0;

//2016-01-25
//assign 	TOTAL 		= I_HEIGHT * I_WIDTH * 2'h3;
assign 	TOTAL 		= new_height * I_WIDTH * 2'h3;

assign 	REM 		= WMOD * 2'h3;

//2016-01-26
//assign 	CHECK_LAST	= TOTAL - 24; 
assign 	WIDTH 		= 2'h3 * I_WIDTH;

assign 	CHECK_LAST	= ((WMOD == 3'h0) && (HMOD == 3'h0))? TOTAL - WIDTH: TOTAL - REM;

assign 	LAST 		= (O_ADDR == CHECK_LAST)? 1 : 0;

assign col_90_start 	= 31'h00000000;
assign col_180_start 	= (WDIV - 1) * 8'h18;
assign col_270_start 	= col_180_start;
assign row_90_start 	= (I_HEIGHT - 4'h8) * I_WIDTH * 2'h3;
assign row_180_start	= col_90_start;
assign row_270_start	= 31'h00000000;

wire [23:0] row_dec;

assign row_dec = WIDTH * 4'hf;

assign out_0 		= row_0 + col_0;
assign out_90 		= row_90 + col_90;
assign out_180 		= row_180 + col_180;
assign out_270 		= row_270 + col_270;

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	LAST_WRITE <= 0;
    else 
	if (next_state == IDLE)
	    LAST_WRITE <= 0;
	else 
	    if (LAST)
		LAST_WRITE <= 1;
	    else
		LAST_WRITE <= LAST_WRITE;

//state transition
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	curr_state <= IDLE;
    else 
	curr_state <= next_state;

//state conditions
always @(*)
    if (!I_HRESET_N)
	next_state = IDLE;
    else 
	case (curr_state)
	    IDLE:
		if (I_START)
		    next_state = READ;
		else
		    next_state = IDLE;
	    READ:
		if (set_count == 6'h3f)
		    next_state = WRITE;
		else
		    next_state = READ;
	    WRITE:
		if (!LAST_WRITE)
		    if (set_count == 6'h3f)
			next_state = READ;
		    else 
			next_state = WRITE;
		else 
		    if (set_count == 6'h3f)
			next_state = IDLE;
		    else 
			next_state = WRITE;
	    default:
		next_state = IDLE;
	endcase

// output image height and width
always @(*)
    if (!I_HRESET_N)
    begin
	new_height = 16'h0000;
	new_width = 16'h0000;
    end
    else
    begin
	if ((I_HEIGHT & 16'h0007) == 16'h0000)
	    new_height = I_HEIGHT;
	else 
	    new_height = I_HEIGHT + deficit_h;
	if ((I_WIDTH & 16'h0007) == 16'h0000)
	    new_width = I_WIDTH;
	else 
	    new_width = I_WIDTH + deficit_w;
    end

//count to 64
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	set_count <= 6'h00;
    else 
	if (I_DMA_READY)
	    set_count <= set_count + 1;
	else 
	    set_count <= set_count;

//count to 8
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	burst_count <= 3'h0;
    else 
	if (I_DMA_READY)
	    burst_count <= burst_count + 1;
	else 
	    burst_count <= burst_count;

//count until it reaches I_HEIGHT - 1
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	height_count <= 16'h0000;
    else 
	case (next_state)
	    IDLE:
		height_count <= 16'h0000;
	    READ:
		if (ROW_DONE)
		    if (burst_count == 3'h7)
			height_count <= 16'h0000;
		    else 
			height_count <= height_count;
		else 
		    if (burst_count == 3'h7)
			height_count <= height_count + 1;
		    else 
			height_count <= height_count;
	    WRITE:
		height_count <= height_count;
	endcase

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	col_address <= 16'h0000;
    else
	case (next_state)
	    IDLE:
		col_address <= 16'h0000;
	    READ:
		if (LAST_WRITE)
		    if (burst_count == 3'h7)
			col_address <= 16'h0000;
		    else 
			col_address <= col_address;
		else 
		    if (ROW_DONE)
			if (burst_count == 3'h7)
			    col_address <= col_address + 24;
			else 
			    col_address <= col_address;
		    else
			col_address <= col_address;
	    WRITE:
		col_address <= col_address;
	endcase
	
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	row_address <= 16'h0000;
    else 
	case (next_state)
	    IDLE:
		row_address <= 16'h0000;
	    READ:
		if (LAST_WRITE)
		    if (burst_count == 3'h7)
			row_address <= 16'h0000;
		    else 
			row_address <= row_address;
		else 
		    if (ROW_DONE)
			if (burst_count == 3'h7)
			    row_address <= 16'h0000;
			else 
			    row_address <= row_address;
		    else 
			if (burst_count == 3'h7)
			    row_address <= row_address + WIDTH;
			else
			    row_address <= row_address;
	    WRITE:
		row_address <= row_address;
	endcase

/******************************************************************
******************************************************************/

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	col_0 <= 16'h0000;
    else
	case (next_state)
	    IDLE:
		col_0 <= 16'h0000;
	    READ:
		col_0 <= col_address;
	    WRITE:
		col_0 <= col_0;
	endcase
	
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	row_0 <= 16'h0000;
    else 
	case (next_state)
	    IDLE:
		row_0 <= 16'h0000;
	    READ:
		if (set_count == 6'h3f)
		    row_0 <= row_address;
		else 
		    row_0 <= row_0;
	    WRITE:
		if (LAST_WRITE)
		    row_0 <= 16'h0000;
		else 
		    if (burst_count == 3'h7)
			row_0 <= row_0 + WIDTH;
		    else 
			row_0 <= row_0;
	endcase

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	row_90 <= 16'h0000;
    else 
	case (next_state)
	    IDLE:
		row_90 <= row_90_start; 
	    READ:
		row_90 <= row_90;
	    WRITE:
		if (LAST_WRITE && set_count == 6'h3f)
		    row_90 <= 16'h0000;
		else 
		    if ((col_90 == col_180_start) && (set_count == 6'h3f))
			row_90 <= row_90 - row_dec;
		    else 
			if (burst_count == 3'h7)
			    row_90 <= row_90 + WIDTH;
			else 
			    row_90 <= row_90;
	endcase

always @(posedge I_HCLK)
    if (I_HRESET_N)
	col_90 <= 16'h0000;
    else 
	case (next_state)
	    IDLE:
		col_90 <= col_90_start;
	    READ:
		col_90 <= col_90;
	    WRITE:
		if (LAST_WRITE && set_count == 6'h3f)
		    col_90 <= 16'h0000;
		else 
		    if (ROW_DONE && set_count == 6'h3f)
			col_90 <= col_90_start;
		    else 
			if (set_count == 6'h3f)
			    col_90 <= col_90 + 24;
			else 
			    col_90 <= col_90;
	endcase

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	row_90 <= 16'h0000;
    else 
	case (next_state)
	    IDLE:
		row_90 <= row_90_start; 
	    READ:
		row_90 <= row_90;
	    WRITE:
		if (LAST_WRITE && set_count == 6'h3f)
		    row_90 <= 16'h0000;
		else 
		    if ((col_90 == col_180_start) && (set_count == 6'h3f))
			row_90 <= row_90 - row_dec;
		    else 
			if (burst_count == 3'h7)
			    row_90 <= row_90 + WIDTH;
			else 
			    row_90 <= row_90;
	endcase

always @(*)
    if (!I_HRESET_N)
	O_ADDR = 32'h00000000;
    else 
	case (curr_state)
	    READ:
		O_ADDR = row_address + col_address;
	    WRITE:
		if (I_DIRECTION)
		    case (I_DEGREES)
			DEG_0:
			    O_ADDR = out_0;
			DEG_90:
			    O_ADDR = out_90;
			DEG_180:
			    O_ADDR = out_180;
			DEG_270:
			    O_ADDR = out_270;
			default:
			    O_ADDR = out_0;
		    endcase
		else 
		    case (I_DEGREES)
			DEG_0:
			    O_ADDR = out_0;
			DEG_90:
			    O_ADDR = out_270;
			DEG_180:
			    O_ADDR = out_180;
			DEG_270:
			    O_ADDR = out_90;
			default:
			    O_ADDR = out_0;
		    endcase
	    default:
		O_ADDR = O_ADDR;
	endcase

endmodule
