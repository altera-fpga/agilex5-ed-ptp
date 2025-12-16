//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

module ftile_ghrd_avst_axist_bridge #(
  parameter DATA_WIDTH    = 64,
  parameter NUM_CHANNELS  = 1,
  parameter NO_OF_BYTES   = 8, 
  parameter EMPTY_BITS    = 3, 
  parameter [3:0] READY_LATENCY [NUM_CHANNELS-1:0] = '{default:1},  // AXI Ready latency + Datapath Adapter delay
  parameter [0:0] PTP_TX_CLASSIFIER_ENABLE [NUM_CHANNELS-1:0] = '{default:0},
  parameter Tiles         = "F",
  parameter SIM_EMULATE   = 1
) (
  input                           i_tx_clk, //i_sl_async_clk_tx
  input                           i_tx_rst_n,
  input                           i_rx_clk, //i_sl_async_clk_rx
  input                           i_rx_rst_n,

  //AXI Stream Tx, from User interface
  input                           i_axi_st_tx_tready,
  output                          o_axi_st_tx_tvalid,
  output  [DATA_WIDTH-1:0]        o_axi_st_tx_tdata,
  output                          o_axi_st_tx_tlast,
  output  [NO_OF_BYTES-1:0]       o_axi_st_tx_tkeep,
  output  [1:0]                   o_axi_st_tx_tuser_client,
  output  [93:0]                  o_axi_st_tx_tuser_ptp,  //PTP signals are valid when tvalid is active?
  output  [327:0]                 o_axi_st_tx_tuser_ptp_extended,
  //Avalon Stream Tx, to EHIP/MAC interface
  output                          o_av_st_tx_ready,
  input                           i_av_st_tx_valid,
  input   [DATA_WIDTH-1:0]        i_av_st_tx_data,
  input                           i_av_st_tx_startofpacket,
  input                           i_av_st_tx_endofpacket,
  input   [EMPTY_BITS-1:0]        i_av_st_tx_empty,
  input                           i_av_st_tx_error,
  input                           i_av_st_tx_skip_crc,
  //tx_ptp
  input   [1:0]                   i_av_st_tx_ptp_ts_valid,
  input                           i_av_st_tx_ptp_ts_req,
  input                           i_av_st_tx_ptp_ins_ets,
  input   [31:0]                   i_av_st_tx_ptp_fp,
  input                           i_av_st_tx_ptp_ins_cf,
  input   [95:0]                  i_av_st_tx_ptp_tx_its,
  input   [6:0]                   i_av_st_tx_ptp_asym_p2p_idx,
  input                           i_av_st_tx_ptp_asym_sign,
  input                           i_av_st_tx_ptp_asym,
  input                           i_av_st_tx_ptp_p2p,
  //
  input                           i_av_st_tx_ptp_ts_format, 
  input                           i_av_st_tx_ptp_update_eb, 
  input                           i_av_st_tx_ptp_zero_csum, 
  input   [15:0]                  i_av_st_tx_ptp_eb_offset, 
  input   [15:0]                  i_av_st_tx_ptp_csum_offset, 
  input   [15:0]                  i_av_st_tx_ptp_cf_offset, 
  input   [15:0]                  i_av_st_tx_ptp_ts_offset, 

  //Avalon Stream Rx, from EHIP/MAC interface
  output                          o_av_st_rx_valid,
  output  [DATA_WIDTH-1:0]        o_av_st_rx_data,
  output                          o_av_st_rx_startofpacket,
  output                          o_av_st_rx_endofpacket,
  output  [EMPTY_BITS-1:0]        o_av_st_rx_empty,
  output  [5:0]                   o_av_st_rx_error,
  output  [39:0]                  o_av_st_rxstatus_data,
  output                          o_av_st_rxstatus_valid,
  output  [95:0]                  o_av_st_ptp_rx_its,

  //AXI Stream Rx, to User interface
  input                           i_axi_st_rx_tvalid,
  input   [DATA_WIDTH-1:0]        i_axi_st_rx_tdata,
  input                           i_axi_st_rx_tlast,
  input   [NO_OF_BYTES-1:0]       i_axi_st_rx_tkeep,
  input   [6:0]                   i_axi_st_rx_tuser_client,
  input   [4:0]                   i_axi_st_rx_tuser_sts,
  input   [31:0]                  i_axi_st_rx_tuser_sts_extended,
  input   [95:0]                  i_axi_st_rx_ingrts0_tdata,
  input                           i_axi_st_rx_ingrts0_tvalid
);

//***********************************************************
//                 PARAMETERS
//***********************************************************
  localparam TILES                    = Tiles;
  localparam PORT_CLIENT_IF           = 1;
  localparam NUM_SEG                  = (PORT_CLIENT_IF == 1)? 1: (DATA_WIDTH/64);  //8 bytes per segment
  localparam AVST_ERR                 = 2*NUM_SEG;   
  localparam AVST_FCS_ERR             = 1*NUM_SEG;   
  localparam AVST_MAC_STS             = 3*NUM_SEG;   
  localparam USER_WIDTH_TX            = AVST_ERR +90 +328;
  localparam USER_WIDTH_RX            = AVST_ERR +90 +328;
  //parameter AXIST_MODE           = "SINGLE_PACKET"; 
  localparam TDATA_WIDTH              = 64;
//  localparam NO_OF_BYTES              = (PORT_CLIENT_IF == 1)?TDATA_WIDTH/8:8; 
  localparam TUSER_WIDTH_TX           = AVST_ERR +90 +328;
  localparam TUSER_WIDTH_RX           = AVST_ERR +90 +328;
  localparam AXIST_ERR                = 2*NUM_SEG;
  localparam ST_READY_LATENCY         = 1;  
  localparam ENABLE_MULTI_STREAM      = 0;  
  localparam NUM_OF_STREAM            = 1;  
  localparam PKT_SEG_PARITY_EN        = 0;
  localparam ENABLE_ECC               = 1;
  localparam USE_M20K                 = "ON";
  localparam PTP_WIDTH                = 'd90;
  localparam PTP_EXT_WIDTH            = 'd328;


//***********************************************************
//                 WIRES and REGS
//***********************************************************

  wire  [USER_WIDTH_TX-1:0]      i_av_st_tx_user;
  wire  [USER_WIDTH_TX-1:0]      o_axi_st_tx_tuser;
  wire  [USER_WIDTH_RX-1:0]      i_axi_st_rx_tuser;
  wire  [USER_WIDTH_RX-1:0]      o_av_st_rx_user;
  wire  [PTP_WIDTH-1:0]          av_st_tx_ptp;
  wire  [PTP_EXT_WIDTH-1:0]      av_st_tx_ptp_ext;

  reg                            o_av_st_tx_ready_reg;




axist_to_avst_bridge_v2 #(
  .TILES                    (TILES),
  .SIM_EMULATE              (SIM_EMULATE),
  .PORT_CLIENT_IF           (PORT_CLIENT_IF),
  .DATA_WIDTH               (DATA_WIDTH),
  .NUM_SEG                  (NUM_SEG),
  .NUM_CHANNELS             (NUM_CHANNELS),
  .EMPTY_BITS               (EMPTY_BITS),
  .AVST_ERR                 (AVST_ERR),
  .AVST_FCS_ERR             (AVST_FCS_ERR),
  .AVST_MAC_STS             (AVST_MAC_STS),
  .USER_WIDTH_TX            (USER_WIDTH_TX),
  .USER_WIDTH_RX            (USER_WIDTH_RX),
  //parameter AXIST_MODE                  ),
  .TDATA_WIDTH              (TDATA_WIDTH),
  .NO_OF_BYTES              (NO_OF_BYTES),
  .TUSER_WIDTH_TX           (TUSER_WIDTH_TX),
  .TUSER_WIDTH_RX           (TUSER_WIDTH_RX),
  .AXIST_ERR                (AXIST_ERR),
  .ST_READY_LATENCY         (ST_READY_LATENCY),
  .ENABLE_MULTI_STREAM      (ENABLE_MULTI_STREAM),
  .NUM_OF_STREAM            (NUM_OF_STREAM),
  .PKT_SEG_PARITY_EN        (PKT_SEG_PARITY_EN),
  .ENABLE_ECC               (ENABLE_ECC),
  .USE_M20K                 (USE_M20K)
 
) u_axist_to_avst_bridge_v2 (
  .i_tx_clk                                              ( i_rx_clk), 
  .i_tx_reset_n                                          ( i_rx_rst_n),
  .i_rx_clk                                              ( i_tx_clk), 
  .i_rx_reset_n                                          ( i_tx_rst_n),
/////////// TX ports ///////////////////       
  //AXI Stream Tx, from User interface   
  //SINGLE PACKET COMPATIBLE SIGNALS              
  .i_axi_st_tx_tvalid                                    ( i_axi_st_rx_tvalid),
  .i_axi_st_tx_tdata                                     ( i_axi_st_rx_tdata),
  .i_axi_st_tx_tlast                                     ( i_axi_st_rx_tlast),
  .i_axi_st_tx_tkeep                                     ( i_axi_st_rx_tkeep),
  .i_axi_st_tx_tuser                                     ( i_axi_st_rx_tuser),
  //MULTI PACKET COMPATIBLE SIGNALS           
  .i_axi_st_tx_tlast_segment                             ( i_axi_st_rx_tlast/*i_axi_st_rx_tlast_segment*/),
  .i_axi_st_tx_tkeep_segment                             ( i_axi_st_rx_tkeep/*i_axi_st_rx_tkeep_segment*/),
  .i_axi_st_tx_pkt_seg_parity                            ( 1'b0 /*i_axi_st_rx_pkt_seg_parity*/),
  .o_axi_st_tx_tready                                    ( o_axi_st_rx_tready),
 
  //Avalon Stream Tx, to MAC interface     
   //SOP ALIGNED COMPATIBLE SIGNALS     
  .i_av_st_tx_ready                                      ( 1'b1 ),
  .o_av_st_tx_data                                       ( o_av_st_rx_data),
  .o_av_st_tx_valid                                      ( o_av_st_rx_valid),
  .o_av_st_tx_startofpacket                              ( o_av_st_rx_startofpacket),
  .o_av_st_tx_endofpacket                                ( o_av_st_rx_endofpacket),
  .o_av_st_tx_empty                                      ( o_av_st_rx_empty),
  .o_av_st_tx_user                                       ( o_av_st_rx_user),
   //MAC_SEGMENTED COMPATIBLE SIGNALS     
  .i_av_st_tx_ms_ready                                   ( 1'b0/*i_av_st_tx_ms_ready*/),
  .o_av_st_tx_ms_data                                    ( /*o_av_st_tx_ms_data*/),
  .o_av_st_tx_ms_valid                                   ( /*o_av_st_tx_ms_valid*/),
  .o_av_st_tx_ms_inframe                                 ( /*o_av_st_tx_ms_inframe*/),
  .o_av_st_tx_ms_eop_empty                               ( /*o_av_st_tx_ms_eop_empty*/),
  .o_tx_fifo_eccstatus                                   ( /*o_tx_fifo_eccstatus*/), 
  .o_axi_st_tx_parity_error                              ( /*o_axi_st_tx_parity_error*/), 
           
/////////// RX ports ////////////////////      
 //////////////////////////////////////////             
  //Avalon Stream Rx, from MAC interface   
 //SOP ALIGNED COMPATIBLE SIGNALS           
  .o_axi_st_rx_ready                                    (/* o_av_st_tx_ready*/), //TBD
  .i_av_st_rx_data                                       ( i_av_st_tx_data),
  .i_av_st_rx_valid                                      ( i_av_st_tx_valid),
  .i_av_st_rx_startofpacket                              ( i_av_st_tx_startofpacket),
  .i_av_st_rx_endofpacket                                ( i_av_st_tx_endofpacket),
  .i_av_st_rx_empty                                      ( i_av_st_tx_empty),
  .i_av_st_rx_user                                       ( i_av_st_tx_user),
 //MAC_SEGMENTED COMPATIBLE SIGNALS           
  .i_av_st_rx_ms_data                                    ( 'd0 /*i_av_st_rx_ms_data*/),
  .i_av_st_rx_ms_valid                                   ( 'd0 /*i_av_st_rx_ms_valid*/),
  .i_av_st_rx_ms_inframe                                 ( 'd0 /*i_av_st_rx_ms_inframe*/),
  .i_av_st_rx_ms_eop_empty                               ( 'd0 /*i_av_st_rx_ms_eop_empty*/),
            
  //AXI Stream Rx, to User interface     
  .i_axi_st_rx_tready                                    ( i_axi_st_tx_tready),
  .o_axi_st_rx_tvalid                                    ( o_axi_st_tx_tvalid),
  .o_axi_st_rx_tdata                                     ( o_axi_st_tx_tdata),
  .o_axi_st_rx_tlast                                     ( o_axi_st_tx_tlast),
  .o_axi_st_rx_tkeep                                     ( o_axi_st_tx_tkeep),
  .o_axi_st_rx_tuser                                     ( o_axi_st_tx_tuser),
  .o_axi_st_rx_tuser_valid                               ( o_axi_st_tx_tuser_valid),
 
 //MULTI PACKET COMPATIBLE SIGNALS           
  .o_axi_st_rx_tlast_segment                             ( /*o_axi_st_tx_tlast_segment */),
  .o_axi_st_rx_tkeep_segment                             ( /*o_axi_st_tx_tkeep_segment */),
  .o_axi_st_rx_pkt_seg_parity                            ( /*o_axi_st_tx_pkt_seg_parity*/)

);

//// ready signal from HSSI to USER/HPS side
//  always @(posedge i_tx_clk or negedge i_tx_rst_n)
//  begin
//    if (!i_tx_rst_n)
//      o_av_st_tx_ready_reg <= 1'b0;
//    else 
//      o_av_st_tx_ready_reg <= i_axi_st_tx_tready;
//  end

//  assign o_av_st_tx_ready = o_av_st_tx_ready_reg;
  assign o_av_st_tx_ready = i_axi_st_tx_tready; 
//--------------------------------------------------------
// user signals from USER side to HSSI side - TX
//--------------------------------------------------------
  generate
  if(Tiles == "F")
  begin
    assign av_st_tx_ptp[1:0]=      i_av_st_tx_ptp_ts_valid[1:0]     ; 
    assign av_st_tx_ptp[2]=        i_av_st_tx_ptp_ts_req            ; 
    assign av_st_tx_ptp[3]=        i_av_st_tx_ptp_ins_ets           ; 
    assign av_st_tx_ptp[10:4]=     i_av_st_tx_ptp_asym_p2p_idx[6:0] ; 
    assign av_st_tx_ptp[11]=       i_av_st_tx_ptp_asym_sign         ; 
    assign av_st_tx_ptp[12]=       i_av_st_tx_ptp_asym              ; 
    assign av_st_tx_ptp[13]=       i_av_st_tx_ptp_p2p               ; 
    assign av_st_tx_ptp[45:14]=    i_av_st_tx_ptp_fp   ; 
    assign av_st_tx_ptp[46]=       1'b0/*i_av_st_tx_ptp_ts_req[1]*/         ; 
    assign av_st_tx_ptp[47]=       1'b0/*i_av_st_tx_ptp_ins_ets[1]*/        ; 
    assign av_st_tx_ptp[54:48]=    7'd0/*i_av_st_tx_ptp_asym_p2p_idx[13:7]*/;
    assign av_st_tx_ptp[55]=       1'b0/*i_av_st_tx_ptp_asym_sign[1]*/      ; 
    assign av_st_tx_ptp[56]=       1'b0/*i_av_st_tx_ptp_asym[1]*/           ; 
    assign av_st_tx_ptp[57]=       1'b0/*i_av_st_tx_ptp_p2p[1]*/            ; 
    assign av_st_tx_ptp[89:58]=    32'd0/*i_av_st_tx_ptp_fp[63:32]*/        ; 
    //
    assign av_st_tx_ptp_ext[164]=     1'b0/*i_av_st_tx_ptp_ins_cf[1]*/      ; 
    assign av_st_tx_ptp_ext[260:165]= 96'd0/*i_av_st_tx_ptp_tx_its[191:96]*/; 
    assign av_st_tx_ptp_ext[327:261]= 67'd0                                 ; 
  end
  endgenerate

  assign av_st_tx_ptp_ext[0]=          i_av_st_tx_ptp_ins_cf        ; 
  assign av_st_tx_ptp_ext[96:1]=       i_av_st_tx_ptp_tx_its[95:0]  ; 
  assign av_st_tx_ptp_ext[97]=         i_av_st_tx_ptp_ts_format     ; 
  assign av_st_tx_ptp_ext[98]=         i_av_st_tx_ptp_update_eb     ; 
  assign av_st_tx_ptp_ext[99]=         i_av_st_tx_ptp_zero_csum     ; 
  assign av_st_tx_ptp_ext[115:100]=    i_av_st_tx_ptp_eb_offset     ; 
  assign av_st_tx_ptp_ext[131:116]=    i_av_st_tx_ptp_csum_offset   ; 
  assign av_st_tx_ptp_ext[147:132]=    i_av_st_tx_ptp_cf_offset     ; 
  assign av_st_tx_ptp_ext[163:148]=    i_av_st_tx_ptp_ts_offset     ; 


  assign i_av_st_tx_user = {i_av_st_tx_skip_crc,i_av_st_tx_error,av_st_tx_ptp_ext,av_st_tx_ptp};
  assign o_axi_st_tx_tuser_client        = o_axi_st_tx_tuser[2+PTP_WIDTH+PTP_EXT_WIDTH-1:PTP_WIDTH+PTP_EXT_WIDTH];
  assign o_axi_st_tx_tuser_ptp_extended  = o_axi_st_tx_tuser[PTP_WIDTH+PTP_EXT_WIDTH-1:PTP_WIDTH];
  assign o_axi_st_tx_tuser_ptp           = o_axi_st_tx_tuser[PTP_WIDTH-1:0];

//--------------------------------------------------
// user signals from HSSI side to USER side - RX
//--------------------------------------------------
  assign i_axi_st_rx_tuser[419:141] =  279'd0;
  assign i_axi_st_rx_tuser[140]     =  i_axi_st_rx_ingrts0_tvalid;
  assign i_axi_st_rx_tuser[139:44]  =  i_axi_st_rx_ingrts0_tdata;
  assign i_axi_st_rx_tuser[43:12]   =  i_axi_st_rx_tuser_sts_extended;
  assign i_axi_st_rx_tuser[11:7]    =  i_axi_st_rx_tuser_sts ;
  assign i_axi_st_rx_tuser[6:0]     =  i_axi_st_rx_tuser_client;

  assign o_av_st_rx_error           = (o_av_st_rx_endofpacket & o_av_st_rx_valid) ? {1'b0,o_av_st_rx_user[4:0]} : 6'd0;
  assign o_av_st_rxstatus_data      = (o_av_st_rx_endofpacket & o_av_st_rx_valid) ? {35'd0,o_av_st_rx_user[11:7]} : 40'd0;
//  assign o_av_st_rxstatus_valid     = (o_av_st_rx_endofpacket & o_av_st_rx_valid) ? 1'b1 : 1'b0;
  assign o_av_st_rxstatus_valid     = o_av_st_rx_startofpacket;
  assign o_av_st_ptp_rx_its         = o_av_st_rx_user[139:44];



//    function integer clog2;
//    input integer value;
//    begin
//      value = value-1;
//      for (clog2=0; value>0; clog2=clog2+1)
//        value = value>>1;
//    end
//    endfunction

endmodule //ftile_ghrd_avst_axist_bridge
