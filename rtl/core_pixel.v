`timescale 1ns/1ps

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

    input [15:0] I_CP_HEIGHT,
    input [15:0] I_CP_WIDTH,
    input [1:0]	 I_CP_DEGREES,
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

wire increment;
wire temp1;
wire temp2;
wire decrement;
wire temp3;
wire temp4;

assign temp1 = (I_CP_DIRECTION && (I_CP_DEGREES == P_DEG_90))? 1 : 0;
assign temp2 = ((!I_CP_DIRECTION) && (I_CP_DEGREES == P_DEG_270))? 1 : 0;
assign increment = temp1 || temp2;
assign temp3 = (I_CP_DIRECTION && (I_CP_DEGREES == P_DEG_270))? 1 : 0;
assign temp4 = ((!I_CP_DIRECTION) && (I_CP_DEGREES == P_DEG_90))? 1 : 0;
assign decrement = temp3 || temp4;

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
        trans_count <= trans_count + 1;

//count to 8
always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	beat_count <= 3'h0;
    else 
        beat_count <= beat_count + 1;

//data from AHB to input buffer - input buffer side
always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	begin
	    O_CP_PIXEL_IN_ADDR0 <= 8'h00;
	    O_CP_PIXEL_IN_ADDR1 <= 8'h01;
	    O_CP_PIXEL_IN_ADDR2 <= 8'h02;
	    O_CP_PIXEL_IN_ADDR3 <= 8'h03;
	end
    else 
	case (next_state)
	    P_IDLE:	
		begin
		    O_CP_PIXEL_IN_ADDR0 <= 8'h00;
		    O_CP_PIXEL_IN_ADDR1 <= 8'h01;
		    O_CP_PIXEL_IN_ADDR2 <= 8'h02;
		    O_CP_PIXEL_IN_ADDR3 <= 8'h03;
		end
	    P_READ:
		if (trans_count == 8'h3f)
		    begin
			O_CP_PIXEL_IN_ADDR0 <= 8'h00;
			O_CP_PIXEL_IN_ADDR1 <= 8'h01;
			O_CP_PIXEL_IN_ADDR2 <= 8'h02;
			O_CP_PIXEL_IN_ADDR3 <= 8'h03;
		    end
		else
                    if ((beat_count != 3'h5) && (beat_count != 3'h6))
                        begin
                            O_CP_PIXEL_IN_ADDR0 <= O_CP_PIXEL_IN_ADDR0 + 4;
                            O_CP_PIXEL_IN_ADDR1 <= O_CP_PIXEL_IN_ADDR1 + 4;
                            O_CP_PIXEL_IN_ADDR2 <= O_CP_PIXEL_IN_ADDR2 + 4;
                            O_CP_PIXEL_IN_ADDR3 <= O_CP_PIXEL_IN_ADDR3 + 4;
                        end
                    else 
                        begin
                            O_CP_PIXEL_IN_ADDR0 <= O_CP_PIXEL_IN_ADDR0;
                            O_CP_PIXEL_IN_ADDR1 <= O_CP_PIXEL_IN_ADDR1;
                            O_CP_PIXEL_IN_ADDR2 <= O_CP_PIXEL_IN_ADDR2;
                            O_CP_PIXEL_IN_ADDR3 <= O_CP_PIXEL_IN_ADDR3;
                        end
            default:
                begin
                    O_CP_PIXEL_IN_ADDR0 <= 8'h00;
                    O_CP_PIXEL_IN_ADDR1 <= 8'h00;
                    O_CP_PIXEL_IN_ADDR2 <= 8'h00;
                    O_CP_PIXEL_IN_ADDR3 <= 8'h00;
                end
        endcase
                
//data from input buffer to output buffer - input buffer side
always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	begin
	    O_CP_PIXEL_OUT_ADDRR <= 8'h00;
	    O_CP_PIXEL_OUT_ADDRG <= 8'h01;
	    O_CP_PIXEL_OUT_ADDRB <= 8'h02;
	end
    else 
	case (next_state)
	    P_IDLE:
		begin
		    O_CP_PIXEL_OUT_ADDRR <= 8'h00;
		    O_CP_PIXEL_OUT_ADDRG <= 8'h01;
		    O_CP_PIXEL_OUT_ADDRB <= 8'h02;
		end
	    P_READ:
                if (trans_count == 6'h3f)
                    begin 
                        O_CP_PIXEL_OUT_ADDRR <= 8'h00;
                        O_CP_PIXEL_OUT_ADDRG <= 8'h01;
                        O_CP_PIXEL_OUT_ADDRB <= 8'h02;
                    end
                else
                    begin
                        O_CP_PIXEL_OUT_ADDRR <= O_CP_PIXEL_OUT_ADDRR + 3;
                        O_CP_PIXEL_OUT_ADDRG <= O_CP_PIXEL_OUT_ADDRG + 3;
                        O_CP_PIXEL_OUT_ADDRB <= O_CP_PIXEL_OUT_ADDRB + 3;
                    end
            default:
                begin
                    O_CP_PIXEL_OUT_ADDRR <= 8'h00;
                    O_CP_PIXEL_OUT_ADDRG <= 8'h00;
                    O_CP_PIXEL_OUT_ADDRB <= 8'h00;
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
	    base_g <= 8'h00;
	    base_b <= 8'h00;
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
                    base_g <= 8'h00;
                    base_b <= 8'h00;
                end
	endcase

//data from input buffer to the output buffer (output buffer side)
always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	begin
	    addr_r <= 8'h00;
	    addr_g <= 8'h00;
	    addr_b <= 8'h00;
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
		if (next_state != P_WRITE)
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
		else 
		    begin
			addr_r <= addr_r;
			addr_g <= addr_g;
			addr_b <= addr_b;
		    end
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
                    addr_g <= 8'h00;
                    addr_b <= 8'h00;
                end
	endcase

always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	begin
	    O_CP_PIXEL_IN_ADDRR <= 8'h00;
	    O_CP_PIXEL_IN_ADDRG <= 8'h00;
	    O_CP_PIXEL_IN_ADDRB <= 8'h00;
	end
    else
        if (next_state == P_IDLE)
            begin
                O_CP_PIXEL_IN_ADDRR <= 8'h00;
                O_CP_PIXEL_IN_ADDRG <= 8'h00;
                O_CP_PIXEL_IN_ADDRB <= 8'h00;
            end
        else 
            begin
                O_CP_PIXEL_IN_ADDRR <= addr_r;
                O_CP_PIXEL_IN_ADDRG <= addr_g;
                O_CP_PIXEL_IN_ADDRB <= addr_b;
            end

always @(posedge I_CP_HCLK)
    if (!I_CP_HRESET_N)
	begin
	    O_CP_PIXEL_OUT_ADDR0 <= 8'h00;
	    O_CP_PIXEL_OUT_ADDR1 <= 8'h01;
	    O_CP_PIXEL_OUT_ADDR2 <= 8'h02;
	    O_CP_PIXEL_OUT_ADDR3 <= 8'h03;
	end
    else 
	case (next_state)
	    P_IDLE:
		begin
		    O_CP_PIXEL_OUT_ADDR0 <= 8'h00;
		    O_CP_PIXEL_OUT_ADDR1 <= 8'h01;
		    O_CP_PIXEL_OUT_ADDR2 <= 8'h02;
		    O_CP_PIXEL_OUT_ADDR3 <= 8'h03;
		end
	    P_WRITE:
                if (trans_count == 6'h3f)
                    begin
                        O_CP_PIXEL_OUT_ADDR0 <= 8'h00;
                        O_CP_PIXEL_OUT_ADDR1 <= 8'h01;
                        O_CP_PIXEL_OUT_ADDR2 <= 8'h02;
                        O_CP_PIXEL_OUT_ADDR3 <= 8'h03;
                    end
                else
                    if ((beat_count != 3'h5) && (beat_count != 3'h6))
                        begin
                            O_CP_PIXEL_OUT_ADDR0 <= O_CP_PIXEL_OUT_ADDR0 + 4;
                            O_CP_PIXEL_OUT_ADDR1 <= O_CP_PIXEL_OUT_ADDR1 + 4;
                            O_CP_PIXEL_OUT_ADDR2 <= O_CP_PIXEL_OUT_ADDR2 + 4;
                            O_CP_PIXEL_OUT_ADDR3 <= O_CP_PIXEL_OUT_ADDR3 + 4;
                        end
                    else 
                        begin
                            O_CP_PIXEL_OUT_ADDR0 <= O_CP_PIXEL_OUT_ADDR0;
                            O_CP_PIXEL_OUT_ADDR1 <= O_CP_PIXEL_OUT_ADDR1;
                            O_CP_PIXEL_OUT_ADDR2 <= O_CP_PIXEL_OUT_ADDR2;
                            O_CP_PIXEL_OUT_ADDR3 <= O_CP_PIXEL_OUT_ADDR3;
                        end
            default:
                begin
                    O_CP_PIXEL_OUT_ADDR0 <= 8'h00;
                    O_CP_PIXEL_OUT_ADDR1 <= 8'h00;
                    O_CP_PIXEL_OUT_ADDR2 <= 8'h00;
                    O_CP_PIXEL_OUT_ADDR3 <= 8'h00;
                end
	endcase

endmodule
