//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

//---------------------------------------------------------------------------------------------
// Description: This is the tx path of PTP Switch System Example Design(packet_switch_tx.sv)			
// 	- All the tx path parameters & Interfaces listed in here		
//	- In this module, the following blocks are integrated
//		Igr_wadj	    --> packet_switch_tx_igr_wadj.sv
//		Igr_arb	        --> packet_switch_igr_arb.sv
//		timestamp demux --> packet_switch_dma_ts_dmux.sv
//--------------------------------------------------------------------------------------------			

module packet_switch_tx
  #(   
	 parameter NUM_PIPELINE                    = 2   //should be equal to HSSI/USER ports
	,parameter DMA_CHNL                        = 6   //DMA channels 
	
	,parameter DMA_DATA_WIDTH                  = 64   // supports only 64b
    ,parameter USER_DATA_WIDTH                 = 256  // supports 64/128/256b
    ,parameter HSSI_DATA_WIDTH	               = 256  // supports 64/128/256b
    
    ,parameter DMA_NUM_OF_SEG                  = 1    // supports only 1
    ,parameter HSSI_NUM_OF_SEG                 = 4    // supports only 1/2/4
    ,parameter USER_NUM_OF_SEG                 = 4    // supports only 1/2/4

    ,parameter USER_IGR_FIFO_DEPTH             = 512
    ,parameter DMA_IGR_FIFO_DEPTH              = 512

    ,parameter TX_CLIENT_WIDTH                 = 2
	
    ,parameter TXEGR_TS_DW                     = 128

    ,parameter SYS_FINGERPRINT_WIDTH           = 20 // system specified fingerprint width. max:28.
	
    ,parameter PTP_WIDTH                       = 94
    ,parameter PTP_EXT_WIDTH                   = 328
	
    ,parameter AWADDR_WIDTH                    = 32
    ,parameter WDATA_WIDTH                     = 32	
	
    ,parameter DMA_CHNL_PER_PIPE               = DMA_CHNL/NUM_PIPELINE	

    ,parameter IGR_DMA_BYTE_ROTATE             = 0
    ,parameter IGR_USER_BYTE_ROTATE            = 0
    ,parameter EGR_HSSI_BYTE_ROTATE            = 0
    ,parameter CNTR_WIDTH                      = 32
    ,parameter DBG_CNTR_EN                     = 0
    )

   ( //---------------------------------------------------------------------------------------
	     
	// Tx streaming clock
     input var logic [NUM_PIPELINE-1:0]               axi_st_clk
    ,input var logic [NUM_PIPELINE-1:0]               axi_st_rst_n	
    //----------------------------------------------------------------------------------------- 
    // init_done status
    ,output var logic [NUM_PIPELINE-1:0]              init_done	
    //-----------------------------------------------------------------------------------------
    // AVMM: sync to axi_st_clk
    //-----ADDRESS-------           
	,input var logic [NUM_PIPELINE-1:0][AWADDR_WIDTH-1:0]           avmm_address
    //---------------------------------                 
    //-----WRITE DATA------------------                  
    ,input var logic [NUM_PIPELINE-1:0]                             avmm_write
    ,input var logic [NUM_PIPELINE-1:0][WDATA_WIDTH-1:0]            avmm_writedata
    ,input var logic [NUM_PIPELINE-1:0][(WDATA_WIDTH/8)-1:0]        avmm_byteenable
    //---------------------------------                 
    //-----READ DATA-------------------          
    ,input var logic [NUM_PIPELINE-1:0]                             avmm_read												 
    ,output var logic [NUM_PIPELINE-1:0][WDATA_WIDTH-1:0]           avmm_readdata 
    ,output var logic [NUM_PIPELINE-1:0]                            avmm_readdata_valid
    //-----------------------------------------------------------------------------------------     
    //=========================================================================================
    // TX Interface:  
    //-----------------------------------------------------------------------------------------
    // tx ingress interface - Input from DMA
    ,input var logic [DMA_CHNL-1:0]                                  dma_tvalid_i
    ,input var logic [DMA_CHNL-1:0][DMA_DATA_WIDTH-1:0]              dma_tdata_i
    ,input var logic [DMA_CHNL-1:0][DMA_DATA_WIDTH/8-1:0]            dma_tkeep_i
    ,input var logic [DMA_CHNL-1:0]                                  dma_tlast_i
    ,input var logic [DMA_CHNL-1:0][PTP_WIDTH -1:0]                  dma_tuser_ptp_i
    ,input var logic [DMA_CHNL-1:0][PTP_EXT_WIDTH -1:0]              dma_tuser_ptp_extended_i
    ,input var logic [DMA_CHNL-1:0][DMA_NUM_OF_SEG-1:0]
                                     [TX_CLIENT_WIDTH-1:0]           dma_tuser_client_i
    ,input var logic [DMA_CHNL-1:0][DMA_NUM_OF_SEG-1:0]              dma_tuser_pkt_seg_parity_i
    ,input var logic [DMA_CHNL-1:0][DMA_NUM_OF_SEG-1:0]              dma_tuser_last_segment_i
																     
    ,output var logic [DMA_CHNL-1:0]                                 dma_tready_o
	//-----------------------------------------------------------------------------------------
    // tx ingress interface - Input from USER
    ,input var logic [NUM_PIPELINE-1:0]                              user_tvalid_i
    ,input var logic [NUM_PIPELINE-1:0][USER_DATA_WIDTH-1:0]         user_tdata_i
    ,input var logic [NUM_PIPELINE-1:0][USER_DATA_WIDTH/8-1:0]       user_tkeep_i
    ,input var logic [NUM_PIPELINE-1:0]                              user_tlast_i
    ,input var logic [NUM_PIPELINE-1:0][PTP_WIDTH -1:0]              user_tuser_ptp_i
    ,input var logic [NUM_PIPELINE-1:0][PTP_EXT_WIDTH -1:0]          user_tuser_ptp_extended_i
    ,input var logic [NUM_PIPELINE-1:0][USER_NUM_OF_SEG-1:0]
                                         [TX_CLIENT_WIDTH-1:0]       user_tuser_client_i
    ,input var logic [NUM_PIPELINE-1:0][USER_NUM_OF_SEG-1:0]         user_tuser_pkt_seg_parity_i
    ,input var logic [NUM_PIPELINE-1:0][USER_NUM_OF_SEG-1:0]         user_tuser_last_segment_i
												   
    ,output var logic [NUM_PIPELINE-1:0]                             user_tready_o

    //-----------------------------------------------------------------------------------------
    // tx egress interface - Outputs to HSSI
    ,output var logic [NUM_PIPELINE-1:0]                             hssi_tvalid_o
    ,output var logic [NUM_PIPELINE-1:0][HSSI_DATA_WIDTH-1:0]        hssi_tdata_o
    ,output var logic [NUM_PIPELINE-1:0][HSSI_DATA_WIDTH/8-1:0]      hssi_tkeep_o
    ,output var logic [NUM_PIPELINE-1:0]                             hssi_tlast_o
    ,output var logic [NUM_PIPELINE-1:0][PTP_WIDTH -1:0]             hssi_tuser_ptp_o
    ,output var logic [NUM_PIPELINE-1:0][PTP_EXT_WIDTH -1:0]         hssi_tuser_ptp_extended_o
    ,output var logic [NUM_PIPELINE-1:0][HSSI_NUM_OF_SEG-1:0]
                                          [TX_CLIENT_WIDTH-1:0]      hssi_tuser_client_o
    ,output var logic [NUM_PIPELINE-1:0][HSSI_NUM_OF_SEG-1:0]        hssi_tuser_pkt_seg_parity_o
    ,output var logic [NUM_PIPELINE-1:0][HSSI_NUM_OF_SEG-1:0]        hssi_tuser_last_segment_o
																		  
    ,input var logic  [NUM_PIPELINE-1:0]                             hssi_tready_i

    
    //=========================================================================================
    // Time Stamp Interface
    //-----------------------------------------------------------------------------------------
    // tx egress timestamp from HSSI
    ,input var logic [NUM_PIPELINE-1:0]                              hssi_egrts0_tvalid_i
    ,input var logic [NUM_PIPELINE-1:0][TXEGR_TS_DW-1:0]             hssi_egrts0_tdata_i
    ,input var logic [NUM_PIPELINE-1:0]                              hssi_egrts1_tvalid_i
    ,input var logic [NUM_PIPELINE-1:0][TXEGR_TS_DW-1:0]             hssi_egrts1_tdata_i
															      
     // tx egress timestamp to DMA                                
    ,output var logic [DMA_CHNL-1:0]                                 dma_egrts0_tvalid_o
    ,output var logic [DMA_CHNL-1:0][TXEGR_TS_DW-1:0]                dma_egrts0_tdata_o
    ,output var logic [DMA_CHNL-1:0]                                 dma_egrts1_tvalid_o
    ,output var logic [DMA_CHNL-1:0][TXEGR_TS_DW-1:0]                dma_egrts1_tdata_o
															      
     // tx egress timestamp to USER                               
    ,output var logic [NUM_PIPELINE-1:0]                             user_egrts0_tvalid_o
    ,output var logic [NUM_PIPELINE-1:0][TXEGR_TS_DW-1:0]            user_egrts0_tdata_o
    ,output var logic [NUM_PIPELINE-1:0]                             user_egrts1_tvalid_o
    ,output var logic [NUM_PIPELINE-1:0][TXEGR_TS_DW-1:0]            user_egrts1_tdata_o

   );

   import packet_switch_pkg::*;
   import packet_switch_hdr_pkg::*;
   
	//====================================================================
	//local parameters
	localparam TX_TUSER_CLIENT_WIDTH     = TX_CLIENT_WIDTH;
	localparam TUSER_PTP_WIDTH           = PTP_WIDTH;
	localparam TUSER_PTP_EXT_WIDTH       = PTP_EXT_WIDTH;
	localparam HSSI_SEG_PARITY_WIDTH     = HSSI_NUM_OF_SEG;
	localparam DMA_SEG_PARITY_WIDTH      = DMA_NUM_OF_SEG;
	localparam USER_SEG_PARITY_WIDTH     = USER_NUM_OF_SEG;

	localparam TX_DMA_TUSER_MD_WIDTH =  TX_TUSER_CLIENT_WIDTH*DMA_NUM_OF_SEG
				   +TUSER_PTP_WIDTH
				   +TUSER_PTP_EXT_WIDTH
				   +DMA_SEG_PARITY_WIDTH;

    localparam TX_HSSI_TUSER_MD_WIDTH =  TX_TUSER_CLIENT_WIDTH*HSSI_NUM_OF_SEG
				    +TUSER_PTP_WIDTH
				    +TUSER_PTP_EXT_WIDTH
					+HSSI_SEG_PARITY_WIDTH;

    localparam TX_USER_TUSER_MD_WIDTH =  TX_TUSER_CLIENT_WIDTH*USER_NUM_OF_SEG
				    +TUSER_PTP_WIDTH
				    +TUSER_PTP_EXT_WIDTH
					+USER_SEG_PARITY_WIDTH;
	
	
	localparam NUM_IGR_INTF = DMA_CHNL_PER_PIPE+1;
	
	// localparam IGR_IFIFO_DEPTH        = (HSSI_DATA_WIDTH == 64) ? 2048 : 4096;
	// localparam IFIFO_DEPTH            = 512;
	localparam EFIFO_DEPTH            = 512;
	localparam EFIFO_TS_DEPTH         = 4;
	
	localparam CYC_CNT = (DMA_NUM_OF_SEG > HSSI_NUM_OF_SEG) ? DMA_NUM_OF_SEG/HSSI_NUM_OF_SEG :
			                        HSSI_NUM_OF_SEG/DMA_NUM_OF_SEG  ;
    localparam CYC_CNT_WIDTH = $clog2(CYC_CNT);
   
	localparam HDR_CYCLE_CNT   = 2;
    localparam PAYLD_CYCLE_CNT = CYC_CNT - HDR_CYCLE_CNT;
	
	localparam BYTESVLD_WIDTH = $clog2((HSSI_NUM_OF_SEG*64)/8);  //64 is SEGMENT_WIDTH
	
	localparam FINGERPRINT_FLD_WIDTH    = 32; // total available fingerprint field width.
    // localparam SYS_FINGERPRINT_WIDTH    = 20; // user specified fingerprint width. max:28.
	localparam TX_TS_DW                 = 96;
    localparam TS_DMUX_DATA_WIDTH = TX_TS_DW + FINGERPRINT_FLD_WIDTH; //same as TXEGR_TS_DW

    localparam MAX_NUM_PIPELINE = packet_switch_pkg::MAX_HSSI_PORTS; //8

    localparam EGR_TS_INTF = packet_switch_pkg::MAX_DMA_CH + 1; //8+1

   localparam TX_FP_START_INDEX = 14 + SYS_FINGERPRINT_WIDTH;
   localparam TX_FP_SELECT = TX_FP_START_INDEX+packet_switch_pkg::PORTS_WIDTH;

	//----------------------------------------------------------------------------------
	//user metadata merged signals
	logic [DMA_CHNL-1:0][TX_DMA_TUSER_MD_WIDTH -1:0]  iwadj_tx_tuser_md_i;
	logic [DMA_CHNL-1:0][TX_HSSI_TUSER_MD_WIDTH -1:0] iwadj_tx_tuser_md;
	logic [NUM_PIPELINE-1:0][TX_USER_TUSER_MD_WIDTH-1:0] user_tx_tuser_md_i;
		  
	//output from DMA wadj
    logic [DMA_CHNL-1:0]                        iwadj_tx_tvalid;
    logic [DMA_CHNL-1:0][HSSI_DATA_WIDTH-1:0]   iwadj_tx_tdata;
    logic [DMA_CHNL-1:0][HSSI_DATA_WIDTH/8-1:0] iwadj_tx_tkeep;
    logic [DMA_CHNL-1:0]                        iwadj_tx_tlast;
    logic [DMA_CHNL-1:0]
		  [HSSI_DATA_WIDTH/DMA_DATA_WIDTH-1:0]  iwadj_tx_tuser_last_segment;
								
    logic [DMA_CHNL-1:0]                        iwadj_tx_tready;	  
	//merged output of wadj(DMA)
    logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]      dma2iarb_tx_tvalid;
    logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]      
							[HSSI_DATA_WIDTH-1:0]        dma2iarb_tx_tdata;
    logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]      
							[HSSI_DATA_WIDTH/8-1:0]      dma2iarb_tx_tkeep;
    logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]      dma2iarb_tx_tlast;
    logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]      
		  [HSSI_DATA_WIDTH/DMA_DATA_WIDTH-1:0]           dma2iarb_tx_tuser_last_segment;
    logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]
							[TX_HSSI_TUSER_MD_WIDTH-1:0] dma2iarb_tx_tuser_md;
															
    logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]      iarb2iwadj_tx_tready;
    logic [DMA_CHNL-1:0]                                 iwadj_fifo_pop, iwadj_fifo_empty,
                                                         iwadj_sop_detect;
	
    //Input from USER
    logic [NUM_PIPELINE-1:0][USER_DATA_WIDTH-1:0]         user_fifo_tdata_o;
    logic [NUM_PIPELINE-1:0][USER_DATA_WIDTH/8-1:0]       user_fifo_tkeep_o;
    logic [NUM_PIPELINE-1:0]                              user_fifo_tlast_o;
    logic [NUM_PIPELINE-1:0][USER_NUM_OF_SEG-1:0]         user_fifo_tlast_segment_o;
								   
    logic [NUM_PIPELINE-1:0]                              user_tx_tready;	
	
	//arb output to hssi
	logic [NUM_PIPELINE-1:0][HSSI_NUM_OF_SEG-1:0]
							[TX_TUSER_CLIENT_WIDTH-1:0]   hssi_tx_tuser_client_o;
	logic [NUM_PIPELINE-1:0][HSSI_SEG_PARITY_WIDTH-1:0]   hssi_tx_tuser_pkt_seg_parity_o;
	logic [NUM_PIPELINE-1:0][TUSER_PTP_WIDTH-1:0]         hssi_tx_tuser_ptp_o;
	logic [NUM_PIPELINE-1:0][TUSER_PTP_EXT_WIDTH -1:0]    hssi_tx_tuser_ptp_extended_o;
	
	
	//arbiter Interfaces
	//ingress
	logic [NUM_PIPELINE-1:0][NUM_IGR_INTF-1:0]           ing2iarb_tvalid, 
													     ing2iarb_tlast, 
														 iarb2ing_tready,
                                                         iarb2iwadj_fifo_pop, 
                                                         ing2iarb_fifo_empty,
                                                         ing2iarb_sop_detect;
	logic [NUM_PIPELINE-1:0][NUM_IGR_INTF-1:0]
							[HSSI_DATA_WIDTH-1:0]        ing2iarb_tdata;
	logic [NUM_PIPELINE-1:0][NUM_IGR_INTF-1:0]
							[HSSI_DATA_WIDTH/8-1:0]      ing2iarb_tkeep;
	logic [NUM_PIPELINE-1:0][NUM_IGR_INTF-1:0]
							[TX_HSSI_TUSER_MD_WIDTH-1:0]  ing2iarb_tuser_usermetadata;
	packet_switch_pkg::SEGMENT_INFO_S
	[NUM_PIPELINE-1:0][NUM_IGR_INTF-1:0]    	         ing2iarb_tuser_segment_info; 

    packet_switch_pkg::SEGMENT_INFO_S [DMA_CHNL-1:0]        iwadj_tuser_segment_info;
    packet_switch_pkg::SEGMENT_INFO_S                       unused_tuser_segment_info;
	// logic [NUM_IGR_INTF-1:0]                          axi_st_crd_ret_o;
	//egress
	logic [NUM_PIPELINE-1:0]                             iarb2hssi_tvalid;
	logic [NUM_PIPELINE-1:0][HSSI_DATA_WIDTH-1:0]        iarb2hssi_tdata;
	logic [NUM_PIPELINE-1:0][HSSI_DATA_WIDTH/8-1:0]      iarb2hssi_tkeep;
	logic [NUM_PIPELINE-1:0][TX_HSSI_TUSER_MD_WIDTH-1:0] iarb2hssi_tuser_usermetadata;
	packet_switch_pkg::SEGMENT_INFO_S [NUM_PIPELINE-1:0]    iarb2hssi_tuser_segment_info;
	
	logic [NUM_PIPELINE-1:0]                             dmux2hssi_tready;
														 
	logic [NUM_PIPELINE-1:0]                             hssi2dmx_ts_tvalid;
	logic [NUM_PIPELINE-1:0][TS_DMUX_DATA_WIDTH-1:0]     hssi2dmx_ts_tdata;
														 
	logic [NUM_PIPELINE-1:0][NUM_IGR_INTF-1:0]           dmux2egrpt_tvalid;
	logic [NUM_PIPELINE-1:0][NUM_IGR_INTF-1:0]          
							[TS_DMUX_DATA_WIDTH-1:0]     dmux2egrpt_tdata;
	
	logic [NUM_PIPELINE-1:0]                             user_egrts_tvalid;
	logic [NUM_PIPELINE-1:0][TS_DMUX_DATA_WIDTH-1:0]     user_egrts_tdata;
	logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]      dma_egrts_tvalid;
	logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]
							[TS_DMUX_DATA_WIDTH-1:0]     dma_egrts_tdata;
							
	logic [NUM_PIPELINE-1:0][WDATA_WIDTH-1:0]	          iarb_avmm_rdata;
	logic [MAX_NUM_PIPELINE-1:0][WDATA_WIDTH-1:0]	      iarb_avmm_rdata_tmp;
	logic [NUM_PIPELINE-1:0]                 	          iarb_avmm_rdata_vld;
	logic [MAX_NUM_PIPELINE-1:0]                 	      iarb_avmm_rdata_vld_tmp;
    
  logic [NUM_PIPELINE-1:0][WDATA_WIDTH-1:0]               dbg_avmm_rdata_tmp;
  logic  [NUM_PIPELINE-1:0]                               dbg_avmm_rdata_vld_tmp;

    logic [NUM_PIPELINE-1:0][EGR_TS_INTF-1:0]             dmux2egrpt0_tvalid, 
                                                          dmux2egrpt1_tvalid;
    logic [NUM_PIPELINE-1:0][EGR_TS_INTF-1:0]
            [TXEGR_TS_DW-1:0]                             dmux2egrpt0_tdata, 
                                                          dmux2egrpt1_tdata;
 
   logic [NUM_PIPELINE-1:0][MAX_DMA_CH-1:0]
           [PTP_WIDTH-1:0]                                dma_tuser_ptp_tmp;

   logic [DMA_CHNL-1:0][PTP_WIDTH-1:0]                    dma_tuser_ptp_mod;

   logic [NUM_PIPELINE-1:0][USER_DATA_WIDTH-1:0]          user_tdata_byte_rotate;

   logic [MAX_NUM_PIPELINE-1:0][PTP_WIDTH-1:0]            user_tuser_ptp_mod;

   logic [NUM_PIPELINE-1:0]                              unused_user_fifo_pop;		

	logic [NUM_PIPELINE-1:0] user_pkt_state;

    packet_switch_pkg::SEGMENT_INFO_S [NUM_PIPELINE-1:0] user_tuser_segment_info;
	
	logic [NUM_PIPELINE-1:0] tx_clk, tx_rst;
	logic [NUM_PIPELINE-1:0] tx_rst_reg;
    logic [NUM_PIPELINE-1:0][4:0] init_cnt;
	
	//clock
	always_comb begin
	  tx_clk = axi_st_clk;
	end

    genvar i;
    generate 
     for (i = 0; i < NUM_PIPELINE; i++) begin : gen_rst_sync_misc

	// tx_reset
	ipbb_asyn_to_syn_rst rst_sync
	 (.clk (tx_clk[i])
	  ,.asyn_rst (!axi_st_rst_n[i])

	  // output
	  ,.syn_rst (tx_rst[i])
	  ); 

	//init done status
	always_ff @(posedge axi_st_clk[i]) begin
      if (!init_cnt[i][4])
        init_cnt[i] <= init_cnt[i] + 1'b1;

      init_done[i] <= init_cnt[i][4];

     if (tx_rst[i]) 
       init_cnt[i] <= '0;
    end // always_ff
	 
	// Generate arrays of reset to be used in submodules
	always_ff @(posedge tx_clk[i]) begin
	  tx_rst_reg[i] <= tx_rst[i];
	end // always_ff

    // user_pkt_state
	always_ff @(posedge tx_clk[i]) begin	
	  if (tx_rst_reg[i])
	    user_pkt_state[i] <= '0;
	  else begin
	    if (user_tvalid_i[i] & user_tlast_i[i] & user_tready_o[i])
		  user_pkt_state[i] <= '0; // clear
		else if (user_tvalid_i[i] & user_tready_o[i])
		  user_pkt_state[i] <= ~user_pkt_state[i] ? '1 : user_pkt_state[i]; // set
      end
	end // always_ff

    // avmm interface
    always_ff @(posedge tx_clk[i]) begin
    //---------------------------------------------------------------------------
      // map to max array
        iarb_avmm_rdata_tmp[i] <= iarb_avmm_rdata[i];
        iarb_avmm_rdata_vld_tmp[i] <= iarb_avmm_rdata_vld[i];
      
      //// zero out rest of unused indicies
      //for (int i = NUM_PIPELINE; i < MAX_NUM_PIPELINE; i++) begin 
      //  iarb_avmm_rdata_tmp[i] <= '0;
      //  iarb_avmm_rdata_vld_tmp[i] <= '0;
      //end // for (int i = NUM_PIPELINE; i < MAX_NUM_PIPELINE; i++)
	end // always_ff


     end
    endgenerate

    always_comb begin
      // zero out rest of unused indicies
      for (int i = NUM_PIPELINE; i < MAX_NUM_PIPELINE; i++) begin 
        iarb_avmm_rdata_tmp[i] = '0;
        iarb_avmm_rdata_vld_tmp[i] = '0;
      end // for (int i = NUM_PIPELINE; i < MAX_NUM_PIPELINE; i++)

      for (int i = 0; i < NUM_PIPELINE; i++) begin 
       avmm_readdata[i] = iarb_avmm_rdata_tmp[i]
                       | dbg_avmm_rdata_tmp[i];       

       avmm_readdata_valid[i] = iarb_avmm_rdata_vld_tmp[i]
                             | dbg_avmm_rdata_vld_tmp[i]; 
      end

    end // always_comb

	
	//========================================================================================
	//TX Path
	//-----------------------------------------------------------------------------------------
	always_comb begin
		dma2iarb_tx_tvalid                  = iwadj_tx_tvalid;
		dma2iarb_tx_tdata                   = iwadj_tx_tdata;
		dma2iarb_tx_tkeep                   = iwadj_tx_tkeep;
		dma2iarb_tx_tlast                   = iwadj_tx_tlast;
		dma2iarb_tx_tuser_last_segment      = iwadj_tx_tuser_last_segment;
		dma2iarb_tx_tuser_md                = iwadj_tx_tuser_md;
		  
		iwadj_tx_tready = iarb2iwadj_tx_tready;	  
	end
	
	
	always_comb begin
	       // ----------------------------------------------------------------------
			for (int dma_chnl = 0; dma_chnl < DMA_CHNL; dma_chnl++) begin : DMA_CHANNELS	
					iwadj_tx_tuser_md_i[dma_chnl] = { 
								 dma_tuser_client_i[dma_chnl]	 
								,dma_tuser_ptp_mod[dma_chnl]	 
								,dma_tuser_ptp_extended_i[dma_chnl]
								,dma_tuser_pkt_seg_parity_i[dma_chnl]
								};  
            end // for (int dma_chnl = 0; dma_chnl < DMA_CHNL; dma_chnl++)

			// ----------------------------------------------------------------------
			for (int num_pp = 0; num_pp < NUM_PIPELINE; num_pp++) begin : PIPELINE_USER_USR_MD
				user_tx_tuser_md_i[num_pp] = { 
							 user_tuser_client_i[num_pp]
							,user_tuser_ptp_mod[num_pp]
							,user_tuser_ptp_extended_i[num_pp]
							,user_tuser_pkt_seg_parity_i[num_pp]
							};	 
            end // for (int num_pp = 0; num_pp < NUM_PIPELINE; num_pp++)

			// ----------------------------------------------------------------------
            for (int num_pp = 0; num_pp < NUM_PIPELINE; num_pp++) begin : PIPELINE_HSSI_USR_MD
					{ hssi_tx_tuser_client_o[num_pp]	 
					 ,hssi_tx_tuser_ptp_o[num_pp]
					 ,hssi_tx_tuser_ptp_extended_o[num_pp]
					 ,hssi_tx_tuser_pkt_seg_parity_o[num_pp]
					} = iarb2hssi_tuser_usermetadata[num_pp];
			end	 // for (int num_pp = 0; num_pp < NUM_PIPELINE; num_pp++)
	
			// ----------------------------------------------------------------------
			
			for (int num_pp = 0; num_pp < NUM_PIPELINE; num_pp++) begin 		       
                // User byte rotate
                if (IGR_USER_BYTE_ROTATE == 1)
                  user_tdata_byte_rotate[num_pp] = fn_user_byte_rotate(user_tdata_i[num_pp]);
                else 
                  user_tdata_byte_rotate[num_pp] = user_tdata_i[num_pp];

			//-----------------------------------------------------------------------------------------
		    // igr_arb egress interface

				ing2iarb_tvalid[num_pp]             = {dma2iarb_tx_tvalid[num_pp], user_tvalid_i[num_pp]};
				ing2iarb_tdata[num_pp]              = {dma2iarb_tx_tdata[num_pp], user_tdata_byte_rotate[num_pp]};
				ing2iarb_tlast[num_pp]              = {dma2iarb_tx_tlast[num_pp], user_tlast_i[num_pp]};
				ing2iarb_tkeep[num_pp]              = {dma2iarb_tx_tkeep[num_pp], user_tkeep_i[num_pp]};
				ing2iarb_tuser_usermetadata[num_pp] = {dma2iarb_tx_tuser_md[num_pp], user_tx_tuser_md_i[num_pp]};
				{iarb2iwadj_tx_tready[num_pp], user_tready_o[num_pp]} = iarb2ing_tready[num_pp];

                // selects chucks of DMA_CHNL_PER_PIPE
				{iwadj_fifo_pop[(num_pp*DMA_CHNL_PER_PIPE) +: DMA_CHNL_PER_PIPE], 
                                                      unused_user_fifo_pop[num_pp]} = iarb2iwadj_fifo_pop[num_pp];
                 
                // selects chucks of DMA_CHNL_PER_PIPE
				ing2iarb_fifo_empty[num_pp] = 
                  {iwadj_fifo_empty[(num_pp*DMA_CHNL_PER_PIPE) +: DMA_CHNL_PER_PIPE], 1'b1};

                ing2iarb_sop_detect[num_pp] =
                  {iwadj_sop_detect[(num_pp*DMA_CHNL_PER_PIPE) +: DMA_CHNL_PER_PIPE], 1'b0};
			
                // generate segment info (only sop and eop) for user port
                user_tuser_segment_info = '0;
		        user_tuser_segment_info[num_pp].sop           = user_tvalid_i[num_pp] & ~user_pkt_state[num_pp];          
		        user_tuser_segment_info[num_pp].eop           = user_tlast_i[num_pp];          
		
                // selects chucks of DMA_CHNL_PER_PIPE
                ing2iarb_tuser_segment_info[num_pp] = 
                  {iwadj_tuser_segment_info[(num_pp*DMA_CHNL_PER_PIPE) +: DMA_CHNL_PER_PIPE], user_tuser_segment_info[num_pp]};	  

            // ----------------------------------------------------------------------

			//TX egress to HSSI			 
			  hssi_tuser_client_o[num_pp]         = hssi_tx_tuser_client_o[num_pp];
			  hssi_tuser_ptp_o[num_pp]            = hssi_tx_tuser_ptp_o[num_pp];
			  hssi_tuser_ptp_extended_o[num_pp]   = hssi_tx_tuser_ptp_extended_o[num_pp];
			  hssi_tuser_pkt_seg_parity_o[num_pp] = hssi_tx_tuser_pkt_seg_parity_o[num_pp];
			  hssi_tvalid_o[num_pp]               = iarb2hssi_tvalid[num_pp];
			  hssi_tdata_o[num_pp]                = EGR_HSSI_BYTE_ROTATE ? fn_hssi_byte_rotate(iarb2hssi_tdata[num_pp]) : 
                                                      iarb2hssi_tdata[num_pp];
			  hssi_tlast_o[num_pp]                = iarb2hssi_tuser_segment_info[num_pp].eop;
			  hssi_tuser_last_segment_o[num_pp]   = iarb2hssi_tuser_segment_info[num_pp].eop;
			  hssi_tkeep_o[num_pp]                = iarb2hssi_tkeep[num_pp];
			  // hssi_tkeep_o[num_pp]                = bytes_valid_to_tkeep(iarb2hssi_tuser_segment_info[num_pp].bytesvld);
		end	// for (int num_pp = 0; num_pp < NUM_PIPELINE; num_pp++)			
	end // always_comb
	
   //---------------------------------------------------------------------------
   // assign timestamp port info according to ingress port

   // DMA port assignment
   always_comb begin
     dma_tuser_ptp_tmp = '0;

     // split dma_tuser_ptp_i into dma_tuser_ptp_tmp by NUM_PIPELINE
     for (int num_pp = 0; num_pp < NUM_PIPELINE; num_pp++) begin
       for (int dma_chnl = 0; dma_chnl < DMA_CHNL_PER_PIPE; dma_chnl++) begin
         dma_tuser_ptp_tmp[num_pp][dma_chnl] = 
           dma_tuser_ptp_i[num_pp*DMA_CHNL_PER_PIPE+dma_chnl];
       end // for (int dma_chnl = 0; dma_chnl < DMA_CHNL_PER_PIPE; dma_chnl++)
     end // for (int num_pp = 0; num_pp < NUM_PIPELINE; num_pp++) 

     // timestamp port assignment
     for (int num_pp = 0; num_pp < NUM_PIPELINE; num_pp++) begin
       dma_tuser_ptp_tmp[num_pp][0][TX_FP_SELECT-1:TX_FP_START_INDEX] = 4'd0;
       dma_tuser_ptp_tmp[num_pp][1][TX_FP_SELECT-1:TX_FP_START_INDEX] = 4'd1;
       dma_tuser_ptp_tmp[num_pp][2][TX_FP_SELECT-1:TX_FP_START_INDEX] = 4'd2;
       dma_tuser_ptp_tmp[num_pp][3][TX_FP_SELECT-1:TX_FP_START_INDEX] = 4'd3;
       dma_tuser_ptp_tmp[num_pp][4][TX_FP_SELECT-1:TX_FP_START_INDEX] = 4'd4;
       dma_tuser_ptp_tmp[num_pp][5][TX_FP_SELECT-1:TX_FP_START_INDEX] = 4'd5;
       dma_tuser_ptp_tmp[num_pp][6][TX_FP_SELECT-1:TX_FP_START_INDEX] = 4'd6;
       dma_tuser_ptp_tmp[num_pp][7][TX_FP_SELECT-1:TX_FP_START_INDEX] = 4'd7;
     end // for (int num_pp = 0; num_pp < NUM_PIPELINE; num_pp++)

     // remap dma_tuser_ptp back to dma_tuser_ptp_mod
      for (int num_pp = 0; num_pp < NUM_PIPELINE; num_pp++) begin
       for (int dma_chnl = 0; dma_chnl < DMA_CHNL_PER_PIPE; dma_chnl++) begin
         dma_tuser_ptp_mod[num_pp*DMA_CHNL_PER_PIPE+dma_chnl] = 
           dma_tuser_ptp_tmp[num_pp][dma_chnl];
       end // for (int dma_chnl = 0; dma_chnl < DMA_CHNL_PER_PIPE; dma_chnl++)
      end // for (int num_pp = 0; num_pp < NUM_PIPELINE; num_pp++)

   end // always_comb

   // User port assignment
   always_comb begin
     for (int i = 0; i < NUM_PIPELINE; i++) begin
      user_tuser_ptp_mod[i] = user_tuser_ptp_i[i];
      user_tuser_ptp_mod[i][TX_FP_SELECT-1:TX_FP_START_INDEX] = 4'd8;
     end
   end
   
   //---------------------------------------------------------------------------

	genvar num_pp, dma_chnl;
	
	generate		
		// for (num_pp = 0; num_pp < NUM_PIPELINE; num_pp++) begin : PIPELINE
			for (dma_chnl = 0; dma_chnl < DMA_CHNL; dma_chnl++) begin : TX_DMA_CHANNELS	
				
			//width adapter for dma to hssi - 64b single seg. to multi segment
			packet_switch_tx_igr_wadj
			   #(   .IDATA_WIDTH (DMA_DATA_WIDTH )
				   ,.INUM_SEG (DMA_NUM_OF_SEG )
				   ,.ENUM_SEG (HSSI_DATA_WIDTH/DMA_DATA_WIDTH )
				   ,.ITUSER_MD_WIDTH (TX_DMA_TUSER_MD_WIDTH )
				   ,.ETUSER_MD_WIDTH (TX_HSSI_TUSER_MD_WIDTH )
				   ,.TID_WIDTH (1)
				   ,.BASE_ADDR   ('h0)
				   ,.MAX_ADDR    ('h8)
				   ,.ADDR_WIDTH  (AWADDR_WIDTH)
				   ,.DATA_WIDTH  (WDATA_WIDTH)
				   ,.IFIFO_DEPTH (DMA_IGR_FIFO_DEPTH)    
				   ,.EFIFO_DEPTH (EFIFO_DEPTH)
				   ,.BYTE_ROTATE (IGR_DMA_BYTE_ROTATE)
                    ) packet_switch_tx_igr_wadj
			   (
				 .clk (dma_chnl < DMA_CHNL_PER_PIPE ? tx_clk[0] : tx_clk[1])
				,.rst (dma_chnl < DMA_CHNL_PER_PIPE ? tx_rst_reg[0] : tx_rst_reg[1])

				//-----------------------------------------------------------------------------------------
				// Ingress axi-st interface:  Inputs from DMA
				// outputs
				,.trdy_o (dma_tready_o[dma_chnl])

				// inputs
				,.tvld_i (dma_tvalid_i[dma_chnl])  
				,.tid_i ('0)
				,.tdata_i (dma_tdata_i[dma_chnl])  
				,.tkeep_i (dma_tkeep_i[dma_chnl])
				,.tuser_md_i (iwadj_tx_tuser_md_i[dma_chnl])
				,.terr_i ('0)  
				,.tlast_i (dma_tlast_i[dma_chnl])
				,.tlast_segment_i (dma_tuser_last_segment_i[dma_chnl])
				
				//------------------------------------------------------------------------------------------
				// Egress axi-st interface: Outputs to HSSI
				// inputs
				,.efifo_pop (iwadj_fifo_pop[dma_chnl])
				// ,.trdy_i (iwadj_tx_tready[dma_chnl])

				// outputs
                ,.efifo_mty (iwadj_fifo_empty[dma_chnl])
				,.iwadj_sop_detect (iwadj_sop_detect[dma_chnl])
				,.tvld_o (iwadj_tx_tvalid[dma_chnl])  
				,.tid_o ()
				,.tdata_o (iwadj_tx_tdata[dma_chnl])
				,.tkeep_o (iwadj_tx_tkeep[dma_chnl])
				,.tuser_md_o (iwadj_tx_tuser_md[dma_chnl])
				,.terr_o ()  
				,.tlast_o (iwadj_tx_tlast[dma_chnl])
				,.tlast_segment_o (iwadj_tx_tuser_last_segment[dma_chnl])   
				,.tuser_segment_info_o (iwadj_tuser_segment_info[dma_chnl])   
      
				);
			
			
			end
		for (num_pp = 0; num_pp < NUM_PIPELINE; num_pp++) begin : TX_PIPELINE		

			packet_switch_igr_arb
				#( .TDATA_WIDTH       (HSSI_DATA_WIDTH)
				  ,.USERMETADATA_WIDTH(TX_HSSI_TUSER_MD_WIDTH)
				  ,.NUM_INTF          (NUM_IGR_INTF)
				  ,.BASE_ADDR          (TX_IGR_ARB_START_ADDR+(num_pp*PORT_OFFSET))
				  ,.MAX_ADDR           ('h8)
				  ,.ADDR_WIDTH         (AWADDR_WIDTH)
				  ,.DATA_WIDTH         (WDATA_WIDTH)
				  ,.USER_IGR_FIFO_DEPTH (USER_IGR_FIFO_DEPTH)
				  ,.DMA_CHNL_PER_PIPE   (DMA_CHNL_PER_PIPE)
				 ) packet_switch_igr_arb_inst
				   (
					 .clk (tx_clk[num_pp])
					,.rst (tx_rst_reg[num_pp])
					//ingress
					,.iwadj2iarb_tvalid             (ing2iarb_tvalid[num_pp])
					,.iwadj2iarb_tdata              (ing2iarb_tdata[num_pp])
					,.iwadj2iarb_tkeep              (ing2iarb_tkeep[num_pp])
					,.iwadj2iarb_tuser_usermetadata (ing2iarb_tuser_usermetadata[num_pp])
					,.iwadj2iarb_tuser_segment_info (ing2iarb_tuser_segment_info[num_pp])
					// ,.axi_st_crd_ret_o              (axi_st_crd_ret_o)
					,.iarb2iwadj_tready             (iarb2ing_tready[num_pp])

                    // output
					,.iarb2iwadj_fifo_pop           (iarb2iwadj_fifo_pop[num_pp])
                    // input
					,.iwadj_fifo_empty              (ing2iarb_fifo_empty[num_pp])
					,.iwadj2iarb_sop_detect         (ing2iarb_sop_detect[num_pp])
					
					//egress
					,.iarb2hssi_tvalid             (iarb2hssi_tvalid[num_pp])
					,.iarb2hssi_tdata              (iarb2hssi_tdata[num_pp])
					,.iarb2hssi_tkeep              (iarb2hssi_tkeep[num_pp])
					,.iarb2hssi_tuser_usermetadata (iarb2hssi_tuser_usermetadata[num_pp])
					,.iarb2hssi_tuser_segment_info (iarb2hssi_tuser_segment_info[num_pp])
					
					,.hssi2iarb_tready             (hssi_tready_i[num_pp])
					
					//AVMM Interface					
					,.avmm_address                  (avmm_address[num_pp])
					,.avmm_read                     (avmm_read[num_pp])
					,.avmm_readdata                 (iarb_avmm_rdata[num_pp])
					,.avmm_write                    (avmm_write[num_pp])
					,.avmm_writedata                (avmm_writedata[num_pp])
			        ,.avmm_byteenable               (avmm_byteenable[num_pp])
					,.avmm_readdata_valid           (iarb_avmm_rdata_vld[num_pp])					
					);
		
		//TX egr timestamp
		packet_switch_dma_ts_dmux
			#( .TX_EGR_TS_WIDTH      (TX_TS_DW)
			  ,.FINGERPRINT_FLD_WIDTH(FINGERPRINT_FLD_WIDTH)
			  ,.SYS_FINGERPRINT_WIDTH(SYS_FINGERPRINT_WIDTH)
			  ,.NUM_INTF             (EGR_TS_INTF)
			  ,.EGR_FIFO_DEPTH       (EFIFO_TS_DEPTH)
			 ) packet_switch_dma_ts_dmux_inst
			   (
				 .clk (tx_clk[num_pp])
				,.rst (tx_rst_reg[num_pp])
				//ingress

                ,.hssi2dmux_0_tvalid           (hssi_egrts0_tvalid_i[num_pp])
                ,.hssi2dmux_0_tdata            (hssi_egrts0_tdata_i[num_pp])
                
                ,.hssi2dmux_1_tvalid           (hssi_egrts1_tvalid_i[num_pp])
                ,.hssi2dmux_1_tdata            (hssi_egrts1_tdata_i[num_pp])
				
				,.dmux2hssi_tready             (dmux2hssi_tready[num_pp]) //not used
				
                //egress

                ,.dmux2egrpt_0_tvalid          (dmux2egrpt0_tvalid[num_pp])
                ,.dmux2egrpt_0_tdata           (dmux2egrpt0_tdata[num_pp])

                ,.dmux2egrpt_1_tvalid          (dmux2egrpt1_tvalid[num_pp])
                ,.dmux2egrpt_1_tdata           (dmux2egrpt1_tdata[num_pp])

				
				,.egrpt2dmux_tready            (9'h1FF)
				);
  
			end
	endgenerate
 
    generate
      for (i = 0; i < NUM_PIPELINE; i++) begin		

    // connect output of dmux to dma channel's or user's TS interface
    always_ff @(posedge tx_clk[i]) begin
        for (int dma_chnl = 0; dma_chnl < DMA_CHNL_PER_PIPE; dma_chnl++) begin
          // dma_egrts0_tvalid_o
          dma_egrts0_tvalid_o[i*DMA_CHNL_PER_PIPE+dma_chnl] 
             <= dmux2egrpt0_tvalid[i][dma_chnl];	    

          // dma_egrts0_tdata_o
          dma_egrts0_tdata_o[i*DMA_CHNL_PER_PIPE+dma_chnl] 
             <= dmux2egrpt0_tdata[i][dma_chnl]; 

          // dma_egrts1_tvalid_o
          dma_egrts1_tvalid_o[i*DMA_CHNL_PER_PIPE+dma_chnl] 
             <= dmux2egrpt1_tvalid[i][dma_chnl];	    

          // dma_egrts1_tdata_o
          dma_egrts1_tdata_o[i*DMA_CHNL_PER_PIPE+dma_chnl] 
             <= dmux2egrpt1_tdata[i][dma_chnl]; 

        end // for (int dma_chnl = 0; dma_chnl < DMA_CHNL_PER_PIPE; dma_chnl++)

        user_egrts0_tvalid_o[i] <=  dmux2egrpt0_tvalid[i][8]; // [8]: user
        user_egrts0_tdata_o[i]  <=  dmux2egrpt0_tdata[i][8];  // [8]: user
        user_egrts1_tvalid_o[i] <=  dmux2egrpt1_tvalid[i][8]; // [8]: user
        user_egrts1_tdata_o[i]  <=  dmux2egrpt1_tdata[i][8];  // [8]: user
    end // always_ff

      end // for
    endgenerate
	
	//function definitions
	function [$clog2(HSSI_DATA_WIDTH/8):0] tkeep_bytesvld;
		input logic [HSSI_DATA_WIDTH/8-1:0] din;
		begin
			logic [$clog2(HSSI_DATA_WIDTH/8):0] tmp_sum;
			logic [$clog2(HSSI_DATA_WIDTH/8)-1:0] tmp_cnt;
			
			tmp_cnt = '0;
			
			for (int i = 0; i < HSSI_DATA_WIDTH/8 ; i++) begin
			
			tmp_sum = tmp_cnt + din[i];
			tmp_cnt = tmp_sum[$clog2(HSSI_DATA_WIDTH/8)-1:0];		
			end // for 
			tkeep_bytesvld  = tmp_sum;	    
		end
    endfunction

    function [HSSI_DATA_WIDTH/8-1:0] bytes_valid_to_tkeep;
		input logic [BYTESVLD_WIDTH-1:0] din;
		begin
			logic [HSSI_DATA_WIDTH/8-1:0] tmp_tkeep;

			for (int i = 0; i < HSSI_DATA_WIDTH/8; i++) begin
			  tmp_tkeep[i] = (i < din ) ? '1 : '0;
			end
			
			bytes_valid_to_tkeep = tmp_tkeep;
		 
		end
    endfunction

   function [USER_DATA_WIDTH/8-1:0] [7:0] fn_user_byte_rotate
     (input [USER_DATA_WIDTH/8-1:0] [7:0] din);
      
      begin
	 logic [USER_DATA_WIDTH/8-1:0] [7:0] tmp_din, tmp;
	 tmp_din = din;
	 
	 for (int i = 0; i < USER_DATA_WIDTH/8; i++) begin
	    tmp[i] = tmp_din[(USER_DATA_WIDTH/8-1)-i];	    
	 end
	 fn_user_byte_rotate = tmp;
      end
   endfunction // fn_user_byte_rotate

   function [HSSI_DATA_WIDTH/8-1:0] [7:0] fn_hssi_byte_rotate
     (input [HSSI_DATA_WIDTH/8-1:0] [7:0] din);
      
      begin
	 logic [HSSI_DATA_WIDTH/8-1:0] [7:0] tmp_din, tmp;
	 tmp_din = din;
	 
	 for (int i = 0; i < HSSI_DATA_WIDTH/8; i++) begin
	    tmp[i] = tmp_din[(HSSI_DATA_WIDTH/8-1)-i];	    
	 end
	 fn_hssi_byte_rotate = tmp;
      end
   endfunction // fn_hssi_byte_rotate

   //------------------------------------------------------------------------------------------
   // TX Debug Counters

  generate

	logic [NUM_PIPELINE-1:0][NUM_IGR_INTF-1:0] ing2iarb_tvalid_mod;

    always_comb begin
      for (int i = 0; i < NUM_PIPELINE; i++) begin
  	    ing2iarb_tvalid_mod[i] = {iarb2iwadj_fifo_pop[i][NUM_IGR_INTF-1:1], user_tvalid_i[i]};
	  end // for
    end // always_comb

    if (DBG_CNTR_EN) begin : gen_tx_dbg
      packet_switch_tx_dbg #(
          .NUM_PIPELINE             (NUM_PIPELINE)
         ,.DMA_CHNL                 (DMA_CHNL)
         ,.DMA_CHNL_PER_PIPE        (DMA_CHNL_PER_PIPE)
         ,.CNTR_WIDTH               (CNTR_WIDTH)
         ,.ADDR_WIDTH               (AWADDR_WIDTH)
         ,.DATA_WIDTH               (WDATA_WIDTH)
      ) packet_switch_tx_dbg_inst (
         .clk                                    (tx_clk)
        ,.rst                                    (tx_rst_reg)

        // avmm interface
        ,.avmm_address                           (avmm_address)
        ,.avmm_write                             (avmm_write)
        ,.avmm_writedata                         (avmm_writedata)
	    ,.avmm_byteenable                        (avmm_byteenable)
        ,.avmm_read                              (avmm_read)
        ,.avmm_readdata                          (dbg_avmm_rdata_tmp)
        ,.avmm_readdatavalid                     (dbg_avmm_rdata_vld_tmp)

        //    {dma_ch_a, dma_ch_b}
        ,.dma2iwadj_tvalid                       (dma_tvalid_i)
        ,.dma2iwadj_tready                       (dma_tready_o)
        ,.dma2iwadj_tlast                        (dma_tlast_i)

        //    {dma_ch_b,   user_1, dma_ch_a,   user_0}
        // ie {b2, b1, b0, user_1, a2, a1, a0, user_0}
        ,.ing2iarb_tvalid                        (ing2iarb_tvalid_mod)
        ,.ing2iarb_tready                        (iarb2ing_tready)
        ,.ing2iarb_tlast                         (ing2iarb_tlast)


        //    {hssi_0, hssi_1}
        ,.iarb2hssi_tvalid                       (hssi_tvalid_o)
        ,.iarb2hssi_tready                       (hssi_tready_i)
        ,.iarb2hssi_tlast                        (hssi_tlast_o)
      );
    end else begin
      // drive to 0
      always_comb begin
        dbg_avmm_rdata_tmp = '0;
        dbg_avmm_rdata_vld_tmp = '0;
      end
    end
  endgenerate


   //------------------------------------------------------------------------------------------
   // debug printouts

   `ifdef DBG_STMT_ON
   // synopsys translate_off

   logic [31:0][31:0] igr_dma_cnt, igr_user_cnt, egr_hssi_cnt, egr_dma_ts_cnt, egr_user_ts_cnt;
   logic [31:0] igr_ts_cnt;

   always_ff @(posedge axi_st_clk[0]) begin
     // igr DMA
     for (int i = 0; i < DMA_CHNL; i = i+1) begin
      if (dma_tvalid_i[i] & dma_tlast_i[i] & dma_tready_o[i]) begin
       igr_dma_cnt[i] <= igr_dma_cnt[i] + 1'b1;
      end

      if (dma_tvalid_i[i] & dma_tready_o[i]) begin
	 $display("[PD_DBG] tx_pipe igr_wadj: (dma_%0d) igr_cnt='d%0d; time=%0t"
          ,i
          ,igr_dma_cnt[i]
          ,$time);

	 $display("[PD_DBG] tx_pipe igr_wadj: (dma_%0d) igr_cnt='d%0d; data='h%0h; tkeep='h%0h; tlast='h%0h;"
          ,i
          ,igr_dma_cnt[i]
          ,dma_tdata_i[i]
		  ,dma_tkeep_i[i]
		  ,dma_tlast_i[i]);
      end
     end // for

      // igr USER
      for (int i = 0; i < NUM_PIPELINE; i = i+1) begin
        if (user_tvalid_i[i] & user_tlast_i[i] & user_tready_o[i]) begin
          igr_user_cnt[i] <= igr_user_cnt[i] + 1'b1;
        end
	  
        if (user_tvalid_i[i] & user_tready_o[i]) begin
	   $display("[PD_DBG] tx_pipe igr_wadj: (user_%0d) igr_cnt='d%0d; time=%0t"
            ,i
            ,igr_user_cnt[i]
            ,$time);
	  
	   $display("[PD_DBG] tx_pipe igr_wadj: (user_%0d) igr_cnt='d%0d; data='h%0h; tkeep='h%0h; tlast='h%0h;"
            ,i
            ,igr_user_cnt[i]
            ,user_tdata_i[i]
	  	  ,user_tkeep_i[i]
	  	  ,user_tlast_i[i]);
        end
      end // for

      // egr HSSI
      for (int i = 0; i < NUM_PIPELINE; i = i+1) begin
        if (hssi_tvalid_o[i] & hssi_tlast_o[i] & hssi_tready_i[i]) begin
          egr_hssi_cnt[i] <= egr_hssi_cnt[i] + 1'b1;
        end
        
        if (hssi_tvalid_o[i] & hssi_tready_i[i]) begin
	   $display("[PD_DBG] tx_pipe egr_hssi_%0d: egr_hssi_cnt='d%0d; time=%0t"
            ,i
            ,egr_hssi_cnt[i]
            ,$time);
	  
	   $display("[PD_DBG] tx_pipe egr_hssi_%0d: egr_hssi_cnt='d%0d; data='h%0h; tkeep='h%0h; tlast='h%0h;"
          ,i
          ,egr_hssi_cnt[i]
	  	  ,hssi_tdata_o[i]
	  	  ,hssi_tkeep_o[i]
	  	  ,hssi_tlast_o[i]);
	  
        end
      end //for

     // ---------------------------------------------------------------------------------------------------
     // timestamp interface
 
     // igr HSSI
     if (hssi_egrts0_tvalid_i) begin
       igr_ts_cnt <= igr_ts_cnt + 1'b1;

    $display("[PD_DBG] tx_pipe igr_timestamp: igr_ts_cnt='d%0d; time=%0t"
          ,igr_ts_cnt
          ,$time);

    $display("[PD_DBG] tx_pipe igr_timestamp: igr_ts_cnt='d%0d; hssi_egrts0_tvalid_i='h%0h; hssi_egrts0_tdata_i='h%0h;"
          ,igr_ts_cnt
          ,hssi_egrts0_tvalid_i
          ,hssi_egrts0_tdata_i);

    $display("[PD_DBG] tx_pipe igr_timestamp: igr_ts_cnt='d%0d; hssi_egrts1_tvalid_i='h%0h; hssi_egrts1_tdata_i='h%0h;"
          ,igr_ts_cnt
          ,hssi_egrts1_tvalid_i
          ,hssi_egrts1_tdata_i);
      end


     // egr DMA
     for (int i = 0; i < DMA_CHNL; i = i+1) begin
       if (dma_egrts0_tvalid_o[i]) begin
         egr_dma_ts_cnt[i] <= egr_dma_ts_cnt[i] + 1'b1;
	  
      $display("[PD_DBG] tx_pipe egr_timestamp: (DMA_%0d) egr_ts_cnt='d%0d; time=%0t"
            ,i
            ,egr_dma_ts_cnt[i]
            ,$time);
	  
      $display("[PD_DBG] tx_pipe egr_timestamp: (DMA_%0d) egr_ts_cnt='d%0d; dma_egrts0_tvalid_o='h%0h; dma_egrts0_tdata_o='h%0h;"
            ,i
            ,egr_dma_ts_cnt[i]
            ,dma_egrts0_tvalid_o[i]
            ,dma_egrts0_tdata_o[i]);
	  
      $display("[PD_DBG] tx_pipe egr_timestamp: (DMA_%0d) egr_ts_cnt='d%0d; dma_egrts1_tvalid_o='h%0h; dma_egrts1_tdata_o='h%0h;"
            ,i
            ,egr_dma_ts_cnt[i]
            ,dma_egrts1_tvalid_o[i]
            ,dma_egrts1_tdata_o[i]);
       end
      end //for

     // egr USER
     for (int i = 0; i < NUM_PIPELINE; i = i+1) begin
       if (user_egrts0_tvalid_o[i]) begin
         egr_user_ts_cnt[i] <= egr_user_ts_cnt[i] + 1'b1;
	  
      $display("[PD_DBG] tx_pipe egr_timestamp: (USER_%0d) egr_ts_cnt='d%0d; time=%0t"
            ,i
            ,egr_user_ts_cnt[i]
            ,$time);
	  
      $display("[PD_DBG] tx_pipe egr_timestamp: (USER_%0d) egr_ts_cnt='d%0d; user_egrts0_tvalid_o='h%0h; user_egrts0_tdata_o='h%0h;"
            ,i
            ,egr_user_ts_cnt[i]
            ,user_egrts0_tvalid_o[i]
            ,user_egrts0_tdata_o[i]);
	  
      $display("[PD_DBG] tx_pipe egr_timestamp: (USER_%0d) egr_ts_cnt='d%0d; user_egrts1_tvalid_o='h%0h; user_egrts1_tdata_o='h%0h;"
            ,i
            ,egr_user_ts_cnt[i]
            ,user_egrts1_tvalid_o[i]
            ,user_egrts1_tdata_o[i]);
       end
     end //for

       if (tx_rst[0]) begin
        igr_dma_cnt <= '0;
        igr_user_cnt <= '0;
        igr_ts_cnt <= '0;
        egr_dma_ts_cnt <= '0;
        egr_user_ts_cnt <= '0;
      end
   end // always_ff

   // synopsys translate_on
   `endif

endmodule // packet_switch_tx