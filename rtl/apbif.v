`timescale 1ns/1ps

module apbif (
    output reg 	[31:0] 	O_PRDATA,
    output reg 		O_PREADY,
    
    input 		I_PSEL,
    input 		I_PENABLE,
    input 		I_PWRITE,
    input 	[31:0] 	I_PADDR,
    input 	[31:0] 	I_PWDATA,

    input 		I_PRESET_N,
    input 		I_PCLK
);

integer i;

reg [7:0] REGISTER_FILE [59:0];

wire [31:0] address;

assign address = {I_PADDR[31:0],2'h0};

always @(posedge I_PCLK)
    if (!I_PRESET_N)
	O_PREADY <= 0;
    else 
	if ((I_PSEL && !I_PENABLE) || (I_PENABLE && !I_PSEL))
	    O_PREADY <= 1;
	else
	    O_PREADY <= 0;

always @(posedge I_PCLK)
    if (!I_PRESET_N)
	for (i = 0; i < 60; i = i + 1)
	    begin
		REGISTER_FILE[i] <= 8'h00;
	    end
    else 
	if (I_PSEL && I_PENABLE && I_PWRITE)
	    for (i = 0; i < 60; i = i + 4)
		begin
		    if (i == address)
			begin
			    REGISTER_FILE[i] 	<= I_PWDATA[7:0];
			    REGISTER_FILE[i + 1] 	<= I_PWDATA[15:8];
			    REGISTER_FILE[i + 2] 	<= I_PWDATA[23:16];
			    REGISTER_FILE[i + 3] 	<= I_PWDATA[31:24];
			end
		    else
			begin
			    REGISTER_FILE[i] 	<= REGISTER_FILE[i];    
			    REGISTER_FILE[i + 1] 	<= REGISTER_FILE[i + 1]; 
			    REGISTER_FILE[i + 2] 	<= REGISTER_FILE[i + 2];
			    REGISTER_FILE[i + 3] 	<= REGISTER_FILE[i + 3];
			end
		end
	else
	    for (i = 0; i < 60; i = i + 1)
		begin
		    REGISTER_FILE[i] <= REGISTER_FILE[i];
		end

always @(posedge I_PCLK)
    if (!I_PRESET_N)
	O_PRDATA <= 32'h00000000;
    else 
	begin
	    O_PRDATA[7:0] <= REGISTER_FILE[address];
	    O_PRDATA[15:8] <= REGISTER_FILE[address + 1];
	    O_PRDATA[23:26] <= REGISTER_FILE[address + 2];
	    O_PRDATA[31:24] <= REGISTER_FILE[address + 3];
	end

endmodule
