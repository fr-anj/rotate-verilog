`timescale 1ns/1ps

module input_mem (
    output reg [7:0] O_IMEM_PIXEL_B,
    output reg [7:0] O_IMEM_PIXEL_G,
    output reg [7:0] O_IMEM_PIXEL_R,

    input [31:0] I_IMEM_RDATA,
    input [7:0] I_IMEM_PIXEL_IN_ADDR0,
    input [7:0] I_IMEM_PIXEL_IN_ADDR1,
    input [7:0] I_IMEM_PIXEL_IN_ADDR2,
    input [7:0] I_IMEM_PIXEL_IN_ADDR3,
    input [7:0] I_IMEM_PIXEL_OUT_ADDRB,
    input [7:0] I_IMEM_PIXEL_OUT_ADDRG,
    input [7:0] I_IMEM_PIXEL_OUT_ADDRR,
    input I_IMEM_PAD,  
    input I_IMEM_WRITE, //from core pixel
    input I_IMEM_HRESET_N,
    input I_IMEM_HCLK
);

integer i;
reg [7:0] memory [191:0];

//write ahb data to the input buffer
always @(posedge I_IMEM_HCLK)
    if (!I_IMEM_HRESET_N)
	for (i = 0; i < 192; i = i + 1)
	    memory[i] <= 8'h00;
    else 
        if (I_IMEM_WRITE)
            begin 
                memory[I_IMEM_PIXEL_IN_ADDR0] <= I_IMEM_RDATA[7:0];
                memory[I_IMEM_PIXEL_IN_ADDR1] <= I_IMEM_RDATA[15:8];
                memory[I_IMEM_PIXEL_IN_ADDR2] <= I_IMEM_RDATA[23:16];
                memory[I_IMEM_PIXEL_IN_ADDR3] <= I_IMEM_RDATA[31:24];
            end
        else 
            begin 
                memory[I_IMEM_PIXEL_IN_ADDR0] <= memory[I_IMEM_PIXEL_IN_ADDR0];
                memory[I_IMEM_PIXEL_IN_ADDR1] <= memory[I_IMEM_PIXEL_IN_ADDR1];
                memory[I_IMEM_PIXEL_IN_ADDR2] <= memory[I_IMEM_PIXEL_IN_ADDR2];
                memory[I_IMEM_PIXEL_IN_ADDR3] <= memory[I_IMEM_PIXEL_IN_ADDR3];
            end

//read data form the input buffer
//data forward the input data
always @(posedge I_IMEM_HCLK)
    if (!I_IMEM_HRESET_N)
	O_IMEM_PIXEL_B <= 8'h00;
    else 
        if (I_IMEM_PAD)
            O_IMEM_PIXEL_B <= 8'h00; //fill with black as padding
        else 
	    if (I_IMEM_PIXEL_OUT_ADDRB == I_IMEM_PIXEL_IN_ADDR0)
		O_IMEM_PIXEL_B <= I_IMEM_RDATA[7:0];
	    else if (I_IMEM_PIXEL_OUT_ADDRB == I_IMEM_PIXEL_IN_ADDR1)
		O_IMEM_PIXEL_B <= I_IMEM_RDATA[15:8];
	    else if (I_IMEM_PIXEL_OUT_ADDRB == I_IMEM_PIXEL_IN_ADDR2)
		O_IMEM_PIXEL_B <= I_IMEM_RDATA[23:16];
	    else if (I_IMEM_PIXEL_OUT_ADDRB ==  I_IMEM_PIXEL_IN_ADDR3)
		O_IMEM_PIXEL_B <= I_IMEM_RDATA[31:24];
	    else 
		O_IMEM_PIXEL_B <= memory[I_IMEM_PIXEL_OUT_ADDRB];

always @(posedge I_IMEM_HCLK)
    if (!I_IMEM_HRESET_N)
	O_IMEM_PIXEL_G <= 8'h00;
    else 
        if (I_IMEM_PAD)
            O_IMEM_PIXEL_G <= 8'h00; //fill with black as padding
        else 
	    if (I_IMEM_PIXEL_OUT_ADDRG == I_IMEM_PIXEL_IN_ADDR0)
		O_IMEM_PIXEL_G <= I_IMEM_RDATA[7:0];
	    else if (I_IMEM_PIXEL_OUT_ADDRG == I_IMEM_PIXEL_IN_ADDR1)
		O_IMEM_PIXEL_G <= I_IMEM_RDATA[15:8];
	    else if (I_IMEM_PIXEL_OUT_ADDRG == I_IMEM_PIXEL_IN_ADDR2)
		O_IMEM_PIXEL_G <= I_IMEM_RDATA[23:16];
	    else if (I_IMEM_PIXEL_OUT_ADDRG ==  I_IMEM_PIXEL_IN_ADDR3)
		O_IMEM_PIXEL_G <= I_IMEM_RDATA[31:24];
	    else 
		O_IMEM_PIXEL_G <= memory[I_IMEM_PIXEL_OUT_ADDRG];

always @(posedge I_IMEM_HCLK)
    if (!I_IMEM_HRESET_N)
	O_IMEM_PIXEL_R <= 8'h00;
    else 
        if (I_IMEM_PAD)
            O_IMEM_PIXEL_R <= 8'h00; //fill with black as padding
        else 
            if (I_IMEM_PIXEL_OUT_ADDRR == I_IMEM_PIXEL_IN_ADDR0)
                O_IMEM_PIXEL_R <= I_IMEM_RDATA[7:0];
            else if (I_IMEM_PIXEL_OUT_ADDRR == I_IMEM_PIXEL_IN_ADDR1)
                O_IMEM_PIXEL_R <= I_IMEM_RDATA[15:8];
            else if (I_IMEM_PIXEL_OUT_ADDRR == I_IMEM_PIXEL_IN_ADDR2)
                O_IMEM_PIXEL_R <= I_IMEM_RDATA[23:16];
            else if (I_IMEM_PIXEL_OUT_ADDRR ==  I_IMEM_PIXEL_IN_ADDR3)
                O_IMEM_PIXEL_R <= I_IMEM_RDATA[31:24];
            else 
                O_IMEM_PIXEL_R <= memory[I_IMEM_PIXEL_OUT_ADDRR];

endmodule
