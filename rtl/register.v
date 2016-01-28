module register_file (
    // TODO: list all APB addresses needed

    output O_START,
    
    input I_SET,
    input I_PRESET_N,
    input I_PCLK
);

//state registers
reg [1:0] curr_state;
reg [1:0] next_state;

parameter
IDLE 	= 2'h0,
READ 	= 2'h2,
WRITE 	= 2'h3;

//state transition
always @(posedge I_PCLK)
    if (I_PRESET_N)
	curr_state <= IDLE;
    else 
	curr_state <= next_state;

//state conditions
always @(*)
    if (I_PRESET_N)
	next_state <= IDLE;
    else 
	case (curr_state)
	    IDLE:
		if (I_SET)
		    next_state <= READ;
		else 
		    next_state <= IDLE;
	    READ:
		//setting up registers
	    WRITE:
		//interrupt
	endcase


