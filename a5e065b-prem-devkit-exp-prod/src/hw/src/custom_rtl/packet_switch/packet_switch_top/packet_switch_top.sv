//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

//---------------------------------------------------------------------------------------------
// Description: This is the top level of PTP Switch System Example Design(packet_switch_top.sv)			
// 	- All the top level parameters & Interfaces listed in here		
//	- In this module, the following blocks are integrated
//		csr interface 	--> packet_switch_axi_lt_avmm.sv
//		tx path	        --> packet_switch_tx.sv
//		rx path	        --> packet_switch_rx.sv
//--------------------------------------------------------------------------------------------			


module packet_switch_top
  #(   
	 parameter HSSI_PORT                       = 1   // number of HSSI ports
	,parameter USER_PORT                       = HSSI_PORT  // number of User ports
	,parameter DMA_CHNL                        = 1   // total number of DMA channels
	
    ,parameter HSSI_DATA_WIDTH	               = 64  // supports 64/128/512b
    ,parameter USER_DATA_WIDTH                 = 64  // supports 64/128/512b
	,parameter DMA_DATA_WIDTH                  = 64   // supports only 64b
    
    ,parameter HSSI_NUM_OF_SEG                 = 1    // supports only 1
    ,parameter USER_NUM_OF_SEG                 = 1    // supports only 1
    ,parameter DMA_NUM_OF_SEG                  = 1    // supports only 1

    ,parameter HSSI_IGR_FIFO_DEPTH             = (HSSI_DATA_WIDTH == 64) ? 2048 : 4096
    ,parameter USER_IGR_FIFO_DEPTH             = 512
    ,parameter DMA_IGR_FIFO_DEPTH              = 512
	
    ,parameter TX_CLIENT_WIDTH                 = 2
    ,parameter RX_CLIENT_WIDTH                 = 7

    ,parameter TXEGR_TS_DW                     = 128
    ,parameter RXIGR_TS_DW                     = 96

    ,parameter SYS_FINGERPRINT_WIDTH           = 20 // system specified fingerprint width. max:28.
	
    ,parameter PTP_WIDTH                       = 94
    ,parameter PTP_EXT_WIDTH                   = 328
    ,parameter STS_WIDTH                       = 4
    ,parameter STS_EXT_WIDTH                   = 32
	
    ,parameter AWADDR_WIDTH                    = 16
    ,parameter WDATA_WIDTH                     = 32	
	
    ,parameter TCAM_KEY_WIDTH                  = 492
    ,parameter TCAM_RESULT_WIDTH               = 32
    ,parameter TCAM_ENTRIES                    = 64
    ,parameter TCAM_USERMETADATA_WIDTH         = 1

    // default: HSSI, msgDMA, and User are all little endian
    ,parameter IGR_DMA_BYTE_ROTATE             = 0
    ,parameter IGR_USER_BYTE_ROTATE            = 0
    ,parameter IGR_HSSI_BYTE_ROTATE            = 1

    // default: HSSI, msgDMA, and User are all little endian
    ,parameter EGR_DMA_BYTE_ROTATE             = 1
    ,parameter EGR_USER_BYTE_ROTATE            = 1
    ,parameter EGR_HSSI_BYTE_ROTATE            = 0

    ,parameter DBG_CNTR_EN                     = 0
    )

   ( //---------------------------------------------------------------------------------------
  
	 
	//AXI Streaming Interface     
	// Tx streaming clock
     input var logic [HSSI_PORT-1:0]               tx_clk_i
    ,input var logic [HSSI_PORT-1:0]               tx_areset_n_i	
     // Rx streaming clock & reset                 
    ,input var logic [HSSI_PORT-1:0]               rx_clk_i
    ,input var logic [HSSI_PORT-1:0]               rx_areset_n_i	
												   
    // axi_lite csr clock & reset                  
    ,input var logic                               axi_lite_clk_i	  
    ,input var logic                               axi_lite_rst_n_i
    //----------------------------------------------------------------------------------------- 
    // init_done status
    ,output var logic [HSSI_PORT-1:0]              tx_init_done_o	
    ,output var logic [HSSI_PORT-1:0]              rx_init_done_o	
    //-----------------------------------------------------------------------------------------
    // axi_lite: sync to axi_lite_clk_i, use as osc_ovs system csr interface
    //-----WRITE ADDRESS CHANNEL-------
    ,input var logic [AWADDR_WIDTH - 1:0]          axi_lite_awaddr_i
    ,input var logic                               axi_lite_awvalid_i 
    ,output var logic                              axi_lite_awready_o 
    //---------------------------------            
    //-----WRITE DATA CHANNEL----------            
    ,input var logic [WDATA_WIDTH - 1:0]           axi_lite_wdata_i 
    ,input var logic                               axi_lite_wvalid_i 
    ,output var logic                              axi_lite_wready_o 
    ,input var logic [(WDATA_WIDTH/8) - 1:0]       axi_lite_wstrb_i
    //---------------------------------            
    //-----WRITE RESPONSE CHANNEL------            
    ,output var logic [1:0]                        axi_lite_bresp_o 
    ,output var logic                              axi_lite_bvalid_o 
    ,input var logic                               axi_lite_bready_i 
    //---------------------------------            
    //-----READ ADDRESS CHANNEL-------             
    ,input var logic [AWADDR_WIDTH - 1:0]          axi_lite_araddr_i 
    ,input var logic                               axi_lite_arvalid_i 
    ,output var logic                              axi_lite_arready_o 
    //---------------------------------            
    //-----READ DATA CHANNEL----------             
    ,output var logic [1:0]                        axi_lite_rresp_o 
    ,output var logic [WDATA_WIDTH - 1:0]          axi_lite_rdata_o
    ,output var logic                              axi_lite_rvalid_o
    ,input var logic                               axi_lite_rready_i
    
    //-----------------------------------------------------------------------------------------
    // TCAM csr interface: 

    //-----WRITE ADDRESS CHANNEL-------
    ,output var logic [HSSI_PORT-1:0][AWADDR_WIDTH - 1:0]     axi_lite_tcam_awaddr_o 
    ,output var logic [HSSI_PORT-1:0]                         axi_lite_tcam_awvalid_o
															  
    ,input var logic [HSSI_PORT-1:0]                          axi_lite_tcam_awready_i
											
     //-----WRITE DATA CHANNEL----------                           
    ,output var logic [HSSI_PORT-1:0] [WDATA_WIDTH - 1:0]     axi_lite_tcam_wdata_o 
    ,output var logic  [HSSI_PORT-1:0]                        axi_lite_tcam_wvalid_o
    ,output var logic [HSSI_PORT-1:0] [(WDATA_WIDTH/8) - 1:0] axi_lite_tcam_wstrb_o
							     			                 
    ,input var logic [HSSI_PORT-1:0]                          axi_lite_tcam_wready_i
								     		                
     //-----WRITE RESPONSE CHANNEL------                           
    ,input var logic [HSSI_PORT-1:0][1:0]                     axi_lite_tcam_bresp_i 
    ,input var logic  [HSSI_PORT-1:0]                         axi_lite_tcam_bvalid_i
									     		
    ,output var logic [HSSI_PORT-1:0]                         axi_lite_tcam_bready_o 
									     		      
     //-----READ ADDRESS CHANNEL-------                            
    ,output var logic [HSSI_PORT-1:0] [AWADDR_WIDTH - 1:0]    axi_lite_tcam_araddr_o 
    ,output var logic [HSSI_PORT-1:0]                         axi_lite_tcam_arvalid_o
									      		    
    ,input var logic [HSSI_PORT-1:0]                          axi_lite_tcam_arready_i 
									      	
     //-----READ DATA CHANNEL----------                        
    ,input var logic [HSSI_PORT-1:0][1:0]                     axi_lite_tcam_rresp_i
     
    ,input var logic [HSSI_PORT-1:0] [WDATA_WIDTH - 1:0]      axi_lite_tcam_rdata_i
    ,input var logic [HSSI_PORT-1:0]                          axi_lite_tcam_rvalid_i   
											
    ,output var logic [HSSI_PORT-1:0]                         axi_lite_tcam_rready_o    
    //-----------------------------------------------------------------------------------------     
    //=========================================================================================
    // TX Interface:  
    //-----------------------------------------------------------------------------------------
    // tx ingress interface - Input from DMA
    ,input var logic [DMA_CHNL-1:0]                          dma_axi_st_tx_tvalid_i
    ,input var logic [DMA_CHNL-1:0][DMA_DATA_WIDTH-1:0]      dma_axi_st_tx_tdata_i
    ,input var logic [DMA_CHNL-1:0][DMA_DATA_WIDTH/8-1:0]    dma_axi_st_tx_tkeep_i
    ,input var logic [DMA_CHNL-1:0]                          dma_axi_st_tx_tlast_i
    ,input var logic [DMA_CHNL-1:0][PTP_WIDTH-1:0]           dma_axi_st_tx_tuser_ptp_i
    ,input var logic [DMA_CHNL-1:0][PTP_EXT_WIDTH-1:0]       dma_axi_st_tx_tuser_ptp_extended_i
    ,input var logic [DMA_CHNL-1:0][DMA_NUM_OF_SEG-1:0]
                                     [TX_CLIENT_WIDTH-1:0]   dma_axi_st_tx_tuser_client_i
    ,input var logic [DMA_CHNL-1:0][DMA_NUM_OF_SEG-1:0]      dma_axi_st_tx_tuser_pkt_seg_parity_i
    ,input var logic [DMA_CHNL-1:0][DMA_NUM_OF_SEG-1:0]      dma_axi_st_tx_tuser_last_segment_i
																 
    ,output var logic [DMA_CHNL-1:0]                         dma_axi_st_tx_tready_o
	//-----------------------------------------------------------------------------------------
    // tx ingress interface - Input from USER
    ,input var logic [USER_PORT-1:0]                              user_axi_st_tx_tvalid_i
    ,input var logic [USER_PORT-1:0][USER_DATA_WIDTH-1:0]         user_axi_st_tx_tdata_i
    ,input var logic [USER_PORT-1:0][USER_DATA_WIDTH/8-1:0]       user_axi_st_tx_tkeep_i
    ,input var logic [USER_PORT-1:0]                              user_axi_st_tx_tlast_i
    ,input var logic [USER_PORT-1:0][PTP_WIDTH-1:0]               user_axi_st_tx_tuser_ptp_i
    ,input var logic [USER_PORT-1:0][PTP_EXT_WIDTH-1:0]           user_axi_st_tx_tuser_ptp_extended_i
    ,input var logic [USER_PORT-1:0][USER_NUM_OF_SEG-1:0] 
                                      [TX_CLIENT_WIDTH-1:0]       user_axi_st_tx_tuser_client_i
    ,input var logic [USER_PORT-1:0][USER_NUM_OF_SEG-1:0]         user_axi_st_tx_tuser_pkt_seg_parity_i
    ,input var logic [USER_PORT-1:0][USER_NUM_OF_SEG-1:0]         user_axi_st_tx_tuser_last_segment_i
												   
    ,output var logic [USER_PORT-1:0]                             user_axi_st_tx_tready_o

    //-----------------------------------------------------------------------------------------
    // tx egress interface - Outputs to HSSI
    ,output var logic [HSSI_PORT-1:0]                             hssi_axi_st_tx_tvalid_o
    ,output var logic [HSSI_PORT-1:0][HSSI_DATA_WIDTH-1:0]        hssi_axi_st_tx_tdata_o
    ,output var logic [HSSI_PORT-1:0][HSSI_DATA_WIDTH/8-1:0]      hssi_axi_st_tx_tkeep_o
    ,output var logic [HSSI_PORT-1:0]                             hssi_axi_st_tx_tlast_o
    ,output var logic [HSSI_PORT-1:0][PTP_WIDTH-1:0]              hssi_axi_st_tx_tuser_ptp_o
    ,output var logic [HSSI_PORT-1:0][PTP_EXT_WIDTH -1:0]         hssi_axi_st_tx_tuser_ptp_extended_o
    ,output var logic [HSSI_PORT-1:0][HSSI_NUM_OF_SEG-1:0]
                                       [TX_CLIENT_WIDTH-1:0]      hssi_axi_st_tx_tuser_client_o
    ,output var logic [HSSI_PORT-1:0][HSSI_NUM_OF_SEG-1:0]        hssi_axi_st_tx_tuser_pkt_seg_parity_o
    ,output var logic [HSSI_PORT-1:0][HSSI_NUM_OF_SEG-1:0]        hssi_axi_st_tx_tuser_last_segment_o
					                               
    ,input var logic  [HSSI_PORT-1:0]                             hssi_axi_st_tx_tready_i

    //=========================================================================================
    // RX Interface
    //-----------------------------------------------------------------------------------------
    // rx ingress interface -  Inputs from HSSI
    ,input var logic [HSSI_PORT-1:0]                              hssi_axi_st_rx_tvalid_i
    ,input var logic [HSSI_PORT-1:0][HSSI_DATA_WIDTH-1:0]         hssi_axi_st_rx_tdata_i
    ,input var logic [HSSI_PORT-1:0][HSSI_DATA_WIDTH/8-1:0]       hssi_axi_st_rx_tkeep_i
    ,input var logic [HSSI_PORT-1:0]                              hssi_axi_st_rx_tlast_i
    //Rx Packet Error Status                                      
    ,input var logic [HSSI_PORT-1:0][HSSI_NUM_OF_SEG-1:0]
                                      [RX_CLIENT_WIDTH-1:0]       hssi_axi_st_rx_tuser_client_i
    //Rx Packet Status                                            
    ,input var logic [HSSI_PORT-1:0][HSSI_NUM_OF_SEG-1:0]         
									   [STS_WIDTH-1:0]            hssi_axi_st_rx_tuser_sts_i
    ,input var logic [HSSI_PORT-1:0][HSSI_NUM_OF_SEG-1:0]
                                       [STS_EXT_WIDTH-1:0]        hssi_axi_st_rx_tuser_sts_extended_i
    ,input var logic [HSSI_PORT-1:0][HSSI_NUM_OF_SEG-1:0]         hssi_axi_st_rx_tuser_pkt_seg_parity_i
    ,input var logic [HSSI_PORT-1:0][HSSI_NUM_OF_SEG-1:0]         hssi_axi_st_rx_tuser_last_segment_i
    ,output var logic [HSSI_PORT-1:0]                             hssi_axi_st_rx_pause_o
															  
    ,output var logic [HSSI_PORT-1:0]                             hssi_axi_st_rx_tready_o

    //-----------------------------------------------------------------------------------------
    // rx egress interface - Output to DMA
    ,output var logic [DMA_CHNL-1:0]                              dma_axi_st_rx_tvalid_o
    ,output var logic [DMA_CHNL-1:0][DMA_DATA_WIDTH-1:0]          dma_axi_st_rx_tdata_o
    ,output var logic [DMA_CHNL-1:0][DMA_DATA_WIDTH/8-1:0]        dma_axi_st_rx_tkeep_o
    ,output var logic [DMA_CHNL-1:0]                              dma_axi_st_rx_tlast_o
    //Rx Packet Error Status                                      
    ,output var logic [DMA_CHNL-1:0][DMA_NUM_OF_SEG-1:0]
                                        [RX_CLIENT_WIDTH-1:0]     dma_axi_st_rx_tuser_client_o
    //Rx Packet Status                                          
    ,output var logic [DMA_CHNL-1:0][DMA_NUM_OF_SEG-1:0]
                                        [STS_WIDTH-1:0]           dma_axi_st_rx_tuser_sts_o
    ,output var logic [DMA_CHNL-1:0][DMA_NUM_OF_SEG-1:0]
                                        [STS_EXT_WIDTH-1:0]       dma_axi_st_rx_tuser_sts_extended_o
    ,output var logic [DMA_CHNL-1:0][DMA_NUM_OF_SEG-1:0]          dma_axi_st_rx_tuser_pkt_seg_parity_o
    ,output var logic [DMA_CHNL-1:0][DMA_NUM_OF_SEG-1:0]          dma_axi_st_rx_tuser_last_segment_o
																  
    ,input var logic [DMA_CHNL-1:0]                               dma_axi_st_rx_tready_i
    //-----------------------------------------------------------------------------------------
    // rx egress interface - Output to USER
    ,output var logic [USER_PORT-1:0]                             user_axi_st_rx_tvalid_o
    ,output var logic [USER_PORT-1:0] [USER_DATA_WIDTH-1:0]       user_axi_st_rx_tdata_o
    ,output var logic [USER_PORT-1:0] [USER_DATA_WIDTH/8-1:0]     user_axi_st_rx_tkeep_o
    ,output var logic [USER_PORT-1:0]                             user_axi_st_rx_tlast_o
    //Rx Packet Error Status                       
    ,output var logic [USER_PORT-1:0][USER_NUM_OF_SEG-1:0]
                                       [RX_CLIENT_WIDTH-1:0]      user_axi_st_rx_tuser_client_o
    //Rx Packet Status                             
    ,output var logic [USER_PORT-1:0][USER_NUM_OF_SEG-1:0] 
									    [STS_WIDTH-1:0]           user_axi_st_rx_tuser_sts_o
    ,output var logic [USER_PORT-1:0][USER_NUM_OF_SEG-1:0]
                                        [STS_EXT_WIDTH-1:0]       user_axi_st_rx_tuser_sts_extended_o
    ,output var logic [USER_PORT-1:0][USER_NUM_OF_SEG-1:0]        user_axi_st_rx_tuser_pkt_seg_parity_o
    ,output var logic [USER_PORT-1:0][USER_NUM_OF_SEG-1:0]        user_axi_st_rx_tuser_last_segment_o
												   
    ,input var logic  [USER_PORT-1:0]                             user_axi_st_rx_tready_i

    //=========================================================================================
    // Time Stamp Interface:
    //-----------------------------------------------------------------------------------------
    // tx egress timestamp from HSSI
    ,input var logic [HSSI_PORT-1:0]                              hssi_axi_st_txegrts0_tvalid_i
    ,input var logic [HSSI_PORT-1:0][TXEGR_TS_DW-1:0]             hssi_axi_st_txegrts0_tdata_i
    ,input var logic [HSSI_PORT-1:0]                              hssi_axi_st_txegrts1_tvalid_i
    ,input var logic [HSSI_PORT-1:0][TXEGR_TS_DW-1:0]             hssi_axi_st_txegrts1_tdata_i
															      
     // tx egress timestamp to DMA                                
    ,output var logic [DMA_CHNL-1:0]                              dma_axi_st_txegrts0_tvalid_o
    ,output var logic [DMA_CHNL-1:0][TXEGR_TS_DW-1:0]             dma_axi_st_txegrts0_tdata_o 
    ,output var logic [DMA_CHNL-1:0]                              dma_axi_st_txegrts1_tvalid_o
    ,output var logic [DMA_CHNL-1:0][TXEGR_TS_DW-1:0]             dma_axi_st_txegrts1_tdata_o 
															      
     // tx egress timestamp to USER                               
    ,output var logic [USER_PORT-1:0]                             user_axi_st_txegrts0_tvalid_o
    ,output var logic [USER_PORT-1:0][TXEGR_TS_DW-1:0]            user_axi_st_txegrts0_tdata_o
    ,output var logic [USER_PORT-1:0]                             user_axi_st_txegrts1_tvalid_o
    ,output var logic [USER_PORT-1:0][TXEGR_TS_DW-1:0]            user_axi_st_txegrts1_tdata_o

    //-----------------------------------------------------------------------------------------
    // rx ingress timestamp from HSSI
    ,input var logic [HSSI_PORT-1:0]                              hssi_axi_st_rxigrts0_tvalid_i
    ,input var logic [HSSI_PORT-1:0][RXIGR_TS_DW-1:0]             hssi_axi_st_rxigrts0_tdata_i
    ,input var logic [HSSI_PORT-1:0]                              hssi_axi_st_rxigrts1_tvalid_i
    ,input var logic [HSSI_PORT-1:0][RXIGR_TS_DW-1:0]             hssi_axi_st_rxigrts1_tdata_i
																  
    // rx ingress timestamp to DMA                                
    ,output var logic [DMA_CHNL-1:0]                              dma_axi_st_rxigrts0_tvalid_o
    ,output var logic [DMA_CHNL-1:0][RXIGR_TS_DW-1:0]             dma_axi_st_rxigrts0_tdata_o
    ,output var logic [DMA_CHNL-1:0]                              dma_axi_st_rxigrts1_tvalid_o
    ,output var logic [DMA_CHNL-1:0][RXIGR_TS_DW-1:0]             dma_axi_st_rxigrts1_tdata_o
																  
    // rx ingress timestamp to USER                               
    ,output var logic [USER_PORT-1:0]                             user_axi_st_rxigrts0_tvalid_o
    ,output var logic [USER_PORT-1:0][RXIGR_TS_DW-1:0]            user_axi_st_rxigrts0_tdata_o
    ,output var logic [USER_PORT-1:0]                             user_axi_st_rxigrts1_tvalid_o
    ,output var logic [USER_PORT-1:0][RXIGR_TS_DW-1:0]            user_axi_st_rxigrts1_tdata_o
    //-----------------------------------------------------------------------------------------
	//=========================================================================================
	//TCAM Interface signals
	//-----------------------------------------------------------------------------------------
	//TCAM Request Interface
	,input var logic  [HSSI_PORT-1:0]                               tcam_req_tready_i
	,output var logic [HSSI_PORT-1:0]                               tcam_req_tvalid_o
	,output var logic [HSSI_PORT-1:0][TCAM_KEY_WIDTH-1:0]           tcam_req_tuser_key_o
	,output var logic [HSSI_PORT-1:0][TCAM_USERMETADATA_WIDTH-1:0]  tcam_req_tuser_usermetadata_o
	//----------------------------------------------------------------------------------------------
	//TCAM Response Interface
	,output var logic [HSSI_PORT-1:0]                               tcam_rsp_tready_o
	,input var logic [HSSI_PORT-1:0]                                tcam_rsp_tvalid_i
	,input var logic [HSSI_PORT-1:0]                                tcam_rsp_tuser_found_i
	,input var logic [HSSI_PORT-1:0][TCAM_RESULT_WIDTH-1:0]         tcam_rsp_tuser_result_i
	,input var logic [HSSI_PORT-1:0][TCAM_ENTRIES-1:0]              tcam_rsp_tuser_match_array_i 
	,input var logic [HSSI_PORT-1:0][$clog2(TCAM_ENTRIES)-1:0]      tcam_rsp_tuser_entry_i 
	,input var logic [HSSI_PORT-1:0][TCAM_USERMETADATA_WIDTH-1:0]   tcam_rsp_tuser_usermetadata_i
   );
   //-----------------------------------------end of top level interfaces

	import packet_switch_pkg::*; 
   // import packet_switch_hdr_pkg::*;

	
	localparam AVMM_MAX_LATENCY = 5;
	localparam NUM_PIPELINE = USER_PORT;
	
	logic axi_lite_rst; 
    logic [HSSI_PORT-1:0] axi_st_tx_rst, axi_st_rx_rst;
	logic [AWADDR_WIDTH-1:0]    avmm_address;
	logic                       avmm_read;
	logic [WDATA_WIDTH-1:0]     avmm_readdata, 
								avmm_readdata_tx, 
								avmm_readdata_rx ;
	logic                       avmm_write;
	logic [WDATA_WIDTH-1:0]     avmm_writedata;
	logic                       avmm_readdata_valid, 
								avmm_readdata_valid_tx, 
								avmm_readdata_valid_rx;

    logic [HSSI_PORT-1:0][AWADDR_WIDTH-1:0]    tx_avmm_address;
    logic [HSSI_PORT-1:0]                      tx_avmm_read;
    logic [HSSI_PORT-1:0]                      tx_avmm_write;
    logic [HSSI_PORT-1:0][WDATA_WIDTH-1:0]     tx_avmm_writedata;
    logic [HSSI_PORT-1:0][(WDATA_WIDTH/8)-1:0] tx_avmm_byteenable;
    
    logic [HSSI_PORT-1:0][WDATA_WIDTH-1:0]    tx_avmm_readdata; 
    logic [HSSI_PORT-1:0]                     tx_avmm_readdata_valid;
    					       
    logic [HSSI_PORT-1:0][AWADDR_WIDTH-1:0]    rx_avmm_address;
    logic [HSSI_PORT-1:0]                      rx_avmm_read;
    logic [HSSI_PORT-1:0]                      rx_avmm_write;
    logic [HSSI_PORT-1:0][WDATA_WIDTH-1:0]     rx_avmm_writedata;
    logic [HSSI_PORT-1:0][(WDATA_WIDTH/8)-1:0] rx_avmm_byteenable;
    logic [HSSI_PORT-1:0][WDATA_WIDTH-1:0]     rx_avmm_readdata;
    logic [HSSI_PORT-1:0]                      rx_avmm_readdata_valid;

    localparam MAX_NUM_PIPELINE = 8;

    logic [MAX_NUM_PIPELINE-1:0] axi_lite_awready_w, axi_lite_wready_w,
      axi_lite_bvalid_w, axi_lite_arready_w, axi_lite_rvalid_w;
    logic [MAX_NUM_PIPELINE-1:0][1:0] axi_lite_bresp_w;
    logic [MAX_NUM_PIPELINE-1:0][1:0]axi_lite_rresp_w;
    logic [MAX_NUM_PIPELINE-1:0][WDATA_WIDTH-1:0]axi_lite_rdata_w;

	//--------------------------------------------------------------------
	// axi_lite reset
	ipbb_asyn_to_syn_rst lite_rst_sync
	 (.clk (axi_lite_clk_i)
	  ,.asyn_rst (!axi_lite_rst_n_i)

	  // output
	  ,.syn_rst (axi_lite_rst)
	  ); 
 
    genvar i;
    generate
     for (i = 0; i < HSSI_PORT; i = i+1) begin : gen_rst_sync

	//---------------------------------------------------------------------
	// TX axi_st reset
	ipbb_asyn_to_syn_rst tx_rst_sync
	 (.clk (tx_clk_i[i])
	  ,.asyn_rst (!tx_areset_n_i[i])

	  // output
	  ,.syn_rst (axi_st_tx_rst[i])
	  ); 
	//---------------------------------------------------------------------
	// RX axi_st reset
	ipbb_asyn_to_syn_rst rx_rst_sync
	 (.clk (rx_clk_i[i])
	  ,.asyn_rst (!rx_areset_n_i[i])

	  // output
	  ,.syn_rst (axi_st_rx_rst[i])
	  ); 
     end
    endgenerate	
	
   //----------------------------------------------------------------------
   //TX Path - packet_switch_tx
   packet_switch_tx
    #( .NUM_PIPELINE    (NUM_PIPELINE)
      ,.DMA_CHNL        (DMA_CHNL    )
      ,.DMA_DATA_WIDTH  (DMA_DATA_WIDTH ) 
      ,.USER_DATA_WIDTH (USER_DATA_WIDTH)
      ,.HSSI_DATA_WIDTH (HSSI_DATA_WIDTH)
      ,.DMA_NUM_OF_SEG  (DMA_NUM_OF_SEG )
      ,.HSSI_NUM_OF_SEG (HSSI_NUM_OF_SEG)
      ,.USER_NUM_OF_SEG (USER_NUM_OF_SEG)
      ,.USER_IGR_FIFO_DEPTH (USER_IGR_FIFO_DEPTH)
      ,.DMA_IGR_FIFO_DEPTH (DMA_IGR_FIFO_DEPTH)
      ,.TXEGR_TS_DW     (TXEGR_TS_DW    )
      ,.SYS_FINGERPRINT_WIDTH (SYS_FINGERPRINT_WIDTH)
      ,.PTP_WIDTH       (PTP_WIDTH      )
      ,.PTP_EXT_WIDTH   (PTP_EXT_WIDTH  )
      ,.AWADDR_WIDTH    (AWADDR_WIDTH   )
      ,.WDATA_WIDTH     (WDATA_WIDTH    )
      ,.TX_CLIENT_WIDTH (TX_CLIENT_WIDTH)
      ,.IGR_DMA_BYTE_ROTATE (IGR_DMA_BYTE_ROTATE)
      ,.IGR_USER_BYTE_ROTATE (IGR_USER_BYTE_ROTATE)
      ,.EGR_HSSI_BYTE_ROTATE (EGR_HSSI_BYTE_ROTATE)
      ,.DBG_CNTR_EN          (DBG_CNTR_EN)
      ) packet_switch_tx_inst
   (
     .axi_st_clk               (tx_clk_i)
	,.axi_st_rst_n             (tx_areset_n_i)
	,.init_done	               (tx_init_done_o)
	//Avalon MM                
	,.avmm_address               (tx_avmm_address)
	,.avmm_read                  (tx_avmm_read)
	,.avmm_readdata              (tx_avmm_readdata)
	,.avmm_write                 (tx_avmm_write)
	,.avmm_writedata             (tx_avmm_writedata)
	,.avmm_byteenable            (tx_avmm_byteenable)
	,.avmm_readdata_valid        (tx_avmm_readdata_valid)

    //=========================================================================================
    // TX Interface:  Inputs from DMA
    // inputs
    ,.dma_tvalid_i               (dma_axi_st_tx_tvalid_i)
    ,.dma_tdata_i                (dma_axi_st_tx_tdata_i)
    ,.dma_tkeep_i                (dma_axi_st_tx_tkeep_i)
    ,.dma_tlast_i                (dma_axi_st_tx_tlast_i)
    ,.dma_tuser_ptp_i            (dma_axi_st_tx_tuser_ptp_i)
    ,.dma_tuser_ptp_extended_i   (dma_axi_st_tx_tuser_ptp_extended_i)
    ,.dma_tuser_client_i         (dma_axi_st_tx_tuser_client_i)
    ,.dma_tuser_pkt_seg_parity_i (dma_axi_st_tx_tuser_pkt_seg_parity_i)
    ,.dma_tuser_last_segment_i   (dma_axi_st_tx_tuser_last_segment_i)
    //output 
    ,.dma_tready_o (dma_axi_st_tx_tready_o)
    //=========================================================================================
    // TX Interface:  Inputs from Userlogic
    // inputs
    ,.user_tvalid_i              (user_axi_st_tx_tvalid_i)
    ,.user_tdata_i               (user_axi_st_tx_tdata_i)
    ,.user_tkeep_i               (user_axi_st_tx_tkeep_i)
    ,.user_tlast_i               (user_axi_st_tx_tlast_i)
    ,.user_tuser_ptp_i           (user_axi_st_tx_tuser_ptp_i)
    ,.user_tuser_ptp_extended_i  (user_axi_st_tx_tuser_ptp_extended_i)
    ,.user_tuser_client_i        (user_axi_st_tx_tuser_client_i)
    ,.user_tuser_pkt_seg_parity_i(user_axi_st_tx_tuser_pkt_seg_parity_i)
    ,.user_tuser_last_segment_i  (user_axi_st_tx_tuser_last_segment_i)
	//output
    ,.user_tready_o (user_axi_st_tx_tready_o)
    //-----------------------------------------------------------------------------------------
    // tx egress interface: Outputs to HSSI
    // outputs
    ,.hssi_tvalid_o              (hssi_axi_st_tx_tvalid_o)
    ,.hssi_tdata_o               (hssi_axi_st_tx_tdata_o)
    ,.hssi_tkeep_o               (hssi_axi_st_tx_tkeep_o)
    ,.hssi_tlast_o               (hssi_axi_st_tx_tlast_o)
    ,.hssi_tuser_ptp_o           (hssi_axi_st_tx_tuser_ptp_o)
    ,.hssi_tuser_ptp_extended_o  (hssi_axi_st_tx_tuser_ptp_extended_o)
    ,.hssi_tuser_client_o        (hssi_axi_st_tx_tuser_client_o)
    ,.hssi_tuser_pkt_seg_parity_o(hssi_axi_st_tx_tuser_pkt_seg_parity_o)
    ,.hssi_tuser_last_segment_o  (hssi_axi_st_tx_tuser_last_segment_o)
    // inputs
    ,.hssi_tready_i (hssi_axi_st_tx_tready_i)

    //=========================================================================================
    // Time Stamp Interface:  tx egress timestamp from HSSI interface
    // inputs
    ,.hssi_egrts0_tvalid_i (hssi_axi_st_txegrts0_tvalid_i)
    ,.hssi_egrts0_tdata_i  (hssi_axi_st_txegrts0_tdata_i)
    ,.hssi_egrts1_tvalid_i (hssi_axi_st_txegrts1_tvalid_i)
    ,.hssi_egrts1_tdata_i  (hssi_axi_st_txegrts1_tdata_i)

    //  tx egress timestamp to DMA interface
    // outputs
    ,.dma_egrts0_tvalid_o  (dma_axi_st_txegrts0_tvalid_o)
    ,.dma_egrts0_tdata_o   (dma_axi_st_txegrts0_tdata_o)
    ,.dma_egrts1_tvalid_o  (dma_axi_st_txegrts1_tvalid_o)
    ,.dma_egrts1_tdata_o   (dma_axi_st_txegrts1_tdata_o)
    //  tx egress timestamp to USER interface
    // outputs
    ,.user_egrts0_tvalid_o  (user_axi_st_txegrts0_tvalid_o)
    ,.user_egrts0_tdata_o   (user_axi_st_txegrts0_tdata_o)
    ,.user_egrts1_tvalid_o  (user_axi_st_txegrts1_tvalid_o)
    ,.user_egrts1_tdata_o   (user_axi_st_txegrts1_tdata_o)
    
    ); 

	//------------------------------------------------------------------------------------------
   //RX Path - packet_switch_rx
   packet_switch_rx
    #( .NUM_PIPELINE    (NUM_PIPELINE)
      ,.DMA_CHNL        (DMA_CHNL    )
      ,.DMA_DATA_WIDTH  (DMA_DATA_WIDTH ) 
      ,.USER_DATA_WIDTH (USER_DATA_WIDTH)
      ,.HSSI_DATA_WIDTH (HSSI_DATA_WIDTH)
      ,.DMA_NUM_OF_SEG  (DMA_NUM_OF_SEG )
      ,.HSSI_NUM_OF_SEG (HSSI_NUM_OF_SEG)
      ,.USER_NUM_OF_SEG (USER_NUM_OF_SEG)
      ,.HSSI_IGR_FIFO_DEPTH (HSSI_IGR_FIFO_DEPTH)
      ,.RXIGR_TS_DW     (RXIGR_TS_DW    )
      ,.STS_WIDTH       (STS_WIDTH      )
      ,.STS_EXT_WIDTH   (STS_EXT_WIDTH  )
      ,.AWADDR_WIDTH    (AWADDR_WIDTH   )
      ,.WDATA_WIDTH     (WDATA_WIDTH    )
      ,.RX_CLIENT_WIDTH (RX_CLIENT_WIDTH    )
      ,.TCAM_KEY_WIDTH          (TCAM_KEY_WIDTH         )
      ,.TCAM_RESULT_WIDTH       (TCAM_RESULT_WIDTH      )
      ,.TCAM_ENTRIES            (TCAM_ENTRIES           )
      ,.TCAM_USERMETADATA_WIDTH (TCAM_USERMETADATA_WIDTH)
      ,.IGR_HSSI_BYTE_ROTATE  (IGR_HSSI_BYTE_ROTATE)
      ,.EGR_DMA_BYTE_ROTATE  (EGR_DMA_BYTE_ROTATE)
      ,.EGR_USER_BYTE_ROTATE (EGR_USER_BYTE_ROTATE)
      ,.DBG_CNTR_EN          (DBG_CNTR_EN)
      ) packet_switch_rx_inst
   (
     .axi_st_clk           (rx_clk_i)
	,.axi_st_rst_n         (rx_areset_n_i)
	,.init_done	           (rx_init_done_o)
	//Avalon MM                
	,.avmm_address               (rx_avmm_address)
	,.avmm_read                  (rx_avmm_read)
	,.avmm_readdata              (rx_avmm_readdata) 
	,.avmm_write                 (rx_avmm_write)
	,.avmm_writedata             (rx_avmm_writedata)
	,.avmm_byteenable            (rx_avmm_byteenable)
	,.avmm_readdata_valid        (rx_avmm_readdata_valid)  
    
	//=========================================================================================
    //-----------------------------------------------------------------------------------------
    // rx ingress interface: Inputs from HSSI
    // inputs
    ,.hssi_tvalid_i              (hssi_axi_st_rx_tvalid_i)
    ,.hssi_tdata_i               (hssi_axi_st_rx_tdata_i)
    ,.hssi_tkeep_i               (hssi_axi_st_rx_tkeep_i)
    ,.hssi_tlast_i               (hssi_axi_st_rx_tlast_i)
    ,.hssi_tuser_sts_i           (hssi_axi_st_rx_tuser_sts_i)
    ,.hssi_tuser_sts_extended_i  (hssi_axi_st_rx_tuser_sts_extended_i)
    ,.hssi_tuser_client_i        (hssi_axi_st_rx_tuser_client_i)
    ,.hssi_tuser_pkt_seg_parity_i(hssi_axi_st_rx_tuser_pkt_seg_parity_i)
    ,.hssi_tuser_last_segment_i  (hssi_axi_st_rx_tuser_last_segment_i)
    ,.hssi_pause_o               (hssi_axi_st_rx_pause_o)
    // Output
    ,.hssi_tready_o (hssi_axi_st_rx_tready_o)
	
	// RX Egress Interface:  Outputs to DMA
    // Outputs
    ,.dma_tvalid_o               (dma_axi_st_rx_tvalid_o)
    ,.dma_tdata_o                (dma_axi_st_rx_tdata_o)
    ,.dma_tkeep_o                (dma_axi_st_rx_tkeep_o)
    ,.dma_tlast_o                (dma_axi_st_rx_tlast_o)
    ,.dma_tuser_sts_o            (dma_axi_st_rx_tuser_sts_o)
    ,.dma_tuser_sts_extended_o   (dma_axi_st_rx_tuser_sts_extended_o)
    ,.dma_tuser_client_o         (dma_axi_st_rx_tuser_client_o)
    ,.dma_tuser_pkt_seg_parity_o (dma_axi_st_rx_tuser_pkt_seg_parity_o)
    ,.dma_tuser_last_segment_o   (dma_axi_st_rx_tuser_last_segment_o)
    //input 
    ,.dma_tready_i (dma_axi_st_rx_tready_i)
    //=========================================================================================
    // TX Interface:  Outputs to Userlogic
    // Outputs
    ,.user_tvalid_o              (user_axi_st_rx_tvalid_o)
    ,.user_tdata_o               (user_axi_st_rx_tdata_o)
    ,.user_tkeep_o               (user_axi_st_rx_tkeep_o)
    ,.user_tlast_o               (user_axi_st_rx_tlast_o)
    ,.user_tuser_sts_o           (user_axi_st_rx_tuser_sts_o)
    ,.user_tuser_sts_extended_o  (user_axi_st_rx_tuser_sts_extended_o)
    ,.user_tuser_client_o        (user_axi_st_rx_tuser_client_o)
    ,.user_tuser_pkt_seg_parity_o(user_axi_st_rx_tuser_pkt_seg_parity_o)
    ,.user_tuser_last_segment_o  (user_axi_st_rx_tuser_last_segment_o)
	//input
    ,.user_tready_i (user_axi_st_rx_tready_i)


    //=========================================================================================
    // Time Stamp Interface:  rx ingress timestamp from HSSI interface
    // inputs
    ,.hssi_igrts0_tvalid_i (hssi_axi_st_rxigrts0_tvalid_i)
    ,.hssi_igrts0_tdata_i  (hssi_axi_st_rxigrts0_tdata_i)
    ,.hssi_igrts1_tvalid_i (hssi_axi_st_rxigrts1_tvalid_i)
    ,.hssi_igrts1_tdata_i  (hssi_axi_st_rxigrts1_tdata_i)

    //  rx egress timestamp to DMA interface
    // outputs
    ,.dma_igrts0_tvalid_o  (dma_axi_st_rxigrts0_tvalid_o)
    ,.dma_igrts0_tdata_o   (dma_axi_st_rxigrts0_tdata_o)
    ,.dma_igrts1_tvalid_o  (dma_axi_st_rxigrts1_tvalid_o)
    ,.dma_igrts1_tdata_o   (dma_axi_st_rxigrts1_tdata_o)
    //  rx egress timestamp to USER interface
    // outputs
    ,.user_igrts0_tvalid_o  (user_axi_st_rxigrts0_tvalid_o)
    ,.user_igrts0_tdata_o   (user_axi_st_rxigrts0_tdata_o)
    ,.user_igrts1_tvalid_o  (user_axi_st_rxigrts1_tvalid_o)
    ,.user_igrts1_tdata_o   (user_axi_st_rxigrts1_tdata_o)
	
	//TCAM interfaces for lookup
	//input
	,.tcam_req_tready_i            (tcam_req_tready_i)
	//output
	,.tcam_req_tvalid_o            (tcam_req_tvalid_o)
	,.tcam_req_tuser_key_o         (tcam_req_tuser_key_o)
	,.tcam_req_tuser_usermetadata_o(tcam_req_tuser_usermetadata_o)
	//output
	,.tcam_rsp_tready_o            (tcam_rsp_tready_o)
	//input
	,.tcam_rsp_tvalid_i            (tcam_rsp_tvalid_i)
	,.tcam_rsp_tuser_found_i       (tcam_rsp_tuser_found_i)
	,.tcam_rsp_tuser_result_i      (tcam_rsp_tuser_result_i)
	,.tcam_rsp_tuser_match_array_i (tcam_rsp_tuser_match_array_i )
	,.tcam_rsp_tuser_entry_i       (tcam_rsp_tuser_entry_i )
	,.tcam_rsp_tuser_usermetadata_i(tcam_rsp_tuser_usermetadata_i)	
    
    );

	//CSR interface
	packet_switch_axi_lt_avmm
	#( .DEVICE_FAMILY    ("Agilex")
      ,.ADDR_WIDTH       (AWADDR_WIDTH)
      ,.DATA_WIDTH       (WDATA_WIDTH) 
      ,.AVMM_MAX_LATENCY (AVMM_MAX_LATENCY)
      ,.HSSI_PORT        (HSSI_PORT)
      ,.DMA_CH           (DMA_CHNL)
      ,.DBG_CNTR_EN      (DBG_CNTR_EN)
      ) packet_switch_axi_lt_avmm_inst
   (
     .axi_lite_clk       (axi_lite_clk_i)
	,.axi_lt_rst	     (axi_lite_rst)

	,.tx_clk             (tx_clk_i)
	,.tx_rst	         (axi_st_tx_rst)

	,.rx_clk             (rx_clk_i)
	,.rx_rst	         (axi_st_rx_rst)

	,.awaddr   (axi_lite_awaddr_i)
	,.awvalid  (axi_lite_awvalid_i)
	,.awready  (axi_lite_awready_o)
	
	,.wdata    (axi_lite_wdata_i )
	,.wvalid   (axi_lite_wvalid_i)
	,.wstrb	   (axi_lite_wstrb_i)
	,.wready   (axi_lite_wready_o)
	
	,.bresp    (axi_lite_bresp_o)
	,.bvalid   (axi_lite_bvalid_o)
	,.bready   (axi_lite_bready_i)
	
	,.araddr   (axi_lite_araddr_i)
	,.arvalid  (axi_lite_arvalid_i)
	,.arready  (axi_lite_arready_o)
	
	,.rresp    (axi_lite_rresp_o)
	,.rdata    (axi_lite_rdata_o)
	,.rvalid   (axi_lite_rvalid_o)
	,.rready   (axi_lite_rready_i)

    //-----------------------------------------------------------------------------------------
    // TCAM csr interface: 
    // Write Address Channel
    ,.axi_lite_tcam_awaddr_o  (axi_lite_tcam_awaddr_o)
    ,.axi_lite_tcam_awvalid_o (axi_lite_tcam_awvalid_o)
    ,.axi_lite_tcam_awready_i (axi_lite_tcam_awready_i)

    // Write Data Channel 
    ,.axi_lite_tcam_wdata_o   (axi_lite_tcam_wdata_o )
    ,.axi_lite_tcam_wvalid_o  (axi_lite_tcam_wvalid_o)
    ,.axi_lite_tcam_wstrb_o   (axi_lite_tcam_wstrb_o )
    ,.axi_lite_tcam_wready_i  (axi_lite_tcam_wready_i)

    // Write Response Channel
    ,.axi_lite_tcam_bresp_i   (axi_lite_tcam_bresp_i )
    ,.axi_lite_tcam_bvalid_i  (axi_lite_tcam_bvalid_i)
    ,.axi_lite_tcam_bready_o  (axi_lite_tcam_bready_o )

    // Read Address Channel
    ,.axi_lite_tcam_araddr_o  (axi_lite_tcam_araddr_o )
    ,.axi_lite_tcam_arvalid_o (axi_lite_tcam_arvalid_o)
    ,.axi_lite_tcam_arready_i (axi_lite_tcam_arready_i)

    // Read Data Channel
    ,.axi_lite_tcam_rresp_i   (axi_lite_tcam_rresp_i)
    ,.axi_lite_tcam_rdata_i   (axi_lite_tcam_rdata_i)
    ,.axi_lite_tcam_rvalid_i  (axi_lite_tcam_rvalid_i ) 
    ,.axi_lite_tcam_rready_o  (axi_lite_tcam_rready_o )
	
    //-----------------------------------------------------------------------------------------
    // AVMM interface

    // tx interface
    // outputs
    ,.tx_avmm_address   (tx_avmm_address  )
    ,.tx_avmm_read      (tx_avmm_read     )
    ,.tx_avmm_write     (tx_avmm_write    )
    ,.tx_avmm_writedata (tx_avmm_writedata)
    ,.tx_avmm_byteenable (tx_avmm_byteenable)

    // inputs
    ,.tx_avmm_readdata       (tx_avmm_readdata      )
    ,.tx_avmm_readdata_valid (tx_avmm_readdata_valid)
					
    // rx interface				       
    // outputs
    ,.rx_avmm_address   (rx_avmm_address  )
    ,.rx_avmm_read      (rx_avmm_read     )
    ,.rx_avmm_write     (rx_avmm_write    )
    ,.rx_avmm_writedata (rx_avmm_writedata)
    ,.rx_avmm_byteenable (rx_avmm_byteenable)
 
    // inputs
    ,.rx_avmm_readdata       (rx_avmm_readdata      )
    ,.rx_avmm_readdata_valid (rx_avmm_readdata_valid)

    //----------------------------------------------------------------------------------------- 
    // init_done status
    ,.tx_init_done      (tx_init_done_o)	
    ,.rx_init_done      (rx_init_done_o)

    );

endmodule // packet_switch_top
