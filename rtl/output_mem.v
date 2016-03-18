`timescale 1ns/1ps

module output_mem (
    output reg [31:0] O_OMEM_WDATA,

    input [7:0] I_OMEM_PIXEL_B,
    input [7:0] I_OMEM_PIXEL_G,
    input [7:0] I_OMEM_PIXEL_R,
    input [7:0] I_OMEM_PIXEL_IN_ADDRB,
    input [7:0] I_OMEM_PIXEL_IN_ADDRG,
    input [7:0] I_OMEM_PIXEL_IN_ADDRR,
    input [7:0] I_OMEM_PIXEL_OUT_ADDR0,
    input [7:0] I_OMEM_PIXEL_OUT_ADDR1,
    input [7:0] I_OMEM_PIXEL_OUT_ADDR2,
    input [7:0] I_OMEM_PIXEL_OUT_ADDR3,
    input I_OMEM_WRITE,
    input I_OMEM_HRESET_N,
    input I_OMEM_HCLK
);
integer i;

reg [7:0] memory [191:0];
reg [7:0] output0;
reg [7:0] output1;
reg [7:0] output2;
reg [7:0] output3;
reg [23:0] buff;

always @(posedge I_OMEM_HCLK)
    if (!I_OMEM_HRESET_N)
	buff <= 24'h00_0000;
    else
	if (I_OMEM_WRITE)
	buff <= {I_OMEM_PIXEL_IN_ADDRR, I_OMEM_PIXEL_IN_ADDRG, I_OMEM_PIXEL_IN_ADDRB};
	else
	    buff <= buff;

always @(posedge I_OMEM_HCLK)
    if (!I_OMEM_HRESET_N)
        for (i = 0; i < 192; i = i + 1)
            memory[i] <= 8'h00;
    else 
        if (I_OMEM_WRITE)
            begin
                memory[buff[7:0]] <= I_OMEM_PIXEL_B;
                memory[buff[15:8]] <= I_OMEM_PIXEL_G;
                memory[buff[23:16]] <= I_OMEM_PIXEL_R;
            end
        else 
            begin
                memory[buff[7:0]] <= memory[I_OMEM_PIXEL_IN_ADDRB];
                memory[buff[15:8]] <= memory[I_OMEM_PIXEL_IN_ADDRG];
                memory[buff[23:16]] <= memory[I_OMEM_PIXEL_IN_ADDRR];
            end

always @(posedge I_OMEM_HCLK)
    if (!I_OMEM_HRESET_N)
	output0 <= 8'h00;
    else 
	if (I_OMEM_PIXEL_OUT_ADDR0 == I_OMEM_PIXEL_IN_ADDRB)
	    output0 <= memory[I_OMEM_PIXEL_IN_ADDRB];
	else if (I_OMEM_PIXEL_OUT_ADDR0 == I_OMEM_PIXEL_IN_ADDRG)
	    output0 <= memory[I_OMEM_PIXEL_IN_ADDRG];
	else if (I_OMEM_PIXEL_OUT_ADDR0 == I_OMEM_PIXEL_IN_ADDRR)
	    output0 <= memory[I_OMEM_PIXEL_IN_ADDRR];
	else 
	    output0 <= memory[I_OMEM_PIXEL_OUT_ADDR0];

always @(posedge I_OMEM_HCLK)
    if (!I_OMEM_HRESET_N)
	output1 <= 8'h00;
    else 
	if (I_OMEM_PIXEL_OUT_ADDR1 == I_OMEM_PIXEL_IN_ADDRB)
	    output1 <= memory[I_OMEM_PIXEL_IN_ADDRB];
	else if (I_OMEM_PIXEL_OUT_ADDR1 == I_OMEM_PIXEL_IN_ADDRG)
	    output1 <= memory[I_OMEM_PIXEL_IN_ADDRG];
	else if (I_OMEM_PIXEL_OUT_ADDR1 == I_OMEM_PIXEL_IN_ADDRR)
	    output1 <= memory[I_OMEM_PIXEL_IN_ADDRR];
	else 
	    output1 <= memory[I_OMEM_PIXEL_OUT_ADDR1];

always @(posedge I_OMEM_HCLK)
    if (!I_OMEM_HRESET_N)
	output2 <= 8'h00;
    else 
	if (I_OMEM_PIXEL_OUT_ADDR2 == I_OMEM_PIXEL_IN_ADDRB)
	    output2 <= memory[I_OMEM_PIXEL_IN_ADDRB];
	else if (I_OMEM_PIXEL_OUT_ADDR2 == I_OMEM_PIXEL_IN_ADDRG)
	    output2 <= memory[I_OMEM_PIXEL_IN_ADDRG];
	else if (I_OMEM_PIXEL_OUT_ADDR2 == I_OMEM_PIXEL_IN_ADDRR)
	    output2 <= memory[I_OMEM_PIXEL_IN_ADDRR];
	else 
	    output2 <= memory[I_OMEM_PIXEL_OUT_ADDR2];

always @(posedge I_OMEM_HCLK)
    if (!I_OMEM_HRESET_N)
	output3 <= 8'h00;
    else 
	if (I_OMEM_PIXEL_OUT_ADDR3 == I_OMEM_PIXEL_IN_ADDRB)
	    output3 <= memory[I_OMEM_PIXEL_IN_ADDRB];
	else if (I_OMEM_PIXEL_OUT_ADDR3 == I_OMEM_PIXEL_IN_ADDRG)
	    output3 <= memory[I_OMEM_PIXEL_IN_ADDRG];
	else if (I_OMEM_PIXEL_OUT_ADDR3 == I_OMEM_PIXEL_IN_ADDRR)
	    output3 <= memory[I_OMEM_PIXEL_IN_ADDRR];
	else 
	    output3 <= memory[I_OMEM_PIXEL_OUT_ADDR3];

always @(*)
    O_OMEM_WDATA <= {output3,output2,output1,output0};

endmodule
