`timescale 1ns/1ps

`define D_CP_PIXEL_SET_WIDTH 8
`define D_CP_PIXEL_SIZE 1
`define D_CP_ADDRESS_OFFSET_AHB 4
`define D_CP_ADDRESS_OFFSET_B 0
`define D_CP_ADDRESS_OFFSET_G 1
`define D_CP_ADDRESS_OFFSET_R 2
`define D_CP_ADDRESS_OFFSET_0 0
`define D_CP_ADDRESS_OFFSET_1 1
`define D_CP_ADDRESS_OFFSET_2 2
`define D_CP_ADDRESS_OFFSET_3 3
`define D_CP_DEFAULT_ADDRESS_B 0
`define D_CP_DEFAULT_ADDRESS_G 1
`define D_CP_DEFAULT_ADDRESS_R 2
`define D_CP_DEFAULT_ADDRESS_0 0 
`define D_CP_DEFAULT_ADDRESS_1 1
`define D_CP_DEFAULT_ADDRESS_2 2
`define D_CP_DEFAULT_ADDRESS_3 3

module core_pixel (
    output reg [7:0] O_CP_PIXEL_IN_ADDR0,
    output reg [7:0] O_CP_PIXEL_IN_ADDR1,
    output reg [7:0] O_CP_PIXEL_IN_ADDR2,
    output reg [7:0] O_CP_PIXEL_IN_ADDR3,
    output reg [7:0] O_CP_PIXEL_OUT_ADDRB,
    output reg [7:0] O_CP_PIXEL_OUT_ADDRG,
    output reg [7:0] O_CP_PIXEL_OUT_ADDRR,
    output reg [7:0] O_CP_PIXEL_OUT_ADDR0, 
    output reg [7:0] O_CP_PIXEL_OUT_ADDR1,
    output reg [7:0] O_CP_PIXEL_OUT_ADDR2,
    output reg [7:0] O_CP_PIXEL_OUT_ADDR3,
    output reg [7:0] O_CP_PIXEL_IN_ADDRR,
    output reg [7:0] O_CP_PIXEL_IN_ADDRG,
    output reg [7:0] O_CP_PIXEL_IN_ADDRB,
    //output reg O_CP_IMEM_PAD, //TODO: transfer to core_set
    input [15:0] I_CP_HEIGHT,
    input [15:0] I_CP_WIDTH,
    input [1:0]	 I_CP_DEGREES,
    input I_CP_STOP,
    input I_CP_DMA_READY, //from dma - start transaction signal
    input I_CP_DIRECTION,
    input I_CP_START,
    input I_CP_HRESET_N,
    input I_CP_RESET,
    input I_CP_HCLK
);

parameter 	P_STATE_IDLE = 2'h0,
		P_STATE_READ = 2'h1,
		P_STATE_WRITE = 2'h2;

parameter 	P_DEG_0	= 2'h0,
		P_DEG_90 = 2'h1,
		P_DEG_180 = 2'h2,
		P_DEG_270 = 2'h3;

reg [1:0] curr_state;
reg [1:0] next_state;

//counters
reg [5:0] trans_count;	//count to 64
reg [2:0] beat_count;	//count to 8

//output addresses
reg [8:0] addr_0;
reg [8:0] addr_90;
reg [8:0] addr_180;
reg [8:0] addr_270;
reg [6:0] tmp_addr_0;
reg [6:0] tmp_addr_90;
reg [6:0] tmp_addr_180;
reg [6:0] tmp_addr_270;

//row addresses MAX:63
reg [6:0] row_0;
reg [6:0] row_90; //MAX:56
reg [6:0] row_180;
reg [6:0] row_270; //MAX:56

//column addresses MAX:7
reg [3:0] col_90;
reg [3:0] col_270;

reg [8:0] pixel_in_0;
reg [8:0] pixel_in_1;
reg [8:0] pixel_in_2;
reg [8:0] pixel_in_3;
reg [8:0] pixel_out_0;
reg [8:0] pixel_out_1;
reg [8:0] pixel_out_2;
reg [8:0] pixel_out_3;

reg [8:0] pixel_out_r;
reg [8:0] pixel_out_g;
reg [8:0] pixel_out_b;

//wire temp_pad; //TODO: transfer this to core_set
//assign temp_pad = (I_CP_WIDTH[2:0] == 3'h0)? I_CP_WIDTH[2:0] : (I_CP_WIDTH[2:0] - 1); //TODO: transfer this to core_set

assign O_CP_PIXEL_IN_ADDR0 = pixel_in_0;
assign O_CP_PIXEL_IN_ADDR1 = pixel_in_1;
assign O_CP_PIXEL_IN_ADDR2 = pixel_in_2;
assign O_CP_PIXEL_IN_ADDR3 = pixel_in_3;
assign O_CP_PIXEL_OUT_ADDR0 = pixel_out_0;
assign O_CP_PIXEL_OUT_ADDR1 = pixel_out_1;
assign O_CP_PIXEL_OUT_ADDR2 = pixel_out_2;
assign O_CP_PIXEL_OUT_ADDR3 = pixel_out_3;

//TODO: run spyglass again after all changes

always @(*)
    begin
	O_CP_PIXEL_IN_ADDRB = pixel_out_b[7:0];
	O_CP_PIXEL_IN_ADDRG = pixel_out_g[7:0];
	O_CP_PIXEL_IN_ADDRR = pixel_out_r[7:0];
    end

always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	begin
	    pixel_out_b <= `D_CP_DEFAULT_ADDRESS_B;
	    pixel_out_g <= `D_CP_DEFAULT_ADDRESS_G;
	    pixel_out_r <= `D_CP_DEFAULT_ADDRESS_R;
	end
    else 
	begin 
	    pixel_out_b <= {1'b0,addr_0};
	    pixel_out_g <= addr_2 + `D_CP_ADDRESS_OFFSET_G;
	    pixel_out_r <= addr_0 + `D_CP_ADDRESS_OFFSET_R;
	end

always @(*)
    if (I_CP_DIRECTION)
	case (I_CP_DEGREES)
	    P_DEG_0:
		begin
		    O_CP_PIXEL_OUT_ADDRB = addr_0[7:0] + `D_CP_ADDRESS_OFFSET_B;
		    O_CP_PIXEL_OUT_ADDRG = addr_0[7:0] + `D_CP_ADDRESS_OFFSET_G;
		    O_CP_PIXEL_OUT_ADDRR = addr_0[7:0] + `D_CP_ADDRESS_OFFSET_R;
		end
	    P_DEG_90:
		begin
		    O_CP_PIXEL_OUT_ADDRB = addr_90[7:0] + `D_CP_ADDRESS_OFFSET_B;
		    O_CP_PIXEL_OUT_ADDRG = addr_90[7:0] + `D_CP_ADDRESS_OFFSET_G;
		    O_CP_PIXEL_OUT_ADDRR = addr_90[7:0] + `D_CP_ADDRESS_OFFSET_R;
		end
	    P_DEG_180:
		begin
		    O_CP_PIXEL_OUT_ADDRB = addr_180[7:0] + `D_CP_ADDRESS_OFFSET_B;
		    O_CP_PIXEL_OUT_ADDRG = addr_180[7:0] + `D_CP_ADDRESS_OFFSET_G;
		    O_CP_PIXEL_OUT_ADDRR = addr_180[7:0] + `D_CP_ADDRESS_OFFSET_R;
		end
	    P_DEG_270:
		begin
		    O_CP_PIXEL_OUT_ADDRB = addr_270[7:0] + `D_CP_ADDRESS_OFFSET_B;
		    O_CP_PIXEL_OUT_ADDRG = addr_270[7:0] + `D_CP_ADDRESS_OFFSET_G;
		    O_CP_PIXEL_OUT_ADDRR = addr_270[7:0] + `D_CP_ADDRESS_OFFSET_R;
		end
	    default:
		begin
		    O_CP_PIXEL_OUT_ADDRB = 8'h00;
		    O_CP_PIXEL_OUT_ADDRG = 8'h00;
		    O_CP_PIXEL_OUT_ADDRR = 8'h00;
		end
	endcase
    else
	case (I_CP_DEGREES)
	    P_DEG_0:
		begin
		    O_CP_PIXEL_OUT_ADDRB = addr_0[7:0] + `D_CP_ADDRESS_OFFSET_B;
		    O_CP_PIXEL_OUT_ADDRG = addr_0[7:0] + `D_CP_ADDRESS_OFFSET_G;
		    O_CP_PIXEL_OUT_ADDRR = addr_0[7:0] + `D_CP_ADDRESS_OFFSET_R;
		end
	    P_DEG_90:
		begin
		    O_CP_PIXEL_OUT_ADDRB = addr_270[7:0] + `D_CP_ADDRESS_OFFSET_B;
		    O_CP_PIXEL_OUT_ADDRG = addr_270[7:0] + `D_CP_ADDRESS_OFFSET_G;
		    O_CP_PIXEL_OUT_ADDRR = addr_270[7:0] + `D_CP_ADDRESS_OFFSET_R;
		end
	    P_DEG_180:
		begin
		    O_CP_PIXEL_OUT_ADDRB = addr_180[7:0] + `D_CP_ADDRESS_OFFSET_B;
		    O_CP_PIXEL_OUT_ADDRG = addr_180[7:0] + `D_CP_ADDRESS_OFFSET_G;
		    O_CP_PIXEL_OUT_ADDRR = addr_180[7:0] + `D_CP_ADDRESS_OFFSET_R;
		end
	    P_DEG_270:
		begin
		    O_CP_PIXEL_OUT_ADDRB = addr_90[7:0] + `D_CP_ADDRESS_OFFSET_B;
		    O_CP_PIXEL_OUT_ADDRG = addr_90[7:0] + `D_CP_ADDRESS_OFFSET_G;
		    O_CP_PIXEL_OUT_ADDRR = addr_90[7:0] + `D_CP_ADDRESS_OFFSET_R;
		end
	    default:
		begin
		    O_CP_PIXEL_OUT_ADDRB = `D_CP_DEFAULT_ADDRESS_B;
		    O_CP_PIXEL_OUT_ADDRG = `D_CP_DEFAULT_ADDRESS_G;
		    O_CP_PIXEL_OUT_ADDRR = `D_CP_DEFAULT_ADDRESS_R;
		end
	endcase

always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	row_0 <= 7'h00;
    else 
	if (next_state == P_STATE_READ)
	    if (trans_count == 6'h3f)
		row_0 <= 7'h00; 
	    else 
		row_0 <= row_0[5:0] + `D_CP_PIXEL_SIZE;
	else 
	    row_0 <= row_0;

always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	row_90 <= 7'h00;
    else 
	case (next_state)
	    P_STATE_READ:
		if (beat_count == 3'h7)
		    row_90 <= 7'h38;
		else 
		    row_90 <= row_90[5:0] - `D_CP_PIXEL_SET_WIDTH;
	    default:
		row_90 <= 7'h38;
	endcase

always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	row_180 <= 7'h00;
    else 
	case (next_state)
	    P_STATE_READ:
		if (trans_count == 6'h3f)
		    row_180 <= 7'h3f; 
		else 
		    row_180 <= row_180[5:0] - `D_CP_PIXEL_SIZE;
	    default:
		row_180 <= 7'h3f;
	endcase

always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	row_270 <= 7'h00;
    else 
	if (next_state == P_STATE_READ)
	    if (beat_count == 3'h7)
		row_270 <= 7'h00;
	    else 
		row_270 <= row_270[5:0] + `D_CP_PIXEL_SET_WIDTH;
	else 
	    row_270 <= row_270;

always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	col_90 <= 4'h0;
    else
	if (next_state == P_STATE_READ)
	    if (trans_count == 6'h3f)
		col_90 <= 4'h0;
	    else
		if (beat_count == 3'h7)
		    col_90 <= col_90[2:0] + `D_CP_PIXEL_SIZE;
	else 
	    col_90 <= col_90;

always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	col_270 <= 4'h0;
    else 
	case (next_state)
	    P_STATE_READ:
		if (trans_count == 6'h3f)
		    col_270 <= 4'h7;
		else 
		    if (beat_count == 3'h7)
			col_270 <= col_270[2:0] - `D_CP_PIXEL_SIZE;
		    else 
			col_270 <= col_270;
	    default:
		col_270 <= 4'h7;
	endcase

always @(*)
    begin 
	tmp_addr_0 = {1'b0, row_0[5:0]}; 
	tmp_addr_90 = row_90[5:0] + col_90[2:0];
	tmp_addr_180 = {1'b0, row_180[5:0]};
	tmp_addr_270 = row_270[5:0] + col_270[2:0];
    end

always @(*)	
    begin
	addr_0 = (tmp_addr_0[5:0] << 1) + tmp_addr_0[5:0];
	addr_90 = (tmp_addr_90[5:0] << 1) + tmp_addr_90[5:0];
	addr_180 = (tmp_addr_180[5:0] << 1) + tmp_addr_180[5:0];
	addr_270 = (tmp_addr_270[5:0] << 1) + tmp_addr_270[5:0];
    end
//always @(*) //TODO: tranfer this to core_set
//    if (beat_count > temp_pad) //not divisible by 8
//	O_CP_IMEM_PAD = 1;
//    else 
//	O_CP_IMEM_PAD = 0;

//state transition
always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	curr_state <= P_STATE_IDLE;
    else 
	curr_state <= next_state;

//state conditions
always @(*)
    if (!I_CP_HRESET_N)
	next_state = P_STATE_IDLE;
    else 
	case(curr_state)
	    P_STATE_IDLE: 
		if (I_CP_DMA_READY)
		    next_state = P_STATE_READ;
		else 
		    next_state = P_STATE_IDLE;
	    P_STATE_READ:
		if (trans_count == 6'h3f)
		    next_state = P_STATE_WRITE;
		else 
		    next_state = P_STATE_READ;
	    P_STATE_WRITE:
		if (trans_count == 6'h3f)
		    next_state = P_STATE_READ;
		else 
		    next_state = P_STATE_WRITE;
	    default: 
		next_state = P_STATE_IDLE;
	endcase

//count tot 64 
always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	trans_count <= 6'h00;
    else 
        if (I_CP_STOP)
	    trans_count <= 6'h00;
	else
	    if (I_CP_DMA_READY)
		trans_count <= trans_count + 1;
	    else
		trans_count <= trans_count;

//count to 8
always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	beat_count <= 3'h0;
    else 
	if (I_CP_STOP)
	    beat_count <= 6'h00;
	else 
	    if (I_CP_DMA_READY)
		beat_count <= beat_count + 1;
	    else 
		beat_count <= beat_count;

//data from AHB to input buffer - input buffer side
always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	begin
	    pixel_in_0 <= `D_CP_DEFAULT_ADDRESS_0;
	    pixel_in_1 <= `D_CP_DEFAULT_ADDRESS_1;
	    pixel_in_2 <= `D_CP_DEFAULT_ADDRESS_2;
	    pixel_in_3 <= `D_CP_DEFAULT_ADDRESS_3;
	end
    else 
	case (next_state)
	    P_STATE_IDLE:	
		begin
		    pixel_in_0 <= `D_CP_DEFAULT_ADDRESS_0;
		    pixel_in_1 <= `D_CP_DEFAULT_ADDRESS_1;
		    pixel_in_2 <= `D_CP_DEFAULT_ADDRESS_2;
		    pixel_in_3 <= `D_CP_DEFAULT_ADDRESS_3;
		end
	    P_STATE_READ:
		if (trans_count == 8'h3f)
		    begin
			pixel_in_0 <= `D_CP_DEFAULT_ADDRESS_0;
			pixel_in_1 <= `D_CP_DEFAULT_ADDRESS_1;
			pixel_in_2 <= `D_CP_DEFAULT_ADDRESS_2;
			pixel_in_3 <= `D_CP_DEFAULT_ADDRESS_3;
		    end
		else
                    if ((beat_count != 3'h5) && (beat_count != 3'h6))
                        begin
                            pixel_in_0 <= pixel_in_0[7:0] + `D_CP_ADDRESS_OFFSET_AHB;
                            pixel_in_1 <= pixel_in_1[7:0] + `D_CP_ADDRESS_OFFSET_AHB;
                            pixel_in_2 <= pixel_in_2[7:0] + `D_CP_ADDRESS_OFFSET_AHB;
                            pixel_in_3 <= pixel_in_3[7:0] + `D_CP_ADDRESS_OFFSET_AHB;
                        end
                    else 
                        begin
                            pixel_in_0 <= pixel_in_0;
                            pixel_in_1 <= pixel_in_1;
                            pixel_in_2 <= pixel_in_2;
                            pixel_in_3 <= pixel_in_3;
                        end
            default:
                begin
		    pixel_in_0 <= `D_CP_DEFAULT_ADDRESS_0;
		    pixel_in_1 <= `D_CP_DEFAULT_ADDRESS_1;
		    pixel_in_2 <= `D_CP_DEFAULT_ADDRESS_2;
		    pixel_in_3 <= `D_CP_DEFAULT_ADDRESS_3;
                end
        endcase
                
always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	begin
	    pixel_out_0 <= `D_DEFAULT_ADDRESS_0;
	    pixel_out_1 <= `D_DEFAULT_ADDRESS_1;
	    pixel_out_2 <= `D_DEFAULT_ADDRESS_2;
	    pixel_out_3 <= `D_DEFAULT_ADDRESS_3;
	end
    else 
	case (next_state)
	    P_STATE_IDLE:
		begin
		    pixel_out_0 <= `D_DEFAULT_ADDRESS_0;
		    pixel_out_1 <= `D_DEFAULT_ADDRESS_1;
		    pixel_out_2 <= `D_DEFAULT_ADDRESS_2;
		    pixel_out_3 <= `D_DEFAULT_ADDRESS_3;
		end
	    P_STATE_WRITE:
                if (trans_count == 6'h3f)
                    begin
                        pixel_out_0 <= `D_DEFAULT_ADDRESS_0;
                        pixel_out_1 <= `D_DEFAULT_ADDRESS_1;
                        pixel_out_2 <= `D_DEFAULT_ADDRESS_2;
                        pixel_out_3 <= `D_DEFAULT_ADDRESS_3;
                    end
                else
                    if ((beat_count != 3'h5) && (beat_count != 3'h6))
                        begin
                            pixel_out_0 <= pixel_out_0[7:0] + `D_CP_ADDRESS_OFFSET_AHB;
                            pixel_out_1 <= pixel_out_1[7:0] + `D_CP_ADDRESS_OFFSET_AHB;
                            pixel_out_2 <= pixel_out_2[7:0] + `D_CP_ADDRESS_OFFSET_AHB;
                            pixel_out_3 <= pixel_out_3[7:0] + `D_CP_ADDRESS_OFFSET_AHB;
                        end
                    else 
                        begin
                            pixel_out_0 <= pixel_out_0;
                            pixel_out_1 <= pixel_out_1;
                            pixel_out_2 <= pixel_out_2;
                            pixel_out_3 <= pixel_out_3;
                        end
            default:
                begin
                    pixel_out_0 <= `D_DEFAULT_ADDRESS_0;
                    pixel_out_1 <= `D_DEFAULT_ADDRESS_1;
                    pixel_out_2 <= `D_DEFAULT_ADDRESS_2;
                    pixel_out_3 <= `D_DEFAULT_ADDRESS_3;
                end
	endcase

endmodule
