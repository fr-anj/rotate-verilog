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
    output 		O_CTRL_BEF_MASK,	
    output 		O_CTRL_AFT_MASK,	
    output 		O_CTRL_INTR_CLEAR,
    output 		O_CTRL_BUSY,		

    input 	[15:0]	I_ROT_IMG_NEW_H,
    input 	[15:0]	I_ROT_IMG_NEW_W,
    input 		I_CTRL_BEF_MASK,
    input 		I_CTRL_AFT_MASK,
    input 		I_CTRL_BUSY,

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

parameter ROT_IMG_NEW_H		= 6'h10,
          ROT_IMG_NEW_W		= 6'h14,
          CTRL_RESET		= 6'h24,
          CTRL_BEF_MASK		= 6'h2c,	
          CTRL_AFT_MASK		= 6'h30,	
          CTRL_INTR_CLEAR	= 6'h34,
          CTRL_BUSY		= 6'h38;		

assign address1 = {I_PADDR[5:2],2'h0};
assign address2 = address1 + 6'h01;
assign address3 = address1 + 6'h02;
assign address4 = address1 + 6'h03;

/***********************
*wire read_only;
*wire read_only_1;
*wire read_only_2;
*wire write_only; 
*
*assign read_only_1 	= (address1 == ROT_IMG_NEW_H) || (address1 == ROT_IMG_NEW_W); 
*assign read_only_2 	= (address1 == CTRL_BEF_MASK) || (address1 == CTRL_AFT_MASK);
*assign read_only 	= read_only_1 || read_only_2 || (address1 == CTRL_BUSY);
*assign write_only 	= (address1 == CTRL_RESET) || (address1 == CTRL_INTR_CLEAR);
***********************/

//request master to extend read state
always @(posedge I_PCLK)
    if (!I_PRESET_N)
	O_PREADY <= 0;
    else 
	if (I_PENABLE)
	    O_PREADY <= 1;
	else 
	    O_PREADY <= 0;

// write to REGISTER_FILE
always @(posedge I_PCLK)
    if (!I_PRESET_N)
	for (i = 0; i < 60; i = i + 1)
	    REGISTER_FILE[i] <= 8'h00;
    else 
	if (I_PSEL && I_PENABLE && I_PWRITE)
	    case (address1)
		//########################################################
		//######################READ-ONLY#########################
		ROT_IMG_NEW_H:
		    begin
			REGISTER_FILE[address1] <= I_ROT_IMG_NEW_H[7:0];
			REGISTER_FILE[address2] <= I_ROT_IMG_NEW_H[15:8];
		    end
		ROT_IMG_NEW_W:
		    begin
			REGISTER_FILE[address1] <= I_ROT_IMG_NEW_W[7:0];
			REGISTER_FILE[address2] <= I_ROT_IMG_NEW_W[15:8];
		    end
		CTRL_BEF_MASK:
		    REGISTER_FILE[address1][0] <= I_CTRL_BEF_MASK;
		CTRL_AFT_MASK:
		    REGISTER_FILE[address1][0] <= I_CTRL_AFT_MASK;
		CTRL_BUSY:
		    REGISTER_FILE[address1][0] <= I_CTRL_BUSY;
		//########################################################
		//########################################################
		default:
		    begin
			REGISTER_FILE[address1]	<= I_PWDATA[7:0];
			REGISTER_FILE[address2]	<= I_PWDATA[15:8];
			REGISTER_FILE[address3]	<= I_PWDATA[23:16];
			REGISTER_FILE[address4]	<= I_PWDATA[31:24];
		    end
	    endcase
	else
	   for (j = 0; j < 60; j = j + 1)
	       REGISTER_FILE[j] <= REGISTER_FILE[j];
    
// to CPU
always @(posedge I_PCLK)
    if (!I_PRESET_N)
	O_PRDATA <= 32'h00000000;
    else 
	if (I_PSEL && I_PENABLE && !I_PWRITE)
	    case (address1)
		CTRL_RESET:
		    O_PRDATA <= O_PRDATA;
		CTRL_INTR_CLEAR:
		    O_PRDATA <= O_PRDATA;
		default:
		    begin
			O_PRDATA[7:0] 	<= REGISTER_FILE[address1];
			O_PRDATA[15:8] 	<= REGISTER_FILE[address2];
			O_PRDATA[23:16]	<= REGISTER_FILE[address3];
			O_PRDATA[31:24]	<= REGISTER_FILE[address4];
		    end
	    endcase
	else 
	    O_PRDATA <= O_PRDATA;

//to core
assign O_DMA_SRC_IMG 	= {REGISTER_FILE[6'h03],REGISTER_FILE[6'h02],REGISTER_FILE[6'h01],REGISTER_FILE[6'h00]};
assign O_DMA_DST_IMG 	= {REGISTER_FILE[6'h07],REGISTER_FILE[6'h06],REGISTER_FILE[6'h05],REGISTER_FILE[6'h04]};
assign O_ROT_IMG_H 	= {REGISTER_FILE[6'h09],REGISTER_FILE[6'h08]};
assign O_ROT_IMG_W 	= {REGISTER_FILE[6'h0d],REGISTER_FILE[6'h0c]};
assign O_ROT_IMG_NEW_H 	= {REGISTER_FILE[6'h11],REGISTER_FILE[6'h10]};
assign O_ROT_IMG_NEW_W 	= {REGISTER_FILE[6'h15],REGISTER_FILE[6'h14]};
assign O_ROT_IMG_MODE 	= REGISTER_FILE[6'h18][1:0]; 
assign O_ROT_IMG_DIR 	= REGISTER_FILE[6'h1c][0];
assign O_CTRL_START 	= REGISTER_FILE[6'h20][0];
assign O_CTRL_RESET 	= REGISTER_FILE[6'h24][0];
assign O_CTRL_INTR_MASK = REGISTER_FILE[6'h28][0];
assign O_CTRL_BEF_MASK 	= REGISTER_FILE[6'h2c][0];
assign O_CTRL_AFT_MASK 	= REGISTER_FILE[6'h30][0];
assign O_CTRL_INTR_CLEAR= REGISTER_FILE[6'h34][0];
assign O_CTRL_BUSY 	= REGISTER_FILE[6'h38][0];

endmodule
