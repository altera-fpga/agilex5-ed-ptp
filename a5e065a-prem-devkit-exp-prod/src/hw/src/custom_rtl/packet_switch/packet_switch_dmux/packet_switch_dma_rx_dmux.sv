//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


//////////////////////////////////////////////////////////////////////////////////////////////
// Description:
// msgDMA demux
//
//////////////////////////////////////////////////////////////////////////////////////////////

module packet_switch_dma_rx_dmux
   #( parameter TDATA_WIDTH                 = 64
     ,parameter NUM_SEG                     = 1
     ,parameter USERMETADATA_WIDTH          = 1
     ,parameter NUM_INTF                    = 3
     ,parameter EGR_FIFO_DEPTH              = 512
     ,parameter BASE_ADDR                   = 'h60
     ,parameter MAX_ADDR                    = 'h10
     ,parameter ADDR_WIDTH                  = 8
     ,parameter DATA_WIDTH                  = 32
     ,parameter DMA_CH                      = 3
   ) 

  (
    //----------------------------------------------------------------------------------------
    // Clocks
     input var logic                                          clk

    //----------------------------------------------------------------------------------------
    // Resets 
    ,input var logic                                          rst

    //-----------------------------------------------------------------------------------------
    // ingress interface
    ,input var logic                                          ewadj2dmux_tvalid
    ,input var logic [TDATA_WIDTH-1:0]                        ewadj2dmux_tdata
    ,input var logic [TDATA_WIDTH/8-1:0]                      ewadj2dmux_tkeep
    ,input var logic                                          ewadj2dmux_tlast
    ,input var logic [NUM_SEG-1:0]                            ewadj2dmux_tlast_segment
    ,input var logic [USERMETADATA_WIDTH-1:0]                 ewadj2dmux_tuser_usermetadata
    ,input var packet_switch_pkg::SEGMENT_INFO_S                 ewadj2dmux_tuser_segment_info
     
    // [PD] to do - use crd return
    // ,output var logic [NUM_INTF-1:0]                       axi_st_crd_ret_o
    ,output var logic                                         dmux2ewadj_tready

    //----------------------------------------------------------------------------------------
    // msgDMA RX interface
    ,output var logic [NUM_INTF-1:0]                          dmux2dma_tvalid
    ,output var logic [NUM_INTF-1:0][TDATA_WIDTH-1:0]         dmux2dma_tdata
    ,output var logic [NUM_INTF-1:0][TDATA_WIDTH/8-1:0]       dmux2dma_tkeep
    ,output var logic [NUM_INTF-1:0]                          dmux2dma_tlast
    ,output var logic [NUM_INTF-1:0][NUM_SEG-1:0]             dmux2dma_tuser_last_segment
    ,output var logic [NUM_INTF-1:0][USERMETADATA_WIDTH-1:0]  dmux2dma_tuser_usermetadata
											                 
    ,input var logic [NUM_INTF-1:0]                           dma2dmux_tready

    //-----------------------------------------------------------------------------------------
    // AVMM interface

    ,input var logic [ADDR_WIDTH-1:0]     avmm_address
    ,input var logic                      avmm_read
    ,output var logic [DATA_WIDTH-1:0]    avmm_readdata 
    ,input var logic                      avmm_write
    ,input var logic [DATA_WIDTH-1:0]     avmm_writedata
    ,input var logic [(DATA_WIDTH/8)-1:0] avmm_byteenable
    ,output var logic                     avmm_readdata_valid

    //-----------------------------------------------------------------------------------------
    // Debug drop state
    ,output var logic [7:0]               dbg_cnt_drop_en

   );
   import packet_switch_pkg::*;

   localparam TKEEP_WIDTH = TDATA_WIDTH/8;

   localparam EGR_FIFO_THRESHOLD = EGR_FIFO_DEPTH - 32;

   localparam MAX_DMA_CHANNELS = 8;

   logic rst_reg_c1, rst_reg_c2, rst_reg_posedge, rst_req_state;

   logic [MAX_DMA_CHANNELS-1:0] egr_fifo_wr;

   logic [MAX_DMA_CHANNELS-1:0] egr_fifo_rd, egr_fifo_tlast, egr_fifo_empty,
     egr_fifo_rdy, egr_fifo_overflow, egr_fifo_underflow, sop_state,
     egr_fifo_full;

   logic [MAX_DMA_CHANNELS-1:0][TDATA_WIDTH-1:0] egr_fifo_tdata;

   logic [MAX_DMA_CHANNELS-1:0][TKEEP_WIDTH-1:0] egr_fifo_tkeep;

   logic [MAX_DMA_CHANNELS-1:0][NUM_SEG-1:0] egr_fifo_tlast_segment;

   logic [MAX_DMA_CHANNELS-1:0][USERMETADATA_WIDTH-1:0] egr_fifo_tuser_usermetadata;

   logic [MAX_DMA_CHANNELS-1:0][$clog2(EGR_FIFO_DEPTH)-1:0] egr_fifo_occ;

   logic [15:0] cfg_dma_0_drop_threshold, cfg_dma_1_drop_threshold, 
     cfg_dma_2_drop_threshold;

   logic [MAX_DMA_CHANNELS-1:0][15:0] cfg_dma_drop_threshold;
   logic [MAX_DMA_CHANNELS-1:0][NUM_SEG-1:0] ewadj2dmux_tlast_segment_mod;

   logic [MAX_DMA_CHANNELS-1:0] cfg_dma_drop_en, 
     drop_thresh_state_c1, drop_thresh_state_posedge, ewadj2dmux_tlast_mod,
     drop_thresh_state;

   logic igr_pkt_state;

   logic [31:0] rst_reg;
   // Generate arrays of reset to be used in submodule
   always_ff @(posedge clk) begin
      rst_reg <= '{default:rst};
   end

   //------------------------------------------------------------------------------------------

   // generate igr_rst_reg_posedge:  
   //  - de-assert tvalid at the ingress width adjuster block
   //  - intentionally generate tlast during 
   //      igr_rst_reg_posedge cycle.

   always_ff @(posedge clk) begin
      rst_reg_c1 <= rst_reg[0];
      rst_reg_c2 <= rst_reg_c1;

      // rst_reg assertion edge detect
      rst_reg_posedge <= !rst_reg_c2 & rst_reg_c1;
   end

   always_ff @(posedge clk) begin
      if (rst_reg_posedge)
	    rst_req_state <= '1;
      
      // if (rst_reg_c2)
      if (rst_reg_c1 & !rst_reg[0])
	    rst_req_state <= '0;      
   end

   // igr_pkt_state
   always_ff @(posedge clk) begin
     if (dmux2ewadj_tready & ewadj2dmux_tvalid & ewadj2dmux_tlast)
       igr_pkt_state <= '1;
     else if (dmux2ewadj_tready & ewadj2dmux_tvalid)
       igr_pkt_state <= '0;

     if (rst)
       igr_pkt_state <= '0;
   end

   // traffic to dma is expected to have low bandwidth,
   // so the egr_fifo should be able drain out
   always_comb begin
     dmux2ewadj_tready = &egr_fifo_rdy;
    
     // write to egr_fifo targeting dma channel
     egr_fifo_wr[0] = !igr_pkt_state & drop_thresh_state_posedge[0] 
                      & ((ewadj2dmux_tuser_segment_info.multicast_en 
                           & ewadj2dmux_tuser_segment_info.multicast_port[0])
                         |(!ewadj2dmux_tuser_segment_info.multicast_en & 
                             ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_0))) ? '1 :
                      ewadj2dmux_tvalid 
                      & dmux2ewadj_tready
                      & !drop_thresh_state[0]
                      & ((ewadj2dmux_tuser_segment_info.multicast_en 
                           & ewadj2dmux_tuser_segment_info.multicast_port[0])
                         |(!ewadj2dmux_tuser_segment_info.multicast_en & 
                             ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_0)));
      if (DMA_CH >= 2)
     egr_fifo_wr[1] = !igr_pkt_state & drop_thresh_state_posedge[1] 
                      & ((ewadj2dmux_tuser_segment_info.multicast_en 
                           & ewadj2dmux_tuser_segment_info.multicast_port[1])
                         |(!ewadj2dmux_tuser_segment_info.multicast_en & 
                             ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_1))) ? '1 :
                      ewadj2dmux_tvalid 
                      & dmux2ewadj_tready
                      & !drop_thresh_state[1]
                      & ((ewadj2dmux_tuser_segment_info.multicast_en 
                           & ewadj2dmux_tuser_segment_info.multicast_port[1])
                         |(!ewadj2dmux_tuser_segment_info.multicast_en & 
                             ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_1)));
       else
      egr_fifo_wr[1] = '0;

      if (DMA_CH >= 3)
     egr_fifo_wr[2] = !igr_pkt_state & drop_thresh_state_posedge[2] 
                      & ((ewadj2dmux_tuser_segment_info.multicast_en 
                           & ewadj2dmux_tuser_segment_info.multicast_port[2])
                         |(!ewadj2dmux_tuser_segment_info.multicast_en & 
                             ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_2))) ? '1 :
                      ewadj2dmux_tvalid 
                      & dmux2ewadj_tready
                      & !drop_thresh_state[2]
                      & ((ewadj2dmux_tuser_segment_info.multicast_en 
                           & ewadj2dmux_tuser_segment_info.multicast_port[2])
                         |(!ewadj2dmux_tuser_segment_info.multicast_en & 
                             ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_2)));
       else
      egr_fifo_wr[2] = '0;
   

     // ----------------------------------------
     // below are reserved
      if (DMA_CH >= 4)
     egr_fifo_wr[3] = !igr_pkt_state & drop_thresh_state_posedge[3]
                      & ((ewadj2dmux_tuser_segment_info.multicast_en 
                           & ewadj2dmux_tuser_segment_info.multicast_port[3])
                         |(!ewadj2dmux_tuser_segment_info.multicast_en & 
                             ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_3))) ? '1 :
                      ewadj2dmux_tvalid 
                      & dmux2ewadj_tready
                      & !drop_thresh_state[3]
                      & ((ewadj2dmux_tuser_segment_info.multicast_en 
                           & ewadj2dmux_tuser_segment_info.multicast_port[3])
                         |(!ewadj2dmux_tuser_segment_info.multicast_en & 
                             ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_3)));
       else
      egr_fifo_wr[3] = '0;

      if (DMA_CH >= 5)
     egr_fifo_wr[4] = !igr_pkt_state & drop_thresh_state_posedge[4] 
                      & ((ewadj2dmux_tuser_segment_info.multicast_en 
                           & ewadj2dmux_tuser_segment_info.multicast_port[4])
                         |(!ewadj2dmux_tuser_segment_info.multicast_en & 
                             ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_4))) ? '1 :
                      ewadj2dmux_tvalid 
                      & dmux2ewadj_tready
                      & !drop_thresh_state[4]
                      & ((ewadj2dmux_tuser_segment_info.multicast_en 
                           & ewadj2dmux_tuser_segment_info.multicast_port[4])
                         |(!ewadj2dmux_tuser_segment_info.multicast_en & 
                             ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_4)));
       else
      egr_fifo_wr[4] = '0;

      if (DMA_CH >= 6)
     egr_fifo_wr[5] = !igr_pkt_state & drop_thresh_state_posedge[5] 
                      & ((ewadj2dmux_tuser_segment_info.multicast_en 
                           & ewadj2dmux_tuser_segment_info.multicast_port[5])
                         |(!ewadj2dmux_tuser_segment_info.multicast_en & 
                             ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_5))) ? '1 :
                      ewadj2dmux_tvalid 
                      & dmux2ewadj_tready
                      & !drop_thresh_state[5]
                      & ((ewadj2dmux_tuser_segment_info.multicast_en 
                           & ewadj2dmux_tuser_segment_info.multicast_port[5])
                         |(!ewadj2dmux_tuser_segment_info.multicast_en & 
                             ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_5)));
       else
      egr_fifo_wr[5] = '0;

      if (DMA_CH >= 7)     
     egr_fifo_wr[6] = !igr_pkt_state & drop_thresh_state_posedge[6] 
                      & ((ewadj2dmux_tuser_segment_info.multicast_en 
                           & ewadj2dmux_tuser_segment_info.multicast_port[6])
                         |(!ewadj2dmux_tuser_segment_info.multicast_en & 
                             ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_6))) ? '1 :
                      ewadj2dmux_tvalid 
                      & dmux2ewadj_tready
                      & !drop_thresh_state[6]
                      & ((ewadj2dmux_tuser_segment_info.multicast_en 
                           & ewadj2dmux_tuser_segment_info.multicast_port[6])
                         |(!ewadj2dmux_tuser_segment_info.multicast_en & 
                             ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_6)));
       else
      egr_fifo_wr[6] = '0;

      if (DMA_CH == 8)
     egr_fifo_wr[7] = !igr_pkt_state & drop_thresh_state_posedge[7] 
                      & ((ewadj2dmux_tuser_segment_info.multicast_en 
                           & ewadj2dmux_tuser_segment_info.multicast_port[7])
                         |(!ewadj2dmux_tuser_segment_info.multicast_en & 
                             ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_7))) ? '1 :
                      ewadj2dmux_tvalid 
                      & dmux2ewadj_tready
                      & !drop_thresh_state[7]
                      & ((ewadj2dmux_tuser_segment_info.multicast_en 
                           & ewadj2dmux_tuser_segment_info.multicast_port[7])
                         |(!ewadj2dmux_tuser_segment_info.multicast_en & 
                             ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_7)));
       else
      egr_fifo_wr[7] = '0;
    
   end

   always_comb begin
    for (int i=0; i < MAX_DMA_CHANNELS; i++) begin
     ewadj2dmux_tlast_mod[i] = drop_thresh_state_posedge[i] ? '1 : ewadj2dmux_tlast;
     ewadj2dmux_tlast_segment_mod[i] = drop_thresh_state_posedge[i] ? 'h1 : ewadj2dmux_tlast_segment;
    end // for
   end
 
   // drop threshold state : assert tlast
   always_ff @(posedge clk) begin
     for (int i=0; i < MAX_DMA_CHANNELS; i++) begin
      if (cfg_dma_drop_en[i]
          & ewadj2dmux_tvalid 
          & !ewadj2dmux_tlast
          & !drop_thresh_state[i]
          & {7'b0,egr_fifo_occ[i]} > cfg_dma_drop_threshold[i])
        drop_thresh_state[i] <= 1'b1;
      else if (({7'b0,egr_fifo_occ[i]} <= cfg_dma_drop_threshold[i])
               & ewadj2dmux_tlast) // below threshold + received eop
        drop_thresh_state[i] <= 1'b0;

      drop_thresh_state_c1[i] <= drop_thresh_state[i];
     end // for

      if (rst_reg[1])
	    drop_thresh_state <= '0;      
   end

   always_comb begin
     for (int i=0; i < MAX_DMA_CHANNELS; i++) begin
       drop_thresh_state_posedge[i] = !drop_thresh_state_c1[i] & drop_thresh_state[i];
     end
   end

     //------------------------------------------------------------------------------------------
     // mid reset condition : assert tlast

      // generate sop_state detection per egr interface:
      always_ff @(posedge clk) begin
       for (int i=0; i < NUM_INTF; i++) begin
         if (dmux2dma_tvalid[i] & dma2dmux_tready[i] & sop_state[i])
	       sop_state[i] <= '0;
         else if (dmux2dma_tvalid[i] & dmux2dma_tlast[i] & dma2dmux_tready[i])
	       sop_state[i] <= '1;
         
         if (rst_reg[2])
	       sop_state[i] <= '1;     
       end 
      end

      always_comb begin
       for (int i=0; i < NUM_INTF; i++) begin
        dmux2dma_tvalid[i] = (rst_reg_posedge & !sop_state[i]) ? '1 :
 				            rst_req_state ? '0 : !egr_fifo_empty[i];
        dmux2dma_tdata[i] = egr_fifo_tdata[i];
        dmux2dma_tkeep[i] = (rst_reg_posedge & !sop_state[i]) ? '1 :
                             egr_fifo_tkeep[i];
        dmux2dma_tlast[i] = (rst_reg_posedge & !sop_state[i]) ? '1 :
 				            rst_req_state ? '0 : egr_fifo_tlast[i];
        dmux2dma_tuser_last_segment[i] = (rst_reg_posedge & !sop_state[i]) ? NUM_SEG-1 :
 				            rst_req_state ? '0 : egr_fifo_tlast_segment[i];
        dmux2dma_tuser_usermetadata[i] = egr_fifo_tuser_usermetadata[i];

       end
      end // always_comb

     //------------------------------------------------------------------------------------------
	logic [MAX_DMA_CHANNELS-1:0] dma2dmux_tready_int;
	
	assign dma2dmux_tready_int = {5'b0, dma2dmux_tready}; //extra DMA channels rdy (8-3) set to 0
	
	always_comb begin
		for (int i=0; i < MAX_DMA_CHANNELS; i++) begin
			egr_fifo_rd[i] = dma2dmux_tready_int[i] 
					& !egr_fifo_empty[i]; 

		end
	end
	always_ff @(posedge clk) begin
		for (int i=0; i < MAX_DMA_CHANNELS; i++) begin
			egr_fifo_rdy[i] <= egr_fifo_occ[i] < EGR_FIFO_THRESHOLD;
		end
	end
	
   genvar i;
   generate
     for (i=0; i < MAX_DMA_CHANNELS; i++) begin : gen_egr_fifo
       packet_switch_ipbb_sdc_fifo_inff 
         #( .DWD ( TDATA_WIDTH
                  +TKEEP_WIDTH
                  +USERMETADATA_WIDTH
                  +1
                  +NUM_SEG
                  )
           ,.NUM_WORDS (EGR_FIFO_DEPTH) ) egr_fifo
         (//------------------------------------------------------------------------------------
          // clk/rst
          .clk1 (clk)
          ,.clk2 (clk)
          ,.rst (rst_reg[3])
       
          // inputs
          ,.din ({ ewadj2dmux_tdata
                  ,ewadj2dmux_tkeep
                  ,ewadj2dmux_tuser_usermetadata
                  ,ewadj2dmux_tlast_mod[i]
                  ,ewadj2dmux_tlast_segment_mod[i]
                 })
          ,.wrreq (egr_fifo_wr[i])
          ,.rdreq (egr_fifo_rd[i])
       
          // outputs
          ,.dout ({ egr_fifo_tdata[i]
                   ,egr_fifo_tkeep[i]
                   ,egr_fifo_tuser_usermetadata[i]
                   ,egr_fifo_tlast[i]
                   ,egr_fifo_tlast_segment[i]
                  }) 
          ,.rdempty (egr_fifo_empty[i]) 
          ,.rdempty_lkahd () 
          ,.wrfull (egr_fifo_full[i])
          ,.wrusedw (egr_fifo_occ[i])
          ,.overflow (egr_fifo_overflow[i])
          ,.underflow (egr_fifo_underflow[i])
          );
       
        
         end // for (int i=0; i < NUM_INTF; i=i+1)
   endgenerate

   dma_rx_dmux_csr_intf
   #( .BASE_ADDR (BASE_ADDR) 
     ,.MAX_ADDR (MAX_ADDR)
     ,.ADDR_WIDTH (ADDR_WIDTH)
     ,.DATA_WIDTH (DATA_WIDTH) ) csr_intf
   (//------------------------------------------------------------------------------------
    // Clock
    // input
    .clk (clk)

    // Reset
    ,.rst (rst_reg[4])

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
    // CSR Drop enable and Drop threshold
    // outputs
    ,.cfg_dma_0_drop_en        (cfg_dma_drop_en[0]       )
    ,.cfg_dma_1_drop_en        (cfg_dma_drop_en[1]       )
    ,.cfg_dma_2_drop_en        (cfg_dma_drop_en[2]       )
    ,.cfg_dma_0_drop_threshold (cfg_dma_drop_threshold[0])
    ,.cfg_dma_1_drop_threshold (cfg_dma_drop_threshold[1])
    ,.cfg_dma_2_drop_threshold (cfg_dma_drop_threshold[2])

   );
   
	always_comb begin
		cfg_dma_drop_en[MAX_DMA_CHANNELS-1:3] = 0; //additional DMA chbl cfg,not needed for current design
		cfg_dma_drop_threshold[MAX_DMA_CHANNELS-1:3] = 0; //additional DMA chbl cfg,not needed for current design
	end

   logic [MAX_DMA_CHANNELS-1:0] dbg_cnt_drop_en_w;

   // Debug counter enable
   always_comb begin
     if ( drop_thresh_state[0] 
         & (ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_0))
         & ewadj2dmux_tvalid 
         & ewadj2dmux_tlast) // eop
          dbg_cnt_drop_en_w[0] = '1; 
     else 
          dbg_cnt_drop_en_w[0] = '0; 

     if ( drop_thresh_state[1] 
         & (ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_1))
         & ewadj2dmux_tvalid 
         & ewadj2dmux_tlast) // eop
          dbg_cnt_drop_en_w[1] = '1; 
     else 
          dbg_cnt_drop_en_w[1] = '0; 

     if ( drop_thresh_state[2] 
         & (ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_2))
         & ewadj2dmux_tvalid 
         & ewadj2dmux_tlast) // eop
          dbg_cnt_drop_en_w[2] = '1; 
     else 
          dbg_cnt_drop_en_w[2] = '0; 

     if ( drop_thresh_state[3] 
         & (ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_3))
         & ewadj2dmux_tvalid 
         & ewadj2dmux_tlast) // eop
          dbg_cnt_drop_en_w[3] = '1; 
     else 
          dbg_cnt_drop_en_w[3] = '0; 

     if ( drop_thresh_state[4] 
         & (ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_4))
         & ewadj2dmux_tvalid 
         & ewadj2dmux_tlast) // eop
          dbg_cnt_drop_en_w[4] = '1; 
     else 
          dbg_cnt_drop_en_w[4] = '0; 

     if ( drop_thresh_state[5] 
         & (ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_5))
         & ewadj2dmux_tvalid 
         & ewadj2dmux_tlast) // eop
          dbg_cnt_drop_en_w[5] = '1; 
     else 
          dbg_cnt_drop_en_w[5] = '0; 

     if ( drop_thresh_state[6] 
         & (ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_6))
         & ewadj2dmux_tvalid 
         & ewadj2dmux_tlast) // eop
          dbg_cnt_drop_en_w[6] = '1; 
     else 
          dbg_cnt_drop_en_w[6] = '0; 

     if ( drop_thresh_state[7] 
         & (ewadj2dmux_tuser_segment_info.egr_port == PORT_E'(MSGDMA_7))
         & ewadj2dmux_tvalid 
         & ewadj2dmux_tlast) // eop
          dbg_cnt_drop_en_w[7] = '1; 
     else 
          dbg_cnt_drop_en_w[7] = '0; 

   end // always_comb

   always_ff @ (posedge clk)
     dbg_cnt_drop_en <= dbg_cnt_drop_en_w;
	
endmodule