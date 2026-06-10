//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module packet_switch_lkup
   #( parameter TDATA_WIDTH                 = 512
     ,parameter TKEEP_WIDTH                 = TDATA_WIDTH/8
     ,parameter USERMETADATA_WIDTH          = 1

     ,parameter TCAM_KEY_WIDTH              = packet_switch_pkg::tuple_map_width
     ,parameter TCAM_RESULT_WIDTH           = packet_switch_pkg::TCAM_RESULT_WIDTH
     ,parameter TCAM_ENTRIES                = 64
     ,parameter TCAM_USERMETADATA_WIDTH     = 1
     ,parameter CHTID_WIDTH                 = 1
     ,parameter NUM_EGR_INTF                = 2 // | number of egress interface that
                                                // | lkup sends pkt to
     ,parameter INST_ID                     = 0 // instance ID
     ,parameter DMA_CH                      = 1
     // scheduler parameter
     // ,parameter NUM_IGR_FIFOS               = 12
     // scheduler parameter
     // ,parameter NUM_IGR_PORTS               = 3 // number of ingress ports per pipeline
     // scheduler parameter
     // ,parameter IGR_FIFO_DEPTH              = 512
   ) 

  (
    //----------------------------------------------------------------------------------------
    // Clocks
    input var logic                                    clk

    //----------------------------------------------------------------------------------------
    // Resets 
    ,input var logic                                   rst

    //-------------------------------------------------------------------------------------------
    // tcam interface
    // result response
    ,input var logic                                   tcam_rsp_tvalid
    ,input var packet_switch_pkg::TCAM_RESULT_S           tcam_rsp_tuser_result
    ,input var logic                                   tcam_rsp_tuser_found
    ,input var logic  [TCAM_USERMETADATA_WIDTH-1:0]    tcam_rsp_tuser_usermetadata 
    ,output var logic                                  tcam_rsp_tready

    // key request:
    ,input var logic                                   tcam_req_tready   								      		      
    ,output var logic                                  tcam_req_tvalid
    ,output var logic  [CHTID_WIDTH-1:0]               tcam_req_tid
    ,output var packet_switch_pkg::tuple_map_S            tcam_req_tuser_key
    ,output var logic  [TCAM_USERMETADATA_WIDTH-1:0]   tcam_req_tuser_usermetadata

    //----------------------------------------------------------------------------------------
    // parser interface
    ,input var logic                                   pars2lu_tvalid
    ,input var logic [TDATA_WIDTH-1:0]                 pars2lu_tdata
    ,input var logic [USERMETADATA_WIDTH-1:0]          pars2lu_tuser_usermetadata
    ,input var packet_switch_pkg::SEGMENT_INFO_S          pars2lu_tuser_segment_info
    ,input var packet_switch_pkg::tuple_map_S             pars2lu_tuser_lu_key

    // ,output var logic                                  lu2pars_tready

    ,input var logic                                   pars2lu_fifo_empty
    ,output var logic                                  lu2pars_fifo_rd

    // TCAM request FIFO
    ,input var logic                                   pars2lu_tcam_req_fifo_empty
    ,output var logic                                  lu2pars_tcam_req_fifo_rd

    //----------------------------------------------------------------------------------------
    // egress width adjust interface
    //   bit 0: dma, bit 1: user.
    ,output var logic [NUM_EGR_INTF-1:0]                          lu2ewadj_tvalid
    ,output var logic [NUM_EGR_INTF-1:0][TDATA_WIDTH-1:0]         lu2ewadj_tdata
    ,output var logic [NUM_EGR_INTF-1:0][TKEEP_WIDTH-1:0]         lu2ewadj_tkeep
    ,output var logic [NUM_EGR_INTF-1:0][USERMETADATA_WIDTH-1:0]  lu2ewadj_tuser_usermetadata
    ,output var packet_switch_pkg::SEGMENT_INFO_S [NUM_EGR_INTF-1:0] lu2ewadj_tuser_segment_info

    ,input var logic [NUM_EGR_INTF-1:0]                           ewadj2lu_tready

    // scheduler interface
    // ,input var logic [NUM_IGR_FIFOS-1:0] 
                       // [$clog2(IGR_FIFO_DEPTH)-1:0]    sch2lu_fifo_occ
   );
   import packet_switch_pkg::*;

   localparam LATENCY_FIFO_DEPTH = 512;
   localparam LATENCY_FIFO_THRESHOLD = LATENCY_FIFO_DEPTH-32;

   packet_switch_pkg::SEGMENT_INFO_S latency_fifo_tuser_segment_info;

   packet_switch_pkg::TCAM_RESULT_S tcam_rsp_result;

   logic [TDATA_WIDTH-1:0] latency_fifo_tdata;

   logic [TCAM_USERMETADATA_WIDTH-1:0] tcam_rsp_usermetadata;

   logic [USERMETADATA_WIDTH-1:0] latency_fifo_tuser_usermetadata;

   logic [$clog2(LATENCY_FIFO_DEPTH)-1:0] latency_fifo_occ;

   logic tcam_rsp_fifo_empty, tcam_rsp_fifo_rd, req_fifo_rdy, latency_fifo_rd, 
     latency_fifo_empty, latency_fifo_full, latency_fifo_overflow, 
     latency_fifo_underflow, tcam_rsp_vld, tcam_rsp_found;
    
   logic [31:0] rst_reg;
   // Generate arrays of reset to be used in submodule
   always_ff @(posedge clk) begin
      rst_reg <= '{default:rst};
   end

   //----------------------------------------------------------------------------------------
   // lkup_tcam_intf

   lkup_tcam_intf
     #( .USERMETADATA_WIDTH (USERMETADATA_WIDTH)      
       ,.TCAM_KEY_WIDTH (TCAM_KEY_WIDTH)          
       ,.TCAM_RESULT_WIDTH (TCAM_RESULT_WIDTH)        
       ,.TCAM_ENTRIES (TCAM_ENTRIES)            
       ,.TCAM_USERMETADATA_WIDTH (TCAM_USERMETADATA_WIDTH) ) lkup_tcam_intf_inst
    (//------------------------------------------------------------------------------------
     // Clocks
     .clk (clk)
	 
     //----------------------------------------------------------------------------------------
     // Resets 
     ,.rst (rst_reg[1])
	 
     //-------------------------------------------------------------------------------------------
     // tcam interface
     // inputs
     ,.tcam_rsp_tvalid (tcam_rsp_tvalid)
     ,.tcam_rsp_tuser_result (tcam_rsp_tuser_result)
     ,.tcam_rsp_tuser_found (tcam_rsp_tuser_found)
     ,.tcam_rsp_tuser_usermetadata (tcam_rsp_tuser_usermetadata)
     // output
     ,.tcam_rsp_tready (tcam_rsp_tready)
	 
     // key request:
     // input
     ,.tcam_req_tready (tcam_req_tready)   								      		      
     // outputs
     ,.tcam_req_tvalid (tcam_req_tvalid)
     ,.tcam_req_tid (tcam_req_tid)
     ,.tcam_req_tuser_key (tcam_req_tuser_key)
     ,.tcam_req_tuser_usermetadata (tcam_req_tuser_usermetadata)
	 
     //----------------------------------------------------------------------------------------
     // ingress interface
     // inputs
     ,.tvalid (pars2lu_tvalid)
     ,.tuser_usermetadata (pars2lu_tuser_usermetadata)
     ,.tuser_segment_info (pars2lu_tuser_segment_info)
     ,.tuser_lu_key (pars2lu_tuser_lu_key)
     ,.pars2lu_tcam_req_fifo_empty (pars2lu_tcam_req_fifo_empty)

     // output
     ,.lu2pars_tcam_req_fifo_rd (lu2pars_tcam_req_fifo_rd)

     //----------------------------------------------------------------------------------------
     // ccm interface
     // outputs
     ,.tcam_rsp_result (tcam_rsp_result)
     ,.tcam_rsp_found (tcam_rsp_found)
     ,.tcam_rsp_usermetadata (tcam_rsp_usermetadata)
	 
     // output
     ,.rsp_fifo_empty (tcam_rsp_fifo_empty)
     // input
     ,.rsp_fifo_rd (tcam_rsp_fifo_rd)
     );

   //----------------------------------------------------------------------------------------
   // lkup_ccm

   lkup_ccm
      #( .TDATA_WIDTH (TDATA_WIDTH)                              
        ,.USERMETADATA_WIDTH (USERMETADATA_WIDTH)          
        ,.TCAM_USERMETADATA_WIDTH (TCAM_USERMETADATA_WIDTH)
        ,.DMA_CH (DMA_CH)
     ) lkup_ccm_inst
    (//------------------------------------------------------------------------------------
     // Clocks
     .clk (clk)
	 
     //----------------------------------------------------------------------------------------
     // Resets 
     ,.rst (rst_reg[1])

     //----------------------------------------------------------------------------------------
     // lkup tcam interface
     // inputs
     ,.tcam_rsp_result (tcam_rsp_result)
     ,.tcam_rsp_found (tcam_rsp_found)
     ,.tcam_rsp_usermetadata (tcam_rsp_usermetadata)
  
     // tcam_rsp_fifo
     // input
     ,.tcam_rsp_fifo_empty (tcam_rsp_fifo_empty)
     // output
     ,.tcam_rsp_fifo_rd (tcam_rsp_fifo_rd)
  
     //----------------------------------------------------------------------------------------
     // latency fifo interface
     // inputs
     ,.pkt_tdata (pars2lu_tdata)
     ,.pkt_tuser_usermetadata (pars2lu_tuser_usermetadata)
     ,.pkt_tuser_segment_info (pars2lu_tuser_segment_info)
     ,.pkt_fifo_empty (pars2lu_fifo_empty)
     // output
     ,.pkt_fifo_rd (lu2pars_fifo_rd)
  
     //----------------------------------------------------------------------------------------
     // egress width adjust interface
     // input
     ,.ewadj2lu_tready (ewadj2lu_tready)

     // outputs
     ,.lu2ewadj_tvalid (lu2ewadj_tvalid)
     ,.lu2ewadj_tdata (lu2ewadj_tdata)
     ,.lu2ewadj_tkeep (lu2ewadj_tkeep)
     ,.lu2ewadj_tuser_usermetadata (lu2ewadj_tuser_usermetadata)
     ,.lu2ewadj_tuser_segment_info (lu2ewadj_tuser_segment_info)

     );


   //------------------------------------------------------------------------------------------
   // debug printouts

   `ifdef DBG_STMT_ON

   // synopsys translate_off
  
   logic [31:0] req_cnt, rsp_cnt, igr_cnt;
   logic [1:0][31:0] egr_cnt;

   always_ff @(posedge clk) begin
      // igr_cnt
      if (lu2pars_fifo_rd & pars2lu_tuser_segment_info.eop) begin
        igr_cnt <= igr_cnt + 1'b1;
      end

      if (lu2pars_fifo_rd) begin
	 $display("[PD_DBG] rx_pipe id:%0d lkup: igr_cnt='d%0d; data='h%0h; sop='h%0h; eop='h%0h; time=%0t"
          ,INST_ID
          ,igr_cnt
          ,pars2lu_tdata
		  ,pars2lu_tuser_segment_info.sop
		  ,pars2lu_tuser_segment_info.eop
		  ,$time);
      end

      // DMA egr_cnt 
      if (lu2ewadj_tvalid[0] & ewadj2lu_tready[0] & lu2ewadj_tuser_segment_info[0].eop) begin
        egr_cnt[0] <= egr_cnt[0] + 1'b1;
      end

      if (lu2ewadj_tvalid[0] & ewadj2lu_tready[0]) begin
	 $display("[PD_DBG] rx_pipe id:%0d lkup (dma): egr_cnt='d%0d; data='h%0h; sop='h%0h; eop='h%0h; time=%0t"
          ,INST_ID
          ,egr_cnt[0]
          ,lu2ewadj_tdata[0]
		  ,lu2ewadj_tuser_segment_info[0].sop
		  ,lu2ewadj_tuser_segment_info[0].eop
		  ,$time);
      end

      // User egr_cnt 
      if (lu2ewadj_tvalid[1] & ewadj2lu_tready[1] & lu2ewadj_tuser_segment_info[1].eop) begin
        egr_cnt[1] <= egr_cnt[1] + 1'b1;
      end

      if (lu2ewadj_tvalid[1] & ewadj2lu_tready[1]) begin
	 $display("[PD_DBG] rx_pipe id:%0d lkup (user): egr_cnt='d%0d; data='h%0h; sop='h%0h; eop='h%0h; time=%0t"
          ,INST_ID
          ,egr_cnt[1]
          ,lu2ewadj_tdata[1]
		  ,lu2ewadj_tuser_segment_info[1].sop
		  ,lu2ewadj_tuser_segment_info[1].eop
		  ,$time);
      end

      // TCAM request
      if (tcam_req_tvalid & tcam_req_tready) begin
        req_cnt <= req_cnt + 1'b1;

	 $display("[PD_DBG] rx_pipe id:%0d lkup: req_cnt='d%0d; time=%0t"
          ,INST_ID
          ,req_cnt
		  ,$time);

	 $display("[PD_DBG] rx_pipe id:%0d lkup: req_cnt='d%0d; ip_protocol='h%0h; ethtype='h%0h;"
          ,INST_ID
          ,req_cnt
          ,tcam_req_tuser_key.ip_protocol
          ,tcam_req_tuser_key.ethtype);

	 $display("[PD_DBG] rx_pipe id:%0d lkup: req_cnt='d%0d; tci_vlana='h%0h; tci_vlanb='h%0h;"
          ,INST_ID
          ,req_cnt
          ,tcam_req_tuser_key.tci_vlana
          ,tcam_req_tuser_key.tci_vlanb);

	 $display("[PD_DBG] rx_pipe id:%0d lkup: req_cnt='d%0d; l4_src_port='h%0h; l4_dst_port='h%0h;"
          ,INST_ID
          ,req_cnt
          ,tcam_req_tuser_key.l4_src_port                        
          ,tcam_req_tuser_key.l4_dst_port);

	 $display("[PD_DBG] rx_pipe id:%0d lkup: req_cnt='d%0d; src_ip='h%0h; dst_ip='h%0h;"
          ,INST_ID
          ,req_cnt
          ,tcam_req_tuser_key.src_ip                        
          ,tcam_req_tuser_key.dst_ip);

	 $display("[PD_DBG] rx_pipe id:%0d lkup: req_cnt='d%0d; src_mac='h%0h; dst_mac='h%0h;"
          ,INST_ID
          ,req_cnt
          ,tcam_req_tuser_key.src_mac
          ,tcam_req_tuser_key.dst_mac);
      end

      // TCAM response
      if (tcam_rsp_tvalid & tcam_rsp_tready) begin
        rsp_cnt <= rsp_cnt + 1'b1;

	 $display("[PD_DBG] rx_pipe id:%0d lkup: rsp_cnt='d%0d; time=%0t"
          ,INST_ID
          ,rsp_cnt
		  ,$time);

	 $display("[PD_DBG] rx_pipe id:%0d lkup: rsp_cnt='d%0d; tcam_rsp_tuser_found=%0h;"
          ,INST_ID
          ,rsp_cnt
          ,tcam_rsp_tuser_found);

	 $display("[PD_DBG] rx_pipe id:%0d lkup: rsp_cnt='d%0d; egr_port='h%0h; drop='h%0h;"
          ,INST_ID
          ,rsp_cnt
          ,tcam_rsp_tuser_result.egr_port
          ,tcam_rsp_tuser_result.drop);
      end

      if (rst) begin
        req_cnt <= '0;
        rsp_cnt <= '0;
        igr_cnt <= '0;
        egr_cnt <= '0;
      end
   end		
   // synopsys translate_on
 `endif

endmodule