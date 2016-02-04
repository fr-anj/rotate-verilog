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

integer i,j;

reg [7:0] REGISTER_FILE [59:0];

wire [5:0] address1;
wire [5:0] address2;
wire [5:0] address3;
wire [5:0] address4;

assign address1 = {I_PADDR[5:2],2'h0};
assign address2 = address1 + 6'h01;
assign address3 = address1 + 6'h02;
assign address4 = address1 + 6'h03;

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
	    REGISTER_FILE[i] <= 8'h00;
    else 
	if (I_PSEL && I_PENABLE && I_PWRITE)
	    begin
		REGISTER_FILE[address1]	<= I_PWDATA[7:0];
		REGISTER_FILE[address2]	<= I_PWDATA[15:8];
		REGISTER_FILE[address3]	<= I_PWDATA[23:16];
		REGISTER_FILE[address4]	<= I_PWDATA[31:24];
	    end
	else
	    for (j = 0; j < 60; j = j + 1)
		REGISTER_FILE[j] <= REGISTER_FILE[j];

always @(posedge I_PCLK)
    if (!I_PRESET_N)
	O_PRDATA <= 32'h00000000;
    else 
	if (I_PSEL && I_PENABLE && !I_PWRITE)
	    begin
		O_PRDATA[7:0] 	<= REGISTER_FILE[address1];
		O_PRDATA[15:8] 	<= REGISTER_FILE[address2];
		O_PRDATA[23:16] 	<= REGISTER_FILE[address3];
		O_PRDATA[31:24] 	<= REGISTER_FILE[address4];
	    end
	else 
	    O_PRDATA <= O_PRDATA;

endmodule
