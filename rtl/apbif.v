`timescale 1ns/1ps

module apbif (
    output reg 	[31:0] 	O_PRDATA,
    output reg 		O_PREADY,
//    output reg 		O_INTERRUPT,

    output 	[31:0] 	O_DMA_SRC_IMG,
    output 	[31:0] 	O_DMA_DST_IMG,
    output 	[15:0] 	O_ROT_IMG_H,
    output 	[15:0] 	O_ROT_IMG_W,
    output 	[15:0] 	O_ROT_IMG_NEW_H,
    output 	[15:0] 	O_ROT_IMG_NEW_W,
    output 	[1:0] 	O_ROT_IMG_MODE,
    output  		O_ROT_IMG_DIR,
    output  		O_CTRL_START,
    output  		O_CTRL_RESET,
    output 		O_CTRL_INTR_MASK,
    output 		O_CTRL_BEF_MASK,	// TODO: confirm if read by core
    output 		O_CTRL_AFT_MASK,	// TODO: confirm if read by core
    output 		O_CTRL_INTR_CLEAR,
    output 		O_CTRL_BUSY,		// TODO: confirm if read by core

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

//request master to extend read state
always @(posedge I_PCLK)
    if (!I_PRESET_N)
	O_PREADY <= 0;
    else 
	if ((I_PSEL && !I_PENABLE) || (I_PENABLE && !I_PSEL))
	    O_PREADY <= 1;
	else
	    O_PREADY <= 0;

// TODO: change to case statement for self-clearing & non-writeable registers
// write to REGISTER_FILE
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

// TODO: change to case statement for non-readable registers
// to CPU
always @(posedge I_PCLK)
    if (!I_PRESET_N)
	O_PRDATA <= 32'h00000000;
    else 
	if (I_PSEL && I_PENABLE && !I_PWRITE)
	    begin
		O_PRDATA[7:0] 	<= REGISTER_FILE[address1];
		O_PRDATA[15:8] 	<= REGISTER_FILE[address2];
		O_PRDATA[23:16]	<= REGISTER_FILE[address3];
		O_PRDATA[31:24]	<= REGISTER_FILE[address4];
	    end
	else 
	    O_PRDATA <= O_PRDATA;

//to core
assign O_DMA_SRC_IMG = {REGISTER_FILE[6'h03],REGISTER_FILE[6'h02],REGISTER_FILE[6'h01],REGISTER_FILE[6'h00]};
assign O_DMA_DST_IMG = {REGISTER_FILE[6'h07],REGISTER_FILE[6'h06],REGISTER_FILE[6'h05],REGISTER_FILE[6'h04]};
assign O_ROT_IMG_H = {REGISTER_FILE[6'h09],REGISTER_FILE[6'h08]};
assign O_ROT_IMG_W = {REGISTER_FILE[6'h0d],REGISTER_FILE[6'h0c]};
assign O_ROT_IMG_NEW_H = {REGISTER_FILE[6'h11],REGISTER_FILE[6'h10]};
assign O_ROT_IMG_NEW_W = {REGISTER_FILE[6'h15],REGISTER_FILE[6'h14]};
assign O_ROT_IMG_MODE = REGISTER_FILE[6'h18][1:0]; 
assign O_ROT_IMG_DIR = REGISTER_FILE[6'h1c][0];
assign O_CTRL_START = REGISTER_FILE[6'h20][0];
assign O_CTRL_RESET = REGISTER_FILE[6'h24][0];
assign O_CTRL_INTR_MASK = REGISTER_FILE[6'h28][0];
assign O_CTRL_BEF_MASK = REGISTER_FILE[6'h2c][0];
assign O_CTRL_AFT_MASK = REGISTER_FILE[6'h30][0];
assign O_CTRL_INTR_CLEAR = REGISTER_FILE[6'h34][0];
assign O_CTRL_BUSY = REGISTER_FILE[6'h38][0];

endmodule
