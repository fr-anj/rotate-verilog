module output_mem (
    output reg [31:0] O_WDATA,

    input [7:0] I_PIXEL_B,
    input [7:0] I_PIXEL_G,
    input [7:0] I_PIXEL_R,
    input [7:0] I_PIXEL_IN_ADDRB,
    input [7:0] I_PIXEL_IN_ADDRG,
    input [7:0] I_PIXEL_IN_ADDRR,
    input [7:0] I_PIXEL_OUT_ADDR0,
    input [7:0] I_PIXEL_OUT_ADDR1,
    input [7:0] I_PIXEL_OUT_ADDR2,
    input [7:0] I_PIXEL_OUT_ADDR3,

    input I_HRESET_N,
    input I_HCLK
);

integer i;

reg [7:0] memory [63:0];
reg [7:0] output0;
reg [7:0] output1;
reg [7:0] output2;
reg [7:0] output3;

always @(posedge I_HCLK)
    if (!I_HRESET_N)
       for (i = 0; i < 64; i = i + 1)
	   memory[i] <= 8'h00;
    else 
	begin
	    memory[I_PIXEL_IN_ADDRB] <= I_PIXEL_B;
	    memory[I_PIXEL_IN_ADDRG] <= I_PIXEL_G;
	    memory[I_PIXEL_IN_ADDRR] <= I_PIXEL_R;
	end

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	output0 <= 8'h00;
    else 
	if (I_PIXEL_OUT_ADDR0 == I_PIXEL_IN_ADDRB)
	    output0 <= I_PIXEL_B;
	else if (I_PIXEL_OUT_ADDR0 == I_PIXEL_IN_ADDRG)
	    output0 <= I_PIXEL_G;
	else if (I_PIXEL_OUT_ADDR0 == I_PIXEL_IN_ADDRR)
	    output0 <= I_PIXEL_R;
	else 
	    output0 <= memory[I_PIXEL_OUT_ADDR0];

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	output1 <= 8'h00;
    else 
	if (I_PIXEL_OUT_ADDR1 == I_PIXEL_IN_ADDRB)
	    output1 <= I_PIXEL_B;
	else if (I_PIXEL_OUT_ADDR1 == I_PIXEL_IN_ADDRG)
	    output1 <= I_PIXEL_G;
	else if (I_PIXEL_OUT_ADDR1 == I_PIXEL_IN_ADDRR)
	    output1 <= I_PIXEL_R;
	else 
	    output1 <= memory[I_PIXEL_OUT_ADDR1];

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	output2 <= 8'h00;
    else 
	if (I_PIXEL_OUT_ADDR2 == I_PIXEL_IN_ADDRB)
	    output2 <= I_PIXEL_B;
	else if (I_PIXEL_OUT_ADDR2 == I_PIXEL_IN_ADDRG)
	    output2 <= I_PIXEL_G;
	else if (I_PIXEL_OUT_ADDR2 == I_PIXEL_IN_ADDRR)
	    output2 <= I_PIXEL_R;
	else 
	    output2 <= memory[I_PIXEL_OUT_ADDR2];

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	output3 <= 8'h00;
    else 
	if (I_PIXEL_OUT_ADDR3 == I_PIXEL_IN_ADDRB)
	    output3 <= I_PIXEL_B;
	else if (I_PIXEL_OUT_ADDR3 == I_PIXEL_IN_ADDRG)
	    output3 <= I_PIXEL_G;
	else if (I_PIXEL_OUT_ADDR3 == I_PIXEL_IN_ADDRR)
	    output3 <= I_PIXEL_R;
	else 
	    output3 <= memory[I_PIXEL_OUT_ADDR3];

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	O_WDATA <= 32'h00000000;
    else 
	O_WDATA <= {output0,output1,output2,output3};

endmodule
