`define no_delay 1

`define assert_hready 1
`define assert_hreset 1
`define assert_hgrant 1
`define deassert_hready 0
`define deassert_hreset 0
`define deassert_hgrant 0

`define assert_psel 1
`define assert_penable 1
`define deassert_psel 0
`define deassert_penable 0

`define min_input_image_height 1
`define min_input_image_width 1
`define mid_input_image_height 16383
`define mid_input_image_width 8191
`define max_input_image_height 32767
`define max_input_image_width 16383

`define min_output_image_height 8
`define min_output_image_width 8

`define rotate_0_degrees 0
`define rotate_90_degrees 1
`define rotate_180_degrees 2
`define rotate_270_degrees 3

`define rotate_direction_cw 0
`define rotate_direction_ccw 1

`define bmp_header_size 54

`define dma_src_img 0
`define dma_dst_img 4
`define rot_img_h 8
`define rot_img_w 12
`define rot_img_new_h 16
`define rot_img_new_w 20
`define rot_img_mode 24
`define rot_img_dir 28
`define ctrl_start 32
`define ctrl_reset 36
`define ctrl_intr_mask 40
`define ctrl_bef_mask 44
`define ctrl_aft_mask 48
`define ctrl_intr_clear 52

module tb_rotation ();
    wire [31:0] O_REG_PRDATA;
    wire [31:0] O_DMA_HADDR;
    wire [31:0] O_DMA_HWDATA;
    wire [1:0] O_DMA_HTRANS;
    wire [2:0] O_DMA_HSIZE;
    wire [2:0] O_DMA_HBURST;
    wire O_DMA_HBUSREQ;
    wire O_DMA_HWRITE;
    wire O_INTR_DONE;

    reg [31:0] I_REG_PADDR;
    reg [31:0] I_REG_PWDATA;
    reg [31:0] I_DMA_HRDATA;
    reg I_REG_PSEL;
    reg I_REG_PENABLE;
    reg I_REG_PWRITE;
    reg I_DMA_HGRANT;
    reg I_DMA_HREADY;
    reg I_PRESET_N;
    reg I_HRESET_N;
    reg I_PCLK;
    reg I_HCLK;

    rotation ROT0 (
    .O_REG_PRDATA(O_REG_PRDATA),
    .O_DMA_HADDR(O_DMA_HADDR),
    .O_DMA_HWDATA(O_DMA_HWDATA),
    .O_DMA_HTRANS(O_DMA_HTRANS),
    .O_DMA_HSIZE(O_DMA_HSIZE),
    .O_DMA_HBURST(O_DMA_HBURST),
    .O_DMA_HBUSREQ(O_DMA_HBUSREQ),
    .O_DMA_HWRITE(O_DMA_HWRITE),
    .O_INTR_DONE(O_INTR_DONE),
    .I_REG_PADDR(I_REG_PADDR),
    .I_REG_PWDATA(I_REG_PWDATA),
    .I_DMA_HRDATA(I_DMA_HRDATA),
    .I_REG_PSEL(I_REG_PSEL),
    .I_REG_PENABLE(I_REG_PENABLE),
    .I_REG_PWRITE(I_REG_PWRITE),
    .I_DMA_HGRANT(I_DMA_HGRANT),
    .I_DMA_HREADY(I_DMA_HREADY),
    .I_PRESET_N(I_PRESET_N),
    .I_HRESET_N(I_HRESET_N),
    .I_PCLK(I_PCLK),
    .I_HCLK(I_HCLK)
    );

integer image;
integer new_image;
integer count;

    integer check, index;
    reg [31:0] data_read;
    reg [15:0] height;
    reg [15:0] width;
    reg [15:0] new_height;
    reg [15:0] new_width;
    reg [31:0] offset;

parameter   p_source = 8'h00, p_destination = 8'h04,
            p_height = 8'h08, p_width = 8'h0c,
            p_new_height = 8'h10, p_new_width = 8'h14,
            p_mode = 8'h18, p_direction = 8'h1c,
            p_start = 8'h20, p_reset = 8'h24,
            p_intr_mask = 8'h28, p_bef_mask = 8'h2c,
            p_aft_mask = 8'h30, p_intr_clear = 52;

always 
    #1 I_HCLK = ~I_HCLK;
always @(posedge I_HCLK)
    I_PCLK = ~I_PCLK;

task initialize;
    I_REG_PADDR <= 0;
    I_REG_PWDATA <= 0;
    I_DMA_HRDATA <= 0;
    I_REG_PSEL <= 0;
    I_REG_PENABLE <= 0;
    I_REG_PWRITE <= 0;
    I_DMA_HGRANT <= 0;
    I_DMA_HREADY <= 0;
    I_PRESET_N <= 1;
    I_HRESET_N <= 1;
    I_PCLK <= 0;
    I_HCLK <= 0;
endtask

task hard_reset ();
    //this should start at the same time.. 
    fork //deassert
        @(posedge I_HCLK) I_HRESET_N <= 0;
        @(posedge I_PCLK) I_PRESET_N <= 0;
    join 

    fork //reassert
        @(posedge I_HCLK) I_HRESET_N <= 1;
        @(posedge I_PCLK) I_PRESET_N <= 1;
    join
endtask

task write_apb (input bit [31:0] address, input bit [31:0] value);
    @(posedge I_PCLK)
        I_REG_PSEL <= 1;
        I_REG_PENABLE <= 0;
        I_REG_PWRITE <= 1;
        I_REG_PADDR <= address;
        I_REG_PWDATA <= value;

    @(posedge I_PCLK)
        I_REG_PENABLE <= 1;
endtask

task soft_reset (input bit address);
    write_apb (p_reset, 1);
endtask

task read_apb (input bit [31:0] address);
    @(posedge I_PCLK)
        I_REG_PSEL <= 1;
        I_REG_PENABLE <= 0;
        I_REG_PWRITE <= 0;
        I_REG_PADDR <= address;

    @(posedge I_PCLK)
        I_REG_PENABLE <= 1;
    @(posedge I_PCLK) 
	I_REG_PENABLE <= 0; 
endtask

task send_to_ahb (input bit [31:0] data);
    @(posedge I_HCLK)
        I_DMA_HREADY <= 1;
        I_DMA_HRDATA <= data;
endtask

task grant_ahb (input bit value, integer delay);
    repeat (delay) @(posedge I_HCLK);
        I_DMA_HGRANT <= value;
endtask

task ready_ahb (input bit value, integer delay);
    repeat (delay) @(posedge I_HCLK) 
        I_DMA_HREADY <= value;
endtask

task set_image_properties (input bit [31:0] height, input bit [31:0] width, input bit [31:0] degrees, input bit [31:0] direction);
    write_apb(p_height, height);
    write_apb(p_width, width);
    write_apb(p_direction, direction);
    write_apb(p_mode, degrees);
endtask

function integer delay (integer new_height, integer new_width);
    integer write_delay;
    write_delay = new_height + new_width;

    delay = write_delay * 2;
endfunction

string input_file = "./input/input.bmp";
string output_file = "./output/output.bmp";
string header;
initial begin
    $vcdplusmemon;
    $vcdpluson;
    
    $display("\n\n================================================");
    $display("===============start simulation=================");

    /*image = $fopen(file, "r");
    new_image = $fopen(new_file, "w");
    if (image == 0) 
        begin
            $display("ERROR in reading file.. file does not exist o__O\n");
            $display("===============failed simulation================");
            $display("================================================\n");
            $finish; 
        end
    else 
        $display("reading file..");

    if (new_image == 0)
        begin
            $display("ERROR in creating file..\n");
            $display("===============failed simulation================");
            $display("================================================\n");
            $finish; 
        end 
    else 
        $display("writing file..");*/

    //initialize all inputs
    initialize();

    hard_reset();

    //####################################################################<<
    //LOAD SCENARIOS #####################################################

    /*----------------------------------------
    * uncomment scenarios to run
    * ---------------------------------------*/

    //scenario 1000--------------------------
    //---------------------------------------
    $display ("running scenario 1000");
    set_image_properties(
        .height(`min_input_image_height), 
        .width(`min_input_image_width), 
        .degrees(`rotate_0_degrees), 
        .direction(`rotate_direction_cw));
    //@(posedge I_PCLK) I_DMA_HGRANT <= `assert_hgrant;
    //ready_ahb (1, 1);

    //scenario 1001--------------------------
    //---------------------------------------
    //$display ("running scenario 1001");
    //set_image_properties(
    //    .height(`min_input_image_height),
    //    .width(`mid_input_image_width),
    //    .degrees(`rotate_90_degrees) 
    //    .direction(`rotate_direction_cw));
    //write_apb(p_start, 1);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <=`deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1002--------------------------
    //---------------------------------------
    //$display ("running scenario 1002");
    //set_image_properties(
    //    .height(`min_input_image_height),
    //    .width(`max_input_image_width),
    //    .degrees(`rotate_180_degrees) 
    //    .direction(`rotate_direction_cw));
    //write_apb(p_start, 1);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1003--------------------------
    //---------------------------------------
    //$display ("running scenario 1003");
    //set_image_properties(
    //    .height(`max_input_image_height),
    //    .width(`min_input_image_width),
    //    .degrees(`rotate_270_degrees) 
    //    .direction(`rotate_direction_cw));
    //write_apb(p_start, 1);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1004--------------------------
    //---------------------------------------
    //$display ("running scenario 1004");
    //set_image_properties(
    //    .height(`max_input_image_height),
    //    .width(`mid_input_image_width),
    //    .degrees(`rotate_90_degrees) 
    //    .direction(`rotate_direction_ccw));
    //write_apb(p_start, 1);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1005--------------------------
    //---------------------------------------
    //$display ("running scenario 1005");
    //set_image_properties(
    //    .height(`max_input_image_height),
    //    .width(`max_input_image_width),
    //    .degrees(`rotate_90_degrees) 
    //    .direction(`rotate_direction_ccw));
    //write_apb(p_start, 1);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1006--------------------------
    //---------------------------------------
    //$display ("running scenario 1006");
    //set_image_properties(
    //    .height(`mid_input_image_height),
    //    .width(`min_input_image_width),
    //    .degrees(`rotate_90_degrees) 
    //    .direction(`rotate_direction_ccw));
    //write_apb(p_start, 1);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1007-------------------------- //TODO: remove scenario 1007
    //---------------------------------------
    //$display ("running scenario 1000");
    //set_image_properties(
    //    .height(`max_input_image_height),
    //    .width(`max_input_image_width),
    //    .degrees(`rotate_90_degrees) 
    //    .direction(`rotate_direction_ccw));
    //write_apb(p_start, 1);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1008--------------------------
    //---------------------------------------
    //$display ("running scenario 1008");
    //set_image_properties(
    //    .height(`mid_input_image_height),
    //    .width(`max_input_image_width),
    //    .degrees(`rotate_0_degrees) 
    //    .direction(`rotate_direction_ccw));
    //write_apb(p_start, 1);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1009--------------------------
    //---------------------------------------
    //$display ("running scenario 1009");
    //set_image_properties(
    //    .height(192),
    //    .width(`min_output_image_width),
    //    .degrees(`rotate_0_degrees) 
    //    .direction(`rotate_direction_cw));
    //write_apb(p_start, 1);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1010--------------------------
    //---------------------------------------
    //$display ("running scenario 1010");
    //set_image_properties(
    //    .height(6144),
    //    .width(16),
    //    .degrees(`rotate_90_degrees) 
    //    .direction(`rotate_direction_ccw));
    //write_apb(p_start, 1);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1011--------------------------
    //---------------------------------------
    //$display ("running scenario 1011");
    //set_image_properties(
    //$display ("running scenario 1000");
    //    .height(`max_input_image_height),
    //    .width(`max_input_image_width),
    //    .degrees(`rotate_270_degrees) 
    //    .direction(`rotate_direction_ccw));
    //write_apb(p_start, 1);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1012--------------------------
    //---------------------------------------
    //$display ("running scenario 1012");
    //set_image_properties(
    //    .height(`min_input_image_height),
    //    .width(`min_input_image_width),
    //    .degrees(`rotate_90_degrees) 
    //    .direction(`rotate_direction_ccw));
    //write_apb(p_start, 1);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1013--------------------------
    //---------------------------------------
    //$display ("running scenario 1013");
    //set_image_properties(
    //    .height(1), 
    //    .width(1), 
    //    .degrees(`rotate_90_degrees), 
    //    .direction(`rotate_direction_cw));
    //write_apb (p_start, 1);
    //@(posedge I_HCLK) I_DMA_HGRANT <= `assert_hgrant;
    //#250;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1014-------------------------- 
    //---------------------------------------
    //$display ("running scenario 1014");
    //set_image_properties(
    //    .height(1), 
    //    .width(1), 
    //    .degrees(`rotate_90_degrees), 
    //    .direction(`rotate_direction_cw));
    //write_apb (p_start, 1);
    //ready_ahb(`no_delay, `assert_hready);
    //#250;
    //@(posedge I_HCLK) I_DMA_HGRANT <= `assert_hgrant;

    //scenario 1015--------------------------
    //---------------------------------------
    //$display ("running scenario 1015");
    //repeat(5) @(posedge I_PCLK)
    //begin
    //    repeat(2)@(posedge I_PCLK);
    //    I_REG_PWDATA = $random;
    //    I_REG_PADDR = $random;
    //end
    //#100;
    //I_REG_PSEL <= `assert_psel;
    //set_image_properties(
    //    .height(1), 
    //    .width(1), 
    //    .degrees(`rotate_90_degrees), 
    //    .direction(`rotate_direction_cw));
    //write_apb(p_start, 1);
    //ready_ahb(`no_delay, `assert_hready);
    //@(posedge I_HCLK) I_DMA_HGRANT <= `assert_hgrant;  

    //(O_DMA_HBUSREQ) @(posedge I_HCLK) grant_ahb(1, 1);
    //####################################################################>>

    read_apb(`dma_dst_img);
    @(posedge I_PCLK)offset <= O_REG_PRDATA;
    read_apb(`rot_img_new_h);
    @(posedge I_PCLK) new_height <= O_REG_PRDATA[15:0];
    read_apb(`rot_img_new_w);
    @(posedge I_PCLK) new_width <= O_REG_PRDATA[15:0];
    ready_ahb(1, 1);
    
//fork //<<<

    //####################################################################<<
    //READ IMAGE #########################################################
    begin
    index = `bmp_header_size;
    image = $fopen(input_file, "r");
    new_image = $fopen(output_file, "wb");

    if (!$feof(image)) 
	$display("successfuly opened file\nreading file..\n\nInput Image Properties:");
    else
	begin
	    $display ("error loading file\nending simulation..");
	    $fclose(image);
	    #1;
	    $finish;
	end

    if (!$feof(new_image)) 
	$display("successfuly created file\nwriting to file..");
    else
	begin
	    $display ("error creating file\nending simulation..");
	    $fclose(new_image);
	    #1;
	    $finish;
	end

    check = $fgets(image, `bmp_header_size, header);
    check = $fseek(image, 22, 0);
    height = $fgetc(image);
    $display("image height = %d",height); 
    check = $fseek(image, 18, 0);
    width = $fgetc(image);
    $display("image width = %d\n",width); 

	write_apb(p_start, 1);
	read_apb(p_start);

    //while (!$feof(image)) 
    //@(posedge I_HCLK) begin
    //    if (!O_DMA_HWRITE)
    //        begin
    //    	$display("address = %x data = %x", O_DMA_HADDR, I_DMA_HRDATA);
    //    	check <= $fseek(image, O_DMA_HADDR + `bmp_header_size, 0);
    //    	I_DMA_HRDATA[7:0] <= $fgetc(image);
    //    	check <= $fseek(image, O_DMA_HADDR + 1 + `bmp_header_size, 0);
    //    	I_DMA_HRDATA[15:8] <= $fgetc(image);
    //    	check <= $fseek(image, O_DMA_HADDR + 2 + `bmp_header_size, 0);
    //    	I_DMA_HRDATA[23:16] <= $fgetc(image);
    //    	check <= $fseek(image, O_DMA_HADDR + 3 + `bmp_header_size, 0);
    //    	I_DMA_HRDATA[31:24] <= $fgetc(image);
    //        end
    //    else 
    //        begin
    //    	check <= $fseek(new_image, O_DMA_HADDR, 0);//+ `bmp_header_size, 0);
    //    	$fwrite(new_image, "%c", O_DMA_HWDATA[7:0]);
    //    	check <= $fseek(new_image, O_DMA_HADDR + 1, 0); //+ `bmp_header_size, 0);
    //    	$fwrite(new_image, "%c", O_DMA_HWDATA[15:8]);
    //    	check <= $fseek(new_image, O_DMA_HADDR + 2, 0); //+ `bmp_header_size, 0);
    //    	$fwrite(new_image, "%c", O_DMA_HWDATA[23:16]);
    //    	check <= $fseek(new_image, O_DMA_HADDR + 3, 0); //+ `bmp_header_size, 0);
    //    	$fwrite(new_image, "%c", O_DMA_HWDATA[31:24]);
    //        end
    //end

    //$display("done reading file\n");
    //$fclose(image);
    //$fclose(new_image);
    end
    //####################################################################>>

    //####################################################################<<
    //CREATE OUTPUT IMAGE ################################################
//    begin
//    new_image = $fopen(output_file, "w");
//
//    if (!$feof(new_image))
//	$display("successfully created new file\nwriting to file..\n\nOutput Image Properties:");
//    else 
//	begin
//	    $display ("error creating file\nending simulation..");
//	    $fclose(image);
//	    #1;
//	    $finish;
//	end
//   
//    $display("image height = %d\nimage width = %d\n",new_height,new_width);
//    //TODO: make sure to read register DMA_DST_IMG for the 
//    //      $fseek offset
//    $fwrite(new_image, "%s", header);
//
//    while (!O_INTR_DONE) begin
//        if (O_DMA_HWRITE)
//            @(posedge I_HCLK) begin
//		$display ("write: %d", check_write);
//        	check <= $fseek(new_image, O_DMA_HADDR + `bmp_header_size, 0);
//        	$fwrite(new_image, "%c", O_DMA_HWDATA[7:0]);
//        	check <= $fseek(new_image, O_DMA_HADDR + 1 + `bmp_header_size, 0);
//        	$fwrite(new_image, "%c", O_DMA_HWDATA[7:0]);
//        	check <= $fseek(new_image, O_DMA_HADDR + 2 + `bmp_header_size, 0);
//        	$fwrite(new_image, "%c", O_DMA_HWDATA[7:0]);
//        	check <= $fseek(new_image, O_DMA_HADDR + 3 + `bmp_header_size, 0);
//        	$fwrite(new_image, "%c", O_DMA_HWDATA[7:0]);
//		check_write <= check_write[14:0] + 1;
//            end
//        else 
//            check <= 0;
//    end
//
//    $display("done creating output image");
//    $fclose(new_image);
//    end
    //####################################################################>>

//join //>>>


    $display("================end simulation==================");
    $display("================================================\n");
    /*$fclose(image);
    $fclose(new_image);*/
    
end

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	I_DMA_HGRANT <= 0;
    else
	if (O_DMA_HBUSREQ)
	    #2 I_DMA_HGRANT <= 1;
	else 
	    I_DMA_HGRANT <= I_DMA_HGRANT;

always @(posedge I_HCLK)
    if (!I_HRESET_N)
	I_DMA_HREADY <= 0;
    else 
	if (O_DMA_HBUSREQ)
	    I_DMA_HREADY <= 1;
	else 
	    I_DMA_HREADY <= I_DMA_HREADY;

always @(posedge I_HCLK)
    if (O_INTR_DONE)
	#300 $finish;
    else 
	#300 $display ("====ongoing test====");

always @(*)
    if (!$feof(image) || O_INTR_DONE) begin

    //while (!$feof(image)) 
    //@(posedge I_HCLK) begin
        if (!O_DMA_HWRITE)
            begin
        	$display("I address = %x data = %x", O_DMA_HADDR, I_DMA_HRDATA);
        	check <= $fseek(image, O_DMA_HADDR + `bmp_header_size, 0);
        	I_DMA_HRDATA[7:0] <= $fgetc(image);
        	check <= $fseek(image, O_DMA_HADDR + 1 + `bmp_header_size, 0);
        	I_DMA_HRDATA[15:8] <= $fgetc(image);
        	check <= $fseek(image, O_DMA_HADDR + 2 + `bmp_header_size, 0);
        	I_DMA_HRDATA[23:16] <= $fgetc(image);
        	check <= $fseek(image, O_DMA_HADDR + 3 + `bmp_header_size, 0);
        	I_DMA_HRDATA[31:24] <= $fgetc(image);
            end
        else 
	    I_DMA_HRDATA <= 0;
    end
    else begin
	$fclose(image);
    end

always @(*)
    if (!$feof(new_image) || O_INTR_DONE) begin
	if (O_DMA_HWRITE)
            begin
        	$display("O address = %x data = %x", O_DMA_HADDR, O_DMA_HWDATA);
        	check <= $fseek(new_image, O_DMA_HADDR, 0); //+ `bmp_header_size, 0);
        	$fwrite(new_image, "%u", O_DMA_HWDATA);
        	//check <= $fseek(new_image, O_DMA_HADDR + 1, 0); //+ `bmp_header_size, 0);
        	//$fwrite(new_image, "%u", O_DMA_HWDATA[15:8]);
        	//check <= $fseek(new_image, O_DMA_HADDR + 2, 0); //+ `bmp_header_size, 0);
        	//$fwrite(new_image, "%u", O_DMA_HWDATA[23:16]);
        	//check <= $fseek(new_image, O_DMA_HADDR + 3, 0); //+ `bmp_header_size, 0);
        	//$fwrite(new_image, "%u", O_DMA_HWDATA[31:24]);
            end
	else 
	    $monitor(O_DMA_HADDR);
    end
    else begin
	$fclose(new_image);
    end
//always @(posedge I_HCLK) 
//    if (!$feof(image) && (O_DMA_HTRANS != 0) && !O_DMA_HWRITE) begin
//            $fscanf(image, "%d", I_DMA_HRDATA[7:0]);
//            $fscanf(image, "%d", I_DMA_HRDATA[15:8]);
//            $fscanf(image, "%d", I_DMA_HRDATA[23:16]);
//            $fscanf(image, "%d", I_DMA_HRDATA[31:24]);
//        end
//    else 
//            I_DMA_HRDATA <= I_DMA_HRDATA;
//
//always @(posedge I_HCLK)
//    if (!O_INTR_DONE)
//        if (O_DMA_HWRITE) begin
//            $fdisplay(image, O_DMA_HWDATA[7:0]);
//            $fdisplay(image, O_DMA_HWDATA[15:8]);
//            $fdisplay(image, O_DMA_HWDATA[23:16]);
//            $fdisplay(image, O_DMA_HWDATA[31:24]);
//        end

endmodule
