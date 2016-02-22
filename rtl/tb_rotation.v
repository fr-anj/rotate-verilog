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

parameter   p_source = 8'h00, p_destination = 8'h04,
            p_height = 8'h08, p_width = 8'h0c,
            p_new_height = 8'h10, p_new_width = 8'h14,
            p_mode = 8'h18, p_direction = 8'h1c,
            p_start = 8'h20, p_reset = 8'h24,
            p_intr_mask = 8'h28, p_bef_mask = 8'h2c,
            p_aft_mask = 8'h30, p_intr_clear = 52;

parameter   p_deg_0 = 0, p_deg_90 = 1, p_deg_180 = 2, p_deg_270 = 3;
parameter   p_ccw = 0, p_cw = 1;

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
        I_REG_PENABLE <= 1;
        I_REG_PWRITE <= 1;
        I_REG_PADDR <= address;
        I_REG_PWDATA <= value;

    @(posedge I_PCLK)
        I_REG_PENABLE <= 0;
endtask

task soft_reset (input bit address);
    write_apb (p_reset, 1);
endtask

task read_apb (input bit [31:0] address);
    @(posedge I_PCLK)
        I_REG_PSEL <= 1;
        I_REG_PENABLE <= 1;
        I_REG_PWRITE <= 0;
        I_REG_PADDR <= address;

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

/*file handling
//reads image by 4 bytes every clock cycle
task read_image (string filename);
    image = $fopen(filename, "r");
    if (image == 0)
        begin
            $display("error in reading image");
            $finish;
        end

    always @(posedge I_HCLK)

    $fclose(filename);
endtask

task create_image (input bit [31:0] data, filename);
    image = $fopen(
endtask
*/
initial begin
    $vcdplusmemon;
    $vcdpluson;
    //initialize all inputs
    initialize();

    hard_reset();

    //scenario 1000
    set_image_properties(.height(1), .width(1), .degrees(p_deg_0), .direction(p_cw));
    write_apb(p_start, 1);
    read_apb(p_start);
    if (O_DMA_HBUSREQ) @(posedge I_HCLK) grant_ahb(1, 1);

    #20000 $finish;
end

endmodule
