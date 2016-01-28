//`define PIXEL_SET_MAX_H 8
//`define PIXEL_SET_MAX_W 8
//`define PIXEL_SET_MAX_PIXEL 64
//`define S:TART_THROUGH_MODE 0
//`define START_90_DEG_MODE 

/**
*Things to take note of 
    * There are 64 pixels
    * 192 addresses 
    * so increment and decrements
    * are by 3s not 1s
    * TODO: edit functional specifications 
    *       fixed address values (decrement/increment)
    * TODO: check code is it corresponds to 
    *       these notes
    * going in requires 4 8bits so 
    * increment or decrements are by 4s
    * TODO: make sure address in (input_mem)
    * 	    and address out (output_mem)
    * 	    follows
    * PIXEL_IN_ADDR_0123 --> by 4s --> from ahb to input_mem
    * PIXEL_OUT_ADDR_RGB --> by 3s --> from input_mem to output_mem
    * PIXEL_IN_ADDR_RGB  --> by 3s --> from input_mem to output_mem
    * PIXEL_OUT_ADDR_0123 --> by 4s --> from output_mem to ahb
    *
*/

module core_pixel (
    output [7:0] O_PIXEL_IN_ADDR0,
    output [7:0] O_PIXEL_IN_ADDR1,
    output [7:0] O_PIXEL_IN_ADDR2,
    output [7:0] O_PIXEL_IN_ADDR3,
    output [7:0] O_PIXEL_OUT_ADDRB,
    output [7:0] O_PIXEL_OUT_ADDRG,
    output [7:0] O_PIXEL_OUT_ADDRR,
    output [7:0] O_PIXEL_OUT_ADDR0,
     
    output [7:0] O_PIXEL_OUT_ADDR1,
    output [7:0] O_PIXEL_OUT_ADDR2,
    output [7:0] O_PIXEL_OUT_ADDR3,
    output [7:0] O_PIXEL_IN_ADDRB,
    output [7:0] O_PIXEL_IN_ADDRG,
    output [7:0] O_PIXEL_IN_ADDRR,

    input [15:0] I_HEIGHT,
    input [15:0] I_WIDTH,
    input 	 I_DIRECTION,
    input [1:0]	 I_DEGREES,
    input 	 I_DMA_READY,
    input 	 I_START,

    input 	 I_HRESET_N,
    input 	 I_HCLK
);

endmodule
