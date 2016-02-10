/*
* TODO: check if input is invalid
*	heigh limit = 32787 or 
*
* */

`timescale 1ns/1ps

module core_set (
    output reg [31:0] 	O_ADDR,
    output reg [2:0] 	O_SIZE,
    output reg 		O_WRITE,
    output reg	 	O_BUSY,
    output reg [4:0] 	O_COUNT,

    input [15:0] 	I_HEIGHT,
    input [15:0] 	I_WIDTH,
    input 		I_DIRECTION,
    input [1:0] 	I_DEGREES,
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

//registers
reg [16:0] new_height;
reg [16:0] new_width;

//counters
reg [5:0] set_count; 	//count to 64 
reg [2:0] burst_count; 	//count to 8	
reg [11:0] hdiv_count; 	//count to HDIV
reg [11:0] wdiv_count; //count to WDIV

//addresses
reg [17:0] row; 	//read row
reg [17:0] col; 	//read column
reg [17:0] row0; 	//read row
reg [17:0] col0; 	//read column
reg [17:0] row90; 	//read row
reg [17:0] col90; 	//read column
reg [17:0] row180; 	//read row
reg [17:0] col180; 	//read column
reg [17:0] row270; 	//read row
reg [17:0] col270; 	//read column

//address decrement or increment
reg [23:0] dec90; 	//decrement 
reg [23:0] dec180;	//decrement
reg [23:0] inc270;	//increment

//signals
reg LAST_HDIV;
reg LAST_WDIV;
reg FIRST;

//height and width properties
wire [17:0] HEIGHT;
wire [17:0] WIDTH;
//wire [18:0] N_HEIGHT;
//wire [18:0] N_WIDTH;
wire [12:0] HDIV;
wire [12:0] WDIV;
wire [2:0] HMOD;
wire [2:0] WMOD;
wire [4:0] HDEFICIT;
wire [4:0] WDEFICIT;

//temp
wire [15:0] temp1;
wire [15:0] temp2;
wire [13:0] HDIVMIN;
wire [13:0] WDIVMIN;

//address manipulation
wire [23:0] START_90;
wire [23:0] ROWDEC_90;
wire [23:0] START_180;
wire [23:0] ROWDEC_180;
wire [23:0] COL_180;
wire [15:0] COLDEC_180;
wire [23:0] ROWINC_270;
wire [23:0] COL_270;

//flags 
wire STOP_ROT; 	//when input image is bigger than max
wire LAST; 	//when last pixel set is processed 
//wire LAST_HDIV; //when hdiv_count reaches HDIV - 1
//wire LAST_WDIV; //when wdiv_count reaches WDIV - 1

//out_addressput
wire [31:0] out_address;
wire [31:0] out_address0;
wire [31:0] out_address90;
wire [31:0] out_address180;
wire [31:0] out_address270;

assign HEIGHT = I_HEIGHT * 2'h3;
assign WIDTH = I_WIDTH * 2'h3;
//assign N_HEIGHT = new_height * 2'h3;
//assign N_WIDTH = new_width * 2'h3;

assign HDIV = new_height[15:3];
assign WDIV = new_width[15:3];

assign HMOD = I_HEIGHT[2:0];
assign WMOD = I_WIDTH[2:0];

assign HDEFICIT = 4'h8 - {1'b0,HMOD};
assign WDEFICIT = 4'h8 - {1'b0,WMOD};

assign temp1 = (new_width - 4'h8) * {2'h0,I_HEIGHT};
assign START_90 = temp1 * 2'h3;
assign ROWDEC_90 = HEIGHT * 4'h8;

assign temp2 = (new_height - 4'h8) * {2'h0,I_WIDTH};
assign START_180 = temp2 * 2'h3;
assign ROWDEC_180 = WIDTH * 4'h8;
assign COL_180 = WDIV * 5'h18;

assign HDIVMIN = HDIV - 1;
assign WDIVMIN = WDIV - 1;
assign COL_270 = HDIVMIN * 5'h18; 
assign ROWINC_270 = ROWDEC_90;

assign STOP_ROT = (I_HEIGHT[15] || (I_WIDTH[15:14] != 2'h0))? 1 : 0;
//assign LAST_HDIV = (hdiv_count == HDIV)? 1 : 0;
//assign LAST_WDIV = (wdiv_count == WDIV - 1)? 1: 0;
assign LAST = (LAST_HDIV && LAST_WDIV)? 1 : 0;

assign out_address = row + col;
assign out_address0 = row0 + col0;
assign out_address90 = row90 + col90;
assign out_address180 = row180 + col180;
assign out_address270 = row270 + col270;

always @(*)
    if (!I_HRESET_N)
	O_SIZE = 3'h0;
    else
	O_SIZE = 3'h2; //32 bit

always @(*)
    if (!I_HRESET_N)
	O_WRITE = 0;
    else 
	if (curr_state == WRITE)
	    O_WRITE = 1;
	else 
	    O_WRITE = 0;

always @(*)
    if (!I_HRESET_N)
	O_COUNT = 5'h00;
    else 
	O_COUNT = 5'h06; //6 bursts INCR

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	FIRST <= 0;
    else 
	case (next_state)
	    IDLE:
		FIRST <= 0;
	    READ:
		if (row == 16'h0000)
		    FIRST <= 1;
		else 
		    FIRST <= FIRST;
	    WRITE:
		FIRST <= 0;
	endcase

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	LAST_HDIV <= 0;
    else 
	if ((hdiv_count == HDIVMIN[11:0]) && (set_count == 6'h3e))
	    LAST_HDIV <= 1;
	else 
	    LAST_HDIV <= 0;

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	LAST_WDIV <= 0;
    else 
	if ((wdiv_count == WDIVMIN[11:0]) && (set_count == 6'h3e))
	    LAST_WDIV <= 1;
	else 
	    LAST_WDIV <= 0;

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
		if (STOP_ROT)
		    next_state = IDLE;
		else 
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
		if (LAST)
		    if (set_count == 6'h3f)
			next_state = IDLE;
		    else 
			next_state = WRITE;
		else 
		    if (set_count == 6'h3f)
			next_state = READ;
		    else 
			next_state = WRITE;
	    default:
		next_state = IDLE;
	endcase

// out_addressput image height 
always @(*)
    if (!I_HRESET_N)
	new_height = 16'h0000;
    else
	if ((I_HEIGHT & 16'h0007) == 16'h0000)
	    new_height = I_HEIGHT;
	else 
	    new_height = I_HEIGHT + {11'h000,HDEFICIT};

// out_addressput image height 

always @(*)
    if (!I_HRESET_N)
	new_width = 16'h0000;
    else
	if ((I_WIDTH & 16'h0007) == 16'h0000)
	    new_width = I_WIDTH;
	else 
	    new_width = I_WIDTH + {11'h000,WDEFICIT};

//count to 64
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	set_count <= 6'h00;
    else 
	if (curr_state == IDLE)
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
	if (curr_state == IDLE)
	    burst_count <= 3'h0;
	else
	    if (I_DMA_READY)
		burst_count <= burst_count + 1;
	    else 
		burst_count <= burst_count;

//count to HDIV
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	hdiv_count <= 12'h000;
    else 
	case (next_state)
	    IDLE:
		hdiv_count <= 12'h000;
	    READ:
		if (!LAST_HDIV)
		    if (set_count == 6'h3f)
			hdiv_count <= hdiv_count + 1;
		    else 
			hdiv_count <= hdiv_count;
		else 
		    if (set_count == 6'h3f)
			hdiv_count <= 12'h000;
		    else 
			hdiv_count <= hdiv_count;
	    WRITE:
		hdiv_count <= hdiv_count;
	endcase

//count to WDIV
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	wdiv_count <= 12'h000;
    else 
	case (next_state)
	    IDLE:
		wdiv_count <= 12'h000;
	    READ:
		if (!LAST_WDIV)
		    if (LAST_HDIV && (set_count == 6'h3f))
			wdiv_count <= wdiv_count + 1;
		    else 
			wdiv_count <= wdiv_count;
		else 
		    if (LAST_HDIV && (set_count == 6'h3f))
			wdiv_count <= 12'h000;
		    else 
			wdiv_count <= wdiv_count;
	    WRITE:
		wdiv_count <= wdiv_count;
	endcase 
		
//*****************************************************//
//*****************************************************//
//*****************************************************//

//current read row
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	row <= 16'h0000;
    else 
	case (next_state)
	    IDLE:
		row <= 16'h0000;
	    READ:
		    if (LAST_HDIV && (set_count == 6'h3f))
			row <= 16'h0000;
		    else 
			if (burst_count == 3'h7)
			    row <= row + WIDTH;
			else 
			    row <= row;
	    WRITE:
		row <= row;
	endcase

//current read column 
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	col <= 16'h0000;
    else 
	case (next_state)
	    IDLE:
		col <= 16'h0000;
	    READ:
		if (!LAST_WDIV)
		    if (LAST_HDIV && (set_count == 6'h3f))
			col <= col + 24;
		    else 
			col <= col;
		else 
		    if (LAST_HDIV && (set_count == 6'h3f))
			col <= 16'h0000;
		    else 
			col <= col;
	    WRITE:
		col <= col;
	endcase

//*****************************************************//
//*****************************************************//
//*****************************************************//

//current read row
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	row0 <= 16'h0000;
    else 
	case (next_state)
	    IDLE:
		row0 <= 16'h0000;
	    READ:
		row0 <= row0;
	    WRITE:
		if (FIRST)
		    row0 <= 16'h0000;
		else 
		    if (burst_count == 3'h7)
			row0 <= row0 + WIDTH;
		    else 
			row0 <= row0;
	endcase

//current read column 
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	col0 <= 16'h0000;
    else 
	case (next_state)
	    IDLE:
		col0 <= 16'h0000;
	    READ:
		if (!LAST_WDIV)
		    if (LAST_HDIV && (set_count == 6'h3f))
			col0 <= col0 + 24;
		    else 
			col0 <= col0;
		else 
		    if (LAST_HDIV && (set_count == 6'h3e))
			col0 <= 16'h0000;
		    else 
			col0 <= col0;
	    WRITE:
		col0 <= col0;
	endcase

//*****************************************************//
//*****************************************************//
//*****************************************************//

//current read column 
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	dec90 <= 16'h0000;
    else 
	case (next_state)
	    IDLE:
		dec90 <= 16'h0000;
	    READ:
		if (!LAST_WDIV)
		    if (LAST_HDIV && (set_count == 6'h3f))
			dec90 <= dec90 + ROWDEC_90;
		    else 
			dec90 <= dec90;
		else 
		    if (LAST_HDIV && (set_count == 6'h3e))
			dec90 <= 16'h0000;
		    else 
			dec90 <= dec90;
	    WRITE:
		dec90 <= dec90;
	endcase

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	row90 <= 16'h0000;
    else 
	case (next_state)
	    IDLE:
		row90 <= 16'h0000;
	    READ:
		row90 <= row90;
	    WRITE:
		if (FIRST || (set_count == 6'h3f))
		    row90 <= START_90 - dec90;
		else
		    if (burst_count == 3'h7)
			row90 <= row90 + HEIGHT;
		    else 
			row90 <= row90;
	endcase

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	col90 <= 16'h0000;
    else 
	case (next_state)
	    IDLE:
		col90 <= 16'h0000;
	    READ:
		col90 <= col90;
	    WRITE:
		if (FIRST)
		    col90 <= 16'h0000;
		else 
		    if (set_count == 6'h3f)
			col90 <= col90 + 24;
		    else 
			col90 <= col90;
	endcase

//*****************************************************//
//*****************************************************//
//*****************************************************//

//current read column 
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	dec180 <= 16'h0000;
    else 
	case (next_state)
	    IDLE:
		dec180 <= 16'h0000;
	    READ:
		if (LAST_HDIV)
		    dec180 <= 16'h0000;
		else 
		    if (set_count == 6'h3f)
			dec180 <= dec180 +  ROWDEC_180;
		    else 
			dec180 <= dec180;
	    WRITE:
		dec180 <= dec180;
	endcase

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	row180 <= 16'h0000;
    else
	case (next_state)
	    IDLE:
		row180 <= 16'h0000;
	    READ:
		row180 <= row180;
	    WRITE:
		if (set_count == 6'h3f)
		    row180 <= START_180 - dec180;
		else 
		    if (burst_count == 3'h7) 
			row180 <= row180 + WIDTH;
		    else 
			row180 <= row180;
	endcase

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	col180 <= 16'h0000;
    else 
	case (next_state)
	    IDLE:
		col180 <= COL_180;
	    READ:
		col180 <= col180;
	    WRITE:
		if (FIRST)
		    col180 <= col180 - 24;
		else 
		    col180 <= col180;
	endcase

//*****************************************************//
//*****************************************************//
//*****************************************************//
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	inc270 <= 16'h0000;
    else 
	case (next_state)
	    IDLE:
		inc270 <= 16'h0000;
	    READ:
		if (!LAST_WDIV)
		    if (LAST_HDIV && (set_count == 6'h3f))
			inc270 <= inc270 + ROWINC_270;
		    else 
			inc270 <= inc270;
		else 
		    if (LAST_HDIV && (set_count == 6'h3e))
			inc270 <= 16'h0000;
		    else 
			inc270 <= inc270;
	    WRITE:
		inc270 <= inc270;
	endcase

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	row270 <= 16'h0000; 
    else
	case (next_state)
	    IDLE:
		row270 <= 16'h0000;
	    READ:
		row270 <= row270;
	    WRITE:
		if (set_count == 6'h3f)
		    row270 <= inc270;
		else
		    if (burst_count == 3'h7)
			row270 <= row270 + HEIGHT;
		    else 
			row270 <= row270;
	endcase

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	col270 <= 16'h0000;
    else 
	case (next_state)
	    IDLE:
		col270 <= 16'h0000;
	    READ:
		col270 <= col270;
	    WRITE:
		if (FIRST)
		    col270 <= COL_270;
		else 
		    if (set_count == 6'h3f)
			col270 <= col270 - 5'h18;
		    else 
			col270 <= col270;
	endcase

//*****************************************************//
//*****************************************************//
//*****************************************************//

always @(*)
    if (!I_HRESET_N)
	O_ADDR = 32'h00000000;
    else 
	case (curr_state)
	    READ:
		O_ADDR = out_address;
	    WRITE:
		if (I_DIRECTION)
		    case (I_DEGREES)
			DEG_0:
			    O_ADDR = out_address0;
			DEG_90:
			    O_ADDR = out_address90;
			DEG_180:
			    O_ADDR = out_address180;
			DEG_270:
			    O_ADDR = out_address270;
			default:
			    O_ADDR = out_address;
		    endcase
		else 
		    case (I_DEGREES)
			DEG_0:
			    O_ADDR = out_address0; 
			DEG_90:
			    O_ADDR = out_address270;
			DEG_180:
			    O_ADDR = out_address180; 
			DEG_270:
			    O_ADDR = out_address90;
			default:
			    O_ADDR = out_address; 
		    endcase
	    default:
		O_ADDR = 32'h00000000;
	endcase

endmodule
