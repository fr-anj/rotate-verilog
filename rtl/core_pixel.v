//this module should start during nseq of dma -NOT- during hgrant
`timescale 1ns/1ps

`define pixel_set_width 8

module core_pixel (
    output [7:0] O_CP_PIXEL_IN_ADDR0,
    output [7:0] O_CP_PIXEL_IN_ADDR1,
    output [7:0] O_CP_PIXEL_IN_ADDR2,
    output [7:0] O_CP_PIXEL_IN_ADDR3,
    output [7:0] O_CP_PIXEL_OUT_ADDRB,
    output [7:0] O_CP_PIXEL_OUT_ADDRG,
    output [7:0] O_CP_PIXEL_OUT_ADDRR,
    output [7:0] O_CP_PIXEL_OUT_ADDR0,
     
    output [7:0] O_CP_PIXEL_OUT_ADDR1,
    output [7:0] O_CP_PIXEL_OUT_ADDR2,
    output [7:0] O_CP_PIXEL_OUT_ADDR3,
    output reg [7:0] O_CP_PIXEL_IN_ADDRR,
    output reg [7:0] O_CP_PIXEL_IN_ADDRG,
    output reg [7:0] O_CP_PIXEL_IN_ADDRB,

//    output reg O_CP_IMEM_PAD, //TODO: transfer to core_set

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

parameter 	P_IDLE = 2'h0,
		P_READ = 2'h1,
		P_WRITE = 2'h2;

parameter 	P_DEG_0	= 2'h0,
		P_DEG_90 = 2'h1,
		P_DEG_180 = 2'h2,
		P_DEG_270 = 2'h3;

reg [1:0] curr_state;
reg [1:0] next_state;

//counters
reg [5:0] trans_count;	//count to 64
reg [2:0] beat_count;	//count to 8

//initial address for rotation 
reg [7:0] pixel_r;
reg [7:0] pixel_g;
reg [7:0] pixel_b;

//base address
reg [7:0] base_r;
reg [7:0] base_g;
reg [7:0] base_b;

//delay reg for O_CP_PIXEL_IN_ADDR (RGB)
reg [7:0] addr_r;
reg [7:0] addr_g;
reg [7:0] addr_b;

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
reg [2:0] col_90;
reg [2:0] col_270;

reg [8:0] PIXEL_IN_ADDR0;
reg [8:0] PIXEL_IN_ADDR1;
reg [8:0] PIXEL_IN_ADDR2;
reg [8:0] PIXEL_IN_ADDR3;
reg [8:0] PIXEL_IN_ADDRB;
reg [8:0] PIXEL_IN_ADDRG;
reg [8:0] PIXEL_IN_ADDRR;
reg [8:0] PIXEL_OUT_ADDR0;
reg [8:0] PIXEL_OUT_ADDR1;
reg [8:0] PIXEL_OUT_ADDR2;
reg [8:0] PIXEL_OUT_ADDR3;
reg [8:0] PIXEL_OUT_ADDRB;
reg [8:0] PIXEL_OUT_ADDRG;
reg [8:0] PIXEL_OUT_ADDRR;

wire increment;
wire temp1;
wire temp2;
wire decrement;
wire temp3;
wire temp4;
//wire temp_pad; //TODO: transfer this to core_set

assign temp1 = (I_CP_DIRECTION && (I_CP_DEGREES == P_DEG_90))? 1 : 0;
assign temp2 = ((!I_CP_DIRECTION) && (I_CP_DEGREES == P_DEG_270))? 1 : 0;
assign increment = temp1 || temp2;
assign temp3 = (I_CP_DIRECTION && (I_CP_DEGREES == P_DEG_270))? 1 : 0;
assign temp4 = ((!I_CP_DIRECTION) && (I_CP_DEGREES == P_DEG_90))? 1 : 0;
assign decrement = temp3 || temp4;
//assign temp_pad = (I_CP_WIDTH[2:0] == 3'h0)? I_CP_WIDTH[2:0] : (I_CP_WIDTH[2:0] - 1); //TODO: transfer this to core_set

assign O_CP_PIXEL_IN_ADDR0 = PIXEL_IN_ADDR0;
assign O_CP_PIXEL_IN_ADDR1 = PIXEL_IN_ADDR1;
assign O_CP_PIXEL_IN_ADDR2 = PIXEL_IN_ADDR2;
assign O_CP_PIXEL_IN_ADDR3 = PIXEL_IN_ADDR3;
//assign O_CP_PIXEL_IN_ADDRR = PIXEL_IN_ADDRR;
//assign O_CP_PIXEL_IN_ADDRG = PIXEL_IN_ADDRG;
//assign O_CP_PIXEL_IN_ADDRB = PIXEL_IN_ADDRB;
//assign O_CP_PIXEL_OUT_ADDRB = PIXEL_OUT_ADDRB;
//assign O_CP_PIXEL_OUT_ADDRG = PIXEL_OUT_ADDRG;
//assign O_CP_PIXEL_OUT_ADDRR = PIXEL_OUT_ADDRR;
assign O_CP_PIXEL_OUT_ADDR0 = PIXEL_OUT_ADDR0;
assign O_CP_PIXEL_OUT_ADDR1 = PIXEL_OUT_ADDR1;
assign O_CP_PIXEL_OUT_ADDR2 = PIXEL_OUT_ADDR2;
assign O_CP_PIXEL_OUT_ADDR3 = PIXEL_OUT_ADDR3;

//TODO: delete unneccessary code
//TODO: run spyglass again after all changes

always @(*)
    if (I_CP_DIRECTION)
	case (I_CP_DEGREES)
	    P_DEG_0:
		begin
		    O_CP_PIXEL_OUT_ADDRR = addr_0;
		    O_CP_PIXEL_OUT_ADDRG = addr_0 + 1;
		    O_CP_PIXEL_OUT_ADDRB = addr_0 + 2;
		end
	    P_DEG_90:
		begin
		    O_CP_PIXEL_OUT_ADDRR = addr_90;
		    O_CP_PIXEL_OUT_ADDRG = addr_90 + 1;
		    O_CP_PIXEL_OUT_ADDRB = addr_90 + 2;
		end
	    P_DEG_180:
		begin
		    O_CP_PIXEL_OUT_ADDRR = addr_180;
		    O_CP_PIXEL_OUT_ADDRG = addr_180 + 1;
		    O_CP_PIXEL_OUT_ADDRB = addr_180 + 2;
		end
	    P_DEG_270:
		begin
		    O_CP_PIXEL_OUT_ADDRR = addr_270;
		    O_CP_PIXEL_OUT_ADDRG = addr_270 + 1;
		    O_CP_PIXEL_OUT_ADDRB = addr_270 + 2;
		end
	    default:
		begin
		    O_CP_PIXEL_OUT_ADDRR = 8'h00;
		    O_CP_PIXEL_OUT_ADDRG = 8'h00;
		    O_CP_PIXEL_OUT_ADDRB = 8'h00;
		end
	endcase
    else
	case (I_CP_DEGREES)
	    P_DEG_0:
		begin
		    O_CP_PIXEL_OUT_ADDRR = addr_0;
		    O_CP_PIXEL_OUT_ADDRG = addr_0 + 1;
		    O_CP_PIXEL_OUT_ADDRB = addr_0 + 2;
		end
	    P_DEG_90:
		begin
		    O_CP_PIXEL_OUT_ADDRR = addr_270;
		    O_CP_PIXEL_OUT_ADDRG = addr_270 + 1;
		    O_CP_PIXEL_OUT_ADDRB = addr_270 + 2;
		end
	    P_DEG_180:
		begin
		    O_CP_PIXEL_OUT_ADDRR = addr_180;
		    O_CP_PIXEL_OUT_ADDRG = addr_180 + 1;
		    O_CP_PIXEL_OUT_ADDRB = addr_180 + 2;
		end
	    P_DEG_270:
		begin
		    O_CP_PIXEL_OUT_ADDRR = addr_90;
		    O_CP_PIXEL_OUT_ADDRG = addr_90 + 1;
		    O_CP_PIXEL_OUT_ADDRB = addr_90 + 2;
		end
	    default:
		begin
		    O_CP_PIXEL_OUT_ADDRR = 8'h00;
		    O_CP_PIXEL_OUT_ADDRG = 8'h00;
		    O_CP_PIXEL_OUT_ADDRB = 8'h00;
		end
	endcase

always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	row_0 <= 7'h00;
    else 
	if (next_state == P_READ)
	    if (trans_count == 6'h3f)
		row_0 <= 7'h00; 
	    else 
		row_0 <= row_0[5:0] + 1;
	else 
	    row_0 <= row_0;

always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	row_90 <= 7'h00;
    else 
	case (next_state)
	    P_READ:
		if (beat_count == 3'h7)
		    row_90 <= 7'h38;
		else 
		    row_90 <= row_90[5:0] - `pixel_set_width;
	    default:
		row_90 <= 7'h38;
	endcase

always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	row_180 <= 7'h00;
    else 
	case (next_state)
	    P_READ:
		if (trans_count == 6'h3f)
		    row_180 <= 7'h3f; 
		else 
		    row_180 <= row_180[5:0] - 1;
	    default:
		row_180 <= 7'h3f;
	endcase

always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	row_270 <= 7'h00;
    else 
	if (next_state == P_READ)
	    if (beat_count == 3'h7)
		row_270 <= 7'h00;
	    else 
		row_270 <= row_270[5:0] + `pixel_set_width;
	else 
	    row_270 <= row_270;

always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	col_90 <= 3'h0;
    else
	if (next_state == P_READ)
	    if (trans_count == 6'h3f)
		col_90 <= 7'h00;
	    else
		if (beat_count == 3'h7)
		    col_90 <= col_90[5:0] + 1;
	else 
	    col_90 <= col_90;

always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	col_270 <= 3'h0;
    else 
	case (next_state)
	    P_READ:
		if (trans_count == 6'h3f)
		    col_270 <= 3'h7;
		else 
		    if (beat_count == 3'h7)
			col_270 <= col_270[5:0] - 1;
		    else 
			col_270 <= col_270;
	    default:
		col_270 <= 7'h07;
	endcase

always @(*)
    begin 
	tmp_addr_0 = {1'b0, row_0[5:0]}; 
	tmp_addr_90 = row_90[5:0] + col_90[5:0];
	tmp_addr_180 = {1'b0, row_180[5:0]};
	tmp_addr_270 = row_270[5:0] + col_270[5:0];
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
	curr_state <= P_IDLE;
    else 
	curr_state <= next_state;

//state conditions
always @(*)
    if (!I_CP_HRESET_N)
	next_state = P_IDLE;
    else 
	case(curr_state)
	    P_IDLE: 
		if (I_CP_DMA_READY)
		    next_state = P_READ;
		else 
		    next_state = P_IDLE;
	    P_READ:
		if (trans_count == 6'h3f)
		    next_state = P_WRITE;
		else 
		    next_state = P_READ;
	    P_WRITE:
		if (trans_count == 6'h3f)
		    next_state = P_READ;
		else 
		    next_state = P_WRITE;
	    default: 
		next_state = P_IDLE;
	endcase

//count tot 64 
always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
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
        if (I_CP_DMA_READY)
            beat_count <= beat_count + 1;
        else 
            beat_count <= beat_count;

//data from AHB to input buffer - input buffer side
always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	begin
	    PIXEL_IN_ADDR0 <= 8'h00;
	    PIXEL_IN_ADDR1 <= 8'h01;
	    PIXEL_IN_ADDR2 <= 8'h02;
	    PIXEL_IN_ADDR3 <= 8'h03;
	end
    else 
	case (next_state)
	    P_IDLE:	
		begin
		    PIXEL_IN_ADDR0 <= 8'h00;
		    PIXEL_IN_ADDR1 <= 8'h01;
		    PIXEL_IN_ADDR2 <= 8'h02;
		    PIXEL_IN_ADDR3 <= 8'h03;
		end
	    P_READ:
		if (trans_count == 8'h3f)
		    begin
			PIXEL_IN_ADDR0 <= 8'h00;
			PIXEL_IN_ADDR1 <= 8'h01;
			PIXEL_IN_ADDR2 <= 8'h02;
			PIXEL_IN_ADDR3 <= 8'h03;
		    end
		else
                    if ((beat_count != 3'h5) && (beat_count != 3'h6))
                        begin
                            PIXEL_IN_ADDR0 <= PIXEL_IN_ADDR0[7:0] + 4;
                            PIXEL_IN_ADDR1 <= PIXEL_IN_ADDR1[7:0] + 4;
                            PIXEL_IN_ADDR2 <= PIXEL_IN_ADDR2[7:0] + 4;
                            PIXEL_IN_ADDR3 <= PIXEL_IN_ADDR3[7:0] + 4;
                        end
                    else 
                        begin
                            PIXEL_IN_ADDR0 <= PIXEL_IN_ADDR0;
                            PIXEL_IN_ADDR1 <= PIXEL_IN_ADDR1;
                            PIXEL_IN_ADDR2 <= PIXEL_IN_ADDR2;
                            PIXEL_IN_ADDR3 <= PIXEL_IN_ADDR3;
                        end
            default:
                begin
		    PIXEL_IN_ADDR0 <= 8'h00;
		    PIXEL_IN_ADDR1 <= 8'h01;
		    PIXEL_IN_ADDR2 <= 8'h02;
		    PIXEL_IN_ADDR3 <= 8'h03;
                end
        endcase
                
//data from input buffer to output buffer - input buffer side
always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	begin
	    PIXEL_OUT_ADDRR <= 8'h00;
	    PIXEL_OUT_ADDRG <= 8'h01;
	    PIXEL_OUT_ADDRB <= 8'h02;
	end
    else 
	case (next_state)
	    P_IDLE:
		begin
		    PIXEL_OUT_ADDRR <= 8'h00;
		    PIXEL_OUT_ADDRG <= 8'h01;
		    PIXEL_OUT_ADDRB <= 8'h02;
		end
	    P_READ:
                if (trans_count == 6'h3f)
                    begin 
                        PIXEL_OUT_ADDRR <= 8'h00;
                        PIXEL_OUT_ADDRG <= 8'h01;
                        PIXEL_OUT_ADDRB <= 8'h02;
                    end
                else
                    begin
                        PIXEL_OUT_ADDRR <= PIXEL_OUT_ADDRR[7:0] + 3;
                        PIXEL_OUT_ADDRG <= PIXEL_OUT_ADDRG[7:0] + 3;
                        PIXEL_OUT_ADDRB <= PIXEL_OUT_ADDRB[7:0] + 3;
                    end
            default:
                begin
                    PIXEL_OUT_ADDRR <= PIXEL_OUT_ADDRR;
                    PIXEL_OUT_ADDRG <= PIXEL_OUT_ADDRG;
                    PIXEL_OUT_ADDRB <= PIXEL_OUT_ADDRB;
                end
	endcase

//initialization for rotated address
always @(*)
    if (I_CP_DIRECTION) //counter-clockwise
        case (I_CP_DEGREES) 
            P_DEG_0:
                begin
                    pixel_r = 8'h00;
                    pixel_g = 8'h01;
                    pixel_b = 8'h02;
                end
            P_DEG_90:
                begin
                    pixel_r = 8'h15;
                    pixel_g = 8'h16;
                    pixel_b = 8'h17;
                end
            P_DEG_180:
                begin
                    pixel_r = 8'hbd;
                    pixel_g = 8'hbe;
                    pixel_b = 8'hbf;
                end
            P_DEG_270:
                begin
                    pixel_r = 8'ha8;
                    pixel_g = 8'ha9;
                    pixel_b = 8'haa;
                end
            default:
                begin
                    pixel_r = 8'h00;
                    pixel_g = 8'h01;
                    pixel_b = 8'h02;
                end
        endcase
    else //clockwise 
        case (I_CP_DEGREES) 
            P_DEG_0:
                begin
                    pixel_r = 8'h00;
                    pixel_g = 8'h01;
                    pixel_b = 8'h02;
                end
            P_DEG_90:
                begin
                    pixel_r = 8'ha8;
                    pixel_g = 8'ha9;
                    pixel_b = 8'haa;
                end
            P_DEG_180:
                begin
                    pixel_r = 8'hbd;
                    pixel_g = 8'hbe;
                    pixel_b = 8'hbf;
                end
            P_DEG_270:
                begin
                    pixel_r = 8'h15;
                    pixel_g = 8'h16;
                    pixel_b = 8'h17;
                end
            default:
                begin
                    pixel_r = 8'h00;
                    pixel_g = 8'h01;
                    pixel_b = 8'h02;
                end
        endcase

//base address increment/decremet for 90 deg or 270 deg
always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	begin 
	    base_r <= 8'h00;
	    base_g <= 8'h01;
	    base_b <= 8'h02;
	end
    else 
	case (next_state) 
	    P_IDLE: 
		begin
		    base_r <= pixel_r;
		    base_g <= pixel_g;
		    base_b <= pixel_b;
		end
	    P_READ:
		if (trans_count == 6'h3e)
		    begin
			base_r <= base_r;
			base_g <= base_g;
			base_b <= base_b;
		    end
		else
		    if (increment)
			if (beat_count == 3'h6)
			    begin
				base_r <= base_r - 3;
				base_g <= base_g - 3;
				base_b <= base_b - 3;
			    end
			else
			    begin 
				base_r <= base_r;
				base_g <= base_g;
				base_b <= base_b;
			    end
		    else
			if (beat_count == 3'h6)
			    begin
				base_r <= base_r + 3;
				base_g <= base_g + 3;
				base_b <= base_b + 3;
			    end
	    P_WRITE:
		if (trans_count == 6'h3e)
		    begin
			base_r <= pixel_r;
			base_g <= pixel_g;
			base_b <= pixel_b;
		    end
		else
		    begin
			base_r <= base_r;
			base_g <= base_g;
			base_b <= base_b;
		    end
            default:
                begin 
                    base_r <= 8'h00;
                    base_g <= 8'h01;
                    base_b <= 8'h02;
                end
	endcase

//data from input buffer to the output buffer (output buffer side)
always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	begin
	    addr_r <= 8'h00;
	    addr_g <= 8'h01;
	    addr_b <= 8'h02;
	end
    else
	case (next_state) 
	    P_IDLE:
		begin
		    addr_r <= pixel_r;
		    addr_g <= pixel_g;
		    addr_b <= pixel_b;
		end
	    P_READ:
		//if (next_state != P_WRITE)
		    if (increment)
			if (beat_count == 3'h7)
			    begin
				addr_r <= base_r;
				addr_g <= base_g;
				addr_b <= base_b;
			    end
			else 
			    begin
				addr_r <= addr_r + 24;
				addr_g <= addr_g + 24;
				addr_b <= addr_b + 24;
			    end
		    else 
			if (!decrement)
			    if (I_CP_DIRECTION)
				begin
				    addr_r <= addr_r + 3;
				    addr_g <= addr_g + 3;
				    addr_b <= addr_b + 3;
				end
			    else
				begin
				    addr_r <= addr_r - 3;
				    addr_g <= addr_g - 3;
				    addr_b <= addr_b - 3;
				end
			else 
			    if (beat_count == 3'h7)
				begin
				    addr_r <= base_r;
				    addr_g <= base_g;
				    addr_b <= base_b;
				end
			    else
				begin
				    addr_r <= addr_r - 24;
				    addr_g <= addr_g - 24;
				    addr_b <= addr_b - 24;
				end
		//else 
		//    begin
		//	addr_r <= addr_r;
		//	addr_g <= addr_g;
		//	addr_b <= addr_b;
		//    end
	    P_WRITE:
		if (trans_count == 6'h3f)
		    begin
			addr_r <= base_r;
			addr_g <= base_g;
			addr_b <= base_b;
		    end
		else 
		    begin
			addr_r <= addr_r;
			addr_g <= addr_g;
			addr_b <= addr_b;
		    end
            default:
                begin
                    addr_r <= 8'h00;
                    addr_g <= 8'h01;
                    addr_b <= 8'h02;
                end
	endcase

always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	begin
	    PIXEL_IN_ADDRR <= 8'h00;
	    PIXEL_IN_ADDRG <= 8'h01;
	    PIXEL_IN_ADDRB <= 8'h02;
	end
    else
        if (next_state == P_IDLE)
            begin
                PIXEL_IN_ADDRR <= 8'h00;
                PIXEL_IN_ADDRG <= 8'h01;
                PIXEL_IN_ADDRB <= 8'h02;
            end
        else 
            begin
                PIXEL_IN_ADDRR <= addr_0;
                PIXEL_IN_ADDRG <= addr_0 + 1;
                PIXEL_IN_ADDRB <= addr_0 + 2;
            end

always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	begin
	    PIXEL_OUT_ADDR0 <= 8'h00;
	    PIXEL_OUT_ADDR1 <= 8'h01;
	    PIXEL_OUT_ADDR2 <= 8'h02;
	    PIXEL_OUT_ADDR3 <= 8'h03;
	end
    else 
	case (next_state)
	    P_IDLE:
		begin
		    PIXEL_OUT_ADDR0 <= 8'h00;
		    PIXEL_OUT_ADDR1 <= 8'h01;
		    PIXEL_OUT_ADDR2 <= 8'h02;
		    PIXEL_OUT_ADDR3 <= 8'h03;
		end
	    P_WRITE:
                if (trans_count == 6'h3f)
                    begin
                        PIXEL_OUT_ADDR0 <= 8'h00;
                        PIXEL_OUT_ADDR1 <= 8'h01;
                        PIXEL_OUT_ADDR2 <= 8'h02;
                        PIXEL_OUT_ADDR3 <= 8'h03;
                    end
                else
                    if ((beat_count != 3'h5) && (beat_count != 3'h6))
                        begin
                            PIXEL_OUT_ADDR0 <= PIXEL_OUT_ADDR0[7:0] + 4;
                            PIXEL_OUT_ADDR1 <= PIXEL_OUT_ADDR1[7:0] + 4;
                            PIXEL_OUT_ADDR2 <= PIXEL_OUT_ADDR2[7:0] + 4;
                            PIXEL_OUT_ADDR3 <= PIXEL_OUT_ADDR3[7:0] + 4;
                        end
                    else 
                        begin
                            PIXEL_OUT_ADDR0 <= PIXEL_OUT_ADDR0;
                            PIXEL_OUT_ADDR1 <= PIXEL_OUT_ADDR1;
                            PIXEL_OUT_ADDR2 <= PIXEL_OUT_ADDR2;
                            PIXEL_OUT_ADDR3 <= PIXEL_OUT_ADDR3;
                        end
            default:
                begin
                    PIXEL_OUT_ADDR0 <= 8'h00;
                    PIXEL_OUT_ADDR1 <= 8'h01;
                    PIXEL_OUT_ADDR2 <= 8'h02;
                    PIXEL_OUT_ADDR3 <= 8'h03;
                end
	endcase

endmodule
