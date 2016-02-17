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
    .O_REG_PRDATA(O_REG_PRDATA);
    .O_DMA_HADDR(O_DMA_HADDR);
    .O_DMA_HWDATA(O_DMA_HWDATA);
    .O_DMA_HTRANS(O_DMA_HTRANS);
    .O_DMA_HSIZE(O_DMA_HSIZE);
    .O_DMA_HBURST(O_DMA_HBURST);
    .O_DMA_HBUSREQ(O_DMA_HBUSREQ);
    .O_DMA_HWRITE(O_DMA_HWRITE);
    .O_INTR_DONE(O_INTR_DONE);
    .I_REG_PADDR(I_REG_PADDR);
    .I_REG_PWDATA(I_REG_PWDATA);
    .I_DMA_HRDATA(I_DMA_HRDATA);
    .I_REG_PSEL(I_REG_PSEL);
    .I_REG_PENABLE(I_REG_PENABLE);
    .I_REG_PWRITE(I_REG_PWRITE);
    .I_DMA_HGRANT(I_DMA_HGRANT);
    .I_DMA_HREADY(I_DMA_HREADY);
    .I_PRESET_N(I_PRESET_N);
    .I_HRESET_N(I_HRESET_N);
    .I_PCLK(I_PCLK);
    .I_HCLK(I_HCLK);
    );

    always 
        #10 I_HCLK <= ~I_HCLK;

    initial begin 
        I_REG_PADDR = 0;
        I_REG_PWDATA = 0;
        I_DMA_HRDATA = 0;
        I_REG_PSEL = 0;
        I_REG_PENABLE = 0;
        I_REG_PWRITE = 0;
        I_DMA_HGRANT = 0;
        I_DMA_HREADY = 0;
        I_PRESET_N = 0;
        I_HRESET_N = 0;
        I_PCLK = 0;
        I_HCLK = 0;
    end

    initial begin
        $vcdpluson;

        #30000 $finish;
    end

endmodule
