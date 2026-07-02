//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


// ==========================================================================
// Project           : HSSI Subsystem 
// Module            : axist_to_avst_bridge.sv
// Description       : 
// Author            : 
// Created           : 
// Changes           : 
//                   : 
// ==========================================================================


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on


module axist_to_avst_bridge #(
    parameter PORT_PROFILE          = "400GBE",                                                                    
    parameter DATA_WIDTH            = 256,                                                                         
    parameter PORT_CLIENT_IF        = 0,  //0 -Multi packet or MAC SEG;   1'b1 : Single packet or AVST SOP         
    parameter NUM_SEG               = (PORT_CLIENT_IF == 1)? 1: (DATA_WIDTH/64),  //8 bytes per segment            
    parameter NUM_MAX_PORTS         = 4,                                                                            
    parameter DR_ENABLE             = 1,                                                                            
    //AXI Side
    parameter TDATA_WIDTH           = 64,                                                                          
    parameter NO_OF_BYTES           = (PORT_CLIENT_IF == 1)?TDATA_WIDTH/8:8,                                       
    parameter TUSER_WIDTH_TX        = 2 +94 +328,                                                                  
    parameter TUSER_WIDTH_RX        = 2 +94 +328,                                                                  
    parameter ST_READY_LATENCY      = 1,                                                                           
    // parameter ENABLE_MULTI_STREAM   = 0,                                                                        
    parameter NUM_OF_STREAM         = 1,                                                                        
    parameter PKT_SEG_PARITY_EN     = 0,
    parameter PKT_SEG_PARITY_WIDTH  = 4,         //macseg - [NUM_SEG-1:0], sopa - [(NUM_MAX_PORTS-1:0]  
    //AVST Side
    //parameter DATA_WIDTH          = 64,
    //parameter EMPTY_BITS          = 3,        
    parameter EMPTY_BITS            = (PORT_CLIENT_IF == 1)? $clog2(TDATA_WIDTH/8) : 3, //3 for mac seg (In RTL num_seg*3 is the port width), SOP DR - 25-2:0,50-5:0,100-11:0, SOP Non DR 25-2:0,50-3:0,100-5:0
    parameter USER_WIDTH_TX         = 2 +94 +328,                                                                  
    parameter USER_WIDTH_RX         = 2 +94 +328,                                                                  
    //                                                                                                             
    parameter ENABLE_ECC            = 1,                                                                           
    // parameter USE_M20K              = "ON",                                                                        
    parameter SIM_EMULATE           = 0                                                                            
    
) (
    input                                            i_tx_clk_p0, 
    input                                            i_tx_clk_p1, 
    input                                            i_tx_clk_p2, 
    input                                            i_tx_clk_p3, 
    input                                            i_tx_reset_n_p0,
    input                                            i_tx_reset_n_p1,
    input                                            i_tx_reset_n_p2,
    input                                            i_tx_reset_n_p3,
    input                                            i_rx_clk_p0, 
    input                                            i_rx_clk_p1, 
    input                                            i_rx_clk_p2, 
    input                                            i_rx_clk_p3, 
    input                                            i_rx_reset_n_p0,
    input                                            i_rx_reset_n_p1,
    input                                            i_rx_reset_n_p2,
    input                                            i_rx_reset_n_p3,
    
    //CSR
    input       [NUM_MAX_PORTS-1:0]                  i_port_active_mask_reg,
    input       [2:0]                                i_active_ports,
    input       [2:0]                                i_active_segments,
    input       [2:0]                                i_port_data_width,
    
    /////////// TX ports ///////////////////                    
    //AXI Stream Tx, from User interface         
    //SINGLE PACKET COMPATIBLE SIGNALS                     
    input       [NUM_MAX_PORTS-1:0]                  i_axi_st_tx_tvalid,                          
    input       [TDATA_WIDTH-1:0]                    i_axi_st_tx_tdata,                           
    input       [NUM_MAX_PORTS-1:0]                  i_axi_st_tx_tlast,                           
    input       [NO_OF_BYTES-1:0]                    i_axi_st_tx_tkeep,                           
    input       [NUM_MAX_PORTS*TUSER_WIDTH_TX-1:0]   i_axi_st_tx_tuser,                           
    //MULTI PACKET COMPATIBLE SIGNALS               
    input       [NUM_SEG-1:0]                        i_axi_st_tx_tlast_segment,                   
    input       [NUM_SEG*8-1:0]                      i_axi_st_tx_tkeep_segment,                   
    input       [PKT_SEG_PARITY_WIDTH-1:0]           i_axi_st_tx_pkt_seg_parity,                  
    output reg  [NUM_MAX_PORTS-1:0]                  o_axi_st_tx_tready,  

    //Avalon Stream Tx, to MAC interface           
    //SOP ALIGNED COMPATIBLE SIGNALS         
    input       [NUM_MAX_PORTS-1:0]                  i_av_st_tx_ready,                             
    output      [DATA_WIDTH-1:0]                     o_av_st_tx_data,                              
    output      [NUM_MAX_PORTS-1:0]                  o_av_st_tx_valid,                             
    output reg  [NUM_MAX_PORTS-1:0]                  o_av_st_tx_startofpacket,                     
    output reg  [NUM_MAX_PORTS-1:0]                  o_av_st_tx_endofpacket,                       
    output      [EMPTY_BITS-1:0]                     o_av_st_tx_empty,  
    output reg  [NUM_MAX_PORTS*USER_WIDTH_TX-1:0]    o_av_st_tx_user,                              
    //MAC_SEGMENTED COMPATIBLE SIGNALS                                                             
    input       [NUM_MAX_PORTS-1:0]                  i_av_st_tx_ms_ready,                          
    output      [DATA_WIDTH-1:0]                     o_av_st_tx_ms_data,                           
    output      [NUM_MAX_PORTS-1:0]                  o_av_st_tx_ms_valid,                          
    output reg  [NUM_SEG-1:0]                        o_av_st_tx_ms_inframe,                        
    output reg  [NUM_SEG*EMPTY_BITS-1:0]             o_av_st_tx_ms_eop_empty,                      
    output reg  [(NUM_MAX_PORTS*2)-1:0]              o_tx_fifo_eccstatus,                          
    output      [NUM_MAX_PORTS-1:0]                  o_axi_st_tx_parity_error,  //To be updated ww12p4                   
    //output reg  [USER_WIDTH_TX-1:0]                o_av_st_tx_ms_user,
                                                 
    /////////// RX ports ////////////////////        
    //////////////////////////////////////////                                               
    //Avalon Stream Rx, from MAC interface       
    //SOP ALIGNED COMPATIBLE SIGNALS                 
    input   [DATA_WIDTH-1:0]                         i_av_st_rx_data,
    input   [NUM_MAX_PORTS-1:0]                      i_av_st_rx_valid,
    input   [NUM_MAX_PORTS-1:0]                      i_av_st_rx_startofpacket,
    input   [NUM_MAX_PORTS-1:0]                      i_av_st_rx_endofpacket,
    input   [EMPTY_BITS-1:0]                         i_av_st_rx_empty,
    input   [NUM_MAX_PORTS*USER_WIDTH_RX-1:0]        i_av_st_rx_user,
    
    //MAC_SEGMENTED COMPATIBLE SIGNALS               
    input   [DATA_WIDTH-1:0]                         i_av_st_rx_ms_data,
    input   [NUM_MAX_PORTS-1:0]                      i_av_st_rx_ms_valid,
    input   [NUM_SEG-1:0]                            i_av_st_rx_ms_inframe,
    input   [NUM_SEG*EMPTY_BITS-1:0]                 i_av_st_rx_ms_eop_empty,
    //input   [TUSER_WIDTH_RX-1:0]                   i_av_st_rx_ms_user,
                                                     
    //AXI Stream Rx, to User interface               
    output reg [NUM_MAX_PORTS-1:0]                   o_axi_st_rx_tready, //TBD
    output reg [NUM_MAX_PORTS-1:0]                   o_axi_st_rx_tvalid,
    output reg [TDATA_WIDTH-1:0]                     o_axi_st_rx_tdata,
    output reg [NUM_MAX_PORTS-1:0]                   o_axi_st_rx_tlast,
    output reg [NO_OF_BYTES-1:0]                     o_axi_st_rx_tkeep,
    output reg [NUM_MAX_PORTS*TUSER_WIDTH_RX-1:0]    o_axi_st_rx_tuser,
    output reg [NUM_MAX_PORTS-1:0]                   o_axi_st_rx_tuser_valid,
    output reg [NUM_MAX_PORTS-1:0]                   o_axi_st_rx_tuser_valid_p2,
    
    //MULTI PACKET COMPATIBLE SIGNALS                
    output reg [NUM_SEG-1:0]                         o_axi_st_rx_tlast_segment,
    output reg [NUM_SEG*8-1:0]                       o_axi_st_rx_tkeep_segment,
    output reg [PKT_SEG_PARITY_WIDTH-1:0]            o_axi_st_rx_pkt_seg_parity                                            
);

//***********************************************************
//***********************************************************
localparam AVST_MODE  = (PORT_CLIENT_IF == 0) ? "MAC_SEGMENTED" : "SOP_ALIGNED";
localparam AXIST_MODE = (PORT_CLIENT_IF == 0) ? "MULTI_PACKET"  : "SINGLE_PACKET";

wire    [DATA_WIDTH-1:0]                    avst_tx_data;     
wire    [NUM_MAX_PORTS-1:0]                 avst_tx_valid;   
wire    [NUM_SEG*EMPTY_BITS-1:0]            avst_tx_empty;
wire    [NUM_MAX_PORTS*TUSER_WIDTH_RX-1:0]  axi_st_rx_tuser;
wire    [NUM_MAX_PORTS-1:0]                 axi_st_rx_tuser_valid;
wire    [NUM_MAX_PORTS-1:0]                 axi_st_rx_tuser_valid_p2;

logic   [NUM_MAX_PORTS-1:0]                 tx_port_active_mask_reg;                           
logic   [2:0]                               tx_active_port;
logic   [2:0]                               tx_active_segment;
logic   [2:0]                               tx_port_data_width;      

logic    [NUM_MAX_PORTS-1:0]                rx_port_active_mask_reg;
logic    [2:0]                              rx_active_port      ;
logic    [2:0]                              rx_active_segment;
logic    [2:0]                              rx_port_data_width;  

//--------------------------------------------------------------------------------------------------
//                   AXI ST to AVST conversion for MAC segmented, SOP aligned
//--------------------------------------------------------------------------------------------------

    axist_to_avst_tx_mac_seg_if #(  
        .SIM_EMULATE           (SIM_EMULATE),  
        .AVST_MODE             (AVST_MODE),
        .AVST_DW               (DATA_WIDTH), 
        .EMPTY_BITS            (EMPTY_BITS),
        .AVST_USER             (USER_WIDTH_TX),
        .AXIST_MODE            (AXIST_MODE),
        .AXI_DW                (TDATA_WIDTH),
        .NO_OF_BYTES           (NO_OF_BYTES),
        .TUSER                 (TUSER_WIDTH_TX),
        .NUM_SEG               (NUM_SEG), 
        .READY_LATENCY         (ST_READY_LATENCY),
        .PKT_SEG_PARITY_EN     (PKT_SEG_PARITY_EN),
        .ENABLE_ECC            (ENABLE_ECC),
        .NUM_MAX_PORTS         (NUM_MAX_PORTS),
        .PORT_PROFILE          (PORT_PROFILE),
        // .USE_M20K              (USE_M20K),
        .PKT_SEG_PARITY_WIDTH  (PKT_SEG_PARITY_WIDTH),
        .DR_ENABLE             (DR_ENABLE)
        
    ) U_axist_to_avst_tx_mac_seg_if_inst (
        .i_tx_clk_p0                 (i_tx_clk_p0),
        .i_tx_clk_p1                 (i_tx_clk_p1),
        .i_tx_clk_p2                 (i_tx_clk_p2),
        .i_tx_clk_p3                 (i_tx_clk_p3),
        .i_tx_reset_n_p0             (i_tx_reset_n_p0),
        .i_tx_reset_n_p1             (i_tx_reset_n_p1),
        .i_tx_reset_n_p2             (i_tx_reset_n_p2),
        .i_tx_reset_n_p3             (i_tx_reset_n_p3),
        .i_port_active_mask          (tx_port_active_mask_reg),    
        .i_port_data_width           (tx_port_data_width),    
        .i_active_ports              (tx_active_port),    
        .i_active_segments           (tx_active_segment),    
        .o_axist_tx_tready           (o_axi_st_tx_tready),
        .i_axist_tx_tvalid           (i_axi_st_tx_tvalid),
        .i_axist_tx_tdata            (i_axi_st_tx_tdata),
        .i_axist_tx_tlast            (i_axi_st_tx_tlast),
        .i_axist_tx_tkeep            (i_axi_st_tx_tkeep),
        .i_axist_tx_tlast_segment    (i_axi_st_tx_tlast_segment),
        .i_axist_tx_tkeep_segment    (i_axi_st_tx_tkeep_segment),
        .i_axist_tx_tuser            (i_axi_st_tx_tuser),
        .i_axist_tx_pkt_seg_parity   (i_axi_st_tx_pkt_seg_parity),
        
        .i_avst_tx_ready             ((AVST_MODE == "MAC_SEGMENTED") ? i_av_st_tx_ms_ready : i_av_st_tx_ready),
        .o_avst_tx_data              (avst_tx_data),
        .o_avst_tx_valid             (avst_tx_valid),
        .o_avst_tx_inframe           (o_av_st_tx_ms_inframe),
        .o_avst_tx_eop_empty         (avst_tx_empty),
        .o_avst_tx_startofpacket     (o_av_st_tx_startofpacket),
        .o_avst_tx_endofpacket       (o_av_st_tx_endofpacket),      
        .o_avst_tx_user              (o_av_st_tx_user),
        .o_axist_tx_parity_error     (o_axi_st_tx_parity_error),
        .o_fifo_eccstatus            (o_tx_fifo_eccstatus)
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
    avst_to_axist_rx_mac_seg_if #(
        .SIM_EMULATE           (SIM_EMULATE),
        .AVST_MODE             (AVST_MODE),
        .AVST_DW               (DATA_WIDTH),
        .PORT_PROFILE          (PORT_PROFILE),
        .EMPTY_BITS            (EMPTY_BITS),
        .AVST_USER             (USER_WIDTH_RX),
        .AXI_DW                (TDATA_WIDTH),
        .NO_OF_BYTES           (NO_OF_BYTES),
        .TUSER                 (TUSER_WIDTH_RX),
        .NUM_SEG               (NUM_SEG),
        .NUM_MAX_PORTS         (NUM_MAX_PORTS),
        .PKT_SEG_PARITY_EN     (PKT_SEG_PARITY_EN),
        .PKT_SEG_PARITY_WIDTH  (PKT_SEG_PARITY_WIDTH),
        .DR_ENABLE             (DR_ENABLE)
    ) U_avst_to_axist_rx_mac_seg_if_inst (
        .i_rx_clk_p0                 (i_rx_clk_p0 ),          
        .i_rx_clk_p1                 (i_rx_clk_p1 ),          
        .i_rx_clk_p2                 (i_rx_clk_p2 ),          
        .i_rx_clk_p3                 (i_rx_clk_p3 ),          
        .i_rx_reset_n_p0             (i_rx_reset_n_p0),
        .i_rx_reset_n_p1             (i_rx_reset_n_p1),
        .i_rx_reset_n_p2             (i_rx_reset_n_p2),
        .i_rx_reset_n_p3             (i_rx_reset_n_p3),
        .i_port_active_mask          (rx_port_active_mask_reg),    
        .i_port_data_width           (rx_port_data_width),    
        .i_active_ports              (rx_active_port),    
        .i_active_segments           (rx_active_segment),           
        .i_avst_rx_valid             ((AVST_MODE == "MAC_SEGMENTED")? i_av_st_rx_ms_valid : i_av_st_rx_valid),
        .i_avst_rx_data              ((AVST_MODE == "MAC_SEGMENTED")? i_av_st_rx_ms_data : i_av_st_rx_data),
        .i_avst_rx_inframe           (i_av_st_rx_ms_inframe),
        .i_avst_rx_eop_empty         ((AVST_MODE == "MAC_SEGMENTED")? i_av_st_rx_ms_eop_empty : i_av_st_rx_empty),
        .i_avst_rx_user              (i_av_st_rx_user),
        .i_avst_rx_startofpacket     (i_av_st_rx_startofpacket),
        .i_avst_rx_endofpacket       (i_av_st_rx_endofpacket),  
        .o_axist_rx_tvalid           (o_axi_st_rx_tvalid),
        .o_axist_rx_tdata            (o_axi_st_rx_tdata),
        .o_axist_rx_tlast            (o_axi_st_rx_tlast),
        .o_axist_rx_tkeep            (o_axi_st_rx_tkeep),
        .o_axist_rx_tlast_segment    (o_axi_st_rx_tlast_segment),
        .o_axist_rx_tkeep_segment    (o_axi_st_rx_tkeep_segment),
        .o_axist_rx_tuser            (axi_st_rx_tuser),
        .o_axist_rx_tuser_valid      (axi_st_rx_tuser_valid),
        .o_axist_rx_tuser_valid_p2   (axi_st_rx_tuser_valid_p2),
        .o_axist_rx_pkt_seg_parity   (o_axi_st_rx_pkt_seg_parity)
    );  
assign o_axi_st_rx_tuser            = axi_st_rx_tuser;
assign o_axi_st_rx_tuser_valid      = axi_st_rx_tuser_valid;
assign o_axi_st_rx_tuser_valid_p2   = axi_st_rx_tuser_valid_p2;

assign tx_active_port               = i_active_ports;
assign tx_active_segment            = i_active_segments;
assign tx_port_active_mask_reg      = i_port_active_mask_reg;
assign tx_port_data_width           = i_port_data_width;

assign rx_active_port               = i_active_ports;
assign rx_active_segment            = i_active_segments;
assign rx_port_active_mask_reg      = i_port_active_mask_reg;
assign rx_port_data_width           = i_port_data_width;      

/*
always @(posedge i_tx_clk or negedge i_tx_reset_n) begin //FHT-200G-2
   if (~i_tx_reset_n) begin
      tx_active_port           <= 3'd0;
      tx_active_segment        <= 3'd0;
      tx_port_active_mask_reg  <= {NUM_MAX_PORTS{1'b0}};
      tx_port_data_width       <= 3'd0;
   end
   else 
   begin
      tx_active_port           <= i_active_ports;
      tx_active_segment        <= i_active_segments;
      tx_port_active_mask_reg  <= i_port_active_mask_reg;
      tx_port_data_width       <= i_port_data_width;
   
   end
end

hssi_ss_resync_std #(
  .SYNC_CHAIN_LENGTH(3),    
  .WIDTH(3),  
  .INIT_VALUE(0)
    ) U_profile_sel_sync_ap(
      .clk     (i_rx_clk),
      .reset   (1'b0),
      .d       (i_active_ports),
      .q       (rx_active_port)
    );
    
hssi_ss_resync_std #(
  .SYNC_CHAIN_LENGTH(3),    
  .WIDTH(3),  
  .INIT_VALUE(0)
    ) U_profile_sel_sync_as(
      .clk     (i_rx_clk),
      .reset   (1'b0),
      .d       (i_active_segments),
      .q       (rx_active_segment)
    );  
    
hssi_ss_resync_std #(
  .SYNC_CHAIN_LENGTH(3),    
  .WIDTH(NUM_MAX_PORTS),  
  .INIT_VALUE(0)
    ) U_profile_sel_sync_am(
      .clk     (i_rx_clk),
      .reset   (1'b0),
      .d       (i_port_active_mask_reg),
      .q       (rx_port_active_mask_reg)
    );      
    
hssi_ss_resync_std #(
  .SYNC_CHAIN_LENGTH(3),    
  .WIDTH(3),  
  .INIT_VALUE(0)
    ) U_profile_sel_sync_dw(
      .clk     (i_rx_clk),
      .reset   (1'b0),
      .d       (i_port_data_width),
      .q       (rx_port_data_width)
    );      
*/  

/*
always @(posedge i_rx_clk or negedge i_rx_reset_n) begin //FHT-200G-2
   if (~i_rx_reset_n) begin
      rx_active_port           <= 3'd0;
      rx_active_segment        <= 3'd0;
      rx_port_active_mask_reg  <= {NUM_MAX_PORTS{1'b0}};
      rx_port_data_width       <= 3'd0;
   end
   else 
   begin
      rx_active_port           <= i_active_ports;
      rx_active_segment        <= i_active_segments;
      rx_port_active_mask_reg  <= i_port_active_mask_reg;
      rx_port_data_width       <= i_port_data_width;           
   end
end
*/

endmodule
