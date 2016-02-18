module tb_rotation ();
    wire [31:0] O_REG_PRDATA;
    wire [31:0] O_DMA_HADDR;
    wire [31:0] O_DMA_HWDATA;
    wire [1:0] O_DMA_HTRANS;
    wire [2:0] O_DMA_HSIZE;
    wire [3:0] O_DMA_HBURST;
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

parameter   p_source = 0, p_destination = 4,
            p_height = 8, p_width = 12,
            p_mode = 24, p_direction = 28,
            p_start = 32, p_reset = 36,
            p_intr_clear = 52;

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

task apb_ready ();
    @(posedge I_PCLK)
        I_REG_PSEL <= 1;
    @(posedge I_PCLK)
        I_REG_PENABLE <= 1;
endtask

task write_apb (address, value);
    @(posedge I_PCLK)
        I_REG_PWRITE <= 1;
        I_REG_PADDR <= address;
        I_REG_PWDATA <= value;
endtask

task soft_reset (address);
    write_apb (p_reset, 1);
endtask

task read_apb (address);
    @(posedge I_PCLK)
        I_REG_PWRITE <= 0;
        I_REG_PADDR <= address;
endtask

task send_to_ahb (data);
    @(posedge I_HCLK)
        I_DMA_HREADY <= 1;
        I_DMA_HRDATA <= data;
endtask

task grant_ahb ();
    @(posedge I_HCLK)
        I_DMA_HGRANT <= 1;
endtask

initial begin
    $vcdpluson;
    //initialize all inputs
    initialize();

    hard_reset();
    apb_ready();

    write_apb(p_height, 8);
    write_apb(p_width, 0);
    #2000 $finish;
end

endmodule
