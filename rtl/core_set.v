`timescale 1ns/1ps

module core_set (
    output reg [31:0] O_CS_ADDR,
    output reg O_CS_WRITE,
    output [4:0] O_CS_COUNT,
    output [2:0] O_CS_SIZE,
    output [15:0] O_CS_NEW_H, 
    output [15:0] O_CS_NEW_W, 


    input [15:0] I_CS_HEIGHT,
    input [15:0] I_CS_WIDTH,
    input [1:0] I_CS_DEGREES,
    input I_CS_DIRECTION,
    input I_CS_START,
    input I_CS_HRESET_N,
    input I_CS_RESET,
    input I_CS_HCLK
);

//state
reg [1:0] curr_state;
reg [1:0] next_state;

parameter 	P_IDLE 	= 2'h0,
		P_READ 	= 2'h1,
		P_WRITE 	= 2'h2; 

parameter 	P_DEG_0 	= 2'h0,
		P_DEG_90 	= 2'h1,
		P_DEG_180 = 2'h2,
		P_DEG_270 = 2'h3;

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
reg [17:0] row0; 	
reg [17:0] col0;	
reg [17:0] row90;
reg [17:0] col90; 	
reg [17:0] row180; 	
reg [17:0] col180; 	
reg [17:0] row270; 	
reg [17:0] col270; 	

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
wire [18:0] N_HEIGHT;
wire [18:0] N_WIDTH;
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
wire [23:0] ROWINC_270;
wire [23:0] COL_270;

//flags 
wire STOP_ROT; 	//when input image is bigger than max
wire LAST; 	//when last pixel set is processed 

//out_addressput
wire [31:0] out_address;
wire [31:0] out_address0;
wire [31:0] out_address90;
wire [31:0] out_address180;
wire [31:0] out_address270;

assign HEIGHT = (I_CS_HEIGHT << 1) + I_CS_HEIGHT;
assign WIDTH = (I_CS_WIDTH << 1) + I_CS_WIDTH;
assign N_HEIGHT = (new_height << 1) + new_height;
assign N_WIDTH = (new_width << 1) + new_width;

assign HDIV = new_height[15:3];
assign WDIV = new_width[15:3];

assign HMOD = I_CS_HEIGHT[2:0];
assign WMOD = I_CS_WIDTH[2:0];

assign HDEFICIT = 4'h8 - {1'b0,HMOD};
assign WDEFICIT = 4'h8 - {1'b0,WMOD};

assign temp1 = (new_width - 4'h8) * {2'h0,I_CS_HEIGHT};
assign START_90 = (temp1 << 1) + temp1;
assign ROWDEC_90 = HEIGHT << 3; 

assign temp2 = (new_height - 4'h8) * {2'h0,I_CS_WIDTH};
assign START_180 = (temp2 << 1) + temp2;
assign ROWDEC_180 = WIDTH << 3; //WIDTH * 8
assign COL_180 = (WDIV << 4) + (WDIV << 3); //WDIV * 24

assign HDIVMIN = HDIV - 1;
assign WDIVMIN = WDIV - 1;
assign COL_270 = (WDIV == 1)? 0 : (HDIVMIN << 4) + (WDIV << 3); //HDIVMIN * 24
assign ROWINC_270 = ROWDEC_90; 

assign STOP_ROT = (I_CS_HEIGHT[15] || (I_CS_WIDTH[15:14] != 2'h0))? 1 : 0;
//assign LAST_HDIV = (hdiv_count == HDIV)? 1 : 0;
//assign LAST_WDIV = (wdiv_count == WDIV - 1)? 1: 0;
assign LAST = (LAST_HDIV && LAST_WDIV)? 1 : 0;

assign out_address = row + col;
assign out_address0 = row0 + col0;
assign out_address90 = row90 + col90;
assign out_address180 = row180 + col180;
assign out_address270 = row270 + col270;

assign O_CS_NEW_H = new_height;
assign O_CS_NEW_W = new_width;

assign O_CS_SIZE = 3'h2;
assign O_CS_COUNT = 5'h06;

always @(*)
    if (curr_state == P_WRITE)
        O_CS_WRITE = 1;
    else 
        O_CS_WRITE = 0;

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	FIRST <= 0;
    else 
	case (next_state)
	    P_IDLE:
		FIRST <= 0;
	    P_READ:
		if (row == 16'h0000)
		    FIRST <= 1;
		else 
		    FIRST <= FIRST;
	    P_WRITE:
		FIRST <= 0;
            default:
                FIRST <= 0;
	endcase

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	LAST_HDIV <= 0;
    else 
	if ((hdiv_count == HDIVMIN[11:0]) && (set_count == 6'h3e))
	    LAST_HDIV <= 1;
	else 
	    LAST_HDIV <= 0;

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	LAST_WDIV <= 0;
    else 
	if ((wdiv_count == WDIVMIN[11:0]) && (set_count == 6'h3e))
	    LAST_WDIV <= 1;
	else 
	    LAST_WDIV <= 0;

//state transition
always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	curr_state <= P_IDLE;
    else 
	curr_state <= next_state;

//state conditions
always @(*)
    if (!I_CS_HRESET_N)
	next_state = P_IDLE;
    else 
	case (curr_state)
	    P_IDLE:
		if (STOP_ROT)
		    next_state = P_IDLE;
		else 
		    if (I_CS_START)
			next_state = P_READ;
		    else 
			next_state = P_IDLE;
	    P_READ:
		if (set_count == 6'h3f)
		    next_state = P_WRITE;
		else
		    next_state = P_READ;
	    P_WRITE:
		if (LAST)
		    if (set_count == 6'h3f)
			next_state = P_IDLE;
		    else 
			next_state = P_WRITE;
		else 
		    if (set_count == 6'h3f)
			next_state = P_READ;
		    else 
			next_state = P_WRITE;
	    default:
		next_state = P_IDLE;
	endcase

// out_addressput image height 
always @(*)
    if ((I_CS_HEIGHT & 16'h0007) == 16'h0000)
        new_height = I_CS_HEIGHT;
    else 
        new_height = I_CS_HEIGHT + {11'h000,HDEFICIT};

// out_addressput image height 

always @(*)
    if ((I_CS_WIDTH & 16'h0007) == 16'h0000)
        new_width = I_CS_WIDTH;
    else 
        new_width = I_CS_WIDTH + {11'h000,WDEFICIT};

//count to 64
always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	set_count <= 6'h00;
    else 
	if (curr_state == P_IDLE)
	    set_count <= 6'h00;
	else 
	    set_count <= set_count + 1;

//count to 8
always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	burst_count <= 3'h0;
    else 
	if (curr_state == P_IDLE)
	    burst_count <= 3'h0;
	else
	    burst_count <= burst_count + 1;

//count to HDIV
always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	hdiv_count <= 12'h000;
    else 
	case (next_state)
	    P_IDLE:
		hdiv_count <= 12'h000;
	    P_READ:
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
	    P_WRITE:
		hdiv_count <= hdiv_count;
            default: 
                hdiv_count <= 12'h000;
	endcase

//count to WDIV
always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	wdiv_count <= 12'h000;
    else 
	case (next_state)
	    P_IDLE:
		wdiv_count <= 12'h000;
	    P_READ:
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
	    P_WRITE:
		wdiv_count <= wdiv_count;
            default:
                wdiv_count <= 12'h000;
	endcase 
		
//*****************************************************//
//*****************************************************//
//*****************************************************//

//current read row
always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	row <= 16'h0000;
    else 
	case (next_state)
	    P_IDLE:
		row <= 16'h0000;
	    P_READ:
		    if (LAST_HDIV && (set_count == 6'h3f))
			row <= 16'h0000;
		    else 
			if (burst_count == 3'h7)
			    row <= row + WIDTH;
			else 
			    row <= row;
	    P_WRITE:
		row <= row;
            default: 
                row <= 16'h0000;
	endcase

//current read column 
always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	col <= 16'h0000;
    else 
	case (next_state)
	    P_IDLE:
		col <= 16'h0000;
	    P_READ:
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
	    P_WRITE:
		col <= col;
            default:
                col <= 16'h0000;
	endcase

//*****************************************************//
//*****************************************************//
//*****************************************************//

//current read row
always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	row0 <= 16'h0000;
    else 
	case (next_state)
	    P_IDLE:
		row0 <= 16'h0000;
	    P_READ:
		row0 <= row0;
	    P_WRITE:
		if (FIRST)
		    row0 <= 16'h0000;
		else 
		    if (burst_count == 3'h7)
			row0 <= row0 + WIDTH;
		    else 
			row0 <= row0;
            default:
                row0 <= 16'h0000;
	endcase

//current read column 
always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	col0 <= 16'h0000;
    else 
	case (next_state)
	    P_IDLE:
		col0 <= 16'h0000;
	    P_READ:
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
	    P_WRITE:
		col0 <= col0;
            default:
                col0 <= 16'h0000;
	endcase

//*****************************************************//
//*****************************************************//
//*****************************************************//

//current read column 
always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	dec90 <= 16'h0000;
    else 
	case (next_state)
	    P_IDLE:
		dec90 <= 16'h0000;
	    P_READ:
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
	    P_WRITE:
		dec90 <= dec90;
            default:
                dec90 <= 16'h0000;
	endcase

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	row90 <= 16'h0000;
    else 
	case (next_state)
	    P_IDLE:
		row90 <= 16'h0000;
	    P_READ:
		row90 <= row90;
	    P_WRITE:
		if (FIRST || (set_count == 6'h3f))
		    row90 <= START_90 - dec90;
		else
		    if (burst_count == 3'h7)
			row90 <= row90 + HEIGHT;
		    else 
			row90 <= row90;
            default:
                row90 <= 16'h0000;
	endcase

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	col90 <= 16'h0000;
    else 
	case (next_state)
	    P_IDLE:
		col90 <= 16'h0000;
	    P_READ:
		col90 <= col90;
	    P_WRITE:
		if (FIRST)
		    col90 <= 16'h0000;
		else 
		    if (set_count == 6'h3f)
			col90 <= col90 + 24;
		    else 
			col90 <= col90;
            default:
                col90 <= 16'h0000;
	endcase

//*****************************************************//
//*****************************************************//
//*****************************************************//

//current read column 
always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	dec180 <= 16'h0000;
    else 
	case (next_state)
	    P_IDLE:
		dec180 <= 16'h0000;
	    P_READ:
		if (LAST_HDIV)
		    dec180 <= 16'h0000;
		else 
		    if (set_count == 6'h3f)
			dec180 <= dec180 +  ROWDEC_180;
		    else 
			dec180 <= dec180;
	    P_WRITE:
		dec180 <= dec180;
            default:
                dec180 <= 16'h0000;
	endcase

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	row180 <= 16'h0000;
    else
	case (next_state)
	    P_IDLE:
		row180 <= 16'h0000;
	    P_READ:
		row180 <= row180;
	    P_WRITE:
		if (set_count == 6'h3f)
		    row180 <= START_180 - dec180;
		else 
		    if (burst_count == 3'h7) 
			row180 <= row180 + WIDTH;
		    else 
			row180 <= row180;
            default:
                row180 <= 16'h0000;
	endcase

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	col180 <= 16'h0000;
    else 
	case (next_state)
	    P_IDLE:
		col180 <= COL_180;
	    P_READ:
		col180 <= col180;
	    P_WRITE:
		if (FIRST)
		    col180 <= col180 - 24;
		else 
		    col180 <= col180;
            default:
                col180 <= 16'h0000;
	endcase

//*****************************************************//
//*****************************************************//
//*****************************************************//
always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	inc270 <= 16'h0000;
    else 
	case (next_state)
	    P_IDLE:
		inc270 <= 16'h0000;
	    P_READ:
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
	    P_WRITE:
		inc270 <= inc270;
            default:
                inc270 <= 16'h0000;
	endcase

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	row270 <= 16'h0000; 
    else
	case (next_state)
	    P_IDLE:
		row270 <= 16'h0000;
	    P_READ:
		row270 <= row270;
	    P_WRITE:
		if (set_count == 6'h3f)
		    row270 <= inc270;
		else
		    if (burst_count == 3'h7)
			row270 <= row270 + HEIGHT;
		    else 
			row270 <= row270;
            default:
                row270 <= 16'h0000;
	endcase

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	col270 <= 16'h0000;
    else 
	case (next_state)
	    P_IDLE:
		col270 <= 16'h0000;
	    P_READ:
		col270 <= col270;
	    P_WRITE:
		if (FIRST)
		    col270 <= COL_270;
		else 
		    if (set_count == 6'h3f)
			col270 <= col270 - 5'h18;
		    else 
			col270 <= col270;
            default:
                col270 <= 16'h0000;
	endcase

//*****************************************************//
//*****************************************************//
//*****************************************************//

always @(*)
    case (curr_state)
        P_READ:
            O_CS_ADDR = out_address;
        P_WRITE:
            if (I_CS_DIRECTION)
                case (I_CS_DEGREES)
                    P_DEG_0:
                        O_CS_ADDR = out_address0;
                    P_DEG_90:
                        O_CS_ADDR = out_address90;
                    P_DEG_180:
                        O_CS_ADDR = out_address180;
                    P_DEG_270:
                        O_CS_ADDR = out_address270;
                    default:
                        O_CS_ADDR = out_address;
                endcase
            else 
                case (I_CS_DEGREES)
                    P_DEG_0:
                        O_CS_ADDR = out_address0; 
                    P_DEG_90:
                        O_CS_ADDR = out_address270;
                    P_DEG_180:
                        O_CS_ADDR = out_address180; 
                    P_DEG_270:
                        O_CS_ADDR = out_address90;
                    default:
                        O_CS_ADDR = out_address; 
                endcase
        default:
            O_CS_ADDR = 32'h00000000;
    endcase

endmodule
