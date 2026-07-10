//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


//---------------------------------------------------------------------------------------------
// Description: This is the top level of Packet Switch top level integrated with TCAM.
//
//--------------------------------------------------------------------------------------------			


module packet_switch_subsys
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
	//=========================================================================================
	//TCAM Interface signals
	//-----------------------------------------------------------------------------------------
	//TCAM Reset Interface
    //,input  [HSSI_PORT-1:0]                        tcam_ss_rst_n
    //,input  [HSSI_PORT-1:0]                        tcam_ss_clk
    ,input  [HSSI_PORT-1:0]                        app_ss_cold_rst_n
    ,input  [HSSI_PORT-1:0]                        app_ss_warm_rst_n
    ,input  [HSSI_PORT-1:0]                        app_ss_rst_req
    ,output [HSSI_PORT-1:0]                        ss_app_rst_rdy
    ,output [HSSI_PORT-1:0]                        ss_app_cold_rst_ack_n
    ,output [HSSI_PORT-1:0]                        ss_app_warm_rst_ack_n

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
    // Time Stamp Interface:-  no clear spec regarding the alignment.
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
   );

    //TCAM AXI-Lite Interface
    logic [HSSI_PORT-1:0][AWADDR_WIDTH - 1:0]     axi_lite_tcam_awaddr_o; 
    logic [HSSI_PORT-1:0]                         axi_lite_tcam_awvalid_o;				  
    logic [HSSI_PORT-1:0]                         axi_lite_tcam_awready_i;             
    logic [HSSI_PORT-1:0] [WDATA_WIDTH - 1:0]     axi_lite_tcam_wdata_o; 
    logic [HSSI_PORT-1:0]                         axi_lite_tcam_wvalid_o;
    logic [HSSI_PORT-1:0] [(WDATA_WIDTH/8) - 1:0] axi_lite_tcam_wstrb_o;     			                 
    logic [HSSI_PORT-1:0]                         axi_lite_tcam_wready_i;        
    logic [HSSI_PORT-1:0][1:0]                    axi_lite_tcam_bresp_i; 
    logic [HSSI_PORT-1:0]                         axi_lite_tcam_bvalid_i;		     		
    logic [HSSI_PORT-1:0]                         axi_lite_tcam_bready_o;                        
    logic [HSSI_PORT-1:0] [AWADDR_WIDTH - 1:0]    axi_lite_tcam_araddr_o; 
    logic [HSSI_PORT-1:0]                         axi_lite_tcam_arvalid_o;		      		    
    logic [HSSI_PORT-1:0]                         axi_lite_tcam_arready_i;                     
    logic [HSSI_PORT-1:0][1:0]                    axi_lite_tcam_rresp_i;
    logic [HSSI_PORT-1:0] [WDATA_WIDTH - 1:0]     axi_lite_tcam_rdata_i;
    logic [HSSI_PORT-1:0]                         axi_lite_tcam_rvalid_i;   										
    logic [HSSI_PORT-1:0]                         axi_lite_tcam_rready_o;

	//TCAM Request Interface
	logic  [HSSI_PORT-1:0]                        tcam_req_tready_i;
	logic [HSSI_PORT-1:0]                         tcam_req_tvalid_o;
	logic [HSSI_PORT-1:0][TCAM_KEY_WIDTH-1:0]     tcam_req_tuser_key_o;
	logic [HSSI_PORT-1:0][TCAM_USERMETADATA_WIDTH-1:0]  tcam_req_tuser_usermetadata_o;
	//----------------------------------------------------------------------------------------------
	//TCAM Resonce Interface
	logic [HSSI_PORT-1:0]                              tcam_rsp_tready_o;
	logic [HSSI_PORT-1:0]                              tcam_rsp_tvalid_i;
	logic [HSSI_PORT-1:0]                              tcam_rsp_tuser_found_i;
	logic [HSSI_PORT-1:0][TCAM_RESULT_WIDTH-1:0]       tcam_rsp_tuser_result_i;
	logic [HSSI_PORT-1:0][TCAM_ENTRIES-1:0]            tcam_rsp_tuser_match_array_i ;
	logic [HSSI_PORT-1:0][$clog2(TCAM_ENTRIES)-1:0]    tcam_rsp_tuser_entry_i ;
	logic [HSSI_PORT-1:0][TCAM_USERMETADATA_WIDTH-1:0] tcam_rsp_tuser_usermetadata_i;

packet_switch_top
   #( .HSSI_PORT  (HSSI_PORT )   
	 ,.USER_PORT  (USER_PORT )   
	 ,.DMA_CHNL   (DMA_CHNL  )   
	
	,.DMA_DATA_WIDTH           (DMA_DATA_WIDTH         )       
    ,.USER_DATA_WIDTH          (USER_DATA_WIDTH        )     
    ,.HSSI_DATA_WIDTH          (HSSI_DATA_WIDTH        )     
							  
    ,.DMA_NUM_OF_SEG           (DMA_NUM_OF_SEG         )      
    ,.HSSI_NUM_OF_SEG          (HSSI_NUM_OF_SEG        )      
    ,.USER_NUM_OF_SEG          (USER_NUM_OF_SEG        )   

    ,.HSSI_IGR_FIFO_DEPTH      (HSSI_IGR_FIFO_DEPTH)
    ,.USER_IGR_FIFO_DEPTH      (USER_IGR_FIFO_DEPTH)
    ,.DMA_IGR_FIFO_DEPTH       (DMA_IGR_FIFO_DEPTH )   

    ,.TX_CLIENT_WIDTH          (TX_CLIENT_WIDTH        )
    ,.RX_CLIENT_WIDTH          (RX_CLIENT_WIDTH        )
 
    ,.TXEGR_TS_DW              (TXEGR_TS_DW            )      
    ,.RXIGR_TS_DW              (RXIGR_TS_DW            )      
    ,.SYS_FINGERPRINT_WIDTH    (SYS_FINGERPRINT_WIDTH  )
							   
    ,.PTP_WIDTH                (PTP_WIDTH              )      
    ,.PTP_EXT_WIDTH            (PTP_EXT_WIDTH          )      
    ,.STS_WIDTH                (STS_WIDTH              )      
    ,.STS_EXT_WIDTH            (STS_EXT_WIDTH          )      
							   
    ,.AWADDR_WIDTH             (AWADDR_WIDTH)      
    ,.WDATA_WIDTH              (WDATA_WIDTH )      
							  
    ,.TCAM_KEY_WIDTH           (TCAM_KEY_WIDTH         )      
    ,.TCAM_RESULT_WIDTH        (TCAM_RESULT_WIDTH      )      
    ,.TCAM_ENTRIES             (TCAM_ENTRIES           )      
    ,.TCAM_USERMETADATA_WIDTH  (TCAM_USERMETADATA_WIDTH)      

    // default: IGR HSSI, msgDMA, and User are all little endian
    ,.IGR_DMA_BYTE_ROTATE      (IGR_DMA_BYTE_ROTATE  )    
    ,.IGR_USER_BYTE_ROTATE     (IGR_USER_BYTE_ROTATE )    
    ,.IGR_HSSI_BYTE_ROTATE     (IGR_HSSI_BYTE_ROTATE )    

    // default: EGR HSSI, msgDMA, and User are all little endian
    ,.EGR_DMA_BYTE_ROTATE      (EGR_DMA_BYTE_ROTATE )      
    ,.EGR_USER_BYTE_ROTATE     (EGR_USER_BYTE_ROTATE)      
    ,.EGR_HSSI_BYTE_ROTATE     (EGR_HSSI_BYTE_ROTATE)      

    ,.DBG_CNTR_EN              (DBG_CNTR_EN)      
   ) packet_switch_top

  (
	//AXI Streaming Interface     
	// Tx streaming clock
     .tx_clk_i     (tx_clk_i)
    ,.tx_areset_n_i	(tx_areset_n_i)
     // Rx streaming clock & reset                 
    ,.rx_clk_i   (rx_clk_i)
    ,.rx_areset_n_i (rx_areset_n_i)
												   
    // axi_lite csr clock & reset                  
    ,.axi_lite_clk_i   (axi_lite_clk_i  )	  
    ,.axi_lite_rst_n_i (axi_lite_rst_n_i)
    //----------------------------------------------------------------------------------------- 
    // init_done status
    ,.tx_init_done_o	(tx_init_done_o)
    ,.rx_init_done_o	(rx_init_done_o)
    //-----------------------------------------------------------------------------------------
    // axi_lite: sync to axi_lite_clk

    //-----WRITE ADDRESS CHANNEL-------
    ,.axi_lite_awaddr_i  (axi_lite_awaddr_i )
    ,.axi_lite_awvalid_i (axi_lite_awvalid_i)
    ,.axi_lite_awready_o (axi_lite_awready_o)
    //---------------------------------            
    //-----WRITE DATA CHANNEL----------            
    ,.axi_lite_wdata_i  (axi_lite_wdata_i )
    ,.axi_lite_wvalid_i (axi_lite_wvalid_i)
    ,.axi_lite_wready_o (axi_lite_wready_o)
    ,.axi_lite_wstrb_i  (axi_lite_wstrb_i )
    //---------------------------------            
    //-----WRITE RESPONSE CHANNEL------            
    ,.axi_lite_bresp_o  (axi_lite_bresp_o )
    ,.axi_lite_bvalid_o (axi_lite_bvalid_o)
    ,.axi_lite_bready_i (axi_lite_bready_i)
    //---------------------------------            
    //-----READ ADDRESS CHANNEL-------             
    ,.axi_lite_araddr_i  (axi_lite_araddr_i )
    ,.axi_lite_arvalid_i (axi_lite_arvalid_i)
    ,.axi_lite_arready_o (axi_lite_arready_o)
    //---------------------------------            
    //-----READ DATA CHANNEL----------             
    ,.axi_lite_rresp_o  (axi_lite_rresp_o )
    ,.axi_lite_rdata_o  (axi_lite_rdata_o )
    ,.axi_lite_rvalid_o (axi_lite_rvalid_o)
    ,.axi_lite_rready_i (axi_lite_rready_i)
    //-----------------------------------------------------------------------------------------
    //-----------------------------------------------------------------------------------------
    // TCAM csr interface: 
    // Write Address Channel
    ,.axi_lite_tcam_awaddr_o  (axi_lite_tcam_awaddr_o )
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
    //=========================================================================================
    // TX Interface:  
    //-----------------------------------------------------------------------------------------
    // tx ingress interface - Input from DMA
    // inputs
 
    ,.dma_axi_st_tx_tvalid_i               (dma_axi_st_tx_tvalid_i              )
    ,.dma_axi_st_tx_tdata_i                (dma_axi_st_tx_tdata_i               )
    ,.dma_axi_st_tx_tkeep_i                (dma_axi_st_tx_tkeep_i               )
    ,.dma_axi_st_tx_tlast_i                (dma_axi_st_tx_tlast_i               )
    ,.dma_axi_st_tx_tuser_ptp_i            (dma_axi_st_tx_tuser_ptp_i           )
    ,.dma_axi_st_tx_tuser_ptp_extended_i   (dma_axi_st_tx_tuser_ptp_extended_i  )
    ,.dma_axi_st_tx_tuser_client_i         (dma_axi_st_tx_tuser_client_i        )
    ,.dma_axi_st_tx_tuser_pkt_seg_parity_i (dma_axi_st_tx_tuser_pkt_seg_parity_i) 
    ,.dma_axi_st_tx_tuser_last_segment_i   (dma_axi_st_tx_tuser_last_segment_i  )
												
    // output				 
    ,.dma_axi_st_tx_tready_o               (dma_axi_st_tx_tready_o)
	//-----------------------------------------------------------------------------------------
    // tx ingress interface - Input from USER
    ,.user_axi_st_tx_tvalid_i               (user_axi_st_tx_tvalid_i              ) 
    ,.user_axi_st_tx_tdata_i                (user_axi_st_tx_tdata_i               ) 
    ,.user_axi_st_tx_tkeep_i                (user_axi_st_tx_tkeep_i               ) 
    ,.user_axi_st_tx_tlast_i                (user_axi_st_tx_tlast_i               ) 
    ,.user_axi_st_tx_tuser_ptp_i            (user_axi_st_tx_tuser_ptp_i           ) 
    ,.user_axi_st_tx_tuser_ptp_extended_i   (user_axi_st_tx_tuser_ptp_extended_i  ) 
    ,.user_axi_st_tx_tuser_client_i         (user_axi_st_tx_tuser_client_i        ) 
    ,.user_axi_st_tx_tuser_pkt_seg_parity_i (user_axi_st_tx_tuser_pkt_seg_parity_i) 
    ,.user_axi_st_tx_tuser_last_segment_i   (user_axi_st_tx_tuser_last_segment_i  ) 
																				
    ,.user_axi_st_tx_tready_o               (user_axi_st_tx_tready_o)               

    //-----------------------------------------------------------------------------------------
    // tx egress interface - Outputs to HSSI
    // outputs
    ,.hssi_axi_st_tx_tvalid_o               (hssi_axi_st_tx_tvalid_o              )
    ,.hssi_axi_st_tx_tdata_o                (hssi_axi_st_tx_tdata_o               )
    ,.hssi_axi_st_tx_tkeep_o                (hssi_axi_st_tx_tkeep_o               )
    ,.hssi_axi_st_tx_tlast_o                (hssi_axi_st_tx_tlast_o               )
    ,.hssi_axi_st_tx_tuser_ptp_o            (hssi_axi_st_tx_tuser_ptp_o           )
    ,.hssi_axi_st_tx_tuser_ptp_extended_o   (hssi_axi_st_tx_tuser_ptp_extended_o  )
    ,.hssi_axi_st_tx_tuser_client_o         (hssi_axi_st_tx_tuser_client_o        )
    ,.hssi_axi_st_tx_tuser_pkt_seg_parity_o (hssi_axi_st_tx_tuser_pkt_seg_parity_o) 
    ,.hssi_axi_st_tx_tuser_last_segment_o   (hssi_axi_st_tx_tuser_last_segment_o  )
					                             
    // input   
    ,.hssi_axi_st_tx_tready_i               (hssi_axi_st_tx_tready_i)

    //=========================================================================================
    // RX Interface
    //-----------------------------------------------------------------------------------------
    // rx ingress interface -  Inputs from HSSI
    // inputs
    ,.hssi_axi_st_rx_tvalid_i               (hssi_axi_st_rx_tvalid_i)
    ,.hssi_axi_st_rx_tdata_i                (hssi_axi_st_rx_tdata_i )
    ,.hssi_axi_st_rx_tkeep_i                (hssi_axi_st_rx_tkeep_i )
    ,.hssi_axi_st_rx_tlast_i                (hssi_axi_st_rx_tlast_i )
    //Rx Packet Error Status                                      
    ,.hssi_axi_st_rx_tuser_client_i         (hssi_axi_st_rx_tuser_client_i)
    //Rx Packet Status                                            
    ,.hssi_axi_st_rx_tuser_sts_i            (hssi_axi_st_rx_tuser_sts_i           )
    ,.hssi_axi_st_rx_tuser_sts_extended_i   (hssi_axi_st_rx_tuser_sts_extended_i  ) 
    ,.hssi_axi_st_rx_tuser_pkt_seg_parity_i (hssi_axi_st_rx_tuser_pkt_seg_parity_i) 
    ,.hssi_axi_st_rx_tuser_last_segment_i   (hssi_axi_st_rx_tuser_last_segment_i  )
									
    // outputs
    ,.hssi_axi_st_rx_tready_o               (hssi_axi_st_rx_tready_o)
    ,.hssi_axi_st_rx_pause_o                (hssi_axi_st_rx_pause_o)

    //-----------------------------------------------------------------------------------------
    // rx egress interface - Output to DMA
    // outputs

    ,.dma_axi_st_rx_tvalid_o (dma_axi_st_rx_tvalid_o)
    ,.dma_axi_st_rx_tdata_o  (dma_axi_st_rx_tdata_o )
    ,.dma_axi_st_rx_tkeep_o  (dma_axi_st_rx_tkeep_o )
    ,.dma_axi_st_rx_tlast_o  (dma_axi_st_rx_tlast_o )
    //Rx Packet Error Status                                      
    ,.dma_axi_st_rx_tuser_client_o (dma_axi_st_rx_tuser_client_o)
    //Rx Packet Status                                          
    ,.dma_axi_st_rx_tuser_sts_o            (dma_axi_st_rx_tuser_sts_o           )
    ,.dma_axi_st_rx_tuser_sts_extended_o   (dma_axi_st_rx_tuser_sts_extended_o  )
    ,.dma_axi_st_rx_tuser_pkt_seg_parity_o (dma_axi_st_rx_tuser_pkt_seg_parity_o)
    ,.dma_axi_st_rx_tuser_last_segment_o   (dma_axi_st_rx_tuser_last_segment_o  )
										
    // input						  
    ,.dma_axi_st_rx_tready_i (dma_axi_st_rx_tready_i) 
    //-----------------------------------------------------------------------------------------
    // rx egress interface - Output to USER
    ,.user_axi_st_rx_tvalid_o (user_axi_st_rx_tvalid_o)  
    ,.user_axi_st_rx_tdata_o  (user_axi_st_rx_tdata_o )  
    ,.user_axi_st_rx_tkeep_o  (user_axi_st_rx_tkeep_o )  
    ,.user_axi_st_rx_tlast_o  (user_axi_st_rx_tlast_o )  
    //Rx Packet Error Status                       
    ,.user_axi_st_rx_tuser_client_o (user_axi_st_rx_tuser_client_o) 
    //Rx Packet Status                             
    ,.user_axi_st_rx_tuser_sts_o            (user_axi_st_rx_tuser_sts_o           ) 
    ,.user_axi_st_rx_tuser_sts_extended_o   (user_axi_st_rx_tuser_sts_extended_o  ) 
    ,.user_axi_st_rx_tuser_pkt_seg_parity_o (user_axi_st_rx_tuser_pkt_seg_parity_o) 
    ,.user_axi_st_rx_tuser_last_segment_o   (user_axi_st_rx_tuser_last_segment_o  ) 
												   
    ,.user_axi_st_rx_tready_i (user_axi_st_rx_tready_i) 
    //=========================================================================================
    // Time Stamp Interface:
    //-----------------------------------------------------------------------------------------
    // tx egress timestamp from HSSI
    //inputs
    ,.hssi_axi_st_txegrts0_tvalid_i (hssi_axi_st_txegrts0_tvalid_i)
    ,.hssi_axi_st_txegrts0_tdata_i  (hssi_axi_st_txegrts0_tdata_i )
    ,.hssi_axi_st_txegrts1_tvalid_i (hssi_axi_st_txegrts1_tvalid_i)
    ,.hssi_axi_st_txegrts1_tdata_i  (hssi_axi_st_txegrts1_tdata_i )
															      
     // tx egress timestamp to DMA                                
    ,.dma_axi_st_txegrts0_tvalid_o (dma_axi_st_txegrts0_tvalid_o )
    ,.dma_axi_st_txegrts0_tdata_o  (dma_axi_st_txegrts0_tdata_o  )
    ,.dma_axi_st_txegrts1_tvalid_o (dma_axi_st_txegrts1_tvalid_o )
    ,.dma_axi_st_txegrts1_tdata_o  (dma_axi_st_txegrts1_tdata_o  )
															      
     // tx egress timestamp to USER                               
    ,.user_axi_st_txegrts0_tvalid_o (user_axi_st_txegrts0_tvalid_o) 
    ,.user_axi_st_txegrts0_tdata_o  (user_axi_st_txegrts0_tdata_o ) 
    ,.user_axi_st_txegrts1_tvalid_o (user_axi_st_txegrts1_tvalid_o) 
    ,.user_axi_st_txegrts1_tdata_o  (user_axi_st_txegrts1_tdata_o ) 

    //-----------------------------------------------------------------------------------------
    // rx ingress timestamp from HSSI
    // inputs
    ,.hssi_axi_st_rxigrts0_tvalid_i (hssi_axi_st_rxigrts0_tvalid_i)
    ,.hssi_axi_st_rxigrts0_tdata_i  (hssi_axi_st_rxigrts0_tdata_i )
    ,.hssi_axi_st_rxigrts1_tvalid_i (hssi_axi_st_rxigrts1_tvalid_i)
    ,.hssi_axi_st_rxigrts1_tdata_i  (hssi_axi_st_rxigrts1_tdata_i )
																  
    // rx ingress timestamp to DMA  
    // outputs                              
    ,.dma_axi_st_rxigrts0_tvalid_o (dma_axi_st_rxigrts0_tvalid_o)
    ,.dma_axi_st_rxigrts0_tdata_o  (dma_axi_st_rxigrts0_tdata_o )
    ,.dma_axi_st_rxigrts1_tvalid_o (dma_axi_st_rxigrts1_tvalid_o)
    ,.dma_axi_st_rxigrts1_tdata_o  (dma_axi_st_rxigrts1_tdata_o )
																  
    // rx ingress timestamp to USER                               
    ,.user_axi_st_rxigrts0_tvalid_o (user_axi_st_rxigrts0_tvalid_o)
    ,.user_axi_st_rxigrts0_tdata_o  (user_axi_st_rxigrts0_tdata_o )
    ,.user_axi_st_rxigrts1_tvalid_o (user_axi_st_rxigrts1_tvalid_o)
    ,.user_axi_st_rxigrts1_tdata_o  (user_axi_st_rxigrts1_tdata_o )
    //-----------------------------------------------------------------------------------------
	//=========================================================================================
	//TCAM Interface signals
	//-----------------------------------------------------------------------------------------
	//TCAM Request Interface
	,.tcam_req_tready_i              (tcam_req_tready_i            ) 
	,.tcam_req_tvalid_o              (tcam_req_tvalid_o            ) 
	,.tcam_req_tuser_key_o           (tcam_req_tuser_key_o         ) 
	,.tcam_req_tuser_usermetadata_o  (tcam_req_tuser_usermetadata_o) 
	//----------------------------------------------------------------------------------------------
	//TCAM Response Interface
	,.tcam_rsp_tready_o               (tcam_rsp_tready_o             )
	,.tcam_rsp_tvalid_i               (tcam_rsp_tvalid_i             )
	,.tcam_rsp_tuser_found_i          (tcam_rsp_tuser_found_i        )
	,.tcam_rsp_tuser_result_i         (tcam_rsp_tuser_result_i       )
	,.tcam_rsp_tuser_match_array_i    ('0  )
	,.tcam_rsp_tuser_entry_i          (tcam_rsp_tuser_entry_i        )
	,.tcam_rsp_tuser_usermetadata_i   (tcam_rsp_tuser_usermetadata_i )
                                      
   );

 generate 

 for(genvar i=0; i<HSSI_PORT; i++) begin : gen_tcam_inst
	
 ptp_bridge_tcam_mem_ss_cam_0 inst_tcam (
		.app_ss_st_aclk                    (rx_clk_i[i]), //(tcam_ss_clk[i]),                    //   input,   width = 1,       axi_st_aclk.clk
		.app_ss_st_areset_n                (rx_areset_n_i[i]),  //(tcam_ss_rst_n[i]), //rx_areset_n_i[i]),                //   input,   width = 1,   axi_st_areset_n.reset_n
		.app_ss_lite_aclk                  (axi_lite_clk_i),                  //   input,   width = 1,     axi_lite_aclk.clk
		.app_ss_lite_areset_n              (axi_lite_rst_n_i),              //   input,   width = 1, axi_lite_areset_n.reset_n
		.ss_app_rst_rdy                    (ss_app_rst_rdy[i]),                    //  output,   width = 1,    graceful_reset.rst_rdy
		.ss_app_cold_rst_ack_n             (ss_app_cold_rst_ack_n[i]),             //  output,   width = 1,                  .cold_ack_n
		.ss_app_warm_rst_ack_n             (ss_app_warm_rst_ack_n[i]),             //  output,   width = 1,                  .warm_ack_n
		.app_ss_cold_rst_n                 (app_ss_cold_rst_n[i]),                 //   input,   width = 1,                  .cold_n
		.app_ss_warm_rst_n                 (app_ss_warm_rst_n[i]),                 //   input,   width = 1,                  .warm_n
		.app_ss_rst_req                    (app_ss_rst_req[i]),                    //   input,   width = 1,                  .rst_req
		.app_ss_st_req_tvalid              (tcam_req_tvalid_o[i]),              //   input,   width = 1,        axi_st_req.tvalid
		.ss_app_st_req_tready              (tcam_req_tready_i[i]),              //  output,   width = 1,                  .tready
		.app_ss_st_req_tid                 (8'd0),                 //   input,   width = 8,                  .tid
		.app_ss_st_req_tuser_key           (tcam_req_tuser_key_o[i]),           //   input,  width = 64,  axi_st_req_tuser.key
		.app_ss_st_req_tuser_ppmetadata    (19'd0),    //   input,  width = 19,                  .ppmetadata
		.app_ss_st_req_tuser_usermetadata  (tcam_req_tuser_usermetadata_o[i]),  //   input,   width = 1,                  .usermetadata
		.ss_app_st_resp_tvalid             (tcam_rsp_tvalid_i[i]),             //  output,   width = 1,       axi_st_resp.tvalid
		.app_ss_st_resp_tready             (tcam_rsp_tready_o[i]),             //   input,   width = 1,                  .tready
		.ss_app_st_resp_tid                (),                //  output,   width = 8,                  .tid
		.ss_app_st_resp_tuser_key          (),          //  output,  width = 64, axi_st_resp_tuser.key
		.ss_app_st_resp_tuser_result       (tcam_rsp_tuser_result_i[i]),       //  output,  width = 32,                  .result
		.ss_app_st_resp_tuser_found        (tcam_rsp_tuser_found_i[i]),        //  output,   width = 1,                  .found
		.ss_app_st_resp_tuser_ppmetadata   (),   //  output,  width = 19,                  .ppmetadata
		.ss_app_st_resp_tuser_usermetadata (tcam_rsp_tuser_usermetadata_i[i]), //  output,   width = 1,                  .usermetadata
		.ss_app_st_resp_tuser_entry        (tcam_rsp_tuser_entry_i[i]),        //  output,   width = 8,                  .entry
		.ss_app_lite_awready               (axi_lite_tcam_awready_i[i]),               //  output,   width = 1,          axi_lite.awready
		.app_ss_lite_awvalid               (axi_lite_tcam_awvalid_o[i]),               //   input,   width = 1,                  .awvalid
		.app_ss_lite_awaddr                (axi_lite_tcam_awaddr_o[i]),                //   input,  width = 32,                  .awaddr
		.app_ss_lite_awprot                (3'b0),                //   input,   width = 3,                  .awprot
		.ss_app_lite_arready               (axi_lite_tcam_arready_i[i]),               //  output,   width = 1,                  .arready
		.app_ss_lite_arvalid               (axi_lite_tcam_arvalid_o[i]),               //   input,   width = 1,                  .arvalid
		.app_ss_lite_araddr                (axi_lite_tcam_araddr_o[i]),                //   input,  width = 32,                  .araddr
		.app_ss_lite_arprot                (3'b0),                //   input,   width = 3,                  .arprot
		.ss_app_lite_wready                (axi_lite_tcam_wready_i[i]),                //  output,   width = 1,                  .wready
		.app_ss_lite_wvalid                (axi_lite_tcam_wvalid_o[i]),                //   input,   width = 1,                  .wvalid
		.app_ss_lite_wdata                 (axi_lite_tcam_wdata_o[i]),                 //   input,  width = 32,                  .wdata
		.app_ss_lite_wstrb                 (axi_lite_tcam_wstrb_o[i]),                 //   input,   width = 4,                  .wstrb
		.app_ss_lite_bready                (axi_lite_tcam_bready_o[i]),                //   input,   width = 1,                  .bready
		.ss_app_lite_bvalid                (axi_lite_tcam_bvalid_i[i]),                //  output,   width = 1,                  .bvalid
		.ss_app_lite_bresp                 (axi_lite_tcam_bresp_i[i]),                 //  output,   width = 2,                  .bresp
		.app_ss_lite_rready                (axi_lite_tcam_rready_o[i]),                //   input,   width = 1,                  .rready
		.ss_app_lite_rvalid                (axi_lite_tcam_rvalid_i[i]),                //  output,   width = 1,                  .rvalid
		.ss_app_lite_rresp                 (axi_lite_tcam_rresp_i[i]),                 //  output,   width = 2,                  .rresp
		.ss_app_lite_rdata                 (axi_lite_tcam_rdata_i[i])                  //  output,  width = 32,                  .rdata
	);
	
 end 
 endgenerate

endmodule // packet_switch_subsys
