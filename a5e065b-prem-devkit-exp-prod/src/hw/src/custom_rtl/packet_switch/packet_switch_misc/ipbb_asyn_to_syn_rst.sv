//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

//--------------------------------------------------------------------------------------------
// Description: ipbb_asyn_to_syn_rst
// 
// Converts asynchronous reset to synchronous reset.
//
//--------------------------------------------------------------------------------------------

module ipbb_asyn_to_syn_rst
    (input  var clk
     ,input var logic asyn_rst

     ,output var logic syn_rst

     );


    logic asyn_rst_c1, asyn_rst_c2;
    
    always @(posedge clk or posedge asyn_rst) begin
	if (asyn_rst) begin
	    asyn_rst_c1 <= 'd1;
	    asyn_rst_c2 <= 'd1;
	    syn_rst     <= 'd1;
	end // if (asyn_rst)
	else begin
	    asyn_rst_c1 <= 'd0;
	
	    asyn_rst_c2 <= asyn_rst_c1;
	
	    syn_rst <= asyn_rst_c2;
	end	
    end

endmodule




	
