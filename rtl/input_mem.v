`timescale 1ns/1ps

module input_mem (
    output [31:0] O_IMEM_WDATA,
    input [7:0] I_IMEM_PIXEL_OUT_ADDR0,
    input [7:0] I_IMEM_PIXEL_OUT_ADDR1,
    input [7:0] I_IMEM_PIXEL_OUT_ADDR2,
    input [7:0] I_IMEM_PIXEL_OUT_ADDR3,

    input [31:0] I_IMEM_RDATA,
    input [7:0] I_IMEM_PIXEL_IN_ADDR0,
    input [7:0] I_IMEM_PIXEL_IN_ADDR1,
    input [7:0] I_IMEM_PIXEL_IN_ADDR2,
    input [7:0] I_IMEM_PIXEL_IN_ADDR3,
    input I_IMEM_WRITE, //from core pixel
    input I_IMEM_HRESET_N,
    input I_IMEM_HCLK
);

integer i;
reg [7:0] memory [191:0];
reg [31:0] buff;
reg [31:0] output_data;

assign O_IMEM_WDATA = output_data;

always @(posedge I_IMEM_HCLK)
    if (!I_IMEM_HRESET_N)
	buff <= 31'h0000_0000;
    else 
	buff <= {I_IMEM_PIXEL_IN_ADDR3, I_IMEM_PIXEL_IN_ADDR2, I_IMEM_PIXEL_IN_ADDR1, I_IMEM_PIXEL_IN_ADDR0};

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
                memory[buff[7:0]] <= memory[buff[7:0]];
                memory[buff[15:8]] <= memory[buff[15:8]];
                memory[buff[23:16]] <= memory[buff[23:16]];
                memory[buff[31:24]] <= memory[buff[31:24]];
            end

always @(posedge I_IMEM_HCLK)
    if (!I_IMEM_HRESET_N)
	output_data <= 31'h0000_0000;
    else 
	if (!I_IMEM_WRITE)
	output_data <= {memory[I_IMEM_PIXEL_OUT_ADDR3],memory[I_IMEM_PIXEL_OUT_ADDR2],memory[I_IMEM_PIXEL_OUT_ADDR1],memory[I_IMEM_PIXEL_OUT_ADDR0]};
	else
	    output_data <= output_data;

endmodule
