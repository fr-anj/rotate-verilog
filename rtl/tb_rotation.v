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

task create_image (input bit [31:0] data, filename);
    image = $fopen("filename","w");
    if (image == 0)
        begin
            $display("error in writing image");
            $finish;
        end
    $fclose(filename);
endtask

string file = "./input/input.txt";
string new_file = "./output/rtloutput.txt";

initial begin
    $vcdplusmemon;
    $vcdpluson;
    
    $display("\n\n================================================");
    $display("===============start simulation=================");

    image = $fopen(file, "r");
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
        $display("writing file..");

    //initialize all inputs
    initialize();

    hard_reset();

    //scenario 1000--------------------------
    //---------------------------------------
    //set_image_properties(
    //    .height(`min_input_image_height), 
    //    .width(`min_input_image_width), 
    //    .degrees(`rotate_0_degrees), 
    //    .direction(`rotate_direction_cw));
    //write_apb(p_start, 1);
    //write_apb(p_start, 0);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= 0; 
    //ready_ahb (1, 1);

    //scenario 1001--------------------------
    //---------------------------------------
    //set_image_properties(
    //    .height(`min_input_image_height),
    //    .width(`mid_input_image_width),
    //    .degrees(`rotate_90_degrees) 
    //    .direction(`rotate_direction_cw));
    //write_apb(p_start, 1);
    //write_apb(p_start, 0);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <=`deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1002--------------------------
    //---------------------------------------
    //set_image_properties(
    //    .height(`min_input_image_height),
    //    .width(`max_input_image_width),
    //    .degrees(`rotate_180_degrees) 
    //    .direction(`rotate_direction_cw));
    //write_apb(p_start, 1);
    //write_apb(p_start, 0);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1003--------------------------
    //---------------------------------------
    //set_image_properties(
    //    .height(`max_input_image_height),
    //    .width(`min_input_image_width),
    //    .degrees(`rotate_270_degrees) 
    //    .direction(`rotate_direction_cw));
    //write_apb(p_start, 1);
    //write_apb(p_start, 0);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1004--------------------------
    //---------------------------------------
    //set_image_properties(
    //    .height(`max_input_image_height),
    //    .width(`mid_input_image_width),
    //    .degrees(`rotate_90_degrees) 
    //    .direction(`rotate_direction_ccw));
    //write_apb(p_start, 1);
    //write_apb(p_start, 0);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1005--------------------------
    //---------------------------------------
    //set_image_properties(
    //    .height(`max_input_image_height),
    //    .width(`max_input_image_width),
    //    .degrees(`rotate_90_degrees) 
    //    .direction(`rotate_direction_ccw));
    //write_apb(p_start, 1);
    //write_apb(p_start, 0);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1006--------------------------
    //---------------------------------------
    //set_image_properties(
    //    .height(`mid_input_image_height),
    //    .width(`min_input_image_width),
    //    .degrees(`rotate_90_degrees) 
    //    .direction(`rotate_direction_ccw));
    //write_apb(p_start, 1);
    //write_apb(p_start, 0);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1007-------------------------- //TODO: remove scenario 1007
    //---------------------------------------
    //set_image_properties(
    //    .height(`max_input_image_height),
    //    .width(`max_input_image_width),
    //    .degrees(`rotate_90_degrees) 
    //    .direction(`rotate_direction_ccw));
    //write_apb(p_start, 1);
    //write_apb(p_start, 0);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1008--------------------------
    //---------------------------------------
    //set_image_properties(
    //    .height(`mid_input_image_height),
    //    .width(`max_input_image_width),
    //    .degrees(`rotate_0_degrees) 
    //    .direction(`rotate_direction_ccw));
    //write_apb(p_start, 1);
    //write_apb(p_start, 0);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1009--------------------------
    //---------------------------------------
    //set_image_properties(
    //    .height(192),
    //    .width(`min_output_image_width),
    //    .degrees(`rotate_0_degrees) 
    //    .direction(`rotate_direction_cw));
    //write_apb(p_start, 1);
    //write_apb(p_start, 0);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1010--------------------------
    //---------------------------------------
    //set_image_properties(
    //    .height(6144),
    //    .width(16),
    //    .degrees(`rotate_90_degrees) 
    //    .direction(`rotate_direction_ccw));
    //write_apb(p_start, 1);
    //write_apb(p_start, 0);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1011--------------------------
    //set_image_properties(
    //    .height(`max_input_image_height),
    //    .width(`max_input_image_width),
    //    .degrees(`rotate_270_degrees) 
    //    .direction(`rotate_direction_ccw));
    //write_apb(p_start, 1);
    //write_apb(p_start, 0);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1012--------------------------
    //set_image_properties(
    //    .height(`min_input_image_height),
    //    .width(`min_input_image_width),
    //    .degrees(`rotate_90_degrees) 
    //    .direction(`rotate_direction_ccw));
    //write_apb(p_start, 1);
    //write_apb(p_start, 0);
    //read_apb(p_start);
    //@(posedge I_PCLK) I_REG_PENABLE <= `deassert_penable;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1013--------------------------
    //---------------------------------------
    //set_image_properties(
    //    .height(1), 
    //    .width(1), 
    //    .degrees(`rotate_90_degrees), 
    //    .direction(`rotate_direction_cw));
    //write_apb (p_start, 1);
    //write_apb (p_start, 0);
    //@(posedge I_HCLK) I_DMA_HGRANT <= `assert_hgrant;
    //#250;
    //ready_ahb(`no_delay, `assert_hready);

    //scenario 1014-------------------------- 
    //---------------------------------------
    //set_image_properties(
    //    .height(1), 
    //    .width(1), 
    //    .degrees(`rotate_90_degrees), 
    //    .direction(`rotate_direction_cw));
    //write_apb (p_start, 1);
    //write_apb (p_start, 0);
    //ready_ahb(`no_delay, `assert_hready);
    //#250;
    //@(posedge I_HCLK) I_DMA_HGRANT <= `assert_hgrant;

    //scenario 1015--------------------------
    //---------------------------------------
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
    //write_apb(p_start, 0);
    //ready_ahb(`no_delay, `assert_hready);
    //@(posedge I_HCLK) I_DMA_HGRANT <= `assert_hgrant;  

    //(O_DMA_HBUSREQ) @(posedge I_HCLK) grant_ahb(1, 1);

    $display("================end simulation==================");
    $display("================================================\n");

    #460

    $fclose(image);
    $fclose(new_image);
    
    $finish;
end

always @(posedge I_HCLK) 
    if (!$feof(image) && (O_DMA_HTRANS != 0) && !O_DMA_HWRITE) begin
            $fscanf(image, "%d", I_DMA_HRDATA[7:0]);
            $fscanf(image, "%d", I_DMA_HRDATA[15:8]);
            $fscanf(image, "%d", I_DMA_HRDATA[23:16]);
            $fscanf(image, "%d", I_DMA_HRDATA[31:24]);
        end
    else 
            I_DMA_HRDATA <= I_DMA_HRDATA;

always @(posedge I_HCLK)
    if (!O_INTR_DONE)
        if (O_DMA_HWRITE) begin
            $fdisplay(image, O_DMA_HWDATA[7:0]);
            $fdisplay(image, O_DMA_HWDATA[15:8]);
            $fdisplay(image, O_DMA_HWDATA[23:16]);
            $fdisplay(image, O_DMA_HWDATA[31:24]);
        end

endmodule
