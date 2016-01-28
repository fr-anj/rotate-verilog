module apbif (
    output reg [31:0] 	O_PRDATA,

    input 		I_PSEL,
    input 		I_PENABLE,
    input [31:0] 	I_PADDR,
    input 		I_PWRITE,
    input [31:0] 	I_PWDATA,

    input 		I_PRESET_N
    input 		I_PCLK,
);

reg [1:0] curr_state;
reg [1:0] next_state;

//registers
reg [

parameter 	IDLE	= 2'h0,
		SETUP 	= 2'h1,
		ENABLE	= 2'h2;

always @(posedge I_PCLK)
    if (!I_PRESET_N)
	curr_state <= IDLE;
    else 
	curr_state <= next_state;

always @(*)
    if (!I_PRESET_N)
	next_state <= IDLE;
    else 
	case (curr_state)
	    IDLE:
		if (I_PSEL)
		    next_state <= SETUP;
		else 
		    next_state <= IDLE;
	    SETUP:
		if (I_PENABLE)
		    next_state <= ENABLE;
		else 
		    next_state <= SETUP;
	    ENABLE:
		if (I_PSEL)
		    next_state <= SETUP;
		else 
		    next_state <= IDLE;
	endcase

always @(posedge I_HCLK)
    if (!I_PRESET_N)
	data <= 32'h00000000;
    else
	if (!I_PWRITE)
	    data <= regdata_out;
	else 
	    data <= data;

endmodule
