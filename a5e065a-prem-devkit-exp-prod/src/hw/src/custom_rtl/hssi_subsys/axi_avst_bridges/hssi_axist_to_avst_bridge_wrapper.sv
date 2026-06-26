//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


// ==========================================================================
// Project           : HSSI Subsystem 
// Module            : hssi_axist_to_avst_bridge_wrapper.sv
// Description       : 
// Author            : 
// Created           : 
// Changes           : 
//                   : 
// ==========================================================================

// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

module hssi_axist_to_avst_bridge_wrapper #(
    parameter NUM_CHANNELS                  = 1,
    parameter TILES                         = "F",
    parameter PORT_PROFILE                  = "25GbE",  
    parameter NUM_MAX_PORTS                 = 1,  
    parameter PKT_CYL                       = 1,  
    parameter PORT_CLIENT_IF                = 1,   //0 for MAC_SEGMENTED and 1 for sopaligned
    parameter PREAMBLE_PASS_TH_EN           = 0,   // 40/50G rates AVST SOP Algined case optional
    parameter DR_ENABLE                     = 0,   // 40/50G rates AVST SOP Algined case optional
    //AXI Side
    parameter TDATA_WIDTH                   = 64,   
    parameter NO_OF_BYTES                   = (PORT_CLIENT_IF == 1) ? TDATA_WIDTH/8 : 8, 
    parameter NUM_SEG                       = (PORT_CLIENT_IF == 1)? 1:(TDATA_WIDTH/64),
    parameter TX_TUSER_CLIENT_WIDTH         = (PORT_CLIENT_IF == 1)? (NUM_MAX_PORTS*2*NUM_SEG) : 2*NUM_SEG, //TBD
    parameter RX_TUSER_CLIENT_WIDTH         = (PORT_CLIENT_IF == 1)? (NUM_MAX_PORTS*7*NUM_SEG) : 7*NUM_SEG, //TBD
    parameter RX_TUSER_STATS_WIDTH          = (PORT_CLIENT_IF == 1)? (NUM_MAX_PORTS*5*NUM_SEG) : 5*NUM_SEG, //TBD
//    parameter ENABLE_MULTI_STREAM           = 0,  
    parameter NUM_OF_STREAM                 = 1,  
    parameter TID                           = 1,
    parameter PKT_SEG_PARITY_EN             = 0,  
    parameter PKT_SEG_PARITY_WIDTH          = (PORT_CLIENT_IF == 1)? NUM_MAX_PORTS: NUM_SEG,  //macseg - [NUM_SEG-1:0], sopa - [(NUM_MAX_PORTS-1:0] 
    parameter ST_READY_LATENCY              = 0,  
    //AVST Side
    parameter DATA_WIDTH                    = 64, 
    parameter EMPTY_BITS                    = (PORT_CLIENT_IF == 0)? 3: ((DR_ENABLE)? ((PORT_PROFILE == "25GbE")? 3: (PORT_PROFILE == "50GAUI-1")? 6: 12):
                                                                                       ((PORT_PROFILE == "25GbE" || PORT_PROFILE == "10GbE")? 3: 
                                                                                       (PORT_PROFILE == "50GAUI-1" || PORT_PROFILE == "40GCAUI-4" || PORT_PROFILE == "50GAUI-2")? 4: 6)),
    parameter ENABLE_ECC                    = 0,  
    parameter ERR                           = 2, 
    parameter FCS_ERR                       = 1, 
    parameter MAC_STS                       = 3,
    parameter AXIST_ERR                     = 2,
    parameter TEMPTY_BITS                   = PREAMBLE_PASS_TH_EN ? 5 : EMPTY_BITS, 
    
    parameter ASYNC_ADAPTERS_EN             = 0,    
    //
    parameter USE_M20K                      = "OFF",
    parameter SIM_EMULATE                   = 0
) (
    input                                                       i_tx_clk_p0, 
    input                                                       i_tx_clk_p1, 
    input                                                       i_tx_clk_p2, 
    input                                                       i_tx_clk_p3, 
    
    input                                                       i_tx_rst_n_p0,
    input                                                       i_tx_rst_n_p1,
    input                                                       i_tx_rst_n_p2,
    input                                                       i_tx_rst_n_p3,
    
    input                                                       i_rx_clk_p0, 
    input                                                       i_rx_clk_p1, 
    input                                                       i_rx_clk_p2, 
    input                                                       i_rx_clk_p3, 
    
    input                                                       i_rx_rst_n_p0,
    input                                                       i_rx_rst_n_p1,
    input                                                       i_rx_rst_n_p2,
    input                                                       i_rx_rst_n_p3,
    //DR CSR                                                    
    input       [5:0]                                           i_profile_sel_reg,    
    output      [2:0]                                           o_active_port,
    output      [NUM_MAX_PORTS-1:0]                             o_port_active_mask_reg,
    output reg  [5:0]                                           o_speed_sel,
    output reg  [2:0]                                           o_data_width,   
    /////////// TX ports ////////////////////                                                                                  
    //AXI Stream Tx, from User interface                       
    //SINGLE PACKET IF                                      
    output reg  [NUM_MAX_PORTS-1:0]                             o_axi_st_tx_tready,
    input       [NUM_MAX_PORTS-1:0]                             i_axi_st_tx_tvalid,
    input       [TDATA_WIDTH-1:0]                               i_axi_st_tx_tdata,
    input       [NUM_MAX_PORTS-1:0]                             i_axi_st_tx_tlast,
    input       [NO_OF_BYTES-1:0]                               i_axi_st_tx_tkeep,
    //ptp signa l    
    // input  [NUM_OF_STREAM*NUM_SEG*AXIST_ERR-1:0]i_axi_st_tx_tuser_client,
    input       [TX_TUSER_CLIENT_WIDTH-1:0]                     i_axi_st_tx_tuser_client,
    input       [(NUM_MAX_PORTS*94)-1:0]                        i_axi_st_tx_tuser_ptp,  
    input       [(NUM_MAX_PORTS*328)-1:0]                       i_axi_st_tx_tuser_ptp_extended,
    //MULTI PACKET IF               
    input       [NUM_SEG-1:0]                                   i_axi_st_tx_tlast_segment,
    input       [NUM_SEG*8-1:0]                                 i_axi_st_tx_tkeep_segment,
                
    input       [PKT_SEG_PARITY_WIDTH-1:0]                      i_axi_st_tx_pkt_seg_parity,
    input       [TID-1:0]                                       i_axi_st_tx_tid,
    output reg  [TID-1:0]                                       o_axi_st_rx_tid,
    
    //Avalon Stream Tx, to MAC interface        
    //SOP Aligned IF            
    input       [NUM_MAX_PORTS-1:0]                             i_tx_avst_ready,
    output reg  [DATA_WIDTH-1:0]                                o_tx_avst_data,
    output reg  [NUM_MAX_PORTS-1:0]                             o_tx_avst_valid,
    output reg  [NUM_MAX_PORTS-1:0]                             o_tx_avst_startofpacket,
    output reg  [NUM_MAX_PORTS-1:0]                             o_tx_avst_endofpacket,

    output reg  [EMPTY_BITS-1:0]                                o_tx_avst_empty,
    output reg  [64-1:0]                                        o_tx_avst_preamble, //TBD
    output reg  [NUM_MAX_PORTS-1:0]                             o_tx_avst_error,
    output reg  [NUM_MAX_PORTS-1:0]                             o_tx_avst_skip_crc, 
    //MAC_SEGMENTED IF      
    input       [NUM_MAX_PORTS-1:0]                             i_tx_mac_ready,
    output reg  [TDATA_WIDTH-1:0]                               o_tx_mac_data,
    output reg  [NUM_MAX_PORTS-1:0]                             o_tx_mac_valid,
    output reg  [NUM_SEG-1:0]                                   o_tx_mac_inframe,
    output reg  [NUM_SEG*TEMPTY_BITS-1:0]                       o_tx_mac_eop_empty,
    output reg  [NUM_SEG-1:0]                                   o_tx_mac_error,
    output reg  [NUM_SEG-1:0]                                   o_tx_mac_skip_crc,  
    output reg  [(NUM_MAX_PORTS*2)-1:0]                         o_tx_fifo_eccstatus,      //TBD
    output      [NUM_MAX_PORTS-1:0]                             o_axi_st_tx_parity_error, //TBD 
    //ptp//
                                                     
    output reg   [NUM_MAX_PORTS-1:0][PKT_CYL*1-1:0]             o_av_st_tx_ptp_ts_format, 
    output reg   [NUM_MAX_PORTS-1:0][PKT_CYL*16-1:0]            o_av_st_tx_ptp_eb_offset, 
    output reg   [NUM_MAX_PORTS-1:0][2-1:0]                     o_av_st_tx_ptp_ts_valid,
                 
    output logic [NUM_MAX_PORTS-1:0][PKT_CYL*1-1:0]             o_av_st_tx_ptp_ins_ets,
    output logic [NUM_MAX_PORTS-1:0][PKT_CYL*1-1:0]             o_av_st_tx_ptp_ins_cf,
    output logic [NUM_MAX_PORTS-1:0][PKT_CYL*1-1:0]             o_av_st_tx_ptp_zero_csum,
    output logic [NUM_MAX_PORTS-1:0][PKT_CYL*1-1:0]             o_av_st_tx_ptp_update_eb,
    output logic [NUM_MAX_PORTS-1:0][PKT_CYL*16-1:0]            o_av_st_tx_ptp_ts_offset,
    output logic [NUM_MAX_PORTS-1:0][PKT_CYL*16-1:0]            o_av_st_tx_ptp_cf_offset,
    output logic [NUM_MAX_PORTS-1:0][PKT_CYL*16-1:0]            o_av_st_tx_ptp_csum_offset,
    output logic [NUM_MAX_PORTS-1:0][PKT_CYL*1-1:0]             o_av_st_tx_ptp_p2p,
    output logic [NUM_MAX_PORTS-1:0][PKT_CYL*1-1:0]             o_av_st_tx_ptp_asym,
    output logic [NUM_MAX_PORTS-1:0][PKT_CYL*1-1:0]             o_av_st_tx_ptp_asym_sign,
    output logic [NUM_MAX_PORTS-1:0][PKT_CYL*7-1:0]             o_av_st_tx_ptp_asym_p2p_idx,
    output logic [NUM_MAX_PORTS-1:0][PKT_CYL*1-1:0]             o_av_st_tx_ptp_ts_req,
    output logic [NUM_MAX_PORTS-1:0][PKT_CYL*32-1:0]            o_av_st_tx_ptp_fp,
    output logic [NUM_MAX_PORTS-1:0][PKT_CYL*96 -1:0]           o_av_st_tx_ptp_tx_its,
    
    /////////// RX ports ////////////////////       
    //Avalon Stream Rx, from MAC interface      
    //SOP Aligned IF
    input        [DATA_WIDTH-1:0]                               i_rx_avst_data,
    input        [NUM_MAX_PORTS-1:0]                            i_rx_avst_valid,
    input        [NUM_MAX_PORTS-1:0]                            i_rx_avst_startofpacket,
    input        [NUM_MAX_PORTS-1:0]                            i_rx_avst_endofpacket,
    input        [EMPTY_BITS-1:0]                               i_rx_avst_empty,
    input        [NUM_MAX_PORTS*6-1:0]                          i_rx_avst_error,
    input        [NUM_MAX_PORTS*40-1:0]                         i_rxstatus_avst_data, //TBD
    input        [NUM_MAX_PORTS-1:0]                            i_rxstatus_avst_valid,//TBD
    // input        [192-1:0] [NUM_MAX_PORTS-1:0]                  i_rx_avst_ptp_rx_its,
    input        [(NUM_MAX_PORTS*192)-1:0]                      i_rx_avst_ptp_rx_its,
    input        [NUM_MAX_PORTS-1:0][64-1:0]                    i_rx_avst_preamble,
    //MAC_SEGMENTED IF      
    input        [TDATA_WIDTH-1:0]                              i_rx_mac_data, 
    input        [NUM_MAX_PORTS-1:0]                            i_rx_mac_valid,
    input        [NUM_SEG-1:0]                                  i_rx_mac_inframe,
    input        [NUM_SEG-1:0][EMPTY_BITS-1:0]                  i_rx_mac_eop_empty,
    input        [NUM_SEG*ERR-1:0]                              i_rx_mac_error,         // max width for all sub ports in dr
    input        [NUM_SEG*FCS_ERR-1:0]                          i_rx_mac_fcs_error,
    input        [NUM_SEG*MAC_STS-1:0]                          i_rx_mac_status,
        
    //AXI Stream Rx, to User interface              
    output reg                                                  o_axi_st_rx_tready,  //TBD no driver
    output reg   [NUM_MAX_PORTS-1:0]                            o_axi_st_rx_tvalid,
    output reg   [TDATA_WIDTH-1:0]                              o_axi_st_rx_tdata,
    output reg   [NUM_MAX_PORTS-1:0]                            o_axi_st_rx_tlast,
    output reg   [NO_OF_BYTES-1:0]                              o_axi_st_rx_tkeep,
    
    //assuming user signal will be per/segment 
    output reg   [7-1:0]                    o_axi_st_rx_tuser_client,  //7*NUM_SEG - MAC SEG, 7*NUM_MAX_PORTS = SOPA 
    output reg   [RX_TUSER_STATS_WIDTH-1:0]                     o_axi_st_rx_tuser_sts,     //5*NUM_SEG - MAC SEG, 5*NUM_MAX_PORTS = SOPA 
    output reg   [32-1:0]                                       o_axi_st_rx_tuser_sts_extended,
    output reg   [(NUM_MAX_PORTS*96)-1:0]                       o_axi_st_rx_ingrts0_tdata,
    output reg   [(NUM_MAX_PORTS*96)-1:0]                       o_axi_st_rx_ingrts1_tdata,
    output reg   [NUM_MAX_PORTS-1:0]                            o_axi_st_rx_ingrts0_tvalid, 
    output reg   [NUM_MAX_PORTS-1:0]                            o_axi_st_rx_ingrts1_tvalid, 
    // output reg [RX_TUSER_CLIENT_WIDTH-1:0]                   o_axi_st_rx_tuser_client,
    // output reg [RX_TUSER_STATS_WIDTH-1:0]                    o_axi_st_rx_tuser_sts,
    // output reg [32-1:0]                                      o_axi_st_rx_tuser_sts_extended,
    // output reg [96-1:0]                                      o_axi_st_rx_ingrts0_tdata,
    // output reg [1-1:0]                                       o_axi_st_rx_ingrts0_tvalid, 
    //MULTI PACKET COMPATIBLE SIGNALS       
    output reg   [NUM_SEG-1:0]                                  o_axi_st_rx_tlast_segment,
    output reg   [NUM_SEG*8-1:0]                                o_axi_st_rx_tkeep_segment,
    output reg   [PKT_SEG_PARITY_WIDTH-1:0]                     o_axi_st_rx_pkt_seg_parity
);

//***********************************************************
//*********************************************************** 
localparam PTP_WIDTH                 = (TILES == "F") ? 'd94 :'d46;
localparam PTP_EXT_WIDTH             = (TILES == "F") ? 'd328 : 'd164;
// localparam TUSER_WIDTH_TX         =  NUM_SEG*AXIST_ERR + PTP_WIDTH + PTP_EXT_WIDTH;
// localparam TUSER_WIDTH_TX_MLST       =  NUM_OF_STREAM*(TX_TUSER_CLIENT_WIDTH + PTP_WIDTH + PTP_EXT_WIDTH);
// localparam TUSER_WIDTH_TX            =  (TX_TUSER_CLIENT_WIDTH + PTP_WIDTH + PTP_EXT_WIDTH);
// localparam AVST_USER_TX              =  TUSER_WIDTH_TX;
                                    
localparam TX_TUSER_MAX_PORTS        = (PORT_CLIENT_IF == 1)? TX_TUSER_CLIENT_WIDTH: (NUM_MAX_PORTS*TX_TUSER_CLIENT_WIDTH); // TX_TUSER_CLIENT_WIDTH = maxports*2 (sopa from tcl), = 2*numseg (macseg from tcl)
localparam TX_TUSER_CLIENT_PER_PORT  = 2*NUM_SEG;
localparam TX_TUSER_WIDTH            = (TX_TUSER_CLIENT_PER_PORT + PTP_WIDTH + PTP_EXT_WIDTH); 
localparam AVST_USER_TX              =  TX_TUSER_WIDTH;
                                     
// localparam AVST_MAC_USER_RX       =  NUM_SEG*ERR + NUM_SEG*FCS_ERR + NUM_SEG*MAC_STS;
localparam AVST_MAC_USER_RX          =  NUM_SEG*ERR + NUM_SEG*FCS_ERR + NUM_SEG*MAC_STS + 96 + 96;  //192+1+2+3 = 198 for num seg =1       
localparam AVST_USER_RX              =  (PORT_CLIENT_IF == 0) ? AVST_MAC_USER_RX : 'd143; //96+6+1+40
localparam TUSER_WIDTH_RX            =  AVST_USER_RX;
localparam ACTIVE_PORT               = 1'b1;
localparam INACTIVE_PORT             = 1'b0;
                                     
localparam NUM_SEG_ERR_BITS          = ERR*NUM_SEG;
localparam NUM_SEG2_ERR_BITS         =(NUM_SEG/2)*ERR;
localparam NUM_SEG4_ERR_BITS         =(NUM_SEG/4)*ERR;
localparam NUM_SEG_ERR_BITS_1        =(NUM_SEG/2)*ERR+(NUM_SEG/4)*ERR;
                                     
localparam NUM_SEG_FCS_ERR_BITS      = FCS_ERR*NUM_SEG;
localparam NUM_SEG2_FCS_ERR_BITS     =(NUM_SEG/2)*FCS_ERR;
localparam NUM_SEG4_FCS_ERR_BITS     =(NUM_SEG/4)*FCS_ERR;
localparam NUM_SEG_FCS_ERR_BITS_1    =(NUM_SEG/2)*FCS_ERR+(NUM_SEG/4)*FCS_ERR;
                                     
localparam NUM_SEG_MAC_STS_BITS      = MAC_STS*NUM_SEG;
localparam NUM_SEG2_MAC_STS_BITS     =(NUM_SEG/2)*MAC_STS;
localparam NUM_SEG4_MAC_STS_BITS     =(NUM_SEG/4)*MAC_STS;
localparam NUM_SEG_MAC_STS_BITS_1    =(NUM_SEG/2)*MAC_STS+(NUM_SEG/4)*MAC_STS;

localparam NUMSEG_1                  = 3*NUM_SEG/2;
localparam NUMSEG_BY_TWO             = NUM_SEG/2;

localparam AVST_DW_BY_TWO            = TDATA_WIDTH/2    ;
localparam AVST_DW_BY_FOUR           = TDATA_WIDTH/4    ;
localparam AVST_DW_BY_FOURX3         = 3*(TDATA_WIDTH/4);
localparam AVST_DW_BY_EIGHT          = TDATA_WIDTH/8    ;
localparam AVST_DW_BY_EIGHTX3        = 3*(TDATA_WIDTH/8);
                                     
localparam NO_BYTES_BY_TWO           = NO_OF_BYTES/2    ;
localparam NO_BYTES_BY_FOUR          = NO_OF_BYTES/4    ;
localparam NO_BYTES_BY_FOURX3        = 3*(NO_OF_BYTES/4);
localparam NO_BYTES_BY_EIGHT         = NO_OF_BYTES/8    ;
localparam NO_BYTES_BY_EIGHTX3       = 3*(NO_OF_BYTES/8);

localparam AVST_DW_P1  = (NUM_MAX_PORTS == 4)? AVST_DW_BY_EIGHT : AVST_DW_BY_FOUR;
localparam NO_BYTES_P1 = (NUM_MAX_PORTS == 4)? NO_BYTES_BY_EIGHT : NO_BYTES_BY_FOUR;

//PREAMBLE PASSTHROUGH EMPTY_BITS logic needed
//localparam TEMPTY_BITS   =  PREAMBLE_PASS_TH_EN ? 5 : EMPTY_BITS;

//Bridge output
wire    [TDATA_WIDTH-1:0]                              avst_tx_data;     
wire    [NUM_MAX_PORTS-1:0]                            avst_tx_valid;   
wire    [NUM_MAX_PORTS-1:0]                            avst_tx_startofpacket;   
wire    [NUM_MAX_PORTS-1:0]                            avst_tx_endofpacket;        
wire    [TEMPTY_BITS-1:0]                              avst_tx_empty;
wire    [NUM_MAX_PORTS*TX_TUSER_WIDTH-1:0]             avst_tx_user;
                                                       
//PPT Tx output                                        
wire    [DATA_WIDTH-1:0]                               ppt_avst_tx_data;     
wire    [NUM_MAX_PORTS-1:0]                            ppt_avst_tx_valid;   
wire    [NUM_MAX_PORTS-1:0]                            ppt_avst_tx_startofpacket;   
wire    [NUM_MAX_PORTS-1:0]                            ppt_avst_tx_endofpacket;
wire    [EMPTY_BITS-1:0]                               ppt_avst_tx_empty;
wire    [NUM_MAX_PORTS*TX_TUSER_WIDTH-1:0]             ppt_avst_tx_user;
wire    [63:0]                                         ppt_avst_tx_preamble;
                                                       
wire    [NUM_MAX_PORTS-1:0]                            axist_tx_tready;   
                                                       
//Bridge input                                         
wire    [TDATA_WIDTH-1:0]                              avst_rx_data;     
wire    [NUM_MAX_PORTS-1:0]                            avst_rx_valid;   
wire    [NUM_MAX_PORTS-1:0]                            avst_rx_startofpacket;   
wire    [NUM_MAX_PORTS-1:0]                            avst_rx_endofpacket;   
wire    [TEMPTY_BITS-1:0]                              avst_rx_empty;
wire    [(NUM_MAX_PORTS*AVST_USER_RX)-1:0]             avst_rx_user;
                                                       
//PPT Rx output                                        
wire    [TDATA_WIDTH-1:0]                              ppt_avst_rx_data;     
wire    [NUM_MAX_PORTS-1:0]                            ppt_avst_rx_valid;   
wire    [NUM_MAX_PORTS-1:0]                            ppt_avst_rx_startofpacket;   
wire    [NUM_MAX_PORTS-1:0]                            ppt_avst_rx_endofpacket;   
wire    [TEMPTY_BITS-1:0]                              ppt_avst_rx_empty;
wire    [(NUM_MAX_PORTS*AVST_USER_RX)-1:0]             ppt_avst_rx_user;
                                                                                                            
wire    [NUM_MAX_PORTS-1:0]                            avst_tx_mac_ready;
wire    [TDATA_WIDTH-1:0]                              avst_tx_mac_data;     
wire    [NUM_MAX_PORTS-1:0]                            avst_tx_mac_valid;      
wire    [NUM_SEG-1:0]                                  avst_tx_mac_inframe;  
//wire  [NUM_SEG*EMPTY_BITS-1:0]                       avst_tx_mac_eop_empty;
wire    [NUM_SEG*TEMPTY_BITS-1:0]                      avst_tx_mac_eop_empty; //in PPT case it should be 5 otherwise EMPTY_BITS
                                                       
wire    [NUM_MAX_PORTS-1:0]                            axist_rx_tvalid;
wire    [NUM_MAX_PORTS-1:0]                            axist_rx_tready;
wire    [TDATA_WIDTH-1:0]                              axist_rx_tdata;       
wire    [NUM_MAX_PORTS-1:0]                            axist_rx_tlast;        
wire    [NO_OF_BYTES-1:0]                              axist_rx_tkeep;   
wire    [NUM_SEG-1:0]                                  axist_rx_tlast_segment;
wire    [NUM_SEG*8-1:0]                                axist_rx_tkeep_segment;
                                                       
wire    [PKT_SEG_PARITY_WIDTH-1:0]                     axist_rx_pkt_seg_parity;
// wire    [NUM_SEG-1:0]                               axist_rx_pkt_seg_parity;
// wire    [4:0]                                          axist_rx_tuser_sts;    //TBD
// wire    [63:0]                                         axist_rx_preamble;     //TBD

// wire    [TUSER_WIDTH_TX-1:0]                           axi_st_tx_mltstrm_tuser;
wire    [(NUM_MAX_PORTS*TX_TUSER_WIDTH)-1:0]           axi_st_tx_tuser;
// wire    [TUSER_WIDTH_TX-1:0]                           avst_tx_mac_user;
wire    [(NUM_MAX_PORTS*TX_TUSER_WIDTH)-1:0]           tx_avst_user;
wire    [64-1:0]                                       avst_tx_preamble;
// wire  [NUM_SEG*AXIST_ERR-1:0]                       tx_tuser_client;
wire    [(NUM_MAX_PORTS*TX_TUSER_CLIENT_PER_PORT)-1:0] tx_tuser_client;
wire    [(NUM_MAX_PORTS*PTP_WIDTH)-1:0]                tx_tuser_ptp;
wire    [(NUM_MAX_PORTS*PTP_EXT_WIDTH)-1:0]            tx_tuser_ptp_extended;


reg     [(NUM_MAX_PORTS*AVST_MAC_USER_RX)-1:0]         rx_av_st_mac_user;
wire    [(NUM_MAX_PORTS*AVST_USER_RX)-1:0]             rx_av_st_user;
wire    [(NUM_MAX_PORTS*AVST_USER_RX)-1:0]             rx_avst_user;
wire    [(NUM_MAX_PORTS*TUSER_WIDTH_RX)-1:0]           axist_rx_tuser;
wire    [NUM_MAX_PORTS-1:0]                            axist_rx_tuser_valid ;
wire    [NUM_MAX_PORTS-1:0]                            axist_rx_tuser_valid_p2;
                                                       
wire    [NUM_MAX_PORTS*6-1:0]                          rx_avst_error;
wire    [NUM_MAX_PORTS*40-1:0]                         rxstatus_avst_data;
wire    [NUM_MAX_PORTS-1:0]                            rxstatus_avst_valid;
wire    [NUM_MAX_PORTS*96-1:0]                         rx_avst_ptp_rx_its;
// wire    [192-1:0]                                      rx_avst_mac_ptp_rx_its;

// wire    [6-1:0]                                     rx_mltstrm_error;
// wire    [40-1:0]                                    rxstatus_mltstrm_data;
// wire    [1-1:0]                                     rxstatus_mltstrm_valid;
// wire    [96-1:0]                                    rx_mltstrm_ptp_rx_its;

wire    [NUM_SEG*ERR-1:0]                              rx_mac_error;   
wire    [NUM_SEG*FCS_ERR-1:0]                          rx_mac_fcs_error;
wire    [NUM_SEG*MAC_STS-1:0]                          rx_mac_status;

reg     [ERR*NUM_SEG-1:0]                              rx_mac_error_d1 = '0 ;
reg     [ERR*NUM_SEG-1:0]                              rx_mac_error_d2 = '0 ;
reg     [FCS_ERR*NUM_SEG-1:0]                          rx_mac_fcs_error_d1 = '0;
reg     [FCS_ERR*NUM_SEG-1:0]                          rx_mac_fcs_error_d2 = '0;
reg     [MAC_STS*NUM_SEG-1:0]                          rx_mac_status_d1 = '0;
reg     [MAC_STS*NUM_SEG-1:0]                          rx_mac_status_d2 = '0;
reg     [(NUM_MAX_PORTS*192)-1:0]                      rx_avst_ptp_rx_its_d1 = '0;
reg     [(NUM_MAX_PORTS*192)-1:0]                      rx_avst_ptp_rx_its_d2 = '0;

wire    [NUM_MAX_PORTS-1:0]                            ppt_avst_tx_ready;

reg     [NUM_MAX_PORTS-1:0]                            port_active_mask_reg;
reg     [2:0]                                          active_port;
reg     [2:0]                                          active_segment;
reg     [2:0]                                          port_data_width; 

// reg     [NUM_MAX_PORTS*6-1:0]                          rx_avst_error_d1       ;
// reg     [NUM_MAX_PORTS*6-1:0]                          rx_avst_error_d2       ;
// reg     [NUM_MAX_PORTS-1:0]                            rxstatus_avst_valid_d1 ;
// reg     [NUM_MAX_PORTS-1:0]                            rxstatus_avst_valid_d2 ;
// reg     [NUM_MAX_PORTS*40-1:0]                         rxstatus_avst_data_d1  ;
// reg     [NUM_MAX_PORTS*40-1:0]                         rxstatus_avst_data_d2  ;
reg     [TX_TUSER_MAX_PORTS-1:0]                       axi_st_tx_tuser_client;
reg     [TX_TUSER_CLIENT_WIDTH-1:0]                    tx_ms_tuser_client;   //2*num_seg for ms

reg     [TDATA_WIDTH-1:0]                              avst_rx_data_d1_p0;
reg     [AVST_DW_P1-1:0]                               avst_rx_data_d1_p1; //MAX_PORTS =4 -> 64, MAX_PORTS =2 -> 128
reg     [AVST_DW_BY_FOUR-1:0]                          avst_rx_data_d1_p2; //128
reg     [AVST_DW_BY_EIGHT-1:0]                         avst_rx_data_d1_p3; //64
                                                       
reg     [NO_OF_BYTES-1:0]                              avst_rx_tkeep_p0;
reg     [NO_BYTES_P1-1:0]                              avst_rx_tkeep_p1; //MAX_PORTS =4 -> 64, MAX_PORTS =2 -> 128
reg     [NO_BYTES_BY_FOUR-1:0]                         avst_rx_tkeep_p2; //128
reg     [NO_BYTES_BY_EIGHT-1:0]                        avst_rx_tkeep_p3; //64  

wire    [3:0]                                          s_rx_clk;
wire    [3:0]                                          s_rx_rst_n;

assign o_active_port          = active_port;
assign o_port_active_mask_reg = port_active_mask_reg;
assign s_rx_clk               = {i_rx_clk_p3,i_rx_clk_p2,i_rx_clk_p1,i_rx_clk_p0};
assign s_rx_rst_n             = {i_rx_rst_n_p3,i_rx_rst_n_p2,i_rx_rst_n_p1,i_rx_rst_n_p0};

//*******************************************************************************************
//*******************************************************************************************
// duplicate based on max ports
/*assign  rx_av_st_mac_user[AVST_MAC_USER_RX-1:192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS] = i_rx_mac_error;
assign  rx_av_st_mac_user[192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:192+NUM_SEG*MAC_STS] = i_rx_mac_fcs_error;
assign  rx_av_st_mac_user[192+NUM_SEG*MAC_STS-1:192] = i_rx_mac_status;  //tuser_sts
assign  rx_av_st_mac_user[192-1:0] = i_rx_avst_ptp_rx_its;

// assign   rx_av_st_user[142:47] = (i_rx_avst_valid && i_rx_avst_startofpacket) ? i_rx_avst_ptp_rx_its : '0;
assign  rx_av_st_user[142:47] = i_rx_avst_ptp_rx_its[95:0];
assign  rx_av_st_user[46:41]  = i_rx_avst_error;
assign  rx_av_st_user[40:40]  = i_rxstatus_avst_valid;
assign  rx_av_st_user[39:0]   = i_rxstatus_avst_data;

assign  rx_avst_user = (PORT_CLIENT_IF == 0) ? rx_av_st_mac_user : rx_av_st_user;*/

// generate if(ENABLE_MULTI_STREAM)
// begin
    // assign  axi_st_tx_mltstrm_tuser = {i_axi_st_tx_tuser_client[1],i_axi_st_tx_tuser_ptp[1],i_axi_st_tx_tuser_ptp_extended[1],i_axi_st_tx_tuser_client[0],i_axi_st_tx_tuser_ptp[0],i_axi_st_tx_tuser_ptp_extended[0]};
// end
// else
// begin
// generate 
// genvar i
// for (i=1; i<=NUM_MAX_PORTS; i=i+1) begin :TX_AXIST_TUSER
   // assign   axi_st_tx_tuser[(TUSER_WIDTH_TX*(i+1)-1:(TUSER_WIDTH_TX*(i+1))-TX_TUSER_CLIENT_WIDTH)]  = i_axi_st_tx_tuser_client[(i+1)*TX_TUSER_CLIENT_WIDTH-1:(i*TX_TUSER_CLIENT_WIDTH)];
   // assign   axi_st_tx_tuser[(TUSER_WIDTH_TX*(i+1))-TX_TUSER_CLIENT_WIDTH-1:(TUSER_WIDTH_TX*(i+1))-TX_TUSER_CLIENT_WIDTH-PTP_WIDTH] = i_axi_st_tx_tuser_ptp[(i+1)*PTP_WIDTH-1:(i*PTP_WIDTH)];
   // assign   axi_st_tx_tuser[(TUSER_WIDTH_TX*(i+1))-TX_TUSER_CLIENT_WIDTH-PTP_WIDTH-1:(TUSER_WIDTH_TX*i)]   = i_axi_st_tx_tuser_ptp_extended[(i+1)*PTP_EXT_WIDTH-1:(i*PTP_EXT_WIDTH)];
// end
// endgenerate
// end 
// endgenerate+(i+1)*

/* ///////////////////sub module instances/////////////////////////
generate if ((ENABLE_MULTI_STREAM) && (PORT_CLIENT_IF == 0))
begin : MULTI_STREAM
    hssi_ss_multi_stream_top #(
        .NUM_SEG             (NUM_SEG),  
        .TDATA_WIDTH        (TDATA_WIDTH),   
        .NO_OF_BYTES        (NO_OF_BYTES),  
        .TUSER_WIDTH_TX     (TUSER_WIDTH_TX),   
        .TUSER_WIDTH_RX     (TUSER_WIDTH_RX),   
        .ST_READY_LATENCY    (ST_READY_LATENCY),  
        .TID                (TID),
        .ENABLE_ECC         (ENABLE_ECC),   
        .USE_M20K           (USE_M20K),     
        .PORT_PROFILE           (PORT_PROFILE),
        .NUM_OF_STREAM      (NUM_OF_STREAM)
        
    )hssi_ss_multi_stream_top_inst(
        .i_tx_clk               (i_tx_clk), 
        .i_tx_reset_n           (i_tx_rst_n),
        .i_rx_clk               (i_rx_clk), 
        .i_rx_reset_n           (i_rx_rst_n),            
        .i_av_st_tx_ready       (axist_tx_tready),   
        .i_axi_st_tx_tvalid     (i_axi_st_tx_tvalid),
        .i_axi_st_tx_tdata      (i_axi_st_tx_tdata),
        .i_axi_st_tx_tlast      (i_axi_st_tx_tlast),
        .i_axi_st_tx_tkeep      (i_axi_st_tx_tkeep),
        .i_axi_st_tx_tuser      (axi_st_tx_mltstrm_tuser),
        .i_axi_st_tx_tid        (i_axi_st_tx_tid),              
        .o_axi_st_tx_tready     (axist_tx_tready_mltstrm),      
        .o_axi_st_tx_tdata      (axist_tx_tdata_mltstrm),
        .o_axi_st_tx_tvalid     (axist_tx_tvalid_mltstrm),
        .o_axi_st_tx_tkeep_seg  (axist_tx_tkeep_mltstrm),
        .o_axi_st_tx_tlast_seg  (axist_tx_tlast_mltstrm),   
        .o_axi_st_tx_tuser      (axist_tx_tuser_mltstrm),        
        .i_axi_st_rx_tvalid     (axist_rx_tvalid), 
        .i_axi_st_rx_tdata      (axist_rx_tdata),  
        .i_axi_st_rx_tlast_seg  (axist_rx_tlast_segment),  
        .i_axi_st_rx_tkeep_seg  (axist_rx_tkeep_segment),  
        .i_axi_st_rx_tuser      (axist_rx_tuser),       
        .o_axi_st_rx_tvalid     (axist_rx_tvalid_mltstrm),
        .o_axi_st_rx_tdata      (axist_rx_tdata_mltstrm),
        .o_axi_st_rx_tkeep      (axist_rx_tkeep_mltstrm),
        .o_axi_st_rx_tlast      (axist_rx_tlast_mltstrm),
        .o_axi_st_rx_tuser      (axist_rx_tuser_mltstrm),
        .o_axi_st_rx_tuser_valid(axist_rx_tuser_mltstrm_valid),
        .o_axi_st_rx_tid        (axist_rx_tid_mltstrm)
    );
end
endgenerate */
        
axist_to_avst_bridge #( 
    .NUM_SEG                (NUM_SEG), 
    .PORT_PROFILE           (PORT_PROFILE),
    .PORT_CLIENT_IF         (PORT_CLIENT_IF),
    .NUM_MAX_PORTS          (NUM_MAX_PORTS),
    .DR_ENABLE              (DR_ENABLE),
    //AXI                   
    .TDATA_WIDTH            (TDATA_WIDTH),
    .NO_OF_BYTES            (NO_OF_BYTES),
    .TUSER_WIDTH_TX         (TX_TUSER_WIDTH), //(TUSER_WIDTH_TX+NUM_SEG),
    .TUSER_WIDTH_RX         (TUSER_WIDTH_RX),
    .ST_READY_LATENCY       (ST_READY_LATENCY),    ////+2 is for adjusting the latency of PREAMBLE_PASS_THROUGH_TX module
    .NUM_OF_STREAM          (NUM_OF_STREAM),
    .PKT_SEG_PARITY_EN      (PKT_SEG_PARITY_EN), ///assuming PREAMBLE PASS THROUGH will be disabled for mac seg case
    .PKT_SEG_PARITY_WIDTH   (PKT_SEG_PARITY_WIDTH), 
    //AVST
    .DATA_WIDTH             (TDATA_WIDTH), 
    .EMPTY_BITS             (TEMPTY_BITS),
    .USER_WIDTH_TX          (AVST_USER_TX),  //(AVST_USER_TX+NUM_SEG),
    .USER_WIDTH_RX          (AVST_USER_RX),
    //
    .ENABLE_ECC             (ENABLE_ECC),
    // .USE_M20K               (USE_M20K),
    .SIM_EMULATE            (SIM_EMULATE)
)axist_to_avst_bridge_inst(
    .i_tx_clk_p0                 (i_tx_clk_p0),
    .i_tx_clk_p1                 (i_tx_clk_p1),
    .i_tx_clk_p2                 (i_tx_clk_p2),
    .i_tx_clk_p3                 (i_tx_clk_p3),
    .i_tx_reset_n_p0             (i_tx_rst_n_p0),
    .i_tx_reset_n_p1             (i_tx_rst_n_p1),
    .i_tx_reset_n_p2             (i_tx_rst_n_p2),
    .i_tx_reset_n_p3             (i_tx_rst_n_p3),
    .i_rx_clk_p0                 (i_rx_clk_p0),
    .i_rx_clk_p1                 (i_rx_clk_p1),
    .i_rx_clk_p2                 (i_rx_clk_p2),
    .i_rx_clk_p3                 (i_rx_clk_p3),
    .i_rx_reset_n_p0             (i_rx_rst_n_p0),
    .i_rx_reset_n_p1             (i_rx_rst_n_p1),
    .i_rx_reset_n_p2             (i_rx_rst_n_p2),
    .i_rx_reset_n_p3             (i_rx_rst_n_p3),
    .i_port_active_mask_reg      (port_active_mask_reg),
    .i_active_ports              (active_port),
    .i_active_segments           (active_segment),
    .i_port_data_width           (port_data_width),
     //
    .i_axi_st_tx_tvalid          (i_axi_st_tx_tvalid),
    .i_axi_st_tx_tdata           (i_axi_st_tx_tdata),
    .i_axi_st_tx_tlast           (i_axi_st_tx_tlast),
    .i_axi_st_tx_tkeep           (i_axi_st_tx_tkeep),
    .i_axi_st_tx_tuser           (axi_st_tx_tuser),         //({tx_parity_error, axi_st_tx_tuser}),
    .i_axi_st_tx_tlast_segment   (i_axi_st_tx_tlast_segment),
    .i_axi_st_tx_tkeep_segment   (i_axi_st_tx_tkeep_segment),
    .i_axi_st_tx_pkt_seg_parity  (i_axi_st_tx_pkt_seg_parity),
    .o_axi_st_tx_tready          (axist_tx_tready),
    //
    .o_axi_st_tx_parity_error    (o_axi_st_tx_parity_error),
    .o_tx_fifo_eccstatus         (o_tx_fifo_eccstatus),
    //
    .i_av_st_tx_ready            ((PORT_CLIENT_IF == 1) ? (PREAMBLE_PASS_TH_EN ? ppt_avst_tx_ready : i_tx_avst_ready) : {NUM_MAX_PORTS{1'b0}}),
    .o_av_st_tx_data             (avst_tx_data),
    .o_av_st_tx_valid            (avst_tx_valid),
    .o_av_st_tx_startofpacket    (avst_tx_startofpacket),
    .o_av_st_tx_endofpacket      (avst_tx_endofpacket),
    .o_av_st_tx_empty            (avst_tx_empty),
    .o_av_st_tx_user             (avst_tx_user), //({avst_tx_parity_error, avst_tx_user}),
    //
    .i_av_st_tx_ms_ready         ((PORT_CLIENT_IF == 0) ? i_tx_mac_ready : {NUM_MAX_PORTS{1'b0}}),
    .o_av_st_tx_ms_data          (avst_tx_mac_data),
    .o_av_st_tx_ms_valid         (avst_tx_mac_valid),
    .o_av_st_tx_ms_inframe       (avst_tx_mac_inframe),
    .o_av_st_tx_ms_eop_empty     (avst_tx_mac_eop_empty),
    //
    .i_av_st_rx_data             ((PORT_CLIENT_IF == 1) ? avst_rx_data : {TDATA_WIDTH{1'b0}}),                  
    .i_av_st_rx_valid            ((PORT_CLIENT_IF == 1) ? avst_rx_valid : {NUM_MAX_PORTS{1'b0}}),                 
    .i_av_st_rx_startofpacket    ((PORT_CLIENT_IF == 1) ? avst_rx_startofpacket : {NUM_MAX_PORTS{1'b0}}),         
    .i_av_st_rx_endofpacket      ((PORT_CLIENT_IF == 1) ? avst_rx_endofpacket : {NUM_MAX_PORTS{1'b0}}),           
    .i_av_st_rx_empty            ((PORT_CLIENT_IF == 1) ? avst_rx_empty : {TEMPTY_BITS{1'b0}}),                 
    .i_av_st_rx_user             (avst_rx_user),                   
     //
    .i_av_st_rx_ms_data          ((PORT_CLIENT_IF == 0) ? i_rx_mac_data : {TDATA_WIDTH{1'b0}}),      
    .i_av_st_rx_ms_valid         ((PORT_CLIENT_IF == 0) ? i_rx_mac_valid : {NUM_MAX_PORTS{1'b0}}),       
    .i_av_st_rx_ms_inframe       ((PORT_CLIENT_IF == 0) ? i_rx_mac_inframe : {NUM_SEG{1'b0}}),    
    .i_av_st_rx_ms_eop_empty     ((PORT_CLIENT_IF == 0) ? i_rx_mac_eop_empty : {TEMPTY_BITS{1'b0}}),
     //
    .o_axi_st_rx_tready          (axist_rx_tready),     
    .o_axi_st_rx_tvalid          (axist_rx_tvalid),      
    .o_axi_st_rx_tdata           (axist_rx_tdata),       
    .o_axi_st_rx_tlast           (axist_rx_tlast),       
    .o_axi_st_rx_tkeep           (axist_rx_tkeep),       
    .o_axi_st_rx_tuser           (axist_rx_tuser),          
    .o_axi_st_rx_tuser_valid     (axist_rx_tuser_valid),
    .o_axi_st_rx_tuser_valid_p2  (axist_rx_tuser_valid_p2),
    .o_axi_st_rx_tlast_segment   (axist_rx_tlast_segment),  
    .o_axi_st_rx_tkeep_segment   (axist_rx_tkeep_segment),   
    .o_axi_st_rx_pkt_seg_parity  (axist_rx_pkt_seg_parity)   
);
    
generate if (PREAMBLE_PASS_TH_EN)
begin : PREAMBLE_PASS_THROUGH_TX
    preamble_pass_through_tx #(
    //AVST In 256
        .TDATA                   (TDATA_WIDTH),
        .TEMPTY_BITS             (TEMPTY_BITS),
        .TUSER                   (AVST_USER_TX),
        //AVST out 128
        .DATA_WIDTH              (DATA_WIDTH), 
        .EMPTY_BITS              (EMPTY_BITS),  
        .USER_WIDTH              (AVST_USER_TX)
    )preamble_pass_through_tx_inst(
        .i_tx_clk                (i_tx_clk_p0),
        .i_tx_reset_n            (i_tx_rst_n_p0),
    //
        .o_user_avst_tx_ready    (ppt_avst_tx_ready),
        .i_user_avst_tx_valid    (avst_tx_valid),      
        .i_user_avst_tx_data     (avst_tx_data),       
        .i_user_avst_tx_empty    (avst_tx_empty),       
        .i_user_avst_tx_sop      (avst_tx_startofpacket && avst_tx_valid),       
        .i_user_avst_tx_eop      (avst_tx_endofpacket && avst_tx_valid),       
        .i_user_avst_tx_user     (avst_tx_user),          
    //
        .i_mac_avst_tx_ready     (i_tx_avst_ready),
        .o_mac_avst_tx_valid     (ppt_avst_tx_valid),
        .o_mac_avst_tx_data      (ppt_avst_tx_data),
        .o_mac_avst_tx_empty     (ppt_avst_tx_empty),
        .o_mac_avst_tx_sop       (ppt_avst_tx_startofpacket),
        .o_mac_avst_tx_eop       (ppt_avst_tx_endofpacket),
        .o_mac_avst_tx_user      (ppt_avst_tx_user),
        .o_mac_avst_tx_preamble  (ppt_avst_tx_preamble)
    );
end
endgenerate


generate if (PREAMBLE_PASS_TH_EN)
begin : PREAMBLE_PASS_THROUGH_RX
    preamble_pass_through_rx #(
      //AVST out 256
      .TDATA                     (TDATA_WIDTH),
      .TEMPTY_BITS               (TEMPTY_BITS),
      .TUSER                     (AVST_USER_RX),
      //AVST in 128
      .DATA_WIDTH                (DATA_WIDTH), 
      .EMPTY_BITS                (EMPTY_BITS),  
      .USER_WIDTH                (AVST_USER_RX)
    )preamble_pass_through_rx_inst(
        .i_rx_clk                (i_rx_clk_p0),
        .i_rx_rst_n              (i_rx_rst_n_p0),
        .i_mac_avst_rx_valid     (i_rx_avst_valid),      
        .i_mac_avst_rx_data      (i_rx_avst_data),       
        .i_mac_avst_rx_sop       (i_rx_avst_startofpacket),       
        .i_mac_avst_rx_eop       (i_rx_avst_endofpacket),       
        .i_mac_avst_rx_empty     (i_rx_avst_empty),       
        .i_mac_avst_rx_user      (rx_avst_user),
        .i_mac_avst_rx_preamble  (i_rx_avst_preamble),
      //
        .o_user_avst_rx_valid    (ppt_avst_rx_valid),
        .o_user_avst_rx_data     (ppt_avst_rx_data),
        .o_user_avst_rx_sop      (ppt_avst_rx_startofpacket),
        .o_user_avst_rx_eop      (ppt_avst_rx_endofpacket),
        .o_user_avst_rx_empty    (ppt_avst_rx_empty),
        .o_user_avst_rx_user     (ppt_avst_rx_user)
    );
end
endgenerate


/////user signal will change based on IF//
///currently based on assuming mac segmented//

generate    
if (PREAMBLE_PASS_TH_EN )  begin    
   assign tx_avst_user            =   ppt_avst_tx_user            ;
   assign o_tx_avst_data          =   ppt_avst_tx_data            ;
   assign o_tx_avst_valid         =   ppt_avst_tx_valid           ;
   assign o_tx_avst_startofpacket =   ppt_avst_tx_startofpacket   ;
   assign o_tx_avst_endofpacket   =   ppt_avst_tx_endofpacket     ;
   assign o_tx_avst_empty         =   ppt_avst_tx_empty           ;
   assign o_tx_avst_preamble      =   ppt_avst_tx_preamble        ;
                                                                  
   assign avst_rx_data            =   ppt_avst_rx_data            ;
   assign avst_rx_valid           =   ppt_avst_rx_valid           ;
   assign avst_rx_startofpacket   =   ppt_avst_rx_startofpacket   ;
   assign avst_rx_endofpacket     =   ppt_avst_rx_endofpacket     ;
   assign avst_rx_empty           =   ppt_avst_rx_empty           ;
   assign avst_rx_user            =   ppt_avst_rx_user            ;
end 
else begin
   assign tx_avst_user            =   avst_tx_user ;
   assign o_tx_avst_data          =   avst_tx_data;
   assign o_tx_avst_valid         =   avst_tx_valid;
   assign o_tx_avst_startofpacket =   avst_tx_startofpacket;
   assign o_tx_avst_endofpacket   =   avst_tx_endofpacket;
   assign o_tx_avst_empty         =   avst_tx_empty;
   assign o_tx_avst_preamble      =   '0;
                                      
   assign avst_rx_data            =   i_rx_avst_data;
   assign avst_rx_valid           =   i_rx_avst_valid;
   assign avst_rx_startofpacket   =   i_rx_avst_startofpacket;
   assign avst_rx_endofpacket     =   i_rx_avst_endofpacket;
   assign avst_rx_empty           =   i_rx_avst_empty;
   assign avst_rx_user            =   rx_avst_user;
end
endgenerate

generate 
genvar i;
for (i=0; i<NUM_MAX_PORTS; i=i+1) begin :TX_AXIST_TUSER
   assign   axi_st_tx_tuser[TX_TUSER_WIDTH*(i+1)-1:(TX_TUSER_WIDTH*(i+1))-TX_TUSER_CLIENT_PER_PORT]  = axi_st_tx_tuser_client[(i+1)*TX_TUSER_CLIENT_PER_PORT-1:(i*TX_TUSER_CLIENT_PER_PORT)];
   assign   axi_st_tx_tuser[TX_TUSER_WIDTH*(i+1)-TX_TUSER_CLIENT_PER_PORT-1:(TX_TUSER_WIDTH*(i+1))-TX_TUSER_CLIENT_PER_PORT-PTP_WIDTH] = i_axi_st_tx_tuser_ptp[(i+1)*PTP_WIDTH-1:(i*PTP_WIDTH)];
   assign   axi_st_tx_tuser[TX_TUSER_WIDTH*(i+1)-TX_TUSER_CLIENT_PER_PORT-PTP_WIDTH-1:(TX_TUSER_WIDTH*i)]   = i_axi_st_tx_tuser_ptp_extended[(i+1)*PTP_EXT_WIDTH-1:(i*PTP_EXT_WIDTH)];

   assign tx_tuser_client[(i+1)*TX_TUSER_CLIENT_PER_PORT-1:(i*TX_TUSER_CLIENT_PER_PORT)] = tx_avst_user[TX_TUSER_WIDTH*(i+1)-1:(TX_TUSER_WIDTH*(i+1))-TX_TUSER_CLIENT_PER_PORT];
   assign tx_tuser_ptp[(i+1)*PTP_WIDTH-1:(i*PTP_WIDTH)]  = tx_avst_user[(TX_TUSER_WIDTH*(i+1))-TX_TUSER_CLIENT_PER_PORT-1:(TX_TUSER_WIDTH*(i+1))-TX_TUSER_CLIENT_PER_PORT-PTP_WIDTH];
   assign tx_tuser_ptp_extended[(i+1)*PTP_EXT_WIDTH-1:(i*PTP_EXT_WIDTH)] = tx_avst_user[(TX_TUSER_WIDTH*(i+1))-TX_TUSER_CLIENT_PER_PORT-PTP_WIDTH-1:(TX_TUSER_WIDTH*i)];
end
endgenerate

assign o_axi_st_tx_tready         = axist_tx_tready;

assign o_tx_mac_data              = avst_tx_mac_data;
assign o_tx_mac_valid             = avst_tx_mac_valid;
assign o_tx_mac_inframe           = avst_tx_mac_inframe;
assign o_tx_mac_eop_empty         = avst_tx_mac_eop_empty;


// duplicate
generate 
genvar l,m,n;
if (PORT_CLIENT_IF == 0) 
begin : MAC_SEG

// if (PORT_PROFILE == "25GbE") begin: TUSER_CLIENT_25GbE
if (NUM_MAX_PORTS == 1) begin: TUSER_CLIENT_1P
   always @ (*) begin //MAC SEG
         axi_st_tx_tuser_client = i_axi_st_tx_tuser_client;     //input       [TX_TUSER_CLIENT_WIDTH-1:0]                     i_axi_st_tx_tuser_client,
   end                                                                                              //TX_TUSER_CLIENT_WIDTH         = (PORT_CLIENT_IF == 1)? (NUM_MAX_PORTS*2*NUM_SEG) : 2*NUM_SEG,
end                                                                                                // localparam TX_TUSER_MAX_PORTS        = (PORT_CLIENT_IF == 1)? TX_TUSER_CLIENT_WIDTH: (NUM_MAX_PORTS*TX_TUSER_CLIENT_WIDTH); // TX_TUSER_CLIENT_WIDTH = maxports*2 (sopa from tcl), = 2*numseg (macseg from tcl)
else if (NUM_MAX_PORTS == 2) begin: TUSER_CLIENT_2P
   always @ (*) begin //MAC SEG
      if (active_port == 3'd1) begin
         axi_st_tx_tuser_client = {{TX_TUSER_CLIENT_WIDTH{1'b0}},i_axi_st_tx_tuser_client};
      end
      else if (active_port == 3'd2) begin
         axi_st_tx_tuser_client = {{NUM_SEG{1'b0}}, i_axi_st_tx_tuser_client[(2*NUM_SEG)-1:NUM_SEG],
                                   {NUM_SEG{1'b0}}, i_axi_st_tx_tuser_client[NUM_SEG-1:0]}; //3:0, 7:4
      end
      else begin
         axi_st_tx_tuser_client = {{TX_TUSER_CLIENT_WIDTH{1'b0}},i_axi_st_tx_tuser_client}; //default condition
      end
   end
end
else begin : TUSER_CLIENT_4P
   always @ (*) begin //MAC SEG
      if (active_port == 3'd1) begin
         axi_st_tx_tuser_client = {{(3*TX_TUSER_CLIENT_WIDTH){1'b0}},i_axi_st_tx_tuser_client};
      end
      else if (active_port == 3'd2) begin
         axi_st_tx_tuser_client = {{NUM_SEG*2{1'b0}}, {NUM_SEG{1'b0}}, i_axi_st_tx_tuser_client[(2*NUM_SEG)-1:NUM_SEG],
                                   {NUM_SEG*2{1'b0}}, {NUM_SEG{1'b0}}, i_axi_st_tx_tuser_client[NUM_SEG-1:0]};
      end
      else if (active_port == 3'd4) begin
         axi_st_tx_tuser_client = {{NUMSEG_1{1'b0}}, i_axi_st_tx_tuser_client[(2*NUM_SEG)-1:NUMSEG_1],
                                   {NUMSEG_1{1'b0}}, i_axi_st_tx_tuser_client[NUMSEG_1-1:NUM_SEG],         //NUMSEG_1 = 3*NUM_SEG/2
                                   {NUMSEG_1{1'b0}}, i_axi_st_tx_tuser_client[NUM_SEG-1:NUM_SEG/2],
                                   {NUMSEG_1{1'b0}}, i_axi_st_tx_tuser_client[NUMSEG_BY_TWO-1:0]};
      end
      else begin
         axi_st_tx_tuser_client = {{(3*TX_TUSER_CLIENT_WIDTH){1'b0}},i_axi_st_tx_tuser_client}; //default condition
      end
   end
end 

// if (PORT_PROFILE == "25GbE" || PORT_PROFILE == "50GAUI-1") begin: 
if (NUM_MAX_PORTS == 1) begin: TUSER_CLIENT_OP_1P
   always @ (*) begin //MAC SEG
        tx_ms_tuser_client = tx_tuser_client;
   end
end 
else if (NUM_MAX_PORTS == 2) begin: TUSER_CLIENT_OP_2P
   always @ (*) begin
      if (active_port == 3'd1) begin
         tx_ms_tuser_client = tx_tuser_client[(2*NUM_SEG)-1:0];//7:0
      end
      else if (active_port == 3'd2) begin
         tx_ms_tuser_client = {tx_tuser_client[3*NUM_SEG-1:2*NUM_SEG],tx_tuser_client[NUM_SEG-1:0]}; //11:8, 3:0
      end
      else begin
         tx_ms_tuser_client = tx_tuser_client[(2*NUM_SEG)-1:0]; //default condition
      end
   end
end
else begin : TUSER_CLIENT_OP_4P
   always @ (*) begin
      if (active_port == 3'd1) begin
         tx_ms_tuser_client = tx_tuser_client[(2*NUM_SEG)-1:0];
      end
      else if (active_port == 3'd2) begin
         tx_ms_tuser_client = {tx_tuser_client[5*NUM_SEG-1:4*NUM_SEG],tx_tuser_client[NUM_SEG-1:0]}; //3:0, 19:16
      end
      else if (active_port == 3'd4) begin
         tx_ms_tuser_client = {tx_tuser_client[13*(NUM_SEG/2)-1:6*NUM_SEG],tx_tuser_client[9*(NUM_SEG/2)-1:4*NUM_SEG],//17:16, 25:24
                               tx_tuser_client[5*(NUM_SEG/2)-1:2*NUM_SEG],tx_tuser_client[(NUM_SEG/2)-1:0]}; //1:0, 9:8
      end
      else begin
         tx_ms_tuser_client = tx_tuser_client[(2*NUM_SEG)-1:0]; //default condition
      end
   end
end

   for (l=0;l<NUM_SEG;l=l+1)
   begin :x
       assign o_tx_mac_error[l]      = tx_ms_tuser_client[2*l];   //no change since tuser for invalid seg should be 0
       assign o_tx_mac_skip_crc[l]   = tx_ms_tuser_client[2*l+1]; //no change since tuser for invalid seg should be 0
   end
   
   assign o_tx_avst_error        = {NUM_MAX_PORTS{1'b0}};
   assign o_tx_avst_skip_crc     = {NUM_MAX_PORTS{1'b0}};
    
end
else begin : SOP_ALIGN
   always @ (*) begin //SOP ALIGNED
      axi_st_tx_tuser_client = i_axi_st_tx_tuser_client;
   end

   for (n=0;n<NUM_MAX_PORTS;n=n+1)
   begin :SOP_ALIGN_ERR_CRC
      // for (m=0;m<2;m=m+2)
      // begin : SOP_ALIGN_ERR_CRC
          assign o_tx_avst_error[n]      = tx_tuser_client[n*2];  
          assign o_tx_avst_skip_crc[n]   = tx_tuser_client[(n*2)+1];
      // end
   end

   assign o_tx_mac_error         = 1'b0;
   assign o_tx_mac_skip_crc      = 1'b0;
end
endgenerate

// duplicate
generate
    if(TILES == "F" && PKT_CYL == 1) begin
    genvar i;
        // always @(posedge i_tx_clk) begin
         for (i=0;i<NUM_MAX_PORTS;i=i+1)
         begin : TUSER_TX_PTP_PKT_CYL_1       
            assign o_av_st_tx_ptp_ts_valid[i]        = tx_tuser_ptp[(PTP_WIDTH*i)+1:(PTP_WIDTH*i)];
            assign o_av_st_tx_ptp_ts_req[i]          = tx_tuser_ptp[(PTP_WIDTH*i)+2];  
            assign o_av_st_tx_ptp_ins_ets[i]         = tx_tuser_ptp[(PTP_WIDTH*i)+3];  
            assign o_av_st_tx_ptp_asym_p2p_idx[i]    = tx_tuser_ptp[(PTP_WIDTH*i)+10:(PTP_WIDTH*i)+4];
            assign o_av_st_tx_ptp_asym_sign[i]       = tx_tuser_ptp[(PTP_WIDTH*i)+11];
            assign o_av_st_tx_ptp_asym[i]            = tx_tuser_ptp[(PTP_WIDTH*i)+12];
            assign o_av_st_tx_ptp_p2p[i]             = tx_tuser_ptp[(PTP_WIDTH*i)+13];
            assign o_av_st_tx_ptp_fp[i]              = tx_tuser_ptp[(PTP_WIDTH*i)+45:(PTP_WIDTH*i)+14]; 
            assign o_av_st_tx_ptp_ins_cf[i]          = tx_tuser_ptp_extended[(PTP_EXT_WIDTH*i)];    
            assign o_av_st_tx_ptp_tx_its[i]          = tx_tuser_ptp_extended[(PTP_EXT_WIDTH*i)+96:(PTP_EXT_WIDTH*i)+1];      
            assign o_av_st_tx_ptp_ts_format[i]       = tx_tuser_ptp_extended[(PTP_EXT_WIDTH*i)+97:(PTP_EXT_WIDTH*i)+97]; 
            assign o_av_st_tx_ptp_update_eb[i]       = tx_tuser_ptp_extended[(PTP_EXT_WIDTH*i)+98:(PTP_EXT_WIDTH*i)+98]; 
            assign o_av_st_tx_ptp_zero_csum[i]       = tx_tuser_ptp_extended[(PTP_EXT_WIDTH*i)+99:(PTP_EXT_WIDTH*i)+99]; 
            assign o_av_st_tx_ptp_eb_offset[i]       = tx_tuser_ptp_extended[(PTP_EXT_WIDTH*i)+115:(PTP_EXT_WIDTH*i)+100]; 
            assign o_av_st_tx_ptp_csum_offset[i]     = tx_tuser_ptp_extended[(PTP_EXT_WIDTH*i)+131:(PTP_EXT_WIDTH*i)+116]; 
            assign o_av_st_tx_ptp_cf_offset[i]       = tx_tuser_ptp_extended[(PTP_EXT_WIDTH*i)+147:(PTP_EXT_WIDTH*i)+132]; 
            assign o_av_st_tx_ptp_ts_offset[i]       = tx_tuser_ptp_extended[(PTP_EXT_WIDTH*i)+163:(PTP_EXT_WIDTH*i)+148];   
         end            
    end 
    else if (TILES == "F" && PKT_CYL == 2) begin 
    genvar j;
         for (j=0;j<NUM_MAX_PORTS;j=j+1)
         begin : TUSER_TX_PTP_PKT_CYL_2     
            assign o_av_st_tx_ptp_ts_valid[j]        = tx_tuser_ptp[(PTP_WIDTH*j)+1:(PTP_WIDTH*j)];                         
            assign o_av_st_tx_ptp_ts_req[j]          = {tx_tuser_ptp[(PTP_WIDTH*j)+48],tx_tuser_ptp[(PTP_WIDTH*j)+2]};                           
            assign o_av_st_tx_ptp_ins_ets[j]         = {tx_tuser_ptp[(PTP_WIDTH*j)+49],tx_tuser_ptp[(PTP_WIDTH*j)+3]};                           
            assign o_av_st_tx_ptp_asym_p2p_idx[j]    = {tx_tuser_ptp[(PTP_WIDTH*j)+56:(PTP_WIDTH*j)+50],tx_tuser_ptp[(PTP_WIDTH*j)+10:(PTP_WIDTH*j)+4]};                        
            assign o_av_st_tx_ptp_asym_sign[j]       = {tx_tuser_ptp[(PTP_WIDTH*j)+57],tx_tuser_ptp[(PTP_WIDTH*j)+11]};                          
            assign o_av_st_tx_ptp_asym[j]            = {tx_tuser_ptp[(PTP_WIDTH*j)+58],tx_tuser_ptp[(PTP_WIDTH*j)+12]};                          
            assign o_av_st_tx_ptp_p2p[j]             = {tx_tuser_ptp[(PTP_WIDTH*j)+59],tx_tuser_ptp[(PTP_WIDTH*j)+13]};                          
            assign o_av_st_tx_ptp_fp[j]              = {tx_tuser_ptp[(PTP_WIDTH*j)+91:(PTP_WIDTH*j)+60],tx_tuser_ptp[(PTP_WIDTH*j)+45:(PTP_WIDTH*j)+14]};       
            
            assign o_av_st_tx_ptp_ins_cf[j]          = {tx_tuser_ptp_extended[(PTP_EXT_WIDTH*j)+164],tx_tuser_ptp_extended[(PTP_EXT_WIDTH*j)]};                  
            assign o_av_st_tx_ptp_tx_its[j]          = {tx_tuser_ptp_extended[(PTP_EXT_WIDTH*j)+260:(PTP_EXT_WIDTH*j)+165],tx_tuser_ptp_extended[(PTP_EXT_WIDTH*j)+96:(PTP_EXT_WIDTH*j)+1]};                                                                                                                
            assign o_av_st_tx_ptp_ts_format[j]       = {tx_tuser_ptp_extended[(PTP_EXT_WIDTH*j)+261],tx_tuser_ptp_extended[(PTP_EXT_WIDTH*j)+97]};                  
            assign o_av_st_tx_ptp_update_eb[j]       = {tx_tuser_ptp_extended[(PTP_EXT_WIDTH*j)+262],tx_tuser_ptp_extended[(PTP_EXT_WIDTH*j)+98]};                 
            assign o_av_st_tx_ptp_zero_csum[j]       = {tx_tuser_ptp_extended[(PTP_EXT_WIDTH*j)+263],tx_tuser_ptp_extended[(PTP_EXT_WIDTH*j)+99]};                   
            assign o_av_st_tx_ptp_eb_offset[j]       = {tx_tuser_ptp_extended[(PTP_EXT_WIDTH*j)+279:(PTP_EXT_WIDTH*j)+264],tx_tuser_ptp_extended[(PTP_EXT_WIDTH*j)+115:(PTP_EXT_WIDTH*j)+100]};             
            assign o_av_st_tx_ptp_csum_offset[j]     = {tx_tuser_ptp_extended[(PTP_EXT_WIDTH*j)+295:(PTP_EXT_WIDTH*j)+280],tx_tuser_ptp_extended[(PTP_EXT_WIDTH*j)+131:(PTP_EXT_WIDTH*j)+116]};             
            assign o_av_st_tx_ptp_cf_offset[j]       = {tx_tuser_ptp_extended[(PTP_EXT_WIDTH*j)+311:(PTP_EXT_WIDTH*j)+296],tx_tuser_ptp_extended[(PTP_EXT_WIDTH*j)+147:(PTP_EXT_WIDTH*j)+132]};             
            assign o_av_st_tx_ptp_ts_offset[j]       = {tx_tuser_ptp_extended[(PTP_EXT_WIDTH*j)+327:(PTP_EXT_WIDTH*j)+312],tx_tuser_ptp_extended[(PTP_EXT_WIDTH*j)+163:(PTP_EXT_WIDTH*j)+148]};  
        end         
    end        
    else begin  
    genvar k;
         for (k=0;k<NUM_MAX_PORTS;k=k+1)
         begin : TUSER_TX_PTP_PKT_CYL  
        // always @(posedge i_tx_clk) begin
            //o_tx_avst_ptp_ts_valid[0]              <= tx_tuser_ptp[0];  
            assign o_av_st_tx_ptp_ts_req[k]          = tx_tuser_ptp[(PTP_WIDTH*k)+2];  
            assign o_av_st_tx_ptp_ins_ets[k]         = tx_tuser_ptp[(PTP_WIDTH*k)+3];
            assign o_av_st_tx_ptp_fp[k]              = tx_tuser_ptp[(PTP_WIDTH*k)+45:(PTP_WIDTH*k)+14]; 
            assign o_av_st_tx_ptp_ins_cf[k]          = tx_tuser_ptp_extended[(PTP_EXT_WIDTH*k)];   
            assign o_av_st_tx_ptp_tx_its[k]          = tx_tuser_ptp_extended[(PTP_EXT_WIDTH*k)+96:(PTP_EXT_WIDTH*k)+1];      
            assign o_av_st_tx_ptp_ts_format[k]       = tx_tuser_ptp_extended[(PTP_EXT_WIDTH*k)+97]; 
            assign o_av_st_tx_ptp_update_eb[k]       = tx_tuser_ptp_extended[(PTP_EXT_WIDTH*k)+98]; 
            assign o_av_st_tx_ptp_zero_csum[k]       = tx_tuser_ptp_extended[(PTP_EXT_WIDTH*k)+99]; 
            assign o_av_st_tx_ptp_eb_offset[k]       = tx_tuser_ptp_extended[(PTP_EXT_WIDTH*k)+115:(PTP_EXT_WIDTH*k)+100]; 
            assign o_av_st_tx_ptp_csum_offset[k]     = tx_tuser_ptp_extended[(PTP_EXT_WIDTH*k)+131:(PTP_EXT_WIDTH*k)+116]; 
            assign o_av_st_tx_ptp_cf_offset[k]       = tx_tuser_ptp_extended[(PTP_EXT_WIDTH*k)+147:(PTP_EXT_WIDTH*k)+132]; 
            assign o_av_st_tx_ptp_ts_offset[k]       = tx_tuser_ptp_extended[(PTP_EXT_WIDTH*k)+163:(PTP_EXT_WIDTH*k)+148]; 
        // end
        end     
    end
endgenerate

// always @(posedge i_rx_clk) begin
    // o_axi_st_rx_tvalid              <=  axist_rx_tvalid;
    // o_axi_st_rx_tdata               <=  axist_rx_tdata ;
    // o_axi_st_rx_tlast               <=  axist_rx_tlast ;
    // o_axi_st_rx_tkeep               <=  axist_rx_tkeep ;
    // o_axi_st_rx_tid                 <= 'd0;
    // o_axi_st_rx_tlast_segment       <= axist_rx_tlast_segment;  
    // o_axi_st_rx_tkeep_segment       <= axist_rx_tkeep_segment;  
    // o_axi_st_rx_pkt_seg_parity      <= axist_rx_pkt_seg_parity; 
// end

generate if (ASYNC_ADAPTERS_EN == 0)  
begin : TDATA_LATCH_SYNC  

   always @(posedge i_rx_clk_p0) begin
       o_axi_st_rx_tvalid              <=  axist_rx_tvalid;
       o_axi_st_rx_tdata               <=  axist_rx_tdata ;
       o_axi_st_rx_tlast               <=  axist_rx_tlast ;
       o_axi_st_rx_tkeep               <=  axist_rx_tkeep ;
       o_axi_st_rx_tid                 <= 'd0;
       o_axi_st_rx_tlast_segment       <= axist_rx_tlast_segment;  
       o_axi_st_rx_tkeep_segment       <= axist_rx_tkeep_segment;  
       o_axi_st_rx_pkt_seg_parity      <= axist_rx_pkt_seg_parity; 
   end           
end
else begin:SOP_ALIGNED_ASYNC
genvar p;

   always_comb
   begin
      o_axi_st_rx_tid                 = 'd0;   
      o_axi_st_rx_tlast_segment       = 'd0;   
      o_axi_st_rx_tkeep_segment       = 'd0;   
   end

   for (p=0;p<NUM_MAX_PORTS;p=p+1)
   begin: RX_SOPA_AXIST_REG
      always @(posedge s_rx_clk[p]) 
      begin
         o_axi_st_rx_tvalid[p]         <= axist_rx_tvalid[p];           
         o_axi_st_rx_tlast[p]          <= axist_rx_tlast[p];
         o_axi_st_rx_pkt_seg_parity[p] <= axist_rx_pkt_seg_parity[p];     
      end
   end  
   
   if (NUM_MAX_PORTS == 4) begin: TDATA_MUX_4P   
      always_comb
      begin
         o_axi_st_rx_tdata  =  (port_data_width == 2)? avst_rx_data_d1_p0 : (port_data_width == 1)? {256'd0,avst_rx_data_d1_p2,avst_rx_data_d1_p0[AVST_DW_BY_FOUR-1:0]} :
                               {256'd0,avst_rx_data_d1_p3,avst_rx_data_d1_p2[AVST_DW_BY_EIGHT-1:0],avst_rx_data_d1_p1,avst_rx_data_d1_p0[AVST_DW_BY_EIGHT-1:0]};
         o_axi_st_rx_tkeep  =  (port_data_width == 2)? avst_rx_tkeep_p0 : (port_data_width == 1)? {32'd0,avst_rx_tkeep_p2,avst_rx_tkeep_p0[NO_BYTES_BY_FOUR-1:0]} :     //32'd0,15:0,15:0
                               {32'd0,avst_rx_tkeep_p3,avst_rx_tkeep_p2[NO_BYTES_BY_EIGHT-1:0],avst_rx_tkeep_p1,avst_rx_tkeep_p0[NO_BYTES_BY_EIGHT-1:0]}; //32'd0,7:0,7:0y,7:0,7:0                             
      end   
   
   end
   else if (NUM_MAX_PORTS == 2) begin: TDATA_MUX_2P
      always_comb
      begin
         o_axi_st_rx_tdata  =  (port_data_width == 2)? avst_rx_data_d1_p0 : (port_data_width == 1)? {256'd0,avst_rx_data_d1_p1,avst_rx_data_d1_p0[AVST_DW_BY_FOUR-1:0]} :
                               {384'd0,avst_rx_data_d1_p1[AVST_DW_BY_EIGHT-1:0],avst_rx_data_d1_p0[AVST_DW_BY_EIGHT-1:0]};
         o_axi_st_rx_tkeep  =  (port_data_width == 2)? avst_rx_tkeep_p0 : (port_data_width == 1)? {32'd0,avst_rx_tkeep_p1,avst_rx_tkeep_p0[NO_BYTES_BY_FOUR-1:0]} :     //32'd0,15:0,15:0
                               {48'd0,avst_rx_tkeep_p1[NO_BYTES_BY_EIGHT-1:0],avst_rx_tkeep_p0[NO_BYTES_BY_EIGHT-1:0]}; //7:0,7:0
      end      
   end
   else begin : TDATA_MUX_1P
      always_comb
      begin   
         o_axi_st_rx_tdata  =  avst_rx_data_d1_p0;
         o_axi_st_rx_tkeep  =  avst_rx_tkeep_p0;
      end
   end
   
   
   if (NUM_MAX_PORTS == 4) begin: TVALID_MUX_4P
   
      always @(posedge i_rx_clk_p0) 
      begin 
         case (active_port)
         3'd1:  
         begin  
            avst_rx_data_d1_p0    <= axist_rx_tdata;    
            avst_rx_tkeep_p0      <= axist_rx_tkeep;    
         end 
         3'd2:
         begin  
            avst_rx_data_d1_p0    <= (port_data_width == 1) ? {{AVST_DW_BY_FOURX3{1'b0}},axist_rx_tdata[AVST_DW_BY_FOUR-1:0]}: //127:0
                                                              {{(TDATA_WIDTH-AVST_DW_BY_EIGHT){1'b0}},axist_rx_tdata[AVST_DW_BY_EIGHT-1:0]}; //63:0
            avst_rx_tkeep_p0      <= (port_data_width == 1) ? {{NO_BYTES_BY_FOURX3{1'b0}},axist_rx_tkeep[NO_BYTES_BY_FOUR-1:0]}: //48'd0,15:0                                                 
                                                              {{(NO_OF_BYTES-NO_BYTES_BY_EIGHT){1'b0}},axist_rx_tkeep[NO_BYTES_BY_EIGHT-1:0]}; //7:0
                                                              
         end        
         3'd4:
         begin  
            avst_rx_data_d1_p0    <= {{(TDATA_WIDTH-AVST_DW_BY_EIGHT){1'b0}},axist_rx_tdata[AVST_DW_BY_EIGHT-1:0]}; //63:0
            avst_rx_tkeep_p0      <= {{(NO_OF_BYTES-NO_BYTES_BY_EIGHT){1'b0}},axist_rx_tkeep[NO_BYTES_BY_EIGHT-1:0]}; //56'd0,7:0
         end                 
         default: begin 
            avst_rx_data_d1_p0    <= {TDATA_WIDTH{1'b0}};
            avst_rx_tkeep_p0      <= {NO_OF_BYTES{1'b0}};
         end
         endcase
      end  
      
      always @(posedge i_rx_clk_p1) 
      begin
         case (active_port)
         3'd1,
         3'd2:           
         begin  
            avst_rx_data_d1_p1    <= {AVST_DW_BY_EIGHT{1'b0}};   
            avst_rx_tkeep_p1      <= {NO_BYTES_BY_EIGHT{1'b0}}; //8'd0      
         end  
         3'd4:
         begin  
            avst_rx_data_d1_p1    <= axist_rx_tdata[AVST_DW_BY_FOUR-1:AVST_DW_BY_EIGHT]; //127:64
            avst_rx_tkeep_p1      <= axist_rx_tkeep[NO_BYTES_BY_FOUR-1:NO_BYTES_BY_EIGHT]; //15:8
         end                 
         default: begin 
            avst_rx_data_d1_p1    <= {AVST_DW_BY_EIGHT{1'b0}};
            avst_rx_tkeep_p1      <= {NO_BYTES_BY_EIGHT{1'b0}};
         end
         endcase
      end     
      
      always @(posedge i_rx_clk_p2) 
      begin
         case (active_port)
         3'd1:  
         begin  
            avst_rx_data_d1_p2    <= {AVST_DW_BY_FOUR{1'b0}};    
            avst_rx_tkeep_p2      <= {NO_BYTES_BY_FOUR{1'b0}}; //16'd0
         end 
         3'd2:
         begin  
            avst_rx_data_d1_p2    <= (port_data_width == 1) ? axist_rx_tdata[AVST_DW_BY_TWO-1:AVST_DW_BY_FOUR]: //255:128
                                     {{AVST_DW_BY_EIGHT{1'b0}},axist_rx_tdata[AVST_DW_BY_FOUR-1:AVST_DW_BY_EIGHT]}; //127:64        
            avst_rx_tkeep_p2      <= (port_data_width == 1) ? axist_rx_tkeep[NO_BYTES_BY_TWO-1:NO_BYTES_BY_FOUR]: //31:16
                                     {{NO_BYTES_BY_EIGHT{1'b0}},axist_rx_tkeep[NO_BYTES_BY_FOUR-1:NO_BYTES_BY_EIGHT]}; //8'd0, 15:8                                      
         end        
         3'd4:
         begin  
            avst_rx_data_d1_p2    <= {{AVST_DW_BY_EIGHT{1'b0}},axist_rx_tdata[AVST_DW_BY_EIGHTX3-1:AVST_DW_BY_FOUR]}; //191:128
            avst_rx_tkeep_p2      <= {{NO_BYTES_BY_EIGHT{1'b0}},axist_rx_tkeep[NO_BYTES_BY_EIGHTX3-1:NO_BYTES_BY_FOUR]}; //8'd0, 23:16
         end                 
         default: begin 
            avst_rx_data_d1_p2    <= {AVST_DW_BY_FOUR{1'b0}};
            avst_rx_tkeep_p2      <= {NO_BYTES_BY_FOUR{1'b0}}; //16'd0          
         end
         endcase  
      end     
      
      always @(posedge i_rx_clk_p3) 
      begin
         case (active_port)
         3'd1:  
         begin  
            avst_rx_data_d1_p3    <= {AVST_DW_BY_EIGHT{1'b0}};    
            avst_rx_tkeep_p3      <= {NO_BYTES_BY_EIGHT{1'b0}}; //8'd0              
         end 
         3'd2:
         begin  
            avst_rx_data_d1_p3    <= {AVST_DW_BY_EIGHT{1'b0}};   
            avst_rx_tkeep_p3      <= {NO_BYTES_BY_EIGHT{1'b0}}; //8'd0              
         end        
         3'd4:
         begin  
            avst_rx_data_d1_p3    <= axist_rx_tdata[AVST_DW_BY_TWO-1:AVST_DW_BY_EIGHTX3]; //255:192
            avst_rx_tkeep_p3      <= axist_rx_tkeep[NO_BYTES_BY_TWO-1:NO_BYTES_BY_EIGHTX3]; //31:24
         end                 
         default: begin 
            avst_rx_data_d1_p3    <= {AVST_DW_BY_EIGHT{1'b0}};
            avst_rx_tkeep_p3      <= {NO_BYTES_BY_EIGHT{1'b0}}; //8'd0
         end
         endcase
      end      
      
   end   
   
   else if (NUM_MAX_PORTS == 2) begin: TVALID_MUX_2P
   
      always @(posedge i_rx_clk_p0) 
      begin
         case (active_port)
         3'd1: 
         begin  
            avst_rx_data_d1_p0    <= axist_rx_tdata;    
            avst_rx_tkeep_p0      <= axist_rx_tkeep; 
         end 
         3'd2:
         begin  
            avst_rx_data_d1_p0    <= (port_data_width == 1) ? {{AVST_DW_BY_FOURX3{1'b0}},axist_rx_tdata[AVST_DW_BY_FOUR-1:0]}: //127:0
                                                              {{(TDATA_WIDTH-AVST_DW_BY_EIGHT){1'b0}},axist_rx_tdata[AVST_DW_BY_EIGHT-1:0]}; //63:0
            avst_rx_tkeep_p0      <= (port_data_width == 1) ? {{NO_BYTES_BY_FOURX3{1'b0}},axist_rx_tkeep[NO_BYTES_BY_FOUR-1:0]}: //48'd0,15:0
                                                              {{(NO_OF_BYTES-NO_BYTES_BY_EIGHT){1'b0}},axist_rx_tkeep[NO_BYTES_BY_EIGHT-1:0]}; //56'd0,8'd0                                                           
         end                 
         default: begin 
            avst_rx_data_d1_p0    <= {TDATA_WIDTH{1'b0}};
            avst_rx_tkeep_p0      <= {NO_OF_BYTES{1'b0}};
         end
         endcase  
      end  
      
      always @(posedge i_rx_clk_p1) 
      begin
         case (active_port)
         3'd1:  
         begin  
            avst_rx_data_d1_p1    <= {AVST_DW_BY_FOUR{1'b0}};   
            avst_rx_tkeep_p1      <= {NO_BYTES_BY_FOUR{1'b0}};          
         end 
         3'd2:
         begin  
            avst_rx_data_d1_p1    <= (port_data_width == 1) ? axist_rx_tdata[AVST_DW_BY_TWO-1:AVST_DW_BY_FOUR]: //255:128
                                                              {{AVST_DW_BY_EIGHT{1'b0}},axist_rx_tdata[AVST_DW_BY_FOUR-1:AVST_DW_BY_EIGHT]}; //127:64
            avst_rx_tkeep_p1      <= (port_data_width == 1) ? axist_rx_tkeep[NO_BYTES_BY_TWO-1:NO_BYTES_BY_FOUR]: //31:16
                                                              {{NO_BYTES_BY_EIGHT{1'b0}},axist_rx_tkeep[NO_BYTES_BY_FOUR-1:NO_BYTES_BY_EIGHT]}; //8'd0, 15:8                                                              
         end                  
         default: begin 
            avst_rx_data_d1_p1    <= {AVST_DW_BY_FOUR{1'b0}};
            avst_rx_tkeep_p1      <= {NO_BYTES_BY_FOUR{1'b0}};              
         end
         endcase    
      end     
   
   end
   
   else begin : TVALID_MUX_1P
   
      always @(posedge i_rx_clk_p0) 
      begin
         avst_rx_data_d1_p0       <= axist_rx_tdata;    
         avst_rx_tkeep_p0         <= axist_rx_tkeep; 
      end
   end       

end
endgenerate

//// duplicate based on max ports
generate
genvar j,k;

   for (k=0;k<NUM_MAX_PORTS;k=k+1)
   begin : RX_TUSER_PTP_RX_ITS    
      assign  rx_av_st_mac_user[(AVST_MAC_USER_RX*k)+192-1:(k*AVST_MAC_USER_RX)] = i_rx_avst_ptp_rx_its[(k+1)*192-1:(k*192)];        
   end          

if (PORT_CLIENT_IF == 0) 
begin : MAC_SEG_RX_TUSER

if (NUM_MAX_PORTS == 1) begin: RX_TUSER_1P
   assign  rx_av_st_mac_user[AVST_MAC_USER_RX-1    :192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS] = i_rx_mac_error[ERR*NUM_SEG-1:0];         //197:196
   assign  rx_av_st_mac_user[192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:192+NUM_SEG*MAC_STS]  = i_rx_mac_fcs_error[FCS_ERR*NUM_SEG-1:0]; //195:195
   assign  rx_av_st_mac_user[192+NUM_SEG*MAC_STS-1:192]                                  = i_rx_mac_status[MAC_STS*NUM_SEG-1:0];    //194:192
end
else if (NUM_MAX_PORTS == 2) begin: RX_TUSER_2P
   always @ (*)
   begin
      if (active_segment == NUM_SEG) begin //1 active port
        rx_av_st_mac_user[AVST_MAC_USER_RX-1:192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS] = i_rx_mac_error[ERR*NUM_SEG-1:0]; 
        rx_av_st_mac_user[(2*AVST_MAC_USER_RX)-1:AVST_MAC_USER_RX+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS] = {NUM_SEG_ERR_BITS{1'b0}};
        
        rx_av_st_mac_user[192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:192+NUM_SEG*MAC_STS] = i_rx_mac_fcs_error[FCS_ERR*NUM_SEG-1:0];
        rx_av_st_mac_user[AVST_MAC_USER_RX+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:AVST_MAC_USER_RX+192+NUM_SEG*MAC_STS] = {NUM_SEG_FCS_ERR_BITS{1'b0}};
        
        rx_av_st_mac_user[192+NUM_SEG*MAC_STS-1:192] = i_rx_mac_status[MAC_STS*NUM_SEG-1:0]; //194:192
        rx_av_st_mac_user[AVST_MAC_USER_RX+192+NUM_SEG*MAC_STS-1:AVST_MAC_USER_RX+192] = {NUM_SEG_MAC_STS_BITS{1'b0}};  //198+192+3-1:
     end 
     else if(active_segment == NUM_SEG/2) begin //1 or 2 active port 
        rx_av_st_mac_user[(AVST_MAC_USER_RX-1):192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS]= {{NUM_SEG2_ERR_BITS{1'd0}},i_rx_mac_error[NUM_SEG2_ERR_BITS-1:0]};    //P0, 8 seg 
        rx_av_st_mac_user[(2*AVST_MAC_USER_RX)-1:AVST_MAC_USER_RX+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS] = {{NUM_SEG2_ERR_BITS{1'd0}},i_rx_mac_error[NUM_SEG_ERR_BITS-1:NUM_SEG2_ERR_BITS]};    //P1, 8 seg LSB
        
        rx_av_st_mac_user[192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:192+NUM_SEG*MAC_STS]  = {{NUM_SEG2_FCS_ERR_BITS{1'b0}},i_rx_mac_fcs_error[NUM_SEG2_FCS_ERR_BITS-1:0]};
        rx_av_st_mac_user[AVST_MAC_USER_RX+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:AVST_MAC_USER_RX+192+NUM_SEG*MAC_STS] = {{NUM_SEG2_FCS_ERR_BITS{1'b0}},i_rx_mac_fcs_error[NUM_SEG_FCS_ERR_BITS-1:NUM_SEG2_FCS_ERR_BITS]};
        
        rx_av_st_mac_user[192+NUM_SEG*MAC_STS-1:192]= {{NUM_SEG2_MAC_STS_BITS{1'b0}},i_rx_mac_status[NUM_SEG2_MAC_STS_BITS-1:0]};  //tuser_sts
        rx_av_st_mac_user[AVST_MAC_USER_RX+192+NUM_SEG*MAC_STS-1:AVST_MAC_USER_RX+192] = {{NUM_SEG2_MAC_STS_BITS{1'b0}},i_rx_mac_status[NUM_SEG_MAC_STS_BITS-1:NUM_SEG2_MAC_STS_BITS]};
     end
     else //active seg = num_seg/4
     begin
        rx_av_st_mac_user[(AVST_MAC_USER_RX-1):192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS] = {{NUM_SEG_ERR_BITS_1{1'd0}},i_rx_mac_error[NUM_SEG4_ERR_BITS-1:0]};    //P0, 8 seg 
        rx_av_st_mac_user[(2*AVST_MAC_USER_RX)-1:AVST_MAC_USER_RX+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS] = {{NUM_SEG_ERR_BITS_1{1'd0}},i_rx_mac_error[NUM_SEG2_ERR_BITS-1:NUM_SEG4_ERR_BITS]}; 
        
        rx_av_st_mac_user[192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:192+NUM_SEG*MAC_STS] = {{NUM_SEG_FCS_ERR_BITS_1{1'b0}},i_rx_mac_fcs_error[NUM_SEG4_FCS_ERR_BITS-1:0]};
        rx_av_st_mac_user[AVST_MAC_USER_RX+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:AVST_MAC_USER_RX+192+NUM_SEG*MAC_STS]= {{NUM_SEG_FCS_ERR_BITS_1{1'b0}},i_rx_mac_fcs_error[NUM_SEG2_FCS_ERR_BITS-1:NUM_SEG4_FCS_ERR_BITS]};
        
        rx_av_st_mac_user[192+NUM_SEG*MAC_STS-1:192] = {{NUM_SEG_MAC_STS_BITS_1{1'b0}},i_rx_mac_status[NUM_SEG4_MAC_STS_BITS-1:0]};  //tuser_sts
        rx_av_st_mac_user[AVST_MAC_USER_RX+192+NUM_SEG*MAC_STS-1:AVST_MAC_USER_RX+192] = {{NUM_SEG_MAC_STS_BITS_1{1'b0}},i_rx_mac_status[NUM_SEG2_MAC_STS_BITS-1:NUM_SEG4_MAC_STS_BITS]};
     end
  end    
end  
//(NUM_MAX_PORTS == 4)      
else begin: RX_TUSER_4P     
   always @ (*)
   begin
      if (active_segment == NUM_SEG) begin //1 active port
       rx_av_st_mac_user[AVST_MAC_USER_RX-1:192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS] = i_rx_mac_error[ERR*NUM_SEG-1:0]; 
       rx_av_st_mac_user[(2*AVST_MAC_USER_RX)-1:AVST_MAC_USER_RX+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS]     = {NUM_SEG_ERR_BITS{1'b0}};
       rx_av_st_mac_user[(3*AVST_MAC_USER_RX)-1:(2*AVST_MAC_USER_RX)+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS] = {NUM_SEG_ERR_BITS{1'b0}};
       rx_av_st_mac_user[(4*AVST_MAC_USER_RX)-1:(3*AVST_MAC_USER_RX)+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS] = {NUM_SEG_ERR_BITS{1'b0}};

       rx_av_st_mac_user[192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:192+NUM_SEG*MAC_STS] = i_rx_mac_fcs_error[FCS_ERR*NUM_SEG-1:0];
       rx_av_st_mac_user[AVST_MAC_USER_RX+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:AVST_MAC_USER_RX+192+NUM_SEG*MAC_STS] = {NUM_SEG_FCS_ERR_BITS{1'b0}};
       rx_av_st_mac_user[(2*AVST_MAC_USER_RX)+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:(2*AVST_MAC_USER_RX)+192+NUM_SEG*MAC_STS] = {NUM_SEG_FCS_ERR_BITS{1'b0}};
       rx_av_st_mac_user[(3*AVST_MAC_USER_RX)+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:(3*AVST_MAC_USER_RX)+192+NUM_SEG*MAC_STS] = {NUM_SEG_FCS_ERR_BITS{1'b0}};
       
       rx_av_st_mac_user[192+NUM_SEG*MAC_STS-1:192] = i_rx_mac_status[MAC_STS*NUM_SEG-1:0];  
       rx_av_st_mac_user[AVST_MAC_USER_RX+192+NUM_SEG*MAC_STS-1:AVST_MAC_USER_RX+192] = {NUM_SEG_MAC_STS_BITS{1'b0}};  
       rx_av_st_mac_user[(2*AVST_MAC_USER_RX)+192+NUM_SEG*MAC_STS-1:(2*AVST_MAC_USER_RX)+192] = {NUM_SEG_MAC_STS_BITS{1'b0}};  
       rx_av_st_mac_user[(3*AVST_MAC_USER_RX)+192+NUM_SEG*MAC_STS-1:(3*AVST_MAC_USER_RX)+192] = {NUM_SEG_MAC_STS_BITS{1'b0}};  
      end
      else if(active_segment == NUM_SEG/2) begin //1 or 2 active port 
        rx_av_st_mac_user[(AVST_MAC_USER_RX)-1:192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS] = {{NUM_SEG2_ERR_BITS{1'd0}},i_rx_mac_error[NUM_SEG2_ERR_BITS-1:0]};    //P0, 8 seg 
        rx_av_st_mac_user[(2*AVST_MAC_USER_RX)-1:AVST_MAC_USER_RX+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS] = {NUM_SEG_ERR_BITS{1'b0}};   
        rx_av_st_mac_user[(3*AVST_MAC_USER_RX)-1:(2*AVST_MAC_USER_RX)+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS] = {{NUM_SEG2_ERR_BITS{1'd0}},i_rx_mac_error[NUM_SEG_ERR_BITS-1:NUM_SEG2_ERR_BITS]};    //P1, 8 seg LSB
        rx_av_st_mac_user[(4*AVST_MAC_USER_RX)-1:(3*AVST_MAC_USER_RX)+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS] = {NUM_SEG_ERR_BITS{1'b0}};

        rx_av_st_mac_user[192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:192+NUM_SEG*MAC_STS] = {{NUM_SEG2_FCS_ERR_BITS{1'b0}},i_rx_mac_fcs_error[NUM_SEG2_FCS_ERR_BITS-1:0]};
        rx_av_st_mac_user[AVST_MAC_USER_RX+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:AVST_MAC_USER_RX+192+NUM_SEG*MAC_STS] = {NUM_SEG_FCS_ERR_BITS{1'b0}}; 
        rx_av_st_mac_user[(2*AVST_MAC_USER_RX)+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:(2*AVST_MAC_USER_RX)+192+NUM_SEG*MAC_STS] = {{NUM_SEG2_FCS_ERR_BITS{1'b0}},i_rx_mac_fcs_error[NUM_SEG_FCS_ERR_BITS-1:NUM_SEG2_FCS_ERR_BITS]};
        rx_av_st_mac_user[(3*AVST_MAC_USER_RX)+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:(3*AVST_MAC_USER_RX)+192+NUM_SEG*MAC_STS] = {NUM_SEG_FCS_ERR_BITS{1'b0}};
        
        rx_av_st_mac_user[192+NUM_SEG*MAC_STS-1:192] = {{NUM_SEG2_MAC_STS_BITS{1'b0}},i_rx_mac_status[NUM_SEG2_MAC_STS_BITS-1:0]};  //tuser_sts
        rx_av_st_mac_user[AVST_MAC_USER_RX+192+NUM_SEG*MAC_STS-1:AVST_MAC_USER_RX+192] = {NUM_SEG_MAC_STS_BITS{1'b0}};  
        rx_av_st_mac_user[(2*AVST_MAC_USER_RX)+192+NUM_SEG*MAC_STS-1:(2*AVST_MAC_USER_RX)+192] = {{NUM_SEG2_MAC_STS_BITS{1'b0}},i_rx_mac_status[NUM_SEG_MAC_STS_BITS-1:NUM_SEG2_MAC_STS_BITS]};
        rx_av_st_mac_user[(3*AVST_MAC_USER_RX)+192+NUM_SEG*MAC_STS-1:(3*AVST_MAC_USER_RX)+192] = {NUM_SEG_MAC_STS_BITS{1'b0}};  
       end
       else //active seg = num_seg/4
       begin
          rx_av_st_mac_user[(AVST_MAC_USER_RX-1):192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS] = {{NUM_SEG_ERR_BITS_1{1'd0}},i_rx_mac_error[NUM_SEG4_ERR_BITS-1:0]};    //P0, 8 seg 
          rx_av_st_mac_user[(2*AVST_MAC_USER_RX)-1:AVST_MAC_USER_RX+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS] = {{NUM_SEG_ERR_BITS_1{1'd0}},i_rx_mac_error[NUM_SEG2_ERR_BITS-1:NUM_SEG4_ERR_BITS]}; 
          rx_av_st_mac_user[(3*AVST_MAC_USER_RX)-1:(2*AVST_MAC_USER_RX)+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS] = {{NUM_SEG_ERR_BITS_1{1'd0}},i_rx_mac_error[NUM_SEG_ERR_BITS_1-1:NUM_SEG2_ERR_BITS]}; 
          rx_av_st_mac_user[(4*AVST_MAC_USER_RX)-1:(3*AVST_MAC_USER_RX)+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS] = {{NUM_SEG_ERR_BITS_1{1'd0}},i_rx_mac_error[NUM_SEG_ERR_BITS-1:NUM_SEG_ERR_BITS_1]}; 
          
          rx_av_st_mac_user[192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:192+NUM_SEG*MAC_STS] = {{NUM_SEG_FCS_ERR_BITS_1{1'b0}},i_rx_mac_fcs_error[NUM_SEG4_FCS_ERR_BITS-1:0]};
          rx_av_st_mac_user[AVST_MAC_USER_RX+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:AVST_MAC_USER_RX+192+NUM_SEG*MAC_STS] = {{NUM_SEG_FCS_ERR_BITS_1{1'b0}},i_rx_mac_fcs_error[NUM_SEG2_FCS_ERR_BITS-1:NUM_SEG4_FCS_ERR_BITS]};
          rx_av_st_mac_user[(2*AVST_MAC_USER_RX)+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:(2*AVST_MAC_USER_RX)+192+NUM_SEG*MAC_STS] = {{NUM_SEG_FCS_ERR_BITS_1{1'b0}},i_rx_mac_fcs_error[NUM_SEG_FCS_ERR_BITS_1-1:NUM_SEG2_FCS_ERR_BITS]};
          rx_av_st_mac_user[(3*AVST_MAC_USER_RX)+192+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:(3*AVST_MAC_USER_RX)+192+NUM_SEG*MAC_STS] = {{NUM_SEG_FCS_ERR_BITS_1{1'b0}},i_rx_mac_fcs_error[NUM_SEG_FCS_ERR_BITS-1:NUM_SEG_FCS_ERR_BITS_1]};
          
          rx_av_st_mac_user[192+NUM_SEG*MAC_STS-1:192] = {{NUM_SEG_MAC_STS_BITS_1{1'b0}},i_rx_mac_status[NUM_SEG4_MAC_STS_BITS-1:0]};  //tuser_sts
          rx_av_st_mac_user[AVST_MAC_USER_RX+192+NUM_SEG*MAC_STS-1:AVST_MAC_USER_RX+192] = {{NUM_SEG_MAC_STS_BITS_1{1'b0}},i_rx_mac_status[NUM_SEG2_MAC_STS_BITS-1:NUM_SEG4_MAC_STS_BITS]};
          rx_av_st_mac_user[(2*AVST_MAC_USER_RX)+192+NUM_SEG*MAC_STS-1:(2*AVST_MAC_USER_RX)+192] = {{NUM_SEG_MAC_STS_BITS_1{1'b0}},i_rx_mac_status[NUM_SEG_MAC_STS_BITS_1-1:NUM_SEG2_MAC_STS_BITS]};  
          rx_av_st_mac_user[(3*AVST_MAC_USER_RX)+192+NUM_SEG*MAC_STS-1:(3*AVST_MAC_USER_RX)+192] = {{NUM_SEG_MAC_STS_BITS_1{1'b0}},i_rx_mac_status[NUM_SEG_MAC_STS_BITS-1:NUM_SEG_MAC_STS_BITS_1]}; 
       end
    end    
end
end
else
begin : SOPA_RX_TUSER 
   for (j=0;j<NUM_MAX_PORTS;j=j+1)
   begin : RX_TUSER_SOP   
      assign  rx_av_st_user[(TUSER_WIDTH_RX*(j+1))-1:(TUSER_WIDTH_RX*j)+47]  = i_rx_avst_ptp_rx_its[((j*2)+1)*96-1:(j*2*96)]; //TUSER_WIDTH_RX = 143 for sopa 142:47<= 95:0 285:190 <= 287:192  
      assign  rx_av_st_user[(TUSER_WIDTH_RX*j)+46:(TUSER_WIDTH_RX*j)+41]  = i_rx_avst_error[(j+1)*6-1:(j*6)]; //TUSER_WIDTH_RX = 143 for sopa 46:41  189:
      assign  rx_av_st_user[(TUSER_WIDTH_RX*j)+40]  = i_rxstatus_avst_valid[j]; //1 bit 40
      assign  rx_av_st_user[(TUSER_WIDTH_RX*j)+39:(TUSER_WIDTH_RX*j)]  = i_rxstatus_avst_data[(j+1)*40-1:(j*40)]; //40 bits 39:0

      assign  rx_avst_ptp_rx_its[(j+1)*96-1:(j*96)]  = axist_rx_tuser[(TUSER_WIDTH_RX*(j+1))-1:(TUSER_WIDTH_RX*j)+47];
      assign  rx_avst_error[(j+1)*6-1:(j*6)]         = axist_rx_tuser[(TUSER_WIDTH_RX*j)+46:(TUSER_WIDTH_RX*j)+41];
      assign  rxstatus_avst_valid[j]                 = axist_rx_tuser[(TUSER_WIDTH_RX*j)+40];
      assign  rxstatus_avst_data[(j+1)*40-1:(j*40)]  = axist_rx_tuser[(TUSER_WIDTH_RX*j)+39:(TUSER_WIDTH_RX*j)];     
   end 
end   
endgenerate 

// assign  rx_av_st_user[46:41]  = i_rx_avst_error; //6 bits 
// assign  rx_av_st_user[40:40]  = i_rxstatus_avst_valid; //1 bits 
// assign  rx_av_st_user[39:0]   = i_rxstatus_avst_data; //40 bits 

assign  rx_avst_user = (PORT_CLIENT_IF == 0) ? rx_av_st_mac_user : rx_av_st_user;

    // always @(posedge i_rx_clk or negedge i_rx_rst_n) begin //23.2
        // if (~i_rx_rst_n) begin
           // rx_mac_error_d1        <= {NUM_SEG_ERR_BITS{1'b0}};
           // rx_mac_error_d2        <= {NUM_SEG_ERR_BITS{1'b0}};
           // rx_mac_fcs_error_d1    <= {NUM_SEG_FCS_ERR_BITS{1'b0}};
           // rx_mac_fcs_error_d2    <= {NUM_SEG_FCS_ERR_BITS{1'b0}};
           // rx_mac_status_d1       <= {NUM_SEG_MAC_STS_BITS{1'b0}};
           // rx_mac_status_d2       <= {NUM_SEG_MAC_STS_BITS{1'b0}};
           // rx_avst_ptp_rx_its_d1  <= {192*NUM_MAX_PORTS{1'b0}};
           // rx_avst_ptp_rx_its_d2  <= {192*NUM_MAX_PORTS{1'b0}};
        // end
        // else
        // begin
           // rx_mac_error_d1        <= i_rx_mac_error;
           // rx_mac_error_d2        <= rx_mac_error_d1;
           // rx_mac_fcs_error_d1    <= i_rx_mac_fcs_error;
           // rx_mac_fcs_error_d2    <= rx_mac_fcs_error_d1;
           // rx_mac_status_d1       <= i_rx_mac_status;
           // rx_mac_status_d2       <= rx_mac_status_d1;
           // rx_avst_ptp_rx_its_d1  <= i_rx_avst_ptp_rx_its;
           // rx_avst_ptp_rx_its_d2  <= rx_avst_ptp_rx_its_d1;
        // end  
     // end   

    always @(posedge i_rx_clk_p0) begin //used by MS 
       rx_mac_error_d1        <= i_rx_mac_error;
       rx_mac_error_d2        <= rx_mac_error_d1;
       rx_mac_fcs_error_d1    <= i_rx_mac_fcs_error;
       rx_mac_fcs_error_d2    <= rx_mac_fcs_error_d1;
       rx_mac_status_d1       <= i_rx_mac_status;
       rx_mac_status_d2       <= rx_mac_status_d1;
       rx_avst_ptp_rx_its_d1  <= i_rx_avst_ptp_rx_its;
       rx_avst_ptp_rx_its_d2  <= rx_avst_ptp_rx_its_d1;
    end   
     
    // always @(posedge i_rx_clk or negedge i_rx_rst_n) begin //23.1
        // if (~i_rx_rst_n) begin
           // rx_avst_error_d1        <= {6*NUM_MAX_PORTS{1'b0}};
           // rx_avst_error_d2        <= {6*NUM_MAX_PORTS{1'b0}};
           // rxstatus_avst_valid_d1  <= {NUM_MAX_PORTS{1'b0}};
           // rxstatus_avst_valid_d2  <= {NUM_MAX_PORTS{1'b0}};
           // rxstatus_avst_data_d1   <= {40*NUM_MAX_PORTS{1'b0}};
           // rxstatus_avst_data_d2   <= {40*NUM_MAX_PORTS{1'b0}};
        // end
        // else
        // begin
           // rx_avst_error_d1        <= i_rx_avst_error;
           // rx_avst_error_d2        <= rx_avst_error_d1;
           // rxstatus_avst_valid_d1  <= i_rxstatus_avst_valid;
           // rxstatus_avst_valid_d2  <= rxstatus_avst_valid_d1;
           // rxstatus_avst_data_d1   <= i_rxstatus_avst_data;
           // rxstatus_avst_data_d2   <= rxstatus_avst_data_d1;
        // end  
     // end    
     
// duplicate maxseg 16 max port2  rxmac error [7:0]  
generate if (PORT_CLIENT_IF == 0)
begin : MAC_SEG_IF

    // assign  rx_mac_error            = axist_rx_tuser[AVST_MAC_USER_RX-1:96+96+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS];
    // assign  rx_mac_fcs_error        = axist_rx_tuser[96+96+NUM_SEG*FCS_ERR+NUM_SEG*MAC_STS-1:96+96+NUM_SEG*MAC_STS];
    // assign  rx_mac_status           = axist_rx_tuser[96+96+NUM_SEG*MAC_STS-1:96+96];
    // assign  rx_avst_mac_ptp_rx_its  = axist_rx_tuser[192-1:0];  
    
genvar j,k; 
    for (j=0; j<NUM_SEG; j=j+1) 
    begin: MAC_SEGMENTED_IF
        // always @(posedge i_rx_clk or negedge i_rx_rst_n) begin //remove reset
            // if (~i_rx_rst_n) begin
                // o_axi_st_rx_tuser_client[(j+1)*7-1:7*j] <= 7'd0;
            // end
            // else if (axist_rx_tlast_segment[j]) begin
           always @(posedge i_rx_clk_p0) begin
              if (axist_rx_tlast_segment[j]) begin
                if (rx_mac_error_d2[(j+1)*ERR-1:ERR*j] == 2'd1)
                    o_axi_st_rx_tuser_client[(j+1)*7-1:7*j] <=   {5'b0,rx_mac_fcs_error_d2[j],1'b1};    //malformed,
                    
                else if (rx_mac_error_d2[(j+1)*ERR-1:ERR*j] == 2'd2)
                    o_axi_st_rx_tuser_client[(j+1)*7-1:7*j] <=   {5'b1,rx_mac_fcs_error_d2[j],1'b0};    //undersized or oversized
                    
                else if (rx_mac_error_d2[(j+1)*ERR-1:ERR*j] == 2'd3)
                    o_axi_st_rx_tuser_client[(j+1)*7-1:7*j] <=   {5'b100,rx_mac_fcs_error_d2[j],1'b0};  //length error
                    
                else 
                    o_axi_st_rx_tuser_client[(j+1)*7-1:7*j] <=   {5'b0,rx_mac_fcs_error_d2[j],1'b0};    //FCS error,            
              end
              else
                 o_axi_st_rx_tuser_client[(j+1)*7-1:7*j] <= '0;
           end
           
           // always @(posedge i_rx_clk or negedge i_rx_rst_n) begin 
               // if (~i_rx_rst_n) begin
                   // o_axi_st_rx_tuser_sts[(j+1)*5-1:5*j] <= 5'b0; 
               // end
               // else if (axist_rx_tlast_segment[j]) begin
              always @(posedge i_rx_clk_p0) begin 
                 if (axist_rx_tlast_segment[j]) begin
                   if (rx_mac_status_d2[(j+1)*MAC_STS-1:MAC_STS*j] == 3'd5)
                       o_axi_st_rx_tuser_sts[(j+1)*5-1:5*j] <= 5'b00101;     //SVLAN/VLAN Frame
                       
                   else if (rx_mac_status_d2[(j+1)*MAC_STS-1:MAC_STS*j] == 3'd4)
                       o_axi_st_rx_tuser_sts[(j+1)*5-1:5*j] <= 5'b00100;     //SFC/PFC frame
                       
                   else if (rx_mac_status_d2[(j+1)*MAC_STS-1:MAC_STS*j] == 3'd7)
                       o_axi_st_rx_tuser_sts[(j+1)*5-1:5*j] <= 5'b00111;     //FC frame (control frame ie Length/Type=0x8808, but not sfc/pfc)
                       
                   else if (rx_mac_status_d2[(j+1)*MAC_STS-1:MAC_STS*j] == 3'd6)
                       o_axi_st_rx_tuser_sts[(j+1)*5-1:5*j] <= 5'b00110;     //Illegal length type frame
                       
                   else if (rx_mac_status_d2[(j+1)*MAC_STS-1:MAC_STS*j] == 3'd1)
                       o_axi_st_rx_tuser_sts[(j+1)*5-1:5*j] <= 5'b00001;       //Ethernet type that was not FC
                       
                   else if (rx_mac_status_d2[(j+1)*MAC_STS-1:MAC_STS*j] == 3'd2)
                       o_axi_st_rx_tuser_sts[(j+1)*5-1:5*j] <= 5'b00010;     //BCAST or MCAST frame
                       
                   else if (rx_mac_status_d2[(j+1)*MAC_STS-1:MAC_STS*j] == 3'd3)
                       o_axi_st_rx_tuser_sts[(j+1)*5-1:5*j] <= 5'b00011;     //PTP frame (Length/Type = 0x88F7)
                       
                   else if(rx_mac_status_d2[(j+1)*MAC_STS-1:MAC_STS*j] == 3'd0)
                       o_axi_st_rx_tuser_sts[(j+1)*5-1:5*j] <= 5'b00000;     //had a valid length (was a data frame)
                       
                   else 
                       o_axi_st_rx_tuser_sts[(j+1)*5-1:5*j] <= 5'b00000;   
               end
               else 
                  o_axi_st_rx_tuser_sts[(j+1)*5-1:5*j] <= '0;
           end 
    end

    for (k=0; k<NUM_MAX_PORTS; k=k+1)
    begin: RX_INGRTS_MS     
    always @(posedge i_rx_clk_p0 or negedge s_rx_rst_n[k]) begin
       if (~s_rx_rst_n[k]) begin
          o_axi_st_rx_ingrts0_tdata[(k+1)*96-1:(k*96)] <= 96'b0;
          o_axi_st_rx_ingrts1_tdata[(k+1)*96-1:(k*96)] <= 96'b0;
          o_axi_st_rx_ingrts0_tvalid[k] <= 1'b0;         
          o_axi_st_rx_ingrts1_tvalid[k] <= 1'b0;         
          // o_axi_st_rx_tuser_sts_extended <= 32'd0;
       end
       else begin
            o_axi_st_rx_ingrts0_tdata[(k+1)*96-1:(k*96)] <= rx_avst_ptp_rx_its_d2[(k*2+1)*96-1:(k*2*96)];
            o_axi_st_rx_ingrts1_tdata[(k+1)*96-1:(k*96)] <= rx_avst_ptp_rx_its_d2[(k*2+2)*96-1:((k*2+1)*96)];
            o_axi_st_rx_ingrts0_tvalid[k] <= axist_rx_tuser_valid[k];
            o_axi_st_rx_ingrts1_tvalid[k] <= axist_rx_tuser_valid_p2[k];
            // o_axi_st_rx_tuser_sts_extended <= 32'd0;
       end
    end
    end
    
    always_comb begin
       o_axi_st_rx_tuser_sts_extended = 32'd0;
    end

end
else if ((PORT_CLIENT_IF == 1) && (ASYNC_ADAPTERS_EN == 0)) begin: SOP_ALIGNED_IF
genvar m,n;

for (m=0;m<NUM_MAX_PORTS;m=m+1)
    begin: SOPA_TUSER
    always @(posedge i_rx_clk_p0 or negedge s_rx_rst_n[m]) begin
        if (~s_rx_rst_n[m]) begin
            // o_axi_st_rx_tuser_client <= {NUM_SEG{7'b0}};
            o_axi_st_rx_tuser_client[(m+1)*7-1:7*m] <= 7'd0;
            // o_axi_st_rx_tuser_sts <= {NUM_SEG{5'b0}}; 
            o_axi_st_rx_tuser_sts[(m+1)*5-1:5*m] <= 5'd0; 
        end
        else if (TILES == "E") begin
            if (axist_rx_tlast && axist_rx_tvalid) begin
                // o_axi_st_rx_tuser_client <= {2'b00,rx_avst_error[4:0]};
                o_axi_st_rx_tuser_client <= {{(RX_TUSER_CLIENT_WIDTH-5){1'b0}},rx_avst_error[4:0]};
            end
            if  (rxstatus_avst_valid && axist_rx_tlast) begin
                if (rxstatus_avst_data[32] || rxstatus_avst_data[33])            //vlan 
                    o_axi_st_rx_tuser_sts <= {{(RX_TUSER_CLIENT_WIDTH-5){1'b0}},5'b0101};   // {{(RX_TUSER_STATS_WIDTH-5){1'b0},{4'b0101}} }    
                else if (rxstatus_avst_data[35] == 1'b1)           //pause/SFC
                    o_axi_st_rx_tuser_sts <= {{(RX_TUSER_CLIENT_WIDTH-5){1'b0}},5'b1001};     
                else if (rxstatus_avst_data[34] == 1'b1)          //control frame
                    o_axi_st_rx_tuser_sts <= {{(RX_TUSER_CLIENT_WIDTH-5){1'b0}},5'b0111};          
//              else if (rxstatus_avst_data[36] == 1'b1)
//                  o_axi_st_rx_tuser_sts <= 5'b0;     
//              else if (rxstatus_avst_data[37] == 1'b1)
//                  o_axi_st_rx_tuser_sts <= 5'd5;     
                else if (rxstatus_avst_data[39] == 1'b1)                //PFC
                    o_axi_st_rx_tuser_sts <= {{(RX_TUSER_CLIENT_WIDTH-5){1'b0}},5'b0100};     
                else 
                    o_axi_st_rx_tuser_sts <= {{(RX_TUSER_CLIENT_WIDTH-5){1'b0}},5'b0000};     
            end
        end 
        else begin  //F TILE     /////need to ckeck 
            if (axist_rx_tlast[m] && axist_rx_tvalid[m]) begin
                o_axi_st_rx_tuser_client[(m+1)*7-1:7*m] <= {1'b0, rx_avst_error[(m+1)*6-1:6*m]};
            end
            if  (rxstatus_avst_valid[m] && axist_rx_tlast[m]) begin
                if (rxstatus_avst_data[(m*40)+33] == 1'b1)               //vlan 
                    o_axi_st_rx_tuser_sts[(m+1)*5-1:(m*5)] <= 5'b00101;           
                else if (rxstatus_avst_data[(m*40)+35] == 1'b1)            //pause/SFC  
                    o_axi_st_rx_tuser_sts[(m+1)*5-1:(m*5)] <= 5'b00100; //1001 --> 0100             
                else if (rxstatus_avst_data[(m*40)+34] == 1'b1)           //control frame
                    o_axi_st_rx_tuser_sts[(m+1)*5-1:(m*5)] <= 5'b00111;          
                //else if (rxstatus_avst_data[36] == 1'b1)
                    //o_axi_st_rx_tuser_sts <= 5'b0;     /////TBD
                else if (rxstatus_avst_data[(m*40)+37] == 1'b1)          ///BCAST/MCAST
                    o_axi_st_rx_tuser_sts[(m+1)*5-1:(m*5)] <= 5'b00010;     
                //else if (rxstatus_avst_data[39] == 1'b1)
                    //o_axi_st_rx_tuser_sts <= 5'b0100;   
                else 
                    o_axi_st_rx_tuser_sts[(m+1)*5-1:(m*5)] <= {(RX_TUSER_STATS_WIDTH){1'b0}};     
            end
        end
    end
end
    for (n=0;n<NUM_MAX_PORTS;n=n+1)
    begin : RX_INGTTS_MS  
    always @(posedge i_rx_clk_p0 or negedge s_rx_rst_n[n]) begin
        if (~s_rx_rst_n[n]) begin
            o_axi_st_rx_ingrts0_tdata[(n+1)*96-1:(n*96)] <= 96'd0;
            o_axi_st_rx_ingrts1_tdata[(n+1)*96-1:(n*96)] <= 96'd0;
            o_axi_st_rx_ingrts0_tvalid[n]     <= 1'b0;
            o_axi_st_rx_ingrts1_tvalid[n]     <= 1'b0;
            // o_axi_st_rx_tuser_sts_extended    <= 32'b0;        
        end
        else begin
            o_axi_st_rx_ingrts0_tdata[(n+1)*96-1:(n*96)]  <= rx_avst_ptp_rx_its[(n+1)*96-1:(n*96)];
            // o_axi_st_rx_ingrts0_tdata[(n+1)*96-1:(n*96)]  <= rx_avst_ptp_rx_its_d2[(n*2+1)*96-1:(n*2*96)];
            o_axi_st_rx_ingrts1_tdata[(n+1)*96-1:(n*96)]  <= 96'b0;
            o_axi_st_rx_ingrts0_tvalid[n]                 <= axist_rx_tuser_valid[n];
            o_axi_st_rx_ingrts1_tvalid[n]                 <= 1'b0;
            // o_axi_st_rx_tuser_sts_extended                <= 32'b0;
        end
    end
    end
    
    
    always_comb begin
       o_axi_st_rx_tuser_sts_extended = 32'd0;
    end 

end 
else begin: SOP_ALIGNED_IF_ASYNC
genvar m,n;

for (m=0;m<NUM_MAX_PORTS;m=m+1)
    begin: SOPA_TUSER
    always @(posedge s_rx_clk[m] or negedge s_rx_rst_n[m]) begin
        if (~s_rx_rst_n[m]) begin
            // o_axi_st_rx_tuser_client <= {NUM_SEG{7'b0}};
            o_axi_st_rx_tuser_client[(m+1)*7-1:7*m] <= 7'd0;
            // o_axi_st_rx_tuser_sts <= {NUM_SEG{5'b0}}; 
            o_axi_st_rx_tuser_sts[(m+1)*5-1:5*m] <= 5'd0; 
        end
        else if (TILES == "E") begin
            if (axist_rx_tlast && axist_rx_tvalid) begin
                // o_axi_st_rx_tuser_client <= {2'b00,rx_avst_error[4:0]};
                o_axi_st_rx_tuser_client <= {{(RX_TUSER_CLIENT_WIDTH-5){1'b0}},rx_avst_error[4:0]};
            end
            if  (rxstatus_avst_valid && axist_rx_tlast) begin
                if (rxstatus_avst_data[32] || rxstatus_avst_data[33])            //vlan 
                    o_axi_st_rx_tuser_sts <= {{(RX_TUSER_CLIENT_WIDTH-5){1'b0}},5'b0101};   // {{(RX_TUSER_STATS_WIDTH-5){1'b0},{4'b0101}} }    
                else if (rxstatus_avst_data[35] == 1'b1)           //pause/SFC
                    o_axi_st_rx_tuser_sts <= {{(RX_TUSER_CLIENT_WIDTH-5){1'b0}},5'b1001};     
                else if (rxstatus_avst_data[34] == 1'b1)          //control frame
                    o_axi_st_rx_tuser_sts <= {{(RX_TUSER_CLIENT_WIDTH-5){1'b0}},5'b0111};          
//              else if (rxstatus_avst_data[36] == 1'b1)
//                  o_axi_st_rx_tuser_sts <= 5'b0;     
//              else if (rxstatus_avst_data[37] == 1'b1)
//                  o_axi_st_rx_tuser_sts <= 5'd5;     
                else if (rxstatus_avst_data[39] == 1'b1)                //PFC
                    o_axi_st_rx_tuser_sts <= {{(RX_TUSER_CLIENT_WIDTH-5){1'b0}},5'b0100};     
                else 
                    o_axi_st_rx_tuser_sts <= {{(RX_TUSER_CLIENT_WIDTH-5){1'b0}},5'b0000};     
            end
        end 
        else begin  //F TILE     /////need to ckeck 
            if (axist_rx_tlast[m] && axist_rx_tvalid[m]) begin
                o_axi_st_rx_tuser_client[(m+1)*7-1:7*m] <= {1'b0, rx_avst_error[(m+1)*6-1:6*m]};
            end
            if  (rxstatus_avst_valid[m] && axist_rx_tlast[m]) begin
                if (rxstatus_avst_data[(m*40)+33] == 1'b1)               //vlan 
                    o_axi_st_rx_tuser_sts[(m+1)*5-1:(m*5)] <= 5'b00101;           
                else if (rxstatus_avst_data[(m*40)+35] == 1'b1)            //pause/SFC  
                    o_axi_st_rx_tuser_sts[(m+1)*5-1:(m*5)] <= 5'b00100; //1001 --> 0100             
                else if (rxstatus_avst_data[(m*40)+34] == 1'b1)           //control frame
                    o_axi_st_rx_tuser_sts[(m+1)*5-1:(m*5)] <= 5'b00111;          
                //else if (rxstatus_avst_data[36] == 1'b1)
                    //o_axi_st_rx_tuser_sts <= 5'b0;     /////TBD
                else if (rxstatus_avst_data[(m*40)+37] == 1'b1)          ///BCAST/MCAST
                    o_axi_st_rx_tuser_sts[(m+1)*5-1:(m*5)] <= 5'b00010;     
                //else if (rxstatus_avst_data[39] == 1'b1)
                    //o_axi_st_rx_tuser_sts <= 5'b0100;   
                else 
                    o_axi_st_rx_tuser_sts[(m+1)*5-1:(m*5)] <= {(RX_TUSER_STATS_WIDTH){1'b0}};     
            end
        end
    end
end	

    for (n=0;n<NUM_MAX_PORTS;n=n+1)
    begin : RX_INGTTS_MS  
    always @(posedge s_rx_clk[n] or negedge s_rx_rst_n[n]) begin
        if (~s_rx_rst_n[n]) begin
            o_axi_st_rx_ingrts0_tdata[(n+1)*96-1:(n*96)] <= 96'd0;
            o_axi_st_rx_ingrts1_tdata[(n+1)*96-1:(n*96)] <= 96'd0;
            o_axi_st_rx_ingrts0_tvalid[n]     <= 1'b0;
            o_axi_st_rx_ingrts1_tvalid[n]     <= 1'b0;
            // o_axi_st_rx_tuser_sts_extended    <= 32'b0;        
        end
        else begin
            o_axi_st_rx_ingrts0_tdata[(n+1)*96-1:(n*96)]  <= rx_avst_ptp_rx_its[(n+1)*96-1:(n*96)];
            // o_axi_st_rx_ingrts0_tdata[(n+1)*96-1:(n*96)]  <= rx_avst_ptp_rx_its_d2[(n*2+1)*96-1:(n*2*96)];
            o_axi_st_rx_ingrts1_tdata[(n+1)*96-1:(n*96)]  <= 96'b0;
            o_axi_st_rx_ingrts0_tvalid[n]                 <= axist_rx_tuser_valid[n];
            o_axi_st_rx_ingrts1_tvalid[n]                 <= 1'b0;
            // o_axi_st_rx_tuser_sts_extended                <= 32'b0;
        end
    end
end 

    always_comb begin
       o_axi_st_rx_tuser_sts_extended = 32'd0;
    end

end 

endgenerate

generate
begin
if (DR_ENABLE == 0)                    
begin:NON_DR
        always_comb begin //NON_DR 
              active_port           = NUM_MAX_PORTS; //1
              active_segment        = (NUM_SEG <= 4)? NUM_SEG: (NUM_SEG == 8)? 3'd5: 3'd6;
              port_data_width       = (TDATA_WIDTH == 64)? 3'd0 : (TDATA_WIDTH == 128)? 3'd1 : (TDATA_WIDTH == 512)? 3'd2 : 3'd3; //3 - PPT data width = 256 bits                                                      
              o_speed_sel           = (PORT_PROFILE == "10GbE")? 6'b010100: (PORT_PROFILE == "25GbE")? 6'b010101: (PORT_PROFILE == "40GCAUI-4")? 6'b010110:
                                       (PORT_PROFILE == "50GAUI-2")? 6'b010111: (PORT_PROFILE == "50GAUI-1")? 6'b011000: (PORT_PROFILE == "100GAUI-1")? 6'b011001:
                                       (PORT_PROFILE == "100GAUI-2")? 6'b011010: (PORT_PROFILE == "100GCAUI-4")? 6'b011011: (PORT_PROFILE == "200GAUI-2")? 6'b011100:
                                       (PORT_PROFILE == "200GAUI-4")? 6'b011101: (PORT_PROFILE == "200GAUI-8")? 6'b011110: (PORT_PROFILE == "400GAUI-4")? 6'b011111: 6'b100000;
              o_data_width          = (TDATA_WIDTH == 64)? 3'b001: (TDATA_WIDTH == 128)? 3'b010: (TDATA_WIDTH == 256)? 3'b011: 
                                       (TDATA_WIDTH == 512)? 3'b100: 3'b101;                                                   
           end 
        end 
     
else if (PORT_PROFILE == "25GbE")                    
begin:PROFILE_25GbE
        always @(*) begin // FGT_25GE_1 
              case (i_profile_sel_reg) // [5:4] = active ports, [3:2]-active lanes, [1:0] - sum of BW
              6'b000000: begin // 1x25GE-1/10GE-1
                            active_port          = 3'd1;
                            active_segment       = 3'd1;
                            port_data_width      = 3'd0; //64 bits 
                            o_speed_sel          = 6'b010101;
                            o_data_width         = 3'b001; 
                         end
              default:   begin
                            active_port          = 3'd0;
                            active_segment       = 3'd0;
                            port_data_width      = 3'd0; 
                            o_speed_sel          = 6'd0;    
                            o_data_width         = 3'd0;                          
                         end
              endcase
           end
        end

else if (PORT_PROFILE == "50GAUI-1")               
begin:PROFILE_50GAUI_1 
        always @(*) begin //FGT/FHT - 50GE_1 
              case (i_profile_sel_reg) 
              6'b000000: begin // 1x50GE-1
                           active_port            = 3'd1;
                           active_segment         = 3'd2;
                           port_data_width        = 3'd1; //128 bits 
                           o_speed_sel            = 6'b011000;
                           o_data_width           = 3'b010; 
                         end                      
              6'b000001: begin // 1x25GE-1/10GE-1 
                           active_port            = 3'd1;
                           active_segment         = 3'd1;
                           port_data_width        = 3'd0; //64 bits
                           o_speed_sel            = 6'b010101;
                           o_data_width           = 3'b001; 
                         end                      
              default:   begin                    
                           active_port            = 3'd0;
                           active_segment         = 3'd0;
                           port_data_width        = 3'd1; 
                           o_speed_sel            = 6'd0;   
                           o_data_width           = 3'd0;
                         end
              endcase
           end
        end

else if ( PORT_PROFILE == "100GCAUI-4")              
begin:PROFILE_100GCAUI_4    
        always @(*) begin //FGT/FHT - 100GE_4 
              case (i_profile_sel_reg) 
              6'b000000: begin // 1x100GE-4
                           active_port           = 3'd1;
                           active_segment        = 3'd4; //4 segments - mac seg
                           port_data_width       = 3'd2; //sopa - 512 bits 
                           o_speed_sel           = 6'b011011;
                           o_data_width          = (PORT_CLIENT_IF)? 3'b100: 3'b011; 
                         end
              6'b000011: begin // 1x40GE-4-FGT
                           active_port           = 3'd1;
                           active_segment        = 3'd2;
                           port_data_width       = 3'd1; //128 bits 
                           o_speed_sel           = 6'b010110;
                           o_data_width          = 3'b010; 
                         end
              6'b000100: begin // 1x100GE-2
                           active_port           = 3'd1;
                           active_segment        = 3'd4;
                           port_data_width       = 3'd2; //sopa - 512 bits 
                           o_speed_sel           = 6'b011010;
                           o_data_width          = (PORT_CLIENT_IF)? 3'b100: 3'b011;  
                         end
              6'b010000: begin // 2x50GE-2
                           active_port           = 3'd2;
                           active_segment        = 3'd2;
                           port_data_width       = 3'd1; //128 bits    
                           o_speed_sel           = 6'b010111;
                           o_data_width          = 3'b010;                            
                         end
              6'b010100: begin // 2x50GE-1
                           active_port           = 3'd2;
                           active_segment        = 3'd2;
                           port_data_width       = 3'd1; //128 bits     
                           o_speed_sel           = 6'b011000;    
                           o_data_width          = 3'b010;                            
                         end
              6'b100000: begin // 4x25GE-1/10GE-1
                           active_port           = 3'd4;
                           active_segment        = 3'd1;
                           port_data_width       = 3'd0; //64 bits                           
                           o_speed_sel           = 6'b010101;  
                           o_data_width          = 3'b001; 
                         end
              6'b001000: begin // 1x100GE-1-FHT
                           active_port           = 3'd1;
                           active_segment        = 3'd4;
                           port_data_width       = 3'd2; //sopa - 512 bits  
                           o_speed_sel           = 6'b011001;
                           o_data_width          = (PORT_CLIENT_IF)? 3'b100: 3'b011;  
                         end                        
              default:   begin
                           active_port           = 3'd0;
                           active_segment        = 3'd1;
                           port_data_width       = 3'd2;  
                           o_speed_sel           = 6'd0;
                           o_data_width          = 3'd0;                          
                         end
              endcase
           end 
        end 

else if ( PORT_PROFILE == "100GAUI-2")
begin:PROFILE_100GAUI_2 
        always @(*) begin //FGT/FHT - 100GE_2 
              case (i_profile_sel_reg) 
                 6'b000000: begin // 1x100GE-2
                              active_port           = 3'd1;
                              active_segment        = 3'd4;
                              port_data_width       = 3'd2; //sopa - 512 bits 
                              o_speed_sel           = 6'b011010; 
                              o_data_width          = (PORT_CLIENT_IF)? 3'b100: 3'b011;                              
                            end
                 6'b000001: begin // 1x50GE-2
                              active_port           = 3'd1;
                              active_segment        = 3'd2;
                              port_data_width       = 3'd1; //128 bits   
                              o_speed_sel           = 6'b010111; 
                              o_data_width          = 3'b010;                            
                            end
                 6'b010000: begin // 2x50GE-1 
                              active_port           = 3'd2;
                              active_segment        = 3'd2;
                              port_data_width       = 3'd1; //128 bits  
                              o_speed_sel           = 6'b011000; 
                              o_data_width          = 3'b010;                            
                            end
                 6'b010001: begin // 2x25GE-1/10GE-1
                              active_port           = 3'd2;
                              active_segment        = 3'd1;
                              port_data_width       = 3'd0; //64 bits      
                              o_speed_sel           = 6'b010101;
                              o_data_width          = 3'b001; 
                            end
                 6'b000100: begin //FHT 1x100GE-1
                              active_port           = 3'd1;
                              active_segment        = 3'd4;
                              port_data_width       = 3'd2; //sopa - 512 bits 
                              o_speed_sel           = 6'b011001;    
                              o_data_width          = (PORT_CLIENT_IF)? 3'b100: 3'b011;                               
                            end                     
                 default:   begin
                              active_port           = 3'd0;
                              active_segment        = 3'd0;
                              port_data_width       = 3'd2;     
                              o_speed_sel           = 6'd0;
                              o_data_width          = 3'd0;                              
                            end
                 endcase
              end 
           end 

else if ( PORT_PROFILE == "400GAUI-8")
begin:PROFILE_400GAUI_8
        always @(*) begin //FGT_400GE_8  
              case (i_profile_sel_reg) 
                 6'b000000: begin // 1x400GE-8
                              active_port           = 3'd1;
                              active_segment        = 3'd6; //decode 6 as 16 segments
                              port_data_width       = 3'd4; //not used for sopa   
                              o_speed_sel           = 6'b100000;      
                              o_data_width          = 3'b101;                            
                            end
                 6'b010000: begin // 2x200GE-4
                              active_port           = 3'd2;
                              active_segment        = 3'd5; //decode 5 as 8 segments
                              port_data_width       = 3'd4; //not used for sopa                                
                              o_speed_sel           = 6'b011101; 
                              o_data_width          = 3'b100;                            
                            end
                 6'b100000: begin // 4x100GE-2
                              active_port           = 3'd4;
                              active_segment        = 3'd4;
                              port_data_width       = 3'd4; //not used for sopa                                
                              o_speed_sel           = 6'b011010;
                              o_data_width          = 3'b011; //1X400g-8 supported only for mac segmented  ;                              
                            end
                 default:   begin
                              active_port           = 3'd0;
                              active_segment        = 3'd0;
                              port_data_width       = 3'd4; //not used for sopa                       
                              o_speed_sel           = 6'd0;
                              o_data_width          = 3'd0;
                            end
                 endcase
              end 
           end 

else if ( PORT_PROFILE == "200GAUI-4")
begin:PROFILE_200GAUI_4 
        always @(*) begin //FHT/FGT-200G-4  
              case (i_profile_sel_reg) 
              6'b000000: begin // 1x200GE-4
                           active_port           = 3'd1;
                           active_segment        = 3'd5; //decode 5 as 8 segments
                           port_data_width       = 3'd4; //not used for sopa                                  
                           o_speed_sel           = 6'b011101;
                           o_data_width          = 3'b100; 
                         end              
              6'b000100: begin // 1x200GE-2
                           active_port           = 3'd1;
                           active_segment        = 3'd5; //decode 5 as 8 segments
                           port_data_width       = 3'd4; //not used for sopa                                  
                           o_speed_sel           = 6'b011100;
                           o_data_width          = 3'b100; 
                         end
              6'b000001: begin // 1x100GE-4
                           active_port           = 3'd1;
                           active_segment        = 3'd4;
                           port_data_width       = 3'd4; //not used for sopa 
                           o_speed_sel           = 6'b011011;  
                           o_data_width          = 3'b011; //1X200g-4 supported only for mac segmented ;                              
                         end
              6'b010000: begin // 2x100GE-2
                           active_port           = 3'd2;
                           active_segment        = 3'd4;
                           port_data_width       = 3'd4; //not used for sopa 
                           o_speed_sel           = 6'b011010;      
                           o_data_width          = 3'b011; //1X200g-4 supported only for mac segmented ;                                                          
                         end              
              6'b010100: begin //2x100GE-1
                           active_port           = 3'd2;
                           active_segment        = 3'd4;
                           port_data_width       = 3'd4; //not used for sopa  
                           o_speed_sel           = 6'b011001;  
                           o_data_width          = 3'b011; //1X200g-4 supported only for mac segmented ;                                                          
                         end
              6'b010001: begin // 2x50GE-2
                           active_port           = 3'd2;
                           active_segment        = 3'd2;
                           port_data_width       = 3'd4; //not used for sopa
                           o_speed_sel           = 6'b010111;  
                           o_data_width          = 3'b010;                         
                         end
              6'b100000: begin // 4x50GE-1
                           active_port           = 3'd4;
                           active_segment        = 3'd2;
                           port_data_width       = 3'd4; //not used for sopa
                           o_speed_sel           = 6'b011000;  
                           o_data_width          = 3'b010;                            
                         end
              default:   begin
                           active_port           = 3'd0;
                           active_segment        = 3'd0;
                           port_data_width       = 3'd4; //not used for sopa 
                           o_speed_sel           = 6'd0;   
                           o_data_width          = 3'd0;                          
                         end
              endcase
           end
        end

else if ( PORT_PROFILE == "100GAUI-1")
begin:PROFILE_100GAUI_1
        always @(*) begin //FHT-100G-1 
              case (i_profile_sel_reg) 
              6'b000000: begin // 1x100GE-1
                           active_port           = 3'd1;
                           active_segment        = 3'd4;
                           port_data_width       = 3'd2; //sopa - 512 bits 
                           o_speed_sel           = 6'b011001;
                           o_data_width          = (PORT_CLIENT_IF)? 3'b100: 3'b011; 
                         end
              6'b000001: begin // 1x50GE-1
                           active_port           = 3'd1;
                           active_segment        = 3'd2;
                           port_data_width       = 3'd1; //128 bits 
                           o_speed_sel           = 6'b011000;
                           o_data_width          = 3'b010; 
                         end
              6'b000010: begin // 1x25GE-1
                           active_port           = 3'd1;
                           active_segment        = 3'd1;
                           port_data_width       = 3'd0; //64 bits   
                           o_speed_sel           = 6'b010101;  
                           o_data_width          = 3'b001;                            
                         end               
              default:   begin             
                           active_port           = 3'd0;
                           active_segment        = 3'd0;
                           port_data_width       = 3'd2;   
                           o_speed_sel           = 6'd0;
                           o_data_width          = 3'd0;                          
                         end
              endcase
           end
        end

else if ( PORT_PROFILE == "400GAUI-4")
begin:PROFILE_400GAUI_4
        always @(*) begin //FHT-400G-4 
              case (i_profile_sel_reg) 
              6'b000000: begin // 1x400GE-4
                           active_port           = 3'd1;
                           active_segment        = 3'd6; //decode 6 as 16 segments
                           port_data_width       = 3'd4; //not used for sopa  
                           o_speed_sel           = 6'b011111;  
                           o_data_width          = 3'b101;                            
                         end
              6'b000001: begin // 1x200GE-4
                           active_port           = 3'd1;
                           active_segment        = 3'd5;  //decode 5 as 8 segments                     
                           port_data_width       = 3'd4; //not used for sopa
                           o_speed_sel           = 6'b011101;  
                           o_data_width          = 3'b100;                            
                         end
              6'b010000: begin // 2x200GE- 2
                           active_port           = 3'd2;
                           active_segment        = 3'd5; //decode 5 as 8 segments
                           port_data_width       = 3'd4; //not used for sopa
                           o_speed_sel           = 6'b011100;  
                           o_data_width          = 3'b100;                            
                         end 
              6'b010001: begin // 2x100GE-2
                           active_port           = 3'd2;
                           active_segment        = 3'd4;
                           port_data_width       = 3'd4; //not used for sopa 
                           o_speed_sel           = 6'b011010;  
                           o_data_width          = 3'b011; //1X400g-4 supported only for mac segmented                            
                         end
              6'b100000: begin // 4x100GE-1
                           active_port           = 3'd4;
                           active_segment        = 3'd4;
                           port_data_width       = 3'd4; //not used for sopa 
                           o_speed_sel           = 6'b011001;  
                           o_data_width          = 3'b011; //1X400g-4 supported only for mac segmented ;                          
                         end
              default:   begin
                           active_port           = 3'd0;
                           active_segment        = 3'd0;
                           port_data_width       = 3'd4; //not used for sopa
                           o_speed_sel           = 6'd0;
                           o_data_width          = 3'd0;                          
                         end
              endcase
           end    
        end   

else //if ( PORT_PROFILE == "200GAUI-2")
begin:PROFILE_200GAUI_2
        always @(*) begin //FHT-200G-2 
              case (i_profile_sel_reg) 
              6'b000000: begin // 1x200GE-2
                           active_port           = 3'd1;
                           active_segment        = 3'd5; //decode 5 as 8 segments 
                           port_data_width       = 3'd4; //not used for sopa
                           o_speed_sel           = 6'b011100;      
                           o_data_width          = 3'b100;                            
                         end
              6'b000001: begin // 1x100GE-2
                           active_port           = 3'd1;
                           active_segment        = 3'd4;
                           port_data_width       = 3'd4; //not used for sopa 
                           o_speed_sel           = 6'b011010;
                           o_data_width          = 3'b011; //1X200g-2 supported only for mac segmented                            
                         end 
              6'b000010: begin // 1x50GE-2
                           active_port           = 3'd1;
                           active_segment        = 3'd2;
                           port_data_width       = 3'd4; //not used for sopa 
                           o_speed_sel           = 6'b010111;
                           o_data_width          = 3'b010;                            
                         end 
              6'b010000: begin // 2x100GE-1
                           active_port           = 3'd2;
                           active_segment        = 3'd4;
                           port_data_width       = 3'd4; //not used for sopa  
                           o_speed_sel           = 6'b011001;  
                           o_data_width          = 3'b011; //1X200g-2 supported only for mac segmented                        
                         end
              6'b010001: begin // 2x50GE-1
                           active_port           = 3'd2;
                           active_segment        = 3'd2;
                           port_data_width       = 3'd4; //not used for sopa  
                           o_speed_sel           = 6'b011000;
                           o_data_width          = 3'b010;                            
                         end
              default:   begin
                           active_port           = 3'd0;
                           active_segment        = 3'd0;
                           port_data_width       = 3'd4; //not used for sopa 
                           o_speed_sel           = 6'd0;   
                           o_data_width          = 3'd0;                          
                         end
              endcase
           end
        end

end
endgenerate 


generate
if (DR_ENABLE == 0)                    
begin:NON_DR_AP
        always_comb begin //NON_DR                            
              port_active_mask_reg  = {NUM_MAX_PORTS{1'b1}};                               
        end 
     end 
     
else if (PORT_PROFILE == "25GbE")                    
begin:PROFILE_25GbE_AP
        always @(*) begin // FGT_25GE_1 
              case (i_profile_sel_reg) // [5:4] = active ports, [3:2]-active lanes, [1:0] - sum of BW
              6'b000000: begin // 1x25GE-1/10GE-1
                            port_active_mask_reg = {NUM_MAX_PORTS{1'b1}};
                         end
              default:   begin
                            port_active_mask_reg  = {NUM_MAX_PORTS{1'b0}};                    
                         end
              endcase
           end
        end

else if (PORT_PROFILE == "50GAUI-1")               
begin:PROFILE_50GAUI_1_AP 
        always @(*) begin //FGT/FHT - 50GE_1 
              case (i_profile_sel_reg) 
              6'b000000: begin // 1x50GE-1
                           port_active_mask_reg  = {NUM_MAX_PORTS{1'b1}};
                         end
              6'b000001: begin // 1x25GE-1/10GE-1
                           port_active_mask_reg  = {NUM_MAX_PORTS{1'b1}};
                         end
              default:   begin
                           port_active_mask_reg  = {NUM_MAX_PORTS{1'b0}};
                         end
              endcase
           end
        end

else if ( PORT_PROFILE == "100GCAUI-4")              
begin:PROFILE_100GCAUI_4_AP    
        always @(*) begin //FGT/FHT - 100GE_4
              case (i_profile_sel_reg) 
              6'b000000: begin // 1x100GE-4
                           port_active_mask_reg  = {INACTIVE_PORT, INACTIVE_PORT, INACTIVE_PORT, ACTIVE_PORT};
                         end
              6'b000011: begin // 1x40GE-4-FGT
                           port_active_mask_reg  = {INACTIVE_PORT, INACTIVE_PORT, INACTIVE_PORT, ACTIVE_PORT};
                         end
              6'b000100: begin // 1x100GE-2
                           port_active_mask_reg  = {INACTIVE_PORT, INACTIVE_PORT, INACTIVE_PORT, ACTIVE_PORT}; 
                         end
              6'b010000: begin // 2x50GE-2
                           port_active_mask_reg  = {INACTIVE_PORT, ACTIVE_PORT, INACTIVE_PORT, ACTIVE_PORT};                           
                         end
              6'b010100: begin // 2x50GE-1
                           port_active_mask_reg  = {INACTIVE_PORT, ACTIVE_PORT, INACTIVE_PORT, ACTIVE_PORT};                         
                         end
              6'b100000: begin // 4x25GE-1/10GE-1
                           port_active_mask_reg  = {ACTIVE_PORT, ACTIVE_PORT, ACTIVE_PORT, ACTIVE_PORT};
                         end
              6'b001000: begin // 1x100GE-1-FHT
                           port_active_mask_reg  = {INACTIVE_PORT, INACTIVE_PORT, INACTIVE_PORT, ACTIVE_PORT}; 
                         end                         
              default:   begin
                           port_active_mask_reg  = {NUM_MAX_PORTS{1'b0}};                      
                         end
              endcase
           end 
        end 
        
else if ( PORT_PROFILE == "100GAUI-2")
begin:PROFILE_100GAUI_2_AP 
        always @(*) begin //FGT/FHT - 100GE_2
              case (i_profile_sel_reg) 
                 6'b000000: begin // 1x100GE-2
                              port_active_mask_reg  = {INACTIVE_PORT,ACTIVE_PORT};                         
                            end
                 6'b000001: begin // 1x50GE-2
                              port_active_mask_reg  = {INACTIVE_PORT,ACTIVE_PORT};                        
                            end
                 6'b010000: begin // 2x50GE-1 
                              port_active_mask_reg  = {ACTIVE_PORT,ACTIVE_PORT};                          
                            end
                 6'b010001: begin // 2x25GE-1/10GE-1
                              port_active_mask_reg  = {ACTIVE_PORT,ACTIVE_PORT};
                            end
                 6'b000100: begin //FHT 1x100GE-1
                              port_active_mask_reg  = {INACTIVE_PORT, ACTIVE_PORT};                         
                            end                     
                 default:   begin
                              port_active_mask_reg  = {NUM_MAX_PORTS{1'b0}};
                            end
                 endcase
              end 
           end 

else if ( PORT_PROFILE == "400GAUI-8")
begin:PROFILE_400GAUI_8_AP
        always @(*) begin //FGT_400GE_8  
              case (i_profile_sel_reg) 
                 6'b000000: begin // 1x400GE-8             
                              port_active_mask_reg  = {INACTIVE_PORT,INACTIVE_PORT,INACTIVE_PORT,ACTIVE_PORT};
                            end
                 6'b010000: begin // 2x200GE-4
                              port_active_mask_reg  = {INACTIVE_PORT,ACTIVE_PORT,INACTIVE_PORT,ACTIVE_PORT};
                            end
                 6'b100000: begin // 4x100GE-2
                              port_active_mask_reg  = {ACTIVE_PORT,ACTIVE_PORT,ACTIVE_PORT,ACTIVE_PORT};                              
                            end
                 default:   begin
                              port_active_mask_reg  = {NUM_MAX_PORTS{1'b0}};
                            end
                 endcase
              end 
           end 

else if ( PORT_PROFILE == "200GAUI-4")
begin:PROFILE_200GAUI_4_AP 
        always @(*) begin //FHT/FGT-200G-4 
              case (i_profile_sel_reg) 
              6'b000000: begin // 1x200GE-4
                           port_active_mask_reg  = {INACTIVE_PORT,INACTIVE_PORT,INACTIVE_PORT,ACTIVE_PORT};
                         end              
              6'b000100: begin // 1x200GE-2
                           port_active_mask_reg  = {INACTIVE_PORT,INACTIVE_PORT,INACTIVE_PORT,ACTIVE_PORT};
                         end
              6'b000001: begin // 1x100GE-4
                           port_active_mask_reg  = {INACTIVE_PORT,INACTIVE_PORT,INACTIVE_PORT,ACTIVE_PORT};                             
                         end
              6'b010000: begin // 2x100GE-2
                           port_active_mask_reg  = {INACTIVE_PORT,ACTIVE_PORT,INACTIVE_PORT,ACTIVE_PORT};                                                       
                         end              
              6'b010100: begin //2x100GE-1
                           port_active_mask_reg  = {INACTIVE_PORT,ACTIVE_PORT,INACTIVE_PORT,ACTIVE_PORT};                                                         
                         end
              6'b010001: begin // 2x50GE-2
                           port_active_mask_reg  = {INACTIVE_PORT,ACTIVE_PORT,INACTIVE_PORT,ACTIVE_PORT};                      
                         end
              6'b100000: begin // 4x50GE-1
                           port_active_mask_reg  = {ACTIVE_PORT,ACTIVE_PORT,ACTIVE_PORT,ACTIVE_PORT};               
                         end
              default:   begin
                           port_active_mask_reg  = {NUM_MAX_PORTS{1'b0}};                    
                         end
              endcase
           end
        end

else if ( PORT_PROFILE == "100GAUI-1")
begin:PROFILE_100GAUI_1_AP
        always @(*) begin //FHT-100G-1
              case (i_profile_sel_reg) 
              6'b000000: begin // 1x100GE-1
                           port_active_mask_reg  = {ACTIVE_PORT};
                         end
              6'b000001: begin // 1x50GE-1
                           port_active_mask_reg  = {ACTIVE_PORT};
                         end
              6'b000010: begin // 1x25GE-1
                           port_active_mask_reg  = {ACTIVE_PORT};                         
                         end               
              default:   begin             
                           port_active_mask_reg  = {NUM_MAX_PORTS{1'b0}};                       
                         end
              endcase
           end
        end

else if ( PORT_PROFILE == "400GAUI-4")
begin:PROFILE_400GAUI_4_AP
        always @(*) begin //FHT-400GE-4
              case (i_profile_sel_reg) 
              6'b000000: begin // 1x400GE-4
                           port_active_mask_reg  = {INACTIVE_PORT,INACTIVE_PORT,INACTIVE_PORT,ACTIVE_PORT};                     
                         end
              6'b000001: begin // 1x200GE-4                
                           port_active_mask_reg  = {INACTIVE_PORT,INACTIVE_PORT,INACTIVE_PORT,ACTIVE_PORT};                           
                         end
              6'b010000: begin // 2x200GE- 2
                           port_active_mask_reg  = {INACTIVE_PORT,ACTIVE_PORT,INACTIVE_PORT,ACTIVE_PORT};                       
                         end 
              6'b010001: begin // 2x100GE-2
                           port_active_mask_reg  = {INACTIVE_PORT,ACTIVE_PORT,INACTIVE_PORT,ACTIVE_PORT};                        
                         end
              6'b100000: begin // 4x100GE-1
                           port_active_mask_reg  = {ACTIVE_PORT,ACTIVE_PORT,ACTIVE_PORT,ACTIVE_PORT};                       
                         end
              default:   begin
                           port_active_mask_reg  = {NUM_MAX_PORTS{1'b0}};                
                         end
              endcase
           end    
        end   

else //if ( PORT_PROFILE == "200GAUI-2")
begin:PROFILE_200GAUI_2_AP
        always @(*) begin //FHT-200G-2
              case (i_profile_sel_reg) 
              6'b000000: begin // 1x200GE-2
                           port_active_mask_reg  = {INACTIVE_PORT,ACTIVE_PORT};                        
                         end
              6'b000001: begin // 1x100GE-2
                           port_active_mask_reg  = {INACTIVE_PORT,ACTIVE_PORT};                   
                         end 
              6'b000010: begin // 1x50GE-2
                           port_active_mask_reg  = {INACTIVE_PORT,ACTIVE_PORT};                       
                         end 
              6'b010000: begin // 2x100GE-1
                           port_active_mask_reg  = {ACTIVE_PORT,ACTIVE_PORT};                       
                         end
              6'b010001: begin // 2x50GE-1
                           port_active_mask_reg  = {ACTIVE_PORT,ACTIVE_PORT};                           
                         end
              default:   begin
                           port_active_mask_reg  = {NUM_MAX_PORTS{1'b0}};             
                         end
              endcase
           end
        end

endgenerate

integer         fp;
// integer         fp,fp2,fp3,fp_out,fp1_out,fp2_out;
// time            time_stamp;
generate 
if (SIM_EMULATE ==1 ) begin: BRIDGE_IO_FILE_DUMP
   initial begin
        fp      = $fopen ( "axi_st_bridge_tx_input.txt", "w" );
        // fp2     = $fopen ( "axi_st_bridge_rx_avst_input.txt", "w" );
        // fp3     = $fopen ( "axi_st_bridge_rx_ms_input.txt", "w" );
        // fp_out  = $fopen ( "axi_st_bridge_tx_avst_output.txt", "w" );
        // fp1_out = $fopen ( "axi_st_bridge_tx_ms_output.txt", "w" );
        // fp2_out = $fopen ( "axi_st_bridge_rx_output.txt", "w" );
    end
    
    always @ (posedge i_tx_clk_p0 ) begin

    // time_stamp <= ($time)/1000;
        $fwrite ( fp, "%h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h\n", i_tx_avst_ready, i_axi_st_tx_tvalid, i_axi_st_tx_tdata,i_axi_st_tx_tlast,i_axi_st_tx_tkeep,i_axi_st_tx_tuser_client,i_axi_st_tx_tuser_ptp, i_axi_st_tx_tuser_ptp_extended, i_axi_st_tx_tlast_segment,i_axi_st_tx_tkeep_segment, i_axi_st_tx_pkt_seg_parity, 
                                                               o_axi_st_tx_tready, i_rx_avst_error, i_rxstatus_avst_data, i_rxstatus_avst_valid, i_rx_avst_ptp_rx_its, i_rx_avst_preamble, i_rx_mac_error, i_rx_mac_fcs_error, i_rx_mac_status);
        // $fwrite ( fp_out, "%h %h %h %h %h %h %h %h %h %h %h\n",i_tx_avst_ready,o_tx_avst_data,o_tx_avst_valid,o_tx_avst_startofpacket, o_tx_avst_endofpacket, o_tx_avst_empty, o_tx_avst_preamble, o_tx_avst_error,o_tx_avst_skip_crc,o_tx_fifo_eccstatus,o_axi_st_tx_parity_error);
        // $fwrite ( fp1_out, "%h %h %h %h %h %h %h %h %h\n",i_tx_mac_ready,o_tx_mac_data,o_tx_mac_valid,o_tx_mac_inframe, o_tx_mac_eop_empty, o_tx_mac_error, o_tx_mac_skip_crc, o_tx_fifo_eccstatus,o_axi_st_tx_parity_error);

    end 
    
   /* always @ (posedge i_rx_clk ) begin
        $fwrite ( fp2, "%h %h %h %h %h %h %h %h %h %h\n", i_rx_avst_data, i_rx_avst_valid,i_rx_avst_startofpacket,i_rx_avst_endofpacket,i_rx_avst_empty,i_rx_avst_error, i_rxstatus_avst_data, i_rxstatus_avst_valid,i_rx_avst_ptp_rx_its, i_rx_avst_preamble);
        $fwrite ( fp3, "%h %h %h %h %h %h %h\n",i_rx_mac_data,i_rx_mac_valid,i_rx_mac_inframe,i_rx_mac_eop_empty, i_rx_mac_error, i_rx_mac_fcs_error, i_rx_mac_status);
        $fwrite ( fp2_out, "%h %h %h %h %h %h %h\n",o_axi_st_rx_tready,o_axi_st_rx_tvalid,o_axi_st_rx_tdata,o_axi_st_rx_tlast, o_axi_st_rx_tkeep, o_axi_st_rx_tuser_client, o_axi_st_rx_tuser_sts);

    end     */
end
endgenerate    

endmodule  
