//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


//---------------------------------------------------------------------------------------------
// Description: axi-2-axi width adjustment from smaller number of segments to larger number 
//              of segments
//
//  - Note: Number of bytes per segment must be the same for both ingress and egress
//----------------------------------------------------------------------------------------------
import packet_switch_pkg::*;

module packet_switch_rx_igr_wadj
 #(parameter  IDATA_WIDTH            = 64      
             ,IKEEP_WIDTH            = IDATA_WIDTH/8
             ,IBYTESVLD_WIDTH        = $clog2(IKEEP_WIDTH)
             ,INUM_SEG               = 1        
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
             ,TID_WIDTH               = 3
 
             ,NUM_SOP                = 1    // only supports NUM_SOP=1
             ,SOP_ALIGN              = 1    // enable sop align during multi-segment mode
			 
			 ,BASE_ADDR              = 'h0
             ,MAX_ADDR               = 'h8
             ,ADDR_WIDTH             = 8
             ,DATA_WIDTH             = 32
	         ,BYTE_ROTATE            = 0    
	         ,EGR_FIFO_EN            = 0 // enable egress FIFO

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
   
   ,input var logic  [INUM_SEG -1:0]        terr_i         // error indiction.
                                                           // note: in multi-segment mode this
                                                           // could result in two packets get
                                                           // merge together with error at the
                                                           // egress.
   ,input var logic                         tlast_i
   ,input var logic [INUM_SEG -1:0]         tlast_segment_i
  

   //------------------------------------------------------------------------------------------
   // Egress axi-st interface
   ,input var logic                          trdy_i
   
   ,output var logic                          tvld_o
   ,output var logic [ENUM_SEG -1:0]
                     [TID_WIDTH -1:0]         tid_o          // vld during sop of axi_st
   
   ,output var logic [ENUM_SEG -1:0]
                     [EDATA_SEG_WIDTH -1:0]   tdata_o
   
   ,output var logic [ENUM_SEG -1:0]
                     [EKEEP_SEG_WIDTH -1:0]   tkeep_o
   
   ,output var logic [ETUSER_MD_WIDTH -1:0]   tuser_md_o      // vld during sop and eop of axi_st
   
   ,output var logic [ENUM_SEG -1:0]          terr_o        // error indiction.
                                                           // note: in multi-segment mode this
                                                           // could result in two packets get
														   // merge together with error at the
														   // egress.
   ,output var logic                          tlast_o
   ,output var logic [ENUM_SEG -1:0]          tlast_segment_o
   ,output var packet_switch_pkg::SEGMENT_INFO_S tuser_segment_info_o
   
   ,output var logic                          rx_pause_o 

   //-----------------------------------------------------------------------------------------
   // Debug drop state
   ,output var logic                          dbg_cnt_drop_en
   
  //-----------------------------------------------------------------------------------------
    // AVMM interface

    ,input var logic [ADDR_WIDTH-1:0]     avmm_address
    ,input var logic                      avmm_read
    ,output var logic [DATA_WIDTH-1:0]    avmm_readdata 
    ,input var logic                      avmm_write
    ,input var logic [DATA_WIDTH-1:0]     avmm_writedata
    ,input var logic [(DATA_WIDTH/8)-1:0] avmm_byteenable
    ,output var logic                     avmm_readdata_valid
    );

   logic [31:0] rst_reg;
   // Generate arrays of reset to be used in submodule
   always_ff @(posedge clk) begin
      rst_reg <= '{default:rst};
   end
   

   localparam CYC_CNT = (INUM_SEG > ENUM_SEG) ? INUM_SEG/ENUM_SEG :
			                        ENUM_SEG/INUM_SEG  ;
   localparam CYC_CNT_WIDTH = $clog2(CYC_CNT);
  	
   localparam HDR_CYCLE_CNT = 2;
   localparam PAYLD_CYCLE_CNT = CYC_CNT - HDR_CYCLE_CNT;
   
   localparam CFG_THRESHOLD_PAD = 16 - IFIFO_WIDTH;
      
   logic ififo_push, ififo_pop, ififo_mty ,ififo_full, ififo_rdempty_lkahd, ififo_ov, 
	 ififo_ud,  tlast_r, efifo_rdy, ififo_tlast, ififo_data_vld;

   logic [IFIFO_WIDTH -1:0] ififo_cnt;

   logic [INUM_SEG -1:0] [TID_WIDTH -1:0] ififo_tid_r;
   logic [15:0] [TID_WIDTH -1:0]  tid_r;
   
   logic [INUM_SEG -1:0] [IDATA_SEG_WIDTH -1:0] ififo_tdata_r;
   logic [15:0] [IDATA_SEG_WIDTH -1:0] tdata_r;
   
   logic [INUM_SEG -1:0][IKEEP_SEG_WIDTH -1:0] ififo_tkeep_r;
   logic [15:0][IKEEP_SEG_WIDTH -1:0] tkeep_r;
   
   logic [ITUSER_MD_WIDTH -1:0] ififo_tuser_md_r;
   logic [ITUSER_MD_WIDTH -1:0] tuser_md_r;

   logic [INUM_SEG -1:0]  ififo_tlast_segment_r, ififo_terr_r;
   logic [15:0] tlast_segment_r, terr_r;
   
   logic [CYC_CNT_WIDTH -1:0]  cyc_cnt, nxt_cyc_cnt, ififo_cyc_cnt;
   

   //logic [4:0] inum_seg, enum_seg;

   logic [15:0] ififo_tlast_segment, ififo_terr;
   
   logic [15:0] [IKEEP_SEG_WIDTH -1:0] ififo_tkeep;
   
   logic [15:0] [IDATA_SEG_WIDTH -1:0] ififo_tdata;

   logic [1:0] [ITUSER_MD_WIDTH -1:0] ififo_tuser_md;
   
   logic [15:0] [TID_WIDTH -1:0]       ififo_tid;
   
   logic efifo_tlast_w, efifo_tlast_r, 
	 efifo_push, efifo_pop, efifo_mty, efifo_full, 
	 efifo_rdempty_lkahd, efifo_ov, efifo_ud ;
   
   logic [EFIFO_WIDTH -1:0] efifo_cnt;
   
   logic [ENUM_SEG -1:0] [TID_WIDTH -1:0] efifo_tid_w, efifo_tid_r;   
   logic [ETUSER_MD_WIDTH -1:0] efifo_tuser_md_w, efifo_tuser_md_r;
   logic [ENUM_SEG -1:0] [EDATA_SEG_WIDTH -1:0] efifo_tdata_w, efifo_tdata_r;
   logic [ENUM_SEG -1:0] [EKEEP_SEG_WIDTH -1:0] efifo_tkeep_w, efifo_tkeep_r;
   logic [ENUM_SEG -1:0] efifo_terr_w, efifo_terr_r,
			 efifo_tlast_segment_w, efifo_tlast_segment_r;

   logic                         tlast_mod;
   logic [INUM_SEG -1:0]         tlast_segment_mod;
   logic [INUM_SEG -1:0]
                    [IKEEP_SEG_WIDTH -1:0]  tkeep_mod;
   
   localparam IFIFO_FC_WM = IFIFO_DEPTH - 32;
   localparam EFIFO_FC_WM = EFIFO_DEPTH - 32;


   logic [ETUSER_MD_WIDTH -1:0] efifo_tuser_md_w_0, efifo_tuser_md_r_0;
  
   logic pkt_state;
   logic hdr_seg, payld_seg;
   logic [$clog2(PAYLD_CYCLE_CNT):0] hdr_seg_cnt;
   logic [1:0] payld_seg_cnt;

   logic cfg_rx_pause_en, no_eop_drop_state, no_eop_drop_state_c1,
     no_eop_drop_state_posedge, igr_pkt_state, ififo_rdy;
   logic [15:0] cfg_rx_pause_threshold;
   logic [15:0] cfg_drop_threshold;

  always_comb begin
      efifo_tuser_md_w_0 = efifo_tuser_md_w[0];
      efifo_tuser_md_r_0 = efifo_tuser_md_r[0];
      
   end
   
   //------------------------------------------------------------------------------------------
   
   // igr_pkt_state
   always_ff @(posedge clk) begin
     if (trdy_o & tvld_i & tlast_i)
       igr_pkt_state <= '1;
     else if (trdy_o & tvld_i)
       igr_pkt_state <= '0;

     if (rst)
       igr_pkt_state <= '0;
   end
   
   logic over_dropthresh;
   always_ff @(posedge clk) begin
     over_dropthresh <= ({{CFG_THRESHOLD_PAD{1'b0}},ififo_cnt} > cfg_drop_threshold);
   end

   // no_eop_drop_state
   always_ff @(posedge clk) begin
     if (cfg_rx_pause_en & over_dropthresh & !no_eop_drop_state & tvld_i & !tlast_i) // sop or mop
       no_eop_drop_state <= '1;
     else if (!over_dropthresh 
               & tvld_i
               & tlast_i) // under threshold + received eop
       no_eop_drop_state <= '0;

     no_eop_drop_state_c1 <= no_eop_drop_state;
     
     if (rst)
       no_eop_drop_state <= '0;
   end

   always_comb begin
     no_eop_drop_state_posedge = !no_eop_drop_state_c1 & no_eop_drop_state;
   end

   logic dbg_cnt_drop_en_w1, dbg_cnt_drop_en_w2;

   // Debug counter enable
   //always_comb begin 
   // // if (no_eop_drop_state & tvld_i & tlast_i)
   // if ((ififo_push & no_eop_drop_state_posedge) |
   //     (!ififo_push & tvld_i & tlast_i))
   //   dbg_cnt_drop_en_w = '1;
   // else 
   //   dbg_cnt_drop_en_w = '0;
   //end
   
   always_ff @(posedge clk) begin
     dbg_cnt_drop_en_w1 <= no_eop_drop_state_posedge & !(tvld_i & tlast_i); // mop (posedge condition)
                                                                            // don't count tvld+tlast as drop
     dbg_cnt_drop_en_w2 <= no_eop_drop_state & (igr_pkt_state & tvld_i); //sop
     dbg_cnt_drop_en <= dbg_cnt_drop_en_w1 | dbg_cnt_drop_en_w2;

     if (rst) begin
       dbg_cnt_drop_en_w1 <= '0;
       dbg_cnt_drop_en_w2 <= '0;
       dbg_cnt_drop_en <= '0;
     end
   end

   generate
     if (INUM_SEG == 1) begin : tlast_seg_1

     always_comb begin
       tlast_mod = no_eop_drop_state_posedge ? '1 : tlast_i;
       tkeep_mod = no_eop_drop_state_posedge & !(tvld_i & tlast_i) ? '1 : tkeep_i;
       tlast_segment_mod = no_eop_drop_state_posedge & !(tvld_i & tlast_i) ? '1 : tlast_segment_i;
       // tdata will have junk
     end
    
     end else begin : tlast_seg_not_1

     always_comb begin
       tlast_mod = no_eop_drop_state_posedge ? '1 : tlast_i;
       tkeep_mod = no_eop_drop_state_posedge & !(tvld_i & tlast_i) ? '1 : tkeep_i;
       tlast_segment_mod[INUM_SEG-2:0] = no_eop_drop_state_posedge & !(tvld_i & tlast_i) ? '0 : 
                                           tlast_segment_i[INUM_SEG-2:0];
       tlast_segment_mod[INUM_SEG-1] = no_eop_drop_state_posedge & !(tvld_i & tlast_i) ? '1 : 
                                           tlast_segment_i[INUM_SEG-1];
       // tdata will have junk
     end

     end
   endgenerate

   always_ff @ (posedge clk) begin
     ififo_rdy <= (ififo_cnt < IFIFO_FC_WM);
   end

   always_comb begin
      // HSSI tready should always be asserted when cfg_rx_pause_en. Backpressure mechanism is via pause.
      trdy_o =  rst ? '0 : 
                  cfg_rx_pause_en ? '1 : ififo_rdy;	  
     
       // push to ififo
      if (cfg_rx_pause_en)
        ififo_push =  no_eop_drop_state_posedge ? '1 : !no_eop_drop_state & (trdy_o & tvld_i);      
      else
        ififo_push = trdy_o & tvld_i;   
   end

   always_comb begin
      if (!ififo_mty & tlast_r & (SOP_ALIGN == 1) & efifo_rdy)
	nxt_cyc_cnt = '0;
      else if (!ififo_mty & efifo_rdy)
	nxt_cyc_cnt = cyc_cnt + 1'b1;     
      else
	nxt_cyc_cnt = cyc_cnt;
   end

   always_ff @(posedge clk) begin
      cyc_cnt <= nxt_cyc_cnt;
      
      if (rst_reg[0])
	cyc_cnt <= '0;
   end

   always_comb begin
      if (EGR_FIFO_EN)
        efifo_rdy = efifo_cnt < EFIFO_FC_WM;
      else
        efifo_rdy = trdy_i;
      
      ififo_pop = !ififo_mty & efifo_rdy ;
   end

   always_comb begin
      rx_pause_o = cfg_rx_pause_en ? 
	     ({{CFG_THRESHOLD_PAD{1'b0}},ififo_cnt} > cfg_rx_pause_threshold) : '0; 
   end

   logic sop_state;
   always_ff @ (posedge clk) begin
     if ((cyc_cnt == '0) & !ififo_mty & !tlast_r & sop_state) 
       sop_state <= '0;
     else if (!ififo_mty & tlast_r) 
       sop_state <= '1;

     if (rst_reg[0])
       sop_state <= '1;
   end

   generate
      if (ENUM_SEG == 16) begin
	 always_ff @(posedge clk) begin
	    case (cyc_cnt)
	      'd0: begin
		 // ififo_tuser_md[0]       <= tuser_md_r[0];
		 ififo_tlast_segment[0]  <= tlast_segment_r[0];
		 ififo_tkeep[0]          <= tkeep_r[0];
		 ififo_tdata[0]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[15:1]       <= '0;		 
	      end
	      'd1: begin
		 // ififo_tuser_md[1]       <= tuser_md_r[0];
		 ififo_tlast_segment[1]  <= tlast_segment_r[0];
		 ififo_tkeep[1]          <= tkeep_r[0];
		 ififo_tdata[1]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[15:2]       <= '0;
	      end
	      'd2: begin
		 // ififo_tuser_md[2]       <= tuser_md_r[0];
		 ififo_tlast_segment[2]  <= tlast_segment_r[0];
		 ififo_tkeep[2]          <= tkeep_r[0];
		 ififo_tdata[2]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[15:3]       <= '0;
	      end
	      'd3: begin
		 // ififo_tuser_md[3]       <= tuser_md_r[0];
		 ififo_tlast_segment[3]  <= tlast_segment_r[0];
		 ififo_tkeep[3]          <= tkeep_r[0];
		 ififo_tdata[3]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[15:4]       <= '0;
	      end
	      'd4: begin
		 // ififo_tuser_md[4]       <= tuser_md_r[0];
		 ififo_tlast_segment[4]  <= tlast_segment_r[0];
		 ififo_tkeep[4]          <= tkeep_r[0];
		 ififo_tdata[4]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[15:5]       <= '0;
	      end
	      'd5: begin
		 // ififo_tuser_md[5]       <= tuser_md_r[0];
		 ififo_tlast_segment[5]  <= tlast_segment_r[0];
		 ififo_tkeep[5]          <= tkeep_r[0];
		 ififo_tdata[5]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[15:6]       <= '0;
	      end
	      'd6: begin
		 // ififo_tuser_md[6]       <= tuser_md_r[0];
		 ififo_tlast_segment[6]  <= tlast_segment_r[0];
		 ififo_tkeep[6]          <= tkeep_r[0];
		 ififo_tdata[6]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[15:7]       <= '0;
	      end
	      'd7: begin
		 // ififo_tuser_md[7]       <= tuser_md_r[0];
		 ififo_tlast_segment[7]  <= tlast_segment_r[0];
		 ififo_tkeep[7]          <= tkeep_r[0];
		 ififo_tdata[7]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[15:8]       <= '0;
	      end
	      'd8: begin
		 // ififo_tuser_md[8]       <= tuser_md_r[0];
		 ififo_tlast_segment[8]  <= tlast_segment_r[0];
		 ififo_tkeep[8]          <= tkeep_r[0];
		 ififo_tdata[8]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[15:9]       <= '0;
	      end
	      'd9: begin
		 // ififo_tuser_md[9]       <= tuser_md_r[0];
		 ififo_tlast_segment[9]  <= tlast_segment_r[0];
		 ififo_tkeep[9]          <= tkeep_r[0];
		 ififo_tdata[9]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[15:10]      <= '0;
	      end
	      'd10: begin
		 // ififo_tuser_md[10]       <= tuser_md_r[0];
		 ififo_tlast_segment[10]  <= tlast_segment_r[0];
		 ififo_tkeep[10]          <= tkeep_r[0];
		 ififo_tdata[10]          <= tdata_r[0];
		 ififo_data_vld           <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[15:11]       <= '0;
	      end
	      'd11: begin
		 // ififo_tuser_md[11]       <= tuser_md_r[0];
		 ififo_tlast_segment[11]  <= tlast_segment_r[0];
		 ififo_tkeep[11]          <= tkeep_r[0];
		 ififo_tdata[11]          <= tdata_r[0];
		 ififo_data_vld           <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[15:12]       <= '0;
	      end
	      'd12: begin
		 // ififo_tuser_md[12]       <= tuser_md_r[0];
		 ififo_tlast_segment[12]  <= tlast_segment_r[0];
		 ififo_tkeep[12]          <= tkeep_r[0];
		 ififo_tdata[12]          <= tdata_r[0];
		 ififo_data_vld           <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[15:13]       <= '0;
	      end
	      'd13: begin
		 // ififo_tuser_md[13]       <= tuser_md_r[0];
		 ififo_tlast_segment[13]  <= tlast_segment_r[0];
		 ififo_tkeep[13]          <= tkeep_r[0];
		 ififo_tdata[13]          <= tdata_r[0];
		 ififo_data_vld           <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[15:14]       <= '0;
	      end
	      'd14: begin
		 // ififo_tuser_md[14]       <= tuser_md_r[0];
		 ififo_tlast_segment[14]  <= tlast_segment_r[0];
		 ififo_tkeep[14]          <= tkeep_r[0];
		 ififo_tdata[14]          <= tdata_r[0];
		 ififo_data_vld           <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[15]          <= '0;
	      end
	      default: begin
		 // ififo_tuser_md[15]       <= tuser_md_r[0];
		 ififo_tlast_segment[15]  <= tlast_segment_r[0];
		 ififo_tkeep[15]          <= tkeep_r[0];
		 ififo_tdata[15]          <= tdata_r[0];
		 ififo_data_vld           <= (ififo_pop);
	      end
	    endcase // case (cyc_cnt)

	    ififo_tlast    <= tlast_r;
	    ififo_tid      <= tid_r;
	    ififo_terr     <= terr_r;
 
        // register metadata at sop or when eop
        if (sop_state)
	      ififo_tuser_md[0] <= tuser_md_r; 
        if (ififo_pop & tlast_r)
	      ififo_tuser_md[1] <= tuser_md_r; 
	    
	    if (rst_reg[0]) begin
	       ififo_data_vld      <= '0;
	       ififo_tdata         <= '0;
	       ififo_tkeep         <= '0;
	       ififo_tlast_segment <= '0;
	    end
	 end // always_ff @ (posedge clk)	 
      end // if (ENUM_SEG == 16)
      
      else if (ENUM_SEG == 8) begin
	 always_ff @(posedge clk) begin
	    case (cyc_cnt)
	      'd0: begin
		 // ififo_tuser_md[0]       <= tuser_md_r[0];
		 ififo_tlast_segment[0]  <= tlast_segment_r[0];
		 ififo_tkeep[0]          <= tkeep_r[0];
		 ififo_tdata[0]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[7:1]        <= '0;
	      end
	      'd1: begin
		 // ififo_tuser_md[1]       <= tuser_md_r[0];
		 ififo_tlast_segment[1]  <= tlast_segment_r[0];
		 ififo_tkeep[1]          <= tkeep_r[0];
		 ififo_tdata[1]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[7:2]        <= '0;
	      end
	      'd2: begin
		 // ififo_tuser_md[2]       <= tuser_md_r[0];
		 ififo_tlast_segment[2]  <= tlast_segment_r[0];
		 ififo_tkeep[2]          <= tkeep_r[0];
		 ififo_tdata[2]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[7:3]        <= '0;
	      end
	      'd3: begin
		 // ififo_tuser_md[3]       <= tuser_md_r[0];
		 ififo_tlast_segment[3]  <= tlast_segment_r[0];
		 ififo_tkeep[3]          <= tkeep_r[0];
		 ififo_tdata[3]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[7:4]        <= '0;
	      end
	      'd4: begin
		 // ififo_tuser_md[4]       <= tuser_md_r[0];
		 ififo_tlast_segment[4]  <= tlast_segment_r[0];
		 ififo_tkeep[4]          <= tkeep_r[0];
		 ififo_tdata[4]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[7:5]        <= '0;
	      end
	      'd5: begin
		 // ififo_tuser_md[5]       <= tuser_md_r[0];
		 ififo_tlast_segment[5]  <= tlast_segment_r[0];
		 ififo_tkeep[5]          <= tkeep_r[0];
		 ififo_tdata[5]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[7:6]        <= '0;
	      end
	      'd6: begin
		 // ififo_tuser_md[6]       <= tuser_md_r[0];
		 ififo_tlast_segment[6]  <= tlast_segment_r[0];
		 ififo_tkeep[6]          <= tkeep_r[0];
		 ififo_tdata[6]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[7]          <= '0;
	      end
	      default: begin
		 // ififo_tuser_md[7]       <= tuser_md_r[0];
		 ififo_tlast_segment[7]  <= tlast_segment_r[0];
		 ififo_tkeep[7]          <= tkeep_r[0];
		 ififo_tdata[7]          <= tdata_r[0];
		 ififo_data_vld          <= ififo_pop;
	      end
	    endcase // case (cyc_cnt)		

	    ififo_tlast    <= tlast_r;
	    ififo_tid      <= tid_r;
	    ififo_terr     <= terr_r;

        // register metadata at sop or when eop
        if (sop_state)
	      ififo_tuser_md[0] <= tuser_md_r; 
        if (ififo_pop & tlast_r)
	      ififo_tuser_md[1] <= tuser_md_r; 
	    
	    if (rst_reg[0]) begin
	       ififo_data_vld      <= '0;
	       ififo_tdata         <= '0;
	       ififo_tkeep         <= '0;
	       ififo_tlast_segment <= '0;
	    end
	 end
      end // if (ENUM_SEG == 8)

      else if (ENUM_SEG == 4) begin
	 always_ff @(posedge clk) begin
	    case (cyc_cnt)
	      'd0: begin
		 // ififo_tuser_md[0]       <= tuser_md_r[0];
		 ififo_tlast_segment[0]  <= tlast_segment_r[0];
		 ififo_tkeep[0]          <= tkeep_r[0];
		 ififo_tdata[0]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[3:1]        <= '0;
	      end
	      'd1: begin
		 // ififo_tuser_md[1]       <= tuser_md_r[0];
		 ififo_tlast_segment[1]  <= tlast_segment_r[0];
		 ififo_tkeep[1]          <= tkeep_r[0];
		 ififo_tdata[1]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[3:2]        <= '0;
	      end
	      'd2: begin
		 // ififo_tuser_md[2]       <= tuser_md_r[0];
		 ififo_tlast_segment[2]  <= tlast_segment_r[0];
		 ififo_tkeep[2]          <= tkeep_r[0];
		 ififo_tdata[2]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[3]          <= '0;
	      end
	      'd3: begin
		 // ififo_tuser_md[3]       <= tuser_md_r[0];
		 ififo_tlast_segment[3]  <= tlast_segment_r[0];
		 ififo_tkeep[3]          <= tkeep_r[0];
		 ififo_tdata[3]          <= tdata_r[0];
		 ififo_data_vld          <= ififo_pop;
	      end
	    endcase
	    ififo_tlast    <= tlast_r;
	    ififo_tid      <= tid_r;
	    ififo_terr     <= terr_r;

        // register metadata at sop or when eop
        if (sop_state)
	      ififo_tuser_md[0] <= tuser_md_r; 
        if (ififo_pop & tlast_r)
	      ififo_tuser_md[1] <= tuser_md_r; 
	    
	    if (rst_reg[0]) begin
	       ififo_data_vld      <= '0;
	       ififo_tdata         <= '0;
	       ififo_tkeep         <= '0;
	       ififo_tlast_segment <= '0;
	    end
	 end
      end // if (ENUM_SEG == 4)
      
      else if (ENUM_SEG == 2) begin
	 always_ff @(posedge clk) begin
	    case (cyc_cnt)
	      'd0: begin
		 // ififo_tuser_md[0]       <= tuser_md_r[0];
		 ififo_tlast_segment[0]  <= tlast_segment_r[0];
		 ififo_tkeep[0]          <= tkeep_r[0];
		 ififo_tdata[0]          <= tdata_r[0];
		 ififo_data_vld          <= (ififo_pop & tlast_r & (SOP_ALIGN == 1));
		 ififo_tkeep[1]          <= '0;
	      end
	      default: begin
		 // ififo_tuser_md[1]       <= tuser_md_r[0];
		 ififo_tlast_segment[1]  <= tlast_segment_r[0];
		 ififo_tkeep[1]          <= tkeep_r[0];
		 ififo_tdata[1]          <= tdata_r[0];
		 ififo_data_vld          <= ififo_pop;
		 
	      end
	    endcase // case (cyc_cnt)
	    ififo_tlast    <= tlast_r;
	    ififo_tid      <= tid_r;
	    ififo_terr     <= terr_r;

        // register metadata at sop or when eop
        if (sop_state)
	      ififo_tuser_md[0] <= tuser_md_r; 
        if (ififo_pop & tlast_r)
	      ififo_tuser_md[1] <= tuser_md_r; 
	    
	    if (rst_reg[0]) begin
	       ififo_data_vld      <= '0;
	       ififo_tdata         <= '0;
	       ififo_tkeep         <= '0;
	       ififo_tlast_segment <= '0;
	    end
	 end // always_ff @ (posedge clk)	 
      end // if (ENUM_SEG == 2)

      else begin
	 always_ff @(posedge clk) begin
	    // ififo_tuser_md[0]       <= tuser_md_r[0];
	    ififo_tlast_segment[0]  <= tlast_segment_r[0];
	    ififo_tkeep[0]          <= tkeep_r[0];
	    ififo_tdata[0]          <= tdata_r[0];
	    ififo_data_vld          <= ififo_pop;

	    ififo_tlast    <= tlast_r;
	    ififo_tid      <= tid_r;
	    ififo_terr     <= terr_r;

        // register metadata at sop or when eop
        if (sop_state)
	      ififo_tuser_md[0] <= tuser_md_r; 
        if (ififo_pop & tlast_r)
	      ififo_tuser_md[1] <= tuser_md_r; 
	    
	    if (rst_reg[0]) begin
	       ififo_data_vld      <= '0;
	       ififo_tdata         <= '0;
	       ififo_tkeep         <= '0;
	       ififo_tlast_segment <= '0;
	    end
	 end

      end // else: !if(ENUM_SEG == 2)
   endgenerate

    
   generate
      if (ENUM_SEG == 1) begin
	 always_comb begin
	    efifo_push    = ififo_data_vld ;
	    
	    efifo_tdata_w         = ififo_tdata[0];
	    efifo_tkeep_w         = ififo_tkeep[0];
	    efifo_tlast_segment_w = ififo_tlast_segment[0] ;
	    efifo_tid_w           = ififo_tid[0];
	    efifo_tuser_md_w      = ififo_tuser_md;
	    efifo_tlast_w         = ififo_tlast;
	    efifo_terr_w          = ififo_terr[0];

	    // tlast_segment_o = efifo_tlast_segment_r[0];
	 end
      end // if (ENUM_SEG == 1)

      else if (ENUM_SEG == 2) begin
	 always_comb begin
	    efifo_push    = ififo_data_vld ;
	    
	    efifo_tdata_w         = ififo_tdata[1:0];
	    efifo_tkeep_w         = ififo_tkeep[1:0];
	    efifo_tlast_segment_w = ififo_tlast_segment[1:0] ;
	    efifo_tid_w           = ififo_tid[1:0];
	    efifo_tuser_md_w      = ififo_tuser_md;
	    efifo_tlast_w         = ififo_tlast;
	    efifo_terr_w          = ififo_terr[1:0];

	    // tlast_segment_o = efifo_tlast_segment_r[1:0];
	 end
      end // if (ENUM_SEG == 2)
      
      else if (ENUM_SEG == 4) begin
	 always_comb begin
	    efifo_push    = ififo_data_vld ;
	    
	    efifo_tdata_w         = ififo_tdata[3:0];
	    efifo_tkeep_w         = ififo_tkeep[3:0];
	    efifo_tlast_segment_w = ififo_tlast_segment[3:0] ;
	    efifo_tid_w           = ififo_tid[3:0];
	    efifo_tuser_md_w      = ififo_tuser_md;
	    efifo_tlast_w         = ififo_tlast;
	    efifo_terr_w          = ififo_terr[3:0];

	    // tlast_segment_o = efifo_tlast_segment_r[3:0];
	 end
      end // if (ENUM_SEG == 4)
      
      else if (ENUM_SEG == 8) begin
	 always_comb begin
	    efifo_push    = ififo_data_vld ;
	    
	    efifo_tdata_w         = ififo_tdata[7:0];
	    efifo_tkeep_w         = ififo_tkeep[7:0];
	    efifo_tlast_segment_w = ififo_tlast_segment[7:0] ;
	    efifo_tid_w           = ififo_tid[7:0];
	    efifo_tuser_md_w      = ififo_tuser_md;
	    efifo_tlast_w         = ififo_tlast;
	    efifo_terr_w          = ififo_terr[7:0];

	    // tlast_segment_o = efifo_tlast_segment_r[7:0];
	 end
      end // if (ENUM_SEG == 8)

      else begin
	 always_comb begin
	    efifo_push    = ififo_data_vld ;
	    
	    efifo_tdata_w         = ififo_tdata[15:0];
	    efifo_tkeep_w         = ififo_tkeep[15:0];
	    efifo_tlast_segment_w = ififo_tlast_segment[15:0] ;
	    efifo_tid_w           = ififo_tid[15:0];
	    efifo_tuser_md_w      = ififo_tuser_md;
	    efifo_tlast_w         = ififo_tlast;
	    efifo_terr_w          = ififo_terr[15:0];

	    // tlast_segment_o = efifo_tlast_segment_r[15:0];
	 end
      end // else: !if(ENUM_SEG == 8)
   endgenerate
   
   //------------------------------------------------------------------------------------------
   // egress interface
//------------------------------------------------------------------------------------------
   generate 
     if (EGR_FIFO_EN) begin   

     always_ff @(posedge clk) begin	
	 	if (rst_reg[2])
	 		pkt_state <= '0;
	 	else
	 		if (tvld_o & tlast_o & trdy_i)
	 		  pkt_state <= '0; // clear
	 		else if (tvld_o & trdy_i)
	 		  pkt_state <= ~pkt_state ? '1 : pkt_state; // set
	 end // always_ff

     end else begin

     always_ff @(posedge clk) begin	
	 	if (rst_reg[2])
	 		pkt_state <= '0;
	 	else
	 		if (tvld_o & tlast_o)
	 		  pkt_state <= '0; // clear
	 		else if (tvld_o)
	 		  pkt_state <= ~pkt_state ? '1 : pkt_state; // set
	 end  

     end
   endgenerate
  	//-----------------------------------------------------------------------------------------
	// Generate hdr_seg_cnt for hdr_seg, payld_seg marking and seg_info
	// Generate payld_seg_cnt for seg_info
	
	always_ff @(posedge clk) begin
	  if (rst_reg[3])
	    hdr_seg_cnt <= '0;
      else
	    if (tvld_o & tlast_o)
		  hdr_seg_cnt <= '0;
	    else if (tvld_o & hdr_seg)
	      hdr_seg_cnt <= hdr_seg_cnt + 1'b1;
		else if (tvld_o) // payld_seg
	      hdr_seg_cnt <= hdr_seg_cnt;
	end
	
	always_comb begin
	  if (hdr_seg_cnt < HDR_CYCLE_CNT) begin
	    hdr_seg       = '1;
	    payld_seg     = '0;
      end else if (hdr_seg_cnt > HDR_CYCLE_CNT - 'd1) begin
	    hdr_seg       = '0;
	    payld_seg     = '1;
	  end else begin
	    hdr_seg       = '0;
	    payld_seg     = '0;
	  end
	end
	
	always_ff @(posedge clk) begin
	  if (rst_reg[4])
	    payld_seg_cnt <= '0;
      else
	    if (tvld_o & tlast_o)
		  payld_seg_cnt <= '0;
	    else if (tvld_o & payld_seg)
	      payld_seg_cnt <= payld_seg_cnt + 1'b1;
	end	 
   
   always_comb begin
      efifo_pop = trdy_i & !efifo_mty;
 
      // egress FIFO enabled
      if (EGR_FIFO_EN) begin
        tvld_o     = !efifo_mty;
        tid_o      = efifo_tid_r;
        tdata_o    = BYTE_ROTATE ? fn_byte_rotate(efifo_tdata_r) : efifo_tdata_r; 
        tkeep_o    = efifo_tkeep_r;
        tuser_md_o = efifo_tuser_md_r;
        terr_o     = efifo_terr_r;
        tlast_o    = efifo_tlast_r;
        tlast_segment_o = efifo_tlast_segment_r[ENUM_SEG-1:0];
	    
        //seg_info
	    tuser_segment_info_o.sop           = !efifo_mty & ~pkt_state;          
	    tuser_segment_info_o.eop           = efifo_tlast_r;          
	    tuser_segment_info_o.sos           = (!efifo_mty & ~pkt_state);          
	    tuser_segment_info_o.eos           = efifo_tlast_r;          
	    // tuser_segment_info_o.bytesvld      = tkeep_bytesvld(efifo_tkeep_r);     
	    tuser_segment_info_o.bytesvld      = '0; // moved calculation to parser     
	    tuser_segment_info_o.hdr_segment   = hdr_seg;  
	    tuser_segment_info_o.payld_segment = payld_seg;
	    tuser_segment_info_o.igr_port      = packet_switch_pkg::PORT_E'(MSGDMA_0);   
	    tuser_segment_info_o.egr_port      = packet_switch_pkg::PORT_E'(MSGDMA_1); 
      end else begin
      // egress FIFO disabled
        tvld_o     = ififo_data_vld;
        tid_o      = ififo_tid[ENUM_SEG-1:0];
        tdata_o    = BYTE_ROTATE ? fn_byte_rotate(ififo_tdata[ENUM_SEG-1:0]) : 
                                                       ififo_tdata[ENUM_SEG-1:0];
        tkeep_o    = ififo_tkeep[ENUM_SEG-1:0];
        tuser_md_o = ififo_tuser_md;
        terr_o     = ififo_terr[ENUM_SEG-1:0];
        tlast_o    = ififo_tlast;
        tlast_segment_o = ififo_tlast_segment[ENUM_SEG-1:0];
	    
        //seg_info
	    tuser_segment_info_o.sop           = tvld_o & ~pkt_state;          
	    tuser_segment_info_o.eop           = tlast_o;          
	    tuser_segment_info_o.sos           = (tvld_o & ~pkt_state);          
	    tuser_segment_info_o.eos           = tlast_o;          
	    // tuser_segment_info_o.bytesvld      = tkeep_bytesvld(efifo_tkeep_r);     
	    tuser_segment_info_o.bytesvld      = '0; // moved calculation to parser     
	    tuser_segment_info_o.hdr_segment   = hdr_seg;  
	    tuser_segment_info_o.payld_segment = payld_seg;
	    tuser_segment_info_o.igr_port      = packet_switch_pkg::PORT_E'(MSGDMA_0);   
	    tuser_segment_info_o.egr_port      = packet_switch_pkg::PORT_E'(MSGDMA_1); 
      end
   end //always_comb
   
   //------------------------------------------------------------------------------------------
   // ingress fifo
   ipbb_scfifo_inff #(  .DWD ( (INUM_SEG*IDATA_SEG_WIDTH)
			      +(INUM_SEG*TID_WIDTH)
			      +(INUM_SEG*IKEEP_SEG_WIDTH)
			      +INUM_SEG
			      +1
			      +(INUM_SEG*ITUSER_MD_WIDTH)
			      +INUM_SEG )
		       ,.NUM_WORDS (IFIFO_DEPTH) ) ififo
     (
      .clk (clk)
      ,.rst (rst_reg[0])

      // inputs
      ,.din ({ tdata_i
	      ,tid_i
	      ,tkeep_mod
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

      // mapping read data from ififo
   always_comb begin
      tdata_r         = '0;
      tid_r           = '0;
      tkeep_r         = '0;
      tlast_segment_r = '0;
      // tuser_md_r      = '0;
      terr_r          = '0;     
      tlast_r         = ififo_tlast_r;
      tuser_md_r      = ififo_tuser_md_r;

      // INUM_SEG = 1
      tdata_r[0]         = ififo_tdata_r;
      tid_r[0]           = ififo_tid_r;
      tkeep_r[0]         = ififo_tkeep_r;
      tlast_segment_r[0] = ififo_tlast_segment_r;
      terr_r[0]          = ififo_terr_r;
   end

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
      ,.rdempty_lkahd ( )
      ,.wrfull (efifo_full)
      ,.wrusedw (efifo_cnt)
      ,.overflow (efifo_ov)
      ,.underflow (efifo_ud)
      );

	function [$clog2(EKEEP_WIDTH):0] tkeep_bytesvld;
	input logic [EKEEP_WIDTH-1:0] din;
	begin
	    logic [$clog2(EKEEP_WIDTH):0] tmp_sum;
	    logic [$clog2(EKEEP_WIDTH)-1:0] tmp_cnt;
	    
	    tmp_cnt = '0;
	    
	    for (int i = 0; i < EKEEP_WIDTH ; i++) begin
		
		tmp_sum = tmp_cnt + din[i];
		tmp_cnt = tmp_sum[$clog2(EKEEP_WIDTH)-1:0];		
	    end // for 
	    tkeep_bytesvld  = tmp_sum;	    
	end
    endfunction

    //csr intf
   igr_wadj_csr_intf
   #( .INUM_SEG   (INUM_SEG) 
     ,.BASE_ADDR  (BASE_ADDR) 
     ,.MAX_ADDR   (MAX_ADDR)
     ,.ADDR_WIDTH (ADDR_WIDTH)
     ,.DATA_WIDTH (DATA_WIDTH)) csr_intf
   (//------------------------------------------------------------------------------------
    // Clock
    // input
    .clk (clk)

    // Reset
    ,.rst (rst_reg[2])

    //-----------------------------------------------------------------------------------------
    // AVMM interface

    // inputs
    ,.avmm_address   (avmm_address)
    ,.avmm_read      (avmm_read)
    ,.avmm_write     (avmm_write)
    ,.avmm_writedata (avmm_writedata)
    ,.avmm_byteenable (avmm_byteenable)

    // outputs
    ,.avmm_readdata (avmm_readdata)  
    ,.avmm_readdata_valid (avmm_readdata_valid)

    //-----------------------------------------------------------------------------------------
    // CSR Priority Port 
    // output
    ,.cfg_rx_pause_en        (cfg_rx_pause_en)
    ,.cfg_rx_pause_threshold (cfg_rx_pause_threshold)
    ,.cfg_drop_threshold     (cfg_drop_threshold)

   );

   // swapping msb byte to lsb byte
   function [(EDATA_SEG_WIDTH*ENUM_SEG)/8-1:0] [7:0] fn_byte_rotate
     (input [(EDATA_SEG_WIDTH*ENUM_SEG)/8-1:0] [7:0] din);
      
      begin
	 logic [(EDATA_SEG_WIDTH*ENUM_SEG)/8-1:0] [7:0] tmp_din, tmp;
	 tmp_din = din;
	 
	 for (int i = 0; i < (EDATA_SEG_WIDTH*ENUM_SEG)/8; i++) begin
	    tmp[i] = tmp_din[((EDATA_SEG_WIDTH*ENUM_SEG)/8-1)-i];	    
	 end
	 fn_byte_rotate = tmp;
      end
   endfunction
   
endmodule // packet_switch_rx_igr_wadj

    

    

				       
