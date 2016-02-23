`timescale 1ns/1ps

module ahbif (
	output reg [31:0] O_AHBIF_HADDR, //to slave
	output reg [31:0] O_AHBIF_HWDATA, //to slave
    	output reg [2:0] O_AHBIF_HSIZE,	//to slave
	output reg [2:0] O_AHBIF_HBURST, //to slave
	output reg [1:0] O_AHBIF_HTRANS, //to slave
	output reg O_AHBIF_HBUSREQ, //to arbiter
	output [31:0] O_AHBIF_RDATA, //to input FIFO 
    	output O_AHBIF_HWRITE, //to slave 

	input [31:0] I_AHBIF_HRDATA, //from slave
	input [31:0] I_AHBIF_ADDR, //from core
	input [31:0] I_AHBIF_WDATA, //from output FIFO
	input [4:0] I_AHBIF_COUNT, //from core
	input [2:0] I_AHBIF_SIZE, //from register file
        input I_AHBIF_STOP,
	input I_AHBIF_START, //from register file
	input I_AHBIF_WRITE, //from core
	input I_AHBIF_HGRANT, //from arbiter
	input I_AHBIF_HREADY,	//from slave
        input I_AHBIF_RESET, //from register file //soft_reset
	input I_AHBIF_HRESET_N,	
	input I_AHBIF_HCLK);		

reg [2:0] curr_state;
reg [2:0] next_state;
reg [3:0] transfer_count;
reg [1:0] transfer_type;
reg [2:0] burst_type;

reg [32:0] address;
reg [31:0] new_addr;
reg [31:0] data;
reg [31:0] addr_check;

wire LAST, LIMIT;

wire [1:0] temp; //address

parameter 	p_check1 = 32'h00000001,
		p_check2 = 32'h00000002,
		p_check4 = 32'h00000004;

parameter 	P_B8 = 3'b000,
		P_B16 = 3'b001,
		P_B32 = 3'b010;

parameter	P_IDLE = 2'b00,
//		P_BUSY = 2'b01,
		P_NSEQ = 2'b10,
		P_SEQ = 2'b11;

parameter 	P_SINGLE = 3'b000,
		P_INCR = 3'b001,
		P_INCR4	= 3'b011,
		P_INCR8	= 3'b101,
		P_INCR16 = 3'b111;

parameter 	p_s_idle = 3'b000,
		p_s_busreq = 3'b001,
		p_s_nseq = 3'b010,
		p_s_seq	= 3'b011,
		p_s_busy = 3'b100,
		p_s_finish = 3'b101;

//current state
always @(posedge I_AHBIF_HCLK)
	if (!I_AHBIF_HRESET_N)
		curr_state <= p_s_idle;
	else 
		curr_state <= next_state;

//next state
always @(*)
        case (curr_state)
                p_s_idle:
                        if (I_AHBIF_START)
                                next_state = p_s_busreq;
                        else 
                                next_state = p_s_idle;
                p_s_busreq:
                    if(I_AHBIF_RESET) //soft_reset
                        next_state = p_s_idle;
                    else 
                        if (I_AHBIF_HREADY)
                                if (I_AHBIF_HGRANT)
                                        next_state = p_s_nseq;
                                else 
                                        next_state = p_s_busreq;
                        else 
                                next_state = p_s_busreq;
                p_s_nseq:
                        if (I_AHBIF_HREADY)
                                if (LAST)
                                        next_state = p_s_finish;
                                else 
                                        if (LIMIT)
                                                next_state = p_s_nseq;
                                        else 
                                                next_state = p_s_seq;
                        else 
                                next_state = p_s_nseq;
                p_s_seq:
                        if (I_AHBIF_HREADY)
                                if (LAST)
                                        next_state = p_s_finish;
                                else 
                                        if (LIMIT)
                                                next_state = p_s_nseq;
                                        else 
                                                next_state = p_s_seq;
                        else 
                                next_state = p_s_seq;
                p_s_finish:
                    if (I_AHBIF_RESET)
                        next_state = p_s_idle;
                    else 
                        if (I_AHBIF_HREADY)
                                if (!I_AHBIF_STOP)
                                        next_state = p_s_busreq;
                                else 
                                        next_state = p_s_idle;
                        else 
                                next_state = p_s_finish;
                default:
                        next_state = p_s_idle;
        endcase

//address output 
always @(*)
    O_AHBIF_HADDR = new_addr;

//address alignment
always @(*)
        case (I_AHBIF_SIZE)
                P_B16:
                        if (I_AHBIF_ADDR[0] != 1'b0)
                                address = I_AHBIF_ADDR + 32'h00000001;
                        else 
                                address = I_AHBIF_ADDR;
                P_B32:
                        if (I_AHBIF_ADDR[1:0] != 2'b00)
                                address = I_AHBIF_ADDR + {29'h00000000,(3'h4 - {1'b0,temp})};
                        else 
                                address = I_AHBIF_ADDR;
                default:
                        address = I_AHBIF_ADDR;
        endcase

//address calculation
always @(posedge I_AHBIF_HCLK)
	if (!I_AHBIF_HRESET_N)
		new_addr <= 32'h00000000;
	else 
		if (next_state == p_s_seq || (next_state == p_s_nseq && LIMIT))
			case (I_AHBIF_SIZE)
				P_B16: 	
					new_addr <= new_addr + 2;
				P_B32:
					new_addr <= new_addr + 4;
				default:
					new_addr <= new_addr + 1;
			endcase
		else if (next_state == p_s_nseq)
			new_addr <= address[31:0];
		else if (next_state == p_s_busy)
			new_addr <= new_addr;
		else 
			new_addr <= 32'h00000000;

//address check look ahead
always @(*)
	if (!I_AHBIF_HRESET_N)
		addr_check = 32'h00000000;
	else 
                case (I_AHBIF_SIZE)
                        //P_B8:
                        P_B16:
                                addr_check = new_addr + p_check2;
                        P_B32:
                                addr_check = new_addr + p_check4;
                        default:
                                addr_check = new_addr + p_check1;
                endcase 

//write data output 
always @(posedge I_AHBIF_HCLK)
	if (!I_AHBIF_HRESET_N)
		O_AHBIF_HWDATA <= 32'h00000000;
	else 
		if (I_AHBIF_WRITE)
			if ((next_state == p_s_seq) || (next_state == p_s_finish) || (next_state == p_s_nseq && LIMIT))
				O_AHBIF_HWDATA <= data;
			else if (next_state == p_s_busy)
				O_AHBIF_HWDATA <= O_AHBIF_HWDATA;
			else 
				O_AHBIF_HWDATA <= 32'h00000000;
		else 
			O_AHBIF_HWDATA <= 32'h00000000;

//write data process 
always @(*)
	if (!I_AHBIF_HRESET_N)
		data = 32'h00000000;
	else 
		if (I_AHBIF_WRITE && (curr_state != p_s_busreq))
			case (I_AHBIF_SIZE)
				P_B16:
					data = {I_AHBIF_WDATA[15:0],I_AHBIF_WDATA[15:0]};				
				P_B32:
					data = I_AHBIF_WDATA;
				default:
					data = {I_AHBIF_WDATA[7:0],I_AHBIF_WDATA[7:0],I_AHBIF_WDATA[7:0],I_AHBIF_WDATA[7:0]};	
			endcase
		else 
			data = 32'h00000000;

//output transfer type
always @(*)
	O_AHBIF_HTRANS = transfer_type;

//process transfer type
always @(posedge I_AHBIF_HCLK)
	if (!I_AHBIF_HRESET_N)
		transfer_type <= 2'b00;
	else 
		case (next_state)
			p_s_nseq:
				transfer_type <= P_NSEQ;
			p_s_seq:
				transfer_type <= P_SEQ;
			default:
				transfer_type <= P_IDLE;
		endcase

//output burst type
always @(posedge I_AHBIF_HCLK)
	if (!I_AHBIF_HRESET_N)
		O_AHBIF_HBURST <= 4'h0;
	else 
		if (next_state == p_s_idle)
			O_AHBIF_HBURST <= 4'h0;
		else 
			O_AHBIF_HBURST <= burst_type;

//process burst type
always @(*)
	if (!I_AHBIF_HRESET_N)
		burst_type = 4'h0;
	else 
		case (I_AHBIF_COUNT)
			5'h01:
				burst_type = P_SINGLE;
			5'h04:
				burst_type = P_INCR4;
			5'h08:
				burst_type = P_INCR8;
			5'h10:
				burst_type = P_INCR16;
			default:
				burst_type = P_INCR;
		endcase

//output O_AHBIF_HSIZE
always @(posedge I_AHBIF_HCLK)
	if (!I_AHBIF_HRESET_N)
		O_AHBIF_HSIZE <= 2'b00;
	else 
		if (next_state == p_s_idle)
			O_AHBIF_HSIZE <= 2'b00;
		else 
			if (I_AHBIF_SIZE == P_B8 || I_AHBIF_SIZE == P_B16 || I_AHBIF_SIZE == P_B32)
				O_AHBIF_HSIZE <= I_AHBIF_SIZE;
			else 
				O_AHBIF_HSIZE <= P_B32;

//bus request to arbiter
always @(posedge I_AHBIF_HCLK)
	if (!I_AHBIF_HRESET_N)
		O_AHBIF_HBUSREQ <= 0;
	else 
            if (I_AHBIF_START)
                    O_AHBIF_HBUSREQ <= 1;
            else 
                if (I_AHBIF_STOP)
                    O_AHBIF_HBUSREQ <= 0;
                else 
                    O_AHBIF_HBUSREQ <= O_AHBIF_HBUSREQ;

//process transfer counter
always @(posedge I_AHBIF_HCLK)
	if (!I_AHBIF_HRESET_N)
		transfer_count <= 4'h0;
	else 
		if (next_state == p_s_busy)
			transfer_count <= transfer_count;
		else if (next_state == p_s_seq || (next_state == p_s_nseq && LIMIT))
			transfer_count <= transfer_count + 4'h1;
		else 
			transfer_count <= 4'h0;

assign O_AHBIF_RDATA = (I_AHBIF_RESET)? 32'h0000_0000 : I_AHBIF_HRDATA; //treat as invalid when soft reset
assign temp = I_AHBIF_ADDR[1:0] & 2'h3;
assign LAST = ({1'b0,transfer_count} < (I_AHBIF_COUNT - 1))? 0 : 1;
assign LIMIT = (addr_check[11:0] == 11'h400)? 1 : 0;
assign O_AHBIF_HWRITE = I_AHBIF_WRITE;

endmodule
