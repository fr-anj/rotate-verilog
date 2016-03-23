`timescale 1ns/1ps

`define D_CP_ADDRESS_OFFSET_AHB 4
`define D_CP_DEFAULT_ADDRESS_0 0 
`define D_CP_DEFAULT_ADDRESS_1 1
`define D_CP_DEFAULT_ADDRESS_2 2
`define D_CP_DEFAULT_ADDRESS_3 3

module core_pixel (
    output [7:0] O_CP_PIXEL_IN_ADDR0,
    output [7:0] O_CP_PIXEL_IN_ADDR1,
    output [7:0] O_CP_PIXEL_IN_ADDR2,
    output [7:0] O_CP_PIXEL_IN_ADDR3,
    output reg [7:0] O_CP_PIXEL_OUT_ADDR0, 
    output reg [7:0] O_CP_PIXEL_OUT_ADDR1,
    output reg [7:0] O_CP_PIXEL_OUT_ADDR2,
    output reg [7:0] O_CP_PIXEL_OUT_ADDR3,

    input [1:0]	 I_CP_DEGREES,
    input I_CP_STOP,
    input I_CP_DMA_READY, //from dma - start transaction signal
    input I_CP_DIRECTION,
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

reg [8:0] pixel_in_0;
reg [8:0] pixel_in_1;
reg [8:0] pixel_in_2;
reg [8:0] pixel_in_3;
reg [8:0] pixel_count_0;
reg [8:0] pixel_count_90;
reg [8:0] pixel_count_180;
reg [8:0] pixel_count_270;
wire [7:0] start_address_0;
wire [7:0] start_address_90;
wire [7:0] start_address_180;
wire [7:0] start_address_270;
reg [8:0] correct_90_0;
reg [8:0] correct_90_1;
reg [8:0] correct_90_2;
reg [8:0] correct_90_3;
reg [8:0] correct_270_0;
reg [8:0] correct_270_1;
reg [8:0] correct_270_2;
reg [8:0] correct_270_3;

wire [8:0] correct_0_0;
wire [8:0] correct_0_1;
wire [8:0] correct_0_2;
wire [8:0] correct_0_3;
reg [8:0] correct_180_0;
reg [8:0] correct_180_1;
reg [8:0] correct_180_2;
reg [8:0] correct_180_3;
wire [8:0] tmp_pixel_count_0;
wire [8:0] tmp_pixel_count_90;
wire [8:0] tmp_pixel_count_180;
wire [8:0] tmp_pixel_count_270;

wire [8:0] beat0_90_1;
wire [8:0] beat0_90_2;
wire [8:0] beat0_90_3;
wire [8:0] beat0_270_1;
wire [8:0] beat0_270_2;
wire [8:0] beat0_270_3;
wire [8:0] beat0_180_0;
wire [8:0] beat0_180_1;
wire [8:0] beat0_180_2;
wire [8:0] beat0_180_3;

wire [8:0] beat1_90_1;
wire [8:0] beat1_90_2;
wire [8:0] beat1_90_3;
wire [8:0] beat1_270_1;
wire [8:0] beat1_270_2;
wire [8:0] beat1_270_3;
wire [8:0] beat1_180_0;
wire [8:0] beat1_180_1;
wire [8:0] beat1_180_2;

wire [8:0] beat2_90_1;
wire [8:0] beat2_90_2;
wire [8:0] beat2_90_3;
wire [8:0] beat2_270_1;
wire [8:0] beat2_270_2;
wire [8:0] beat2_270_3;
wire [8:0] beat2_180_0;
wire [8:0] beat2_180_2;
wire [8:0] beat2_180_3;

assign beat0_90_1 = pixel_count_90[7:0] + 8'h01;
assign beat0_90_2 = pixel_count_90[7:0] + 8'h02;
assign beat0_90_3 = pixel_count_90[7:0] - 8'h18;
assign beat0_270_1 = pixel_count_270[7:0] + 8'h01;
assign beat0_270_2 = pixel_count_270[7:0] + 8'h02;
assign beat0_270_3 = pixel_count_270[7:0] + 8'h18;
assign beat0_180_0 = pixel_count_180[7:0] + 8'h01;
assign beat0_180_1 = pixel_count_180[7:0] + 8'h02;
assign beat0_180_2 = pixel_count_180[7:0] + 8'h03;
assign beat0_180_3 = pixel_count_180[7:0] - 8'h02;

assign beat1_90_1 = beat0_90_1;
assign beat1_90_2 = pixel_count_90[7:0] - 8'h19;
assign beat1_90_3 = beat0_90_3;
assign beat1_270_1 = beat0_270_1;
assign beat1_270_2 = pixel_count_270[7:0] + 8'h17;
assign beat1_270_3 = beat0_270_3;
assign beat1_180_0 = beat0_180_2;
assign beat1_180_1 = pixel_count_180[7:0] + 8'h04;
assign beat1_180_2 = pixel_count_180[7:0] - 8'h01;

assign beat2_90_1 = pixel_count_90[7:0] - 8'h1a;
assign beat2_90_2 = beat1_90_2;
assign beat2_90_3 = beat0_90_3;
assign beat2_270_1 = pixel_count_270[7:0] + 8'h16;
assign beat2_270_2 = beat1_270_2;
assign beat2_270_3 = beat0_270_3;
assign beat2_180_0 = pixel_count_180[7:0] + 8'h05;
assign beat2_180_2 = beat0_180_0;
assign beat2_180_3 = beat0_180_1;


assign start_address_0 = 8'h00;
assign start_address_90 = 8'ha8;
assign start_address_180 = 8'hbc;
assign start_address_270 = 8'h15;
assign correct_0_0 = pixel_count_0;
assign correct_0_1 = pixel_count_0[7:0] + 1;
assign correct_0_2 = pixel_count_0[7:0] + 2;
assign correct_0_3 = pixel_count_0[7:0] + 3;
assign tmp_pixel_count_0 = pixel_count_0[7:0] + 8'h04;
assign tmp_pixel_count_90 = pixel_count_90[7:0] - 8'h17;
assign tmp_pixel_count_180 = pixel_count_180[7:0] - 8'h04;
assign tmp_pixel_count_270 = pixel_count_270[7:0] + 8'h19; 

always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	begin
	    pixel_count_0 <= 9'h000;
	    pixel_count_90 <= 9'h000;
	    pixel_count_180 <= 9'h000;
	    pixel_count_270 <= 9'h000;
	end
    else 
	case (next_state)
	    P_STATE_IDLE:
		begin
		    pixel_count_0 <= {1'b0,start_address_0};
		    pixel_count_90 <= {1'b0,start_address_90};
		    pixel_count_180 <= {1'b0,start_address_180};
		    pixel_count_270 <= {1'b0,start_address_270};
		end
	    P_STATE_READ:
		begin
		    pixel_count_0 <= pixel_count_0;
		    pixel_count_90 <= pixel_count_90;
		    pixel_count_180 <= pixel_count_180;
		    pixel_count_270 <= pixel_count_270;
		end
	    P_STATE_WRITE:
		if (trans_count == 6'h3f)
		    begin
			pixel_count_0 <= {1'b0,start_address_0};
			pixel_count_90 <= {1'b0,start_address_90};
			pixel_count_180 <= {1'b0,start_address_180};
			pixel_count_270 <= {1'b0,start_address_270};
		    end
		else
		    case (beat_count)
			3'h0:
			    begin
				pixel_count_0 <= tmp_pixel_count_0;
				pixel_count_90 <= tmp_pixel_count_90;
				pixel_count_180 <= tmp_pixel_count_180;
				pixel_count_270 <= tmp_pixel_count_270;
			    end
			3'h1:
			    begin
				pixel_count_0 <= tmp_pixel_count_0;
				pixel_count_90 <= tmp_pixel_count_90;
				pixel_count_180 <= tmp_pixel_count_180;
				pixel_count_270 <= tmp_pixel_count_270;
			    end
			3'h2:
			    begin
				pixel_count_0 <= tmp_pixel_count_0;
				pixel_count_90 <= pixel_count_90[7:0] - 8'h32;
				pixel_count_180 <= tmp_pixel_count_180;
				pixel_count_270 <= pixel_count_270[7:0] + 8'h2e;
			    end
			3'h3:
			    begin
				pixel_count_0 <= tmp_pixel_count_0;
				pixel_count_90 <= tmp_pixel_count_90;
				pixel_count_180 <= tmp_pixel_count_180;
				pixel_count_270 <= tmp_pixel_count_270;
			    end
			3'h4:
			    begin
				pixel_count_0 <= tmp_pixel_count_0;
				pixel_count_90 <= tmp_pixel_count_90;
				pixel_count_180 <= tmp_pixel_count_180;
				pixel_count_270 <= tmp_pixel_count_270;
			    end
			3'h7:
			    begin
				pixel_count_0 <= tmp_pixel_count_0;
				pixel_count_90 <= pixel_count_90[7:0] + 8'h91;
				pixel_count_180 <= tmp_pixel_count_180;
				pixel_count_270 <= pixel_count_270[7:0] - 8'h95;
			    end
			default:
			    begin
				pixel_count_0 <= pixel_count_0;
				pixel_count_90 <= pixel_count_90;
				pixel_count_180 <= pixel_count_180;
				pixel_count_270 <= pixel_count_270;
			    end
		    endcase
	    default:
		begin
		    pixel_count_0 <= pixel_count_0;
		    pixel_count_90 <= pixel_count_90;
		    pixel_count_180 <= pixel_count_180;
		    pixel_count_270 <= pixel_count_270;
		end
	endcase

always @(*)
    if (!I_CP_DIRECTION)
	case (I_CP_DEGREES)
	    P_DEG_0:
		begin
		    O_CP_PIXEL_OUT_ADDR0 = correct_0_0[7:0];
		    O_CP_PIXEL_OUT_ADDR1 = correct_0_1[7:0];
		    O_CP_PIXEL_OUT_ADDR2 = correct_0_2[7:0];
		    O_CP_PIXEL_OUT_ADDR3 = correct_0_3[7:0];
		end
	    P_DEG_90:
		begin
		    O_CP_PIXEL_OUT_ADDR0 = correct_90_0[7:0];
		    O_CP_PIXEL_OUT_ADDR1 = correct_90_1[7:0];
		    O_CP_PIXEL_OUT_ADDR2 = correct_90_2[7:0];
		    O_CP_PIXEL_OUT_ADDR3 = correct_90_3[7:0];
		end
	    P_DEG_180:
		begin
		    O_CP_PIXEL_OUT_ADDR0 = correct_180_0[7:0];
		    O_CP_PIXEL_OUT_ADDR1 = correct_180_1[7:0];
		    O_CP_PIXEL_OUT_ADDR2 = correct_180_2[7:0];
		    O_CP_PIXEL_OUT_ADDR3 = correct_180_3[7:0];
		end
	    P_DEG_270:
		begin
		    O_CP_PIXEL_OUT_ADDR0 = correct_270_0[7:0];
		    O_CP_PIXEL_OUT_ADDR1 = correct_270_1[7:0];
		    O_CP_PIXEL_OUT_ADDR2 = correct_270_2[7:0];
		    O_CP_PIXEL_OUT_ADDR3 = correct_270_3[7:0];
		end
	    default:
		begin
		    O_CP_PIXEL_OUT_ADDR0 = correct_0_0[7:0];
		    O_CP_PIXEL_OUT_ADDR1 = correct_0_1[7:0];
		    O_CP_PIXEL_OUT_ADDR2 = correct_0_2[7:0];
		    O_CP_PIXEL_OUT_ADDR3 = correct_0_3[7:0];
		end
	endcase
    else
	case (I_CP_DEGREES)
	    P_DEG_0:
		begin
		    O_CP_PIXEL_OUT_ADDR0 = correct_0_0[7:0];
		    O_CP_PIXEL_OUT_ADDR1 = correct_0_1[7:0];
		    O_CP_PIXEL_OUT_ADDR2 = correct_0_2[7:0];
		    O_CP_PIXEL_OUT_ADDR3 = correct_0_3[7:0];
		end
	    P_DEG_90:
		begin
		    O_CP_PIXEL_OUT_ADDR0 = correct_270_0[7:0];
		    O_CP_PIXEL_OUT_ADDR1 = correct_270_1[7:0];
		    O_CP_PIXEL_OUT_ADDR2 = correct_270_2[7:0];
		    O_CP_PIXEL_OUT_ADDR3 = correct_270_3[7:0];
		end
	    P_DEG_180:
		begin
		    O_CP_PIXEL_OUT_ADDR0 = correct_180_0[7:0];
		    O_CP_PIXEL_OUT_ADDR1 = correct_180_1[7:0];
		    O_CP_PIXEL_OUT_ADDR2 = correct_180_2[7:0];
		    O_CP_PIXEL_OUT_ADDR3 = correct_180_3[7:0];
		end
	    P_DEG_270:
		begin
		    O_CP_PIXEL_OUT_ADDR0 = correct_90_0[7:0];
		    O_CP_PIXEL_OUT_ADDR1 = correct_90_1[7:0];
		    O_CP_PIXEL_OUT_ADDR2 = correct_90_2[7:0];
		    O_CP_PIXEL_OUT_ADDR3 = correct_90_3[7:0];
		end
	    default:
		begin
		    O_CP_PIXEL_OUT_ADDR0 = correct_0_0[7:0];
		    O_CP_PIXEL_OUT_ADDR1 = correct_0_1[7:0];
		    O_CP_PIXEL_OUT_ADDR2 = correct_0_2[7:0];
		    O_CP_PIXEL_OUT_ADDR3 = correct_0_3[7:0];
		end
	endcase

always @(*)
	if (curr_state == P_STATE_WRITE)
	    case (beat_count)
		3'h0:
		    begin
			correct_90_0 = pixel_count_90[7:0];
			correct_90_1 = beat0_90_1;
			correct_90_2 = beat0_90_2;
			correct_90_3 = beat0_90_3;
			correct_270_0 = pixel_count_270[7:0];
			correct_270_1 = beat0_270_1;
			correct_270_2 = beat0_270_2;
			correct_270_3 = beat0_270_3;
			correct_180_0 = beat0_180_0;
			correct_180_1 = beat0_180_1;
			correct_180_2 = beat0_180_2;
			correct_180_3 = beat0_180_3;
		    end
		3'h1:
		    begin
			correct_90_0 = pixel_count_90[7:0];
			correct_90_1 = beat1_90_1;
			correct_90_2 = beat1_90_2;
			correct_90_3 = beat1_90_3;
			correct_270_0 = pixel_count_270[7:0];
			correct_270_1 = beat1_270_1;
			correct_270_2 = beat1_270_2;
			correct_270_3 = beat1_270_3;
			correct_180_0 = beat1_180_0;
			correct_180_1 = beat1_180_1;
			correct_180_2 = beat1_180_2;
			correct_180_3 = pixel_count_180[7:0];
		    end
		3'h2:
		    begin
			correct_90_0 = pixel_count_90[7:0];
			correct_90_1 = beat2_90_1;
			correct_90_2 = beat2_90_2;
			correct_90_3 = beat2_90_3;
			correct_270_0 = pixel_count_270[7:0];
			correct_270_1 = beat2_270_1;
			correct_270_2 = beat2_270_2;
			correct_270_3 = beat2_270_3;
			correct_180_0 = beat2_180_0;
			correct_180_1 = pixel_count_180[7:0];
			correct_180_2 = beat2_180_2;
			correct_180_3 = beat2_180_3;
		    end
		3'h3:
		    begin
			correct_90_0 = pixel_count_90[7:0];
			correct_90_1 = beat0_90_1;
			correct_90_2 = beat0_90_2;
			correct_90_3 = beat0_90_3;
			correct_270_0 = pixel_count_270[7:0];
			correct_270_1 = beat0_270_1;
			correct_270_2 = beat0_270_2;
			correct_270_3 = beat0_270_3;
			correct_180_0 = beat0_180_0;
			correct_180_1 = beat0_180_1;
			correct_180_2 = beat0_180_2;
			correct_180_3 = beat0_180_3;
		    end
		3'h4:
		    begin
			correct_90_0 = pixel_count_90[7:0];
			correct_90_1 = beat1_90_1;
			correct_90_2 = beat1_90_2;
			correct_90_3 = beat1_90_3;
			correct_270_0 = pixel_count_270[7:0];
			correct_270_1 = beat1_270_1;
			correct_270_2 = beat1_270_2;
			correct_270_3 = beat1_270_3;
			correct_180_0 = beat1_180_0;
			correct_180_1 = beat1_180_1;
			correct_180_2 = beat1_180_2;
			correct_180_3 = pixel_count_180[7:0];
		    end
		3'h5:
		    begin
			correct_90_0 = pixel_count_90[7:0];
			correct_90_1 = beat2_90_1;
			correct_90_2 = beat2_90_2;
			correct_90_3 = beat2_90_3;
			correct_270_0 = pixel_count_270[7:0];
			correct_270_1 = beat2_270_1;
			correct_270_2 = beat2_270_2;
			correct_270_3 = beat2_270_3;
			correct_180_0 = beat2_180_0;
			correct_180_1 = pixel_count_180[7:0];
			correct_180_2 = beat2_180_2;
			correct_180_3 = beat2_180_3;
		    end
		3'h6:
		    begin
			correct_90_0 = pixel_count_90[7:0];
			correct_90_1 = beat2_90_1;
			correct_90_2 = beat2_90_2;
			correct_90_3 = beat2_90_3;
			correct_270_0 = pixel_count_270[7:0];
			correct_270_1 = beat2_270_1;
			correct_270_2 = beat2_270_2;
			correct_270_3 = beat2_270_3;
			correct_180_0 = beat2_180_0;
			correct_180_1 = pixel_count_180[7:0];
			correct_180_2 = beat2_180_2;
			correct_180_3 = beat2_180_3;
		    end
		3'h7:
		    begin
			correct_90_0 = pixel_count_90[7:0];
			correct_90_1 = beat2_90_1;
			correct_90_2 = beat2_90_2;
			correct_90_3 = beat2_90_3;
			correct_270_0 = pixel_count_270[7:0];
			correct_270_1 = beat2_270_1;
			correct_270_2 = beat2_270_2;
			correct_270_3 = beat2_270_3;
			correct_180_0 = beat2_180_0;
			correct_180_1 = pixel_count_180[7:0];
			correct_180_2 = beat2_180_2;
			correct_180_3 = beat2_180_3;
		    end
		default:
		    begin
			correct_90_0 = pixel_count_90[7:0];
			correct_90_1 = beat2_90_1;
			correct_90_2 = beat2_90_2;
			correct_90_3 = beat2_90_3;
			correct_270_0 = pixel_count_270[7:0];
			correct_270_1 = beat2_270_1;
			correct_270_2 = beat2_270_2;
			correct_270_3 = beat2_270_3;
			correct_180_0 = beat2_180_0;
			correct_180_1 = pixel_count_180[7:0];
			correct_180_2 = beat2_180_2;
			correct_180_3 = beat2_180_3;
		    end
	    endcase
	else
	    begin
			correct_90_0 = pixel_count_90[7:0];
			correct_90_1 = beat2_90_1;
			correct_90_2 = beat2_90_2;
			correct_90_3 = beat2_90_3;
			correct_270_0 = pixel_count_270[7:0];
			correct_270_1 = beat2_270_1;
			correct_270_2 = beat2_270_2;
			correct_270_3 = beat2_270_3;
			correct_180_0 = beat2_180_0;
			correct_180_1 = pixel_count_180[7:0];
			correct_180_2 = beat2_180_2;
			correct_180_3 = beat2_180_3;
	    end

assign O_CP_PIXEL_IN_ADDR0 = pixel_in_0[7:0];
assign O_CP_PIXEL_IN_ADDR1 = pixel_in_1[7:0];
assign O_CP_PIXEL_IN_ADDR2 = pixel_in_2[7:0];
assign O_CP_PIXEL_IN_ADDR3 = pixel_in_3[7:0];

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
		if (I_CP_RESET)
		    next_state = P_STATE_IDLE;
		else
		    if (trans_count == 6'h3f)
			next_state = P_STATE_WRITE;
		    else 
			next_state = P_STATE_READ;
	    P_STATE_WRITE:
		if (I_CP_RESET)
		    next_state = P_STATE_IDLE;
		else
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
	if (I_CP_STOP)
	    begin 
		pixel_in_0 <= 9'h000;
		pixel_in_1 <= 9'h000;
		pixel_in_2 <= 9'h000;
		pixel_in_3 <= 9'h000;
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
                
endmodule
