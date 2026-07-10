//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


//---------------------------------------------------------------------------------------------
// Description: axi-2-axi width adjustment from larger number of segments to smaller number 
//              of segments
//  Supports valid configuration
//  - ENUM_SEG = 1;  INUM_SEG = 1, 2, 4, 8, 16
//
//  - Note: Number of bytes per segment must be the same for both ingress and egress
//          ENUM_SEG = 1 is currently supported
//----------------------------------------------------------------------------------------------

module packet_switch_axi_wdj_lg2sm
 #(parameter  IDATA_WIDTH            = 1024      // supports the following setting
                                                 // 64, 128, 256, 512 and 1024
             ,IKEEP_WIDTH            = IDATA_WIDTH/8
             ,IBYTESVLD_WIDTH        = $clog2(IKEEP_WIDTH)
             ,INUM_SEG               = 16        
             ,INUM_SEG_WIDTH         = $clog2(INUM_SEG)
             ,IDATA_SEG_WIDTH        = IDATA_WIDTH/INUM_SEG    // data width per segment
             ,IKEEP_SEG_WIDTH        = IKEEP_WIDTH/INUM_SEG
             ,IBYTESVLD_SEG_WIDTH    = $clog2(IKEEP_SEG_WIDTH)   
             ,IFIFO_DEPTH            = 512
             ,IFIFO_WIDTH            = $clog2(IFIFO_DEPTH)

             ,ENUM_SEG               = 1 
             ,EDATA_WIDTH            = ENUM_SEG * IDATA_SEG_WIDTH 
             ,EKEEP_WIDTH            = EDATA_WIDTH/8
             ,EBYTESVLD_WIDTH        = $clog2(EKEEP_WIDTH)
            
             ,ENUM_SEG_WIDTH         = $clog2(ENUM_SEG)
             ,EDATA_SEG_WIDTH        = EDATA_WIDTH/ENUM_SEG   // data width per segment
             ,EKEEP_SEG_WIDTH        = EKEEP_WIDTH/ENUM_SEG
             ,EBYTESVLD_SEG_WIDTH    = $clog2(EKEEP_SEG_WIDTH)  
             ,EFIFO_DEPTH            = 512
             ,EFIFO_WIDTH            = $clog2(EFIFO_DEPTH)
   
             ,ITUSER_MD_WIDTH         = 1
             ,ETUSER_MD_WIDTH         = 1   
             ,TID_WIDTH              = 3
 
             ,NUM_SOP                = 1    // only supports NUM_SOP=1
   )
   (
    input var logic                        clk
   ,input var logic                        rst       // active high sync to clk
   
   //------------------------------------------------------------------------------------------
   // Ingress axi-st interface
   ,output var logic                        trdy_o
   
   ,input var logic                         tvld_i
   ,input var logic [INUM_SEG -1:0]
                    [TID_WIDTH -1:0]        tid_i          // vld during sop of axi_st
   
   ,input var logic [INUM_SEG -1:0]
                    [IDATA_SEG_WIDTH -1:0]  tdata_i
   
   ,input var logic [INUM_SEG -1:0]
                    [IKEEP_SEG_WIDTH -1:0]  tkeep_i
   
   ,input var logic [ITUSER_MD_WIDTH -1:0]  tuser_md_i      // vld during sop of axi_st
   
   ,input var logic [INUM_SEG -1:0]         terr_i         // error indiction.
                                                           // note: in multi-segment mode this
                                                           // could result in two packets get
                                                           // merge together with error at the
                                                           // egress.
   ,input var logic                         tlast_i
   ,input var logic [INUM_SEG -1:0]         tlast_segment_i
  

   //------------------------------------------------------------------------------------------
   // Egress axi-st interface
   ,input var logic                          trdy_i
   
   ,output var logic                         tvld_o
   ,output var logic [ENUM_SEG -1:0]
                     [TID_WIDTH -1:0]        tid_o          // vld during sop of axi_st
   
   ,output var logic [ENUM_SEG -1:0]
                     [EDATA_SEG_WIDTH -1:0]  tdata_o
   
   ,output var logic [ENUM_SEG -1:0]
                     [EKEEP_SEG_WIDTH -1:0]  tkeep_o
   
   ,output var logic [ETUSER_MD_WIDTH -1:0]  tuser_md_o    // 
   
   ,output var logic [ENUM_SEG -1:0]         terr_o        // error indiction.
                                                           // note: in multi-segment mode this
                                                           // could result in two packets get
                                                           // merge together with error at the
                                                           // egress.
   ,output var logic                         tlast_o
   ,output var logic [ENUM_SEG -1:0]         tlast_segment_o

   //-----------------------------------------------------------------------------------------
   // CSR config register interface
   ,input var logic                          cfg_drop_en
   ,input var logic [15:0]                   cfg_drop_threshold
   ,output var logic                         dbg_cnt_drop_en
  
    );

   logic [31:0] rst_reg;
   // Generate arrays of reset to be used in submodule
   always_ff @(posedge clk) begin
      rst_reg <= '{default:rst};
   end

   localparam CYC_CNT = (INUM_SEG > ENUM_SEG) ? INUM_SEG/ENUM_SEG :
			                        ENUM_SEG/INUM_SEG  ;
   localparam CYC_CNT_WIDTH = $clog2(CYC_CNT);
   
   localparam IFIFO_FC_WM = IFIFO_DEPTH - 32;
   localparam EFIFO_FC_WM = EFIFO_DEPTH - 32;

   localparam CFG_THRESHOLD_PAD = 16 - IFIFO_WIDTH;

   localparam ETUSER_MD_PAD = ETUSER_MD_WIDTH - 4; // pad with zeroes except for egr_port (4b)
   
   logic ififo_push, ififo_pop, ififo_mty ,ififo_full, ififo_rdempty_lkahd, ififo_ov, 
	 ififo_ud,   efifo_rdy, ififo_tlast_r;

   logic [IFIFO_WIDTH -1:0] ififo_cnt;
   
   logic [INUM_SEG -1:0] [TID_WIDTH -1:0] ififo_tid_r;
   logic [15:0] [TID_WIDTH -1:0]  tid_r;
   
   logic [INUM_SEG -1:0] [IDATA_SEG_WIDTH -1:0] ififo_tdata_r;
   logic [15:0] [IDATA_SEG_WIDTH -1:0] tdata_r;
   
   logic [INUM_SEG -1:0][IKEEP_SEG_WIDTH -1:0] ififo_tkeep_r;
   logic [15:0][IKEEP_SEG_WIDTH -1:0] tkeep_r;
   logic [15:0]  seg_tkeep_r;
   
   logic [ITUSER_MD_WIDTH -1:0] ififo_tuser_md_r;
   logic [ITUSER_MD_WIDTH -1:0] tuser_md_r;

   logic [INUM_SEG -1:0]  ififo_tlast_segment_r, ififo_terr_r;
   logic [15:0] tlast_segment_r, terr_r;

   logic ifitlast_r, tlast_r;
		
   logic [CYC_CNT_WIDTH -1:0]  cyc_cnt, nxt_cyc_cnt;
   
   logic [15:0] mod_tlast_segment_r;

   //logic [4:0] 	inum_seg, enum_seg;
   
   logic [15:0] [EKEEP_SEG_WIDTH -1:0] mod_tkeep_r;
    
   logic [15:0] [EDATA_SEG_WIDTH -1:0] mod_tdata_r;

   logic [ITUSER_MD_WIDTH -1:0]  mod_tuser_md_r;

   logic [15:0] [TID_WIDTH -1:0]   mod_tid_r;

   logic [15:0] mod_terr_r;
   
   logic 	mod_tlast_r;
   
   logic efifo_tlast_w,  efifo_tlast_r, efifo_terr_r,
	 efifo_push, efifo_pop, efifo_mty, efifo_full, 
	 efifo_rdempty_lkahd, efifo_ov, efifo_ud ;
   logic [ENUM_SEG -1:0] efifo_tlast_segment_w, efifo_terr_w, efifo_tlast_segment_r;
   logic [ENUM_SEG -1:0] [TID_WIDTH -1:0] efifo_tid_w, efifo_tid_r;  
   // logic [ENUM_SEG -1:0] [ETUSER_MD_WIDTH -1:0] efifo_tuser_md_w, efifo_tuser_md_r;
   logic [ETUSER_MD_WIDTH -1:0] efifo_tuser_md_w, efifo_tuser_md_r;
   logic [ENUM_SEG -1:0] [EDATA_SEG_WIDTH -1:0] efifo_tdata_w, efifo_tdata_r;
   logic [ENUM_SEG -1:0] [EKEEP_SEG_WIDTH -1:0] efifo_tkeep_w, efifo_tkeep_r;
   
   logic [EFIFO_WIDTH -1:0] efifo_cnt;

   logic no_eop_drop_state, no_eop_drop_state_c1,
     igr_pkt_state, tlast_mod;
   logic [INUM_SEG -1:0]         tlast_segment_mod;
   logic [INUM_SEG -1:0]
                    [IKEEP_SEG_WIDTH -1:0]  tkeep_mod;

   logic [INUM_SEG -1:0]
                    [TID_WIDTH -1:0]        tid_c1;       
   
   logic [INUM_SEG -1:0]
                    [IDATA_SEG_WIDTH -1:0]  tdata_c1;
   
   logic [INUM_SEG -1:0]
                    [IKEEP_SEG_WIDTH -1:0]  tkeep_c1;
   
   logic [ITUSER_MD_WIDTH -1:0]  tuser_md_c1;    
   
   logic [INUM_SEG -1:0]         terr_c1;

   logic ififo_overthresh;  
   
   //------------------------------------------------------------------------------------------
   always_comb begin
      trdy_o =  rst ? '0 : 
                  cfg_drop_en ? '1 : ififo_cnt < IFIFO_FC_WM;
   end

   always_comb begin
      // push to ififo
      if (cfg_drop_en)
        ififo_push =  (ififo_overthresh
                      & !igr_pkt_state 
                      & tvld_i
                      & !no_eop_drop_state
                      & !tlast_i) ? '1 :
                            !no_eop_drop_state & (trdy_o & tvld_i);    
      else
        ififo_push = trdy_o & tvld_i;     
   end

   logic dbg_cnt_drop_en_w;

   // Debug counter enable
   always_comb begin 
    if (no_eop_drop_state & tvld_i & tlast_i) 
      dbg_cnt_drop_en_w = '1;
    else 
      dbg_cnt_drop_en_w = '0;
   end
   
   always_ff @(posedge clk) 
     dbg_cnt_drop_en <= dbg_cnt_drop_en_w;

   //------------------------------------------------------------------------------------------
   //------------------------------------------------------------------------------------------
   // drop mechanism

   // igr_pkt_state
   always_ff @(posedge clk) begin
     if (trdy_o & tvld_i & tlast_i)
       igr_pkt_state <= '1;
     else if (trdy_o & tvld_i)
       igr_pkt_state <= '0;
   
     if (rst)
       igr_pkt_state <= '0;
   end

   // ififo_overthresh
   always_ff @(posedge clk) begin
     if (cfg_drop_en & ({{CFG_THRESHOLD_PAD{1'b0}},ififo_cnt} > cfg_drop_threshold))
       ififo_overthresh <= '1;
     else
       ififo_overthresh <= '0;
 
     if (rst)
       ififo_overthresh <= '0;
   end
   
   // no_eop_drop_state
   always_ff @(posedge clk) begin
     if (ififo_overthresh
         & !igr_pkt_state 
         & !no_eop_drop_state
         & tvld_i
         & !tlast_i)
       no_eop_drop_state <= '1;
     else if (!ififo_overthresh 
               & igr_pkt_state) // under threshold + received eop
       no_eop_drop_state <= '0;
   
     no_eop_drop_state_c1 <= no_eop_drop_state;
     
     if (rst)
       no_eop_drop_state <= '0;
   end

   generate
     if (INUM_SEG == 1) begin : tlast_seg_1

     always_comb begin
       tlast_mod = (ififo_overthresh
                      & !igr_pkt_state 
                      & tvld_i
                      & !no_eop_drop_state
                      & !tlast_i) ? '1 : tlast_i;
       // tkeep_mod = no_eop_drop_state_posedge ? '1 : tkeep_i;
       tlast_segment_mod = (ififo_overthresh
                      & !igr_pkt_state 
                      & tvld_i
                      & !no_eop_drop_state
                      & !tlast_i) ? '1 : tlast_segment_i;
     end
    
     end else begin : tlast_seg_not_1

     always_comb begin
       tlast_mod = (ififo_overthresh
                      & !igr_pkt_state 
                      & tvld_i
                      & !no_eop_drop_state
                      & !tlast_i) ? '1 : tlast_i;
       // tkeep_mod = no_eop_drop_state_posedge ? '1 : tkeep_i;
       tlast_segment_mod[INUM_SEG-2:0] = (ififo_overthresh
                      & !igr_pkt_state 
                      & tvld_i
                      & !no_eop_drop_state
                      & !tlast_i) ? '0 : 
                                           tlast_segment_i[INUM_SEG-2:0];
       tlast_segment_mod[INUM_SEG-1] = (ififo_overthresh
                      & !igr_pkt_state 
                      & tvld_i
                      & !no_eop_drop_state
                      & !tlast_i) ? '1 : 
                                           tlast_segment_i[INUM_SEG-1];
     end

     end
   endgenerate

   //------------------------------------------------------------------------------------------

   always_comb begin
      for (int i = 0; i < 16; i++) begin
	 seg_tkeep_r[i] = |tkeep_r[i];	 
      end

      /*
      if (!ififo_mty & efifo_rdy & !seg_tkeep_r[cyc_cnt])
	nxt_cyc_cnt = '0;    
      else if (!ififo_mty & efifo_rdy & seg_tkeep_r[cyc_cnt])
	nxt_cyc_cnt = cyc_cnt + 1'b1;     
      else
	nxt_cyc_cnt = cyc_cnt;*/

     if (!ififo_mty & efifo_rdy)
	nxt_cyc_cnt = cyc_cnt + 1'b1;     
      else
	nxt_cyc_cnt = cyc_cnt;
   end

   always_ff @(posedge clk) begin
      if (INUM_SEG == 1)
	cyc_cnt <= '0;
      else
	cyc_cnt <= nxt_cyc_cnt;
      
      if (rst_reg[0])
	cyc_cnt <= '0;
   end

   always_ff @(posedge clk) begin
      efifo_rdy <= efifo_cnt < EFIFO_FC_WM;
   end
 
   always_comb begin      
      if (INUM_SEG == 1) begin
        ififo_pop = 
         // (!ififo_mty & !seg_tkeep_r[cyc_cnt] & efifo_rdy)
         |(!ififo_mty & efifo_rdy);
      end else begin
        ififo_pop = 
           (!ififo_mty & efifo_rdy & (cyc_cnt == '1));
      end
   end

   generate
      if (INUM_SEG == 1) begin
	 always_comb begin     	    
	    mod_tlast_r         = tlast_r;
	    mod_tuser_md_r      = tuser_md_r;

	    mod_tlast_segment_r[0]    = tlast_segment_r[0];
	    mod_tkeep_r[0]            = tkeep_r[0];
	    mod_tdata_r[0]            = tdata_r[0];
	    // mod_tuser_md_r[0]         = tuser_md_r[0];
	    mod_tid_r[0]              = tid_r[0];
	    mod_terr_r[0]             = terr_r[0];
	    
	    mod_tlast_segment_r[15:1] = '0;
	    mod_tkeep_r[15:1]         = '0;
	    mod_tdata_r[15:1]         = '0;
	    // mod_tuser_md_r[15:1]      = '0;
	    mod_tid_r[15:1]           = '0;
	    mod_terr_r[15:1]          = '0;
	 end // always_comb
      end // if (INUM_SEG == 1)

      else if (INUM_SEG == 2) begin
	 always_comb begin     	    
	    mod_tlast_r         = tlast_r & tlast_segment_r[cyc_cnt];
	    mod_tuser_md_r      = tuser_md_r;

	    case (cyc_cnt)
	      'd0: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[0];
		 mod_tkeep_r[0]         = tkeep_r[0];
		 mod_tdata_r[0]         = tdata_r[0];
		 // mod_tuser_md_r[0]      = tuser_md_r[0];
		 mod_tid_r[0]           = tid_r[0];
		 mod_terr_r[0]          = terr_r[0];
	      end
	      default: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[1];
		 mod_tkeep_r[0]         = tkeep_r[1];
		 mod_tdata_r[0]         = tdata_r[1];
		 // mod_tuser_md_r[0]      = tuser_md_r[1];
		 mod_tid_r[0]           = tid_r[1];
		 mod_terr_r[0]          = terr_r[1];
	      end
	    endcase // case (cyc_cnt)
	    	    
	    mod_tlast_segment_r[15:1] = '0;
	    mod_tkeep_r[15:1]         = '0;
	    mod_tdata_r[15:1]         = '0;
	    // mod_tuser_md_r[15:1]      = '0;
	    mod_tid_r[15:1]           = '0;
	    mod_terr_r[15:1]          = '0;
	 end // always_comb
      end // if (INUM_SEG == 2)
      
      else if (INUM_SEG == 4) begin
	 always_comb begin
	    mod_tlast_r         = tlast_r & tlast_segment_r[cyc_cnt];
	    mod_tuser_md_r      = tuser_md_r;

	    case (cyc_cnt)
	      'd0: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[0];
		 mod_tkeep_r[0]         = tkeep_r[0];
		 mod_tdata_r[0]         = tdata_r[0];
		 // mod_tuser_md_r[0]      = tuser_md_r[0];
		 mod_tid_r[0]           = tid_r[0];
		 mod_terr_r[0]          = terr_r[0];
	      end
	      'd1: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[1];
		 mod_tkeep_r[0]         = tkeep_r[1];
		 mod_tdata_r[0]         = tdata_r[1];
		 // mod_tuser_md_r[0]      = tuser_md_r[1];
		 mod_tid_r[0]           = tid_r[1];
		 mod_terr_r[0]          = terr_r[1];
	      end
	      'd2: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[2];
		 mod_tkeep_r[0]         = tkeep_r[2];
		 mod_tdata_r[0]         = tdata_r[2];
		 // mod_tuser_md_r[0]      = tuser_md_r[2];
		 mod_tid_r[0]           = tid_r[2];
		 mod_terr_r[0]          = terr_r[2];
	      end
	      default: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[3];
		 mod_tkeep_r[0]         = tkeep_r[3];
		 mod_tdata_r[0]         = tdata_r[3];
		 // mod_tuser_md_r[0]      = tuser_md_r[3];
		 mod_tid_r[0]           = tid_r[3];
		 mod_terr_r[0]          = terr_r[3];
	      end
	    endcase // case (cyc_cnt)

	    mod_tlast_segment_r[15:1] = '0;
	    mod_tkeep_r[15:1]         = '0;
	    mod_tdata_r[15:1]         = '0;
	    // mod_tuser_md_r[15:1]      = '0;
	    mod_tid_r[15:1]           = '0;
	    mod_terr_r[15:1]          = '0;
	 end 
      end // if (INUM_SEG == 4)

      else if (INUM_SEG == 8) begin
	 always_comb begin
	    mod_tlast_r         = tlast_r & tlast_segment_r[cyc_cnt];
	    mod_tuser_md_r      = tuser_md_r;

	    case (cyc_cnt)
	      'd0: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[0];
		 mod_tkeep_r[0]         = tkeep_r[0];
		 mod_tdata_r[0]         = tdata_r[0];
		 // mod_tuser_md_r[0]      = tuser_md_r[0];
		 mod_tid_r[0]           = tid_r[0];
		 mod_terr_r[0]          = terr_r[0];
	      end
	      'd1: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[1];
		 mod_tkeep_r[0]         = tkeep_r[1];
		 mod_tdata_r[0]         = tdata_r[1];
		 // mod_tuser_md_r[0]      = tuser_md_r[1];
		 mod_tid_r[0]           = tid_r[1];
		 mod_terr_r[0]          = terr_r[1];
	      end
	      'd2: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[2];
		 mod_tkeep_r[0]         = tkeep_r[2];
		 mod_tdata_r[0]         = tdata_r[2];
		 // mod_tuser_md_r[0]      = tuser_md_r[2];
		 mod_tid_r[0]           = tid_r[2];
		 mod_terr_r[0]          = terr_r[2];
	      end
	      'd3: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[3];
		 mod_tkeep_r[0]         = tkeep_r[3];
		 mod_tdata_r[0]         = tdata_r[3];
		 // mod_tuser_md_r[0]      = tuser_md_r[3];
		 mod_tid_r[0]           = tid_r[3];
		 mod_terr_r[0]          = terr_r[3];
	      end
	      'd4: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[4];
		 mod_tkeep_r[0]         = tkeep_r[4];
		 mod_tdata_r[0]         = tdata_r[4];
		 // mod_tuser_md_r[0]      = tuser_md_r[4];
		 mod_tid_r[0]           = tid_r[4];
		 mod_terr_r[0]          = terr_r[4];
	      end
	      'd5: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[5];
		 mod_tkeep_r[0]         = tkeep_r[5];
		 mod_tdata_r[0]         = tdata_r[5];
		 // mod_tuser_md_r[0]      = tuser_md_r[5];
		 mod_tid_r[0]           = tid_r[5];
		 mod_terr_r[0]          = terr_r[5];
	      end
	      'd6: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[6];
		 mod_tkeep_r[0]         = tkeep_r[6];
		 mod_tdata_r[0]         = tdata_r[6];
		 // mod_tuser_md_r[0]      = tuser_md_r[6];
		 mod_tid_r[0]           = tid_r[6];
		 mod_terr_r[0]          = terr_r[6];
	      end
	      default: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[7];
		 mod_tkeep_r[0]         = tkeep_r[7];
		 mod_tdata_r[0]         = tdata_r[7];
		 // mod_tuser_md_r[0]      = tuser_md_r[7];
		 mod_tid_r[0]           = tid_r[7];
		 mod_terr_r[0]           = terr_r[7];
	      end
	    endcase // case (cyc_cnt)

	    mod_tlast_segment_r[15:1] = '0;
	    mod_tkeep_r[15:1]         = '0;
	    mod_tdata_r[15:1]         = '0;
	    // mod_tuser_md_r[15:1]      = '0;
	    mod_tid_r[15:1]           = '0;
	    mod_terr_r[15:1]          = '0;
	 end // always_comb	 
      end // if (INUM_SEG == 8)

      else begin
	 always_comb begin
	    mod_tlast_r  = tlast_r & tlast_segment_r[cyc_cnt];
	    mod_tuser_md_r      = tuser_md_r;
	    
	    case (cyc_cnt)
	      'd0: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[0];
		 mod_tkeep_r[0]         = tkeep_r[0];
		 mod_tdata_r[0]         = tdata_r[0];
		 // mod_tuser_md_r[0]      = tuser_md_r[0];
		 mod_tid_r[0]           = tid_r[0];
		 mod_terr_r[0]          = terr_r[0];
	      end
	      'd1: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[1];
		 mod_tkeep_r[0]         = tkeep_r[1];
		 mod_tdata_r[0]         = tdata_r[1];
		 // mod_tuser_md_r[0]      = tuser_md_r[1];
		 mod_tid_r[0]           = tid_r[1];
		 mod_terr_r[0]          = terr_r[1];
	      end
	      'd2: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[2];
		 mod_tkeep_r[0]         = tkeep_r[2];
		 mod_tdata_r[0]         = tdata_r[2];
		 // mod_tuser_md_r[0]      = tuser_md_r[2];
		 mod_tid_r[0]           = tid_r[2];
		 mod_terr_r[0]          = terr_r[2];
	      end
	      'd3: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[3];
		 mod_tkeep_r[0]         = tkeep_r[3];
		 mod_tdata_r[0]         = tdata_r[3];
		 // mod_tuser_md_r[0]      = tuser_md_r[3];
		 mod_tid_r[0]           = tid_r[3];
		 mod_terr_r[0]          = terr_r[3];
	      end
	      'd4: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[4];
		 mod_tkeep_r[0]         = tkeep_r[4];
		 mod_tdata_r[0]         = tdata_r[4];
		 // mod_tuser_md_r[0]      = tuser_md_r[4];
		 mod_tid_r[0]           = tid_r[4];
		 mod_terr_r[0]          = terr_r[4];
	      end
	      'd5: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[5];
		 mod_tkeep_r[0]         = tkeep_r[5];
		 mod_tdata_r[0]         = tdata_r[5];
		 // mod_tuser_md_r[0]      = tuser_md_r[5];
		 mod_tid_r[0]           = tid_r[5];
		 mod_terr_r[0]          = terr_r[5];
	      end
	      'd6: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[6];
		 mod_tkeep_r[0]         = tkeep_r[6];
		 mod_tdata_r[0]         = tdata_r[6];
		 // mod_tuser_md_r[0]      = tuser_md_r[6];
		 mod_tid_r[0]           = tid_r[6];
		 mod_terr_r[0]          = terr_r[6];
	      end
	      'd7: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[7];
		 mod_tkeep_r[0]         = tkeep_r[7];
		 mod_tdata_r[0]         = tdata_r[7];
		 // mod_tuser_md_r[0]      = tuser_md_r[7];
		 mod_tid_r[0]           = tid_r[7];
		 mod_terr_r[0]          = terr_r[7];
	      end
	      'd8: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[8];
		 mod_tkeep_r[0]         = tkeep_r[8];
		 mod_tdata_r[0]         = tdata_r[8];
		 // mod_tuser_md_r[0]      = tuser_md_r[8];
		 mod_tid_r[0]           = tid_r[8];
		 mod_terr_r[0]          = terr_r[8];
	      end
	      'd9: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[9];
		 mod_tkeep_r[0]         = tkeep_r[9];
		 mod_tdata_r[0]         = tdata_r[9];
		 // mod_tuser_md_r[0]      = tuser_md_r[9];
		 mod_tid_r[0]           = tid_r[9];
		 mod_terr_r[0]          = terr_r[9];
	      end
	      'd10: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[10];
		 mod_tkeep_r[0]         = tkeep_r[10];
		 mod_tdata_r[0]         = tdata_r[10];
		 // mod_tuser_md_r[0]      = tuser_md_r[10];
		 mod_tid_r[0]           = tid_r[10];
		 mod_terr_r[0]          = terr_r[10];
	      end
	      'd11: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[11];
		 mod_tkeep_r[0]         = tkeep_r[11];
		 mod_tdata_r[0]         = tdata_r[11];
		 // mod_tuser_md_r[0]      = tuser_md_r[11];
		 mod_tid_r[0]           = tid_r[11];
		 mod_terr_r[0]          = terr_r[11];
	      end
	      'd12: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[12];
		 mod_tkeep_r[0]         = tkeep_r[12];
		 mod_tdata_r[0]         = tdata_r[12];
		 // mod_tuser_md_r[0]      = tuser_md_r[12];
		 mod_tid_r[0]           = tid_r[12];
		 mod_terr_r[0]          = terr_r[12];
	      end
	      'd13: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[13];
		 mod_tkeep_r[0]         = tkeep_r[13];
		 mod_tdata_r[0]         = tdata_r[13];
		 // mod_tuser_md_r[0]      = tuser_md_r[13];
		 mod_tid_r[0]           = tid_r[13];
		 mod_terr_r[0]          = terr_r[13];
	      end
	      'd14: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[14];
		 mod_tkeep_r[0]         = tkeep_r[14];
		 mod_tdata_r[0]         = tdata_r[14];
		 // mod_tuser_md_r[0]      = tuser_md_r[14];
		 mod_tid_r[0]           = tid_r[14];
		 mod_terr_r[0]          = terr_r[14];
	      end
	      default: begin
		 mod_tlast_segment_r[0] = tlast_segment_r[15];
		 mod_tkeep_r[0]         = tkeep_r[15];
		 mod_tdata_r[0]         = tdata_r[15];
		 // mod_tuser_md_r[0]      = tuser_md_r[15];
		 mod_tid_r[0]           = tid_r[15];
		 mod_terr_r[0]          = terr_r[15];
	      end
	    endcase // case (cyc_cnt)	    
	    mod_tlast_segment_r[15:1] = '0;
	    mod_tkeep_r[15:1]         = '0;
	    mod_tdata_r[15:1]         = '0;
	    // mod_tuser_md_r[15:1]      = '0;
	    mod_tid_r[15:1]           = '0;
	    mod_terr_r[15:1]          = '0;
	 end

      end // else: !if(INUM_SEG == 8)
   endgenerate

   logic sop_state;
   always_ff @ (posedge clk) begin
     // if (efifo_push & !efifo_tlast_w & sop_state) 
     if (!ififo_mty & seg_tkeep_r[cyc_cnt] & efifo_rdy & !mod_tlast_r & sop_state) 
       sop_state <= '0;
     else if (!ififo_mty & seg_tkeep_r[cyc_cnt] & efifo_rdy & mod_tlast_r)
       sop_state <= '1;

     if (rst_reg[0])
       sop_state <= '1;
   end   
   
   always_ff @(posedge clk) begin
      if (INUM_SEG == 1)
	efifo_push <= ififo_pop;
      else
	efifo_push <= (!ififo_mty & seg_tkeep_r[cyc_cnt] & efifo_rdy);
      
      efifo_tdata_w         <= mod_tdata_r[0];
      efifo_tkeep_w         <= mod_tkeep_r[0];
      efifo_tlast_segment_w <= mod_tlast_segment_r[0];
      efifo_tid_w           <= mod_tid_r[0];

      if (!ififo_mty & efifo_rdy & sop_state) // sop
        efifo_tuser_md_w      <= mod_tuser_md_r[ETUSER_MD_WIDTH-1:0]; // segment_0
      else if (!ififo_mty & efifo_rdy & mod_tlast_r) // eop
	    efifo_tuser_md_w <= {mod_tuser_md_r[ITUSER_MD_WIDTH-1:ETUSER_MD_WIDTH], 
                      mod_tuser_md_r[packet_switch_pkg::SEGMENT_INFO_WIDTH-1:0]}; // segment_1
      else // mop
        efifo_tuser_md_w <= {{ETUSER_MD_PAD{1'b0}}, mod_tuser_md_r[3:0]}; 

      efifo_tlast_w         <= mod_tlast_r;
      efifo_terr_w          <= mod_terr_r[0];	 	 
   end // always_ff @ (posedge clk)
   
   //------------------------------------------------------------------------------------------
   // egress interface

   always_comb begin
      efifo_pop = trdy_i & !efifo_mty;

      
      tvld_o          = !efifo_mty;
      //tvld_o          = trdy_i & !efifo_mty;
      tid_o           = efifo_tid_r;
      tdata_o         = efifo_tdata_r;
      tkeep_o         = efifo_tkeep_r;
      tuser_md_o      = efifo_tuser_md_r;
      terr_o          = efifo_terr_r;
      tlast_o         = efifo_tlast_r ;
      tlast_segment_o = efifo_tlast_segment_r;     

      // send metadata at sop or when eop
      //if (efifo_pop & tlast_o)
	  //  tuser_md_o = {efifo_tuser_md_r[ITUSER_MD_WIDTH-1:ETUSER_MD_WIDTH], 
      //                18'h0, 
      //                efifo_tuser_md_r[3:0]}; // segment_1
      //else if (sop_state)
	  //  tuser_md_o = efifo_tuser_md_r[ETUSER_MD_WIDTH-1:0]; // segment_0
      //else
	  //  tuser_md_o = {{ETUSER_MD_PAD{1'b0}}, efifo_tuser_md_r[3:0]}; 

   end

   
   //------------------------------------------------------------------------------------------
   // ingress fifo
   ipbb_scfifo_inff #(  .DWD ( (INUM_SEG*IDATA_SEG_WIDTH)   // tdata_i
			      +(INUM_SEG*TID_WIDTH)         // tid_i
			      +(INUM_SEG*IKEEP_SEG_WIDTH)   // tkeep_i
			      +INUM_SEG                     // tlast_segment_i
			      +1                            // tlast_i
			      +(ITUSER_MD_WIDTH)   // tuser_md_i
			      +INUM_SEG )                   // terr_i
		       ,.NUM_WORDS (IFIFO_DEPTH) ) ififo
     (
      .clk (clk)
      ,.rst (rst_reg[0])

      // inputs
      ,.din ({ tdata_i
	      ,tid_i
	      ,tkeep_i
	      ,tlast_segment_mod
	      ,tlast_mod
	      ,tuser_md_i
	      ,terr_i})
      ,.wrreq (ififo_push)
      ,.rdreq (ififo_pop)

      // outputs
      ,.dout ({ ififo_tdata_r
	       ,ififo_tid_r
	       ,ififo_tkeep_r
	       ,ififo_tlast_segment_r
	       ,ififo_tlast_r
	       ,ififo_tuser_md_r
	       ,ififo_terr_r})
      ,.rdempty (ififo_mty)
      ,.wrfull (ififo_full)
      ,.wrusedw (ififo_cnt)
      ,.rdempty_lkahd (ififo_rdempty_lkahd)
      ,.overflow (ififo_ov)
      ,.underflow (ififo_ud)
      );

   generate
      if (INUM_SEG == 1) begin
	 always_comb begin
	    tdata_r[0]         = ififo_tdata_r;
	    tid_r[0]           = ififo_tid_r;
	    tkeep_r[0]         = ififo_tkeep_r;
	    tlast_segment_r[0] = ififo_tlast_segment_r;
	    tuser_md_r         = ififo_tuser_md_r;
	    terr_r[0]          = ififo_terr_r;
	    tlast_r            = ififo_tlast_r;
	    
	    tdata_r[15:1]         = '0;
	    tid_r[15:1]           = '0;
	    tkeep_r[15:1]         = '0;
	    tlast_segment_r[15:1] = '0;
	    // tuser_md_r[15:1]      = '0;
	    terr_r[15:1]          = '0;	    
	 end
      end // if (INUM_SEG == 1)

      else if (INUM_SEG == 2) begin
	 always_comb begin
	    tdata_r[1:0]         = ififo_tdata_r;
	    tid_r[1:0]           = ififo_tid_r;
	    tkeep_r[1:0]         = ififo_tkeep_r;
	    tlast_segment_r[1:0] = ififo_tlast_segment_r;
	    tuser_md_r           = ififo_tuser_md_r;
	    terr_r[1:0]          = ififo_terr_r;
	    tlast_r              = ififo_tlast_r;
	    
	    tdata_r[15:2]         = '0;
	    tid_r[15:2]           = '0;
	    tkeep_r[15:2]         = '0;
	    tlast_segment_r[15:2] = '0;
	    // tuser_md_r[15:2]      = '0;
	    terr_r[15:2]          = '0;	    
	 end
      end // if (INUM_SEG == 1)
      
      else if (INUM_SEG == 4) begin
	 always_comb begin
	    tdata_r[3:0]         = ififo_tdata_r;
	    tid_r[3:0]           = ififo_tid_r;
	    tkeep_r[3:0]         = ififo_tkeep_r;
	    tlast_segment_r[3:0] = ififo_tlast_segment_r;
	    tuser_md_r           = ififo_tuser_md_r;
	    terr_r[3:0]          = ififo_terr_r;
	    tlast_r              = ififo_tlast_r;
	    
	    tdata_r[15:4]         = '0;
	    tid_r[15:4]           = '0;
	    tkeep_r[15:4]         = '0;
	    tlast_segment_r[15:4] = '0;
	    // tuser_md_r[15:4]      = '0;
	    terr_r[15:4]          = '0;	    
	 end
      end // if (INUM_SEG == 4)

      else if (INUM_SEG == 8) begin
	 always_comb begin
	    tdata_r[7:0]         = ififo_tdata_r;
	    tid_r[7:0]           = ififo_tid_r;
	    tkeep_r[7:0]         = ififo_tkeep_r;
	    tlast_segment_r[7:0] = ififo_tlast_segment_r;
	    tuser_md_r           = ififo_tuser_md_r;
	    terr_r[7:0]          = ififo_terr_r;
	    tlast_r              = ififo_tlast_r;
	    
	    tdata_r[15:8]         = '0;
	    tid_r[15:8]           = '0;
	    tkeep_r[15:8]         = '0;
	    tlast_segment_r[15:8] = '0;
	    // tuser_md_r[15:8]      = '0;
	    terr_r[15:8]          = '0;	    
	 end
      end // if (INUM_SEG == 8)
      
      else  begin
	 always_comb begin
	    tdata_r[15:0]         = ififo_tdata_r;
	    tid_r[15:0]           = ififo_tid_r;
	    tkeep_r[15:0]         = ififo_tkeep_r;
	    tlast_segment_r[15:0] = ififo_tlast_segment_r;
	    tuser_md_r            = ififo_tuser_md_r;
	    terr_r[15:0]          = ififo_terr_r;
	    tlast_r               = ififo_tlast_r;
	 end
      end // else: !if(INUM_SEG == 8)
   endgenerate
   
   
   //------------------------------------------------------------------------------------------
   // egress fifo
   ipbb_scfifo_inff #(  .DWD ( (ENUM_SEG*EDATA_SEG_WIDTH)
			      +(ENUM_SEG*TID_WIDTH)
			      +(ENUM_SEG*EKEEP_SEG_WIDTH)
			      +ENUM_SEG
			      +1
			      +(ETUSER_MD_WIDTH)
			      +ENUM_SEG )
		       ,.NUM_WORDS (EFIFO_DEPTH) ) efifo
     (
      .clk (clk)
      ,.rst (rst_reg[1])

      // inputs
      ,.din ({ efifo_tdata_w
	      ,efifo_tid_w
	      ,efifo_tkeep_w
	      ,efifo_tlast_segment_w
	      ,efifo_tlast_w
	      ,efifo_tuser_md_w
	      ,efifo_terr_w})
      ,.wrreq (efifo_push)
      ,.rdreq (efifo_pop)

      // outputs
      ,.dout ({efifo_tdata_r
	      ,efifo_tid_r
	      ,efifo_tkeep_r
	      ,efifo_tlast_segment_r
	      ,efifo_tlast_r
	      ,efifo_tuser_md_r
	      ,efifo_terr_r})
      ,.rdempty (efifo_mty)
      ,.wrfull (efifo_full)
      ,.wrusedw (efifo_cnt)
      ,.rdempty_lkahd (efifo_rdempty_lkahd)
      ,.overflow (efifo_ov)
      ,.underflow (efifo_ud)
      );



endmodule // ipbb_axi_wdj_lg2sm

    

    

				       
