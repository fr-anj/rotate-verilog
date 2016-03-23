`timescale 1ns/1ps

module ahbif (
	output reg [31:0] O_AHBIF_HADDR, //to slave
	output reg [31:0] O_AHBIF_HWDATA, //to slave
    	output reg [2:0] O_AHBIF_HSIZE,	//to slave
	output reg [2:0] O_AHBIF_HBURST, //to slave
	output reg [1:0] O_AHBIF_HTRANS, //to slave
	output reg O_AHBIF_HBUSREQ, //to arbiter
    	output O_AHBIF_HWRITE, //to slave 
        output O_AHBIF_READY, //to core
        //output O_AHBIF_BUFF_WRITE,

	//input [31:0] I_AHBIF_HRDATA, //from slave
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
reg [32:0] tmp_addr;
reg [31:0] data;
reg [31:0] addr_check;
reg READY;
//reg BUFF_WRITE;

wire LAST, LIMIT;

parameter 	//p_check1 = 32'h00000001,
		//p_check2 = 32'h00000002,
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

//ready signal to core
always @(posedge I_AHBIF_HCLK)
    if (!I_AHBIF_HRESET_N)
        READY <= 0;
    else 
        if (next_state == p_s_nseq)
            READY <= 1;
        else 
            READY <= READY;

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
                        if (I_AHBIF_STOP)
                                next_state = p_s_idle;
                        else 
                                next_state = p_s_busreq;
                else 
                        next_state = p_s_finish;
        default:
                next_state = p_s_idle;
    endcase

//address output 
always @(*)
    if (I_AHBIF_STOP)
	O_AHBIF_HADDR = 32'h0000_0000;
    else 
	    O_AHBIF_HADDR = tmp_addr[31:0];

always @(*)
    tmp_addr = new_addr + address[31:0];

//address alignment
always @(*)
        address = I_AHBIF_ADDR;

//address calculation
always @(posedge I_AHBIF_HCLK)
	if (!I_AHBIF_HRESET_N)
		new_addr <= 32'h00000000;
	else 
		if ((next_state == p_s_seq) || ((next_state == p_s_nseq) && LIMIT))
		    new_addr <= new_addr + 4;
		else if (next_state == p_s_nseq)
			new_addr <= 32'h0000_0000;

		else 
			new_addr <= new_addr;

//address check look ahead
always @(*)
	if (!I_AHBIF_HRESET_N)
		addr_check = 32'h00000000;
	else 
		addr_check = address + p_check4;

//write data output 
always @(*)
	O_AHBIF_HWDATA = data;


//write data process 
always @(*)
	if (!I_AHBIF_HRESET_N)
		data = 32'h00000000;
	else 
		data = I_AHBIF_WDATA;


//output transfer type
always @(*)
    if (I_AHBIF_STOP)
	O_AHBIF_HTRANS = 3'h0;
    else
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
				burst_type = P_INCR;

//output O_AHBIF_HSIZE
always @(posedge I_AHBIF_HCLK)
	if (!I_AHBIF_HRESET_N)
		O_AHBIF_HSIZE <= 2'b00;
	else 
		if (next_state == p_s_idle)
			O_AHBIF_HSIZE <= 2'b00;
		else 
			O_AHBIF_HSIZE <= I_AHBIF_SIZE;
			

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
		if ((next_state == p_s_seq) || ((next_state == p_s_nseq) && LIMIT))
			transfer_count <= transfer_count + 4'h1;
		else 
			transfer_count <= 4'h0;

assign LAST = ({1'b0,transfer_count} < (I_AHBIF_COUNT - 1))? 0 : 1;
assign LIMIT = (addr_check[11:0] == 11'h400)? 1 : 0;
assign O_AHBIF_HWRITE = I_AHBIF_WRITE;
assign O_AHBIF_READY = READY;
//assign O_AHBIF_BUFF_WRITE = BUFF_WRITE;

endmodule
