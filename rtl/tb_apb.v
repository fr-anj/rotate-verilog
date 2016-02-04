`timescale 1ns/1ps

module tb_apb;


    wire [31:0] O_PRDATA;
    wire 	O_PREADY;
    
    reg 	I_PSEL;
    reg 	I_PENABLE;
    reg 	I_PWRITE;
    reg [31:0] 	I_PADDR;
    reg [31:0] 	I_PWDATA;
    reg 	I_PRESET_N;
    reg 	I_PCLK;

    apbif APB0 (
    .O_PRDATA(O_PRDATA),
    .O_PREADY(O_PREADY), 
    .I_PSEL(I_PSEL),
    .I_PENABLE(I_PENABLE),
    .I_PWRITE(I_PWRITE),
    .I_PADDR(I_PADDR),
    .I_PWDATA(I_PWDATA),
    .I_PRESET_N(I_PRESET_N),
    .I_PCLK(I_PCLK)
    );

    initial begin
	I_PCLK = 0; 
	I_PRESET_N = 1;
	I_PSEL = 0;
	I_PENABLE = 0;
	I_PWRITE = 0;
	I_PADDR = 0;
	I_PWDATA = 0;
    end

    always 
	#1 I_PCLK = ~I_PCLK;

    initial begin
	$vcdpluson;
	$vcdplusmemon;

	@(posedge I_PCLK)
	    I_PRESET_N <= 1;

	@(posedge I_PCLK)
	    I_PRESET_N <= 0;

	@(posedge I_PCLK)
	    I_PRESET_N <= 1;

	@(posedge I_PCLK)
	    begin
		I_PADDR <= 0;
		I_PWDATA <= 0;
	    end

	@(posedge I_PCLK)
	    begin
		I_PADDR <= 4;
		I_PWDATA <= 500;
	    end

	@(posedge I_PCLK)
	    I_PSEL <= 1;

	@(posedge I_PCLK)
	    I_PENABLE <= 1;

	@(posedge I_PCLK)
	    I_PENABLE <= 0;

	@(posedge I_PCLK)
	    I_PWRITE <= 1;

	@(posedge I_PCLK)
	    begin
		I_PADDR <= 4;
		I_PWDATA <= 128;
		I_PENABLE <= 1;
	    end

	@(posedge I_PCLK)
	    I_PENABLE <= 0;

	repeat(4) @(posedge I_PCLK);
	@(posedge I_PCLK)
	    begin
		I_PADDR <= 8;
		I_PWDATA <= 24;
		I_PENABLE <= 1;
	    end

	repeat(4) @(posedge I_PCLK);
	@(posedge I_PCLK)
	    begin
		I_PADDR <= 16;
		I_PWDATA <= 5555;
		I_PENABLE <= 1;
	    end

	repeat(4) @(posedge I_PCLK);
	@(posedge I_PCLK)
	    begin
		I_PADDR <= 56;
		I_PWDATA <= 66666;
		I_PENABLE <= 0;
	    end

	repeat(8)@(posedge I_PCLK);

	@(posedge I_PCLK)
	    I_PENABLE <= 1;

	#500 $finish;
    end

endmodule
