//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


//---------------------------------------------------------------------------------------------
// Description: Priority Round Robin
//  - Round Robin arbitration within a priority
//  - Priority 0 is highest priority.
//  - Higher priority will get service until queue is empty before switching to a lower 
//    priority.
//---------------------------------------------------------------------------------------------

module ipbb_priority_rr
 #(
   parameter NUM_QUE            = 4     // number of queue per priority
            ,NUM_PRIORITY       = 2     // number of priority Max NUM_PRIORITY = 4
            ,NUM_QUE_WIDTH      = $clog2(NUM_QUE)
            ,NUM_PRIORITY_WIDTH = $clog2(NUM_PRIORITY)
   )
 (
   input var logic                            clk
  ,input var logic                            rst
  ,input var logic [NUM_PRIORITY -1:0]
                   [NUM_QUE -1:0]             req
  ,input var logic                            en

  ,output var logic                           gnt_vld
  ,output var logic [NUM_QUE_WIDTH -1:0]      gnt_id
  ,output var logic [NUM_PRIORITY_WIDTH -1:0] gnt_prio_id
  
  
  );   

   logic [NUM_PRIORITY -1:0]
	 [NUM_QUE -1:0]        rr_req;
   
   logic [NUM_PRIORITY -1:0]
	 [NUM_QUE_WIDTH -1:0] rr_gnt_id, nxt_rr_gnt_id;
   
   logic [NUM_PRIORITY -1:0] rr_gnt, nxt_rr_gnt;
   
   logic [NUM_PRIORITY -1:0] rr_prio_gnt;
   
   logic [NUM_PRIORITY_WIDTH -1:0] rr_prio_id;
   
   
   always_comb begin
      for (int i = 0; i < NUM_PRIORITY; i++) begin
	 rr_prio_gnt[i] = |nxt_rr_gnt[i];
      end
   end

   generate
      if (NUM_PRIORITY == 2) begin
	 always_comb begin
	    case (1)
	      rr_prio_gnt[0]: begin
		 rr_prio_id  = '0;
		 gnt_prio_id = '0;
		 gnt_id      = nxt_rr_gnt_id[0];
		 gnt_vld     = |nxt_rr_gnt[0];
	      end
	      rr_prio_gnt[1]: begin
		 rr_prio_id  = 'd1;
		 gnt_prio_id = 'd1;
		 gnt_id      = nxt_rr_gnt_id[1];
		 gnt_vld     = |nxt_rr_gnt[1];
	      end
	      default: begin       
		 rr_prio_id  = '0;
		 gnt_prio_id = '0;
		 gnt_id      = nxt_rr_gnt_id[0];
		 gnt_vld     = |nxt_rr_gnt[0];
	      end
	    endcase // case (1)
	 end
      end

      else if (NUM_PRIORITY == 3) begin
	 always_comb begin
	    case (1)
	      rr_prio_gnt[0]: begin
		 rr_prio_id  = '0;
		 gnt_prio_id = '0;
		 gnt_id      = nxt_rr_gnt_id[0];
		 gnt_vld     = |nxt_rr_gnt[0];
	      end
	      rr_prio_gnt[1]: begin
		 rr_prio_id  = 'd1;
		 gnt_prio_id = 'd1;
		 gnt_id      = nxt_rr_gnt_id[1];
		 gnt_vld     = |nxt_rr_gnt[1];
	      end
	      rr_prio_gnt[2]: begin
		 rr_prio_id  = 'd2;
		 gnt_prio_id = 'd2;
		 gnt_id      = nxt_rr_gnt_id[2];
		 gnt_vld     = |nxt_rr_gnt[2];
	      end
	      default: begin       
		 rr_prio_id  = '0;
		 gnt_prio_id = '0;
		 gnt_id      = nxt_rr_gnt_id[0];
		 gnt_vld     = |nxt_rr_gnt[0];
	      end
	    endcase // case (1)
	 end
      end
      
      else if (NUM_PRIORITY == 4) begin
	 always_comb begin
	    case (1)
	      rr_prio_gnt[0]: begin
		 rr_prio_id  = '0;
		 gnt_prio_id = '0;
		 gnt_id      = nxt_rr_gnt_id[0];
		 gnt_vld     = |nxt_rr_gnt[0];
	      end
	      rr_prio_gnt[1]: begin
		 rr_prio_id  = 'd1;
		 gnt_prio_id = 'd1;
		 gnt_id      = nxt_rr_gnt_id[1];
		 gnt_vld     = |nxt_rr_gnt[1];
	      end
	      rr_prio_gnt[2]: begin
		 rr_prio_id  = 'd2;
		 gnt_prio_id = 'd2;
		 gnt_id      = nxt_rr_gnt_id[2];
		 gnt_vld     = |nxt_rr_gnt[2];
	      end
	      rr_prio_gnt[3]: begin
		 rr_prio_id  = 'd3;
		 gnt_prio_id = 'd3;
		 gnt_id      = nxt_rr_gnt_id[3];
		 gnt_vld     = |nxt_rr_gnt[3];
	      end
	      
	      default: begin
		 rr_prio_id  = '0;
		 gnt_prio_id = '0;
		 gnt_id      = nxt_rr_gnt_id[0];
		 gnt_vld     = |nxt_rr_gnt[0];
	      end
	    endcase // case (1)
	 end
      end // if (NUM_PRIORITY == 4)

      else begin
	 always_comb begin
	    rr_prio_id = '0;
	    gnt_prio_id = '0;
	    gnt_id      = nxt_rr_gnt_id[0];
	    gnt_vld     = |nxt_rr_gnt[0];
	 end
      end // else: !if(NUM_PRIORITY == 4)
   endgenerate
   
      
   generate
      for (genvar gi = 0; gi < NUM_PRIORITY; gi++) begin
	 ipbb_rrarb 
	  #(.N(NUM_QUE) ) rrarb
	   (.clk (clk)
	    ,.reset (rst)

	    // inputs
	    ,.req (req[gi])
	    ,.en (en)

	    // outputs
	    ,.gnt_id (rr_gnt_id[gi])
	    ,.gnt_id_vld (rr_gnt[gi])
	    ,.nxt_gnt_id (nxt_rr_gnt_id[gi])
	    ,.nxt_gnt_id_vld (nxt_rr_gnt[gi])

	    );
      end
   endgenerate

endmodule // ipbb_priority_rr

 
