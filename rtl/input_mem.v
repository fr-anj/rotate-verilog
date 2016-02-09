`timescale 1ns/1ps

module input_mem (
    output reg [7:0] O_PIXEL_B,
    output reg [7:0] O_PIXEL_G,
    output reg [7:0] O_PIXEL_R,

    input [31:0] I_HWDATA,
    input [7:0] I_PIXEL_IN_ADDR0,
    input [7:0] I_PIXEL_IN_ADDR1,
    input [7:0] I_PIXEL_IN_ADDR2,
    input [7:0] I_PIXEL_IN_ADDR3,
    input [7:0] I_PIXEL_OUT_ADDRB,
    input [7:0] I_PIXEL_OUT_ADDRG,
    input [7:0] I_PIXEL_OUT_ADDRR,
    
    input I_HRESET_N,
    input I_HCLK
);

integer i;

reg [7:0] memory [63:0];

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	for (i = 0; i < 64; i = i + 1)
	    memory[i] <= 8'h00;
    else 
	begin 
	    memory[I_PIXEL_IN_ADDR0] <= I_HWDATA[7:0];
	    memory[I_PIXEL_IN_ADDR1] <= I_HWDATA[15:8];
	    memory[I_PIXEL_IN_ADDR2] <= I_HWDATA[23:16];
	    memory[I_PIXEL_IN_ADDR3] <= I_HWDATA[31:24];
	end

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	O_PIXEL_B <= 8'h00;
    else 
	if (I_PIXEL_OUT_ADDRB == I_PIXEL_IN_ADDR0)
	    O_PIXEL_B <= I_HWDATA[7:0];
	else if (I_PIXEL_OUT_ADDRB == I_PIXEL_IN_ADDR1)
	    O_PIXEL_B <= I_HWDATA[15:8];
	else if (I_PIXEL_OUT_ADDRB == I_PIXEL_IN_ADDR2)
	    O_PIXEL_B <= I_HWDATA[23:16];
	else if (I_PIXEL_OUT_ADDRB ==  I_PIXEL_IN_ADDR3)
	    O_PIXEL_B <= I_HWDATA[31:24];
	else 
	    O_PIXEL_B <= memory[I_PIXEL_OUT_ADDRB];

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	O_PIXEL_G <= 8'h00;
    else 
	if (I_PIXEL_OUT_ADDRG == I_PIXEL_IN_ADDR0)
	    O_PIXEL_G <= I_HWDATA[7:0];
	else if (I_PIXEL_OUT_ADDRG == I_PIXEL_IN_ADDR1)
	    O_PIXEL_G <= I_HWDATA[15:8];
	else if (I_PIXEL_OUT_ADDRG == I_PIXEL_IN_ADDR2)
	    O_PIXEL_G <= I_HWDATA[23:16];
	else if (I_PIXEL_OUT_ADDRG ==  I_PIXEL_IN_ADDR3)
	    O_PIXEL_G <= I_HWDATA[31:24];
	else 
	    O_PIXEL_G <= memory[I_PIXEL_OUT_ADDRG];

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	O_PIXEL_R <= 8'h00;
    else 
	if (I_PIXEL_OUT_ADDRR == I_PIXEL_IN_ADDR0)
	    O_PIXEL_R <= I_HWDATA[7:0];
	else if (I_PIXEL_OUT_ADDRR == I_PIXEL_IN_ADDR1)
	    O_PIXEL_R <= I_HWDATA[15:8];
	else if (I_PIXEL_OUT_ADDRR == I_PIXEL_IN_ADDR2)
	    O_PIXEL_R <= I_HWDATA[23:16];
	else if (I_PIXEL_OUT_ADDRR ==  I_PIXEL_IN_ADDR3)
	    O_PIXEL_R <= I_HWDATA[31:24];
	else 
	    O_PIXEL_R <= memory[I_PIXEL_OUT_ADDRR];

endmodule
