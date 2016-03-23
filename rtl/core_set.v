`timescale 1ns/1ps

module core_set (
    output [31:0] O_CS_ADDR,
    output [31:0] O_CS_DST_IMG, //to register file
    output [15:0] O_CS_NEW_H, //to register file
    output [15:0] O_CS_NEW_W, //to register file
    output [4:0] O_CS_COUNT, //to dma
    output [2:0] O_CS_SIZE, //to dma
    output O_CS_WRITE, //to dma
    output O_CS_INTR_DONE, //to register file
    input [15:0] I_CS_HEIGHT,
    input [15:0] I_CS_WIDTH,
    input [1:0] I_CS_DEGREES,
    input I_CS_DMA_READY, //from dma - start transaction signal
    input I_CS_DIRECTION,
    //input I_CS_START,
    input I_CS_HRESET_N,
    input I_CS_RESET,
    input I_CS_HCLK

    //interrupt registers
);

wire [13:0] height_div_by_8;
wire [13:0] width_div_by_8;
wire [2:0] height_div_by_8_rem;
wire [2:0] width_div_by_8_rem;
wire [3:0] height_deficit_of_8;
wire [3:0] width_deficit_of_8;
wire height_div_by_8_is_reached;
wire width_div_by_8_is_reached;
wire is_right_angle_rotate;
wire is_last_height_and_width;

wire [17:0] height_mul_3;
wire [17:0] height_mask_3;
wire [17:0] height_mask_7;
wire [2:0] height_diff_4;
wire [3:0] height_diff_8;
wire [18:0] height_read_correct;
wire [18:0] height_write_correct;
wire [17:0] width_mul_3;
wire [17:0] width_mask_3;
wire [17:0] width_mask_7;
wire [2:0] width_diff_4;
wire [3:0] width_diff_8;
wire [18:0] width_read_correct;
wire [18:0] width_write_correct;
wire [21:0] dec_row_address_90;
wire [21:0] dec_row_address_180;
wire [21:0] inc_row_address_270;
wire [34:0] start_address_write_row_90;
wire [34:0] start_address_write_row_180;
wire [32:0] start_address_write_col_180;
wire [31:0] start_address_write_col_270;
wire [31:0] total_size;
wire [33:0] total_size_mul_3;
wire [16:0] tmp_height;
wire [16:0] tmp_width;
wire [16:0] tmp_new_height;
wire [16:0] tmp_new_width;
wire [33:0] tmp_ahb_0;
wire [33:0] tmp_ahb_90;
wire [33:0] tmp_ahb_180;
wire [33:0] tmp_ahb_270;

reg [1:0] curr_state;
reg [1:0] next_state;
reg [5:0] trans_count;
reg [2:0] trans_div_by_8_count;
reg [2:0] beat_count;
reg [13:0] height_div_by_8_count;
reg [13:0] width_div_by_8_count;

reg [32:0] read_row_address;
reg [32:0] read_col_address;
reg [32:0] write_base_90_deg_address;
reg [32:0] write_base_180_deg_address;
reg [32:0] write_base_270_deg_address;
reg [32:0] write_row_0_deg_address;
reg [32:0] write_row_90_deg_address;
reg [32:0] write_row_180_deg_address;
reg [32:0] write_row_270_deg_address;
reg [32:0] write_col_0_deg_address;
reg [32:0] write_col_90_deg_address;
reg [32:0] write_col_180_deg_address;
reg [32:0] write_col_270_deg_address;
reg zero_height;
reg zero_width;

//output registers
reg [33:0] address_to_ahb;
reg [33:0] address_dst_to_reg;
reg [16:0] new_height_to_reg;
reg [16:0] new_width_to_reg;
//reg [4:0] transfer_count_to_dma;
//reg [2:0] transfer_size_to_dma;
reg write_signal_to_dma;
reg interrupt;

parameter //states
P_IDLE = 2'h0,
P_READ = 2'h1,
P_WRITE = 2'h2;

parameter //degrees
P_0_deg = 2'h0,
P_90_deg = 2'h1,
P_180_deg = 2'h2,
P_270_deg = 2'h3;

assign height_div_by_8 = (height_div_by_8_rem == 0)? I_CS_HEIGHT[15:3] - 13'h0001 : {1'b0, I_CS_HEIGHT[15:3]};
assign width_div_by_8 = (width_div_by_8_rem == 0)? I_CS_WIDTH[15:3] - 13'h0001: {1'b0, I_CS_WIDTH[15:3]};
assign height_div_by_8_rem = I_CS_HEIGHT[2:0];
assign width_div_by_8_rem = I_CS_WIDTH[2:0];
assign height_deficit_of_8 = 8 - {1'b0, height_div_by_8_rem};
assign width_deficit_of_8 = 8 - {1'b0, width_div_by_8_rem};
assign height_div_by_8_is_reached = (height_div_by_8_count[12:0] < height_div_by_8[12:0])? 0 : 1;
assign width_div_by_8_is_reached = (width_div_by_8_count[12:0] < width_div_by_8[12:0])? 0 : 1;
assign is_right_angle_rotate = ((I_CS_DEGREES == P_90_deg) || (I_CS_DEGREES == P_270_deg))? 1 : 0;
assign is_last_height_and_width = (height_div_by_8_is_reached && width_div_by_8_is_reached)? 1 : 0;

assign height_mul_3 = (I_CS_HEIGHT << 1) + I_CS_HEIGHT;//I_CS_HEIGHT << 2; //(I_CS_HEIGHT << 1) + I_CS_HEIGHT;
assign height_mask_3 = height_mul_3 & 17'h0_0003;
assign height_mask_7 = height_mul_3 & 17'h0_0007;
assign height_diff_4 = 3'h4 - height_mask_3[2:0];
assign height_diff_8 = 4'h8 - height_mul_3;
assign height_read_correct = (height_mask_3[1:0] == 2'b00)? height_mul_3 : height_mul_3 + {15'h0000, height_diff_4};
assign height_write_correct = (height_mask_7[2:0] == 3'b000)? height_mul_3 : (tmp_new_height << 1) + tmp_new_height;
assign width_mul_3 = (I_CS_WIDTH << 1) + I_CS_WIDTH;//I_CS_WIDTH << 2; //(I_CS_WIDTH << 1) + I_CS_WIDTH;
assign width_mask_3 = width_mul_3 & 17'h0_0003;
assign width_mask_7 = width_mul_3 & 17'h0_0007;
assign width_diff_4 = 3'h4 - width_mask_3[2:0];
assign width_diff_8 = 4'h8 - width_mul_3;
assign width_read_correct = (width_mask_3[1:0] == 2'b00)? width_mul_3 : width_mul_3 + {15'h0000, width_diff_4};
assign width_write_correct = (width_mask_3[1:0] == 2'b00)? width_mul_3 : (tmp_new_width << 1) + tmp_new_width;
assign dec_row_address_90 = height_write_correct << 3;
assign dec_row_address_180 = width_write_correct << 3;
assign inc_row_address_270 = dec_row_address_90;
assign start_address_write_row_90 = total_size_mul_3 - {12'h000, dec_row_address_90};
assign start_address_write_row_180 = total_size_mul_3 - {12'h000, dec_row_address_180};
assign start_address_write_col_180 = width_div_by_8 * 13'h0018;
assign start_address_write_col_270 = height_div_by_8 * 13'h0018;
assign total_size = new_height_to_reg[15:0] * new_width_to_reg[15:0];
assign total_size_mul_3 = (total_size << 1) + {1'b0, total_size};
assign tmp_height = {1'b0, I_CS_HEIGHT};
assign tmp_width = {1'b0, I_CS_WIDTH};
assign tmp_new_width = I_CS_WIDTH + {12'h000, width_deficit_of_8};
assign tmp_new_height = I_CS_HEIGHT + {12'h000, height_deficit_of_8};
assign tmp_ahb_0 = write_row_0_deg_address + write_col_0_deg_address;
assign tmp_ahb_90 = (write_row_90_deg_address[31:0] + write_col_90_deg_address[31:0]) + {1'b0, write_base_90_deg_address[31:0]};
assign tmp_ahb_180 = (write_row_180_deg_address[31:0] + write_col_180_deg_address[31:0]) + {1'b0, write_base_180_deg_address[31:0]};
assign tmp_ahb_270 = (write_row_270_deg_address[31:0] + write_col_270_deg_address[31:0]) + {1'b0, write_base_270_deg_address[31:0]};

assign O_CS_ADDR = address_to_ahb[31:0];
assign O_CS_DST_IMG = address_dst_to_reg[31:0];  
assign O_CS_NEW_H = new_height_to_reg[15:0];
assign O_CS_NEW_W = new_width_to_reg[15:0];
assign O_CS_COUNT = 5'h06;
assign O_CS_SIZE = 3'h2;
assign O_CS_WRITE = write_signal_to_dma;
assign O_CS_INTR_DONE = interrupt;

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	curr_state <= P_IDLE;
    else 
	curr_state <= next_state;

always @(*)
    case (curr_state)
	P_IDLE:
	    if (I_CS_DMA_READY && !interrupt)
		next_state = P_READ;
	    else 
		next_state = P_IDLE;
	P_READ:
	    if (interrupt || I_CS_RESET)
		next_state = P_IDLE;
	    else
		if (trans_count == 6'h3f)
		    next_state = P_WRITE;
		else 
		    next_state = P_READ;
	P_WRITE:
	    if (I_CS_RESET)
		next_state = P_IDLE;
	    else
		if (trans_count == 6'h3f)
		    next_state = P_READ;
		else 
		    next_state = P_WRITE;
	default:
	    next_state = P_IDLE;
    endcase

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	trans_count <= 6'h00;
    else 
	case (next_state)
	    P_IDLE:
		trans_count <= 6'h00;
	    default:
		if (interrupt)
		    trans_count <= 6'h00;
		else
		 //    if (!I_CS_DMA_READY)
			// trans_count <= trans_count;
		 //    else 
			trans_count <= trans_count + 1;
	endcase

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	trans_div_by_8_count <= 3'h0;
    else 
	case (next_state)
	    P_IDLE:
		trans_div_by_8_count <= 3'h0;
	    default:
		// if (interrupt)
		//     trans_div_by_8_count <= 3'h0;
		// else 
		    if ((beat_count == 3'h7) && I_CS_DMA_READY)
			trans_div_by_8_count <= trans_div_by_8_count + 1;
		    else 
			trans_div_by_8_count <= trans_div_by_8_count;
	endcase

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	beat_count <= 3'h0;
    else 
	case (next_state)
	    P_IDLE:
		beat_count <= 3'h0;
	    default:
		//if (interrupt)
		//     beat_count <= 3'h0;
		// else
		//     if (!I_CS_DMA_READY)
		// 	beat_count <= beat_count;
		//     else 
			beat_count <= beat_count + 1;
	endcase

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	height_div_by_8_count <= 14'h0000;
    else 
	case (next_state)
	    P_IDLE:
		height_div_by_8_count <= 14'h0000;
	    P_READ:
		if (!height_div_by_8_is_reached)
		    if (trans_count == 6'h3f)
			height_div_by_8_count <= height_div_by_8_count[12:0] + 1;
		    else 
			height_div_by_8_count <= height_div_by_8_count;
		else 
		    if (trans_count == 6'h3f)
			height_div_by_8_count <= 14'h0000;
		    else 
			height_div_by_8_count <= height_div_by_8_count;
	    P_WRITE:
		height_div_by_8_count <= height_div_by_8_count;
	    default:
		height_div_by_8_count <= 14'h0000;
	endcase

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	width_div_by_8_count <= 14'h0000;
    else 
	case (next_state)
	    P_IDLE:
		width_div_by_8_count <= 14'h0000;
	    P_READ:
		if (!width_div_by_8_is_reached)
		    if ((trans_count == 6'h3f) && height_div_by_8_is_reached)
			width_div_by_8_count <= width_div_by_8_count[12:0] + 1;
		    else 
			width_div_by_8_count <= width_div_by_8_count;
		else 
		    if ((trans_count == 6'h3f) && height_div_by_8_is_reached)
			width_div_by_8_count <= 14'h0000;
		    else 
			width_div_by_8_count <= width_div_by_8_count;
	    P_WRITE:
		width_div_by_8_count <= width_div_by_8_count;
	    default:
		width_div_by_8_count <= 14'h0000;
	endcase

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	read_row_address <= 33'h0_0000_0000;
    else 
	case (next_state)
	    P_IDLE:
		read_row_address <= 33'h0_0000_0000;
	    P_READ:
		if (height_div_by_8_is_reached && (trans_count == 6'h3f))
		    read_row_address <= 33'h0_0000_0000;
		else 
		    if (beat_count == 3'h7)
			read_row_address <= read_row_address[31:0] + {13'h0000, width_read_correct};
		    else 
			read_row_address <= read_row_address;
	    P_WRITE:
		read_row_address <= read_row_address;
	    default:
		read_row_address <= 33'h0_0000_0000;
	endcase

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	read_col_address <= 33'h0_0000_0000;
    else 
	case (next_state)
	    P_IDLE:
		read_col_address <= 33'h0_0000_0000;
	    P_READ:
		    if (height_div_by_8_is_reached && (trans_count == 6'h3f))
			read_col_address <= read_col_address[31:0] + 32'h0000_0018;
		    else 
			read_col_address <= read_col_address;
	    default: 
		read_col_address <= read_col_address;
	endcase

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	write_row_0_deg_address <= 33'h0_0000_0000;
    else 
	case (next_state)
	    P_IDLE:
		write_row_0_deg_address <= 33'h0_0000_0000;
	    P_READ:
		write_row_0_deg_address <= write_row_0_deg_address;
	    P_WRITE:
		if (zero_height)
		    write_row_0_deg_address <= 33'h0_0000_0000;
		else 
		    if (beat_count == 3'h7)
			write_row_0_deg_address <= write_row_0_deg_address[31:0] + {13'h0000, width_write_correct};
		    else 
			write_row_0_deg_address <= write_row_0_deg_address;
	    default:
		write_row_0_deg_address <= 33'h0_0000_0000;
	endcase

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	write_col_0_deg_address <= 33'h0_0000_0000;
    else 
	case (next_state)
	    P_IDLE:
		write_col_0_deg_address <= 33'h0_0000_0000;
	    P_READ:
		write_col_0_deg_address <= write_col_0_deg_address;
	    P_WRITE:
		if (zero_height )//&& (trans_count == 6'h3f))
		    //if (read_col_address == 33'h0_0000_0000)
		    if (zero_width) 
			write_col_0_deg_address <= 33'h0_0000_0000;
		    else 
			write_col_0_deg_address <= write_col_0_deg_address[31:0] + 32'h0000_0018;
		else 
		    write_col_0_deg_address <= write_col_0_deg_address;
	    default:
		write_col_0_deg_address <= 33'h0_0000_0000;
	endcase
	
//////////////////////////>
always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	write_base_90_deg_address <= 33'h0_0000_0000;
    else 
	case (next_state)
	    P_IDLE:
		write_base_90_deg_address <= 33'h0_0000_0000;
	    P_READ:
		write_base_90_deg_address <= write_base_90_deg_address;
	    P_WRITE:
		if (zero_height )//&& (trans_count == 6'h3f))
		    if (zero_width)
			write_base_90_deg_address <= start_address_write_row_90[32:0];
		    else 
			write_base_90_deg_address <= write_base_90_deg_address[31:0] - {10'h000, dec_row_address_90};
		else 
		    write_base_90_deg_address <= write_base_90_deg_address;
	    default:
		write_base_90_deg_address <= 33'h0_0000_0000;
	endcase

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	write_row_90_deg_address <= 33'h0_0000_0000;
    else 
	case (next_state)
	    P_IDLE:
		write_row_90_deg_address <= 33'h0_0000_0000;
	    P_READ:
		write_row_90_deg_address <= write_row_90_deg_address;
	    P_WRITE:
		if (trans_count == 6'h3f)
		    write_row_90_deg_address <= 33'h0_0000_0000;
		else 
		    if (beat_count == 3'h7)
			write_row_90_deg_address <= write_row_90_deg_address[31:0] + {13'h0000, height_write_correct};
		    else 
			write_row_90_deg_address <= write_row_90_deg_address;
	    default:
		write_row_90_deg_address <= 33'h0_0000_0000;
	endcase

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	write_col_90_deg_address <= 33'h0_0000_0000;
    else 
	case (next_state)
	    P_IDLE:
		write_col_90_deg_address <= 33'h0_0000_0000;
	    P_READ:
		write_col_90_deg_address <= write_col_90_deg_address;
	    P_WRITE:
		if (zero_height)
		    if (trans_count == 6'h3f)
			write_col_90_deg_address <= 33'h0_0000_0000;
		    else 
			write_col_90_deg_address <= write_col_90_deg_address;
		else
		    if (trans_count == 6'h3f)
			write_col_90_deg_address <= write_col_90_deg_address[31:0] + 32'h0000_0018;
		    else 
			write_col_90_deg_address <= write_col_90_deg_address;
	    default:
		write_col_90_deg_address <= 33'h0_0000_0000;
	endcase

//////////////////////////>
always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	write_base_180_deg_address <= 33'h0_0000_0000;
    else 
	case (next_state)
	    P_IDLE:
		write_base_180_deg_address <= 33'h0_0000_0000;
	    P_READ:
		write_base_180_deg_address <= write_base_180_deg_address;
	    P_WRITE:
		if (zero_height)
		    if (trans_count == 6'h3f)
			write_base_180_deg_address <= start_address_write_row_180[32:0];
		    else 
			write_base_180_deg_address <= write_base_180_deg_address;
		else 
		    if (trans_count == 6'h3f)
			write_base_180_deg_address <= write_base_180_deg_address[31:0] - {10'h000, dec_row_address_180};
		    else 
			write_base_180_deg_address <= write_base_180_deg_address;
	    default:
		write_base_180_deg_address <= 33'h0_0000_0000;
	endcase

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	write_row_180_deg_address <= 33'h0_0000_0000;
    else 
	case (next_state)
	    P_IDLE:
		write_row_180_deg_address <= 33'h0_0000_0000;
	    P_READ:
		write_row_180_deg_address <= write_row_180_deg_address;
	    P_WRITE:
		if (trans_count == 6'h3f)
		    write_row_180_deg_address <= 33'h0_0000_0000;
		else 
		    if (beat_count == 3'h7)
			write_row_180_deg_address <= write_row_180_deg_address[31:0] + {13'h0000, width_write_correct};
		    else 
			write_row_180_deg_address <= write_row_180_deg_address;
	    default:
		write_row_180_deg_address <= 33'h0_0000_0000;
	endcase

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	write_col_180_deg_address <= 33'h0_0000_0000;
    else 
	case (next_state)
	    P_IDLE:
		write_col_180_deg_address <= 33'h0_0000_0000;
	    P_READ:
		write_col_180_deg_address <= write_col_180_deg_address;
	    P_WRITE:
		if (zero_height && (trans_count == 6'h3f))
		    if (zero_width)
			write_col_180_deg_address <= start_address_write_col_180;
		    else
			write_col_180_deg_address <= write_col_180_deg_address[31:0] - 32'h0000_0018;
		else
		    write_col_180_deg_address <= write_col_180_deg_address;
	    default:
		write_col_180_deg_address <= 33'h0_0000_0000;
	endcase

//////////////////////////>
always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	write_base_270_deg_address <= 33'h0_0000_0000;
    else 
	case (next_state)
	    P_IDLE:
		write_base_270_deg_address <= 33'h0_0000_0000;
	    P_READ:
		write_base_270_deg_address <= write_base_270_deg_address;
	    P_WRITE:
		if (zero_height)// && (trans_count == 6'h3f))
		    if (zero_width)
			write_base_270_deg_address <= 33'h0_0000_0000;
		    else 
			write_base_270_deg_address <= write_base_270_deg_address[31:0] + {10'h000, inc_row_address_270}; 
		else 
		    write_base_270_deg_address <= write_base_270_deg_address;
	    default:
		write_base_270_deg_address <= write_base_270_deg_address;
	endcase

always @(*)
    write_row_270_deg_address = write_row_90_deg_address;

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	write_col_270_deg_address <= 33'h0_0000_0000;
    else 
	case (next_state)
	    P_IDLE:
		write_col_270_deg_address <= 33'h0_0000_0000;
	    P_READ:
		write_col_270_deg_address <= write_col_270_deg_address;
	    P_WRITE:
		if (zero_height)
		 //    if (trans_count == 6'h3f)
			// write_col_270_deg_address <= start_address_write_col_270;
		 //    else 
			write_col_270_deg_address <= write_col_270_deg_address;
		else 
		    if (trans_count == 6'h3f)
			write_col_270_deg_address <= write_col_270_deg_address[31:0] - 32'h0000_0018;
		    else 
			write_col_270_deg_address <= write_col_270_deg_address;
	    default:
		write_col_270_deg_address <= write_col_270_deg_address;
	endcase

always @(*)
    case (curr_state)
	P_IDLE:
	    address_to_ahb = 34'h0_0000_0000;
	P_READ:
	    address_to_ahb = read_row_address + read_col_address;
	P_WRITE:
	    if (I_CS_DIRECTION)
		case (I_CS_DEGREES)
		    P_0_deg:
			address_to_ahb = tmp_ahb_0;
		    P_90_deg:
			address_to_ahb = tmp_ahb_90;
		    P_180_deg:
			address_to_ahb = tmp_ahb_180;
		    P_270_deg:
			address_to_ahb = tmp_ahb_270;
		    default:
			address_to_ahb = tmp_ahb_0;
		endcase
	    else 
		case (I_CS_DEGREES)
		    P_0_deg:
			address_to_ahb = tmp_ahb_0;
		    P_90_deg:
			address_to_ahb = tmp_ahb_270;
		    P_180_deg:
			address_to_ahb = tmp_ahb_180;
		    P_270_deg:
			address_to_ahb = tmp_ahb_90;
		    default:
			address_to_ahb = tmp_ahb_0;
		endcase
	default:
	    address_to_ahb = 34'h0_0000_0000;
    endcase

//////////////////////////////////////////////////////////////////////////////////////////////////////>
//OUTPUT_REG//////////////////////////////////////////////////////////////////////////////////////////>
always @(*)
    if ((new_height_to_reg[15:0] == 16'h0000) || (new_width_to_reg[15:0] == 16'h0000))
	address_dst_to_reg = 34'h0_0000_0000;
    else 
	address_dst_to_reg = total_size_mul_3;

always @(*)
    if (height_div_by_8_rem == 3'h0)
	if (is_right_angle_rotate)
	    new_height_to_reg = tmp_width;
	else 
	    new_height_to_reg = tmp_height;
    else 
	if (is_right_angle_rotate)
	    new_height_to_reg = tmp_new_width;
	else 
	    new_height_to_reg = tmp_new_height;

always @(*)
    if (width_div_by_8_rem == 3'h0)
	if (!is_right_angle_rotate)
	    new_width_to_reg = tmp_width;
	else 
	    new_width_to_reg = tmp_height;
    else 
	if (!is_right_angle_rotate)
	    new_width_to_reg = tmp_new_width;
	else 
	    new_width_to_reg = tmp_new_height;

always @(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	write_signal_to_dma <= 0;
    else 
	case (next_state)
	    P_WRITE:
		write_signal_to_dma <= 1;
	    default:
		write_signal_to_dma <= 0;
	endcase

always@(posedge I_CS_HCLK)
    if (!I_CS_HRESET_N)
	interrupt <= 0;
    else 
	case (next_state)
	    P_READ:
		if (is_last_height_and_width && (trans_count == 6'h3f))
		    interrupt <= 1;
		else
		    interrupt <= interrupt;
	    default:
		interrupt <= interrupt;
	endcase
//////////////////////////////////////////////////////////////////////////////////////////////////////>
//////////////////////////////////////////////////////////////////////////////////////////////////////>

always @(*)
    case (curr_state)
	P_IDLE:
	    zero_height = 0;
	P_READ:
	    if (height_div_by_8_count == 14'h0000)
		zero_height = 1;
	    else 
		zero_height = 0;
	P_WRITE:
	    zero_height = 0;
	default: 
	    zero_height = 0;
    endcase

always @(*)
    case (curr_state)
	P_IDLE:
	    zero_width = 0;
	P_READ:
	    if (width_div_by_8_count == 14'h0000)
		zero_width = 1;
	    else 
		zero_width = 0;
	P_WRITE:
	    zero_width = 0;
	default: 
	    zero_width = 0;
    endcase

endmodule
