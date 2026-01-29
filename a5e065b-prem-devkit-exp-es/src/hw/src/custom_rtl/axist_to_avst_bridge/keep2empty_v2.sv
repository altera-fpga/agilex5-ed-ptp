//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 



// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on


module keep2empty_v2 #(
    parameter EMPTY_BITS    	 = 3,
    parameter NO_OF_BYTES  		 = 8 
	
) (
    input       				         clk, 
    input       				         rst_n, 
    input      [NO_OF_BYTES-1:0] keep_bits_in, 
    output reg [EMPTY_BITS-1:0]  empty_bits_out_d1

);

//***********************************************************
//***********************************************************

//reg [NO_OF_BYTES-1:0] keep_reg;
//reg [NO_OF_BYTES-1:0] empty_bytes;

always @(posedge clk or negedge rst_n)
begin
	if (~rst_n)
		empty_bits_out_d1 <= {EMPTY_BITS{1'b0}};
	else 
		empty_bits_out_d1 <= empty_bytes(keep_bits_in);
end
	

		function [EMPTY_BITS-1:0] empty_bytes;
			 input [NO_OF_BYTES-1:0] keep;
			 integer i;
			 begin
				 empty_bytes = {EMPTY_BITS{1'b0}};
				 for (i=0;i<NO_OF_BYTES;i=i+1) begin
					if (!keep[i])
						empty_bytes = empty_bytes + 1'b1;
				 end
			 end
		endfunction
endmodule
