//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

//--------------------------------------------------------------------------------------------
// Description: ipbb_sfw_fifo
// 
// - Store and fwd fifo
//
///////////////////////////////////////////////////////////////////////////////////////////////

module packet_switch_ipbb_sfw_fifo #(parameter DW=8, DEPTH=16)
   (
     input var logic                     clk
    ,input var logic                     rst
    ,input var logic                     push     // push data
    ,input var logic                     rel_ptr  // release wptr
    ,input var logic                     pop      // pop data
    ,input var logic [DW-1:0]            din      // din

    ,output var logic [DW-1:0]           dout     // data output
    ,output var logic                    full     // full
    ,output var logic                    empty    // empty
    ,output var logic [$clog2(DEPTH)-1:0]  cnt      // fifo occupancy
    ,output var logic                    overflow     // full
    ,output var logic                    underflow // empty

    );

   localparam ADDR_WIDTH = $clog2(DEPTH);
   localparam MEM_DEPTH = 2**ADDR_WIDTH; // to fill up the whole range of ADDR_WIDTH
   localparam FULL_THRESHOLD = MEM_DEPTH-2;
   
   // memory buffer
   logic [MEM_DEPTH-1:0] [DW-1:0] mem;
   logic [DW-1:0] 	      mem_wdata, mem_rdata, mem_rdata_1c;
   logic [ADDR_WIDTH-1:0]     mem_wptr, nxt_mem_wptr, mem_rptr, nxt_mem_rptr, rel_wptr_dly,
			      rel_wptr_dly1,
			      rel_wptr, nxt_rel_wptr;
   logic 		      mem_wr, mem_rd, mem_rdata_vld, mem_rdata_vld_1c, mem_empty,
			      pref_buf_full;
   logic [2:0] 		      nxt_pref_buf_cnt, pref_buf_cnt;
   
   logic tmp; 
   			      
   
   logic [$clog2(DEPTH)-1:0] sfw_fifo_cnt, mem_ptr;
   logic                     sfw_fifo_empty,  sfw_fifo_full;
   
   always_comb begin
      // rd pointer
      nxt_mem_rptr = pop ? mem_rptr + 1'b1 : mem_rptr;

      // wr pointer
      nxt_mem_wptr = push ? mem_wptr + 1'b1 : mem_wptr;

      // release wr pointer
      nxt_rel_wptr = push & rel_ptr ? (mem_wptr + 1'b1) : rel_wptr_dly;  
           
   end
   
   always_ff @(posedge clk) begin
      mem_wptr       <= nxt_mem_wptr;
      mem_rptr       <= nxt_mem_rptr;
      rel_wptr_dly   <= nxt_rel_wptr;
      rel_wptr_dly1  <= rel_wptr_dly;
      
      rel_wptr       <= rel_wptr_dly1;

      if (rst) begin
	 mem_rptr     <= '0;
	 mem_wptr     <= '0;
	 rel_wptr_dly <= '0;
	 
      end
   end
   
   always_comb begin      
      empty = sfw_fifo_empty ? '1 : 
                               (mem_rptr == rel_wptr);
      full  = sfw_fifo_full; 
      cnt   = sfw_fifo_cnt;
   end
   
   
   packet_switch_ipbb_sdc_fifo_inff #( .DWD (DW)
		        ,.NUM_WORDS  (DEPTH)
		       ) sfw_fifo
     ( .clk1 (clk)
       ,.clk2 (clk)
       ,.rst (rst)
       
       // inputs
       ,.din (din)
       ,.wrreq (push)
       ,.rdreq (pop)
       
       // outputs
       ,.dout (dout)
       ,.rdempty (sfw_fifo_empty)
       ,.rdempty_lkahd ()
       ,.wrfull (sfw_fifo_full)
       ,.wrusedw (sfw_fifo_cnt)
       ,.overflow(overflow)
       ,.underflow(underflow)
       );
  
  
endmodule
