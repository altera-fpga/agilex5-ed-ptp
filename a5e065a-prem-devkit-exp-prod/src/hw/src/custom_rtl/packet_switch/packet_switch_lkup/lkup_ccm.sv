//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


//////////////////////////////////////////////////////////////////////////////////////////////
// Description:
//   Congestion management, dequeue lookup response, and dequeue packet
//
//////////////////////////////////////////////////////////////////////////////////////////////

module lkup_ccm
   #( parameter TDATA_WIDTH                 = 512
     ,parameter TKEEP_WIDTH                 = TDATA_WIDTH/8
     ,parameter USERMETADATA_WIDTH          = 1
     ,parameter TCAM_USERMETADATA_WIDTH     = 1
     ,parameter NUM_EGR_INTF                = 2
     ,parameter EGR_FIFO_DEPTH              = 512
     ,parameter DMA_CH                      = 1
     // scheduler parameter
     // ,parameter NUM_IGR_PORTS               = 3  // number of ingress ports per pipeline
     // scheduler parameter
     // ,parameter NUM_IGR_FIFOS               = 12 // number of ingress fifos per pipeline
     // scheduler parameter
     // ,parameter IGR_FIFO_DEPTH              = 512
   ) 

  (
    //----------------------------------------------------------------------------------------
    // Clocks
    input var logic                                   clk

    //----------------------------------------------------------------------------------------
    // Resets 
    ,input var logic                                  rst

    //----------------------------------------------------------------------------------------
    // lkup tcam interface
    ,input var packet_switch_pkg::TCAM_RESULT_S          tcam_rsp_result
    ,input var logic                                  tcam_rsp_found
    ,input var logic [TCAM_USERMETADATA_WIDTH-1:0]    tcam_rsp_usermetadata 

    // tcam_rsp_fifo
    ,input var logic                                  tcam_rsp_fifo_empty
    ,output var logic                                 tcam_rsp_fifo_rd

    //----------------------------------------------------------------------------------------
    // latency fifo interface
    ,input var logic [TDATA_WIDTH-1:0]                pkt_tdata
    ,input var logic [USERMETADATA_WIDTH-1:0]         pkt_tuser_usermetadata
    ,input var packet_switch_pkg::SEGMENT_INFO_S         pkt_tuser_segment_info
     
    ,input var logic                                  pkt_fifo_empty
    ,output var logic                                 pkt_fifo_rd

    //----------------------------------------------------------------------------------------
    // egress width adjust interface
    //   bit 0: dma, bit 1: user.
    ,input var logic [NUM_EGR_INTF-1:0]                           ewadj2lu_tready
    ,output var logic [NUM_EGR_INTF-1:0]                          lu2ewadj_tvalid
    ,output var logic [NUM_EGR_INTF-1:0][TDATA_WIDTH-1:0]         lu2ewadj_tdata
    ,output var logic [NUM_EGR_INTF-1:0][TKEEP_WIDTH-1:0]         lu2ewadj_tkeep
    ,output var logic [NUM_EGR_INTF-1:0][USERMETADATA_WIDTH-1:0]  lu2ewadj_tuser_usermetadata
    ,output var packet_switch_pkg::SEGMENT_INFO_S [NUM_EGR_INTF-1:0] lu2ewadj_tuser_segment_info

    // scheduler interface
    // ,input var logic [NUM_IGR_FIFOS-1:0] 
                       // [$clog2(IGR_FIFO_DEPTH)-1:0]   sch2lu_fifo_occ

    //----------------------------------------------------------------------------------------
    // csr configuration interface
    // drop threshold for scheduler fifo occupancy
    // ,input var logic [NUM_IGR_FIFOS-1:0] 
                       // [$clog2(IGR_FIFO_DEPTH)-1:0]   cfg_drop_threshd

   );
   import packet_switch_pkg::*;

   // localparam NUM_EGR_PORTS = NUM_IGR_PORTS;  
   localparam EGR_FIFO_THRESHOLD = EGR_FIFO_DEPTH - 32;

   logic drop_detect, drop_detect_c1, tcam_rsp_drop_state, 
     threshld_drop_state, threshld_drop_detect_seop, tcam_rsp_fifo_rd_dma, 
     tcam_rsp_fifo_rd_user;

   logic                          pkt_tvld, pkt_vld_c1, dma_vld, user_vld;
   logic [TDATA_WIDTH-1:0]        pkt_tdata_c1;
   logic [(TDATA_WIDTH/8)-1:0]    pkt_tkeep_c1;
   logic [USERMETADATA_WIDTH-1:0] pkt_tuser_usermetadata_c1;
   packet_switch_pkg::SEGMENT_INFO_S pkt_tuser_segment_info_c1;

   logic [NUM_EGR_INTF-1:0] egr_fifo_wr, egr_fifo_rd, egr_fifo_empty,
     egr_fifo_full, egr_fifo_overflow, egr_fifo_underflow;

   logic [NUM_EGR_INTF-1:0][$clog2(EGR_FIFO_DEPTH)-1:0] egr_fifo_occ;
   logic [NUM_EGR_INTF-1:0] egr_fifo_rdy, pkt_fifo_rd_state;

   packet_switch_pkg::PORT_E egr_port_reg;

   logic [15:0] multicast_port_reg; 
   logic multicast_en_reg;

   logic [31:0] rst_reg;
   // Generate arrays of reset to be used in submodule
   always_ff @(posedge clk) begin
      rst_reg <= '{default:rst};
   end

   // determine drop from result or rsp_found
   always_comb begin
     if (!tcam_rsp_fifo_empty 
         & tcam_rsp_found 
         & !tcam_rsp_result.drop
         & !pkt_fifo_rd_state[0]
         & !pkt_fifo_rd_state[1]
	     & (tcam_rsp_result.multicast_en
	        & (|tcam_rsp_result.multicast_port[DMA_CH-1:0]) // any DMA
            & tcam_rsp_result.multicast_port[8] // user
	        )
         ) begin
        // tcam hit, multicast enabled to send to DMA & User
        tcam_rsp_fifo_rd_dma = ewadj2lu_tready[0] & ewadj2lu_tready[1];
        tcam_rsp_fifo_rd_user = ewadj2lu_tready[0] & ewadj2lu_tready[1];
        drop_detect = '0;
     end else if (!tcam_rsp_fifo_empty 
         & tcam_rsp_found 
         & !tcam_rsp_result.drop
         & !pkt_fifo_rd_state[0]
         & !pkt_fifo_rd_state[1]
	     & ( (tcam_rsp_result.multicast_en
	          & (|tcam_rsp_result.multicast_port[DMA_CH-1:0])) // multicast to DMA

	               | ((tcam_rsp_result.egr_port == PORT_E'(MSGDMA_0))
                   | (tcam_rsp_result.egr_port == PORT_E'(MSGDMA_1))    
                   | (tcam_rsp_result.egr_port == PORT_E'(MSGDMA_2))    
                   | (tcam_rsp_result.egr_port == PORT_E'(MSGDMA_3))    
                   | (tcam_rsp_result.egr_port == PORT_E'(MSGDMA_4))    
                   | (tcam_rsp_result.egr_port == PORT_E'(MSGDMA_5))    
                   | (tcam_rsp_result.egr_port == PORT_E'(MSGDMA_6))    
                   | (tcam_rsp_result.egr_port == PORT_E'(MSGDMA_7))))
         & !tcam_rsp_result.multicast_port[8] 
				) begin
       // tcam hit, egr_port or multicast is msgDMA
       tcam_rsp_fifo_rd_dma = ewadj2lu_tready[0];
       tcam_rsp_fifo_rd_user = '0;
       drop_detect = '0;
     end else if (!tcam_rsp_fifo_empty 
                  & tcam_rsp_found 
                  & !tcam_rsp_result.drop
                  & !pkt_fifo_rd_state[0]
                  & !pkt_fifo_rd_state[1]) begin
       // tcam hit, egr_port is User
       tcam_rsp_fifo_rd_dma = '0;
       tcam_rsp_fifo_rd_user = ewadj2lu_tready[1];
       drop_detect = '0;
     end else if (!tcam_rsp_fifo_empty & !pkt_fifo_rd_state[0] & !pkt_fifo_rd_state[1]) begin
       // tcam miss
       tcam_rsp_fifo_rd_dma = '1;
       tcam_rsp_fifo_rd_user = '1;
       drop_detect = '1;
     end else begin
       tcam_rsp_fifo_rd_dma = '0;
       tcam_rsp_fifo_rd_user = '0;
       drop_detect = '0; 
     end

   // tcam_rsp_fifo_rd
   tcam_rsp_fifo_rd = tcam_rsp_fifo_rd_dma | tcam_rsp_fifo_rd_user;

   end

   // pkt_fifo_rd: read at the same time of tcam_rsp_fifo_rd 
   always_comb begin
       // dma port
       if (tcam_rsp_fifo_rd_dma |
           (ewadj2lu_tready[0] & pkt_fifo_rd_state[0] & !pkt_fifo_empty)) begin
         dma_vld = '1;
       end else begin
         dma_vld = '0;
       end

       // user port
       if (tcam_rsp_fifo_rd_user |
           (ewadj2lu_tready[1] & pkt_fifo_rd_state[1] & !pkt_fifo_empty)) begin
         user_vld = '1;
       end else begin
         user_vld = '0;
       end

     pkt_tvld = dma_vld | user_vld;
     pkt_fifo_rd = pkt_tvld;
     
   end

   // tcam_rsp_drop_state : indicates in drop state based on tcam_rsp
   always_ff @(posedge clk) begin   
     if (rst) begin
       tcam_rsp_drop_state <= '0;
     end else begin
       if (drop_detect & !pkt_tuser_segment_info.eop) begin
         tcam_rsp_drop_state <= '1; // set for non-eop
       end else if (tcam_rsp_drop_state & pkt_tuser_segment_info.eop) begin
         tcam_rsp_drop_state <= '0;
       end
     end
   end

   // pkt_fifo_rd_state : indicates in middle of dequeuing pkt and stall tcam_rsp_fifo
   always_ff @(posedge clk) begin   
     if (rst) begin
       pkt_fifo_rd_state <= '0;
     end else begin
       if (tcam_rsp_fifo_rd_dma & pkt_tuser_segment_info.sop & !pkt_tuser_segment_info.eop) begin
         pkt_fifo_rd_state[0] <= '1;
       end else if (pkt_fifo_rd_state[0] & pkt_tvld & pkt_tuser_segment_info.eop) begin
         pkt_fifo_rd_state[0] <= '0;
       end

       if (tcam_rsp_fifo_rd_user & pkt_tuser_segment_info.sop & !pkt_tuser_segment_info.eop) begin
         pkt_fifo_rd_state[1] <= '1;
       end else if (pkt_fifo_rd_state[1] & pkt_tvld & pkt_tuser_segment_info.eop) begin
         pkt_fifo_rd_state[1] <= '0;
       end

     end
   end

   always_ff @(posedge clk) begin  
     egr_port_reg <= 
        pkt_tuser_segment_info.sop ? tcam_rsp_result.egr_port : egr_port_reg;

     multicast_port_reg <= 
        pkt_tuser_segment_info.sop ? tcam_rsp_result.multicast_port : multicast_port_reg;

     multicast_en_reg <= 
        pkt_tuser_segment_info.sop ? tcam_rsp_result.multicast_en : multicast_en_reg;
   end

   always_comb begin
     lu2ewadj_tvalid[0]    = (drop_detect | tcam_rsp_drop_state) ? '0 : dma_vld;
     lu2ewadj_tvalid[1]    = (drop_detect | tcam_rsp_drop_state) ? '0 : user_vld;
 
     for (int i=0; i < 2; i=i+1) begin
       lu2ewadj_tdata[i]              = pkt_tdata;
       lu2ewadj_tkeep[i]              = cal_bytesvld2tkeep(pkt_tuser_segment_info.bytesvld);
       lu2ewadj_tuser_usermetadata[i] = pkt_tuser_usermetadata;
       lu2ewadj_tuser_segment_info[i].sop = pkt_tuser_segment_info.sop;  
       lu2ewadj_tuser_segment_info[i].eop = pkt_tuser_segment_info.eop;  
       lu2ewadj_tuser_segment_info[i].sos = pkt_tuser_segment_info.sos;  
       lu2ewadj_tuser_segment_info[i].eos = pkt_tuser_segment_info.eos;  
       lu2ewadj_tuser_segment_info[i].bytesvld = pkt_tuser_segment_info.bytesvld;  
       lu2ewadj_tuser_segment_info[i].hdr_segment = pkt_tuser_segment_info.hdr_segment;  
       lu2ewadj_tuser_segment_info[i].payld_segment = pkt_tuser_segment_info.payld_segment;  
       lu2ewadj_tuser_segment_info[i].igr_port = pkt_tuser_segment_info.igr_port;  
       lu2ewadj_tuser_segment_info[i].egr_port = pkt_tuser_segment_info.sop ? tcam_rsp_result.egr_port :
                                                    egr_port_reg;
       lu2ewadj_tuser_segment_info[i].multicast_port = 
                                         pkt_tuser_segment_info.sop ? tcam_rsp_result.multicast_port :
                                           multicast_port_reg;
       lu2ewadj_tuser_segment_info[i].multicast_en = 
                                         pkt_tuser_segment_info.sop ? tcam_rsp_result.multicast_en :
					   multicast_en_reg;
     end

   end

   //--------------------------------------------------------------------------------------
   function logic [TKEEP_WIDTH-1:0] cal_bytesvld2tkeep
     (input [$clog2(TKEEP_WIDTH)-1:0] bytesvld );
      begin
	 logic [$clog2(TKEEP_WIDTH)-1:0] mty;
	 
	 logic [TKEEP_WIDTH-1:0] tmp;

	 mty = TKEEP_WIDTH[$clog2(TKEEP_WIDTH)-1:0] - bytesvld;
	 
	 tmp = '1;

	 cal_bytesvld2tkeep = tmp >> mty;	 
      end
   endfunction

endmodule
