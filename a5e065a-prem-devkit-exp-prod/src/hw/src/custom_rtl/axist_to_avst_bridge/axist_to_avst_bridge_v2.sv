//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on


module axist_to_avst_bridge_v2 #(
    parameter TILES                    = "E",
    parameter SIM_EMULATE              = 0,
    parameter PORT_CLIENT_IF           = 0,
    parameter DATA_WIDTH               = 64,
    parameter NUM_SEG                  = (PORT_CLIENT_IF == 1)? 1: (DATA_WIDTH/64),  //8 bytes per segment
    parameter NUM_CHANNELS             = 1, 
    parameter EMPTY_BITS               = 3,
    parameter AVST_ERR                 = 2*NUM_SEG,   
    parameter AVST_FCS_ERR             = 1*NUM_SEG,   
    parameter AVST_MAC_STS             = 3*NUM_SEG,   
    parameter USER_WIDTH_TX            = AVST_ERR +90 +328,
    parameter USER_WIDTH_RX            = AVST_ERR +90 +328,
    //parameter AXIST_MODE		    	= "SINGLE_PACKET", 
    parameter TDATA_WIDTH              = 64,
    parameter NO_OF_BYTES              = (PORT_CLIENT_IF == 1)?TDATA_WIDTH/8:8, 
    parameter TUSER_WIDTH_TX           = AVST_ERR +90 +328,
    parameter TUSER_WIDTH_RX           = AVST_ERR +90 +328,
    parameter AXIST_ERR                = 2*NUM_SEG,
    parameter ST_READY_LATENCY         = 1,  
    parameter ENABLE_MULTI_STREAM      = 0,  
    parameter NUM_OF_STREAM            = 1,  
    parameter PKT_SEG_PARITY_EN        = 0,
    parameter ENABLE_ECC               = 1,
    parameter USE_M20K                 = "ON"
 
) (
    input   [NUM_OF_STREAM-1:0]                             i_tx_clk, 
    input   [NUM_OF_STREAM-1:0]                             i_tx_reset_n,
    input   [NUM_OF_STREAM-1:0]                             i_rx_clk, 
    input   [NUM_OF_STREAM-1:0]                             i_rx_reset_n,
/////////// TX ports ///////////////////       
    //AXI Stream Tx, from User interface   
    //SINGLE PACKET COMPATIBLE SIGNALS              
    input  [NUM_OF_STREAM-1:0]                              i_axi_st_tx_tvalid,
    input  [NUM_OF_STREAM*TDATA_WIDTH-1:0]                  i_axi_st_tx_tdata,
    input  [NUM_OF_STREAM-1:0]                              i_axi_st_tx_tlast,
    input  [NUM_OF_STREAM*NO_OF_BYTES-1:0]                  i_axi_st_tx_tkeep,
    input  [NUM_OF_STREAM*TUSER_WIDTH_TX-1:0]               i_axi_st_tx_tuser,
    //MULTI PACKET COMPATIBLE SIGNALS           
    input  [NUM_SEG-1:0]                                    i_axi_st_tx_tlast_segment,
    input  [NUM_SEG*NO_OF_BYTES-1:0]                        i_axi_st_tx_tkeep_segment,
    input  [NUM_SEG-1:0]                                    i_axi_st_tx_pkt_seg_parity,
    output reg                                              o_axi_st_tx_tready,
 
    //Avalon Stream Tx, to MAC interface     
     //SOP ALIGNED COMPATIBLE SIGNALS     
    input                                                   i_av_st_tx_ready,
    output reg  [NUM_OF_STREAM*DATA_WIDTH-1:0]              o_av_st_tx_data,
    output reg  [NUM_OF_STREAM-1:0]                         o_av_st_tx_valid,
    output reg  [NUM_OF_STREAM-1:0]                         o_av_st_tx_startofpacket,
    output reg  [NUM_OF_STREAM-1:0]                         o_av_st_tx_endofpacket,
    output reg  [NUM_OF_STREAM*EMPTY_BITS-1:0]              o_av_st_tx_empty,
    output reg  [NUM_OF_STREAM*USER_WIDTH_TX-1:0]           o_av_st_tx_user,
    // output reg  [NUM_OF_STREAM-1:0]             	 o_av_st_tx_error,
    // output reg  [NUM_OF_STREAM*AVST_ERR-1:0]    	 o_av_st_tx_skip_crc,                                         		 											 
     //MAC_SEGMENTED COMPATIBLE SIGNALS     
    input                                                   i_av_st_tx_ms_ready,
    output reg  [DATA_WIDTH-1:0]                            o_av_st_tx_ms_data,
    output reg  [1-1:0]                                     o_av_st_tx_ms_valid,
    output reg  [NUM_SEG-1:0]                               o_av_st_tx_ms_inframe,
    output reg  [NUM_SEG*EMPTY_BITS-1:0]                    o_av_st_tx_ms_eop_empty,
    output reg  [2-1:0]                                     o_tx_fifo_eccstatus, 
    output                                                  o_axi_st_tx_parity_error, 
    //output reg  [USER_WIDTH_TX-1:0]          		 o_av_st_tx_ms_user,
             
/////////// RX ports ////////////////////      
 //////////////////////////////////////////             
    //Avalon Stream Rx, from MAC interface   
 //SOP ALIGNED COMPATIBLE SIGNALS           
    output reg [NUM_OF_STREAM-1:0]                          o_axi_st_rx_ready, //TBD
    input   [NUM_OF_STREAM*DATA_WIDTH-1:0]                  i_av_st_rx_data,
    input   [NUM_OF_STREAM-1:0]                             i_av_st_rx_valid,
    input   [NUM_OF_STREAM-1:0]                             i_av_st_rx_startofpacket,
    input   [NUM_OF_STREAM-1:0]                             i_av_st_rx_endofpacket,
    input   [NUM_OF_STREAM*EMPTY_BITS-1:0]                  i_av_st_rx_empty,
    input   [USER_WIDTH_RX-1:0]                             i_av_st_rx_user,
    // input   [NUM_OF_STREAM*40-1:0]              	 i_av_st_rxstatus_data,
    // input   [NUM_OF_STREAM-1:0]                 	 i_av_st_rxstatus_valid,
    // input   [NUM_OF_STREAM*96-1:0]              	 i_av_st_ptp_rx_its,	
 //MAC_SEGMENTED COMPATIBLE SIGNALS           
    input   [DATA_WIDTH-1:0]                                i_av_st_rx_ms_data,
    input   [1-1:0]                                         i_av_st_rx_ms_valid,
    input   [NUM_SEG-1:0]                                   i_av_st_rx_ms_inframe,
    input   [NUM_SEG*EMPTY_BITS-1:0]                        i_av_st_rx_ms_eop_empty,
    //input   [TUSER_WIDTH_RX-1:0]          			 i_av_st_rx_ms_user,
              
    //AXI Stream Rx, to User interface     
    input  [NUM_OF_STREAM-1:0]                              i_axi_st_rx_tready,
    output reg [NUM_OF_STREAM-1:0]                          o_axi_st_rx_tvalid,
    output reg [NUM_OF_STREAM*TDATA_WIDTH-1:0]              o_axi_st_rx_tdata,
    output reg [NUM_OF_STREAM-1:0]                          o_axi_st_rx_tlast,
    output reg [NUM_OF_STREAM*NO_OF_BYTES-1:0]              o_axi_st_rx_tkeep,
    output reg [TUSER_WIDTH_RX-1:0]                         o_axi_st_rx_tuser,
    output reg [NUM_SEG-1:0]                                o_axi_st_rx_tuser_valid,
 
 //MULTI PACKET COMPATIBLE SIGNALS           
    output reg [NUM_SEG-1:0]                                o_axi_st_rx_tlast_segment,
    output reg [NUM_SEG*NO_OF_BYTES-1:0]                    o_axi_st_rx_tkeep_segment,
    output reg [NUM_SEG-1:0]                                o_axi_st_rx_pkt_seg_parity

);

//***********************************************************
//***********************************************************
localparam AVST_MODE  = (PORT_CLIENT_IF == 0) ? "MAC_SEGMENTED" : "SOP_ALIGNED";
localparam AXIST_MODE = (PORT_CLIENT_IF == 0) ? "MULTI_PACKET"  : "SINGLE_PACKET";

wire             axist_tx_tready;
wire [NUM_OF_STREAM*DATA_WIDTH-1:0] avst_tx_data;     
wire [NUM_OF_STREAM-1:0]     avst_tx_valid;   
wire [NUM_SEG-1:0]       avst_tx_inframe;  
wire [NUM_SEG*EMPTY_BITS-1:0]   avst_tx_empty;
wire [AVST_ERR-1:0]       avst_tx_mac_error;
wire [AVST_ERR-1:0]       avst_tx_skip_crc;

wire [NUM_OF_STREAM*TDATA_WIDTH-1:0] axist_tx_tdata;        
wire [NUM_OF_STREAM-1:0]     axist_tx_tlast;        
wire [NUM_SEG-1:0]       axist_tx_tlast_segment;
wire [NUM_SEG*NO_OF_BYTES-1:0]   axist_tx_tkeep_segment;
wire [TUSER_WIDTH_RX-1:0]      axi_st_rx_tuser;
wire             axi_st_tx_tready;

wire [NUM_SEG*NO_OF_BYTES-1:0]    axi_st_rx_tkeep;
wire [NUM_SEG-1:0]        axi_st_rx_tlast;
wire [NUM_SEG-1:0]        axi_st_rx_tuser_valid;

//--------------------------------------------------------------------------------------------------
//                   AXI ST to AVST conversion for MAC segmented, SOP aligned
//--------------------------------------------------------------------------------------------------
 axist_to_avst_tx_mac_seg_if_v2 #( 
  .SIM_EMULATE     (SIM_EMULATE), 
  .AVST_MODE        (AVST_MODE),
  .AVST_DW             (DATA_WIDTH), 
  .EMPTY_BITS        (EMPTY_BITS),
  .AVST_ERR          (AVST_ERR), 
  .FCS_ERR         (AVST_FCS_ERR),
  .MAC_STS         (AVST_MAC_STS),
  .AVST_USER        (USER_WIDTH_TX),
  .AXIST_MODE    (AXIST_MODE),
  .AXI_DW             (TDATA_WIDTH),
  .NO_OF_BYTES       (NO_OF_BYTES),
  .TUSER            (TUSER_WIDTH_TX),
  .AXI_ERR            (AXIST_ERR),
  .NUM_SEG             (NUM_SEG), 
  .READY_LATENCY       (ST_READY_LATENCY),
  .PKT_SEG_PARITY_EN   (PKT_SEG_PARITY_EN),
  .ENABLE_ECC      (ENABLE_ECC),
  .USE_M20K      (USE_M20K)
 ) U_axist_to_avst_tx_mac_seg_if_inst (
  .i_tx_clk           (i_tx_clk),
  .i_tx_reset_n                (i_tx_reset_n),
  .o_axist_tx_tready           (o_axi_st_tx_tready),
  .i_axist_tx_tvalid           (i_axi_st_tx_tvalid),
  .i_axist_tx_tdata            (i_axi_st_tx_tdata),
  .i_axist_tx_tlast            (i_axi_st_tx_tlast),
  .i_axist_tx_tkeep            (i_axi_st_tx_tkeep),
  .i_axist_tx_tlast_segment    (i_axi_st_tx_tlast_segment),
  .i_axist_tx_tkeep_segment    (i_axi_st_tx_tkeep_segment),
  .i_axist_tx_tuser         (i_axi_st_tx_tuser),
  .i_axist_tx_pkt_seg_parity    (i_axi_st_tx_pkt_seg_parity),
  .i_avst_tx_ready             ((AVST_MODE == "MAC_SEGMENTED") ? i_av_st_tx_ms_ready : i_av_st_tx_ready),
  .o_avst_tx_data              (avst_tx_data),
  .o_avst_tx_valid             (avst_tx_valid),
  .o_avst_tx_inframe           (o_av_st_tx_ms_inframe),
  .o_avst_tx_eop_empty         (avst_tx_empty),
  .o_avst_tx_startofpacket   (o_av_st_tx_startofpacket),
  .o_avst_tx_endofpacket      (o_av_st_tx_endofpacket),   
  .o_avst_tx_user             (o_av_st_tx_user),
      .o_axist_tx_parity_error     (o_axi_st_tx_parity_error),
  .o_fifo_eccstatus          (o_tx_fifo_eccstatus)
 );

assign o_av_st_tx_ms_data      = (AVST_MODE == "MAC_SEGMENTED") ? avst_tx_data  :'d0;
assign o_av_st_tx_ms_valid     = (AVST_MODE == "MAC_SEGMENTED") ? avst_tx_valid :'d0;
assign o_av_st_tx_ms_eop_empty = (AVST_MODE == "MAC_SEGMENTED") ? avst_tx_empty :'d0;
assign o_av_st_tx_data         = (AVST_MODE == "SOP_ALIGNED") ? avst_tx_data  : 'd0;
assign o_av_st_tx_valid        = (AVST_MODE == "SOP_ALIGNED") ? avst_tx_valid :'d0;
assign o_av_st_tx_empty        = (AVST_MODE == "SOP_ALIGNED") ? avst_tx_empty :'d0;

//--------------------------------------------------------------------------------------------------
//                   AVST to AXI ST conversion for MAC segmented, SOP aligned
//--------------------------------------------------------------------------------------------------
 avst_to_axist_rx_mac_seg_if_v2 #(
  .SIM_EMULATE    (SIM_EMULATE),
  .AVST_MODE     (AVST_MODE),
  .AVST_DW          (DATA_WIDTH),
  .EMPTY_BITS     (EMPTY_BITS),
  .AVST_ERR       (AVST_ERR),
  .FCS_ERR      (AVST_FCS_ERR),
  .MAC_STS      (AVST_MAC_STS),
  .AVST_USER     (USER_WIDTH_RX),
  .AXI_DW          (TDATA_WIDTH),
  .NO_OF_BYTES    (NO_OF_BYTES),
  .TUSER      (TUSER_WIDTH_RX),
  .AXI_ERR         (AXIST_ERR),
  .NUM_SEG          (NUM_SEG),
  .PKT_SEG_PARITY_EN(PKT_SEG_PARITY_EN)
 ) U_avst_to_axist_rx_mac_seg_if_inst (
  .i_rx_clk          (i_rx_clk ),   
  .i_rx_reset_n                (i_rx_reset_n),
  .i_avst_rx_valid             ((AVST_MODE == "MAC_SEGMENTED")? i_av_st_rx_ms_valid : i_av_st_rx_valid),
  .i_avst_rx_data              ((AVST_MODE == "MAC_SEGMENTED")? i_av_st_rx_ms_data : i_av_st_rx_data),
  .i_avst_rx_inframe           (i_av_st_rx_ms_inframe),
  .i_avst_rx_eop_empty         ((AVST_MODE == "MAC_SEGMENTED")? i_av_st_rx_ms_eop_empty : i_av_st_rx_empty),
  .i_avst_rx_user            (i_av_st_rx_user),
  .i_avst_rx_startofpacket     (i_av_st_rx_startofpacket),
  .i_avst_rx_endofpacket       (i_av_st_rx_endofpacket),
  .i_axi_st_rx_tready          (i_axi_st_rx_tready),
  .o_axist_rx_tvalid           (o_axi_st_rx_tvalid),
  .o_axist_rx_tdata            (o_axi_st_rx_tdata),
  .o_axist_rx_tlast            (o_axi_st_rx_tlast),
  .o_axist_rx_tlast_segment    (o_axi_st_rx_tlast_segment),
  .o_axist_rx_tkeep_segment    (axi_st_rx_tkeep),
  .o_axist_rx_tuser          (axi_st_rx_tuser),
  .o_axist_rx_tuser_valid    (axi_st_rx_tuser_valid),
  .o_axist_rx_pkt_seg_parity  (o_axi_st_rx_pkt_seg_parity)
  
 ); 
assign o_axi_st_rx_tuser    = axi_st_rx_tuser;
assign o_axi_st_rx_tuser_valid  = axi_st_rx_tuser_valid;
assign o_axi_st_rx_tkeep_segment = axi_st_rx_tkeep;
//assign o_axi_st_rx_tlast_segment = (AVST_MODE == "MAC_SEGMENTED")? axi_st_rx_tlast : '0 ;
assign o_axi_st_rx_tkeep    = axi_st_rx_tkeep;
// else begin

////MAC sop aligned
// end
// endgenerate

 
endmodule
