//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

//--------------------------------------------------------------------------------------------
// Description: packet_switch_ipbb_pref_rrarb
// 
// - basic round robin arbitration with prefetch
//
///////////////////////////////////////////////////////////////////////////////////////////////
//`default_nettype none

module packet_switch_ipbb_pref_rrarb 
 #( parameter  N        = 2      // number of inputs min=2, max=8
   ,parameter  NUM_REQ  = 32     // number of requests per input
   ,parameter  SP_IF0   = 0      // if0 has strict priority if set

   ,parameter  SP_ARB   = 1      // strict priority arbitration. only 1 is supported.
    
   ,parameter  PREF_GNT_DEPTH = N*4
   ,parameter  N_WIDTH = N < 2 ? 1 : $clog2(N)
    ) 
   ( 

     input var logic                         clk
    ,input var logic                         rst

    ,input var logic [N-1:0]                 req        // input port request
    //,input var logic [N-1:0]                 req_stall  // stall the rr request. the stall
    //                                                    // port will not get to enqueue to
    //                                                    // the pref_rr_ffio

    ,input var logic                         gnt_in_flight
    ,input var logic                         gnt_pop
    ,output var logic [N_WIDTH-1:0]          gnt        // selected port 
    ,output var logic                        gnt_vld    // selected port valid

    ,output var logic [N-1:0][$clog2(PREF_GNT_DEPTH)-1:0] num_pref_gnt
     );

		       
   
   localparam NUM_REQ_WIDTH = $clog2(NUM_REQ);
   localparam PREF_GNT_WIDTH = $clog2(PREF_GNT_DEPTH);
   localparam PREF_GNT_STALL_WM = (PREF_GNT_DEPTH == 4) ? PREF_GNT_DEPTH - 2 : PREF_GNT_DEPTH - 4;
   
   // Generate arrays of reset to be used in submodule
   logic [31:0] rst_reg;
   always_ff @(posedge clk) begin
	rst_reg <= '{default:rst};
   end
   
   logic [N-1:0] [NUM_REQ_WIDTH-1:0] ireq_cnt;
   logic [N-1:0] inc_ireq_cnt,  dec_ireq_cnt, rr_req, rr_req_tmp;
   
   logic [N-1:0] rr_en, pref_rr_fifo_rdy, pref_rr_fifo_mty, pref_rr_fifo_full;

   logic [N-1:0] rr_pop, xfer_ongoing;

   always_comb begin
      inc_ireq_cnt = req;
      // dec_ireq_cnt = rr_gnt;      
      dec_ireq_cnt = rr_en;      
   end

   
   // keeps tracks of number of input requests
   always_ff @(posedge clk) begin
      for (int i = 0; i < N; i++) begin
	 if (inc_ireq_cnt[i] & !dec_ireq_cnt[i])
	   ireq_cnt[i] <= ireq_cnt[i] + 1'b1;
	 else if (!inc_ireq_cnt[i] & dec_ireq_cnt[i])
	   ireq_cnt[i] <= ireq_cnt[i] - 1'b1;
      end
      
      if (rst_reg[0])
	ireq_cnt <= '0;      
   end

   always_comb begin
      for (int i = 0; i < N; i++) begin
	 // rr request if number of input requests is not zero
	 rr_req_tmp[i] = (ireq_cnt[i] != '0) ;
      end

      if (SP_IF0 == 1) begin
	 if (rr_req_tmp[0]) begin
	    rr_req[0] = '1;

	    for (int i = 1; i < N; i++) begin
	       rr_req[i] = '0;	       
	    end
	 end
	 
	 else begin
	    rr_req = rr_req_tmp;	  
	 end	 
      end
      else begin
	 rr_req = rr_req_tmp;
      end

      for (int i = 0; i < N; i++) begin
        // pref_rr_fifo_rdy[i] = num_pref_gnt[i] < PREF_GNT_STALL_WM;
        
        // enable rr
        // rr_en = |rr_req & pref_rr_fifo_rdy;      
        rr_en[i] = rr_req[i] & pref_rr_fifo_rdy[i];      
      end
   end

   always_ff @(posedge clk) begin
      for (int i = 0; i < N; i++) begin
        pref_rr_fifo_rdy[i] <= num_pref_gnt[i] < PREF_GNT_STALL_WM;
      end
   end

   genvar i;
   generate
   for (i = 0; i < N; i++) begin : gen_rr_fifo
    packet_switch_ipbb_sdc_fifo_inff
     #(.DWD (1)
       ,.NUM_WORDS  (PREF_GNT_DEPTH)
       ) rr_fifo
      (  .clk1 (clk)
	,.clk2 (clk)
	,.rst (rst_reg[2])
	
	// inputs
	,.din (rr_en[i])
	,.wrreq (rr_en[i])
	,.rdreq (rr_pop[i])
	
	// outputs
	,.dout ()
	,.rdempty (pref_rr_fifo_mty[i])
    ,.rdempty_lkahd () 
	,.wrfull (pref_rr_fifo_full[i])
	,.wrusedw (num_pref_gnt[i])
	
	);
   end
   endgenerate

   always_comb begin
    for (int i = 0; i < N; i++) begin
     rr_pop[i] = xfer_ongoing[i] & gnt_pop & (gnt == i);
    end	    
/*
     rr_pop[0] = xfer_ongoing[0] & gnt_pop & (gnt == 'd0);
     rr_pop[1] = xfer_ongoing[1] & gnt_pop & (gnt == 'd1);
     rr_pop[2] = xfer_ongoing[2] & gnt_pop & (gnt == 'd2);
     rr_pop[3] = xfer_ongoing[3] & gnt_pop & (gnt == 'd3);
*/
   end

   always_ff @(posedge clk) begin
    for (int i = 0; i < N; i++) begin
     if (!pref_rr_fifo_mty[i] & !gnt_in_flight & !gnt_pop & (gnt == i))
       xfer_ongoing[i] <= '1;
     else if (xfer_ongoing[i] & gnt_pop)
       xfer_ongoing[i] <= '0;
    end	// for   

    if (rst)
      xfer_ongoing <= '0;
   end  

   generate
   if (N == 8) begin :  gen_gnt_8

   always_comb begin
     gnt = '0;
     gnt_vld = '0;
     if (!pref_rr_fifo_mty[0] & (!gnt_in_flight | xfer_ongoing[0])) begin
       gnt = 'd0;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[1] & (!gnt_in_flight | xfer_ongoing[1])) begin
       gnt = 'd1;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[2] & (!gnt_in_flight | xfer_ongoing[2])) begin
       gnt = 'd2;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[3] & (!gnt_in_flight | xfer_ongoing[3])) begin
       gnt = 'd3;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[4] & (!gnt_in_flight | xfer_ongoing[4])) begin
       gnt = 'd4;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[5] & (!gnt_in_flight | xfer_ongoing[5])) begin
       gnt = 'd5;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[6] & (!gnt_in_flight | xfer_ongoing[6])) begin
       gnt = 'd6;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[7] & (!gnt_in_flight | xfer_ongoing[7])) begin
       gnt = 'd7;
       gnt_vld = '1;
     end else begin
       gnt = '0;
       gnt_vld = '0;
     end
   end

   end else if (N == 7) begin : gen_gnt_7

   always_comb begin
     gnt = '0;
     gnt_vld = '0;
     if (!pref_rr_fifo_mty[0] & (!gnt_in_flight | xfer_ongoing[0])) begin
       gnt = 'd0;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[1] & (!gnt_in_flight | xfer_ongoing[1])) begin
       gnt = 'd1;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[2] & (!gnt_in_flight | xfer_ongoing[2])) begin
       gnt = 'd2;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[3] & (!gnt_in_flight | xfer_ongoing[3])) begin
       gnt = 'd3;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[4] & (!gnt_in_flight | xfer_ongoing[4])) begin
       gnt = 'd4;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[5] & (!gnt_in_flight | xfer_ongoing[5])) begin
       gnt = 'd5;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[6] & (!gnt_in_flight | xfer_ongoing[6])) begin
       gnt = 'd6;
       gnt_vld = '1;
     end else begin
       gnt = '0;
       gnt_vld = '0;
     end
   end

   end else if (N == 6) begin : gen_gnt_6

   always_comb begin
     gnt = '0;
     gnt_vld = '0;
     if (!pref_rr_fifo_mty[0] & (!gnt_in_flight | xfer_ongoing[0])) begin
       gnt = 'd0;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[1] & (!gnt_in_flight | xfer_ongoing[1])) begin
       gnt = 'd1;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[2] & (!gnt_in_flight | xfer_ongoing[2])) begin
       gnt = 'd2;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[3] & (!gnt_in_flight | xfer_ongoing[3])) begin
       gnt = 'd3;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[4] & (!gnt_in_flight | xfer_ongoing[4])) begin
       gnt = 'd4;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[5] & (!gnt_in_flight | xfer_ongoing[5])) begin
       gnt = 'd5;
       gnt_vld = '1;
     end else begin
       gnt = '0;
       gnt_vld = '0;
     end
   end

   end else if (N == 5) begin : gen_gnt_5

   always_comb begin
     gnt = '0;
     gnt_vld = '0;
     if (!pref_rr_fifo_mty[0] & (!gnt_in_flight | xfer_ongoing[0])) begin
       gnt = 'd0;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[1] & (!gnt_in_flight | xfer_ongoing[1])) begin
       gnt = 'd1;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[2] & (!gnt_in_flight | xfer_ongoing[2])) begin
       gnt = 'd2;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[3] & (!gnt_in_flight | xfer_ongoing[3])) begin
       gnt = 'd3;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[4] & (!gnt_in_flight | xfer_ongoing[4])) begin
       gnt = 'd4;
       gnt_vld = '1;
     end else begin
       gnt = '0;
       gnt_vld = '0;
     end
   end

   end else if (N == 4) begin : gen_gnt_4

   always_comb begin
     gnt = '0;
     gnt_vld = '0;
     if (!pref_rr_fifo_mty[0] & (!gnt_in_flight | xfer_ongoing[0])) begin
       gnt = 'd0;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[1] & (!gnt_in_flight | xfer_ongoing[1])) begin
       gnt = 'd1;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[2] & (!gnt_in_flight | xfer_ongoing[2])) begin
       gnt = 'd2;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[3] & (!gnt_in_flight | xfer_ongoing[3])) begin
       gnt = 'd3;
       gnt_vld = '1;
     end else begin
       gnt = '0;
       gnt_vld = '0;
     end
   end

   end else if (N == 3) begin : gen_gnt_3

   always_comb begin
     gnt = '0;
     gnt_vld = '0;
     if (!pref_rr_fifo_mty[0] & (!gnt_in_flight | xfer_ongoing[0])) begin
       gnt = 'd0;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[1] & (!gnt_in_flight | xfer_ongoing[1])) begin
       gnt = 'd1;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[2] & (!gnt_in_flight | xfer_ongoing[2])) begin
       gnt = 'd2;
       gnt_vld = '1;
     end else begin
       gnt = '0;
       gnt_vld = '0;
     end
   end

   end else begin : gen_gnt_2

   always_comb begin
     gnt = '0;
     gnt_vld = '0;
     if (!pref_rr_fifo_mty[0] & (!gnt_in_flight | xfer_ongoing[0])) begin
       gnt = 'd0;
       gnt_vld = '1;
     end else if (!pref_rr_fifo_mty[1] & (!gnt_in_flight | xfer_ongoing[1])) begin
       gnt = 'd1;
       gnt_vld = '1;
     end else begin
       gnt = '0;
       gnt_vld = '0;
     end
   end

   end
   endgenerate
   
endmodule