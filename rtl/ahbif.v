/*------------------------------------------------------------------
--------------------------------------------------------------------
DATE: 15/09/21														
	*from 120 errors to 30 from address always block				
DATE: 15/09/22														
	*0 errors 2 warnings left: openmore <not driven by a register>	
	*bug 1 -> SINGLE transaction									
DATE: 15/09/23														
	*bug 1 -FIXED-
	*bug 2 -> when hwrite is already asserted and and hgrant is not
	yet asserted and on the next clk cycle when hgrant is asserted
	the haddress is still the previous haddress
DATE: 15/09/24
	*bug 2 -FIXED-
	*bug 3 -> invalid I_SIZE transaction
DATE: 15/11/02
	*bug 3 -FIXED-
DATE: 15/11/03
	*changed I_COUNT to 5 bits
	*bug 4 -> LIMIT always asserted stuck at NSEQ
	*bug 4 -FIXED- *wasn't actual bug but bug on testbench
	*bug 5 -> transfer_count do nat latch value when BUSY
	*bug 5 -FIXED-
	*bug 6 -> BUSY next address crosses 1kb limit does not NSEQ
	*bug 6 -FIXED-
	*FINSIHED testing jurgen's scenarios
	*running spyglass..
		9 errors 18 warnings
	*fixing 9 errors 
		-> starc 2005 = 9 errors
		-FIXED-
		-> waveforms still the same
	*fixing 16 warnings
		->overflow warning -currently ignored-
		->feed through warning (I_WRITE and O_HWRITE) -currently ignored-
	*8 warnings left -currently ignored-
DATE: 15/11/04
	*added HRDATA
	*7 warnings
		-> feed through warning (HRDATA and O_RDATA) -currently ignored-
	*added O_RDATA
	*6 warnings

TODO: cleanup code
TODO: check signals if it corresponds to the current design specification
TODO: include HRESP
--------------------------------------------------------------------
------------------------------------------------------------------*/
`timescale 1ns/1ps

module ahbif (
	output reg		O_HBUSREQ,	//to arbiter
	output reg 	[31:0] 	O_HADDR,		//to slave
	output reg 	[1:0]	O_HTRANS,		//to slave
    	output 			O_HWRITE,		//to slave 
    	output reg 	[2:0]   O_HSIZE,		//to slave
	output reg 	[2:0]   O_HBURST,		//to slave
	output reg 	[31:0]  O_HWDATA,		//to slave
	output	 	[31:0]	O_RDATA,	//to input FIFO 

	input 		[31:0]	HRDATA,		//from slave

	input 			I_START,	//from register file
	input 		[2:0]	I_SIZE,		//from register file
	input 		[31:0]	I_ADDR,		//from core
	input 		[31:0]	I_WDATA,	//from output FIFO
	input 		[4:0]	I_COUNT,	//from core
	input 			I_WRITE,	//from core
	input 			I_BUSY,		//from core

	input 			HGRANT,		//from arbiter
	input 			HREADY,		//from slave
	input 			HRESETN_N,	
	input 			HCLK);		

reg [2:0] curr_state;
reg [2:0] next_state;
reg [3:0] transfer_count;
reg [1:0] transfer_type;
reg [2:0] burst_type;

reg [32:0] address;
reg [31:0] new_addr;
reg [31:0] data;
reg [31:0] addr_check;

//reg [2:0] size;
wire	LAST,
		LIMIT;

wire [1:0] temp; //address

parameter 	check1 = 32'h00000001,
		check2 = 32'h00000002,
		check4 = 32'h00000004;

parameter 	B8 	= 3'b000,
		B16	= 3'b001,
		B32 = 3'b010;

parameter	IDLE 	= 2'b00,
		BUSY 	= 2'b01,
		NSEQ 	= 2'b10,
		SEQ 	= 2'b11;

parameter 	SINGLE 	= 3'b000,
		INCR 	= 3'b001,
		INCR4	= 3'b011,
		INCR8	= 3'b101,
		INCR16	= 3'b111;

parameter 	s_idle		= 3'b000,
		s_busreq	= 3'b001,
		s_nseq		= 3'b010,
		s_seq		= 3'b011,
		s_busy 		= 3'b100,
		s_finish 	= 3'b101;

//current state
always @(posedge HCLK)
	if (!HRESETN_N)
		curr_state <= s_idle;
	else 
		curr_state <= next_state;

//next state
always @(*)
	if (!HRESETN_N)
		next_state = s_idle;
	else 
		case (curr_state)
			s_idle:
				if (I_START)
					next_state = s_busreq;
				else 
					next_state = s_idle;
			s_busreq:
				if (HREADY)
					if (HGRANT)
						next_state = s_nseq;
					else 
						next_state = s_busreq;
				else 
					next_state = s_busreq;
			s_nseq:
				if (HREADY)
					if (!I_BUSY)
/*						if (!LIMIT)
							if (LAST)
								next_state = s_finish;
							else 
								if (LAST)
									next_state = s_finish;
								else 
									next_state = s_seq;
						else 
							next_state = s_nseq;*/
						if (LAST)
							next_state = s_finish;
						else 
							if (LIMIT)
								next_state = s_nseq;
							else 
								next_state = s_seq;
					else 
						next_state = s_busy;
				else 
					next_state = s_nseq;
			s_seq:
				if (HREADY)
					if (!I_BUSY)
						/*if (!LIMIT)
							if (LAST)
								next_state = s_finish;
							else 
								if (LAST)
									next_state = s_finish;
								else 
									next_state = s_seq;
						else 
							next_state = s_nseq;*/
						if (LAST)
							next_state = s_finish;
						else 
							if (LIMIT)
								next_state = s_nseq;
							else 
								next_state = s_seq;
					else 
						next_state = s_busy;
				else 
					next_state = s_seq;
			s_busy:
				if (HREADY)
					if (I_BUSY)
						next_state = s_busy;
					else
						if (LIMIT)
							next_state = s_nseq;
						else
							next_state = s_seq;
				else 
					next_state = s_busy;
			s_finish:
				if (HREADY)
					if (I_START)
						next_state = s_busreq;
					else 
						next_state = s_idle;
				else 
					next_state = s_finish;
			default:
				next_state = s_idle;
		endcase

//address output 
always @(*)
	// if (!HRESETN_N)
	// 	O_HADDR = 32'h00000000;
	// else 
		O_HADDR = new_addr;

// assign O_HADDR = new_addr;

//address alignment
always @(*)
	if (!HRESETN_N)
		address = 32'h00000000;
	else 
		case (I_SIZE)
			B16:
				if (I_ADDR[0] != 1'b0)
					address = I_ADDR + 32'h00000001;
				else 
					address = I_ADDR;
			B32:
				if (I_ADDR[1:0] != 2'b00)
					address = I_ADDR + {29'h00000000,(3'h4 - {1'b0,temp})};
				else 
					address = I_ADDR;
			default:
				address = I_ADDR;
		endcase
		/*if (I_SIZE == B8)
			address = I_ADDR;
		else if (I_SIZE == B16)
			address = {I_ADDR[31:1],1'b0};
		else 
			address = {I_ADDR[31:2],2'b00};*/

//address calculation
always @(posedge HCLK)
	if (!HRESETN_N)
		new_addr <= 32'h00000000;
	else 
		if (next_state == s_seq || (next_state == s_nseq && LIMIT))
			case (I_SIZE)
				// B8:
				// 	new_addr <= new_addr + 1;
				B16: 	
					new_addr <= new_addr + 2;
				B32:
					new_addr <= new_addr + 4;
				default:
					new_addr <= new_addr + 1;
			endcase
		else if (next_state == s_nseq)
			new_addr <= address[31:0];
		else if (next_state == s_busy)
			new_addr <= new_addr;
		else 
			new_addr <= 32'h00000000;

//address check look ahead
always @(*)
	if (!HRESETN_N)
		addr_check = 32'h00000000;
	else 
/*		if (next_state == s_nseq)
			case (I_SIZE)
			B8:
				addr_check = new_addr + 1;
			B16:
				addr_check = new_addr + 2;
			B32:
				addr_check = new_addr + 4;
			default:
				addr_check = 32'h00000000;
			endcase
		else */
			case (I_SIZE)
				//B8:
				B16:
					addr_check = new_addr + check2;
				B32:
					addr_check = new_addr + check4;
				default:
				 	addr_check = new_addr + check1;
					//addr_check = 32'h00000000;
			endcase 

//write data output 
always @(posedge HCLK)
	if (!HRESETN_N)
		O_HWDATA <= 32'h00000000;
	else 
		if (I_WRITE)
			if ((next_state == s_seq) || (next_state == s_finish) || (next_state == s_nseq && LIMIT))
				O_HWDATA <= data;
			else if (next_state == s_busy)
				O_HWDATA <= O_HWDATA;
			else 
				O_HWDATA <= 32'h00000000;
		else 
			O_HWDATA <= 32'h00000000;

//write data process 
always @(*)
	if (!HRESETN_N)
		data = 32'h00000000;
	else 
		if (I_WRITE && (curr_state != s_busreq))
			case (I_SIZE)
				B16:
					data = {I_WDATA[15:0],I_WDATA[15:0]};				
				B32:
					data = I_WDATA;
				default:
					data = {I_WDATA[7:0],I_WDATA[7:0],I_WDATA[7:0],I_WDATA[7:0]};	
			endcase
		else 
			data = 32'h00000000;

//output transfer type
always @(*)
	// if (!HRESETN_N)
	// 	O_HTRANS = 2'b00;
	// else 
		O_HTRANS = transfer_type;

// assign O_HTRANS = transfer_type;

//process transfer type
always @(posedge HCLK)
	if (!HRESETN_N)
		transfer_type <= 2'b00;
	else 
		case (next_state)
			s_nseq:
				transfer_type <= NSEQ;
			s_seq:
				transfer_type <= SEQ;
			s_busy:
				transfer_type <= BUSY;
			default:
				transfer_type <= IDLE;
		endcase

//output burst type
always @(posedge HCLK)
	if (!HRESETN_N)
		O_HBURST <= 4'h0;
	else 
		if (next_state == s_idle)
			O_HBURST <= 4'h0;
		else 
			O_HBURST <= burst_type;

//process burst type
always @(*)
	if (!HRESETN_N)
		burst_type = 4'h0;
	else 
		case (I_COUNT)
			5'h01:
				burst_type = SINGLE;
			5'h04:
				burst_type = INCR4;
			5'h08:
				burst_type = INCR8;
			5'h10:
				burst_type = INCR16;
			default:
				burst_type = INCR;
		endcase

//output O_HSIZE
always @(posedge HCLK)
	if (!HRESETN_N)
		O_HSIZE <= 2'b00;
	else 
		if (next_state == s_idle)
			O_HSIZE <= 2'b00;
		else 
			if (I_SIZE == B8 || I_SIZE == B16 || I_SIZE == B32)
				O_HSIZE <= I_SIZE;
			else 
				O_HSIZE <= B32;

//bus request to arbiter
always @(posedge HCLK)
	if (!HRESETN_N)
		O_HBUSREQ <= 0;
	else 
		if (I_START)
			O_HBUSREQ <= 1;
		else 
			O_HBUSREQ <= O_HBUSREQ;

//process transfer counter
always @(posedge HCLK)
	if (!HRESETN_N)
		transfer_count <= 4'h0;
	else 
		if (next_state == s_busy)
			transfer_count <= transfer_count;
		else if (next_state == s_seq || (next_state == s_nseq && LIMIT))
			transfer_count <= transfer_count + 4'h1;
		else 
			transfer_count <= 4'h0;

//O_HSIZE correction
// always @(*)
// 	if (!HRESETN_N)
// 		size = 0;
// 	else 
// 		if (I_SIZE == B32)
// 			size = B32;
// 		else if (I_SIZE == B16)
// 			size = B16;
// 		else 
// 			size = B8;
assign O_RDATA = HRDATA;
assign temp = I_ADDR[1:0] & 2'h3;
assign LAST 	= ({1'b0,transfer_count} < (I_COUNT - 1))? 0 : 1;
assign LIMIT 	= (addr_check[11:0] == 11'h400)? 1 : 0;
assign O_HWRITE 	= I_WRITE;
endmodule
