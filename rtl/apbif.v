`timescale 1ns/1ps

module apbif (
    output reg O_APBIF_PREADY,
    output [31:0] O_APBIF_DMA_SRC_IMG,
    //output reg [31:0] O_APBIF_DMA_DST_IMG,
    output [15:0] O_APBIF_ROT_IMG_H,
    output [15:0] O_APBIF_ROT_IMG_W,
    output [1:0] O_APBIF_ROT_IMG_MODE,
    output O_APBIF_ROT_IMG_DIR,
    output O_APBIF_CTRL_START,
    output O_APBIF_CTRL_RESET,
    output [31:0] O_APBIF_PRDATA,
    //output reg INTERRUPT

    input [31:0] I_APBIF_PADDR,
    input [31:0] I_APBIF_PWDATA,
    input [31:0] I_APBIF_DMA_DST_IMG,
    input [15:0] I_APBIF_ROT_IMG_NEW_H,
    input [15:0] I_APBIF_ROT_IMG_NEW_W,
    input I_APBIF_PSEL,
    input I_APBIF_PENABLE,
    input I_APBIF_PWRITE,
    input I_APBIF_PRESET_N,
    input I_APBIF_PCLK
);

//reg [7:0] REGISTER_FILE [59:0];
reg [31:0] read_data;
reg [31:0] reg_dma_src_img;
reg [31:0] reg_dma_dst_img;
reg [31:0] reg_rot_img_h;
reg [31:0] reg_rot_img_w;
reg [31:0] reg_rot_img_new_h;
reg [31:0] reg_rot_img_new_w;
reg [31:0] reg_rot_img_mode;
reg [31:0] reg_rot_img_dir;
reg [31:0] reg_ctrl_start;
reg [31:0] reg_ctrl_reset;
reg [31:0] reg_ctrl_intr_mask;
reg [31:0] reg_ctrl_bef_mask;
reg [31:0] reg_ctrl_aft_mask;
reg [31:0] reg_intr_clear;

parameter 
P_DMA_SRC_IMG = 32'h0000_0000,
P_DMA_DST_IMG = 32'h0000_0004,
P_ROT_IMG_H = 32'h0000_0008,
P_ROT_IMG_W = 32'h0000_000c,
P_ROT_IMG_NEW_H = 32'h0000_0010,
P_ROT_IMG_NEW_W = 32'h0000_0014,
P_ROT_IMG_MODE = 32'h0000_0018, 
P_ROT_IMG_DIR = 32'h0000_001c,
P_CTRL_START = 32'h0000_0020,
P_CTRL_RESET = 32'h0000_0024,
P_CTRL_INTR_MASK = 32'h0000_0028,
P_CTRL_BEF_MASK = 32'h0000_002c,
P_CTRL_AFT_MASK = 32'h0000_0030,
P_INTR_CLEAR = 32'h0000_0032;

assign O_APBIF_PRDATA = read_data;
assign O_APBIF_DMA_SRC_IMG = reg_dma_src_img;
//assign O_APBIF_DMA_DST_IMG = reg_dma_dst_img;
assign O_APBIF_ROT_IMG_H = reg_rot_img_h[15:0];
assign O_APBIF_ROT_IMG_W = reg_rot_img_w[15:0];
assign O_APBIF_ROT_IMG_MODE = reg_rot_img_mode[1:0];
assign O_APBIF_ROT_IMG_DIR = reg_rot_img_dir[0];
assign O_APBIF_CTRL_START = reg_ctrl_start[0];
assign O_APBIF_CTRL_RESET = reg_ctrl_reset[0];

always @(*)
    if (I_APBIF_PENABLE)
        O_APBIF_PREADY = 1;
    else 
        O_APBIF_PREADY = 0;

always @(posedge I_APBIF_PCLK)
    if (!I_APBIF_PRESET_N) begin
	reg_dma_src_img <= 31'H0000_0000;
	reg_dma_dst_img <= 31'H0000_0000;
	reg_rot_img_h <= 31'H0000_0000;
	reg_rot_img_w <= 31'H0000_0000;
	reg_rot_img_new_h <= 31'H0000_0000;
	reg_rot_img_new_w <= 31'H0000_0000;
	reg_rot_img_mode <= 31'H0000_0000;
	reg_rot_img_dir <= 31'H0000_0000;
	reg_ctrl_start <= 31'H0000_0000;
	reg_ctrl_reset <= 31'H0000_0000;
	reg_ctrl_intr_mask <= 31'H0000_0000;
	reg_ctrl_bef_mask <= 31'H0000_0000;
	reg_ctrl_aft_mask <= 31'H0000_0000;
	reg_intr_clear <= 31'H0000_0001;
	read_data <= 31'h0000_0000;
    end
    else
	if (I_APBIF_PSEL && I_APBIF_PENABLE)
	    if (I_APBIF_PWRITE) begin
		read_data <= read_data;
		reg_dma_dst_img <= I_APBIF_DMA_DST_IMG;
		reg_rot_img_new_h <= I_APBIF_ROT_IMG_NEW_H;
		reg_rot_img_new_w <= I_APBIF_ROT_IMG_NEW_W;
		//reg_ctrl_bef_mask <= ;
		//reg_ctrl_aft_mask <= ;
		case (I_APBIF_PADDR)
		    P_DMA_SRC_IMG:
			reg_dma_src_img <= I_APBIF_PWDATA;
		    //P_DMA_DST_IMG:
		    //    REG_DMA_DST_IMG <= I_APBIF_PWDATA;
		    P_ROT_IMG_H:
			reg_rot_img_h <= I_APBIF_PWDATA;
		    P_ROT_IMG_W:
			reg_rot_img_w <= I_APBIF_PWDATA;
		    //P_ROT_IMG_NEW_H:
		    //    REG_ROT_IMG_NEW_H <= I_APBIF_PWDATA;
		    //P_ROT_IMG_NEW_W:
		    //    REG_ROT_IMG_NEW_W <= I_APBIF_PWDATA;
		    P_ROT_IMG_MODE:
			reg_rot_img_mode <= I_APBIF_PWDATA;
		    P_ROT_IMG_DIR:
			reg_rot_img_dir <= I_APBIF_PWDATA;
		    P_CTRL_START:
			reg_ctrl_start <= I_APBIF_PWDATA;
		    P_CTRL_RESET:
			reg_ctrl_reset <= I_APBIF_PWDATA;
		    P_CTRL_INTR_MASK:
			reg_ctrl_intr_mask <= I_APBIF_PWDATA;
		    //P_CTRL_BEF_MASK:
		    //    REG_CTRL_BEF_MASK <= I_APBIF_PWDATA;
		    //P_CTRL_AFT_MASK:
		    //    REG_CTRL_AFT_MASK <= I_APBIF_PWDATA;
		    P_INTR_CLEAR:
			reg_intr_clear <= I_APBIF_PWDATA;
		    default:
			begin
			    reg_dma_src_img <= reg_dma_src_img;
			    reg_dma_dst_img <= reg_dma_dst_img;
			    reg_rot_img_h <= reg_rot_img_h;
			    reg_rot_img_w <= reg_rot_img_w;
			    reg_rot_img_new_h <= reg_rot_img_new_h;
			    reg_rot_img_new_w <= reg_rot_img_new_w;
			    reg_rot_img_mode <= reg_rot_img_mode;
			    reg_rot_img_dir <= reg_rot_img_dir;
			    reg_ctrl_start <= reg_ctrl_start;
			    reg_ctrl_reset <= reg_ctrl_reset;
			    reg_ctrl_intr_mask <= reg_ctrl_intr_mask;
			    reg_ctrl_bef_mask <= reg_ctrl_bef_mask;
			    reg_ctrl_aft_mask <= reg_ctrl_aft_mask;
			    reg_intr_clear <= reg_intr_clear;
			end
		endcase
	    end
	    else 
		case (I_APBIF_PADDR)
		    P_DMA_SRC_IMG:
			read_data <= reg_dma_src_img;
		    P_DMA_DST_IMG:
			read_data <= reg_dma_dst_img;
		    P_ROT_IMG_H:
			read_data <= reg_rot_img_h;
		    P_ROT_IMG_W:
			read_data <= reg_rot_img_w;
		    P_ROT_IMG_NEW_H:
			read_data <= reg_rot_img_new_h;
		    P_ROT_IMG_NEW_W:
			read_data <= reg_rot_img_new_w;
		    P_ROT_IMG_MODE:
			read_data <= reg_rot_img_mode;
		    P_ROT_IMG_DIR:
			read_data <= reg_rot_img_dir;
		    P_CTRL_START:
			read_data <= reg_ctrl_start;
		    P_CTRL_RESET:
			read_data <= reg_ctrl_reset;
		    P_CTRL_INTR_MASK:
			read_data <= reg_ctrl_intr_mask;
		    P_CTRL_BEF_MASK:
			read_data <= reg_ctrl_bef_mask;
		    P_CTRL_AFT_MASK:
			read_data <= reg_ctrl_aft_mask;
		    P_INTR_CLEAR:
		        read_data <= read_data;
		    default:
			read_data <= read_data;
		endcase
	else begin 
	    read_data <= read_data;
	    reg_dma_src_img <= reg_dma_src_img;
	    reg_dma_dst_img <= reg_dma_dst_img;
	    reg_rot_img_h <= reg_rot_img_h;
	    reg_rot_img_w <= reg_rot_img_w;
	    reg_rot_img_new_h <= reg_rot_img_new_h;
	    reg_rot_img_new_w <= reg_rot_img_new_w;
	    reg_rot_img_mode <= reg_rot_img_mode;
	    reg_rot_img_dir <= reg_rot_img_dir;
	    reg_ctrl_start <= 31'H0000_0000;
	    reg_ctrl_reset <= reg_ctrl_reset;
	    reg_ctrl_intr_mask <= reg_ctrl_intr_mask;
	    reg_ctrl_bef_mask <= reg_ctrl_bef_mask;
	    reg_ctrl_aft_mask <= reg_ctrl_aft_mask;
	    reg_intr_clear <= reg_intr_clear;
	end

endmodule
