//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


import sm_ptp_pkg::*;

module top #(
   `ifdef NUM_QSFP_1
    parameter NUM_QSFP      = 1  , 
   `elsif NUM_QSFP_2  
	parameter NUM_QSFP       = 2  , 
   `elsif NUM_QSFP_3  
    parameter NUM_QSFP      = 3  ,
   `elsif NUM_QSFP_4  
    parameter NUM_QSFP      = 4  ,
   `endif
   `ifdef NUM_CHANNELS_2
    parameter NUM_CHANNELS  = 2  ,
   `else
    parameter NUM_CHANNELS  = 1  ,
   `endif
     parameter ADDR_WIDTH      = 14                         
    ,parameter DATA_WIDTH      = 64	
	 ,parameter TS_REQ_FP_WIDTH = 20
	 ,parameter RXIGR_TS_DW     = 96
	 ,parameter PTP_WIDTH       = 94
    ,parameter PTP_EXT_WIDTH   = 328
    ,parameter DMA_CHANNELS    = 4
    ,parameter A0_PAGE_END_ADDR= 128
    ,parameter NUM_PG_SUPPORT  = 4
	)(
// Clock 
  input    wire          fpga_clk_100                     ,

//HPS
// HPS EMIF
  output   wire          emif_hps_emif_mem_0_mem_ck_t     ,
  output   wire          emif_hps_emif_mem_0_mem_ck_c     ,
  output   wire [16:0]   emif_hps_emif_mem_0_mem_a        ,
  output   wire          emif_hps_emif_mem_0_mem_act_n    ,
  output   wire [1:0]    emif_hps_emif_mem_0_mem_ba       ,
  output   wire [1:0]    emif_hps_emif_mem_0_mem_bg       ,
  output   wire          emif_hps_emif_mem_0_mem_cke      ,
  output   wire          emif_hps_emif_mem_0_mem_cs_n     ,
  output   wire          emif_hps_emif_mem_0_mem_odt      ,
  output   wire          emif_hps_emif_mem_0_mem_reset_n  ,
  output   wire          emif_hps_emif_mem_0_mem_par      ,
  input    wire          emif_hps_emif_mem_0_mem_alert_n  ,
  inout    wire [4:0]    emif_hps_emif_mem_0_mem_dbi_n,
  input    wire          emif_hps_emif_oct_0_oct_rzqin    ,
  input    wire          emif_hps_emif_ref_clk_0_clk      ,
  inout    wire [4:0]    emif_hps_emif_mem_0_mem_dqs_t    ,
  inout    wire [4:0]    emif_hps_emif_mem_0_mem_dqs_c    ,
  inout    wire [39:0]   emif_hps_emif_mem_0_mem_dq       ,
  input    wire          hps_jtag_tck                     ,
  input    wire          hps_jtag_tms                     ,
  output   wire          hps_jtag_tdo                     ,
  input    wire          hps_jtag_tdi                     ,
  output   wire          hps_sdmmc_CCLK                   ,
  inout    wire          hps_sdmmc_CMD                    ,
  inout    wire          hps_sdmmc_D0                     ,
  inout    wire          hps_sdmmc_D1                     ,
  inout    wire          hps_sdmmc_D2                     ,
  inout    wire          hps_sdmmc_D3                     ,
  														
  output   wire          hps_emac2_TX_CLK                 ,
  input    wire          hps_emac2_RX_CLK                 ,
  output   wire          hps_emac2_TX_CTL                 ,
  input    wire          hps_emac2_RX_CTL                 ,
  output   wire          hps_emac2_TXD0                   ,
  output   wire          hps_emac2_TXD1                   ,
  input    wire          hps_emac2_RXD0                   ,
  input    wire          hps_emac2_RXD1                   ,
  output   wire          hps_emac2_PPS                    ,
  input    wire          hps_emac2_PPS_TRIG               ,
  output   wire          hps_emac2_TXD2                   ,
  output   wire          hps_emac2_TXD3                   ,
  input    wire          hps_emac2_RXD2                   ,
  input    wire          hps_emac2_RXD3                   ,
  inout    wire          hps_emac2_MDIO                   ,
  output   wire          hps_emac2_MDC                    ,
  input    wire          hps_uart0_RX                     ,
  output   wire          hps_uart0_TX                     ,
  inout    wire          hps_i3c1_SDA                     ,
  inout    wire          hps_i3c1_SCL                     ,
  inout    wire          hps_gpio0_io0                    ,
  inout    wire          hps_gpio0_io1                    ,
  inout    wire          hps_gpio0_io11                   ,
  inout    wire          hps_gpio1_io3                    ,
  inout    wire          hps_gpio1_io4                    ,
  input    wire          hps_osc_clk                      ,
  input    wire          fpga_reset_n                     ,
  inout    wire          zl_i2c_scl                       ,
  inout    wire          zl_i2c_sda                       ,
														
//HSSI Subsystem                                        ,
input  wire [NUM_CHANNELS*1-1:0]   i_rx_serial_data     ,
input  wire [NUM_CHANNELS*1-1:0]   i_rx_serial_data_n   ,
output wire [NUM_CHANNELS*1-1:0]   o_tx_serial_data     ,
output wire [NUM_CHANNELS*1-1:0]   o_tx_serial_data_n   ,
														
 input wire  [NUM_CHANNELS-1:0]    i_clk_ref_p          ,
output wire                        o_clk_rec_div_66     ,
//output wire                        o_clk_rec_div_66_n     ,
														
//QSFP_CONTLR                                           ,
inout  wire                qsfp_i2c_scl                 ,
inout  wire                qsfp_i2c_sda                 ,
input  wire [NUM_QSFP-1:0] qsfpa_modprsln               ,
input  wire                intn_qsfp                    ,
output wire [NUM_QSFP-1:0] qsfpa_modeseln               ,
output wire [NUM_QSFP-1:0] qsfpa_lpmode                 ,
output wire [NUM_QSFP-1:0] qsfpa_resetn                 ,
input  wire                i_clk_master_tod             ,
output wire                o_ptp_pps 

);

    wire  [NUM_CHANNELS*1-1:0]  o_clk_rec_div_66_int          ;
	 wire  [NUM_CHANNELS*1-1:0]  o_clk_tx_div                  ;
    wire                        system_clk_100                ;
    wire                        ninit_done                    ;
    wire                        system_reset                  ;
    wire                        system_reset_n                  ;
    wire                        system_reset_csr              ;
    wire  [NUM_CHANNELS-1:0]    system_reset_161              ;
    wire 			              qsfp_i2c_scl_in               ;
    wire 			              qsfp_i2c_sda_in               ;
    wire 			              qsfp_i2c_scl_oe               ;
    wire 			              qsfp_i2c_sda_oe               ;
    wire 			              zl_i2c_scl_oe                 ;
    wire 			              zl_i2c_sda_oe                 ;
    wire  [NUM_QSFP-1:0]        qsfpa_reset                   ;
    wire  [NUM_QSFP-1:0]        qsfpa_modesel                 ;
    logic [DATA_WIDTH-1:0]      csr_readdata                  ;
    logic                       csr_readdata_valid            ;
    logic [DATA_WIDTH-1:0]      csr_wdata                     ;
    logic [ADDR_WIDTH-1:0]      csr_addr                      ;
    logic                       csr_write                     ;
    logic                       csr_read                      ;
    logic                       csr_waitreq                   ;
    logic [DATA_WIDTH/8-1:0]	  csr_byteenable                ;
    logic                       csr_debugaccess               ;
    logic 		[0:0]  			  csr_burstcount                ;
    integer                     i_qsfpa_reset                 ;
    integer                     i_qsfpa_modesel               ;
    logic   [7:0]               qsfp_cntlr_axi_bdg_m0_awid    ;
    logic   [13:0]              qsfp_cntlr_axi_bdg_m0_awaddr  ;
    logic   [7:0]               qsfp_cntlr_axi_bdg_m0_awlen   ;
    logic   [2:0]               qsfp_cntlr_axi_bdg_m0_awsize  ;
    logic   [1:0]               qsfp_cntlr_axi_bdg_m0_awburst ;
    logic   [0:0]               qsfp_cntlr_axi_bdg_m0_awlock  ;
    logic   [3:0]               qsfp_cntlr_axi_bdg_m0_awcache ;
    logic   [2:0]               qsfp_cntlr_axi_bdg_m0_awprot  ;
    logic                       qsfp_cntlr_axi_bdg_m0_awvalid ;        
    logic                       qsfp_cntlr_axi_bdg_m0_awready ;  
    logic   [63:0]              qsfp_cntlr_axi_bdg_m0_wdata   ;  
    logic   [7:0]               qsfp_cntlr_axi_bdg_m0_wstrb   ;  
    logic                       qsfp_cntlr_axi_bdg_m0_wlast   ; 
    logic                       qsfp_cntlr_axi_bdg_m0_wvalid  ;  
    logic                       qsfp_cntlr_axi_bdg_m0_wready  ;  
    logic   [7:0]               qsfp_cntlr_axi_bdg_m0_bid     ; 
    logic   [1:0]               qsfp_cntlr_axi_bdg_m0_bresp   ;  
    logic                       qsfp_cntlr_axi_bdg_m0_bvalid  ;  
    logic                       qsfp_cntlr_axi_bdg_m0_bready  ;  
    logic   [7:0]               qsfp_cntlr_axi_bdg_m0_arid    ;  
    logic   [13:0]              qsfp_cntlr_axi_bdg_m0_araddr  ;  
    logic   [7:0]               qsfp_cntlr_axi_bdg_m0_arlen   ;  
    logic   [2:0]               qsfp_cntlr_axi_bdg_m0_arsize  ;  
    logic   [1:0]               qsfp_cntlr_axi_bdg_m0_arburst ;  
    logic   [0:0]               qsfp_cntlr_axi_bdg_m0_arlock  ;  
    logic   [3:0]               qsfp_cntlr_axi_bdg_m0_arcache ;  
    logic   [2:0]               qsfp_cntlr_axi_bdg_m0_arprot  ; 
    logic                       qsfp_cntlr_axi_bdg_m0_arvalid ;  
    logic                       qsfp_cntlr_axi_bdg_m0_arready ;  
    logic   [7:0]               qsfp_cntlr_axi_bdg_m0_rid     ;  
    logic   [63:0]              qsfp_cntlr_axi_bdg_m0_rdata   ;  
    logic   [1:0]               qsfp_cntlr_axi_bdg_m0_rresp   ;  
    logic                       qsfp_cntlr_axi_bdg_m0_rlast   ; 
    logic                       qsfp_cntlr_axi_bdg_m0_rvalid  ;  
    logic                       qsfp_cntlr_axi_bdg_m0_rready  ;
    wire [NUM_CHANNELS-1:0]     iopll_locked_export_161       ;
    wire                        iopll_locked_export           ;
    wire                        iopll_locked_export_100M      ;
    wire                        iopll_locked_export_125M      ;
    wire                        fpga_reset_n_csr              ;
    wire                        ninit_done_csr                ;
    wire                        clk_bdg_125_clk               ;
    wire                        clk_bdg_100_clk               ;
    wire                        clk_bdg_161_0_in_clk_clk      ;
    wire                        rst_bdg_ap_resetn_reset       ;
    wire  [NUM_CHANNELS-1:0]    o_clk_pll_161m                ;	
    wire                        user_space_csr_m0_waitrequest  ;
    wire     [31:0]             user_space_csr_m0_readdata     ;
    wire                        user_space_csr_m0_readdatavalid;
    wire                        user_space_csr_m0_burstcount   ;
    wire     [31:0]             user_space_csr_m0_writedata    ;
    wire     [11:0]             user_space_csr_m0_address      ;
    wire                        user_space_csr_m0_write        ;
    wire                        user_space_csr_m0_read         ;
    wire     [3:0]              user_space_csr_m0_byteenable   ;
    wire                        user_space_csr_m0_debugaccess  ;
    wire [NUM_CHANNELS -1:0]    o_user_tx_rst_n_161            ;
    wire [NUM_CHANNELS -1:0]    o_user_rx_rst_n_161            ;
    wire [NUM_CHANNELS -1:0]    o_user_tx_rst_n_100            ;
    wire [NUM_CHANNELS -1:0]    o_user_rx_rst_n_100            ;
    wire [NUM_CHANNELS -1:0]    eth_user_tx_rst_n              ;
    wire [NUM_CHANNELS -1:0]    eth_user_rx_rst_n              ;
    wire [NUM_CHANNELS -1:0]    fifo_tx_user_reset             ;
    wire [NUM_CHANNELS -1:0]    fifo_rx_user_reset             ;
    wire [NUM_CHANNELS-1:0]     i_rst_n                        ;
    reg  [NUM_CHANNELS-1:0]     i_rst_n_125                    ;
    wire [NUM_CHANNELS-1:0]     i_tx_rst_n                     ;
    wire [NUM_CHANNELS-1:0]     i_rx_rst_n                     ;
    wire [NUM_CHANNELS-1:0]     rst_ack_n                      ;
    reg  [NUM_CHANNELS-1:0]     rst_ack_n_125                  ;
    wire [NUM_CHANNELS-1:0]     tx_rst_ack_n                   ;
    wire [NUM_CHANNELS-1:0]     rx_rst_ack_n                   ;
    wire [NUM_CHANNELS-1:0]     i_src_rs_grant                 ;
    wire [NUM_CHANNELS-1:0]     i_pma_cu_clk                   ;
    wire [NUM_CHANNELS-1:0]     o_src_rs_req                   ;
    wire [NUM_CHANNELS-1:0]     o_rx_pcs_ready                 ;
    wire [NUM_CHANNELS-1:0]     o_tx_lanes_stable              ;
    wire [NUM_CHANNELS-1:0]     o_tx_pll_locked                ;
    wire [NUM_CHANNELS-1:0]     o_cdr_lock                     ;
    wire  [NUM_CHANNELS-1:0]    o_csr_rst_n                    ;
    wire  [NUM_CHANNELS-1:0]    o_csr_tx_rst_n                 ;
    wire  [NUM_CHANNELS-1:0]    o_csr_rx_rst_n                 ;
    wire                        o_clk_sys                      ;
    wire                        o_pll_lock                     ;
	 wire  [NUM_CHANNELS-1:0]                         avst_tx_ready_int    ;
    wire  [NUM_CHANNELS-1:0]                         avst_tx_valid_int    ;
    wire  [NUM_CHANNELS-1:0]                         avst_tx_sop_int      ;
    wire  [NUM_CHANNELS-1:0]                         avst_tx_eop_int      ;
    wire  [NUM_CHANNELS-1:0]  [EMPTY_WIDTH-1:0]      avst_tx_empty_int    ;
    wire  [NUM_CHANNELS-1:0]  [WORDS*DATA_WIDTH-1:0] avst_tx_data_int     ;
    wire  [NUM_CHANNELS-1:0]                         avst_tx_error_int    ;
    wire  [NUM_CHANNELS-1:0]                         avst_tx_skip_crc_int ;
    logic [NUM_CHANNELS-1:0]                         avst_rx_valid_int    ;
    wire  [NUM_CHANNELS-1:0] [WORDS*DATA_WIDTH-1:0]  avst_rx_tdata_int    ;
    wire  [NUM_CHANNELS-1:0] [EMPTY_WIDTH*WORDS-1:0] avst_rx_empty_int    ;
    logic [NUM_CHANNELS-1:0]                         avst_rx_sop_int      ;
    logic [NUM_CHANNELS-1:0]                         avst_rx_eop_int      ;

    logic [NUM_CHANNELS-1:0]                         user_axi_st_tx_tvalid_i   ;
    logic [NUM_CHANNELS-1:0] [USER_DATA_WIDTH-1:0]   user_axi_st_tx_tdata_i    ;
    logic [NUM_CHANNELS-1:0] [USER_DATA_WIDTH/8-1:0] user_axi_st_tx_tkeep_i    ;
    logic [NUM_CHANNELS-1:0]                         user_axi_st_tx_tlast_i    ;
    logic [NUM_CHANNELS-1:0] [PTP_WIDTH-1:0]         user_axi_st_tx_tuser_ptp_i;
    logic [NUM_CHANNELS-1:0]                         user_axi_st_tx_tready_o   ;
    logic [NUM_CHANNELS-1:0] [USER_NUM_OF_SEG-1:0]   user_axi_st_tx_tuser_last_segment_i;                                            


    logic [NUM_CHANNELS-1:0] [PTP_EXT_WIDTH-1:0]      		user_axi_st_tx_tuser_ptp_extended_i;
    logic [NUM_CHANNELS-1:0] [USER_NUM_OF_SEG-1:0] 
                                           [TX_CLIENT_WIDTH-1:0] user_axi_st_tx_tuser_client_i;
    logic [NUM_CHANNELS-1:0] [USER_NUM_OF_SEG-1:0]    		user_axi_st_tx_tuser_pkt_seg_parity_i;
    logic [NUM_CHANNELS-1:0]                                user_axi_st_rx_tvalid_o;
    logic [NUM_CHANNELS-1:0] [USER_DATA_WIDTH-1:0]          user_axi_st_rx_tdata_o;
    logic [NUM_CHANNELS-1:0] [USER_DATA_WIDTH/8-1:0]        user_axi_st_rx_tkeep_o;
    logic [NUM_CHANNELS-1:0]                                user_axi_st_rx_tlast_o;                    
    logic [NUM_CHANNELS-1:0][USER_NUM_OF_SEG-1:0]
                                         [RX_CLIENT_WIDTH-1:0]user_axi_st_rx_tuser_client_o;                         
    logic [NUM_CHANNELS-1:0][USER_NUM_OF_SEG-1:0] 
                                          [STS_WIDTH-1:0]     user_axi_st_rx_tuser_sts_o;
    logic [NUM_CHANNELS-1:0][USER_NUM_OF_SEG-1:0]
                                         [STS_EXT_WIDTH-1:0]  user_axi_st_rx_tuser_sts_extended_o;
    logic [NUM_CHANNELS-1:0][USER_NUM_OF_SEG-1:0]             user_axi_st_rx_tuser_pkt_seg_parity_o;
    logic [NUM_CHANNELS-1:0][USER_NUM_OF_SEG-1:0]             user_axi_st_rx_tuser_last_segment_o;                    
    logic [NUM_CHANNELS-1:0]                                  user_axi_st_rx_tready_i;
  
    logic   [DMA_CHANNELS-1:0][PTP_WIDTH -1:0]               dma_axi_st_tx_tuser_ptp_i             ;
    logic   [DMA_CHANNELS-1:0][PTP_EXT_WIDTH -1:0]           dma_axi_st_tx_tuser_ptp_extended_i    ;
    logic   [DMA_CHANNELS-1:0] [1:0]                         dma_axi_st_tx_tuser_client_i          ;
      
    wire [NUM_CHANNELS-1:0]                                  hssi_ss_st_tx_tvalid             ;            
    wire [NUM_CHANNELS-1:0] [HSSI_DATA_WIDTH-1:0]            hssi_ss_st_tx_tdata              ;            
    wire [NUM_CHANNELS-1:0] [HSSI_DATA_WIDTH/8-1:0]          hssi_ss_st_tx_tkeep              ;            
    wire [NUM_CHANNELS-1:0]                                  hssi_ss_st_tx_tlast              ;            
    wire [NUM_CHANNELS-1:0]                                  hssi_ss_st_tx_tready             ;            
    wire [NUM_CHANNELS-1:0]                                  hssi_ss_st_rx_tvalid             ;            
    wire [NUM_CHANNELS-1:0] [HSSI_DATA_WIDTH-1:0]            hssi_ss_st_rx_tdata              ;            
    wire [NUM_CHANNELS-1:0] [HSSI_DATA_WIDTH/8-1:0]          hssi_ss_st_rx_tkeep              ;            
    wire [NUM_CHANNELS-1:0]                                  hssi_ss_st_rx_tlast              ; 
    logic [NUM_CHANNELS-1:0] [1:0]                           hssi_ss_st_tx_tuser_client       ; 
    logic [NUM_CHANNELS-1:0] [PTP_WIDTH -1:0]                hssi_ss_st_tx_tuser_ptp          ; 
    logic [NUM_CHANNELS-1:0] [PTP_EXT_WIDTH -1:0]            hssi_ss_st_tx_tuser_ptp_extended ; 
    logic [NUM_CHANNELS-1:0]                                 hssi_ss_st_tx_tuser_last_segment ; 
    logic [NUM_CHANNELS-1:0]                                 hssi_ss_st_tx_tuser_pkt_seg_parity ; 
  
    logic [DMA_CHANNELS-1:0]                                 dma_axi_st_tx_tvalid_i              ;
    logic [DMA_CHANNELS-1:0][DMA_DATA_WIDTH-1:0]             dma_axi_st_tx_tdata_i               ;
    logic [DMA_CHANNELS-1:0][DMA_DATA_WIDTH/8-1:0]           dma_axi_st_tx_tkeep_i               ;
    logic [DMA_CHANNELS-1:0]                                 dma_axi_st_tx_tlast_i               ;
    logic [DMA_CHANNELS-1:0]                                 dma_axi_st_rx_tready_i              ;
                 
    logic [DMA_CHANNELS-1:0][DMA_NUM_OF_SEG-1:0]             dma_axi_st_tx_tuser_last_segment_i  ;
    logic [DMA_CHANNELS-1:0]                                 dma_axi_st_tx_tready_o              ;
    logic [DMA_CHANNELS-1:0]                                 dma_axi_st_rx_tvalid_o              ;
    logic [DMA_CHANNELS-1:0][DMA_DATA_WIDTH-1:0]             dma_axi_st_rx_tdata_o               ;
    logic [DMA_CHANNELS-1:0][DMA_DATA_WIDTH/8-1:0]           dma_axi_st_rx_tkeep_o               ;
    logic [DMA_CHANNELS-1:0]                                 dma_axi_st_rx_tlast_o               ;
               
    wire  [NUM_CHANNELS-1:0]                                 ss_app_cold_rst_ack_n, ss_app_warm_rst_ack_n, ss_app_cold_rst_ack_n_sync, ss_app_warm_rst_ack_n_sync;
    reg   [NUM_CHANNELS-1:0]                                 tcam_cold_rst_n, tcam_warm_rst_n;
             
    wire  [NUM_CHANNELS-1:0]                                 hssi_ptp_tx_egrts_tvalid ;      
    wire  [NUM_CHANNELS-1:0] [TXEGR_TS_DW-1:0]               hssi_ptp_tx_egrts_tdata;                          
    wire  [NUM_CHANNELS-1:0]                                 hssi_ptp_rx_ingrts_tvalid ;    
    wire  [NUM_CHANNELS-1:0] [RXIGR_TS_DW-1:0]               hssi_ptp_rx_ingrts_tdata;      
    
    
    wire                                                     ch0_tx_dma_fifo_0_out_ts_req_valid;       
    wire   [19:0]                                            ch0_tx_dma_fifo_0_out_ts_req_fingerprint; 
    wire                                                     ch1_tx_dma_fifo_0_out_ts_req_valid;        
    wire   [19:0]                                            ch1_tx_dma_fifo_0_out_ts_req_fingerprint;  
    wire                                                     ch2_tx_dma_fifo_0_out_ts_req_valid;       
    wire   [19:0]                                            ch2_tx_dma_fifo_0_out_ts_req_fingerprint; 
    wire                                                     ch3_tx_dma_fifo_0_out_ts_req_valid;        
    wire   [19:0]                                            ch3_tx_dma_fifo_0_out_ts_req_fingerprint;  
    
    logic                                                    ts_req_valid0,ts_req_valid_reg0;       
    logic                                                    ts_req_valid1,ts_req_valid_reg1;       
    logic                                                    ts_req_valid2,ts_req_valid_reg2;       
    logic                                                    ts_req_valid3,ts_req_valid_reg3;       
    logic   [19:0]                                           ts_req_fingerprint0,ts_req_fingerprint_reg0;
    logic   [19:0]                                           ts_req_fingerprint1,ts_req_fingerprint_reg1;
    logic   [19:0]                                           ts_req_fingerprint2,ts_req_fingerprint_reg2;
    logic   [19:0]                                           ts_req_fingerprint3,ts_req_fingerprint_reg3;
	 
    logic [DMA_CHANNELS-1:0]                                 tx_ts_valid ;
    logic [DMA_CHANNELS-1:0] [TS_REQ_FP_WIDTH-1:0]           tx_ts_fp ;
    logic [DMA_CHANNELS-1:0] [RXIGR_TS_DW-1:0]               tx_ts_data ;
    logic [DMA_CHANNELS-1:0]                                 dma_axi_st_rxigrts_tvalid;
    logic [DMA_CHANNELS-1:0]  [RXIGR_TS_DW-1:0]              dma_axi_st_rxigrts_tdata; 
	         
    logic [DMA_CHANNELS-1:0]                                 dma_axi_st_rxigrts_tvalid_reg0,dma_axi_st_rxigrts_tvalid_reg1,dma_axi_st_rxigrts_tvalid_reg2;
    logic [DMA_CHANNELS-1:0]  [RXIGR_TS_DW-1:0]              dma_axi_st_rxigrts_tdata_reg0,dma_axi_st_rxigrts_tdata_reg1,dma_axi_st_rxigrts_tdata_reg2;
    logic [DMA_CHANNELS-1:0]                                 rx_ingrts0_interface_0_tvalid;                                  
    logic [DMA_CHANNELS-1:0][RXIGR_TS_DW-1:0]                rx_ingrts0_interface_0_tdata ; 
    wire [DMA_CHANNELS-1:0]                                  dma_axi_st_txegrts_tvalid_o  ;
    wire [DMA_CHANNELS-1:0][TX_EGRESS-1:0]                   dma_axi_st_txegrts_tdata_o   ;
    wire [NUM_CHANNELS-1:0][20-1:0]                          i_reconfig_eth_addr           ;
    wire [NUM_CHANNELS-1:0][4-1:0]                           i_reconfig_eth_byteenable     ;
    wire [NUM_CHANNELS-1:0]                                  o_reconfig_eth_readdata_valid ;
    wire [NUM_CHANNELS-1:0]                                  i_reconfig_eth_read           ;
    wire [NUM_CHANNELS-1:0]                                  i_reconfig_eth_write          ;
    wire [NUM_CHANNELS-1:0][32-1:0]                          o_reconfig_eth_readdata       ;
    wire [NUM_CHANNELS-1:0][32-1:0]                          i_reconfig_eth_writedata      ;
    wire [NUM_CHANNELS-1:0]                                  o_reconfig_eth_waitrequest    ;
    wire [NUM_CHANNELS-1:0]                                  i_reconfig_clk                ;
  
    wire                                                    master_tod_csr_m0_waitrequest    ;
    wire [31:0]                                             master_tod_csr_m0_readdata       ;
    wire                                                    master_tod_csr_m0_readdatavalid  ;
    wire [0:0]                                              master_tod_csr_m0_burstcount     ;
    wire [31:0]                                             master_tod_csr_m0_writedata      ;
    wire [9:0]                                              master_tod_csr_m0_address        ;
    wire                                                    master_tod_csr_m0_write          ;
    wire                                                    master_tod_csr_m0_read           ;
    wire [3:0]                                              master_tod_csr_m0_byteenable     ;
    wire                                                    master_tod_csr_m0_debugaccess    ;
    logic [NUM_CHANNELS-1:0][95:0]                          ptp_tx_tod                       ;
    logic [NUM_CHANNELS-1:0][95:0]                          ptp_rx_tod                       ;
    logic [NUM_CHANNELS-1:0]                                ptp_tx_tod_valid                 ;
    logic [NUM_CHANNELS-1:0]                                ptp_rx_tod_valid                 ;
    logic [NUM_CHANNELS-1:0]                                tx_pll_locked_reg                ;
    logic [NUM_CHANNELS-1:0]                                cdr_lock_reg                     ;
    logic [NUM_CHANNELS-1:0]                                tx_tod_rst_n_wire                ;
    logic [NUM_CHANNELS-1:0]                                tx_tod_rst_n_reg                 ;
    logic [NUM_CHANNELS-1:0]                                tx_tod_rst_n_reg2                ;
    logic [NUM_CHANNELS-1:0]                                rx_tod_rst_n_wire                ;
    logic [NUM_CHANNELS-1:0]                                rx_tod_rst_n_reg                 ;
    logic [NUM_CHANNELS-1:0]                                rx_tod_rst_n_reg2                ;
    logic [NUM_CHANNELS-1:0]                                tx_tod_rst_n                     ;
    logic [NUM_CHANNELS-1:0]                                rx_tod_rst_n                     ;
    logic [NUM_CHANNELS-1:0]                                clk_tx_tod                       ;
    logic [NUM_CHANNELS-1:0]                                clk_rx_tod                       ;
    logic [NUM_CHANNELS-1:0]                                tx_pll_locked_sync               ;
    logic [NUM_CHANNELS-1:0]                                rx_cdr_lock_sync                 ;
    logic [NUM_CHANNELS-1:0]                                tx_todsync_sampling_clk_locked_sync;
    logic [NUM_CHANNELS-1:0]                                rx_todsync_sampling_clk_locked_sync;
	  wire                                                   o_pma_cpu_clk                   ;
	  wire                                                   clk_ptp_sample                  ;
    
	 assign qsfp_i2c_scl_in      = qsfp_i2c_scl;
    assign qsfp_i2c_sda_in      = qsfp_i2c_sda;
    assign qsfp_i2c_scl         = qsfp_i2c_scl_oe ? 1'b0 : 1'bz;
    assign qsfp_i2c_sda         = qsfp_i2c_sda_oe ? 1'b0 : 1'bz;
    assign qsfpa_resetn         = ~qsfpa_reset;
    assign qsfpa_modeseln       = ~qsfpa_modesel;
    assign zl_i2c_scl           = (zl_i2c_scl_oe == 1'b1) ? 1'b0 : 1'bz;
    assign zl_i2c_sda           = (zl_i2c_sda_oe == 1'b1) ? 1'b0 : 1'bz;
    assign system_clk_100       = fpga_clk_100;
 
    assign i_reconfig_clk[0]    = clk_bdg_125_clk;
    assign i_reconfig_clk[1]    = clk_bdg_125_clk;

`ifdef SIM_MODE
   assign system_reset_n = ~ninit_done;
`else
   defparam rd1.CNTR_BITS = 28;
   alt_reset_delay rd1 (.clk(fpga_clk_100), .ready_in(~ninit_done), .ready_out(system_reset_n) );
`endif
  assign system_reset = (~system_reset_n);

  ipm_cdc_async_rst #(
      .NUM_STAGES                 (3)
   ) sync_ninit_done (
      .clk                        (clk_bdg_125_clk),        
      .arst_in                    (system_reset),    
      .srst_out                   (system_reset_csr) 
   );
 
	cdr_clk_gpio u0 (
		.ck        (o_clk_rec_div_66_int[0]),        
		.din       (2'b10),              
		.pad_out   (o_clk_rec_div_66),   
		//.pad_out_b (o_clk_rec_div_66_n)  
		.pad_out_b ()  
	);
	

  axis_if #(.DATA_W(TDATA_WIDTH),.TID(TID)) axis_h2d_if [DMA_CHANNELS-1:0]();
  axis_if #(.DATA_W(TDATA_WIDTH),.TID(TID)) axis_d2h_if [DMA_CHANNELS-1:0]();
   
  axi4lite_if #(.AWADDR_WIDTH(16), .WDATA_WIDTH(32), .ARADDR_WIDTH(16), .RDATA_WIDTH(32))  axi4lite_pktcli [NUM_CHANNELS-1:0]();
  axi4lite_if #(.AWADDR_WIDTH(16), .WDATA_WIDTH(32), .ARADDR_WIDTH(16), .RDATA_WIDTH(32))  axi4lite_packetsw();

  logic [NUM_CHANNELS-1:0] [3:0] trafficgen_system_status;
  wire [1:0] o_tx_lanes_stable_sync, o_tx_pll_locked_sync, o_rx_pcs_ready_sync;

  assign trafficgen_system_status[0] = {o_rx_pcs_ready_sync[0] ,o_tx_pll_locked_sync[0], o_tx_lanes_stable_sync[0] , system_reset_csr};

// **************************************************************************//
//                 synchronizers                                             //
// **************************************************************************//  
  for (genvar i=0; i < NUM_CHANNELS; i++) begin : sts_tx_lanes_stable
    eth_f_altera_std_synchronizer_nocut tx_lanes_stable (
        .clk        (clk_bdg_125_clk),
        .reset_n    (o_tx_lanes_stable[i]),
        .din        (1'b1),         
        .dout       (o_tx_lanes_stable_sync[i])
    );
   end

  for (genvar i=0; i < NUM_CHANNELS; i++) begin : sts_tx_pll_locked
    eth_f_altera_std_synchronizer_nocut tx_pll_locked (
        .clk        (clk_bdg_125_clk),
        .reset_n    (o_tx_pll_locked[i]),
        .din        (1'b1),        
        .dout       (o_tx_pll_locked_sync[i])
    );
   end
    
  for (genvar i=0; i < NUM_CHANNELS; i++) begin : sts_rx_pcs_ready
    eth_f_altera_std_synchronizer_nocut rx_pcs_ready (
        .clk        (clk_bdg_125_clk),
        .reset_n    (o_rx_pcs_ready[i]),
        .din        (1'b1 ),         
        .dout       (o_rx_pcs_ready_sync[i])
    );
   end   

   eth_f_altera_std_synchronizer_nocut sync_iopll_lock_100M (
      .clk                       (clk_bdg_100_clk),
      .reset_n                   (iopll_locked_export),
      .din                       (1'b1),
      .dout                      (iopll_locked_export_100M)
    );
   eth_f_altera_std_synchronizer_nocut sync_iopll_lock_125M (
      .clk                       (clk_bdg_125_clk),
      .reset_n                   (iopll_locked_export),
      .din                       (1'b1),
      .dout                      (iopll_locked_export_125M)
    );
	
   eth_f_altera_std_synchronizer_nocut sync_iopll_lock_161_0 (
      .clk                       (o_clk_pll_161m[0]),
      .reset_n                   (iopll_locked_export),
      .din                       (1'b1 ),
      .dout                      (iopll_locked_export_161[0])
    );
	 
	    eth_f_altera_std_synchronizer_nocut sync_iopll_lock_161_1 (
      .clk                       (o_clk_pll_161m[1]),
      .reset_n                   (iopll_locked_export),
      .din                       (1'b1 ),
      .dout                      (iopll_locked_export_161[1])
    );
 

 	 eth_f_altera_std_synchronizer_nocut sync_rst_ack_n_125_0 (
      .clk                       (clk_bdg_125_clk),
      .reset_n                   (rst_ack_n[0]),
      .din                       (1'b1 ),
      .dout                      (rst_ack_n_125[0])
    );

 	 eth_f_altera_std_synchronizer_nocut sync_rst_ack_n_125_1 (
      .clk                       (clk_bdg_125_clk),
      .reset_n                   (rst_ack_n[1]),
      .din                       (1'b1 ),
      .dout                      (rst_ack_n_125[1])
    );

	 
	 eth_f_altera_std_synchronizer_nocut sync_i_rst_n_125_0 (
      .clk                       (clk_bdg_125_clk),
      .reset_n                   (i_rst_n[0]),
      .din                       (1'b1 ),
      .dout                      (i_rst_n_125[0])
    );

	 eth_f_altera_std_synchronizer_nocut sync_i_rst_n_125_1 (
      .clk                       (clk_bdg_125_clk),
      .reset_n                   (i_rst_n[1]),
      .din                       (1'b1 ),
      .dout                      (i_rst_n_125[1])
    );
	 
for(genvar i = 0; i < DMA_CHANNELS; i++) begin : tx_ts_assign
    always_comb begin
       tx_ts_valid[i] = dma_axi_st_txegrts_tvalid_o[i];
       tx_ts_fp[i]    = dma_axi_st_txegrts_tdata_o[i][115:96];
       tx_ts_data[i]  = dma_axi_st_txegrts_tdata_o[i][95:0];
    end
end

// **************************************************************************//
//   Tx Timestamp req & fingerprint signals
//   fingerprint& ts_req generated inside tx_dma_fifo module
//   tx_dma_fifo(128bit DW) --> avst_to_axi module(64bit). So PD tool adds adapter inbetween
//   fifo to avst module, two clock cycles delay. So we are delaying ts_req & finger print   
//   ts_req & finger print should be aligned with streaming data                  
// **************************************************************************// 

	always@(posedge o_clk_pll_161m[0]) begin
	ts_req_valid_reg0 <= ch0_tx_dma_fifo_0_out_ts_req_valid;
	ts_req_valid0     <= ts_req_valid_reg0;
	
	ts_req_fingerprint_reg0 <= ch0_tx_dma_fifo_0_out_ts_req_fingerprint;
	ts_req_fingerprint0     <= ts_req_fingerprint_reg0;

	ts_req_valid_reg1 <= ch1_tx_dma_fifo_0_out_ts_req_valid;
	ts_req_valid1     <= ts_req_valid_reg1;
	
	ts_req_fingerprint_reg1 <= ch1_tx_dma_fifo_0_out_ts_req_fingerprint;
	ts_req_fingerprint1     <= ts_req_fingerprint_reg1;
	end
	
	always@(posedge o_clk_pll_161m[1]) begin
	ts_req_valid_reg2 <= ch2_tx_dma_fifo_0_out_ts_req_valid;
	ts_req_valid2     <= ts_req_valid_reg2;
	
	ts_req_fingerprint_reg2 <= ch2_tx_dma_fifo_0_out_ts_req_fingerprint;
	ts_req_fingerprint2     <= ts_req_fingerprint_reg2;

	ts_req_valid_reg3 <= ch3_tx_dma_fifo_0_out_ts_req_valid;
	ts_req_valid3     <= ts_req_valid_reg3;
	
	ts_req_fingerprint_reg3 <= ch3_tx_dma_fifo_0_out_ts_req_fingerprint;
	ts_req_fingerprint3     <= ts_req_fingerprint_reg3;
	end

// **************************************************************************//
//   Rx Ingress timestamp
//   avst_to_axi module(64bit) -->rx_dma_fifo(128bit DW) --> . So PD tool adds adapter inbetween
//   avst to fifo module, three clock cycles delay. So we are delaying Ingress ts &  valid                   
// **************************************************************************// 
	always@(posedge o_clk_pll_161m[0]) begin
	
	dma_axi_st_rxigrts_tvalid_reg1[0] <= dma_axi_st_rxigrts_tvalid_reg0[0];
	dma_axi_st_rxigrts_tvalid_reg2[0] <= dma_axi_st_rxigrts_tvalid_reg1[0];
	rx_ingrts0_interface_0_tvalid[0]  <= dma_axi_st_rxigrts_tvalid_reg2[0];
	
	dma_axi_st_rxigrts_tdata_reg1[0] <= dma_axi_st_rxigrts_tdata_reg0[0];
	dma_axi_st_rxigrts_tdata_reg2[0] <= dma_axi_st_rxigrts_tdata_reg1[0];
	rx_ingrts0_interface_0_tdata[0]  <= dma_axi_st_rxigrts_tdata_reg2[0];

	dma_axi_st_rxigrts_tvalid_reg1[1] <= dma_axi_st_rxigrts_tvalid_reg0[1];
	dma_axi_st_rxigrts_tvalid_reg2[1] <= dma_axi_st_rxigrts_tvalid_reg1[1];
	rx_ingrts0_interface_0_tvalid[1]  <= dma_axi_st_rxigrts_tvalid_reg2[1];
	
	dma_axi_st_rxigrts_tdata_reg1[1] <= dma_axi_st_rxigrts_tdata_reg0[1];
	dma_axi_st_rxigrts_tdata_reg2[1] <= dma_axi_st_rxigrts_tdata_reg1[1];
	rx_ingrts0_interface_0_tdata[1]  <= dma_axi_st_rxigrts_tdata_reg2[1];
	end
	
    always@(posedge o_clk_pll_161m[1]) begin
	dma_axi_st_rxigrts_tvalid_reg1[2]  <= dma_axi_st_rxigrts_tvalid_reg0[2];
	dma_axi_st_rxigrts_tvalid_reg2[2]  <= dma_axi_st_rxigrts_tvalid_reg1[2];
	rx_ingrts0_interface_0_tvalid [2]  <= dma_axi_st_rxigrts_tvalid_reg2[2];
	
	dma_axi_st_rxigrts_tdata_reg1[2] <= dma_axi_st_rxigrts_tdata_reg0[2];
	dma_axi_st_rxigrts_tdata_reg2[2] <= dma_axi_st_rxigrts_tdata_reg1[2];
	rx_ingrts0_interface_0_tdata [2] <= dma_axi_st_rxigrts_tdata_reg2[2];
	
	dma_axi_st_rxigrts_tvalid_reg1[3]  <= dma_axi_st_rxigrts_tvalid_reg0[3];
	dma_axi_st_rxigrts_tvalid_reg2[3]  <= dma_axi_st_rxigrts_tvalid_reg1[3];
	rx_ingrts0_interface_0_tvalid [3]  <= dma_axi_st_rxigrts_tvalid_reg2[3];
	
	dma_axi_st_rxigrts_tdata_reg1[3] <= dma_axi_st_rxigrts_tdata_reg0[3];
	dma_axi_st_rxigrts_tdata_reg2[3] <= dma_axi_st_rxigrts_tdata_reg1[3];
	rx_ingrts0_interface_0_tdata [3] <= dma_axi_st_rxigrts_tdata_reg2[3];
	
	end

// **************************************************************************//
//                 qsys_top module instance                                  //
// **************************************************************************//                                 

qsys_top soc_inst (
.clk_100_clk                               (system_clk_100           ),
.clk_bdg_100_clk                           (clk_bdg_100_clk          ),
.clk_bdg_125_clk                           (clk_bdg_125_clk          ),
.clk_in_0_161m_clk                  		 (o_clk_pll_161m[0]        ),
.hip_ptp_sample_clk                        (clk_ptp_sample           ), //114.28Mhz
.iopll_locked_export                       (iopll_locked_export      ),
.rst_bdg_100_clk_clk                       (clk_bdg_100_clk          ),
.rst_bdg_100_rst_reset_n                   (iopll_locked_export_100M ), 
.rst_bdg_125_clk_clk                       (clk_bdg_125_clk          ),
.rst_bdg_125_rst_reset_n                   (iopll_locked_export_125M ),

.qsfp_cntlr_axi_bdg_m0_awid                (qsfp_cntlr_axi_bdg_m0_awid),           
.qsfp_cntlr_axi_bdg_m0_awaddr              (qsfp_cntlr_axi_bdg_m0_awaddr),         
.qsfp_cntlr_axi_bdg_m0_awlen               (qsfp_cntlr_axi_bdg_m0_awlen),          
.qsfp_cntlr_axi_bdg_m0_awsize              (qsfp_cntlr_axi_bdg_m0_awsize),         
.qsfp_cntlr_axi_bdg_m0_awburst             (qsfp_cntlr_axi_bdg_m0_awburst),        
.qsfp_cntlr_axi_bdg_m0_awlock              (qsfp_cntlr_axi_bdg_m0_awlock),         
.qsfp_cntlr_axi_bdg_m0_awcache             (qsfp_cntlr_axi_bdg_m0_awcache),        
.qsfp_cntlr_axi_bdg_m0_awprot              (qsfp_cntlr_axi_bdg_m0_awprot),         
.qsfp_cntlr_axi_bdg_m0_awvalid             (qsfp_cntlr_axi_bdg_m0_awvalid),        
.qsfp_cntlr_axi_bdg_m0_awready             (qsfp_cntlr_axi_bdg_m0_awready),        
.qsfp_cntlr_axi_bdg_m0_wdata               (qsfp_cntlr_axi_bdg_m0_wdata),          
.qsfp_cntlr_axi_bdg_m0_wstrb               (qsfp_cntlr_axi_bdg_m0_wstrb),          
.qsfp_cntlr_axi_bdg_m0_wlast               (qsfp_cntlr_axi_bdg_m0_wlast),          
.qsfp_cntlr_axi_bdg_m0_wvalid              (qsfp_cntlr_axi_bdg_m0_wvalid),         
.qsfp_cntlr_axi_bdg_m0_wready              (qsfp_cntlr_axi_bdg_m0_wready),         
.qsfp_cntlr_axi_bdg_m0_bid                 (qsfp_cntlr_axi_bdg_m0_bid),            
.qsfp_cntlr_axi_bdg_m0_bresp               (qsfp_cntlr_axi_bdg_m0_bresp),          
.qsfp_cntlr_axi_bdg_m0_bvalid              (qsfp_cntlr_axi_bdg_m0_bvalid),         
.qsfp_cntlr_axi_bdg_m0_bready              (qsfp_cntlr_axi_bdg_m0_bready),         
.qsfp_cntlr_axi_bdg_m0_arid                (qsfp_cntlr_axi_bdg_m0_arid),           
.qsfp_cntlr_axi_bdg_m0_araddr              (qsfp_cntlr_axi_bdg_m0_araddr),         
.qsfp_cntlr_axi_bdg_m0_arlen               (qsfp_cntlr_axi_bdg_m0_arlen),          
.qsfp_cntlr_axi_bdg_m0_arsize              (qsfp_cntlr_axi_bdg_m0_arsize),         
.qsfp_cntlr_axi_bdg_m0_arburst             (qsfp_cntlr_axi_bdg_m0_arburst),        
.qsfp_cntlr_axi_bdg_m0_arlock              (qsfp_cntlr_axi_bdg_m0_arlock),         
.qsfp_cntlr_axi_bdg_m0_arcache             (qsfp_cntlr_axi_bdg_m0_arcache),        
.qsfp_cntlr_axi_bdg_m0_arprot              (qsfp_cntlr_axi_bdg_m0_arprot),         
.qsfp_cntlr_axi_bdg_m0_arvalid             (qsfp_cntlr_axi_bdg_m0_arvalid),        
.qsfp_cntlr_axi_bdg_m0_arready             (qsfp_cntlr_axi_bdg_m0_arready),        
.qsfp_cntlr_axi_bdg_m0_rid                 (qsfp_cntlr_axi_bdg_m0_rid),                    
.qsfp_cntlr_axi_bdg_m0_rdata               (qsfp_cntlr_axi_bdg_m0_rdata),                  
.qsfp_cntlr_axi_bdg_m0_rresp               (qsfp_cntlr_axi_bdg_m0_rresp),                  
.qsfp_cntlr_axi_bdg_m0_rlast               (qsfp_cntlr_axi_bdg_m0_rlast),                  
.qsfp_cntlr_axi_bdg_m0_rvalid              (qsfp_cntlr_axi_bdg_m0_rvalid),                 
.qsfp_cntlr_axi_bdg_m0_rready              (qsfp_cntlr_axi_bdg_m0_rready), 

.ninit_done_ninit_done                     (ninit_done),
.subsys_hps_agilex_hps_i2c0_scl_i_clk      (zl_i2c_scl) , 		  
.subsys_hps_agilex_hps_i2c0_scl_oe_clk     (zl_i2c_scl_oe) ,		
.subsys_hps_agilex_hps_i2c0_sda_i          (zl_i2c_sda) ,     		
.subsys_hps_agilex_hps_i2c0_sda_oe         (zl_i2c_sda_oe) ,    	

.emif_hps_emif_mem_ck_0_mem_ck_t           (emif_hps_emif_mem_0_mem_ck_t),
.emif_hps_emif_mem_ck_0_mem_ck_c           (emif_hps_emif_mem_0_mem_ck_c),
.emif_hps_emif_mem_0_mem_a                 (emif_hps_emif_mem_0_mem_a),
.emif_hps_emif_mem_0_mem_act_n             (emif_hps_emif_mem_0_mem_act_n),
.emif_hps_emif_mem_0_mem_ba                (emif_hps_emif_mem_0_mem_ba),
.emif_hps_emif_mem_0_mem_bg                (emif_hps_emif_mem_0_mem_bg),
.emif_hps_emif_mem_0_mem_cke               (emif_hps_emif_mem_0_mem_cke),
.emif_hps_emif_mem_0_mem_cs_n              (emif_hps_emif_mem_0_mem_cs_n),
.emif_hps_emif_mem_0_mem_odt               (emif_hps_emif_mem_0_mem_odt),
.emif_hps_emif_mem_reset_n_mem_reset_n     (emif_hps_emif_mem_0_mem_reset_n),
.emif_hps_emif_mem_0_mem_par               (emif_hps_emif_mem_0_mem_par),
.emif_hps_emif_mem_0_mem_alert_n           (emif_hps_emif_mem_0_mem_alert_n),
.emif_hps_emif_mem_0_mem_dbi_n             (emif_hps_emif_mem_0_mem_dbi_n),
.emif_hps_emif_mem_0_mem_dqs_t             (emif_hps_emif_mem_0_mem_dqs_t),
.emif_hps_emif_mem_0_mem_dqs_c             (emif_hps_emif_mem_0_mem_dqs_c),
.emif_hps_emif_mem_0_mem_dq                (emif_hps_emif_mem_0_mem_dq),
.emif_hps_emif_oct_0_oct_rzqin             (emif_hps_emif_oct_0_oct_rzqin),
.emif_hps_emif_ref_clk_0_clk               (emif_hps_emif_ref_clk_0_clk),
.hps_io_jtag_tck                           (hps_jtag_tck),                
.hps_io_jtag_tms                           (hps_jtag_tms),                
.hps_io_jtag_tdo                           (hps_jtag_tdo),                 
.hps_io_jtag_tdi                           (hps_jtag_tdi),    
.hps_io_emac2_tx_clk                       (hps_emac2_TX_CLK),      
.hps_io_emac2_rx_clk                       (hps_emac2_RX_CLK),  
.hps_io_emac2_tx_ctl                       (hps_emac2_TX_CTL),     
.hps_io_emac2_rx_ctl                       (hps_emac2_RX_CTL),  
.hps_io_emac2_txd0                         (hps_emac2_TXD0),        
.hps_io_emac2_txd1                         (hps_emac2_TXD1),  
.hps_io_emac2_rxd0                         (hps_emac2_RXD0),   
.hps_io_emac2_rxd1                         (hps_emac2_RXD1),     
.hps_io_emac2_pps                          (hps_emac2_PPS),      
.hps_io_emac2_pps_trig                     (hps_emac2_PPS_TRIG), 
.hps_io_emac2_txd2                         (hps_emac2_TXD2),      
.hps_io_emac2_txd3                         (hps_emac2_TXD3),  
.hps_io_emac2_rxd2                         (hps_emac2_RXD2),     
.hps_io_emac2_rxd3                         (hps_emac2_RXD3),   
.hps_io_mdio2_mdio                         (hps_emac2_MDIO),  
.hps_io_mdio2_mdc                          (hps_emac2_MDC),  
.hps_io_sdmmc_cclk                         (hps_sdmmc_CCLK),   
.hps_io_sdmmc_cmd                          (hps_sdmmc_CMD), 
.hps_io_sdmmc_data0                        (hps_sdmmc_D0),          
.hps_io_sdmmc_data1                        (hps_sdmmc_D1),          
.hps_io_sdmmc_data2                        (hps_sdmmc_D2),         
.hps_io_sdmmc_data3                        (hps_sdmmc_D3),        
.hps_io_i3c1_sda                           (hps_i3c1_SDA),     
.hps_io_i3c1_scl                           (hps_i3c1_SCL),
.hps_io_uart0_rx                           (hps_uart0_RX),          
.hps_io_uart0_tx                           (hps_uart0_TX), 
.hps_io_gpio0                              (hps_gpio0_io0),
.hps_io_gpio1                          	   (hps_gpio0_io1),
.hps_io_gpio11                             (hps_gpio0_io11),
.hps_io_gpio27                             (hps_gpio1_io3),
.hps_io_gpio28                             (hps_gpio1_io4),
.hps_io_hps_osc_clk                        (hps_osc_clk),
//.h2f_reset_reset                           (h2f_reset),
.h2f_reset_reset                           (),
.reset_reset_n                             (system_reset_n),
 //##########################     PORT 0     ##########################################
  // --------------   Tx mSGDMA Channel 0 to HSSI port 0----------------------//

  .subsys_msgdma_ch0_eth_p0_axi_tx_st_tready                          (axis_h2d_if[0].tready),
  .subsys_msgdma_ch0_eth_p0_axi_tx_st_tvalid                          (axis_h2d_if[0].tvalid),
  .subsys_msgdma_ch0_eth_p0_axi_tx_st_tdata                           (axis_h2d_if[0].tdata ),
  .subsys_msgdma_ch0_eth_p0_axi_tx_st_tlast                           (axis_h2d_if[0].tlast ),
  .subsys_msgdma_ch0_eth_p0_axi_tx_st_tkeep                           (axis_h2d_if[0].tkeep ),
  .subsys_msgdma_ch0_eth_p0_axi_tx_st_tuser                           (dma_axi_st_tx_tuser_client_i[0]),

  .subsys_msgdma_ch0_eth_p0_avst_tx_ptp_i_av_st_tx_skip_crc           ('d0),
  .subsys_msgdma_ch0_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_ts_valid       ('d0),
  .subsys_msgdma_ch0_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_ins_ets        ('d0),
  .subsys_msgdma_ch0_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_ins_cf         ('d0),
  .subsys_msgdma_ch0_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_tx_its         ('d0),
  .subsys_msgdma_ch0_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_asym_p2p_idx   ('d0),
  .subsys_msgdma_ch0_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_asym_sign      ('d0),
  .subsys_msgdma_ch0_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_asym           ('d0),
  .subsys_msgdma_ch0_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_p2p            ('d0),
  .subsys_msgdma_ch0_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_ts_format      ('d0),
  .subsys_msgdma_ch0_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_update_eb      ('d0),
  .subsys_msgdma_ch0_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_zero_csum      ('d0),
  .subsys_msgdma_ch0_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_eb_offset      ('d0),
  .subsys_msgdma_ch0_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_csum_offset    ('d0),
  .subsys_msgdma_ch0_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_cf_offset      ('d0),
  .subsys_msgdma_ch0_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_ts_offset      ('d0),
  `ifdef NON_PTP_ETHERNET
  .subsys_msgdma_ch0_eth_p0_avst_tx_ptp_valid                         (ch0_tx_dma_fifo_0_out_ts_req_valid),
  .subsys_msgdma_ch0_eth_p0_avst_tx_ptp_fingerprint                   (ch0_tx_dma_fifo_0_out_ts_req_fingerprint),
  `else
  .subsys_msgdma_ch0_eth_p0_avst_tx_ptp_valid                         (ts_req_valid0),
  .subsys_msgdma_ch0_eth_p0_avst_tx_ptp_fingerprint                   (ts_req_fingerprint0),
  `endif
  .subsys_msgdma_ch0_eth_p0_tx_dma_fifo_0_out_ts_req_valid            (ch0_tx_dma_fifo_0_out_ts_req_valid), 
  .subsys_msgdma_ch0_eth_p0_tx_dma_fifo_0_out_ts_req_fingerprint      (ch0_tx_dma_fifo_0_out_ts_req_fingerprint), 
  
  .subsys_msgdma_ch0_eth_p0_ts_chs_compl_0_clk_bus_in_clk_bus         (o_clk_pll_161m[0]),
  .subsys_msgdma_ch0_eth_p0_ts_chs_compl_0_rst_bus_in_rst_bus         (~eth_user_tx_rst_n[0]),
  
  .subsys_msgdma_ch0_eth_p0_fifo_user_rst_tx_reset_n                  (fifo_tx_user_reset[0]), //100Mhz
  .subsys_msgdma_ch0_eth_p0_fifo_user_rst_rx_reset_n                  (fifo_rx_user_reset[0]), //100Mhz
  
  .subsys_msgdma_ch0_eth_p0_hssi_rst_tx_reset_n                       (eth_user_tx_rst_n[0]),
  .subsys_msgdma_ch0_eth_p0_hssi_rst_rx_reset_n                       (eth_user_rx_rst_n[0]),
  
  .subsys_msgdma_ch0_eth_p0_tx_tuser_ptp_tuser_1                      (dma_axi_st_tx_tuser_ptp_i[0]),
  .subsys_msgdma_ch0_eth_p0_tx_tuser_ptp_extended_tuser_2             (dma_axi_st_tx_tuser_ptp_extended_i[0]),
  
  .subsys_msgdma_ch0_eth_p0_rx_tuser_sts_tuser_1                     ('d0),
  .subsys_msgdma_ch0_eth_p0_rx_ingrts0_interface_tdata               (dma_axi_st_rxigrts_tdata[0]),
  .subsys_msgdma_ch0_eth_p0_rx_ingrts0_interface_tvalid              (dma_axi_st_rxigrts_tvalid[0]),
  

  .subsys_msgdma_ch0_eth_p0_avst_rx_ptp_valid                      (dma_axi_st_rxigrts_tvalid_reg0[0]),  
  .subsys_msgdma_ch0_eth_p0_avst_rx_ptp_data                       (dma_axi_st_rxigrts_tdata_reg0[0] ),  
  	
  .subsys_msgdma_ch0_eth_p0_rx_dma_fifo_in_ts_data                (rx_ingrts0_interface_0_tdata[0]),  
  .subsys_msgdma_ch0_eth_p0_rx_dma_fifo_in_ts_valid               (rx_ingrts0_interface_0_tvalid[0]),
 
  
 // --------------  HSSI Port0 to Rx mSGDMA  Channel 0  ----------------------//                                              
   .subsys_msgdma_ch0_eth_p0_axi_rx_st_tvalid                        (axis_d2h_if[0].tvalid),
   .subsys_msgdma_ch0_eth_p0_axi_rx_st_tdata                         (axis_d2h_if[0].tdata ),
   .subsys_msgdma_ch0_eth_p0_axi_rx_st_tlast                         (axis_d2h_if[0].tlast ),
   .subsys_msgdma_ch0_eth_p0_axi_rx_st_tkeep                         (axis_d2h_if[0].tkeep ),
   .subsys_msgdma_ch0_eth_p0_axi_rx_st_tuser                         ('d0),//axis_d2h_if_pkt_fifo.tuser ),

   .subsys_msgdma_ch0_eth_p0_hssi_ets_ts_adapter_0_egrs_ts_hssi_tvalid(tx_ts_valid[0]),
   .subsys_msgdma_ch0_eth_p0_hssi_ets_ts_adapter_0_egrs_ts_hssi_tdata ({tx_ts_fp[0],tx_ts_data[0]}),

  // --------------   Tx mSGDMA Channel 1 to HSSI port 0----------------------//

  .subsys_msgdma_ch1_eth_p0_axi_tx_st_tready                          (axis_h2d_if[1].tready),
  .subsys_msgdma_ch1_eth_p0_axi_tx_st_tvalid                          (axis_h2d_if[1].tvalid),
  .subsys_msgdma_ch1_eth_p0_axi_tx_st_tdata                           (axis_h2d_if[1].tdata ),
  .subsys_msgdma_ch1_eth_p0_axi_tx_st_tlast                           (axis_h2d_if[1].tlast ),
  .subsys_msgdma_ch1_eth_p0_axi_tx_st_tkeep                           (axis_h2d_if[1].tkeep ),
  .subsys_msgdma_ch1_eth_p0_axi_tx_st_tuser                           (dma_axi_st_tx_tuser_client_i[1]),//axis_h2d_if_pkt_fifo.tuser ),

  .subsys_msgdma_ch1_eth_p0_avst_tx_ptp_i_av_st_tx_skip_crc           ('d0),
  .subsys_msgdma_ch1_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_ts_valid       ('d0),
  .subsys_msgdma_ch1_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_ins_ets        ('d0),
  .subsys_msgdma_ch1_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_ins_cf         ('d0),
  .subsys_msgdma_ch1_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_tx_its         ('d0),
  .subsys_msgdma_ch1_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_asym_p2p_idx   ('d0),
  .subsys_msgdma_ch1_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_asym_sign      ('d0),
  .subsys_msgdma_ch1_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_asym           ('d0),
  .subsys_msgdma_ch1_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_p2p            ('d0),
  .subsys_msgdma_ch1_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_ts_format      ('d0),
  .subsys_msgdma_ch1_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_update_eb      ('d0),
  .subsys_msgdma_ch1_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_zero_csum      ('d0),
  .subsys_msgdma_ch1_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_eb_offset      ('d0),
  .subsys_msgdma_ch1_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_csum_offset    ('d0),
  .subsys_msgdma_ch1_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_cf_offset      ('d0),
  .subsys_msgdma_ch1_eth_p0_avst_tx_ptp_i_av_st_tx_ptp_ts_offset      ('d0),
  `ifdef NON_PTP_ETHERNET
  .subsys_msgdma_ch1_eth_p0_avst_tx_ptp_valid                         (ch1_tx_dma_fifo_0_out_ts_req_valid),
  .subsys_msgdma_ch1_eth_p0_avst_tx_ptp_fingerprint                   (ch1_tx_dma_fifo_0_out_ts_req_fingerprint),
  `else
  .subsys_msgdma_ch1_eth_p0_avst_tx_ptp_valid                         (ts_req_valid1),
  .subsys_msgdma_ch1_eth_p0_avst_tx_ptp_fingerprint                   (ts_req_fingerprint1),
  `endif
  .subsys_msgdma_ch1_eth_p0_tx_dma_fifo_0_out_ts_req_valid            (ch1_tx_dma_fifo_0_out_ts_req_valid), 
  .subsys_msgdma_ch1_eth_p0_tx_dma_fifo_0_out_ts_req_fingerprint      (ch1_tx_dma_fifo_0_out_ts_req_fingerprint), 
  
  .subsys_msgdma_ch1_eth_p0_ts_chs_compl_0_clk_bus_in_clk_bus         (o_clk_pll_161m[0]),
  .subsys_msgdma_ch1_eth_p0_ts_chs_compl_0_rst_bus_in_rst_bus         (~eth_user_tx_rst_n[0]),
  
  .subsys_msgdma_ch1_eth_p0_fifo_user_rst_tx_reset_n                  (fifo_tx_user_reset[0]), //100Mhz
  .subsys_msgdma_ch1_eth_p0_fifo_user_rst_rx_reset_n                  (fifo_rx_user_reset[0]), //100Mhz
  
  .subsys_msgdma_ch1_eth_p0_hssi_rst_tx_reset_n                       (eth_user_tx_rst_n[0]),
  .subsys_msgdma_ch1_eth_p0_hssi_rst_rx_reset_n                       (eth_user_rx_rst_n[0]),
  
  .subsys_msgdma_ch1_eth_p0_tx_tuser_ptp_tuser_1                      (dma_axi_st_tx_tuser_ptp_i[1]),
  .subsys_msgdma_ch1_eth_p0_tx_tuser_ptp_extended_tuser_2             (dma_axi_st_tx_tuser_ptp_extended_i[1]),
  
  .subsys_msgdma_ch1_eth_p0_rx_tuser_sts_tuser_1                      ('d0),
  .subsys_msgdma_ch1_eth_p0_rx_ingrts0_interface_tdata                (dma_axi_st_rxigrts_tdata[1]),
  .subsys_msgdma_ch1_eth_p0_rx_ingrts0_interface_tvalid               (dma_axi_st_rxigrts_tvalid[1]),
  

  .subsys_msgdma_ch1_eth_p0_avst_rx_ptp_valid                         (dma_axi_st_rxigrts_tvalid_reg0[1]),  
  .subsys_msgdma_ch1_eth_p0_avst_rx_ptp_data                          (dma_axi_st_rxigrts_tdata_reg0[1] ),  
  	
  .subsys_msgdma_ch1_eth_p0_rx_dma_fifo_in_ts_data                    (rx_ingrts0_interface_0_tdata[1]),  
  .subsys_msgdma_ch1_eth_p0_rx_dma_fifo_in_ts_valid                   (rx_ingrts0_interface_0_tvalid[1]),
 
  
 // --------------  HSSI Port0 to Rx mSGDMA  Channel 1  ----------------------//                                              
   .subsys_msgdma_ch1_eth_p0_axi_rx_st_tvalid                        (axis_d2h_if[1].tvalid),
   .subsys_msgdma_ch1_eth_p0_axi_rx_st_tdata                         (axis_d2h_if[1].tdata ),
   .subsys_msgdma_ch1_eth_p0_axi_rx_st_tlast                         (axis_d2h_if[1].tlast ),
   .subsys_msgdma_ch1_eth_p0_axi_rx_st_tkeep                         (axis_d2h_if[1].tkeep ),
   .subsys_msgdma_ch1_eth_p0_axi_rx_st_tuser                         ('d0),//axis_d2h_if_pkt_fifo.tuser ),

   .subsys_msgdma_ch1_eth_p0_hssi_ets_ts_adapter_0_egrs_ts_hssi_tvalid(tx_ts_valid[1]),
   .subsys_msgdma_ch1_eth_p0_hssi_ets_ts_adapter_0_egrs_ts_hssi_tdata ({tx_ts_fp[1],tx_ts_data[1]}),

  .qhip_port_0_m0_waitrequest            (o_reconfig_eth_waitrequest[0]   ),
  .qhip_port_0_m0_readdata               (o_reconfig_eth_readdata[0]      ), 
  .qhip_port_0_m0_readdatavalid          (o_reconfig_eth_readdata_valid[0]),
  .qhip_port_0_m0_burstcount             (),
  .qhip_port_0_m0_writedata              (i_reconfig_eth_writedata[0]      ),
  .qhip_port_0_m0_address                (i_reconfig_eth_addr[0]           ), 
  .qhip_port_0_m0_write                  (i_reconfig_eth_write [0]         ), 
  .qhip_port_0_m0_read                   (i_reconfig_eth_read[0]           ),
  .qhip_port_0_m0_byteenable             (i_reconfig_eth_byteenable[0]     ),
  .qhip_port_0_m0_debugaccess            (),
 
  
  .user_space_csr_m0_waitrequest        (user_space_csr_m0_waitrequest  ),
  .user_space_csr_m0_readdata           (user_space_csr_m0_readdata     ),
  .user_space_csr_m0_readdatavalid      (user_space_csr_m0_readdatavalid),
  .user_space_csr_m0_burstcount         (user_space_csr_m0_burstcount   ),
  .user_space_csr_m0_writedata          (user_space_csr_m0_writedata    ),
  .user_space_csr_m0_address            (user_space_csr_m0_address      ),
  .user_space_csr_m0_write              (user_space_csr_m0_write        ),
  .user_space_csr_m0_read               (user_space_csr_m0_read         ),
  .user_space_csr_m0_byteenable         (user_space_csr_m0_byteenable   ),
  .user_space_csr_m0_debugaccess        (user_space_csr_m0_debugaccess  ),
  
  .axi4lite_pktcli_0_m0_awaddr          (axi4lite_pktcli[0].awaddr  ),
  .axi4lite_pktcli_0_m0_awprot          (axi4lite_pktcli[0].awprot  ),
  .axi4lite_pktcli_0_m0_awvalid         (axi4lite_pktcli[0].awvalid ),
  .axi4lite_pktcli_0_m0_awready         (axi4lite_pktcli[0].awready ),
  .axi4lite_pktcli_0_m0_wdata           (axi4lite_pktcli[0].wdata   ),
  .axi4lite_pktcli_0_m0_wstrb           (axi4lite_pktcli[0].wstrb   ),
  .axi4lite_pktcli_0_m0_wvalid          (axi4lite_pktcli[0].wvalid  ),
  .axi4lite_pktcli_0_m0_wready          (axi4lite_pktcli[0].wready  ),
  .axi4lite_pktcli_0_m0_bresp           (axi4lite_pktcli[0].bresp   ),
  .axi4lite_pktcli_0_m0_bvalid          (axi4lite_pktcli[0].bvalid  ),
  .axi4lite_pktcli_0_m0_bready          (axi4lite_pktcli[0].bready  ),
  .axi4lite_pktcli_0_m0_araddr          (axi4lite_pktcli[0].araddr  ),
  .axi4lite_pktcli_0_m0_arprot          (axi4lite_pktcli[0].arprot  ),
  .axi4lite_pktcli_0_m0_arvalid         (axi4lite_pktcli[0].arvalid ),
  .axi4lite_pktcli_0_m0_arready         (axi4lite_pktcli[0].arready ),
  .axi4lite_pktcli_0_m0_rdata           (axi4lite_pktcli[0].rdata   ),
  .axi4lite_pktcli_0_m0_rresp           (axi4lite_pktcli[0].rresp   ),
  .axi4lite_pktcli_0_m0_rvalid          (axi4lite_pktcli[0].rvalid  ),
  .axi4lite_pktcli_0_m0_rready          (axi4lite_pktcli[0].rready  ),
  
  .master_tod_csr_m0_waitrequest        (master_tod_csr_m0_waitrequest),   //in
  .master_tod_csr_m0_readdata           (master_tod_csr_m0_readdata),      //in
  .master_tod_csr_m0_readdatavalid      (master_tod_csr_m0_readdatavalid), //in
  .master_tod_csr_m0_burstcount         (),
  .master_tod_csr_m0_writedata          (master_tod_csr_m0_writedata),
  .master_tod_csr_m0_address            (master_tod_csr_m0_address),
  .master_tod_csr_m0_write              (master_tod_csr_m0_write),
  .master_tod_csr_m0_read               (master_tod_csr_m0_read),
  .master_tod_csr_m0_byteenable         (),
  .master_tod_csr_m0_debugaccess        (),
 
  
   `ifdef NUM_CHANNELS_2
 //##########################     PORT 1    ##########################################

  // --------------   Tx mSGDMA Channel 0 to HSSI port 1----------------------//

  .subsys_msgdma_ch0_eth_p1_axi_tx_st_tready                          (axis_h2d_if[2].tready),
  .subsys_msgdma_ch0_eth_p1_axi_tx_st_tvalid                          (axis_h2d_if[2].tvalid),
  .subsys_msgdma_ch0_eth_p1_axi_tx_st_tdata                           (axis_h2d_if[2].tdata ),
  .subsys_msgdma_ch0_eth_p1_axi_tx_st_tlast                           (axis_h2d_if[2].tlast ),
  .subsys_msgdma_ch0_eth_p1_axi_tx_st_tkeep                           (axis_h2d_if[2].tkeep ),
  .subsys_msgdma_ch0_eth_p1_axi_tx_st_tuser                           (dma_axi_st_tx_tuser_client_i[2]),//axis_h2d_if_pkt_fifo.tuser ),

  .subsys_msgdma_ch0_eth_p1_avst_tx_ptp_i_av_st_tx_skip_crc           ('d0),
  .subsys_msgdma_ch0_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_ts_valid       ('d0),
  .subsys_msgdma_ch0_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_ins_ets        ('d0),
  .subsys_msgdma_ch0_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_ins_cf         ('d0),
  .subsys_msgdma_ch0_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_tx_its         ('d0),
  .subsys_msgdma_ch0_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_asym_p2p_idx   ('d0),
  .subsys_msgdma_ch0_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_asym_sign      ('d0),
  .subsys_msgdma_ch0_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_asym           ('d0),
  .subsys_msgdma_ch0_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_p2p            ('d0),
  .subsys_msgdma_ch0_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_ts_format      ('d0),
  .subsys_msgdma_ch0_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_update_eb      ('d0),
  .subsys_msgdma_ch0_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_zero_csum      ('d0),
  .subsys_msgdma_ch0_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_eb_offset      ('d0),
  .subsys_msgdma_ch0_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_csum_offset    ('d0),
  .subsys_msgdma_ch0_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_cf_offset      ('d0),
  .subsys_msgdma_ch0_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_ts_offset      ('d0),
  `ifdef NON_PTP_ETHERNET
  .subsys_msgdma_ch0_eth_p1_avst_tx_ptp_valid                         (ch2_tx_dma_fifo_0_out_ts_req_valid),
  .subsys_msgdma_ch0_eth_p1_avst_tx_ptp_fingerprint                   (ch2_tx_dma_fifo_0_out_ts_req_fingerprint),
  `else
  .subsys_msgdma_ch0_eth_p1_avst_tx_ptp_valid                         (ts_req_valid2),
  .subsys_msgdma_ch0_eth_p1_avst_tx_ptp_fingerprint                   (ts_req_fingerprint2),
  `endif
  .subsys_msgdma_ch0_eth_p1_tx_dma_fifo_0_out_ts_req_valid            (ch2_tx_dma_fifo_0_out_ts_req_valid), 
  .subsys_msgdma_ch0_eth_p1_tx_dma_fifo_0_out_ts_req_fingerprint      (ch2_tx_dma_fifo_0_out_ts_req_fingerprint), 
  
  .subsys_msgdma_ch0_eth_p1_ts_chs_compl_0_clk_bus_in_clk_bus         (o_clk_pll_161m[1]),
  .subsys_msgdma_ch0_eth_p1_ts_chs_compl_0_rst_bus_in_rst_bus         (~eth_user_tx_rst_n[1]),
  
  .subsys_msgdma_ch0_eth_p1_fifo_user_rst_tx_reset_n                  (fifo_tx_user_reset[1]), //100Mhz
  .subsys_msgdma_ch0_eth_p1_fifo_user_rst_rx_reset_n                  (fifo_rx_user_reset[1]), //100Mhz
  
  .subsys_msgdma_ch0_eth_p1_hssi_rst_tx_reset_n                       (eth_user_tx_rst_n[1]),
  .subsys_msgdma_ch0_eth_p1_hssi_rst_rx_reset_n                       (eth_user_rx_rst_n[1]),
  
  .subsys_msgdma_ch0_eth_p1_tx_tuser_ptp_tuser_1                      (dma_axi_st_tx_tuser_ptp_i[2]),
  .subsys_msgdma_ch0_eth_p1_tx_tuser_ptp_extended_tuser_2             (dma_axi_st_tx_tuser_ptp_extended_i[2]),
  
  .subsys_msgdma_ch0_eth_p1_rx_tuser_sts_tuser_1                      ('d0),
  .subsys_msgdma_ch0_eth_p1_rx_ingrts0_interface_tdata                (dma_axi_st_rxigrts_tdata[2]),
  .subsys_msgdma_ch0_eth_p1_rx_ingrts0_interface_tvalid               (dma_axi_st_rxigrts_tvalid[2]),
  

  .subsys_msgdma_ch0_eth_p1_avst_rx_ptp_valid                         (dma_axi_st_rxigrts_tvalid_reg0[2]),  
  .subsys_msgdma_ch0_eth_p1_avst_rx_ptp_data                          (dma_axi_st_rxigrts_tdata_reg0[2] ),  
  	
  .subsys_msgdma_ch0_eth_p1_rx_dma_fifo_in_ts_data                    (rx_ingrts0_interface_0_tdata[2]),  
  .subsys_msgdma_ch0_eth_p1_rx_dma_fifo_in_ts_valid                   (rx_ingrts0_interface_0_tvalid[2]),
 
  
 // --------------  HSSI Port1 to Rx mSGDMA  Channel 0  ----------------------//                                              
   .subsys_msgdma_ch0_eth_p1_axi_rx_st_tvalid                         (axis_d2h_if[2].tvalid),
   .subsys_msgdma_ch0_eth_p1_axi_rx_st_tdata                          (axis_d2h_if[2].tdata ),
   .subsys_msgdma_ch0_eth_p1_axi_rx_st_tlast                          (axis_d2h_if[2].tlast ),
   .subsys_msgdma_ch0_eth_p1_axi_rx_st_tkeep                          (axis_d2h_if[2].tkeep ),
   .subsys_msgdma_ch0_eth_p1_axi_rx_st_tuser                          ('d0),//axis_d2h_if_pkt_fifo.tuser ),

   .subsys_msgdma_ch0_eth_p1_hssi_ets_ts_adapter_0_egrs_ts_hssi_tvalid(tx_ts_valid[2]),
   .subsys_msgdma_ch0_eth_p1_hssi_ets_ts_adapter_0_egrs_ts_hssi_tdata ({tx_ts_fp[2],tx_ts_data[2]}),

  // --------------   Tx mSGDMA Channel 1 to HSSI port 1----------------------//

  .subsys_msgdma_ch1_eth_p1_axi_tx_st_tready                          (axis_h2d_if[3].tready),
  .subsys_msgdma_ch1_eth_p1_axi_tx_st_tvalid                          (axis_h2d_if[3].tvalid),
  .subsys_msgdma_ch1_eth_p1_axi_tx_st_tdata                           (axis_h2d_if[3].tdata ),
  .subsys_msgdma_ch1_eth_p1_axi_tx_st_tlast                           (axis_h2d_if[3].tlast ),
  .subsys_msgdma_ch1_eth_p1_axi_tx_st_tkeep                           (axis_h2d_if[3].tkeep ),
  .subsys_msgdma_ch1_eth_p1_axi_tx_st_tuser                           (dma_axi_st_tx_tuser_client_i[3]),//axis_h2d_if_pkt_fifo.tuser ),

  .subsys_msgdma_ch1_eth_p1_avst_tx_ptp_i_av_st_tx_skip_crc           ('d0),
  .subsys_msgdma_ch1_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_ts_valid       ('d0),
  .subsys_msgdma_ch1_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_ins_ets        ('d0),
  .subsys_msgdma_ch1_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_ins_cf         ('d0),
  .subsys_msgdma_ch1_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_tx_its         ('d0),
  .subsys_msgdma_ch1_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_asym_p2p_idx   ('d0),
  .subsys_msgdma_ch1_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_asym_sign      ('d0),
  .subsys_msgdma_ch1_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_asym           ('d0),
  .subsys_msgdma_ch1_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_p2p            ('d0),
  .subsys_msgdma_ch1_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_ts_format      ('d0),
  .subsys_msgdma_ch1_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_update_eb      ('d0),
  .subsys_msgdma_ch1_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_zero_csum      ('d0),
  .subsys_msgdma_ch1_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_eb_offset      ('d0),
  .subsys_msgdma_ch1_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_csum_offset    ('d0),
  .subsys_msgdma_ch1_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_cf_offset      ('d0),
  .subsys_msgdma_ch1_eth_p1_avst_tx_ptp_i_av_st_tx_ptp_ts_offset      ('d0),
  `ifdef NON_PTP_ETHERNET
  .subsys_msgdma_ch1_eth_p1_avst_tx_ptp_valid                         (ch3_tx_dma_fifo_0_out_ts_req_valid),
  .subsys_msgdma_ch1_eth_p1_avst_tx_ptp_fingerprint                   (ch3_tx_dma_fifo_0_out_ts_req_fingerprint),
  `else
  .subsys_msgdma_ch1_eth_p1_avst_tx_ptp_valid                         (ts_req_valid3),
  .subsys_msgdma_ch1_eth_p1_avst_tx_ptp_fingerprint                   (ts_req_fingerprint3),
  `endif
  .subsys_msgdma_ch1_eth_p1_tx_dma_fifo_0_out_ts_req_valid            (ch3_tx_dma_fifo_0_out_ts_req_valid), 
  .subsys_msgdma_ch1_eth_p1_tx_dma_fifo_0_out_ts_req_fingerprint      (ch3_tx_dma_fifo_0_out_ts_req_fingerprint), 
  
  .subsys_msgdma_ch1_eth_p1_ts_chs_compl_0_clk_bus_in_clk_bus         (o_clk_pll_161m[1]),
  .subsys_msgdma_ch1_eth_p1_ts_chs_compl_0_rst_bus_in_rst_bus         (~eth_user_tx_rst_n[1]),
  
  .subsys_msgdma_ch1_eth_p1_fifo_user_rst_tx_reset_n                  (fifo_tx_user_reset[1]), //100Mhz
  .subsys_msgdma_ch1_eth_p1_fifo_user_rst_rx_reset_n                  (fifo_rx_user_reset[1]), //100Mhz
  
  .subsys_msgdma_ch1_eth_p1_hssi_rst_tx_reset_n                       (eth_user_tx_rst_n[1]),
  .subsys_msgdma_ch1_eth_p1_hssi_rst_rx_reset_n                       (eth_user_rx_rst_n[1]),
  
  .subsys_msgdma_ch1_eth_p1_tx_tuser_ptp_tuser_1                      (dma_axi_st_tx_tuser_ptp_i[3]),
  .subsys_msgdma_ch1_eth_p1_tx_tuser_ptp_extended_tuser_2             (dma_axi_st_tx_tuser_ptp_extended_i[3]),
  
  .subsys_msgdma_ch1_eth_p1_rx_tuser_sts_tuser_1                      ('d0),
  .subsys_msgdma_ch1_eth_p1_rx_ingrts0_interface_tdata                (dma_axi_st_rxigrts_tdata[3]),
  .subsys_msgdma_ch1_eth_p1_rx_ingrts0_interface_tvalid               (dma_axi_st_rxigrts_tvalid[3]),
  

  .subsys_msgdma_ch1_eth_p1_avst_rx_ptp_valid                         (dma_axi_st_rxigrts_tvalid_reg0[3]),  
  .subsys_msgdma_ch1_eth_p1_avst_rx_ptp_data                          (dma_axi_st_rxigrts_tdata_reg0[3] ),  
  	
  .subsys_msgdma_ch1_eth_p1_rx_dma_fifo_in_ts_data                    (rx_ingrts0_interface_0_tdata[3]),  
  .subsys_msgdma_ch1_eth_p1_rx_dma_fifo_in_ts_valid                   (rx_ingrts0_interface_0_tvalid[3]),
 
  
 // --------------  HSSI Port1 to Rx mSGDMA  Channel 1  ----------------------//                                              
   .subsys_msgdma_ch1_eth_p1_axi_rx_st_tvalid                         (axis_d2h_if[3].tvalid),
   .subsys_msgdma_ch1_eth_p1_axi_rx_st_tdata                          (axis_d2h_if[3].tdata ),
   .subsys_msgdma_ch1_eth_p1_axi_rx_st_tlast                          (axis_d2h_if[3].tlast ),
   .subsys_msgdma_ch1_eth_p1_axi_rx_st_tkeep                          (axis_d2h_if[3].tkeep ),
   .subsys_msgdma_ch1_eth_p1_axi_rx_st_tuser                          ('d0),//axis_d2h_if_pkt_fifo.tuser ),

   .subsys_msgdma_ch1_eth_p1_hssi_ets_ts_adapter_0_egrs_ts_hssi_tvalid(tx_ts_valid[3]),
   .subsys_msgdma_ch1_eth_p1_hssi_ets_ts_adapter_0_egrs_ts_hssi_tdata ({tx_ts_fp[3],tx_ts_data[3]}),
	
  
  
  .clk_in_1_161m_clk                  	(o_clk_pll_161m[1]),
  .qhip_port_1_m0_waitrequest           (o_reconfig_eth_waitrequest[1]   ),
  .qhip_port_1_m0_readdata              (o_reconfig_eth_readdata[1]      ),
  .qhip_port_1_m0_readdatavalid         (o_reconfig_eth_readdata_valid[1]),
  .qhip_port_1_m0_burstcount            (),
  .qhip_port_1_m0_writedata             (i_reconfig_eth_writedata[1]     ),
  .qhip_port_1_m0_address               (i_reconfig_eth_addr[1]          ),
  .qhip_port_1_m0_write                 (i_reconfig_eth_write [1]        ),
  .qhip_port_1_m0_read                  (i_reconfig_eth_read[1]          ),
  .qhip_port_1_m0_byteenable            (i_reconfig_eth_byteenable[1]    ),
  .qhip_port_1_m0_debugaccess           (),
  .axi4lite_pktcli_1_m0_awaddr          (axi4lite_pktcli[1].awaddr  ),
  .axi4lite_pktcli_1_m0_awprot          (axi4lite_pktcli[1].awprot  ),
  .axi4lite_pktcli_1_m0_awvalid         (axi4lite_pktcli[1].awvalid ),
  .axi4lite_pktcli_1_m0_awready         (axi4lite_pktcli[1].awready ),
  .axi4lite_pktcli_1_m0_wdata           (axi4lite_pktcli[1].wdata   ),
  .axi4lite_pktcli_1_m0_wstrb           (axi4lite_pktcli[1].wstrb   ),
  .axi4lite_pktcli_1_m0_wvalid          (axi4lite_pktcli[1].wvalid  ),
  .axi4lite_pktcli_1_m0_wready          (axi4lite_pktcli[1].wready  ),
  .axi4lite_pktcli_1_m0_bresp           (axi4lite_pktcli[1].bresp   ),
  .axi4lite_pktcli_1_m0_bvalid          (axi4lite_pktcli[1].bvalid  ),
  .axi4lite_pktcli_1_m0_bready          (axi4lite_pktcli[1].bready  ),
  .axi4lite_pktcli_1_m0_araddr          (axi4lite_pktcli[1].araddr  ),
  .axi4lite_pktcli_1_m0_arprot          (axi4lite_pktcli[1].arprot  ),
  .axi4lite_pktcli_1_m0_arvalid         (axi4lite_pktcli[1].arvalid ),
  .axi4lite_pktcli_1_m0_arready         (axi4lite_pktcli[1].arready ),
  .axi4lite_pktcli_1_m0_rdata           (axi4lite_pktcli[1].rdata   ),
  .axi4lite_pktcli_1_m0_rresp           (axi4lite_pktcli[1].rresp   ),
  .axi4lite_pktcli_1_m0_rvalid          (axi4lite_pktcli[1].rvalid  ),
  .axi4lite_pktcli_1_m0_rready          (axi4lite_pktcli[1].rready  ),
   `endif
  .axi4lite_packetsw_m0_awaddr          (axi4lite_packetsw.awaddr  ),
  .axi4lite_packetsw_m0_awprot          (axi4lite_packetsw.awprot  ),
  .axi4lite_packetsw_m0_awvalid         (axi4lite_packetsw.awvalid ),
  .axi4lite_packetsw_m0_awready         (axi4lite_packetsw.awready ),
  .axi4lite_packetsw_m0_wdata           (axi4lite_packetsw.wdata   ),
  .axi4lite_packetsw_m0_wstrb           (axi4lite_packetsw.wstrb   ),
  .axi4lite_packetsw_m0_wvalid          (axi4lite_packetsw.wvalid  ),
  .axi4lite_packetsw_m0_wready          (axi4lite_packetsw.wready  ),
  .axi4lite_packetsw_m0_bresp           (axi4lite_packetsw.bresp   ),
  .axi4lite_packetsw_m0_bvalid          (axi4lite_packetsw.bvalid  ),
  .axi4lite_packetsw_m0_bready          (axi4lite_packetsw.bready  ),
  .axi4lite_packetsw_m0_araddr          (axi4lite_packetsw.araddr  ),
  .axi4lite_packetsw_m0_arprot          (axi4lite_packetsw.arprot  ),
  .axi4lite_packetsw_m0_arvalid         (axi4lite_packetsw.arvalid ),
  .axi4lite_packetsw_m0_arready         (axi4lite_packetsw.arready ),
  .axi4lite_packetsw_m0_rdata           (axi4lite_packetsw.rdata   ),
  .axi4lite_packetsw_m0_rresp           (axi4lite_packetsw.rresp   ),
  .axi4lite_packetsw_m0_rvalid          (axi4lite_packetsw.rvalid  ),
  .axi4lite_packetsw_m0_rready          (axi4lite_packetsw.rready  ),

  .f2h_irq1_in_irq                      (32'd0),   
  .subsys_msgdma_ch0_eth_p0_avst_rx_ptp_o_av_st_rxstatus_data   (),        
  .subsys_msgdma_ch1_eth_p0_avst_rx_ptp_o_av_st_rxstatus_data   (),        
  .subsys_msgdma_ch0_eth_p1_avst_rx_ptp_o_av_st_rxstatus_data   (),         
  .subsys_msgdma_ch1_eth_p1_avst_rx_ptp_o_av_st_rxstatus_data   ()          
);   

for(genvar i = 0; i < NUM_CHANNELS; i++) begin : user_last_segment_assign
  assign user_axi_st_tx_tuser_last_segment_i[i][0] = user_axi_st_tx_tlast_i[i] ;
  assign user_axi_st_tx_tuser_pkt_seg_parity_i[i]  = 1'b0;
end
		
		
 // ********************************************************************* //
// GTS Reset Sequencer Intel FPGA Hard IP provides 
// the PMA Control Unit clock i_pma_cu_clk to the GTS Ethernet Intel FPGA Hard IP.
// ********************************************************************* //

  gts_reset_sequencer reset_sequencer (
		 .o_src_rs_grant    (i_src_rs_grant),    
		 .i_src_rs_priority (2'b00),             
		 .i_src_rs_req      (o_src_rs_req),      
		 .o_pma_cu_clk      (i_pma_cu_clk)       
	);


// ********************************************************************* //
// GTS System PLL Intel FPGA Hard IP provides 
// i_clk_sys to the GTS Ethernet Intel FPGA Hard IP.
// ********************************************************************* //
 gts_systempll system_pll (
        .o_pll_lock     (o_pll_lock),     
        .o_syspll_c0    (o_clk_sys),      
        .i_refclk       (i_clk_ref_p[0]), 
        .i_refclk_ready (1'b1)             
    );   
 
// ********************************************************************* //
//                  Master Tod
// ********************************************************************* //
reg         ptp_rst_n_src;
wire        ptp_master_tod_rst_n;
wire        clk_todsync_sample; 
wire        clk_todsync_sample_locked;
wire        ptp_master_tod_96b_load_valid;
wire [95:0] ptp_master_tod_96b_load_data;
wire        ptp_master_tod_valid;
wire [95:0] ptp_master_tod;

intel_eth_gts_ptp_xcvr_resync_std #(
    .SYNC_CHAIN_LENGTH  (3),
    .WIDTH              (1),
    .INIT_VALUE         (0)
) master_tod_rst_sync (
    .clk                (i_clk_master_tod),
    .reset              (1'b0),
    .d                  (system_reset_n),
    .q                  (ptp_master_tod_rst_n)
);

//---------------------------------------------------------------
// TOD Synchronizer's sampling clock (derived from master TOD clock)
sync_tod_iopll todsync_sampl_pll (
		.refclk   (i_clk_master_tod),    
		.locked   (clk_todsync_sample_locked),    
		.rst      (~ptp_master_tod_rst_n),      
		.outclk_0 (clk_todsync_sample) //106.66Mhz(tod sync & advance pps_sampling clk) 
	);

//---------------------------------------------------------------
// Master Time-of-Day
assign master_tod_csr_m0_readdatavalid = master_tod_csr_m0_read & !master_tod_csr_m0_waitrequest;

intel_eth_gts_ptp_mtod_top #(
    .EN_PPS_ADV (EN_PPS_ADV)
) master_tod (
    .i_clk_reconfig             (clk_bdg_100_clk),
    .i_reconfig_rst_n           (iopll_locked_export_100M),
    .i_clk_tod                  (i_clk_master_tod),
	 .pps_samp_clk               (clk_todsync_sample),
    .i_tod_rst_n                (ptp_master_tod_rst_n),
    .i_csr_addr                 (master_tod_csr_m0_address[5:2]),
    .i_csr_write                (master_tod_csr_m0_write),
    .i_csr_writedata            (master_tod_csr_m0_writedata),
    .i_csr_read                 (master_tod_csr_m0_read),
    .o_csr_readdata             (master_tod_csr_m0_readdata),
    .o_csr_waitrequest          (master_tod_csr_m0_waitrequest),
    .i_tod_96b_load_valid       (ptp_master_tod_96b_load_valid),
    .i_tod_96b_load_data        (ptp_master_tod_96b_load_data),
    .o_tod_96b_valid            (ptp_master_tod_valid),
    .o_tod_96b_data             (ptp_master_tod),
    .o_pps                      (o_ptp_pps)  
);
// Master TOD load - not demonstrating
assign ptp_master_tod_96b_load_valid  = 1'b0;
assign ptp_master_tod_96b_load_data   = 96'h0;


generate for(genvar i=0;i<NUM_CHANNELS;i++) begin : gen_mulit_inst


      assign eth_user_tx_rst_n [i]  = o_user_tx_rst_n_161[i] & iopll_locked_export_161[i];
      assign eth_user_rx_rst_n [i]  = o_user_rx_rst_n_161[i] & iopll_locked_export_161[i];
      assign fifo_tx_user_reset [i] = o_user_tx_rst_n_100[i] & iopll_locked_export_100M;
      assign fifo_rx_user_reset [i] = o_user_rx_rst_n_100[i] & iopll_locked_export_100M;  

		assign clk_tx_tod[i]  = o_clk_tx_div[i] ;
      assign clk_rx_tod[i]  = o_clk_rec_div_66_int[i];

	
    // PTP Timestamp Accuracy Mode = "1:Advanced"

    assign tx_tod_rst_n_wire[i] = tx_pll_locked_sync[i] & tx_todsync_sampling_clk_locked_sync[i];
    assign rx_tod_rst_n_wire[i] = rx_cdr_lock_sync[i] & rx_todsync_sampling_clk_locked_sync[i];
    
    // flops to fix recovery time violation from tx_tod_rst_n to tod_sync inst
    always @(posedge clk_tx_tod[i]) begin
        tx_tod_rst_n_reg [i] <= tx_tod_rst_n_wire[i];
        tx_tod_rst_n_reg2[i] <= tx_tod_rst_n_reg [i];
        tx_tod_rst_n     [i] <= tx_tod_rst_n_reg2[i];
    end
    always @(posedge clk_rx_tod[i]) begin
        rx_tod_rst_n_reg  [i] <= rx_tod_rst_n_wire[i];
        rx_tod_rst_n_reg2 [i] <= rx_tod_rst_n_reg [i];
        rx_tod_rst_n      [i] <= rx_tod_rst_n_reg2[i];
    end

    intel_eth_gts_altera_std_synchronizer_nocut tx_todsync_sampling_locked_sync_inst (
        .clk        (clk_tx_tod[i]),
        .reset_n    (1'b1),
        .din        (clk_todsync_sample_locked),
        .dout       (tx_todsync_sampling_clk_locked_sync[i])
    );
    intel_eth_gts_altera_std_synchronizer_nocut rx_todsync_sampling_locked_sync_inst (
        .clk        (clk_rx_tod[i]),
        .reset_n    (1'b1),
        .din        (clk_todsync_sample_locked),
        .dout       (rx_todsync_sampling_clk_locked_sync[i])
    );
    intel_eth_gts_altera_std_synchronizer_nocut tx_pll_locked_sync_inst (
        .clk        (clk_tx_tod[i]),
        .reset_n    (1'b1),
        .din        (o_tx_pll_locked[i]),
        .dout       (tx_pll_locked_sync[i])
    );
    intel_eth_gts_altera_std_synchronizer_nocut rx_cdr_lock_sync_inst (
        .clk        (clk_rx_tod[i]),
        .reset_n    (1'b1),
        .din        (o_cdr_lock[i]),
        .dout       (rx_cdr_lock_sync[i])
    );
// ********************************************************************* //
//                 Slave Tx Tod
// ********************************************************************* //
 intel_eth_gts_ptp_stod_top #(
 .EN_10G_ADV_MODE (1),
 .SYNC_MODE       (2) 
    ) tx_tod (
        .i_clk_reconfig             (clk_bdg_100_clk),
        .i_reconfig_rst_n           (iopll_locked_export_100M),
        .i_clk_mtod                 (i_clk_master_tod),
        .i_clk_stod                 (clk_tx_tod[i]),
        .i_clk_todsync_sampling     (clk_todsync_sample),
        .i_mtod_rst_n               (ptp_master_tod_rst_n),
        .i_stod_rst_n               (tx_tod_rst_n[i]),
        .i_mtod_data                (ptp_master_tod),
        .i_mtod_valid               (ptp_master_tod_valid),
        .o_stod_data                (ptp_tx_tod[i]),
        .o_stod_valid               (ptp_tx_tod_valid[i])
    );
// ********************************************************************* //
//                  Slave Rx Tod
// ********************************************************************* //
    intel_eth_gts_ptp_stod_top #(
        .EN_10G_ADV_MODE (1),
		  .SYNC_MODE       (2)
    ) rx_tod (
        .i_clk_reconfig             (clk_bdg_100_clk),
        .i_reconfig_rst_n           (iopll_locked_export_100M),
        .i_clk_mtod                 (i_clk_master_tod),
        .i_clk_stod                 (clk_rx_tod[i]),
        .i_clk_todsync_sampling     (clk_todsync_sample),
        .i_mtod_rst_n               (ptp_master_tod_rst_n),
        .i_stod_rst_n               (rx_tod_rst_n[i]),
        .i_mtod_data                (ptp_master_tod),
        .i_mtod_valid               (ptp_master_tod_valid),
        .o_stod_data                (ptp_rx_tod[i]),
        .o_stod_valid               (ptp_rx_tod_valid[i])
    );
// PTP ED TODs -- end
// ********************************************************************* //
//                  HSSI Subsystem Instance
// ********************************************************************* //
  
 hssi_ss_top #(
   .DEBUG_ENABLE (DEBUG_ENABLE),
	.TX_EGRESS    (TX_EGRESS)
   )hssi_ss_top (
 //.i_refclk2pll_p        (i_refclk2pll_p_d[i]), //Ethernet system clock
   .i_clk_sys             (o_clk_sys),//Ethernet system clock
   .i_pll_lock            (o_pll_lock),
   .i_reconfig_clk        (i_reconfig_clk[i]),
   .i_clk_ref_p           (i_clk_ref_p[i]), //reference clock for TX PLL channel
   
   .i_rx_serial_data      (i_rx_serial_data[i*1+:1]   ),
   .i_rx_serial_data_n    (i_rx_serial_data_n[i*1+:1] ),
   .o_tx_serial_data      (o_tx_serial_data[i*1+:1]   ),
   .o_tx_serial_data_n    (o_tx_serial_data_n[i*1+:1] ),
   
   .i_rst_n               (i_rst_n_125   [i]),
   .i_tx_rst_n            (i_tx_rst_n[i]),
   .i_rx_rst_n            (i_rx_rst_n[i]),
   .eth_user_tx_rst_n     (eth_user_tx_rst_n[i]),
   .eth_user_rx_rst_n     (eth_user_rx_rst_n[i]),
   
   .rst_ack_n             (rst_ack_n   [i]),
   .tx_rst_ack_n          (tx_rst_ack_n[i]),
   .rx_rst_ack_n          (rx_rst_ack_n[i]),
   
   .i_reconfig_reset      (!iopll_locked_export_125M),
   
   .o_clk_pll_161m        (o_clk_pll_161m[i]),
  
   .o_cdr_lock            (o_cdr_lock [i]),
   .o_tx_pll_locked       (o_tx_pll_locked[i]),
   .o_tx_lanes_stable     (o_tx_lanes_stable[i] ),
   .o_rx_pcs_ready        (o_rx_pcs_ready[i]),
   .o_clk_rec_div64       (),
   
   .o_rx_block_lock        (),
   .o_local_fault_status   (),
   .o_remote_fault_status  (),
   .i_stats_snapshot       ('d0),  
   .o_rx_hi_ber            (),
   .o_rx_pcs_fully_aligned (),

   //------------  Tx ports  ----------------------/                                                                                  
   //  AXI Stream Tx, from PTP bridge subystem   
   .pp_app_ss_st_tx_tready       (hssi_ss_st_tx_tready[i]),
   .app_pp_ss_st_tx_tvalid       (hssi_ss_st_tx_tvalid[i]),
   .app_pp_ss_st_tx_tdata        (hssi_ss_st_tx_tdata[i] ),
   .app_pp_ss_st_tx_tlast        (hssi_ss_st_tx_tlast[i] ),
   .app_pp_ss_st_tx_tkeep        (hssi_ss_st_tx_tkeep[i] ),
   .app_pp_ss_st_tx_client       (hssi_ss_st_tx_tuser_client[i] ),
   .app_pp_ss_st_tx_ptp          (hssi_ss_st_tx_tuser_ptp[i]),
   .app_pp_ss_st_tx_ptp_extended (hssi_ss_st_tx_tuser_ptp_extended[i]),
   .app_pp_ss_st_tx_seg_parity   (hssi_ss_st_tx_tuser_pkt_seg_parity[i]),
   
    //---------- TX EGRESS ------------------
   .axi_st_txegrts_tvalid_o      (hssi_ptp_tx_egrts_tvalid[i]),          
   .axi_st_txegrts_tdata_o       (hssi_ptp_tx_egrts_tdata[i]),
   
  //------------  Rx ports  ----------------------/                                                                                  
  //  AXI Stream Rx, to PTP bridge subystem                                                                                   
   .ss_pp_app_rx_tvalid                  (hssi_ss_st_rx_tvalid[i]),
   .ss_pp_app_rx_tdata                   (hssi_ss_st_rx_tdata[i] ),
   .ss_pp_app_rx_tkeep                   (hssi_ss_st_rx_tkeep[i] ),
   .ss_pp_app_rx_tlast                   (hssi_ss_st_rx_tlast[i] ),
   .ss_pp_app_rx_tuser_client            (),
   .ss_pp_app_rx_tuser_sts               (),
   .ss_pp_app_rx_tuser_sts_extended      (),
   .ss_pp_app_st_rx_tuser_pkt_seg_parity (),

 .axi_st_rxingrts_tvalid_o             (hssi_ptp_rx_ingrts_tvalid[i]),  
 .axi_st_rxingrts_tdata_o              (hssi_ptp_rx_ingrts_tdata[i]),
 
 .i_clk_tx_tod   (clk_tx_tod[i]),
 .i_clk_rx_tod   (clk_rx_tod[i]),
 .i_clk_ptp_sample (clk_ptp_sample),
									   
 .axi_st_txtod_tvalid_i                (ptp_tx_tod_valid[i]),
 .axi_st_txtod_tdata_i                 (ptp_tx_tod[i]),
									 
 .axi_st_rxtod_tvalid                  (ptp_rx_tod_valid[i]),
 .axi_st_rxtod_tdata                   (ptp_rx_tod[i]),
									
 .o_clk_tx_div_66                      (o_clk_tx_div[i]),
 .o_clk_rec_div_66                     (o_clk_rec_div_66_int[i]),
								
 .i_tx_pause                           (),
 .o_rx_pause                           (),
									
 .i_tx_pfc                             (),
 .o_rx_pfc                             (),

 
   .i_reconfig_eth_addr                  (i_reconfig_eth_addr          [i] >> 2),
   .i_reconfig_eth_byteenable            (i_reconfig_eth_byteenable    [i]),
   .o_reconfig_eth_readdata_valid        (o_reconfig_eth_readdata_valid[i]),
   .i_reconfig_eth_read                  (i_reconfig_eth_read          [i]),
   .i_reconfig_eth_write                 (i_reconfig_eth_write         [i]),
   .o_reconfig_eth_readdata              (o_reconfig_eth_readdata      [i]),
   .i_reconfig_eth_writedata             (i_reconfig_eth_writedata     [i]),
   .o_reconfig_eth_waitrequest           (o_reconfig_eth_waitrequest   [i]),
   .i_src_rs_grant                       (i_src_rs_grant[i]),
   .o_src_rs_req                         (o_src_rs_req  [i]),
   .i_pma_cu_clk                         (i_pma_cu_clk  [i])
);  

// ********************************************************************* //
//                  Packet Client adaptor
// ********************************************************************* //

 eth_f_packet_client_top_axi_adaptor #(
    .WIDTH                                 (DATA_WIDTH),
    .WORDS                                 (WORDS),
    .EMPTY_WIDTH                           (EMPTY_WIDTH)
  ) packet_client_axi_adaptor_top_0(
    .i_arst                                (eth_user_rx_rst_n[i]), // active low reset
    .i_clk_tx                              (o_clk_pll_161m[i] ),
    .i_clk_rx                              (o_clk_pll_161m[i] ),
    
    //from packet client tx
    .o_avst_tx_ready                       (avst_tx_ready_int            [i]),
    .i_avst_tx_valid                       (avst_tx_valid_int            [i]),
    .i_avst_tx_sop                         (avst_tx_sop_int              [i]),
    .i_avst_tx_eop                         (avst_tx_eop_int              [i]),
    .i_avst_tx_empty                       (avst_tx_empty_int            [i]),
    .i_avst_tx_data                        (avst_tx_data_int             [i]),
    .i_avst_tx_error                       (avst_tx_error_int            [i]),
    .i_avst_tx_skip_crc                    (avst_tx_skip_crc_int         [i]),

																	     
    // to packet_switch                                                         

    .i_axis_tx_ready                       (user_axi_st_tx_tready_o      [i]),
    .o_axis_tx_valid                       (user_axi_st_tx_tvalid_i      [i]),
    .o_axis_tx_tdata                       (user_axi_st_tx_tdata_i       [i]),
    .o_axis_tx_tkeep                       (user_axi_st_tx_tkeep_i       [i]),
    .o_axis_tx_tlast                       (user_axi_st_tx_tlast_i       [i]),
    .o_axis_tx_tuser                       (user_axi_st_tx_tuser_ptp_i   [i]),

    // from packet_switch
    .o_axis_rx_ready                       (user_axi_st_rx_tready_i      [i]),
    .i_axis_rx_valid                       (user_axi_st_rx_tvalid_o      [i]),
    .i_axis_rx_tdata                       (user_axi_st_rx_tdata_o       [i]),
    .i_axis_rx_tlast                       (user_axi_st_rx_tlast_o       [i]),
    .i_axis_rx_tkeep                       (user_axi_st_rx_tkeep_o       [i]),
    .i_axis_rx_tuser                       (user_axi_st_rx_tuser_client_o[i]),

    // to packet client rx
    .i_avst_rx_ready                       (1'b1),
    .o_avst_rx_valid                       (avst_rx_valid_int            [i]),
    .o_avst_rx_tdata                       (avst_rx_tdata_int            [i]),
    .o_avst_rx_empty                       (avst_rx_empty_int            [i]),
    .o_avst_rx_sop                         (avst_rx_sop_int              [i]),
    .o_avst_rx_eop                         (avst_rx_eop_int              [i]),
    .o_tx_st_eop_sync_with_macsec_tuser_error ()
  );

// ********************************************************************* //
//                  Packet Client Top
// ********************************************************************* //  
 eth_f_packet_client_top #(
     .PKT_CYL          (PKT_CYL          ) 
    ,.CLIENT_IF_TYPE   (CLIENT_IF_TYPE   ) 
    ,.READY_LATENCY    (READY_LATENCY    ) 
    ,.DATA_WIDTH       (DATA_WIDTH       ) 
    ,.WORDS            (WORDS            ) 
    ,.EMPTY_WIDTH      (EMPTY_WIDTH      ) 
    ) i_eth_f_packet_client_top (
    .i_arst_tx                                (!eth_user_tx_rst_n[i]) , 
    .i_arst_rx                                (!eth_user_rx_rst_n[i]) , 
    .i_clk_tx                              (o_clk_pll_161m   [i] ),
    .i_clk_rx                              (o_clk_pll_161m   [i] ),
    .i_clk_status                          (clk_bdg_125_clk),
    .i_clk_status_rst                      (!iopll_locked_export_125M),
	
     //AVST TX IF -done
    .i_tx_ready                            (avst_tx_ready_int     [i]),
    .o_tx_valid                            (avst_tx_valid_int     [i]),
    .o_tx_sop                              (avst_tx_sop_int       [i]),
    .o_tx_eop                              (avst_tx_eop_int       [i]),
    .o_tx_empty                            (avst_tx_empty_int     [i]),
    .o_tx_data                             (avst_tx_data_int      [i]),
    .o_tx_error                            (avst_tx_error_int     [i]),
    .o_tx_skip_crc                         (avst_tx_skip_crc_int  [i]),
    .i_rx_valid                            (avst_rx_valid_int     [i]),
    .i_rx_sop                              (avst_rx_sop_int       [i]),
    .i_rx_eop                              (avst_rx_eop_int       [i]),
    .i_rx_empty                            (avst_rx_empty_int     [i]),
    .i_rx_data                             (avst_rx_tdata_int     [i]),
    .i_rx_error                            (7'b0),    
    .i_rxstatus_valid                      (1'b0),
    .i_rxstatus_data                       (40'd0),
    .i_rx_preamble                         (64'b0),
    .o_tx_preamble                         (),
    
    .pktcli_csr_if_slv                     (axi4lite_pktcli [i]),
    .o_cold_rst_csr                        (), 
    .i_sadb_config_done                    (1'b0),
    .i_system_status                       (trafficgen_system_status [i])
);
                                   
end endgenerate

// ********************************************************************* //
//                  Reset Controller
// ********************************************************************* //  
srd_rst_ctrl #(
  .NUM_CHANNELS (NUM_CHANNELS)
)inst_srd_rst_ctrl
(
  .pwrgood_rst_n             (iopll_locked_export_161),  //(iopll_locked_export_125M), 
  .i_sys_rst_n               (o_csr_rst_n   ),
  .i_sys_tx_rst_n            (o_csr_tx_rst_n),  
  .i_sys_rx_rst_n            (o_csr_rx_rst_n),  

  .i_clk_pll_161m            (o_clk_pll_161m),//161Mhz ETH clk
  .i_clk_csr                 (o_clk_pll_161m), //i_reconfig_clk), //125Mhz CSR clk
  .i_clk_100                 (clk_bdg_100_clk),//100Mhz DMA clk

  .o_eth_rx_rst_n            (i_rx_rst_n ),
  .o_eth_tx_rst_n            (i_tx_rst_n ),
  .o_eth_rst_n               (i_rst_n    ),
  .o_eth_csr_rst_n           (),
  
  .i_rst_ack_n               (rst_ack_n    ),
  .i_tx_rst_ack_n            (tx_rst_ack_n ),
  .i_rx_rst_ack_n            (rx_rst_ack_n ),
  .o_user_tx_rst_n_161       (o_user_tx_rst_n_161),
  .o_user_rx_rst_n_161       (o_user_rx_rst_n_161),
  .o_user_tx_rst_n_100       (o_user_tx_rst_n_100),
  .o_user_rx_rst_n_100       (o_user_rx_rst_n_100)
);

// ********************************************************************* //
//                  USER SPACE CSR Module
// ********************************************************************* //  
  
 top_user_space_csr #(
  .NUM_CHANNELS (NUM_CHANNELS),
  .FIFO_DEPTH   (FIFO_DEPTH)
 )top_user_space_csr (
  .csr_clk               (clk_bdg_125_clk),
  .reset                 (iopll_locked_export_125M),
  .csr_wr_data           (user_space_csr_m0_writedata     ),
  .csr_read              (user_space_csr_m0_read          ),
  .csr_write             (user_space_csr_m0_write         ),
  .csr_byteenable        (user_space_csr_m0_byteenable    ),
  .csr_address           (user_space_csr_m0_address       ),
  .csr_waitrequest       (user_space_csr_m0_waitrequest   ),
  .csr_rd_data           (user_space_csr_m0_readdata      ),
  .csr_rd_vld            (user_space_csr_m0_readdatavalid ),
   
  .ack_i_rst_n           (rst_ack_n_125), 
  .ack_i_tx_rst_n        (tx_rst_ack_n),                    
  .ack_i_rx_rst_n        (rx_rst_ack_n),
 
  .o_rst_n               (o_csr_rst_n   ),
  .o_tx_rst_n            (o_csr_tx_rst_n),
  .o_rx_rst_n            (o_csr_rx_rst_n),
  
  .i_rx_pcs_ready        (o_rx_pcs_ready   ),
  .i_tx_lanes_stable     (o_tx_lanes_stable),
  .i_tx_pll_locked       (o_tx_pll_locked  ),
  .i_cdr_lock            (o_cdr_lock       ),
  .i_sys_pll_locked      (iopll_locked_export),
  `ifdef NUM_CHANNELS_2
  .port1_tx_fifo_depth_i  (),
  .port1_rx_fifo_depth_i  (),
  `endif
  .port0_tx_fifo_depth_i  (),
  .port0_rx_fifo_depth_i  ()
);


// ################################################################### // 
//RES-50004 - Multiple Asynchronous Resets within Reset Synchronizer Chain	
// During asynchronous reset synchronizer chain, we should use common reset pin for every register//
// so removing the negedge iopll_locked_export_125M, we should during synchronous reset 
// ################################################################### // 
// ********************************************************************* //
//                  Packet Switch reset sequence
// ********************************************************************* //  

// cold boot reset logic
  eth_f_altera_std_synchronizer_nocut cold_boot_rstack_tcam_inst_1 (
    .clk        (clk_bdg_125_clk),
    .reset_n    (ss_app_cold_rst_ack_n[0]),
    .din        (1'b1),         
    .dout       (ss_app_cold_rst_ack_n_sync[0])
  );
  
always @(posedge clk_bdg_125_clk or negedge iopll_locked_export_125M) 
  if(~iopll_locked_export_125M)
    tcam_cold_rst_n[0] <= 1'b0;
  else if(~ss_app_cold_rst_ack_n_sync[0])
    tcam_cold_rst_n[0] <= 1'b1;
	 
// warm boot reset logic
  eth_f_altera_std_synchronizer_nocut warm_boot_rstack_tcam_inst_1 (
    .clk        (clk_bdg_125_clk),
    .reset_n    (ss_app_warm_rst_ack_n[0]),
    .din        (1'b1),         
    .dout       (ss_app_warm_rst_ack_n_sync[0])
  );

always @(posedge clk_bdg_125_clk or negedge iopll_locked_export_125M) 
  if(~iopll_locked_export_125M)
    tcam_warm_rst_n[0] <= 1'b0;
  else if(~ss_app_warm_rst_ack_n_sync[0])
    tcam_warm_rst_n[0] <= 1'b1;

  
`ifdef NUM_CHANNELS_2 
assign i_reconfig_clk[1] = clk_bdg_125_clk;
assign trafficgen_system_status[1] = {o_rx_pcs_ready_sync[1] ,o_tx_pll_locked_sync[1], o_tx_lanes_stable_sync[1] , system_reset_csr};

 // cold boot reset logic
  eth_f_altera_std_synchronizer_nocut cold_boot_rstack_tcam_inst_2 (
    .clk        (clk_bdg_125_clk),
    .reset_n    (ss_app_cold_rst_ack_n[1]),
    .din        (1'b1),         
    .dout       (ss_app_cold_rst_ack_n_sync[1])
  );
  
	 always @(posedge clk_bdg_125_clk or negedge iopll_locked_export_125M) 
  if(~iopll_locked_export_125M)
    tcam_cold_rst_n[1] <= 1'b0;
  else if(~ss_app_cold_rst_ack_n_sync[1])
    tcam_cold_rst_n[1] <= 1'b1;

	
	 // warm boot reset logic
  eth_f_altera_std_synchronizer_nocut warm_boot_rstack_tcam_inst_2 (
    .clk        (clk_bdg_125_clk),	
    .reset_n    (ss_app_warm_rst_ack_n[1]),
    .din        (1'b1),         
    .dout       (ss_app_warm_rst_ack_n_sync[1])
  );
  

always @(posedge clk_bdg_125_clk or negedge iopll_locked_export_125M) 
  if(~iopll_locked_export_125M)
    tcam_warm_rst_n[1] <= 1'b0;
  else if(~ss_app_warm_rst_ack_n_sync[1])
    tcam_warm_rst_n[1] <= 1'b1;
	
assign dma_axi_st_tx_tvalid_i[3]                = axis_h2d_if[3].tvalid;
assign dma_axi_st_tx_tdata_i[3]                 = axis_h2d_if[3].tdata;
assign dma_axi_st_tx_tkeep_i[3]                 = axis_h2d_if[3].tkeep;
assign dma_axi_st_tx_tlast_i[3]                 = axis_h2d_if[3].tlast;
assign dma_axi_st_tx_tuser_last_segment_i[3][0] = axis_h2d_if[3].tlast;
assign axis_h2d_if[3].tready                    = dma_axi_st_tx_tready_o[3]  ;

assign axis_d2h_if[3].tvalid                  = dma_axi_st_rx_tvalid_o[3];
assign axis_d2h_if[3].tdata                   = dma_axi_st_rx_tdata_o[3]  ;
assign axis_d2h_if[3].tkeep                   = dma_axi_st_rx_tkeep_o[3]  ;
assign axis_d2h_if[3].tlast                   = dma_axi_st_rx_tlast_o[3]  ;
assign dma_axi_st_rx_tready_i[3]              = 1'b1;
assign axis_d2h_if[3].tid                     = 'd0;  	 
 

assign dma_axi_st_tx_tvalid_i[2]                = axis_h2d_if[2].tvalid;
assign dma_axi_st_tx_tdata_i[2]                 = axis_h2d_if[2].tdata;
assign dma_axi_st_tx_tkeep_i[2]                 = axis_h2d_if[2].tkeep;
assign dma_axi_st_tx_tlast_i[2]                 = axis_h2d_if[2].tlast;
assign dma_axi_st_tx_tuser_last_segment_i[2][0] = axis_h2d_if[2].tlast;
assign axis_h2d_if[2].tready                    = dma_axi_st_tx_tready_o[2]  ;

assign axis_d2h_if[2].tvalid                  = dma_axi_st_rx_tvalid_o[2];
assign axis_d2h_if[2].tdata                   = dma_axi_st_rx_tdata_o[2]  ;
assign axis_d2h_if[2].tkeep                   = dma_axi_st_rx_tkeep_o[2]  ;
assign axis_d2h_if[2].tlast                   = dma_axi_st_rx_tlast_o[2]  ;
assign dma_axi_st_rx_tready_i[2]              = 1'b1;
assign axis_d2h_if[2].tid                     = 'd0;  	 
 
 
`endif
 

assign dma_axi_st_tx_tvalid_i[1]                = axis_h2d_if[1].tvalid;
assign dma_axi_st_tx_tdata_i[1]                 = axis_h2d_if[1].tdata;
assign dma_axi_st_tx_tkeep_i[1]                 = axis_h2d_if[1].tkeep;
assign dma_axi_st_tx_tlast_i[1]                 = axis_h2d_if[1].tlast;
assign dma_axi_st_tx_tuser_last_segment_i[1][0] = axis_h2d_if[1].tlast;
assign axis_h2d_if[1].tready                    = dma_axi_st_tx_tready_o[1]  ;

assign axis_d2h_if[1].tvalid                  = dma_axi_st_rx_tvalid_o[1];
assign axis_d2h_if[1].tdata                   = dma_axi_st_rx_tdata_o[1]  ;
assign axis_d2h_if[1].tkeep                   = dma_axi_st_rx_tkeep_o[1]  ;
assign axis_d2h_if[1].tlast                   = dma_axi_st_rx_tlast_o[1]  ;
assign dma_axi_st_rx_tready_i[1]              = 1'b1;
assign axis_d2h_if[1].tid                     = 'd0;  	 
 
assign dma_axi_st_tx_tvalid_i[0]                = axis_h2d_if[0].tvalid;
assign dma_axi_st_tx_tdata_i[0]                 = axis_h2d_if[0].tdata;
assign dma_axi_st_tx_tkeep_i[0]                 = axis_h2d_if[0].tkeep;
assign dma_axi_st_tx_tlast_i[0]                 = axis_h2d_if[0].tlast;
assign dma_axi_st_tx_tuser_last_segment_i[0][0] = axis_h2d_if[0].tlast;
assign axis_h2d_if[0].tready                    = dma_axi_st_tx_tready_o[0];

assign axis_d2h_if[0].tvalid                  = dma_axi_st_rx_tvalid_o[0];
assign axis_d2h_if[0].tdata                   = dma_axi_st_rx_tdata_o[0]  ;
assign axis_d2h_if[0].tkeep                   = dma_axi_st_rx_tkeep_o[0]  ;
assign axis_d2h_if[0].tlast                   = dma_axi_st_rx_tlast_o[0]  ;
assign dma_axi_st_rx_tready_i[0]              = 1'b1;
assign axis_d2h_if[0].tid                     = 'd0;  



// ********************************************************************* //
//                  Packet Switch subsystem
// ********************************************************************* //      
packet_switch_subsys
   #(.HSSI_PORT  (NUM_CHANNELS )   
     ,.USER_PORT  (NUM_CHANNELS )   
     ,.DMA_CHNL   (DMA_CHANNELS )   
    
    ,.DMA_DATA_WIDTH           (DMA_DATA_WIDTH         )       
    ,.USER_DATA_WIDTH          (USER_DATA_WIDTH        )     
    ,.HSSI_DATA_WIDTH          (HSSI_DATA_WIDTH        )     
                              
    ,.DMA_NUM_OF_SEG           (DMA_NUM_OF_SEG         )      
    ,.HSSI_NUM_OF_SEG          (HSSI_NUM_OF_SEG        )      
    ,.USER_NUM_OF_SEG          (USER_NUM_OF_SEG        )   

    ,.HSSI_IGR_FIFO_DEPTH      (PTP_BRDG_HSSI_IGR_FIFO_DEPTH)
    ,.USER_IGR_FIFO_DEPTH      (PTP_BRDG_USER_IGR_FIFO_DEPTH)
    ,.DMA_IGR_FIFO_DEPTH       (PTP_BRDG_DMA_IGR_FIFO_DEPTH )   

    ,.TX_CLIENT_WIDTH          (TX_CLIENT_WIDTH        )
    ,.RX_CLIENT_WIDTH          (RX_CLIENT_WIDTH        )
 
    ,.TXEGR_TS_DW              (TXEGR_TS_DW            )      
    ,.RXIGR_TS_DW              (RXIGR_TS_DW            )      
    ,.SYS_FINGERPRINT_WIDTH    (TS_REQ_FP_WIDTH        )
                               
    ,.PTP_WIDTH                (PTP_WIDTH              )      
    ,.PTP_EXT_WIDTH            (PTP_EXT_WIDTH          )      
    ,.STS_WIDTH                (STS_WIDTH              )      
    ,.STS_EXT_WIDTH            (STS_EXT_WIDTH          )      
                               
    ,.AWADDR_WIDTH             (PTP_BRDG_AWADDR_WIDTH)      
    ,.WDATA_WIDTH              (PTP_BRDG_WDATA_WIDTH )      
                              
    ,.TCAM_KEY_WIDTH           (SM_TCAM_KEY_WIDTH         )      
    ,.TCAM_RESULT_WIDTH        (SM_TCAM_RESULT_WIDTH      )      
    ,.TCAM_ENTRIES             (SM_TCAM_ENTRIES           )      
    ,.TCAM_USERMETADATA_WIDTH  (SM_TCAM_USERMETADATA_WIDTH)      

    // default: IGR HSSI, msgDMA, and User are all little endian
    ,.IGR_DMA_BYTE_ROTATE      (IGR_DMA_BYTE_ROTATE  )    
    ,.IGR_USER_BYTE_ROTATE     (IGR_USER_BYTE_ROTATE )    
    ,.IGR_HSSI_BYTE_ROTATE     (IGR_HSSI_BYTE_ROTATE )    

    // default: EGR HSSI, msgDMA, and User are all little endian
    ,.EGR_DMA_BYTE_ROTATE      (EGR_DMA_BYTE_ROTATE )      
    ,.EGR_USER_BYTE_ROTATE     (EGR_USER_BYTE_ROTATE)      
    ,.EGR_HSSI_BYTE_ROTATE     (EGR_HSSI_BYTE_ROTATE) 
    ,.DBG_CNTR_EN              (DBG_CNTR_EN            )    	 
   ) packet_switch_subsys

  (
    //AXI Streaming Interface     
    // Tx streaming clock
     .tx_clk_i             (o_clk_pll_161m)
    ,.tx_areset_n_i        (eth_user_tx_rst_n)
     // Rx streaming clock & reset                 
    ,.rx_clk_i             (o_clk_pll_161m)
    ,.rx_areset_n_i        (eth_user_rx_rst_n)
                                                   
    // axi_lite csr clock & reset                  
    ,.axi_lite_clk_i   (clk_bdg_125_clk)	  
    ,.axi_lite_rst_n_i (iopll_locked_export_125M) 
    //----------------------------------------------------------------------------------------- 
    // init_done status
    ,.tx_init_done_o        ()
    ,.rx_init_done_o        ()

    //-----------------------------------------------------------------------------------------
    //TCAM Reset Interface
    ,.app_ss_cold_rst_n     (tcam_cold_rst_n)      
    ,.app_ss_warm_rst_n     (tcam_warm_rst_n)       
    ,.app_ss_rst_req        ('0)     
    ,.ss_app_rst_rdy        ()
    ,.ss_app_cold_rst_ack_n (ss_app_cold_rst_ack_n)
    ,.ss_app_warm_rst_ack_n (ss_app_warm_rst_ack_n)

    //-----------------------------------------------------------------------------------------
    // axi_lite: sync to axi_lite_clk

    //-----WRITE ADDRESS CHANNEL-------
    ,.axi_lite_awaddr_i  (axi4lite_packetsw.awaddr )
    ,.axi_lite_awvalid_i (axi4lite_packetsw.awvalid)
    ,.axi_lite_awready_o (axi4lite_packetsw.awready)
    //---------------------------------            
    //-----WRITE DATA CHANNEL----------            
    ,.axi_lite_wdata_i  (axi4lite_packetsw.wdata )
    ,.axi_lite_wvalid_i (axi4lite_packetsw.wvalid)
    ,.axi_lite_wready_o (axi4lite_packetsw.wready)
    ,.axi_lite_wstrb_i  (axi4lite_packetsw.wstrb )
    //---------------------------------            
    //-----WRITE RESPONSE CHANNEL------            
    ,.axi_lite_bresp_o  (axi4lite_packetsw.bresp  )
    ,.axi_lite_bvalid_o (axi4lite_packetsw.bvalid )
    ,.axi_lite_bready_i (axi4lite_packetsw.bready )
    //---------------------------------            
    //-----READ ADDRESS CHANNEL-------             
    ,.axi_lite_araddr_i (axi4lite_packetsw.araddr )
    ,.axi_lite_arvalid_i(axi4lite_packetsw.arvalid)
    ,.axi_lite_arready_o (axi4lite_packetsw.arready)
    //---------------------------------            
    //-----READ DATA CHANNEL----------             
    ,.axi_lite_rresp_o  (axi4lite_packetsw.rresp )
    ,.axi_lite_rdata_o  (axi4lite_packetsw.rdata )
    ,.axi_lite_rvalid_o (axi4lite_packetsw.rvalid)
    ,.axi_lite_rready_i (axi4lite_packetsw.rready)
    //=========================================================================================
    // TX Interface:  
    //-----------------------------------------------------------------------------------------
    // tx ingress interface - Input from DMA
    // inputs
    ,.dma_axi_st_tx_tvalid_i                (dma_axi_st_tx_tvalid_i          )
    ,.dma_axi_st_tx_tdata_i                 (dma_axi_st_tx_tdata_i           )
    ,.dma_axi_st_tx_tkeep_i                 (dma_axi_st_tx_tkeep_i           )
    ,.dma_axi_st_tx_tlast_i                 (dma_axi_st_tx_tlast_i           )
    ,.dma_axi_st_tx_tuser_ptp_i             (dma_axi_st_tx_tuser_ptp_i       )
    ,.dma_axi_st_tx_tuser_ptp_extended_i    (dma_axi_st_tx_tuser_ptp_extended_i)
    ,.dma_axi_st_tx_tuser_client_i          (dma_axi_st_tx_tuser_client_i)
    ,.dma_axi_st_tx_tuser_pkt_seg_parity_i  ('d0 )  
    ,.dma_axi_st_tx_tuser_last_segment_i    (dma_axi_st_tx_tuser_last_segment_i )  

    // output                                                                     
    ,.dma_axi_st_tx_tready_o                (dma_axi_st_tx_tready_o          )
    //-----------------------------------------------------------------------------------------
    // tx ingress interface - Input from USER
    ,.user_axi_st_tx_tvalid_i               (user_axi_st_tx_tvalid_i              )  
    ,.user_axi_st_tx_tdata_i                (user_axi_st_tx_tdata_i               )  
    ,.user_axi_st_tx_tkeep_i                (user_axi_st_tx_tkeep_i               )  
    ,.user_axi_st_tx_tlast_i                (user_axi_st_tx_tlast_i               )  
    ,.user_axi_st_tx_tuser_ptp_i            (user_axi_st_tx_tuser_ptp_i           )  
    ,.user_axi_st_tx_tuser_ptp_extended_i   ('d0 )  
    ,.user_axi_st_tx_tuser_client_i         ('d0 )  
    ,.user_axi_st_tx_tuser_pkt_seg_parity_i (user_axi_st_tx_tuser_pkt_seg_parity_i )  
    ,.user_axi_st_tx_tuser_last_segment_i   (user_axi_st_tx_tuser_last_segment_i  )  
    ,.user_axi_st_tx_tready_o               (user_axi_st_tx_tready_o              )                

    //-----------------------------------------------------------------------------------------
    // tx egress interface - Outputs to HSSI
    // outputs
    ,.hssi_axi_st_tx_tvalid_o               (hssi_ss_st_tx_tvalid                 )
    ,.hssi_axi_st_tx_tdata_o                (hssi_ss_st_tx_tdata                  )
    ,.hssi_axi_st_tx_tkeep_o                (hssi_ss_st_tx_tkeep                  )
    ,.hssi_axi_st_tx_tlast_o                (hssi_ss_st_tx_tlast                  )
    ,.hssi_axi_st_tx_tuser_ptp_o            (hssi_ss_st_tx_tuser_ptp              )
    ,.hssi_axi_st_tx_tuser_ptp_extended_o   (hssi_ss_st_tx_tuser_ptp_extended     )
    ,.hssi_axi_st_tx_tuser_client_o         (hssi_ss_st_tx_tuser_client           )
    ,.hssi_axi_st_tx_tuser_pkt_seg_parity_o (hssi_ss_st_tx_tuser_pkt_seg_parity    )  
    ,.hssi_axi_st_tx_tuser_last_segment_o   (hssi_ss_st_tx_tuser_last_segment     )

    // input                                                                      
    ,.hssi_axi_st_tx_tready_i               (hssi_ss_st_tx_tready                 )

    //=========================================================================================
    // RX Interface
    //-----------------------------------------------------------------------------------------
    // rx ingress interface -  Inputs from HSSI
    // inputs
    ,.hssi_axi_st_rx_tvalid_i               (hssi_ss_st_rx_tvalid                 )
    ,.hssi_axi_st_rx_tdata_i                (hssi_ss_st_rx_tdata                  )
    ,.hssi_axi_st_rx_tkeep_i                (hssi_ss_st_rx_tkeep                  )
    ,.hssi_axi_st_rx_tlast_i                (hssi_ss_st_rx_tlast                  )
    //Rx Packet Error Status                                                      
    ,.hssi_axi_st_rx_tuser_client_i         ('d0 )
    //Rx Packet Status                                                            
    ,.hssi_axi_st_rx_tuser_sts_i            ('d0 )
    ,.hssi_axi_st_rx_tuser_sts_extended_i   ('d0 ) 
    ,.hssi_axi_st_rx_tuser_pkt_seg_parity_i ('d0 ) 
    ,.hssi_axi_st_rx_tuser_last_segment_i   ('d0 )

    // outputs                                                                    
    ,.hssi_axi_st_rx_tready_o               (                                     )  
    ,.hssi_axi_st_rx_pause_o                (                                     )

    //-----------------------------------------------------------------------------------------
    // rx egress interface - Output to DMA
    // outputs
    ,.dma_axi_st_rx_tvalid_o                (dma_axi_st_rx_tvalid_o          )
    ,.dma_axi_st_rx_tdata_o                 (dma_axi_st_rx_tdata_o           )
    ,.dma_axi_st_rx_tkeep_o                 (dma_axi_st_rx_tkeep_o           )
    ,.dma_axi_st_rx_tlast_o                 (dma_axi_st_rx_tlast_o           )
    //Rx Packet Error Status                                                    
    ,.dma_axi_st_rx_tuser_client_o          (                                    )
    //Rx Packet Status                                                          
    ,.dma_axi_st_rx_tuser_sts_o             (                                    )
    ,.dma_axi_st_rx_tuser_sts_extended_o    (                                    )
    ,.dma_axi_st_rx_tuser_pkt_seg_parity_o  (                                    )
    ,.dma_axi_st_rx_tuser_last_segment_o    (                                    )

    // input                                                                    
    ,.dma_axi_st_rx_tready_i                (dma_axi_st_rx_tready_i      ) 
    //-----------------------------------------------------------------------------------------
    // rx egress interface - Output to USER
    ,.user_axi_st_rx_tvalid_o               (user_axi_st_rx_tvalid_o             )   
    ,.user_axi_st_rx_tdata_o                (user_axi_st_rx_tdata_o              )  
    ,.user_axi_st_rx_tkeep_o                (user_axi_st_rx_tkeep_o              )   
    ,.user_axi_st_rx_tlast_o                (user_axi_st_rx_tlast_o              )   
    //Rx Packet Error Status                                                     
    ,.user_axi_st_rx_tuser_client_o         (user_axi_st_rx_tuser_client_o       )  
    //Rx Packet Status                                                           
    ,.user_axi_st_rx_tuser_sts_o            (                                    ) 
    ,.user_axi_st_rx_tuser_sts_extended_o   (                                    ) 
    ,.user_axi_st_rx_tuser_pkt_seg_parity_o (                                    ) 
    ,.user_axi_st_rx_tuser_last_segment_o   (                                    ) 

    ,.user_axi_st_rx_tready_i               (user_axi_st_rx_tready_i             )  

    //=========================================================================================
    // Time Stamp Interface:
    //-----------------------------------------------------------------------------------------
    // tx egress timestamp from HSSI
    //inputs
    ,.hssi_axi_st_txegrts0_tvalid_i         (hssi_ptp_tx_egrts_tvalid)
    ,.hssi_axi_st_txegrts0_tdata_i          (hssi_ptp_tx_egrts_tdata)
    ,.hssi_axi_st_txegrts1_tvalid_i         ('d0)
    ,.hssi_axi_st_txegrts1_tdata_i          ('d0)

    // tx egress timestamp to DMA                                        
    ,.dma_axi_st_txegrts0_tvalid_o          (dma_axi_st_txegrts_tvalid_o         )
    ,.dma_axi_st_txegrts0_tdata_o           (dma_axi_st_txegrts_tdata_o          )
    ,.dma_axi_st_txegrts1_tvalid_o          (                                    )
    ,.dma_axi_st_txegrts1_tdata_o           (                                    )

     // tx egress timestamp to USER                               
    ,.user_axi_st_txegrts0_tvalid_o         (                                    ) 
    ,.user_axi_st_txegrts0_tdata_o          (                                    ) 
    ,.user_axi_st_txegrts1_tvalid_o         (                                    ) 
    ,.user_axi_st_txegrts1_tdata_o          (                                    ) 

    //-----------------------------------------------------------------------------------------
    // rx ingress timestamp from HSSI
    // inputs  
    ,.hssi_axi_st_rxigrts0_tvalid_i        (hssi_ptp_rx_ingrts_tvalid)
    ,.hssi_axi_st_rxigrts0_tdata_i         (hssi_ptp_rx_ingrts_tdata)
    ,.hssi_axi_st_rxigrts1_tvalid_i        ('d0)
    ,.hssi_axi_st_rxigrts1_tdata_i         ('d0)

    // rx ingress timestamp to DMA  
    // outputs                                                              
    ,.dma_axi_st_rxigrts0_tvalid_o         (dma_axi_st_rxigrts_tvalid           )
    ,.dma_axi_st_rxigrts0_tdata_o          (dma_axi_st_rxigrts_tdata            )
    ,.dma_axi_st_rxigrts1_tvalid_o         (                                     )
    ,.dma_axi_st_rxigrts1_tdata_o          (                                     )

    // rx ingress timestamp to USER                               
    ,.user_axi_st_rxigrts0_tvalid_o        (                                     ) 
    ,.user_axi_st_rxigrts0_tdata_o         (                                     ) 
    ,.user_axi_st_rxigrts1_tvalid_o        (                                     ) 
    ,.user_axi_st_rxigrts1_tdata_o         (                                     )                                      
   );

// ********************************************************************* //
//                        QSFP Controller
// ********************************************************************* //
qsfp_top #(
    .ADDR_WIDTH(ADDR_WIDTH),                     
    .DATA_WIDTH(DATA_WIDTH),
	 .NUM_QSFP(NUM_QSFP),
    .A0_PAGE_END_ADDR (A0_PAGE_END_ADDR),
    .NUM_PG_SUPPORT (NUM_PG_SUPPORT)
	)qsfp_top_inst(
		.clk					           (clk_bdg_125_clk),
		.reset				           (~iopll_locked_export_125M),  
		.modprsn				           (qsfpa_modprsln),             
		.int_qsfp			           (~intn_qsfp),                 
	   .i2c_0_i2c_serial_sda_in     (qsfp_i2c_sda_in),
		.i2c_0_i2c_serial_scl_in     (qsfp_i2c_scl_in),
		.i2c_0_i2c_serial_sda_oe     (qsfp_i2c_sda_oe),  
		.i2c_0_i2c_serial_scl_oe     (qsfp_i2c_scl_oe),
		.modsel  			           (qsfpa_modesel),     
		.lpmode				           (qsfpa_lpmode),
		.softresetqsfpm	           (qsfpa_reset),       // Drive inverted value of config_softresetqsfpm to actual qsfp module
	   .stp_clk                     (),
      .axi_bdg_s0_awid             (qsfp_cntlr_axi_bdg_m0_awid),             
		.axi_bdg_s0_awaddr           (qsfp_cntlr_axi_bdg_m0_awaddr),           
		.axi_bdg_s0_awlen            (qsfp_cntlr_axi_bdg_m0_awlen),            
		.axi_bdg_s0_awsize           (qsfp_cntlr_axi_bdg_m0_awsize),           
		.axi_bdg_s0_awburst          (qsfp_cntlr_axi_bdg_m0_awburst),          
		.axi_bdg_s0_awlock           (qsfp_cntlr_axi_bdg_m0_awlock),           
		.axi_bdg_s0_awcache          (qsfp_cntlr_axi_bdg_m0_awcache),          
		.axi_bdg_s0_awprot           (qsfp_cntlr_axi_bdg_m0_awprot),           
		.axi_bdg_s0_awvalid          (qsfp_cntlr_axi_bdg_m0_awvalid),          
		.axi_bdg_s0_awready          (qsfp_cntlr_axi_bdg_m0_awready),          
		.axi_bdg_s0_wdata            (qsfp_cntlr_axi_bdg_m0_wdata),           
		.axi_bdg_s0_wstrb            (qsfp_cntlr_axi_bdg_m0_wstrb),           
		.axi_bdg_s0_wlast            (qsfp_cntlr_axi_bdg_m0_wlast),           
		.axi_bdg_s0_wvalid           (qsfp_cntlr_axi_bdg_m0_wvalid),          
		.axi_bdg_s0_wready           (qsfp_cntlr_axi_bdg_m0_wready),          
		.axi_bdg_s0_bid              (qsfp_cntlr_axi_bdg_m0_bid),             
		.axi_bdg_s0_bresp            (qsfp_cntlr_axi_bdg_m0_bresp),           
		.axi_bdg_s0_bvalid           (qsfp_cntlr_axi_bdg_m0_bvalid),          
		.axi_bdg_s0_bready           (qsfp_cntlr_axi_bdg_m0_bready),          
		.axi_bdg_s0_arid             (qsfp_cntlr_axi_bdg_m0_arid),            
		.axi_bdg_s0_araddr           (qsfp_cntlr_axi_bdg_m0_araddr),          
		.axi_bdg_s0_arlen            (qsfp_cntlr_axi_bdg_m0_arlen),           
		.axi_bdg_s0_arsize           (qsfp_cntlr_axi_bdg_m0_arsize),          
		.axi_bdg_s0_arburst          (qsfp_cntlr_axi_bdg_m0_arburst),         
		.axi_bdg_s0_arlock           (qsfp_cntlr_axi_bdg_m0_arlock),           
		.axi_bdg_s0_arcache          (qsfp_cntlr_axi_bdg_m0_arcache),          
		.axi_bdg_s0_arprot           (qsfp_cntlr_axi_bdg_m0_arprot),           
		.axi_bdg_s0_arvalid          (qsfp_cntlr_axi_bdg_m0_arvalid),          
		.axi_bdg_s0_arready          (qsfp_cntlr_axi_bdg_m0_arready),          
		.axi_bdg_s0_rid              (qsfp_cntlr_axi_bdg_m0_rid),              
		.axi_bdg_s0_rdata            (qsfp_cntlr_axi_bdg_m0_rdata),            
		.axi_bdg_s0_rresp            (qsfp_cntlr_axi_bdg_m0_rresp),            
		.axi_bdg_s0_rlast            (qsfp_cntlr_axi_bdg_m0_rlast),            
		.axi_bdg_s0_rvalid           (qsfp_cntlr_axi_bdg_m0_rvalid),           
		.axi_bdg_s0_rready           (qsfp_cntlr_axi_bdg_m0_rready)
	);
	

	
endmodule


