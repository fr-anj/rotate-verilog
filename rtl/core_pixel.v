`timescale 1ns/1ps

/**
*Things to take note of 
    * There are 64 pixels
    * 192 addresses 
    * so increment and decrements
    * are by 3s not 1s
    * TODO: edit functional specifications 
    *       fixed address values (decrement/increment)
    * TODO: check code is it corresponds to 
    *       these notes
    * going in requires 4 8bits so 
    * increment or decrements are by 4s
    * TODO: make sure address in (input_mem)
    * 	    and address out (output_mem)
    * 	    follows
    * PIXEL_IN_ADDR_0123 --> by 4s --> from ahb to input_mem
    * PIXEL_OUT_ADDR_RGB --> by 3s --> from input_mem to output_mem
    * PIXEL_IN_ADDR_RGB  --> by 3s --> from input_mem to output_mem
    * PIXEL_OUT_ADDR_0123 --> by 4s --> from output_mem to ahb

    * TODO: limit output depending on height and width
    * TODO: fix state transition read->write->read 
    * 	    this should not have happened 
    *
    * #####I DON'T THINK IT IS NEEDED
    * TODO: assess use of height and width for module
    *       >use the modulo 8 to fill with black
    * #####I DON'T THINK IT IS NEEDED FOR THIS.. DMA will handle
    *
    * 
    * TODO: consider HEIGHT and WIDTH registers for core_set instead of this
    * 	    this module.       
*/

module core_pixel (
    output reg [7:0] O_PIXEL_IN_ADDR0,
    output reg [7:0] O_PIXEL_IN_ADDR1,
    output reg [7:0] O_PIXEL_IN_ADDR2,
    output reg [7:0] O_PIXEL_IN_ADDR3,
    output reg [7:0] O_PIXEL_OUT_ADDRB,
    output reg [7:0] O_PIXEL_OUT_ADDRG,
    output reg [7:0] O_PIXEL_OUT_ADDRR,
    output reg [7:0] O_PIXEL_OUT_ADDR0,
     
    output reg [7:0] O_PIXEL_OUT_ADDR1,
    output reg [7:0] O_PIXEL_OUT_ADDR2,
    output reg [7:0] O_PIXEL_OUT_ADDR3,
    output reg [7:0] O_PIXEL_IN_ADDRR,
    output reg [7:0] O_PIXEL_IN_ADDRG,
    output reg [7:0] O_PIXEL_IN_ADDRB,

    //output reg O_DONE_READ,
    //output reg O_DONE_WRITE,

    input [15:0] I_HEIGHT,	//TODO: remove this in specs and code
    input [15:0] I_WIDTH,	//TODO: remove this in specs and code
    input 	 I_DIRECTION,
    input [1:0]	 I_DEGREES,
    input 	 I_DMA_READY,
    input 	 I_START,

    input 	 I_HRESET_N,
    input 	 I_HCLK
);

parameter 	IDLE 	= 2'h0,
		READ 	= 2'h1,
		WRITE 	= 2'h2;

parameter 	DEG_0 	= 2'h0,
		DEG_90	= 2'h1,
		DEG_180 = 2'h2,
		DEG_270 = 2'h3;

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

//delay reg for O_PIXEL_IN_ADDR (RGB)
reg [7:0] addr_r;
reg [7:0] addr_g;
reg [7:0] addr_b;

wire increment;
wire temp1;
wire temp2;
wire decrement;
wire temp3;
wire temp4;

assign temp1 = (I_DIRECTION && (I_DEGREES == DEG_90))? 1 : 0;
assign temp2 = (!I_DIRECTION && (I_DEGREES == DEG_270))? 1 : 0;
assign increment = temp1 || temp2;
assign temp3 = (I_DIRECTION && (I_DEGREES == DEG_270))? 1 : 0;
assign temp4 = (!I_DIRECTION && (I_DEGREES == DEG_90))? 1 : 0;
assign decrement = temp3 || temp4;

/*
wire temp3;
wire count8;

assign temp3 = (I_DEGREE == DEG_90 || I_DEGREEE == DEG_270)? 1 : 0; 
assign count8 = (temp3 && beat_count == 3'h7)? 1 : 0;
*/

//state transition
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	curr_state <= IDLE;
    else 
	curr_state <= next_state;

//state conditions
always @(*)
    if (!I_HRESET_N)
	next_state <= IDLE;
    else 
	case(curr_state)
	    IDLE: 
		if (I_START)
		    next_state <= READ;
		else 
		    next_state <= IDLE;
	    READ:
		if (trans_count == 6'h3f)
		    next_state <= WRITE;
		else 
		    next_state <= READ;
	    WRITE:
		if (trans_count == 6'h3f)
		    next_state <= READ;
		else 
		    next_state <= WRITE;
	endcase

//count tot 64 
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	trans_count <= 6'h00;
    else 
	if (I_DMA_READY)
	    trans_count <= trans_count + 1;
	else 
	    trans_count <= trans_count; //pause count up

//count to 8
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	beat_count <= 3'h0;
    else 
	if (I_DMA_READY)
	    beat_count <= beat_count + 1;
	else 
	    beat_count <= beat_count;

//data from AHB to input buffer - input buffer side
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	begin
	    O_PIXEL_IN_ADDR0 <= 8'h00;
	    O_PIXEL_IN_ADDR1 <= 8'h00;
	    O_PIXEL_IN_ADDR2 <= 8'h00;
	    O_PIXEL_IN_ADDR3 <= 8'h00;
	end
    else 
	case (next_state)
	    IDLE:	
		begin
		    O_PIXEL_IN_ADDR0 <= 8'h00;
		    O_PIXEL_IN_ADDR1 <= 8'h01;
		    O_PIXEL_IN_ADDR2 <= 8'h02;
		    O_PIXEL_IN_ADDR3 <= 8'h03;
		end
	    READ:
		if (trans_count == 8'h3f)
		    begin
			O_PIXEL_IN_ADDR0 <= 8'h00;
			O_PIXEL_IN_ADDR1 <= 8'h01;
			O_PIXEL_IN_ADDR2 <= 8'h02;
			O_PIXEL_IN_ADDR3 <= 8'h03;
		    end
		else
		    if (I_DMA_READY)
			if (beat_count != 3'h5 && beat_count != 3'h6)
			    begin
				O_PIXEL_IN_ADDR0 <= O_PIXEL_IN_ADDR0 + 4;
				O_PIXEL_IN_ADDR1 <= O_PIXEL_IN_ADDR1 + 4;
				O_PIXEL_IN_ADDR2 <= O_PIXEL_IN_ADDR2 + 4;
				O_PIXEL_IN_ADDR3 <= O_PIXEL_IN_ADDR3 + 4;
			    end
			else 
			    begin
				O_PIXEL_IN_ADDR0 <= O_PIXEL_IN_ADDR0;
				O_PIXEL_IN_ADDR1 <= O_PIXEL_IN_ADDR1;
				O_PIXEL_IN_ADDR2 <= O_PIXEL_IN_ADDR2;
				O_PIXEL_IN_ADDR3 <= O_PIXEL_IN_ADDR3;
			    end
		    else 
			begin
			    O_PIXEL_IN_ADDR0 <= O_PIXEL_IN_ADDR0;
			    O_PIXEL_IN_ADDR1 <= O_PIXEL_IN_ADDR1;
			    O_PIXEL_IN_ADDR2 <= O_PIXEL_IN_ADDR2;
			    O_PIXEL_IN_ADDR3 <= O_PIXEL_IN_ADDR3;
			end
	endcase

//data from input buffer to output buffer - input buffer side
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	begin
	    O_PIXEL_OUT_ADDRR <= 8'h00;
	    O_PIXEL_OUT_ADDRG <= 8'h00;
	    O_PIXEL_OUT_ADDRB <= 8'h00;
	end
    else 
	case (next_state)
	    IDLE:
		begin
		    O_PIXEL_OUT_ADDRR <= 8'h00;
		    O_PIXEL_OUT_ADDRG <= 8'h01;
		    O_PIXEL_OUT_ADDRB <= 8'h02;
		end
	    READ:
		if (I_DMA_READY)
		    if (trans_count == 6'h3f)
			begin 
			    O_PIXEL_OUT_ADDRR <= 8'h00;
			    O_PIXEL_OUT_ADDRG <= 8'h01;
			    O_PIXEL_OUT_ADDRB <= 8'h02;
			end
		    else
			begin
			    O_PIXEL_OUT_ADDRR <= O_PIXEL_OUT_ADDRR + 3;
			    O_PIXEL_OUT_ADDRG <= O_PIXEL_OUT_ADDRG + 3;
			    O_PIXEL_OUT_ADDRB <= O_PIXEL_OUT_ADDRB + 3;
			end
		else 
		    begin
			O_PIXEL_OUT_ADDRR <= O_PIXEL_OUT_ADDRR;
			O_PIXEL_OUT_ADDRG <= O_PIXEL_OUT_ADDRG;
			O_PIXEL_OUT_ADDRB <= O_PIXEL_OUT_ADDRB;
		    end
	endcase

//initialization for rotated address
always @(*)
    if (!I_HRESET_N)
	begin
	    pixel_r <= 8'h00;
	    pixel_g <= 8'h00;
	    pixel_b <= 8'h00;
	end
    else
	if (I_DIRECTION) //counter-clockwise
	    case (I_DEGREES) //refer to function specification
		DEG_0:
		    begin
			pixel_r <= 8'h00;
			pixel_g <= 8'h01;
			pixel_b <= 8'h02;
		    end
		DEG_90:
		    begin
			pixel_r <= 8'h15;
			pixel_g <= 8'h16;
			pixel_b <= 8'h17;
		    end
		DEG_180:
		    begin
			pixel_r <= 8'hbd;
			pixel_g <= 8'hbe;
			pixel_b <= 8'hbf;
		    end
		DEG_270:
		    begin
			pixel_r <= 8'ha8;
			pixel_g <= 8'ha9;
			pixel_b <= 8'haa;
		    end
		default:
		    begin
			pixel_r <= 8'h00;
			pixel_g <= 8'h00;
			pixel_b <= 8'h00;
		    end
	    endcase
	else //clockwise 
	    case (I_DEGREES) //refer to function specification
		DEG_0:
		    begin
			pixel_r <= 8'h00;
			pixel_g <= 8'h01;
			pixel_b <= 8'h02;
		    end
		DEG_90:
		    begin
			pixel_r <= 8'ha8;
			pixel_g <= 8'ha9;
			pixel_b <= 8'haa;
		    end
		DEG_180:
		    begin
			pixel_r <= 8'hbd;
			pixel_g <= 8'hbe;
			pixel_b <= 8'hbf;
		    end
		DEG_270:
		    begin
			pixel_r <= 8'h15;
			pixel_g <= 8'h16;
			pixel_b <= 8'h17;
		    end
		default:
		    begin
			pixel_r <= 8'h00;
			pixel_g <= 8'h00;
			pixel_b <= 8'h00;
		    end
	    endcase

//base address increment/decrement for 90 deg or 270 deg
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	begin 
	    base_r <= 8'h00;
	    base_g <= 8'h00;
	    base_b <= 8'h00;
	end
    else 
	case (next_state) 
	    IDLE: 
		begin
		    base_r <= pixel_r;
		    base_g <= pixel_g;
		    base_b <= pixel_b;
		end
	    READ:
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
	    WRITE:
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
	endcase

//data from input buffer to the output buffer - output buffer side
//this is where rotation happens
//
// TODO: check if through mode or 180 since these do not need special rotation
//     	 addresses
always @(posedge I_HCLK)
    if (!I_HRESET_N)
	begin
	    addr_r <= 8'h00;
	    addr_g <= 8'h00;
	    addr_b <= 8'h00;
	end
    else
	case (curr_state) //1 clock cycle delay from pixel out address
	    IDLE:
		begin
		    addr_r <= pixel_r;
		    addr_g <= pixel_g;
		    addr_b <= pixel_b;
		end
	    READ:
		if (I_DMA_READY && next_state != WRITE)
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
			    if (I_DIRECTION)
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
		else 
		    begin
			addr_r <= addr_r;
			addr_g <= addr_g;
			addr_b <= addr_b;
		    end
	    WRITE:
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
	endcase

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	begin
	    O_PIXEL_IN_ADDRR <= 8'h00;
	    O_PIXEL_IN_ADDRG <= 8'h00;
	    O_PIXEL_IN_ADDRB <= 8'h00;
	end
    else
	begin
	    O_PIXEL_IN_ADDRR <= addr_r;
	    O_PIXEL_IN_ADDRG <= addr_g;
	    O_PIXEL_IN_ADDRB <= addr_b;
	end

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	begin
	    O_PIXEL_OUT_ADDR0 <= 8'h00;
	    O_PIXEL_OUT_ADDR1 <= 8'h00;
	    O_PIXEL_OUT_ADDR2 <= 8'h00;
	    O_PIXEL_OUT_ADDR3 <= 8'h00;
	end
    else 
	case (next_state)
	    IDLE:
		begin
		    O_PIXEL_OUT_ADDR0 <= 8'h00;
		    O_PIXEL_OUT_ADDR1 <= 8'h01;
		    O_PIXEL_OUT_ADDR2 <= 8'h02;
		    O_PIXEL_OUT_ADDR3 <= 8'h03;
		end
	    WRITE:
		if (I_DMA_READY)
		    if (trans_count == 6'h3f)
			begin
			    O_PIXEL_OUT_ADDR0 <= 8'h00;
			    O_PIXEL_OUT_ADDR1 <= 8'h01;
			    O_PIXEL_OUT_ADDR2 <= 8'h02;
			    O_PIXEL_OUT_ADDR3 <= 8'h03;
			end
		    else
			if (beat_count != 3'h5 && beat_count != 3'h6)
			    begin
				O_PIXEL_OUT_ADDR0 <= O_PIXEL_OUT_ADDR0 + 4;
				O_PIXEL_OUT_ADDR1 <= O_PIXEL_OUT_ADDR1 + 4;
				O_PIXEL_OUT_ADDR2 <= O_PIXEL_OUT_ADDR2 + 4;
				O_PIXEL_OUT_ADDR3 <= O_PIXEL_OUT_ADDR3 + 4;
			    end
			else 
			    begin
				O_PIXEL_OUT_ADDR0 <= O_PIXEL_OUT_ADDR0;
				O_PIXEL_OUT_ADDR1 <= O_PIXEL_OUT_ADDR1;
				O_PIXEL_OUT_ADDR2 <= O_PIXEL_OUT_ADDR2;
				O_PIXEL_OUT_ADDR3 <= O_PIXEL_OUT_ADDR3;
			    end
		else 
			begin
			    O_PIXEL_OUT_ADDR0 <= O_PIXEL_OUT_ADDR0;
			    O_PIXEL_OUT_ADDR1 <= O_PIXEL_OUT_ADDR1;
			    O_PIXEL_OUT_ADDR2 <= O_PIXEL_OUT_ADDR2;
			    O_PIXEL_OUT_ADDR3 <= O_PIXEL_OUT_ADDR3;
			end
	endcase

endmodule
