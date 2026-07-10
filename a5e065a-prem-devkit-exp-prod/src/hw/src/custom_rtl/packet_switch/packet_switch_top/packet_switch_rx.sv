//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

//---------------------------------------------------------------------------------------------
// Description: This is the rx path of PTP Switch System Example Design(packet_switch_rx.sv)			
// 	- All the rx path parameters & Interfaces listed in here		
//	- In this module, the following blocks are integrated

//		Igr wadj	 --> packet_switch_rx_igr_wadj.sv
//      Egr_wadj     --> packet_switch_egr_wadj.sv
//		Parser	     --> packet_switch_parse_class.sv
//		Lookup	     --> packet_switch_lkup.sv
//		Demux	     --> packet_switch_dma_rx_dmux.sv
//
// igr_wadj configurations:
// ----------------------------------------------------------------------------------
// HSSI/USER Interface | HSSI/USER Data Width | Core Data Width |     wadj type     | 
// ----------------------------------------------------------------------------------
//       10G           |          64          |       512       |   sm2lg (1 to 8)  
//       25G           |          64          |       512       |   sm2lg (1 to 8)  
//       40/50G        |          128         |       512       |   sm2lg (1 to 4)  
//       100G          |          512         |       512       |   sm2lg (1 to 1)  
// ----------------------------------------------------------------------------------
// 
// egr_wadj configurations:
// ------------------------------------------------------------------------------------------
//                 |                |                     | HSSI/USER  |                    |
// Core Data Width | Core Seg Width | HSSI/USER Interface | Data Width |   wadj type        | 
// ------------------------------------------------------------------------------------------
//       512       |       64       |      10G            |    64      | lg2sm (8 to 1)
//       512       |       64       |      25G            |    64      | lg2sm (8 to 1)
//       512       |       128      |      40/50G         |    128     | lg2sm (4 to 1)
//       512       |       512      |      100G           |    512     | lg2sm (1 to 1)
// ------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------------			

module packet_switch_rx
  #(   
	 parameter NUM_PIPELINE                    = 2   //should be equal to HSSI & USER interface
	,parameter DMA_CHNL                        = 3   //DMA channel per interface
	
	,parameter DMA_DATA_WIDTH                  = 64   // supports only 64b
    ,parameter USER_DATA_WIDTH                 = 64   // supports 64/128/512b
    ,parameter HSSI_DATA_WIDTH	               = 512  // supports 64/128/512b
    
    ,parameter DMA_NUM_OF_SEG                  = 1    // supports only 1
    ,parameter HSSI_NUM_OF_SEG                 = 1    // supports only 1
    ,parameter USER_NUM_OF_SEG                 = 1    // supports only 1

    ,parameter HSSI_IGR_FIFO_DEPTH             = (HSSI_DATA_WIDTH == 64) ? 2048 : 4096
	
    ,parameter RX_CLIENT_WIDTH                 = 7

    ,parameter RXIGR_TS_DW                     = 96
	
    ,parameter STS_WIDTH                       = 94
    ,parameter STS_EXT_WIDTH                   = 328
	
    ,parameter AWADDR_WIDTH                    = 32
    ,parameter WDATA_WIDTH                     = 32	
		
    ,parameter TCAM_KEY_WIDTH                  = 492
    ,parameter TCAM_RESULT_WIDTH               = 32
    ,parameter TCAM_ENTRIES                    = 64
    ,parameter TCAM_USERMETADATA_WIDTH         = 1
	
	,parameter DMA_CHNL_PER_PIPE               = DMA_CHNL/NUM_PIPELINE

    ,parameter IGR_HSSI_BYTE_ROTATE            = 1
    ,parameter EGR_DMA_BYTE_ROTATE             = 1
    ,parameter EGR_USER_BYTE_ROTATE            = 1
    ,parameter CNTR_WIDTH                      = 32
    ,parameter DBG_CNTR_EN                     = 0
    )

   ( //---------------------------------------------------------------------------------------
      
	// Rx streaming clock
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
    // RX Interface:  
    //-----------------------------------------------------------------------------------------
    // rx egress interface - Outputs to DMA
    ,output var logic [DMA_CHNL-1:0]                                dma_tvalid_o
    ,output var logic [DMA_CHNL-1:0][DMA_DATA_WIDTH-1:0]            dma_tdata_o
    ,output var logic [DMA_CHNL-1:0][DMA_DATA_WIDTH/8-1:0]          dma_tkeep_o
    ,output var logic [DMA_CHNL-1:0]                                dma_tlast_o
    ,output var logic [DMA_CHNL-1:0][DMA_NUM_OF_SEG-1:0]
									[STS_WIDTH -1:0]                dma_tuser_sts_o
    ,output var logic [DMA_CHNL-1:0][DMA_NUM_OF_SEG-1:0]
									[STS_EXT_WIDTH -1:0]            dma_tuser_sts_extended_o
    ,output var logic [DMA_CHNL-1:0][DMA_NUM_OF_SEG-1:0]
                                      [RX_CLIENT_WIDTH-1:0]         dma_tuser_client_o
    ,output var logic [DMA_CHNL-1:0][DMA_NUM_OF_SEG-1:0]            dma_tuser_pkt_seg_parity_o
    ,output var logic [DMA_CHNL-1:0][DMA_NUM_OF_SEG-1:0]            dma_tuser_last_segment_o
																 
    ,input var logic [DMA_CHNL-1:0]                                 dma_tready_i
	//-----------------------------------------------------------------------------------------
    // rx egress interface - Output to USER
    ,output var logic [NUM_PIPELINE-1:0]                            user_tvalid_o
    ,output var logic [NUM_PIPELINE-1:0][USER_DATA_WIDTH-1:0]       user_tdata_o
    ,output var logic [NUM_PIPELINE-1:0][USER_DATA_WIDTH/8-1:0]     user_tkeep_o
    ,output var logic [NUM_PIPELINE-1:0]                            user_tlast_o
    ,output var logic [NUM_PIPELINE-1:0][USER_NUM_OF_SEG-1:0]
									    [STS_WIDTH -1:0]            user_tuser_sts_o
    ,output var logic [NUM_PIPELINE-1:0][USER_NUM_OF_SEG-1:0]
									    [STS_EXT_WIDTH -1:0]        user_tuser_sts_extended_o
    ,output var logic [NUM_PIPELINE-1:0][USER_NUM_OF_SEG-1:0]
                                          [RX_CLIENT_WIDTH-1:0]     user_tuser_client_o
    ,output var logic [NUM_PIPELINE-1:0][USER_NUM_OF_SEG-1:0]       user_tuser_pkt_seg_parity_o
    ,output var logic [NUM_PIPELINE-1:0][USER_NUM_OF_SEG-1:0]       user_tuser_last_segment_o
												   
    ,input var logic [NUM_PIPELINE-1:0]                             user_tready_i

    //-----------------------------------------------------------------------------------------
    // rx ingress interface - Inputs from HSSI
    ,input var logic [NUM_PIPELINE-1:0]                             hssi_tvalid_i
    ,input var logic [NUM_PIPELINE-1:0][HSSI_DATA_WIDTH-1:0]        hssi_tdata_i
    ,input var logic [NUM_PIPELINE-1:0][HSSI_DATA_WIDTH/8-1:0]      hssi_tkeep_i
    ,input var logic [NUM_PIPELINE-1:0]                             hssi_tlast_i
    ,input var logic [NUM_PIPELINE-1:0][HSSI_NUM_OF_SEG-1:0]
									   [STS_WIDTH -1:0]             hssi_tuser_sts_i
    ,input var logic [NUM_PIPELINE-1:0][HSSI_NUM_OF_SEG-1:0]
									   [STS_EXT_WIDTH -1:0]         hssi_tuser_sts_extended_i
    ,input var logic [NUM_PIPELINE-1:0][HSSI_NUM_OF_SEG-1:0]
                                         [RX_CLIENT_WIDTH-1:0]      hssi_tuser_client_i
    ,input var logic [NUM_PIPELINE-1:0][HSSI_NUM_OF_SEG-1:0]        hssi_tuser_pkt_seg_parity_i
    ,input var logic [NUM_PIPELINE-1:0][HSSI_NUM_OF_SEG-1:0]        hssi_tuser_last_segment_i
    ,output var logic [NUM_PIPELINE-1:0]                            hssi_pause_o
																		  
    ,output var logic  [NUM_PIPELINE-1:0]                           hssi_tready_o

    
    //=========================================================================================
    // Time Stamp Interface
    //-----------------------------------------------------------------------------------------
    // rx ingress timestamp from HSSI
    ,input var logic [NUM_PIPELINE-1:0]                             hssi_igrts0_tvalid_i
    ,input var logic [NUM_PIPELINE-1:0][RXIGR_TS_DW-1:0]            hssi_igrts0_tdata_i
    ,input var logic [NUM_PIPELINE-1:0]                             hssi_igrts1_tvalid_i
    ,input var logic [NUM_PIPELINE-1:0][RXIGR_TS_DW-1:0]            hssi_igrts1_tdata_i
													             
     // rx ingress timestamp to DMA                                                 
    ,output var logic [DMA_CHNL-1:0]                                dma_igrts0_tvalid_o
    ,output var logic [DMA_CHNL-1:0][RXIGR_TS_DW-1:0]               dma_igrts0_tdata_o
    ,output var logic [DMA_CHNL-1:0]                                dma_igrts1_tvalid_o
    ,output var logic [DMA_CHNL-1:0][RXIGR_TS_DW-1:0]               dma_igrts1_tdata_o
													                 		      
     // rx ingress timestamp to USER                                                
    ,output var logic [NUM_PIPELINE-1:0]                            user_igrts0_tvalid_o
    ,output var logic [NUM_PIPELINE-1:0][RXIGR_TS_DW-1:0]           user_igrts0_tdata_o
    ,output var logic [NUM_PIPELINE-1:0]                            user_igrts1_tvalid_o
    ,output var logic [NUM_PIPELINE-1:0][RXIGR_TS_DW-1:0]           user_igrts1_tdata_o
    
	//=========================================================================================
	//TCAM Interface signals
	//-----------------------------------------------------------------------------------------
	//TCAM Request Interface
	,input var logic  [NUM_PIPELINE-1:0]                              tcam_req_tready_i
	
	,output var logic [NUM_PIPELINE-1:0]                              tcam_req_tvalid_o
	,output var packet_switch_pkg::tuple_map_S [NUM_PIPELINE-1:0]        tcam_req_tuser_key_o
	,output var logic [NUM_PIPELINE-1:0][TCAM_USERMETADATA_WIDTH-1:0] tcam_req_tuser_usermetadata_o
	//-----------------------------------------------------------------------------------------
	//TCAM Resonce Interface
	,output var logic [NUM_PIPELINE-1:0]                              tcam_rsp_tready_o
	
	,input var logic [NUM_PIPELINE-1:0]                               tcam_rsp_tvalid_i
	,input var logic [NUM_PIPELINE-1:0]                               tcam_rsp_tuser_found_i
	,input var  packet_switch_pkg::TCAM_RESULT_S [NUM_PIPELINE-1:0]      tcam_rsp_tuser_result_i
	,input var logic [NUM_PIPELINE-1:0][TCAM_ENTRIES-1:0]             tcam_rsp_tuser_match_array_i 
	,input var logic [NUM_PIPELINE-1:0][$clog2(TCAM_ENTRIES)-1:0]     tcam_rsp_tuser_entry_i 
	,input var logic [NUM_PIPELINE-1:0][TCAM_USERMETADATA_WIDTH-1:0]  tcam_rsp_tuser_usermetadata_i
	
   );

   import packet_switch_pkg::*;
   
	//====================================================================
	//local parameters
	localparam RX_TUSER_CLIENT_WIDTH     = RX_CLIENT_WIDTH;
	localparam TUSER_STS_WIDTH           = STS_WIDTH;
	localparam TUSER_STS_EXT_WIDTH       = STS_EXT_WIDTH;
	localparam HSSI_SEG_PARITY_WIDTH     = HSSI_NUM_OF_SEG;
	localparam DMA_SEG_PARITY_WIDTH      = DMA_NUM_OF_SEG;
	localparam USER_SEG_PARITY_WIDTH     = USER_NUM_OF_SEG;

    localparam IGR_WADJ_INUM_SEG = (HSSI_DATA_WIDTH == 64) ? 8 : 
                                   (HSSI_DATA_WIDTH == 128) ? 4 : 2;
					
	localparam RX_DMA_TUSER_MD_WIDTH = ((RX_TUSER_CLIENT_WIDTH
				   +TUSER_STS_WIDTH
				   +TUSER_STS_EXT_WIDTH)*DMA_NUM_OF_SEG)
				   +DMA_SEG_PARITY_WIDTH
				   +2*(RXIGR_TS_DW+1); //1-ts valid

    localparam RX_HSSI_TUSER_MD_WIDTH = ((RX_TUSER_CLIENT_WIDTH
				    +TUSER_STS_WIDTH
				    +TUSER_STS_EXT_WIDTH)*HSSI_NUM_OF_SEG)
				    +HSSI_SEG_PARITY_WIDTH
				    +2*(RXIGR_TS_DW+1); //1-ts valid

    localparam RX_USER_TUSER_MD_WIDTH = ((RX_TUSER_CLIENT_WIDTH
				    +TUSER_STS_WIDTH
				    +TUSER_STS_EXT_WIDTH)*USER_NUM_OF_SEG)
				    +USER_SEG_PARITY_WIDTH
				    +2*(RXIGR_TS_DW+1); //1-ts valid
	
	localparam IGR_IFIFO_DEPTH        = HSSI_IGR_FIFO_DEPTH;
	localparam IGR_FIFO_DEPTH         = 512; // dma and user egr_wadj
	localparam EGR_FIFO_DEPTH         = 512;
	
	localparam PIPE_DATA_WIDTH = 512;
	localparam NUM_EGR_INTF    = 2; //[1]USER & [0]DMA

    localparam MAX_NUM_PIPELINE = packet_switch_pkg::MAX_HSSI_PORTS;
    localparam METADATA_CORE_SEG = PIPE_DATA_WIDTH/HSSI_DATA_WIDTH;
    localparam METADATA_CORE_WD = RX_HSSI_TUSER_MD_WIDTH*2; // seg_1: eop cycle, seg_0: sop cycle

	//----------------------------------------------------------------------------------
 	//user metadata merged signals
	logic [NUM_PIPELINE-1:0][RX_HSSI_TUSER_MD_WIDTH-1:0]  hssi2iwadj_tuser_md_i;
	
	
    logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]
							[STS_WIDTH-1:0]                dma_rx_tuser_sts_o;
    logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]	       
							[STS_EXT_WIDTH-1:0]            dma_rx_tuser_sts_extended_o;
    logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]        
							[DMA_NUM_OF_SEG-1:0]           
							[RX_TUSER_CLIENT_WIDTH-1:0]    dma_rx_tuser_client_o;
    logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]        
							[DMA_SEG_PARITY_WIDTH-1:0]     dma_rx_tuser_pkt_seg_parity_o;
	
	// rx timestamp interface
	logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]
							[RXIGR_TS_DW-1:0]              dma_rx_ts0_tdata_o;
	logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]        dma_rx_ts0_tvalid_o; 
	logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]
							[RXIGR_TS_DW-1:0]              dma_rx_ts1_tdata_o;
	logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]        dma_rx_ts1_tvalid_o; 	 	 
	
	//arbiter Interfaces
	//ingress
	logic [NUM_PIPELINE-1:0]                               iwadj2pars_tvalid;
	logic [NUM_PIPELINE-1:0][PIPE_DATA_WIDTH-1:0]          iwadj2pars_tdata;
	logic [NUM_PIPELINE-1:0][PIPE_DATA_WIDTH/8-1:0]        iwadj2pars_tkeep;
	logic [NUM_PIPELINE-1:0][METADATA_CORE_WD-1:0]         iwadj2pars_tuser_md;
	logic [NUM_PIPELINE-1:0]
		  [PIPE_DATA_WIDTH/HSSI_DATA_WIDTH-1:0]            iwadj2pars_tuser_last_segment;
	logic [NUM_PIPELINE-1:0]                               iwadj2pars_tlast;
	packet_switch_pkg::SEGMENT_INFO_S [NUM_PIPELINE-1:0]      iwadj2pars_tuser_seg_info; 
	// logic [NUM_INTF-1:0]                          axi_st_crd_ret_o;
	
	//parser Interfaces
	logic [NUM_PIPELINE-1:0]                               pars2iwadj_tready, lu2pars_tready, 
                                                           lu2pars_fifo_rd, lu2pars_tcam_req_fifo_rd;
	logic [NUM_PIPELINE-1:0]                               pars2lu_tvalid, pars2lu_fifo_empty, 
                                                           pars2lu_tcam_req_fifo_empty;
	logic [NUM_PIPELINE-1:0][PIPE_DATA_WIDTH-1:0]          pars2lu_tdata;
	logic [NUM_PIPELINE-1:0][METADATA_CORE_WD-1:0]         pars2lu_tuser_usermetadata;
	packet_switch_pkg::SEGMENT_INFO_S [NUM_PIPELINE-1:0]      pars2lu_tuser_segment_info;
	packet_switch_pkg::tuple_map_S [NUM_PIPELINE-1:0]         pars2lu_tuser_tuple_map;
	
	logic [NUM_PIPELINE-1:0]                               egr2lu_tready_i;
	logic [NUM_PIPELINE-1:0][NUM_EGR_INTF-1:0]             ewadj2lu_tready;
	logic [NUM_PIPELINE-1:0][NUM_EGR_INTF-1:0]             lu2ewadj_tvalid;
	logic [NUM_PIPELINE-1:0][NUM_EGR_INTF-1:0]
							[PIPE_DATA_WIDTH-1:0]          lu2ewadj_tdata;
	logic [NUM_PIPELINE-1:0][NUM_EGR_INTF-1:0]             
							[PIPE_DATA_WIDTH/8-1:0]        lu2ewadj_tkeep;
	logic [NUM_PIPELINE-1:0][NUM_EGR_INTF-1:0]
							[METADATA_CORE_WD-1:0]         lu2ewadj_tuser_usermetadata;
	packet_switch_pkg::SEGMENT_INFO_S
	[NUM_PIPELINE-1:0][NUM_EGR_INTF-1:0]      		       lu2ewadj_tuser_segment_info;
	
	//Egress Width adjuster interfaces	
	logic [NUM_PIPELINE-1:0][NUM_EGR_INTF-1:0]             egr2ewadj_tready_i;
														   
	logic [NUM_PIPELINE-1:0]                               dmux2ewadj_tready; 
	//Egress Width adjuster to DMA						 		   
	logic [NUM_PIPELINE-1:0]                               ewadj_dma_tvalid_o;
	logic [NUM_PIPELINE-1:0]                               ewadj_dma_tlast_o;
	logic [NUM_PIPELINE-1:0][DMA_NUM_OF_SEG-1:0]           ewadj_dma_tlast_segment_o;
	logic [NUM_PIPELINE-1:0][DMA_DATA_WIDTH-1:0]           ewadj_dma_tdata_o;
	logic [NUM_PIPELINE-1:0][DMA_DATA_WIDTH/8-1:0]         ewadj_dma_tkeep_o;
	logic [NUM_PIPELINE-1:0][RX_HSSI_TUSER_MD_WIDTH-1:0]   ewadj_dma_tuser_usermetadata_o;
	packet_switch_pkg::SEGMENT_INFO_S[NUM_PIPELINE-1:0]       ewadj_dma_tuser_segment_info_o;
	//Egress Width adjuster to User													   
	logic [NUM_PIPELINE-1:0]                               ewadj_user_tvalid_o;
	logic [NUM_PIPELINE-1:0]                               ewadj_user_tlast_o;
	logic [NUM_PIPELINE-1:0][USER_NUM_OF_SEG-1:0]          ewadj_user_tlast_segment_o;
	logic [NUM_PIPELINE-1:0][USER_DATA_WIDTH-1:0]          ewadj_user_tdata_o;
	logic [NUM_PIPELINE-1:0][USER_DATA_WIDTH/8-1:0]        ewadj_user_tkeep_o;
	logic [NUM_PIPELINE-1:0][RX_USER_TUSER_MD_WIDTH-1:0]   ewadj_user_tuser_usermetadata_o;
	packet_switch_pkg::SEGMENT_INFO_S[NUM_PIPELINE-1:0]       ewadj_user_tuser_segment_info_o;
	
	logic [NUM_PIPELINE-1:0][AWADDR_WIDTH-1:0]             ewadj_avmm_addr;
	logic [NUM_PIPELINE-1:0]                               ewadj_avmm_rd;
	logic [NUM_PIPELINE-1:0][WDATA_WIDTH-1:0]              ewadj_avmm_rdata ;
	logic [MAX_NUM_PIPELINE-1:0]          
							[WDATA_WIDTH-1:0]              ewadj_avmm_rdata_tmp ;
	logic [NUM_PIPELINE-1:0]                               ewadj_avmm_wr;
	logic [NUM_PIPELINE-1:0][WDATA_WIDTH-1:0]              ewadj_avmm_wdata;
	logic [NUM_PIPELINE-1:0]                               ewadj_avmm_rdata_vld, ewadj_dbg_cnt_drop_en;

	logic [MAX_NUM_PIPELINE-1:0]                           ewadj_avmm_rdata_vld_tmp;
	
	//Egresss Demux Interfaces
	logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]        dma2dmux_tready;
	
	logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]        dmux2dma_tvalid_o;
	logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]        dmux2dma_tlast_o;
	logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]                                  
							[DMA_NUM_OF_SEG-1:0]           dmux2dma_tuser_last_segment_o;
	logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]                                  
						    [DMA_DATA_WIDTH-1:0]           dmux2dma_tdata_o;
	logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]                                  
							[DMA_DATA_WIDTH/8-1:0]         dmux2dma_tkeep_o;
	logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]                                  
							[RX_HSSI_TUSER_MD_WIDTH-1:0]   dmux2dma_tuser_usermetadata_o;
	packet_switch_pkg::SEGMENT_INFO_S [DMA_CHNL_PER_PIPE-1:0] dmux2dma_tuser_segment_info_o;
	
	

    logic [NUM_PIPELINE-1:0][WDATA_WIDTH-1:0]              dmux_avmm_rdata;
    logic [MAX_NUM_PIPELINE-1:0][WDATA_WIDTH-1:0]          dmux_avmm_rdata_tmp;
    logic [NUM_PIPELINE-1:0]                               dmux_avmm_rdata_vld; 
    logic [MAX_NUM_PIPELINE-1:0]                           dmux_avmm_rdata_vld_tmp; 
	
	logic [NUM_PIPELINE-1:0][WDATA_WIDTH-1:0]	           iwadj_avmm_rdata;
	logic [MAX_NUM_PIPELINE-1:0][WDATA_WIDTH-1:0]	       iwadj_avmm_rdata_tmp;
	logic [NUM_PIPELINE-1:0]                 	           iwadj_avmm_rdata_vld;
	logic [MAX_NUM_PIPELINE-1:0]                 	       iwadj_avmm_rdata_vld_tmp;
	
	// Debug Signals
	logic [NUM_PIPELINE-1:0][WDATA_WIDTH-1:0] dbg_avmm_rdata_tmp;
	logic [NUM_PIPELINE-1:0] dbg_avmm_rdata_vld_tmp, iwadj_dbg_cnt_drop_en;
	logic [NUM_PIPELINE-1:0][7:0] dmux_dbg_cnt_drop_en;

	logic [NUM_PIPELINE-1:0] rx_clk, rx_rst;
	logic [NUM_PIPELINE-1:0] rx_rst_reg;
    logic [NUM_PIPELINE-1:0][4:0] init_cnt;
	
	//clock
	always_comb begin
	  rx_clk = axi_st_clk;
	end

    genvar i;
    generate
     for (i = 0; i < NUM_PIPELINE; i++) begin : gen_rst_sync_misc

	// rx_reset
	ipbb_asyn_to_syn_rst rst_sync
	 (.clk (rx_clk[i])
	  ,.asyn_rst (!axi_st_rst_n[i])

	  // output
	  ,.syn_rst (rx_rst[i])
	  ); 

	//init done status
	always_ff @(posedge axi_st_clk[i]) begin
      if (!init_cnt[i][4])
        init_cnt[i] <= init_cnt[i] + 1'b1;

      init_done[i] <= init_cnt[i][4];

     if (rx_rst[i]) 
       init_cnt[i] <= '0;
    end // always_ff
	 
	// Generate arrays of reset to be used in submodules
	always_ff @(posedge rx_clk[i]) begin
	  rx_rst_reg[i] <= rx_rst[i];
	end // always_ff

    // avmm interface
    always_ff @(posedge axi_st_clk[i]) begin   

     // avmm_readdata[i] <= dmux_avmm_rdata_tmp[i] | iwadj_avmm_rdata_tmp[i] | dbg_avmm_rdata_tmp[i];
     avmm_readdata[i] <= dmux_avmm_rdata_tmp[i] | iwadj_avmm_rdata_tmp[i] | ewadj_avmm_rdata_tmp[i] 
	                                                                     | dbg_avmm_rdata_tmp[i];
	 
     // avmm_readdata_valid[i] <= dmux_avmm_rdata_vld_tmp[i]| iwadj_avmm_rdata_vld_tmp[i] | dbg_avmm_rdata_vld_tmp[i];
     avmm_readdata_valid[i] <= dmux_avmm_rdata_vld_tmp[i]| iwadj_avmm_rdata_vld_tmp[i] | ewadj_avmm_rdata_vld_tmp[i] 
	                                                                      | dbg_avmm_rdata_vld_tmp[i];

    end // always_ff


     end
    endgenerate

   always_comb begin
     dmux_avmm_rdata_tmp = '0;
     dmux_avmm_rdata_vld_tmp = '0;
     iwadj_avmm_rdata_tmp = '0;
     iwadj_avmm_rdata_vld_tmp = '0;
     ewadj_avmm_rdata_tmp = '0;
     ewadj_avmm_rdata_vld_tmp = '0;
 
     // map to max array
     for (int i = 0; i < NUM_PIPELINE; i++) begin 
       dmux_avmm_rdata_tmp[i] = dmux_avmm_rdata[i];
       dmux_avmm_rdata_vld_tmp[i] = dmux_avmm_rdata_vld[i];
       iwadj_avmm_rdata_tmp[i] = iwadj_avmm_rdata[i];
       iwadj_avmm_rdata_vld_tmp[i] = iwadj_avmm_rdata_vld[i];
       ewadj_avmm_rdata_tmp[i] = ewadj_avmm_rdata[i];
       ewadj_avmm_rdata_vld_tmp[i] = ewadj_avmm_rdata_vld[i];
     end // for (int i = 0; i < NUM_PIPELINE; i++)

   end // always_comb

	always_comb begin
		dma2dmux_tready = dma_tready_i;
	end
	
	//========================================================================================
	//RX Path
	//----------------------------------------------------------------------------------------
	always_comb begin
		for (int num_pp = 0; num_pp < NUM_PIPELINE; num_pp++) begin
                // hssi2iwadj_tuser_md_i
				hssi2iwadj_tuser_md_i[num_pp] = { hssi_igrts1_tdata_i[num_pp]
				                                 ,hssi_igrts1_tvalid_i[num_pp]
				                                 ,hssi_igrts0_tdata_i[num_pp]
				                                 ,hssi_igrts0_tvalid_i[num_pp]
				                                 ,hssi_tuser_client_i[num_pp]	 
				                                 ,hssi_tuser_sts_i[num_pp]
				                                 ,hssi_tuser_sts_extended_i[num_pp]
				                                 ,hssi_tuser_pkt_seg_parity_i[num_pp]
				                                };	 
				
                // ewadj_tuser_usermetadata_o
				{ user_igrts1_tdata_o[num_pp]
				 ,user_igrts1_tvalid_o[num_pp]
				 ,user_igrts0_tdata_o[num_pp]
				 ,user_igrts0_tvalid_o[num_pp]
				 ,user_tuser_client_o[num_pp]	 
				 ,user_tuser_sts_o[num_pp]
				 ,user_tuser_sts_extended_o[num_pp]
				 ,user_tuser_pkt_seg_parity_o[num_pp]} = ewadj_user_tuser_usermetadata_o[num_pp];


			user_tvalid_o[num_pp] = ewadj_user_tvalid_o[num_pp];
			user_tdata_o[num_pp]  = ewadj_user_tdata_o[num_pp];
			user_tkeep_o[num_pp]  = ewadj_user_tkeep_o[num_pp];
			user_tlast_o[num_pp]  = ewadj_user_tlast_o[num_pp];
			user_tuser_last_segment_o[num_pp] = ewadj_user_tuser_segment_info_o[num_pp].eop;
			
			egr2ewadj_tready_i[num_pp] = {user_tready_i[num_pp],dmux2ewadj_tready[num_pp]}; 

            for (int dma_chnl = 0; dma_chnl < DMA_CHNL_PER_PIPE; dma_chnl++) begin
                // dmux2dma_tuser_usermetadata_o
				{ dma_rx_ts1_tdata_o[num_pp][dma_chnl]
				 ,dma_rx_ts1_tvalid_o[num_pp][dma_chnl]
				 ,dma_rx_ts0_tdata_o[num_pp][dma_chnl]
				 ,dma_rx_ts0_tvalid_o[num_pp][dma_chnl]
				 ,dma_rx_tuser_client_o[num_pp][dma_chnl]	 
				 ,dma_rx_tuser_sts_o[num_pp][dma_chnl]
				 ,dma_rx_tuser_sts_extended_o[num_pp][dma_chnl]
				 ,dma_rx_tuser_pkt_seg_parity_o[num_pp][dma_chnl]} = 
                    dmux2dma_tuser_usermetadata_o[num_pp][dma_chnl];
            end // for (int dma_chnl = 0; dma_chnl < DMA_CHNL_PER_PIPE; dma_chnl++)	
		end	// for (int num_pp = 0; num_pp < NUM_PIPELINE; num_pp++)
	end

		// output of dmux to dma channel's interface
		always_comb begin
		  for (int num_pp = 0; num_pp < NUM_PIPELINE; num_pp++) begin		
			for (int dma_chnl = 0; dma_chnl < DMA_CHNL_PER_PIPE; dma_chnl++) begin
				dma_igrts0_tvalid_o[num_pp*DMA_CHNL_PER_PIPE+dma_chnl] 
				 = dma_rx_ts0_tvalid_o[num_pp][dma_chnl];	    

				dma_igrts0_tdata_o[num_pp*DMA_CHNL_PER_PIPE+dma_chnl] 
				 = dma_rx_ts0_tdata_o[num_pp][dma_chnl]; 

				dma_igrts1_tvalid_o[num_pp*DMA_CHNL_PER_PIPE+dma_chnl] 
				 = dma_rx_ts1_tvalid_o[num_pp][dma_chnl];	    

				dma_igrts1_tdata_o[num_pp*DMA_CHNL_PER_PIPE+dma_chnl] 
				 = dma_rx_ts1_tdata_o[num_pp][dma_chnl]; 
				 
				dma_tvalid_o[num_pp*DMA_CHNL_PER_PIPE+dma_chnl] = 
                  dmux2dma_tvalid_o[num_pp][dma_chnl];

				dma_tdata_o[num_pp*DMA_CHNL_PER_PIPE+dma_chnl]  = 
                  dmux2dma_tdata_o[num_pp][dma_chnl];

				dma_tkeep_o[num_pp*DMA_CHNL_PER_PIPE+dma_chnl]  = 
                  dmux2dma_tkeep_o[num_pp][dma_chnl];

				dma_tlast_o[num_pp*DMA_CHNL_PER_PIPE+dma_chnl]  = 
                  dmux2dma_tlast_o[num_pp][dma_chnl];

				dma_tuser_last_segment_o[num_pp*DMA_CHNL_PER_PIPE+dma_chnl] = 
                  dmux2dma_tuser_last_segment_o[num_pp][dma_chnl];		

				dma_tuser_sts_o[num_pp*DMA_CHNL_PER_PIPE+dma_chnl] = 
                  dma_rx_tuser_sts_o[num_pp][dma_chnl];

				dma_tuser_sts_extended_o[num_pp*DMA_CHNL_PER_PIPE+dma_chnl] = 
                  dma_rx_tuser_sts_extended_o[num_pp][dma_chnl];

				dma_tuser_client_o[num_pp*DMA_CHNL_PER_PIPE+dma_chnl] = 
                  dma_rx_tuser_client_o[num_pp][dma_chnl];

				dma_tuser_pkt_seg_parity_o[num_pp*DMA_CHNL_PER_PIPE+dma_chnl] = 
                  dma_rx_tuser_pkt_seg_parity_o[num_pp][dma_chnl];	 
			
			end // for (int dma_chnl = 0; dma_chnl < DMA_CHNL_PER_PIPE; dma_chnl++)
		 end // for (int num_pp = 0; num_pp < NUM_PIPELINE; num_pp++)
		end // always_comb
	
	genvar num_pp, num_egr_intf, dma_chnl;
	generate
 		for ( num_pp = 0; num_pp < NUM_PIPELINE; num_pp++) begin : RX_PIPELINE
			
			//width adapter from hssi
			packet_switch_rx_igr_wadj
			   #(   .IDATA_WIDTH (HSSI_DATA_WIDTH )
				   ,.INUM_SEG (HSSI_NUM_OF_SEG )
				   ,.ENUM_SEG (PIPE_DATA_WIDTH/HSSI_DATA_WIDTH )
				   ,.ITUSER_MD_WIDTH (RX_HSSI_TUSER_MD_WIDTH )
				   ,.ETUSER_MD_WIDTH (METADATA_CORE_WD )
				   ,.TID_WIDTH (1)
				   ,.BASE_ADDR   (RX_IGR_WADJ_START_ADDR+(num_pp*PORT_OFFSET))
				   ,.MAX_ADDR    ('h8)
				   ,.ADDR_WIDTH  (AWADDR_WIDTH)
				   ,.DATA_WIDTH  (WDATA_WIDTH)
				   ,.IFIFO_DEPTH (IGR_IFIFO_DEPTH)    
				   ,.EFIFO_DEPTH (EGR_FIFO_DEPTH)
                   ,.BYTE_ROTATE (IGR_HSSI_BYTE_ROTATE)) packet_switch_rx_igr_wadj
			   (
			 .clk (rx_clk[num_pp])
			,.rst (rx_rst_reg[num_pp])

			//-----------------------------------------------------------------------------------------
			// Ingress axi-st interface:  Inputs from DMA
			// outputs
			,.trdy_o (hssi_tready_o[num_pp])

			// inputs
			,.tvld_i (hssi_tvalid_i[num_pp])  
			,.tid_i ('0)
			,.tdata_i (hssi_tdata_i[num_pp])  
			,.tkeep_i (hssi_tkeep_i[num_pp])
			,.tuser_md_i (hssi2iwadj_tuser_md_i[num_pp])
			,.terr_i ('0)  
			,.tlast_i (hssi_tlast_i[num_pp])
			,.tlast_segment_i (hssi_tuser_last_segment_i[num_pp])
			
			//------------------------------------------------------------------------------------------
			// Egress axi-st interface: Outputs to HSSI
			// inputs
			,.trdy_i (pars2iwadj_tready[num_pp])

			// outputs
			,.tvld_o (iwadj2pars_tvalid[num_pp])  
			,.tid_o ()
			,.tdata_o (iwadj2pars_tdata[num_pp])
			,.tkeep_o (iwadj2pars_tkeep[num_pp])
			,.tuser_md_o (iwadj2pars_tuser_md[num_pp])
			,.terr_o ()  
			,.tlast_o (iwadj2pars_tlast[num_pp])
			,.tlast_segment_o (iwadj2pars_tuser_last_segment[num_pp])  
			,.tuser_segment_info_o (iwadj2pars_tuser_seg_info[num_pp]) 
				
			,.rx_pause_o (hssi_pause_o[num_pp])  
			,.dbg_cnt_drop_en (iwadj_dbg_cnt_drop_en[num_pp])  
            //-----------------------------------------------------------------------------------------
			// AVMM interface

			// inputs
			,.avmm_address   (avmm_address[num_pp])
			,.avmm_read      (avmm_read[num_pp])
			,.avmm_write     (avmm_write[num_pp])
			,.avmm_writedata (avmm_writedata[num_pp])
			,.avmm_byteenable (avmm_byteenable[num_pp])

			// outputs
			,.avmm_readdata (iwadj_avmm_rdata[num_pp])  
			,.avmm_readdata_valid (iwadj_avmm_rdata_vld[num_pp]) 
		   
			);
		
		//Parser module
		packet_switch_parse_class
		#( .TDATA_WIDTH  (PIPE_DATA_WIDTH)
          ,.INST_ID (num_pp)
		  ,.USERMETADATA_WIDTH(METADATA_CORE_WD)) packet_switch_parse_class_inst
		 (
			 .clk (rx_clk[num_pp])
			,.rst (rx_rst_reg[num_pp])

			//-----------------------------------------------------------------------------------------
			// Ingress axi-st interface:  Inputs from wadj
			// outputs
			,.pars2iwadj_tready (pars2iwadj_tready[num_pp])

			// inputs
			,.iwadj2pars_tvalid            (iwadj2pars_tvalid[num_pp])
			,.iwadj2pars_tdata             (iwadj2pars_tdata[num_pp])
			,.iwadj2pars_tkeep             (iwadj2pars_tkeep[num_pp])
			,.iwadj2pars_tuser_usermetadata(iwadj2pars_tuser_md[num_pp])
			,.iwadj2pars_tuser_segment_info(iwadj2pars_tuser_seg_info[num_pp])
			
			//------------------------------------------------------------------------------------------
			// Egress axi-st interface: Outputs to Lookup
			// inputs
            ,.lu2pars_fifo_rd (lu2pars_fifo_rd[num_pp])
            ,.lu2pars_tcam_req_fifo_rd    (lu2pars_tcam_req_fifo_rd[num_pp])

			// outputs
			,.pars2lu_fifo_empty         (pars2lu_fifo_empty[num_pp])      
			,.pars2lu_tvalid             (pars2lu_tvalid[num_pp])      
			,.pars2lu_tdata              (pars2lu_tdata[num_pp])
			,.pars2lu_tuser_usermetadata (pars2lu_tuser_usermetadata[num_pp])
			,.pars2lu_tuser_segment_info (pars2lu_tuser_segment_info[num_pp])
			,.pars2lu_tuser_tuple_map    (pars2lu_tuser_tuple_map[num_pp] )
			,.pars2lu_tcam_req_fifo_empty (pars2lu_tcam_req_fifo_empty[num_pp] )
		 );
		 
		 //Lookup module
		packet_switch_lkup
		#( .TDATA_WIDTH  (PIPE_DATA_WIDTH)
		  ,.USERMETADATA_WIDTH(METADATA_CORE_WD)
		  ,.TCAM_KEY_WIDTH         (TCAM_KEY_WIDTH)
		  ,.TCAM_RESULT_WIDTH      (TCAM_RESULT_WIDTH)
		  ,.TCAM_ENTRIES           (TCAM_ENTRIES)
		  ,.TCAM_USERMETADATA_WIDTH(TCAM_USERMETADATA_WIDTH)
		  ,.CHTID_WIDTH            (1)
		  ,.NUM_EGR_INTF           (NUM_EGR_INTF)
		  ,.DMA_CH                 (DMA_CHNL_PER_PIPE)
          ,.INST_ID (num_pp)
		  ) packet_switch_lkup_inst
		 (
			 .clk (rx_clk[num_pp])
			,.rst (rx_rst_reg[num_pp])

			//-----------------------------------------------------------------------------------------
			// tcam interface
			// responce
			,.tcam_rsp_tvalid             (tcam_rsp_tvalid_i[num_pp]  ) 
			,.tcam_rsp_tuser_result       (tcam_rsp_tuser_result_i[num_pp])
			,.tcam_rsp_tuser_found        (tcam_rsp_tuser_found_i[num_pp])
			,.tcam_rsp_tuser_usermetadata (tcam_rsp_tuser_usermetadata_i[num_pp])
			
			,.tcam_rsp_tready             (tcam_rsp_tready_o[num_pp])
			//request
			,.tcam_req_tready   		  (tcam_req_tready_i[num_pp] )
			
			,.tcam_req_tvalid             (tcam_req_tvalid_o[num_pp])
			,.tcam_req_tid                () //KM: need to check
			,.tcam_req_tuser_key          (tcam_req_tuser_key_o[num_pp])
			,.tcam_req_tuser_usermetadata (tcam_req_tuser_usermetadata_o[num_pp])
			//inputs from Parser							  
			,.pars2lu_fifo_empty          (pars2lu_fifo_empty[num_pp])      
			,.pars2lu_tvalid              (pars2lu_tvalid[num_pp])
			,.pars2lu_tdata               (pars2lu_tdata[num_pp])
			,.pars2lu_tuser_usermetadata  (pars2lu_tuser_usermetadata[num_pp])
			,.pars2lu_tuser_segment_info  (pars2lu_tuser_segment_info[num_pp])
			,.pars2lu_tuser_lu_key        (pars2lu_tuser_tuple_map[num_pp])
			,.pars2lu_tcam_req_fifo_empty (pars2lu_tcam_req_fifo_empty[num_pp])
									
			// outputs
			,.lu2pars_fifo_rd             (lu2pars_fifo_rd[num_pp])
            ,.lu2pars_tcam_req_fifo_rd    (lu2pars_tcam_req_fifo_rd[num_pp])

			//output to egress wadj							  
			,.lu2ewadj_tvalid             (lu2ewadj_tvalid[num_pp])
			,.lu2ewadj_tdata              (lu2ewadj_tdata[num_pp])
			,.lu2ewadj_tkeep              (lu2ewadj_tkeep[num_pp])
			,.lu2ewadj_tuser_usermetadata (lu2ewadj_tuser_usermetadata[num_pp])
			,.lu2ewadj_tuser_segment_info (lu2ewadj_tuser_segment_info[num_pp])
										
			,.ewadj2lu_tready             (ewadj2lu_tready[num_pp])	
			
			
		 );
 
       	    //RX Egress Demux
			packet_switch_dma_rx_dmux
			#( .TDATA_WIDTH         (DMA_DATA_WIDTH)
			  ,.NUM_SEG             (DMA_NUM_OF_SEG)
			  ,.USERMETADATA_WIDTH  (RX_HSSI_TUSER_MD_WIDTH)
			  ,.NUM_INTF            (DMA_CHNL_PER_PIPE)
			  ,.EGR_FIFO_DEPTH      (EGR_FIFO_DEPTH)
			  ,.BASE_ADDR           (RX_EGR_DMUX_START_ADDR+(num_pp*PORT_OFFSET))
			  ,.MAX_ADDR            ('h24)
			  ,.ADDR_WIDTH          (AWADDR_WIDTH)
			  ,.DATA_WIDTH          (WDATA_WIDTH)
			  ,.DMA_CH              (DMA_CHNL_PER_PIPE)
			  ) packet_switch_dma_rx_dmux_inst
			 (
				 .clk (rx_clk[num_pp])
				,.rst (rx_rst_reg[num_pp])

				//-----------------------------------------------------------------------------------------
				// ingress
				,.ewadj2dmux_tvalid            (ewadj_dma_tvalid_o[num_pp])
				,.ewadj2dmux_tdata             (ewadj_dma_tdata_o[num_pp])
				,.ewadj2dmux_tkeep             (ewadj_dma_tkeep_o[num_pp])
				,.ewadj2dmux_tlast             (ewadj_dma_tlast_o[num_pp])
				,.ewadj2dmux_tlast_segment     (ewadj_dma_tlast_segment_o[num_pp])
				,.ewadj2dmux_tuser_usermetadata(ewadj_dma_tuser_usermetadata_o[num_pp])
				,.ewadj2dmux_tuser_segment_info(ewadj_dma_tuser_segment_info_o[num_pp])
				// axi_st_crd_ret_o          ()
				,.dmux2ewadj_tready            (dmux2ewadj_tready[num_pp])
				//egress
				,.dmux2dma_tvalid              (dmux2dma_tvalid_o[num_pp])
				,.dmux2dma_tdata               (dmux2dma_tdata_o[num_pp])
				,.dmux2dma_tkeep               (dmux2dma_tkeep_o[num_pp])
				,.dmux2dma_tlast               (dmux2dma_tlast_o[num_pp])
				,.dmux2dma_tuser_last_segment  (dmux2dma_tuser_last_segment_o[num_pp])
				,.dmux2dma_tuser_usermetadata  (dmux2dma_tuser_usermetadata_o[num_pp])
				
				,.dma2dmux_tready              (dma2dmux_tready[num_pp])

				//-----------------------------------------------------------------------------------------
                // AVMM interface
                // inputs
	            ,.avmm_address               (avmm_address[num_pp])   
	            ,.avmm_read                  (avmm_read[num_pp])      
	            ,.avmm_write                 (avmm_write[num_pp])     
	            ,.avmm_writedata             (avmm_writedata[num_pp]) 
			    ,.avmm_byteenable            (avmm_byteenable[num_pp])
          
                // outputs
	            ,.avmm_readdata              (dmux_avmm_rdata[num_pp])
	            ,.avmm_readdata_valid        (dmux_avmm_rdata_vld[num_pp]) 			
				//-----------------------------------------------------------------------------------------
				// Debug drop state
				,.dbg_cnt_drop_en 			 (dmux_dbg_cnt_drop_en[num_pp]) 
			 );  		 
			
			
				
				//Egress Width adjuster to USER
				packet_switch_egr_wadj
				#( .DEVICE_FAMILY       ("Agilex")
				  ,.IGR_SEG_WIDTH       (PIPE_DATA_WIDTH)
				  ,.IGR_NUM_SEG         (1)
				  ,.EGR_NUM_SEG         (USER_NUM_OF_SEG)
				  ,.EGR_TDATA_WIDTH     (USER_DATA_WIDTH)
                  ,.ITUSER_MD_WIDTH     (METADATA_CORE_WD)
                  ,.ETUSER_MD_WIDTH     (RX_HSSI_TUSER_MD_WIDTH)
				  ,.NUM_IGR_FIFOS       (12)
				  ,.IGR_FIFO_DEPTH      (IGR_FIFO_DEPTH)
				  ,.SFW_ENABLE          (0)
				  ,.EGR_FIFO_DEPTH      (EGR_FIFO_DEPTH)
				  ,.BYTE_ROTATE         (EGR_USER_BYTE_ROTATE)
				  ,.WADJ_ID             ("USER")
				  ,.BASE_ADDR           (RX_EGR_WADJ_START_ADDR+(num_pp*PORT_OFFSET))
				  ,.MAX_ADDR            ('h8)
			      ,.ADDR_WIDTH          (AWADDR_WIDTH)
			      ,.DATA_WIDTH          (WDATA_WIDTH)
				  ) packet_switch_egr_wadj_USER_inst
				 (
					 .clk (rx_clk[num_pp])
					,.rst (rx_rst_reg[num_pp])

					//-----------------------------------------------------------------------------------------
					// ingress
					,.axi_st_tvalid_i			 (lu2ewadj_tvalid[num_pp][1])
					,.axi_st_tdata_i             (lu2ewadj_tdata[num_pp][1])
					,.axi_st_tkeep_i             (lu2ewadj_tkeep[num_pp][1])
					,.axi_st_tuser_usermetadata_i(lu2ewadj_tuser_usermetadata[num_pp][1])
					,.axi_st_tuser_segment_info_i(lu2ewadj_tuser_segment_info[num_pp][1])
					                           
					,.axi_st_tready_o            (ewadj2lu_tready[num_pp][1])
					//Egress			        
					,.axi_st_tvalid_o            (ewadj_user_tvalid_o[num_pp])
					,.axi_st_tdata_o             (ewadj_user_tdata_o[num_pp])
					,.axi_st_tkeep_o             (ewadj_user_tkeep_o[num_pp])
					,.axi_st_tlast_o             (ewadj_user_tlast_o[num_pp])
					,.axi_st_tuser_last_segment_o(ewadj_user_tlast_segment_o[num_pp])
					,.axi_st_tuser_usermetadata_o(ewadj_user_tuser_usermetadata_o[num_pp])
					,.axi_st_tuser_segment_info_o(ewadj_user_tuser_segment_info_o[num_pp])
					
					,.axi_st_tready_i            (egr2ewadj_tready_i[num_pp][1])

			        // inputs
			        ,.avmm_address   (avmm_address[num_pp])
			        ,.avmm_read      (avmm_read[num_pp])
			        ,.avmm_write     (avmm_write[num_pp])
			        ,.avmm_writedata (avmm_writedata[num_pp])
			        ,.avmm_byteenable (avmm_byteenable[num_pp])
			        
			        // outputs
			        ,.avmm_readdata (ewadj_avmm_rdata[num_pp])  
			        ,.avmm_readdata_valid (ewadj_avmm_rdata_vld[num_pp]) 

			        ,.dbg_cnt_drop_en (ewadj_dbg_cnt_drop_en[num_pp]) 				
				 );
	
			    //Egress Width adjuster to dma dmux
				packet_switch_egr_wadj
				#( .DEVICE_FAMILY       ("Agilex")
				  ,.IGR_SEG_WIDTH       (PIPE_DATA_WIDTH)
				  ,.IGR_NUM_SEG         (1)
				  ,.EGR_NUM_SEG         (DMA_NUM_OF_SEG)
				  ,.EGR_TDATA_WIDTH     (DMA_DATA_WIDTH)
                  ,.ITUSER_MD_WIDTH     (METADATA_CORE_WD)
                  ,.ETUSER_MD_WIDTH     (RX_HSSI_TUSER_MD_WIDTH)
				  ,.NUM_IGR_FIFOS       (12)
				  ,.IGR_FIFO_DEPTH      (IGR_FIFO_DEPTH)
				  ,.SFW_ENABLE          (0)
				  ,.EGR_FIFO_DEPTH      (EGR_FIFO_DEPTH)
                  ,.BYTE_ROTATE         (EGR_DMA_BYTE_ROTATE)
                  ,.WADJ_ID             ("DMA")
				  ) packet_switch_egr_wadj_DMA_inst
				 (
					 .clk (rx_clk[num_pp])
					,.rst (rx_rst_reg[num_pp])

					//-----------------------------------------------------------------------------------------
					// ingress
					,.axi_st_tvalid_i			 (lu2ewadj_tvalid[num_pp][0])
					,.axi_st_tdata_i             (lu2ewadj_tdata[num_pp][0])
					,.axi_st_tkeep_i             (lu2ewadj_tkeep[num_pp][0])
					,.axi_st_tuser_usermetadata_i(lu2ewadj_tuser_usermetadata[num_pp][0])
					,.axi_st_tuser_segment_info_i(lu2ewadj_tuser_segment_info[num_pp][0])
					                           
					,.axi_st_tready_o            (ewadj2lu_tready[num_pp][0])
					//Egress			        
					,.axi_st_tvalid_o            (ewadj_dma_tvalid_o[num_pp])
					,.axi_st_tdata_o             (ewadj_dma_tdata_o[num_pp])
					,.axi_st_tkeep_o             (ewadj_dma_tkeep_o[num_pp])
					,.axi_st_tlast_o             (ewadj_dma_tlast_o[num_pp])
					,.axi_st_tuser_last_segment_o(ewadj_dma_tlast_segment_o[num_pp])
					,.axi_st_tuser_usermetadata_o(ewadj_dma_tuser_usermetadata_o[num_pp])
					,.axi_st_tuser_segment_info_o(ewadj_dma_tuser_segment_info_o[num_pp])
					
					,.axi_st_tready_i            (egr2ewadj_tready_i[num_pp][0])

			        // inputs
			        ,.avmm_address   ('0)
			        ,.avmm_read      ('0)
			        ,.avmm_write     ('0)
			        ,.avmm_writedata ('0)
			        ,.avmm_byteenable ('0)
			        
			        // outputs
			        ,.avmm_readdata ()
			        ,.avmm_readdata_valid ()

			        ,.dbg_cnt_drop_en () // no drop if egr_wadj configured in DMA mode
				 );

		end // for ( num_pp = 0; num_pp < NUM_PIPELINE; num_pp++)
	endgenerate

   //------------------------------------------------------------------------------------------
   // RX Debug Counters


  generate
    if (DBG_CNTR_EN) begin
      packet_switch_rx_dbg #(
				  .NUM_PIPELINE							(NUM_PIPELINE)
				 ,.DMA_CHNL									(DMA_CHNL)
				 ,.DMA_CHNL_PER_PIPE				(DMA_CHNL_PER_PIPE)
				 ,.NUM_EGR_INTF							(NUM_EGR_INTF)
				 ,.CNTR_WIDTH								(CNTR_WIDTH)
         ,.ADDR_WIDTH               (AWADDR_WIDTH)
         ,.DATA_WIDTH               (WDATA_WIDTH)
			) packet_switch_rx_dbg_inst (
         .clk                                    		(rx_clk)
        ,.rst                                    		(rx_rst_reg)

        // avmm interface
        ,.avmm_address                           		(avmm_address)
        ,.avmm_write                             		(avmm_write)
        ,.avmm_writedata                         		(avmm_writedata)
	    ,.avmm_byteenable                               (avmm_byteenable)
        ,.avmm_read                              		(avmm_read)
        ,.avmm_readdata                          		(dbg_avmm_rdata_tmp)
        ,.avmm_readdatavalid                     		(dbg_avmm_rdata_vld_tmp)

				// igr_wadj (recv)
				,.hssi2iwadj_tvalid       							 		(hssi_tvalid_i)
				,.hssi2iwadj_tready       							 		(hssi_tready_o)
				,.hssi2iwadj_tlast       							   		(hssi_tlast_i)

				// igr_wadj (xfer) and igr_parser (recv)
				,.iwadj2pars_tvalid       							 		(iwadj2pars_tvalid)
				,.iwadj2pars_tready       							 		(pars2iwadj_tready)
				,.iwadj2pars_tlast       							   		(iwadj2pars_tlast)

				// igr_parser (xfer) and lkup (recv)
				,.pars2lu_tvalid												 		(pars2lu_tvalid)
				,.pars2lu_tready												 		('1)
				,.pars2lu_seg_info											 		(pars2lu_tuser_segment_info)

				// lkup (xfer) and egr_wadj (recv)
				,.lu2ewadj_tvalid											 	 		(lu2ewadj_tvalid)
				,.lu2ewadj_tready											 	 		(ewadj2lu_tready)
				,.lu2ewadj_seg_info										 	 		(lu2ewadj_tuser_segment_info)

				// lkup (drop)
				,.lk_drop_tvalid												 		(tcam_rsp_tvalid_i)
				,.lk_drop_tuser_result											(tcam_rsp_tuser_result_i)
				,.lk_drop_tuser_found												(tcam_rsp_tuser_found_i)

				// egr_wadj_user (xfer)
				,.ewadj_user_tvalid         								(ewadj_user_tvalid_o)
				,.ewadj_user_tready         								(user_tready_i)
				,.ewadj_user_tlast          								(ewadj_user_tlast_o)

				// egr_wadj_dma (xfer) and dmux (recv)
				,.ewadj_dma_tvalid     											(ewadj_dma_tvalid_o)
				,.ewadj_dma_tready            						  (dmux2ewadj_tready)
				,.ewadj_dma_tlast     											(ewadj_dma_tlast_o)

				// dmux (xfer)
				,.dmux2dma_tvalid														(dma_tvalid_o)
				,.dmux2dma_tready														(dma_tready_i)
				,.dmux2dma_tlast														(dma_tlast_o)

				// drop counters
				,.iwadj_dbg_cnt_drop_en										(iwadj_dbg_cnt_drop_en)
				,.dmux_dbg_cnt_drop_en										(dmux_dbg_cnt_drop_en)
				,.ewadj_dbg_cnt_drop_en										(ewadj_dbg_cnt_drop_en)
      );
    end else begin
      // drive to 0
      always_comb begin
        dbg_avmm_rdata_tmp = '0;
        dbg_avmm_rdata_vld_tmp = '0;
				// dmux_drop_thresh_state = '0;
      end
    end
  endgenerate


   //------------------------------------------------------------------------------------------
   // debug printouts

   `ifdef DBG_STMT_ON

   // synopsys translate_off
  
   logic [31:0][31:0] igr_cnt, egr_dma_cnt, egr_user_cnt, egr_dma_ts_cnt, egr_user_ts_cnt;
   logic [31:0] igr_ts_cnt;

   always_ff @(posedge axi_st_clk[0]) begin
      // igr HSSI
     for (int i = 0; i < NUM_PIPELINE; i = i+1) begin
      if (hssi_tvalid_i[i] & hssi_tlast_i[i] & hssi_tready_o[i]) begin
        igr_cnt[i] <= igr_cnt[i] + 1'b1;
      end

      if (hssi_tvalid_i[i] & hssi_tready_o[i]) begin
	 $display("[PD_DBG] rx_pipe igr_wadj: (hssi_%0d) igr_cnt='d%0d; time=%0t"
          ,i
          ,igr_cnt[i]
          ,$time);

	 $display("[PD_DBG] rx_pipe igr_wadj: (hssi_%0d) igr_cnt='d%0d; data='h%0h; tkeep='h%0h; tlast='h%0h;"
          ,i
          ,igr_cnt[i]
          ,hssi_tdata_i[i]
		  ,hssi_tkeep_i[i]
		  ,hssi_tlast_i[i]);
      end
     end // for

      // egr DMA
     for (int i = 0; i < DMA_CHNL; i = i+1) begin
      if (dma_tvalid_o[i] & dma_tlast_o[i] & dma_tready_i[i]) begin
        egr_dma_cnt[i] <= egr_dma_cnt[i] + 1'b1;
      end

      if (dma_tvalid_o[i] & dma_tready_i[i]) begin
	 $display("[PD_DBG] rx_pipe egr_dma_%0d: egr_dma_cnt='d%0d; time=%0t"
          ,i
          ,egr_dma_cnt[i]
          ,$time);

	 $display("[PD_DBG] rx_pipe egr_dma_%0d: egr_dma_cnt='d%0d; data='h%0h; tkeep='h%0h; tlast='h%0h;"
          ,i
          ,egr_dma_cnt[i]
		  ,dma_tdata_o[i]
		  ,dma_tkeep_o[i]
		  ,dma_tlast_o[i]);

      end
     end // for
   
      // egr USER
     for (int i = 0; i < NUM_PIPELINE; i = i+1) begin
      if (user_tvalid_o[i] & user_tlast_o[i] & user_tready_i[i]) begin
        egr_user_cnt[i] <= egr_user_cnt[i] + 1'b1;
      end

      if (user_tvalid_o[i] & user_tready_i[i]) begin
	 $display("[PD_DBG] rx_pipe egr_user_%0d: egr_user_cnt='d%0d; time=%0t"
          ,i
          ,egr_user_cnt[i]
          ,$time);

	 $display("[PD_DBG] rx_pipe egr_user_%0d: egr_user_cnt='d%0d; data='h%0h; tkeep='h%0h; tlast='h%0h;"
          ,i
          ,egr_user_cnt[i]
		  ,user_tdata_o[i]
		  ,user_tkeep_o[i]
		  ,user_tlast_o[i]);

      end
     end // for

    //=========================================================================================
    // Time Stamp Interface
 
     // igr HSSI
    //  if (hssi_igrts0_tvalid_i) begin
    //    igr_ts_cnt <= igr_ts_cnt + 1'b1;
	// 
    // $display("[PD_DBG] rx_pipe igr_timestamp: igr_ts_cnt='d%0d; time=%0t"
    //       ,igr_ts_cnt
    //       ,$time);
	// 
    // $display("[PD_DBG] rx_pipe igr_timestamp: igr_ts_cnt='d%0d; hssi_igrts0_tvalid_i='h%0h; hssi_igrts0_tdata_i='h%0h;"
    //       ,igr_ts_cnt
    //       ,hssi_igrts0_tvalid_i
    //       ,hssi_igrts0_tdata_i);
	// 
    // $display("[PD_DBG] rx_pipe igr_timestamp: igr_ts_cnt='d%0d; hssi_igrts1_tvalid_i='h%0h; hssi_igrts1_tdata_i='h%0h;"
    //       ,igr_ts_cnt
    //       ,hssi_igrts1_tvalid_i
    //       ,hssi_igrts1_tdata_i);
    //   end

     // egr DMA
    for (int i = 0; i < DMA_CHNL; i = i+1) begin
     if (dma_igrts0_tvalid_o[i]) begin
       egr_dma_ts_cnt[i] <= egr_dma_ts_cnt[i] + 1'b1;

    $display("[PD_DBG] rx_pipe egr_timestamp: (DMA_%0d) egr_ts_cnt='d%0d; time=%0t"
          ,i
          ,egr_dma_ts_cnt[i]
          ,$time);

    $display("[PD_DBG] rx_pipe egr_timestamp: (DMA_%0d) egr_ts_cnt='d%0d; dma_igrts0_tvalid_o='h%0h; dma_igrts0_tdata_o='h%0h;"
          ,i
          ,egr_dma_ts_cnt[i]
          ,dma_igrts0_tvalid_o[i]
          ,dma_igrts0_tdata_o[i]);

    $display("[PD_DBG] rx_pipe egr_timestamp: (DMA_%0d) egr_ts_cnt='d%0d; dma_igrts1_tvalid_o='h%0h; dma_igrts1_tdata_o='h%0h;"
          ,i
          ,egr_dma_ts_cnt[i]
          ,dma_igrts1_tvalid_o[i]
          ,dma_igrts1_tdata_o[i]);
     end
    end // for

     // egr USER
    for (int i = 0; i < NUM_PIPELINE; i = i+1) begin
     if (user_igrts0_tvalid_o[i]) begin
       egr_user_ts_cnt[i] <= egr_user_ts_cnt[i] + 1'b1;

    $display("[PD_DBG] rx_pipe egr_timestamp: (USER_%0d) egr_ts_cnt='d%0d; time=%0t"
          ,i
          ,egr_user_ts_cnt[i]
          ,$time);

    $display("[PD_DBG] rx_pipe egr_timestamp: (USER_%0d) egr_ts_cnt='d%0d; user_igrts0_tvalid_o='h%0h; user_igrts0_tdata_o='h%0h;"
          ,i
          ,egr_user_ts_cnt[i]
          ,user_igrts0_tvalid_o[i]
          ,user_igrts0_tdata_o[i]);

    $display("[PD_DBG] rx_pipe egr_timestamp: (USER_%0d) egr_ts_cnt='d%0d; user_igrts1_tvalid_o='h%0h; user_igrts1_tdata_o='h%0h;"
          ,i
          ,egr_user_ts_cnt[i]
          ,user_igrts1_tvalid_o[i]
          ,user_igrts1_tdata_o[i]);
     end
    end // for

      if (rx_rst[0]) begin
        igr_cnt <= '0;
        igr_ts_cnt <= '0;
        egr_dma_cnt <= '0;
        egr_user_cnt <= '0;
        egr_dma_ts_cnt <= '0;
        egr_user_ts_cnt <= '0;
      end
   end		
   // synopsys translate_on
 `endif


endmodule // packet_switch_rx