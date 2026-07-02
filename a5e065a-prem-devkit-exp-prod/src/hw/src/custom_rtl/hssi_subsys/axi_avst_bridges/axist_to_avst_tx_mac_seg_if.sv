//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


// ==========================================================================
// Project           : HSSI Subsystem 
// Module            : axist_to_avst_tx_mac_seg_if.sv
// Description       : 
// Author            : 
// Created           : 
// Changes           : 
//                   : 
// ==========================================================================

// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

module axist_to_avst_tx_mac_seg_if #(
    parameter SIM_EMULATE        = 1,
    parameter AVST_MODE          = "MAC_SEGMENTED",
    parameter AVST_DW            = 64,
    parameter NUM_SEG            = (AVST_MODE == "SOP_ALIGNED")?1:(AVST_DW/64),  //8 bytes per segment
    parameter EMPTY_BITS         = 3, //3*num_seg for mac seg, SOP DR - 25-2:0,50-5:0,100-11:0, SOP Non DR 25-2:0,50-3:0,100-5:0
    parameter AVST_USER          = 2 + 94 +328, 
    parameter AXIST_MODE         = "MULTI_PACKET", 
    parameter AXI_DW             = 64,
    parameter NO_OF_BYTES        = 8, 
    parameter TUSER              = 2 +94 +328, 
    parameter READY_LATENCY      = 16,  
    parameter PKT_SEG_PARITY_EN  = 0,
    parameter ENABLE_ECC         = 1,
    parameter NUM_MAX_PORTS      = 4,
    parameter PORT_PROFILE       = "400GBE", 
    // parameter USE_M20K           = "ON",
    parameter PKT_SEG_PARITY_WIDTH  = 4,         //macseg - [NUM_SEG-1:0], sopa - [(NUM_MAX_PORTS-1:0]   
    parameter DR_ENABLE          = 1         
) (
    input                                       i_tx_clk_p0,          
    input                                       i_tx_clk_p1, 
    input                                       i_tx_clk_p2, 
    input                                       i_tx_clk_p3, 
    input                                       i_tx_reset_n_p0,     
    input                                       i_tx_reset_n_p1,
    input                                       i_tx_reset_n_p2,
    input                                       i_tx_reset_n_p3,
    input         [NUM_MAX_PORTS-1:0]           i_port_active_mask,
    input         [2:0]                         i_port_data_width,    //current profile parameters based on profile_sel_reg only for sopa
    input         [2:0]                         i_active_ports,       //current profile parameters based on profile_sel_reg - both sopa and mac seg
    input         [2:0]                         i_active_segments,    //current profile parameters based on profile_sel_reg only for mac seg
                                                 
    //AXI Stream Tx, User side interface               
    output reg    [NUM_MAX_PORTS-1:0]           o_axist_tx_tready,  
    input         [NUM_MAX_PORTS-1:0]           i_axist_tx_tvalid,  
    input         [AXI_DW-1:0]                  i_axist_tx_tdata,   
    input         [NUM_MAX_PORTS-1:0]           i_axist_tx_tlast,   
    input         [NO_OF_BYTES-1:0]             i_axist_tx_tkeep,   
    input         [NUM_SEG-1:0]                 i_axist_tx_tlast_segment, 
    input         [NUM_SEG*8-1:0]               i_axist_tx_tkeep_segment, 
    input         [NUM_MAX_PORTS*TUSER-1:0]     i_axist_tx_tuser,         
    input         [PKT_SEG_PARITY_WIDTH-1:0]    i_axist_tx_pkt_seg_parity,        
    
    //Avalon Stream Tx, MAC side interface  
    input         [NUM_MAX_PORTS-1:0]           i_avst_tx_ready,            
    output        [AVST_DW-1:0]                 o_avst_tx_data,             
    output        [NUM_MAX_PORTS-1:0]           o_avst_tx_valid,            
    output        [NUM_MAX_PORTS-1:0]           o_avst_tx_valid_pkt_client, //only used in ED for PKT client IF 
    output        [NUM_SEG-1:0]                 o_avst_tx_inframe,        
    output        [NUM_SEG*EMPTY_BITS-1:0]      o_avst_tx_eop_empty,        //sopa -> 25-2:0,50-5:0,100-11:0, mac seg - empty bits always 3

    output        [NUM_MAX_PORTS-1:0]           o_avst_tx_startofpacket,    
    output        [NUM_MAX_PORTS-1:0]           o_avst_tx_endofpacket,      
    output        [NUM_MAX_PORTS*AVST_USER-1:0] o_avst_tx_user,             
    output        [NUM_MAX_PORTS-1:0]           o_axist_tx_parity_error,    //To CSR status reg 
    output        [(NUM_MAX_PORTS*2)-1:0]       o_fifo_eccstatus                                

);

localparam EN_ECC                 = (ENABLE_ECC) ? "TRUE" : "FALSE" ;
    
localparam FIFO_WIDTH0 =  (AVST_MODE == "MAC_SEGMENTED")? (1+(NUM_SEG*EMPTY_BITS)+NUM_SEG+AVST_DW+AVST_USER) :
                                                          (3+EMPTY_BITS+AVST_DW+AVST_USER); 
                                                          
localparam FIFO_WIDTH1 =  (AVST_MODE == "MAC_SEGMENTED")? (1+((NUM_SEG*EMPTY_BITS)/NUM_MAX_PORTS)+(NUM_SEG/NUM_MAX_PORTS)+(AVST_DW/NUM_MAX_PORTS)+AVST_USER):                                                                                 
                                                          (NUM_MAX_PORTS == 2)? (3+EMPTY_BITS+(AVST_DW/4)+AVST_USER) : (3+EMPTY_BITS+(AVST_DW/8)+AVST_USER);  
                                                          
localparam FIFO_WIDTH2 =  (AVST_MODE == "MAC_SEGMENTED")? (1+((NUM_SEG*EMPTY_BITS)/2)+(NUM_SEG/2)+(AVST_DW/2)+AVST_USER):
                                                          (3+EMPTY_BITS+(AVST_DW/4)+AVST_USER); 
                                                          
localparam FIFO_WIDTH3 =  (AVST_MODE == "MAC_SEGMENTED")? (1+((NUM_SEG*EMPTY_BITS)/4)+(NUM_SEG/4)+(AVST_DW/4)+AVST_USER):
                                                          (3+EMPTY_BITS+(AVST_DW/8)+AVST_USER); 

localparam FIFO_DEPTH             = 5;  //minium is 6 //** 3, fifo depth = 8
localparam DC_FIFO_LATENCY        = 2 + 6 + 6; // 2 cycles for wen delay, 6 cycles for empty delay, 6 cycles of ren delay
// localparam FIFO_LEVEL_CHECK       = (2**FIFO_DEPTH) - READY_LATENCY - DC_FIFO_LATENCY - 'd4; //1+3 cycles for ready to wen on AXI side //TO BE ANALYZED
// localparam FIFO_LEVEL_CHECK       = (2**FIFO_DEPTH) - READY_LATENCY - 'd4; //1+3 cycles for ready to wen on AXI side //TO BE ANALYZED //32-16-4 =12
localparam FIFO_LEVEL_CHECK       = 4; //1+3 cycles for ready to wen on AXI side //TO BE ANALYZED //32-16-4 =12
localparam NUM_SEG_BITS           = 2*NUM_SEG;
localparam NUM_SEG_BY_MAX_PORTS   = NUM_SEG/NUM_MAX_PORTS; 
localparam AVST_DW_BY_MAX_PORTS   = AVST_DW/NUM_MAX_PORTS; 
localparam EMPTY_BY_MAX_PORTS     = (NUM_SEG*EMPTY_BITS)/NUM_MAX_PORTS; 

localparam NUM_SEG_BY_TWO         = NUM_SEG/2; 
localparam NUM_SEG_BY_FOUR        = NUM_SEG/4; 
localparam NUM_SEG_BY_FOURX3      = 3*(NUM_SEG/4); 

localparam AVST_DW_BY_TWO         = AVST_DW/2;
localparam AVST_DW_BY_FOUR        = AVST_DW/4;
localparam AVST_DW_BY_FOURX3      = 3*(AVST_DW/4);
localparam AVST_DW_BY_EIGHT       = AVST_DW/8;
localparam AVST_DW_BY_EIGHTX3     = 3*(AVST_DW/8);

localparam EMPTY_BY_TWO           = (NUM_SEG*EMPTY_BITS)/2;                                       
localparam EMPTY_BY_FOURX3        = 3*((NUM_SEG*EMPTY_BITS)/4); 

//***********************************************************
//***********************************************************

reg    [NUM_SEG*8-1:0]                           axist_tx_tkeep_segment_d1 = '0;
reg    [NUM_SEG-1:0]                             axist_tx_tlast_segment_d1 = '0;
reg    [NUM_SEG-1:0]                             axist_tx_tlast_segment_d2 = '0;
reg    [AVST_DW-1:0]                             avst_tx_data_d1 = '0;              
reg    [AVST_DW-1:0]                             avst_tx_data_d2 = '0;              
            
reg    [NUM_SEG-1:0]                             avst_tx_inframe_d2;                                                          
logic  [NUM_MAX_PORTS*TUSER-1:0]                 avst_tx_user_sp;

reg    [NUM_SEG-1:0]                             avst_eop_d3;
reg    [NUM_SEG-1:0]                             avst_sop_d3;
reg                                              par_err_detected;

wire   [FIFO_WIDTH0-1:0]                         fifo_data_in0;         
wire   [FIFO_WIDTH1-1:0]                         fifo_data_in1;         
wire   [FIFO_WIDTH2-1:0]                         fifo_data_in2;         
wire   [FIFO_WIDTH3-1:0]                         fifo_data_in3;         

wire                                             av_st_tx_fifo_empty0;   
wire                                             av_st_tx_fifo_empty1;   
wire                                             av_st_tx_fifo_empty2;   
wire                                             av_st_tx_fifo_empty3;  

wire                                             av_st_tx_fifo_ae0;   
wire                                             av_st_tx_fifo_ae1;   
wire                                             av_st_tx_fifo_ae2;   
wire                                             av_st_tx_fifo_ae3;  
wire                                             av_st_tx_fifo_ae4;  
      
wire                                             avst_tx_ready0;        
wire                                             avst_tx_ready1;        
wire                                             avst_tx_ready2;        
wire                                             avst_tx_ready3;        

wire                                             fifo_wrreq0;           
wire                                             fifo_wrreq1;           
wire                                             fifo_wrreq2;           
wire                                             fifo_wrreq3;           

wire   [FIFO_WIDTH0-1:0]                         fifo_data_out0;        
wire   [FIFO_WIDTH1-1:0]                         fifo_data_out1;        
wire   [FIFO_WIDTH2-1:0]                         fifo_data_out2;        
wire   [FIFO_WIDTH3-1:0]                         fifo_data_out3;        

// wire   [FIFO_WIDTH0-1:0]                         fifo_data_in4; 
// wire                                             avst_tx_ready4;
// wire                                             av_st_tx_fifo_empty4; 
// wire   [FIFO_WIDTH0-1:0]                         fifo_data_out4;
// wire                                             fifo_wrreq4;
 
wire   [NUM_MAX_PORTS-1:0]                       av_st_tx_fifo_af;
  
wire   [2-1:0]                                   ecc_status0;
wire   [2-1:0]                                   ecc_status1;
wire   [2-1:0]                                   ecc_status2;
wire   [2-1:0]                                   ecc_status3;
// wire   [2-1:0]                                   ecc_status4;
   
reg    [NUM_MAX_PORTS-1:0]                       fifo_wrreq_d1;           
reg    [NUM_MAX_PORTS-1:0]                       fifo_wrreq_d2;        
wire   [NUM_MAX_PORTS-1:0]                       axist_tx_tready_delayed;       
reg    [NUM_MAX_PORTS-1:0]                       axist_tx_tready_delayed_d1 = '0;   


reg    [NUM_SEG*EMPTY_BITS-1:0]                  avst_tx_eop_empty_d1 = 0 ;        //* check if required - required
reg    [NUM_SEG*EMPTY_BITS-1:0]                  avst_tx_eop_empty_d2;

//sopa
reg    [AVST_DW-1:0]                             avst_tx_swiped_data_d2_0;      
reg    [AVST_DW-1:0]                             avst_tx_swapped_data;        

wire   [PKT_SEG_PARITY_WIDTH-1:0]                tx_avst_parity_detect_d1;           
                                                 
reg    [NUM_MAX_PORTS-1:0]                       avst_sop_latch;
reg    [NUM_MAX_PORTS-1:0]                       avst_eop_d1;
reg    [NUM_MAX_PORTS-1:0]                       avst_sop_d1;
reg    [NUM_MAX_PORTS-1:0]                       avst_sop_d0;
reg    [NUM_MAX_PORTS-1:0]                       avst_tx_parity_error_d1;                                                                                                
wire   [NUM_MAX_PORTS*2-1:0]                     avst_tx_user_client;

// mac seg                                       
reg    [NUM_SEG*EMPTY_BITS-1:0]                  keep2empty_d1;                  //* check if required - required
                                                 
logic  [PKT_SEG_PARITY_WIDTH-1:0]                tx_parity_detect_d1;           
logic  [PKT_SEG_PARITY_WIDTH-1:0]                mac_tx_pkt_seg_parity_d1;     

reg    [NUM_SEG-1:0]                             tx_parity_detect_d1_p0      ;
reg    [NUM_SEG-1:0]                             tx_parity_detect_d1_p1      ;
reg    [NUM_SEG-1:0]                             tx_parity_detect_d1_p2      ;
reg    [NUM_SEG-1:0]                             tx_parity_detect_d1_p3      ;
reg    [NUM_SEG-1:0]                             mac_tx_pkt_seg_parity_d1_p0 ;
reg    [NUM_SEG-1:0]                             mac_tx_pkt_seg_parity_d1_p1 ;
reg    [NUM_SEG-1:0]                             mac_tx_pkt_seg_parity_d1_p2 ;
reg    [NUM_SEG-1:0]                             mac_tx_pkt_seg_parity_d1_p3 ;

reg    [NUM_SEG-1:0]                             mac_avst_eop_d1;
reg    [NUM_SEG-1:0]                             mac_avst_sop_d1;
reg    [NUM_SEG-1:0]                             mac_avst_eop_d2;
reg    [NUM_SEG-1:0]                             tx_parity_error_d2;
wire   [NUM_SEG*2-1:0]                           mac_avst_tx_user_client;
                                                 
logic  [NUM_SEG-1:0]  [63:0]                     axi_st_tx_seg_data;

reg    [NUM_SEG-1:0]                             avst_eop_d1_p0    ; 
reg    [NUM_SEG-1:0]                             avst_eop_d1_p1    ; 
reg    [NUM_SEG-1:0]                             avst_eop_d1_p2    ; 
reg    [NUM_SEG-1:0]                             avst_eop_d1_p3    ; 
                                                 
reg    [NUM_SEG-1:0]                             avst_sop_latch_p0 ;
reg    [NUM_SEG-1:0]                             avst_sop_latch_p1 ;
reg    [NUM_SEG-1:0]                             avst_sop_latch_p2 ;
reg    [NUM_SEG-1:0]                             avst_sop_latch_p3 ;
                                                 
reg    [NUM_SEG-1:0]                             avst_eop_d2_p0   ;
reg    [NUM_SEG-1:0]                             avst_eop_d2_p1   ;
reg    [NUM_SEG-1:0]                             avst_eop_d2_p2   ;
reg    [NUM_SEG-1:0]                             avst_eop_d2_p3   ;
                                                 
reg    [NUM_SEG-1:0]                             avst_sop_d1_p0   ;
reg    [NUM_SEG-1:0]                             avst_sop_d1_p1   ;
reg    [NUM_SEG-1:0]                             avst_sop_d1_p2   ;
reg    [NUM_SEG-1:0]                             avst_sop_d1_p3   ;
                                                 
reg    [NUM_SEG-1:0]                             avst_tx_inframe_d2_p0   ;
reg    [NUM_SEG-1:0]                             avst_tx_inframe_d2_p1   ;
reg    [NUM_SEG-1:0]                             avst_tx_inframe_d2_p2   ;
reg    [NUM_SEG-1:0]                             avst_tx_inframe_d2_p3   ;
                                                 
reg    [NUM_SEG-1:0]                             tx_parity_error_d2_p0   ;
reg    [NUM_SEG-1:0]                             tx_parity_error_d2_p1   ;
reg    [NUM_SEG-1:0]                             tx_parity_error_d2_p2   ;
reg    [NUM_SEG-1:0]                             tx_parity_error_d2_p3   ;
                                                 
reg    [NUM_SEG*2-1:0]                           avst_tx_user_client_d2_p0   ;
reg    [NUM_SEG*2-1:0]                           avst_tx_user_client_d2_p1   ;
reg    [NUM_SEG*2-1:0]                           avst_tx_user_client_d2_p2   ;
reg    [NUM_SEG*2-1:0]                           avst_tx_user_client_d2_p3   ;
                                                 
wire   [NUM_SEG*2-1:0]                           avst_tx_user_client_p0;
wire   [NUM_SEG*2-1:0]                           avst_tx_user_client_p1;
wire   [NUM_SEG*2-1:0]                           avst_tx_user_client_p2;
wire   [NUM_SEG*2-1:0]                           avst_tx_user_client_p3;
                                                 
wire                                             par_err_detected_p0 ;
wire                                             par_err_detected_p1 ;
wire                                             par_err_detected_p2 ;
wire                                             par_err_detected_p3 ;
// wire   [3:0]                                     keep2empty_sop_align_d1 [NO_OF_BYTES/8-1:0]; // = '{default:'0}; //4 bits bw since every 64 bits are processed // changed to 2:0 -> 64 bits -> 8 bytes -> 7 bytes can be empty
wire   [EMPTY_BITS-1:0]                          keep2empty_sopa_d1_p0;
wire   [EMPTY_BITS-1:0]                          keep2empty_sopa_d1_p1;
wire   [EMPTY_BITS-1:0]                          keep2empty_sopa_d1_p2;
wire   [EMPTY_BITS-1:0]                          keep2empty_sopa_d1_p3;

reg    [4:0]                                     active_segments; 

wire   [NUM_SEG-1:0]                             tx_valid_parity_error_p0;
wire   [NUM_SEG-1:0]                             tx_valid_parity_error_p1;
wire   [NUM_SEG-1:0]                             tx_valid_parity_error_p2;
wire   [NUM_SEG-1:0]                             tx_valid_parity_error_p3;

reg    [NUM_SEG-1:0]                             avst_tx_data_valid_p0;
reg    [NUM_SEG-1:0]                             avst_tx_data_valid_p1;
reg    [NUM_SEG-1:0]                             avst_tx_data_valid_p2;
reg    [NUM_SEG-1:0]                             avst_tx_data_valid_p3;

reg    [NUM_SEG-1:0]                             axist_tx_tlast_segment_p0; 
reg    [NUM_SEG-1:0]                             axist_tx_tlast_segment_p1; 
reg    [NUM_SEG-1:0]                             axist_tx_tlast_segment_p2; 
reg    [NUM_SEG-1:0]                             axist_tx_tlast_segment_p3; 

reg    [NUM_SEG-1:0]                             axist_tx_tlast_segment_p0_d1; 
reg    [NUM_SEG-1:0]                             axist_tx_tlast_segment_p1_d1; 
reg    [NUM_SEG-1:0]                             axist_tx_tlast_segment_p2_d1; 
reg    [NUM_SEG-1:0]                             axist_tx_tlast_segment_p3_d1; 

reg    [NUM_SEG*8-1:0]                           axist_tx_tkeep_segment_p0;
reg    [NUM_SEG*8-1:0]                           axist_tx_tkeep_segment_p1;
reg    [NUM_SEG*8-1:0]                           axist_tx_tkeep_segment_p2;
reg    [NUM_SEG*8-1:0]                           axist_tx_tkeep_segment_p3;

reg    [NUM_SEG*8-1:0]                           axist_tx_tkeep_segment_p0_d1;
reg    [NUM_SEG*8-1:0]                           axist_tx_tkeep_segment_p1_d1;
reg    [NUM_SEG*8-1:0]                           axist_tx_tkeep_segment_p2_d1;
reg    [NUM_SEG*8-1:0]                           axist_tx_tkeep_segment_p3_d1;

wire   [EMPTY_BITS-1:0]                          s_avst_tx_eop_empty_p3;
wire   [EMPTY_BITS-1:0]                          s_avst_tx_eop_empty_p2;
wire   [EMPTY_BITS-1:0]                          s_avst_tx_eop_empty_p1;
wire   [EMPTY_BITS-1:0]                          s_avst_tx_eop_empty_p0;

wire                                             av_st_tx_fifo_flag0;
wire                                             av_st_tx_fifo_flag1;
wire                                             av_st_tx_fifo_flag2;
wire                                             av_st_tx_fifo_flag3;

reg    [NUM_SEG*2-1:0]                           avst_tx_user_client_d1_p0 = '0  ;
reg    [NUM_SEG*2-1:0]                           avst_tx_user_client_d1_p1 = '0  ;
reg    [NUM_SEG*2-1:0]                           avst_tx_user_client_d1_p2 = '0  ;
reg    [NUM_SEG*2-1:0]                           avst_tx_user_client_d1_p3 = '0  ;

reg                                              avst_tx_valid_d1_p0;
reg                                              avst_tx_valid_d1_p1;
reg                                              avst_tx_valid_d1_p2;
reg                                              avst_tx_valid_d1_p3;

reg                                              avst_tx_valid_d2_p0;
reg                                              avst_tx_valid_d2_p1;
reg                                              avst_tx_valid_d2_p2;
reg                                              avst_tx_valid_d2_p3;

reg    [TUSER-1:0]                               avst_tx_user_d1_p0;
reg    [TUSER-1:0]                               avst_tx_user_d1_p1;
reg    [TUSER-1:0]                               avst_tx_user_d1_p2;
reg    [TUSER-1:0]                               avst_tx_user_d1_p3;

reg    [TUSER-1:0]                               avst_tx_user_d2_p0;
reg    [TUSER-1:0]                               avst_tx_user_d2_p1;
reg    [TUSER-1:0]                               avst_tx_user_d2_p2;
reg    [TUSER-1:0]                               avst_tx_user_d2_p3;

reg    [AVST_DW_BY_FOUR-1:0]                     avst_tx_swiped_data_128_p0;
reg    [AVST_DW_BY_FOUR-1:0]                     avst_tx_swiped_data_128_p1;
reg    [AVST_DW_BY_FOUR-1:0]                     avst_tx_swiped_data_128_p2;
       
reg    [63:0]                                    avst_tx_swiped_data_64_p0; //used in 50GAUI and 100GAUI 
reg    [AVST_DW_BY_EIGHT-1:0]                    avst_tx_swiped_data_64_p1;
reg    [AVST_DW_BY_EIGHT-1:0]                    avst_tx_swiped_data_64_p2;
reg    [AVST_DW_BY_EIGHT-1:0]                    avst_tx_swiped_data_64_p3; 

generate if (AVST_MODE == "MAC_SEGMENTED") 
begin : MS_TVALID_MUX                             
   
   always @(posedge i_tx_clk_p0) //* initialize 0 at declaration for d1 and d2, port wise reset only for valid d1 and d2 - done
   begin
      avst_tx_data_d1              <= i_axist_tx_tdata;            //* tuser split port wise  - done , data split into port wise chunks instead of single bus - not required, MS single clock, SOPA - swiped_data is split
      avst_tx_data_d2              <= avst_tx_data_d1;
      axist_tx_tkeep_segment_d1    <= i_axist_tx_tkeep_segment;  
      axist_tx_tlast_segment_d1    <= i_axist_tx_tlast_segment;         
      axist_tx_tlast_segment_d2    <= axist_tx_tlast_segment_d1;         
   end    
   
   if (NUM_MAX_PORTS == 4) begin: TVALID_MUX_4P
   
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
      begin
          if (~i_tx_reset_n_p0) begin
              avst_tx_valid_d1_p0             <= 1'b0;
              avst_tx_valid_d2_p0             <= 1'b0;   
              avst_tx_user_d1_p0              <= '0;  
              avst_tx_user_d2_p0              <= '0;
              fifo_wrreq_d1[0]                <= '0;
              fifo_wrreq_d2[0]                <= '0;              
          end
          else begin
              avst_tx_valid_d1_p0             <= i_axist_tx_tvalid[0];           
              avst_tx_valid_d2_p0             <= avst_tx_valid_d1_p0;      
              avst_tx_user_d1_p0              <= i_axist_tx_tuser[AVST_USER-1:0];
              avst_tx_user_d2_p0              <= avst_tx_user_d1_p0;
              fifo_wrreq_d1[0]                <= axist_tx_tready_delayed[0];     //delaying the wrreq of fifo to ready latency value
              fifo_wrreq_d2[0]                <= fifo_wrreq_d1[0];               //wrreq delayed by 2 cycles to match conversion delay            
          end
      end
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1) 
      begin
          if (~i_tx_reset_n_p1) begin
              avst_tx_valid_d1_p1             <= 1'b0;
              avst_tx_valid_d2_p1             <= 1'b0;      
              avst_tx_user_d1_p1              <= '0;  
              avst_tx_user_d2_p1              <= '0;  
              fifo_wrreq_d1[1]                <= '0;
              fifo_wrreq_d2[1]                <= '0;                  
          end
          else begin
              avst_tx_valid_d1_p1             <= i_axist_tx_tvalid[1];           
              avst_tx_valid_d2_p1             <= avst_tx_valid_d1_p1;  
              avst_tx_user_d1_p1              <= i_axist_tx_tuser[(2*AVST_USER)-1:AVST_USER];
              avst_tx_user_d2_p1              <= avst_tx_user_d1_p1;              
              fifo_wrreq_d1[1]                <= axist_tx_tready_delayed[1];     //delaying the wrreq of fifo to ready latency value
              fifo_wrreq_d2[1]                <= fifo_wrreq_d1[1];               //wrreq delayed by 2 cycles to match conversion delay                
          end
      end    
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p2) 
      begin
          if (~i_tx_reset_n_p2) begin
              avst_tx_valid_d1_p2             <= 1'b0;
              avst_tx_valid_d2_p2             <= 1'b0;      
              avst_tx_user_d1_p2              <= '0;  
              avst_tx_user_d2_p2              <= '0;  
              fifo_wrreq_d1[2]                <= '0;
              fifo_wrreq_d2[2]                <= '0;                  
          end
          else begin
              avst_tx_valid_d1_p2             <= i_axist_tx_tvalid[2];           
              avst_tx_valid_d2_p2             <= avst_tx_valid_d1_p2;   
              avst_tx_user_d1_p2              <= i_axist_tx_tuser[(3*AVST_USER)-1:(2*AVST_USER)];
              avst_tx_user_d2_p2              <= avst_tx_user_d1_p2;   
              fifo_wrreq_d1[2]                <= axist_tx_tready_delayed[2];     //delaying the wrreq of fifo to ready latency value
              fifo_wrreq_d2[2]                <= fifo_wrreq_d1[2];               //wrreq delayed by 2 cycles to match conversion delay            
          end
      end     
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p3) 
      begin
          if (~i_tx_reset_n_p3) begin
              avst_tx_valid_d1_p3             <= 1'b0;
              avst_tx_valid_d2_p3             <= 1'b0;      
              avst_tx_user_d1_p3              <= '0;  
              avst_tx_user_d2_p3              <= '0; 
              fifo_wrreq_d1[3]                <= '0;
              fifo_wrreq_d2[3]                <= '0;                  
          end
          else begin
              avst_tx_valid_d1_p3             <= i_axist_tx_tvalid[3];           
              avst_tx_valid_d2_p3             <= avst_tx_valid_d1_p3;
              avst_tx_user_d1_p3              <= i_axist_tx_tuser[(4*AVST_USER)-1:(3*AVST_USER)];
              avst_tx_user_d2_p3              <= avst_tx_user_d1_p3;       
              fifo_wrreq_d1[3]                <= axist_tx_tready_delayed[3];     //delaying the wrreq of fifo to ready latency value
              fifo_wrreq_d2[3]                <= fifo_wrreq_d1[3];               //wrreq delayed by 2 cycles to match conversion delay            
          end
      end   

      always @(posedge i_tx_clk_p0)        
      begin 
         avst_tx_user_client_d1_p0 <= i_axist_tx_tuser[TUSER-1:TUSER-NUM_SEG_BITS]; //sop->423:422 
         axist_tx_tready_delayed_d1[0] <= axist_tx_tready_delayed[0]; //ready delayed one more cycle to match delay of avst_eop_d1 and avst_sop_d1 to generate avst_tx_inframe_d2 in mac segmented generate block                
      end     
         
      always @(posedge i_tx_clk_p0)        
      begin 
         avst_tx_user_client_d1_p1 <= i_axist_tx_tuser[(2*TUSER)-1:(2*TUSER)-(NUM_SEG_BITS)]; //sop->423:422 
         axist_tx_tready_delayed_d1[1] <= axist_tx_tready_delayed[1]; //ready delayed one more cycle to match delay of avst_eop_d1 and avst_sop_d1 to generate avst_tx_inframe_d2 in mac segmented generate block                        
      end         
      
      always @(posedge i_tx_clk_p0)         
      begin 
         avst_tx_user_client_d1_p2 <= i_axist_tx_tuser[(3*TUSER)-1:(3*TUSER)-(NUM_SEG_BITS)]; //sop->423:422 
         axist_tx_tready_delayed_d1[2] <= axist_tx_tready_delayed[2]; //ready delayed one more cycle to match delay of avst_eop_d1 and avst_sop_d1 to generate avst_tx_inframe_d2 in mac segmented generate block                        
      end    
         
      always @(posedge i_tx_clk_p0)         
      begin 
         avst_tx_user_client_d1_p3 <= i_axist_tx_tuser[(4*TUSER)-1:(4*TUSER)-(NUM_SEG_BITS)]; //sop->423:422 
         axist_tx_tready_delayed_d1[3] <= axist_tx_tready_delayed[3]; //ready delayed one more cycle to match delay of avst_eop_d1 and avst_sop_d1 to generate avst_tx_inframe_d2 in mac segmented generate block                        
      end        
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) //* split  port wise , clk and reset
      begin
          if(~i_tx_reset_n_p0) begin
              o_axist_tx_tready[0] <= 1'b0;
          end
          else if(i_avst_tx_ready[0]) begin
              o_axist_tx_tready[0] <= 1'b1;
          end
          else if (av_st_tx_fifo_af[0]) begin   //** check this condition
             o_axist_tx_tready[0] <= 1'b0;
          end
      end
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1) //* split  port wise , clk and reset
      begin
          if(~i_tx_reset_n_p1) begin
              o_axist_tx_tready[1] <= 1'b0;
          end
          else if(i_avst_tx_ready[1]) begin
              o_axist_tx_tready[1] <= 1'b1;
          end
          else if (av_st_tx_fifo_af[1]) begin   //** check this condition
             o_axist_tx_tready[1] <= 1'b0;
          end
      end        

      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p2) //* split  port wise , clk and reset
      begin
          if(~i_tx_reset_n_p2) begin
              o_axist_tx_tready[2] <= 1'b0;
          end
          else if(i_avst_tx_ready[2]) begin
              o_axist_tx_tready[2] <= 1'b1;
          end
          else if (av_st_tx_fifo_af[2]) begin   //** check this condition
             o_axist_tx_tready[2] <= 1'b0;
          end
      end   

      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p3) //* split  port wise , clk and reset
      begin
          if(~i_tx_reset_n_p3) begin
              o_axist_tx_tready[3] <= 1'b0;
          end
          else if(i_avst_tx_ready[3]) begin
              o_axist_tx_tready[3] <= 1'b1;
          end
          else if (av_st_tx_fifo_af[3]) begin   //** check this condition
             o_axist_tx_tready[3] <= 1'b0;
          end
      end     
      
      hssi_ss_delay_reg #(
         .CYCLES (READY_LATENCY),                                 
         .WIDTH  (1)                                              
      )i_axi_ready_latency_delay_reg_p0 (
         .clk    (i_tx_clk_p0),
         .din    (o_axist_tx_tready[0]),
         .dout   (axist_tx_tready_delayed[0])
         );

      hssi_ss_delay_reg #(
         .CYCLES (READY_LATENCY),                                 
         .WIDTH  (1)                                              
      )i_axi_ready_latency_delay_reg_p1 (
         .clk    (i_tx_clk_p0),
         .din    (o_axist_tx_tready[1]),
         .dout   (axist_tx_tready_delayed[1])
         );   

      hssi_ss_delay_reg #(
         .CYCLES (READY_LATENCY),                                 
         .WIDTH  (1)                                              
      )i_axi_ready_latency_delay_reg_p2 (
         .clk    (i_tx_clk_p0),
         .din    (o_axist_tx_tready[2]),
         .dout   (axist_tx_tready_delayed[2])
         ); 

      hssi_ss_delay_reg #(
         .CYCLES (READY_LATENCY),                                 
         .WIDTH  (1)                                              
      )i_axi_ready_latency_delay_reg_p3 (
         .clk    (i_tx_clk_p0),
         .din    (o_axist_tx_tready[3]),
         .dout   (axist_tx_tready_delayed[3])
         );              

   end   
   else if (NUM_MAX_PORTS == 2) begin: TVALID_MUX_2P
   
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
      begin
          if (~i_tx_reset_n_p0) begin
              avst_tx_valid_d1_p0             <= 1'b0;
              avst_tx_valid_d2_p0             <= 1'b0;     
              avst_tx_user_d1_p0              <= '0;  
              avst_tx_user_d2_p0              <= '0;     
              fifo_wrreq_d1[0]                <= '0;
              fifo_wrreq_d2[0]                <= '0;              
          end
          else begin
              avst_tx_valid_d1_p0             <= i_axist_tx_tvalid[0];           
              avst_tx_valid_d2_p0             <= avst_tx_valid_d1_p0; 
              avst_tx_user_d1_p0              <= i_axist_tx_tuser[AVST_USER-1:0];
              avst_tx_user_d2_p0              <= avst_tx_user_d1_p0;    
              fifo_wrreq_d1[0]                <= axist_tx_tready_delayed[0];     //delaying the wrreq of fifo to ready latency value
              fifo_wrreq_d2[0]                <= fifo_wrreq_d1[0];               //wrreq delayed by 2 cycles to match conversion delay              
          end
      end
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1) 
      begin
          if (~i_tx_reset_n_p1) begin
              avst_tx_valid_d1_p1             <= 1'b0;
              avst_tx_valid_d2_p1             <= 1'b0;
              avst_tx_user_d1_p1              <= '0;  
              avst_tx_user_d2_p1              <= '0; 
              fifo_wrreq_d1[1]                <= '0;
              fifo_wrreq_d2[1]                <= '0;                  
          end
          else begin
              avst_tx_valid_d1_p1             <= i_axist_tx_tvalid[1];           
              avst_tx_valid_d2_p1             <= avst_tx_valid_d1_p1;   
              avst_tx_user_d1_p1              <= i_axist_tx_tuser[(2*AVST_USER)-1:AVST_USER];
              avst_tx_user_d2_p1              <= avst_tx_user_d1_p1;   
              fifo_wrreq_d1[1]                <= axist_tx_tready_delayed[1];     //delaying the wrreq of fifo to ready latency value
              fifo_wrreq_d2[1]                <= fifo_wrreq_d1[1];               //wrreq delayed by 2 cycles to match conversion delay            
          end
      end  

      always @(posedge i_tx_clk_p0)        
      begin 
         avst_tx_user_client_d1_p0 <= i_axist_tx_tuser[TUSER-1:TUSER-NUM_SEG_BITS]; //sop->423:422
         axist_tx_tready_delayed_d1[0] <= axist_tx_tready_delayed[0]; //ready delayed one more cycle to match delay of avst_eop_d1 and avst_sop_d1 to generate avst_tx_inframe_d2 in mac segmented generate block        
      end    
         
      always @(posedge i_tx_clk_p0)        
      begin 
         avst_tx_user_client_d1_p1 <= i_axist_tx_tuser[(2*TUSER)-1:(2*TUSER)-(NUM_SEG_BITS)]; //sop->423:422
         axist_tx_tready_delayed_d1[1] <= axist_tx_tready_delayed[1]; //ready delayed one more cycle to match delay of avst_eop_d1 and avst_sop_d1 to generate avst_tx_inframe_d2 in mac segmented generate block                
      end        
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) //* split  port wise , clk and reset
      begin
          if(~i_tx_reset_n_p0) begin
              o_axist_tx_tready[0] <= 1'b0;
          end
          else if(i_avst_tx_ready[0]) begin
              o_axist_tx_tready[0] <= 1'b1;
          end
          else if (av_st_tx_fifo_af[0]) begin   //** check this condition
             o_axist_tx_tready[0] <= 1'b0;
          end
      end
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1) //* split  port wise , clk and reset
      begin
          if(~i_tx_reset_n_p1) begin
              o_axist_tx_tready[1] <= 1'b0;
          end
          else if(i_avst_tx_ready[1]) begin
              o_axist_tx_tready[1] <= 1'b1;
          end
          else if (av_st_tx_fifo_af[1]) begin   //** check this condition
             o_axist_tx_tready[1] <= 1'b0;
          end
      end   
      
      hssi_ss_delay_reg #(
         .CYCLES (READY_LATENCY),                                 
         .WIDTH  (1)                                              
      )i_axi_ready_latency_delay_reg_p0 (
         .clk    (i_tx_clk_p0),
         .din    (o_axist_tx_tready[0]),
         .dout   (axist_tx_tready_delayed[0])
         );

      hssi_ss_delay_reg #(
         .CYCLES (READY_LATENCY),                                 
         .WIDTH  (1)                                              
      )i_axi_ready_latency_delay_reg_p1 (
         .clk    (i_tx_clk_p0),
         .din    (o_axist_tx_tready[1]),
         .dout   (axist_tx_tready_delayed[1])
         );   
      
   end
   else begin : TVALID_MUX_1P
   
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
      begin
          if (~i_tx_reset_n_p0) begin
              avst_tx_valid_d1_p0             <= 1'b0;
              avst_tx_valid_d2_p0             <= 1'b0;      
              avst_tx_user_d1_p0              <= '0;  
              avst_tx_user_d2_p0              <= '0;     
              fifo_wrreq_d1                   <= '0;
              fifo_wrreq_d2                   <= '0;
          end
          else begin
              avst_tx_valid_d1_p0             <= i_axist_tx_tvalid;          
              avst_tx_valid_d2_p0             <= avst_tx_valid_d1_p0; 
              avst_tx_user_d1_p0              <= i_axist_tx_tuser;
              avst_tx_user_d2_p0              <= avst_tx_user_d1_p0;    
              fifo_wrreq_d1                   <= axist_tx_tready_delayed;     //delaying the wrreq of fifo to ready latency value
              fifo_wrreq_d2                   <= fifo_wrreq_d1;               //wrreq delayed by 2 cycles to match conversion delay
          end
      end
      
      always @(posedge i_tx_clk_p0)         
      begin 
         avst_tx_user_client_d1_p0  <= i_axist_tx_tuser[TUSER-1:(TUSER-NUM_SEG_BITS)]; //sop->423:422
         axist_tx_tready_delayed_d1 <= axist_tx_tready_delayed; //ready delayed one more cycle to match delay of avst_eop_d1 and avst_sop_d1 to generate avst_tx_inframe_d2 in mac segmented generate block
      end      

      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) //* split  port wise , clk and reset
      begin
          if(~i_tx_reset_n_p0) begin
              o_axist_tx_tready <= 1'b0;
          end
          else if(i_avst_tx_ready) begin
              o_axist_tx_tready <= 1'b1;
          end
          else if (av_st_tx_fifo_af) begin   //** check this condition
             o_axist_tx_tready <= 1'b0;
          end
      end   

      hssi_ss_delay_reg #(
         .CYCLES (READY_LATENCY),                                 
         .WIDTH  (1)                                              
      )i_axi_ready_latency_delay_reg (
         .clk    (i_tx_clk_p0),
         .din    (o_axist_tx_tready),
         .dout   (axist_tx_tready_delayed)
         );   
      
   end       
end
else begin: SOPA_TVALID_MUX
   if (NUM_MAX_PORTS == 4) begin: TVALID_MUX_4P
   
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
      begin
          if (~i_tx_reset_n_p0) begin
              avst_tx_valid_d1_p0             <= 1'b0;
              avst_tx_valid_d2_p0             <= 1'b0;   
              avst_tx_user_d1_p0              <= '0;  
              avst_tx_user_d2_p0              <= '0;
              fifo_wrreq_d1[0]                <= '0;
              fifo_wrreq_d2[0]                <= '0;              
          end
          else begin
              avst_tx_valid_d1_p0             <= i_axist_tx_tvalid[0];           
              avst_tx_valid_d2_p0             <= avst_tx_valid_d1_p0;      
              avst_tx_user_d1_p0              <= i_axist_tx_tuser[AVST_USER-1:0];
              avst_tx_user_d2_p0              <= avst_tx_user_d1_p0;
              fifo_wrreq_d1[0]                <= axist_tx_tready_delayed[0];     //delaying the wrreq of fifo to ready latency value
              fifo_wrreq_d2[0]                <= fifo_wrreq_d1[0];               //wrreq delayed by 2 cycles to match conversion delay            
          end
      end
      
      always @(posedge i_tx_clk_p1 or negedge i_tx_reset_n_p1) 
      begin
          if (~i_tx_reset_n_p1) begin
              avst_tx_valid_d1_p1             <= 1'b0;
              avst_tx_valid_d2_p1             <= 1'b0;      
              avst_tx_user_d1_p1              <= '0;  
              avst_tx_user_d2_p1              <= '0;  
              fifo_wrreq_d1[1]                <= '0;
              fifo_wrreq_d2[1]                <= '0;                  
          end
          else begin
              avst_tx_valid_d1_p1             <= i_axist_tx_tvalid[1];           
              avst_tx_valid_d2_p1             <= avst_tx_valid_d1_p1;  
              avst_tx_user_d1_p1              <= i_axist_tx_tuser[(2*AVST_USER)-1:AVST_USER];
              avst_tx_user_d2_p1              <= avst_tx_user_d1_p1;              
              fifo_wrreq_d1[1]                <= axist_tx_tready_delayed[1];     //delaying the wrreq of fifo to ready latency value
              fifo_wrreq_d2[1]                <= fifo_wrreq_d1[1];               //wrreq delayed by 2 cycles to match conversion delay                
          end
      end    
      
      always @(posedge i_tx_clk_p2 or negedge i_tx_reset_n_p2) 
      begin
          if (~i_tx_reset_n_p2) begin
              avst_tx_valid_d1_p2             <= 1'b0;
              avst_tx_valid_d2_p2             <= 1'b0;      
              avst_tx_user_d1_p2              <= '0;  
              avst_tx_user_d2_p2              <= '0;  
              fifo_wrreq_d1[2]                <= '0;
              fifo_wrreq_d2[2]                <= '0;                  
          end
          else begin
              avst_tx_valid_d1_p2             <= i_axist_tx_tvalid[2];           
              avst_tx_valid_d2_p2             <= avst_tx_valid_d1_p2;   
              avst_tx_user_d1_p2              <= i_axist_tx_tuser[(3*AVST_USER)-1:(2*AVST_USER)];
              avst_tx_user_d2_p2              <= avst_tx_user_d1_p2;   
              fifo_wrreq_d1[2]                <= axist_tx_tready_delayed[2];     //delaying the wrreq of fifo to ready latency value
              fifo_wrreq_d2[2]                <= fifo_wrreq_d1[2];               //wrreq delayed by 2 cycles to match conversion delay            
          end
      end     
      
      always @(posedge i_tx_clk_p3 or negedge i_tx_reset_n_p3) 
      begin
          if (~i_tx_reset_n_p3) begin
              avst_tx_valid_d1_p3             <= 1'b0;
              avst_tx_valid_d2_p3             <= 1'b0;      
              avst_tx_user_d1_p3              <= '0;  
              avst_tx_user_d2_p3              <= '0; 
              fifo_wrreq_d1[3]                <= '0;
              fifo_wrreq_d2[3]                <= '0;                  
          end
          else begin
              avst_tx_valid_d1_p3             <= i_axist_tx_tvalid[3];           
              avst_tx_valid_d2_p3             <= avst_tx_valid_d1_p3;
              avst_tx_user_d1_p3              <= i_axist_tx_tuser[(4*AVST_USER)-1:(3*AVST_USER)];
              avst_tx_user_d2_p3              <= avst_tx_user_d1_p3;       
              fifo_wrreq_d1[3]                <= axist_tx_tready_delayed[3];     //delaying the wrreq of fifo to ready latency value
              fifo_wrreq_d2[3]                <= fifo_wrreq_d1[3];               //wrreq delayed by 2 cycles to match conversion delay            
          end
      end   

      always @(posedge i_tx_clk_p0)        
      begin 
         avst_tx_user_client_d1_p0 <= i_axist_tx_tuser[TUSER-1:TUSER-NUM_SEG_BITS]; //sop->423:422 
         axist_tx_tready_delayed_d1[0] <= axist_tx_tready_delayed[0]; //ready delayed one more cycle to match delay of avst_eop_d1 and avst_sop_d1 to generate avst_tx_inframe_d2 in mac segmented generate block                
      end     
         
      always @(posedge i_tx_clk_p1)        
      begin 
         avst_tx_user_client_d1_p1 <= i_axist_tx_tuser[(2*TUSER)-1:(2*TUSER)-(NUM_SEG_BITS)]; //sop->423:422 
         axist_tx_tready_delayed_d1[1] <= axist_tx_tready_delayed[1]; //ready delayed one more cycle to match delay of avst_eop_d1 and avst_sop_d1 to generate avst_tx_inframe_d2 in mac segmented generate block                        
      end         
      
      always @(posedge i_tx_clk_p2)         
      begin 
         avst_tx_user_client_d1_p2 <= i_axist_tx_tuser[(3*TUSER)-1:(3*TUSER)-(NUM_SEG_BITS)]; //sop->423:422 
         axist_tx_tready_delayed_d1[2] <= axist_tx_tready_delayed[2]; //ready delayed one more cycle to match delay of avst_eop_d1 and avst_sop_d1 to generate avst_tx_inframe_d2 in mac segmented generate block                        
      end    
         
      always @(posedge i_tx_clk_p3)         
      begin 
         avst_tx_user_client_d1_p3 <= i_axist_tx_tuser[(4*TUSER)-1:(4*TUSER)-(NUM_SEG_BITS)]; //sop->423:422 
         axist_tx_tready_delayed_d1[3] <= axist_tx_tready_delayed[3]; //ready delayed one more cycle to match delay of avst_eop_d1 and avst_sop_d1 to generate avst_tx_inframe_d2 in mac segmented generate block                        
      end        
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) //* split  port wise , clk and reset
      begin
          if(~i_tx_reset_n_p0) begin
              o_axist_tx_tready[0] <= 1'b0;
          end
          else if(i_avst_tx_ready[0]) begin
              o_axist_tx_tready[0] <= 1'b1;
          end
          else if (av_st_tx_fifo_af[0]) begin   //** check this condition
             o_axist_tx_tready[0] <= 1'b0;
          end
      end
      
      always @(posedge i_tx_clk_p1 or negedge i_tx_reset_n_p1) //* split  port wise , clk and reset
      begin
          if(~i_tx_reset_n_p1) begin
              o_axist_tx_tready[1] <= 1'b0;
          end
          else if(i_avst_tx_ready[1]) begin
              o_axist_tx_tready[1] <= 1'b1;
          end
          else if (av_st_tx_fifo_af[1]) begin   //** check this condition
             o_axist_tx_tready[1] <= 1'b0;
          end
      end        

      always @(posedge i_tx_clk_p2 or negedge i_tx_reset_n_p2) //* split  port wise , clk and reset
      begin
          if(~i_tx_reset_n_p2) begin
              o_axist_tx_tready[2] <= 1'b0;
          end
          else if(i_avst_tx_ready[2]) begin
              o_axist_tx_tready[2] <= 1'b1;
          end
          else if (av_st_tx_fifo_af[2]) begin   //** check this condition
             o_axist_tx_tready[2] <= 1'b0;
          end
      end   

      always @(posedge i_tx_clk_p3 or negedge i_tx_reset_n_p3) //* split  port wise , clk and reset
      begin
          if(~i_tx_reset_n_p3) begin
              o_axist_tx_tready[3] <= 1'b0;
          end
          else if(i_avst_tx_ready[3]) begin
              o_axist_tx_tready[3] <= 1'b1;
          end
          else if (av_st_tx_fifo_af[3]) begin   //** check this condition
             o_axist_tx_tready[3] <= 1'b0;
          end
      end     
      
      hssi_ss_delay_reg #(
         .CYCLES (READY_LATENCY),                                 
         .WIDTH  (1)                                              
      )i_axi_ready_latency_delay_reg_p0 (
         .clk    (i_tx_clk_p0),
         .din    (o_axist_tx_tready[0]),
         .dout   (axist_tx_tready_delayed[0])
         );

      hssi_ss_delay_reg #(
         .CYCLES (READY_LATENCY),                                 
         .WIDTH  (1)                                              
      )i_axi_ready_latency_delay_reg_p1 (
         .clk    (i_tx_clk_p1),
         .din    (o_axist_tx_tready[1]),
         .dout   (axist_tx_tready_delayed[1])
         );   

      hssi_ss_delay_reg #(
         .CYCLES (READY_LATENCY),                                 
         .WIDTH  (1)                                              
      )i_axi_ready_latency_delay_reg_p2 (
         .clk    (i_tx_clk_p2),
         .din    (o_axist_tx_tready[2]),
         .dout   (axist_tx_tready_delayed[2])
         ); 

      hssi_ss_delay_reg #(
         .CYCLES (READY_LATENCY),                                 
         .WIDTH  (1)                                              
      )i_axi_ready_latency_delay_reg_p3 (
         .clk    (i_tx_clk_p3),
         .din    (o_axist_tx_tready[3]),
         .dout   (axist_tx_tready_delayed[3])
         );              

   end   
   else if (NUM_MAX_PORTS == 2) begin: TVALID_MUX_2P
   
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
      begin
          if (~i_tx_reset_n_p0) begin
              avst_tx_valid_d1_p0             <= 1'b0;
              avst_tx_valid_d2_p0             <= 1'b0;     
              avst_tx_user_d1_p0              <= '0;  
              avst_tx_user_d2_p0              <= '0;     
              fifo_wrreq_d1[0]                <= '0;
              fifo_wrreq_d2[0]                <= '0;              
          end
          else begin
              avst_tx_valid_d1_p0             <= i_axist_tx_tvalid[0];           
              avst_tx_valid_d2_p0             <= avst_tx_valid_d1_p0; 
              avst_tx_user_d1_p0              <= i_axist_tx_tuser[AVST_USER-1:0];
              avst_tx_user_d2_p0              <= avst_tx_user_d1_p0;    
              fifo_wrreq_d1[0]                <= axist_tx_tready_delayed[0];     //delaying the wrreq of fifo to ready latency value
              fifo_wrreq_d2[0]                <= fifo_wrreq_d1[0];               //wrreq delayed by 2 cycles to match conversion delay              
          end
      end
      
      always @(posedge i_tx_clk_p1 or negedge i_tx_reset_n_p1) 
      begin
          if (~i_tx_reset_n_p1) begin
              avst_tx_valid_d1_p1             <= 1'b0;
              avst_tx_valid_d2_p1             <= 1'b0;
              avst_tx_user_d1_p1              <= '0;  
              avst_tx_user_d2_p1              <= '0; 
              fifo_wrreq_d1[1]                <= '0;
              fifo_wrreq_d2[1]                <= '0;                  
          end
          else begin
              avst_tx_valid_d1_p1             <= i_axist_tx_tvalid[1];           
              avst_tx_valid_d2_p1             <= avst_tx_valid_d1_p1;   
              avst_tx_user_d1_p1              <= i_axist_tx_tuser[(2*AVST_USER)-1:AVST_USER];
              avst_tx_user_d2_p1              <= avst_tx_user_d1_p1;   
              fifo_wrreq_d1[1]                <= axist_tx_tready_delayed[1];     //delaying the wrreq of fifo to ready latency value
              fifo_wrreq_d2[1]                <= fifo_wrreq_d1[1];               //wrreq delayed by 2 cycles to match conversion delay            
          end
      end  

      always @(posedge i_tx_clk_p0)        
      begin 
         avst_tx_user_client_d1_p0 <= i_axist_tx_tuser[TUSER-1:TUSER-NUM_SEG_BITS]; //sop->423:422
         axist_tx_tready_delayed_d1[0] <= axist_tx_tready_delayed[0]; //ready delayed one more cycle to match delay of avst_eop_d1 and avst_sop_d1 to generate avst_tx_inframe_d2 in mac segmented generate block        
      end    
         
      always @(posedge i_tx_clk_p1)        
      begin 
         avst_tx_user_client_d1_p1 <= i_axist_tx_tuser[(2*TUSER)-1:(2*TUSER)-(NUM_SEG_BITS)]; //sop->423:422
         axist_tx_tready_delayed_d1[1] <= axist_tx_tready_delayed[1]; //ready delayed one more cycle to match delay of avst_eop_d1 and avst_sop_d1 to generate avst_tx_inframe_d2 in mac segmented generate block                
      end        
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) //* split  port wise , clk and reset
      begin
          if(~i_tx_reset_n_p0) begin
              o_axist_tx_tready[0] <= 1'b0;
          end
          else if(i_avst_tx_ready[0]) begin
              o_axist_tx_tready[0] <= 1'b1;
          end
          else if (av_st_tx_fifo_af[0]) begin   //** check this condition
             o_axist_tx_tready[0] <= 1'b0;
          end
      end
      
      always @(posedge i_tx_clk_p1 or negedge i_tx_reset_n_p1) //* split  port wise , clk and reset
      begin
          if(~i_tx_reset_n_p1) begin
              o_axist_tx_tready[1] <= 1'b0;
          end
          else if(i_avst_tx_ready[1]) begin
              o_axist_tx_tready[1] <= 1'b1;
          end
          else if (av_st_tx_fifo_af[1]) begin   //** check this condition
             o_axist_tx_tready[1] <= 1'b0;
          end
      end   
      
      hssi_ss_delay_reg #(
         .CYCLES (READY_LATENCY),                                 
         .WIDTH  (1)                                              
      )i_axi_ready_latency_delay_reg_p0 (
         .clk    (i_tx_clk_p0),
         .din    (o_axist_tx_tready[0]),
         .dout   (axist_tx_tready_delayed[0])
         );

      hssi_ss_delay_reg #(
         .CYCLES (READY_LATENCY),                                 
         .WIDTH  (1)                                              
      )i_axi_ready_latency_delay_reg_p1 (
         .clk    (i_tx_clk_p1),
         .din    (o_axist_tx_tready[1]),
         .dout   (axist_tx_tready_delayed[1])
         );   
      
   end
   else begin : TVALID_MUX_1P
   
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
      begin
          if (~i_tx_reset_n_p0) begin
              avst_tx_valid_d1_p0             <= 1'b0;
              avst_tx_valid_d2_p0             <= 1'b0;      
              avst_tx_user_d1_p0              <= '0;  
              avst_tx_user_d2_p0              <= '0;     
              fifo_wrreq_d1                   <= '0;
              fifo_wrreq_d2                   <= '0;
          end
          else begin
              avst_tx_valid_d1_p0             <= i_axist_tx_tvalid;          
              avst_tx_valid_d2_p0             <= avst_tx_valid_d1_p0; 
              avst_tx_user_d1_p0              <= i_axist_tx_tuser;
              avst_tx_user_d2_p0              <= avst_tx_user_d1_p0;    
              fifo_wrreq_d1                   <= axist_tx_tready_delayed;     //delaying the wrreq of fifo to ready latency value
              fifo_wrreq_d2                   <= fifo_wrreq_d1;               //wrreq delayed by 2 cycles to match conversion delay
          end
      end
      
      always @(posedge i_tx_clk_p0)         
      begin 
         avst_tx_user_client_d1_p0  <= i_axist_tx_tuser[TUSER-1:(TUSER-NUM_SEG_BITS)]; //sop->423:422
         axist_tx_tready_delayed_d1 <= axist_tx_tready_delayed; //ready delayed one more cycle to match delay of avst_eop_d1 and avst_sop_d1 to generate avst_tx_inframe_d2 in mac segmented generate block
      end      

      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) //* split  port wise , clk and reset
      begin
          if(~i_tx_reset_n_p0) begin
              o_axist_tx_tready <= 1'b0;
          end
          else if(i_avst_tx_ready) begin
              o_axist_tx_tready <= 1'b1;
          end
          else if (av_st_tx_fifo_af) begin   //** check this condition
             o_axist_tx_tready <= 1'b0;
          end
      end   

      hssi_ss_delay_reg #(
         .CYCLES (READY_LATENCY),                                 
         .WIDTH  (1)                                              
      )i_axi_ready_latency_delay_reg (
         .clk    (i_tx_clk_p0),
         .din    (o_axist_tx_tready),
         .dout   (axist_tx_tready_delayed)
         );   
      
   end       
end

endgenerate   

generate if ((AVST_MODE == "MAC_SEGMENTED" || AXIST_MODE == "MULTI_PACKET") && (NUM_MAX_PORTS == 1)) //Non-DR cases will always enter this loop
begin :MAC_SEGMENTED_1P
    genvar j;
    
   for (j=0; j<NUM_SEG; j=j+1) begin :TX_MS_1P_LOGIC
   
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) begin
         if (~i_tx_reset_n_p0) begin
            avst_eop_d1_p0[j] <= 1'b0;
            avst_sop_latch_p0[j] <= 1'b1;
         end
         else if (axist_tx_tready_delayed[0] && i_axist_tx_tvalid[0] && i_axist_tx_tlast_segment[j]) begin
            avst_eop_d1_p0[j] <= 1'b1 ;
            avst_sop_latch_p0[j] <= 1'b1 ;
         end
         else if (axist_tx_tready_delayed[0] && i_axist_tx_tvalid[0]) begin
            avst_eop_d1_p0[j] <= 1'b0 ;
            avst_sop_latch_p0[j] <= 1'b0 ;
         end         
         else begin
            avst_eop_d1_p0[j] <= 1'b0;
            avst_sop_latch_p0[j] <= avst_sop_latch_p0[j];
         end         
      end
        
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) begin
         if (~i_tx_reset_n_p0) begin
            avst_eop_d2_p0[j] <= 1'b0;
         end
         else begin
            avst_eop_d2_p0[j] <= avst_eop_d1_p0[j];
         end
      end 

if ((PORT_PROFILE == "25GbE" || PORT_PROFILE == "50GAUI-1") || ((DR_ENABLE == 0) && (PORT_PROFILE == "10GbE" || PORT_PROFILE == "40GCAUI-4" || PORT_PROFILE == "50GAUI-2")))  
begin :MS_1P_25G_50G
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
      begin
         if (~i_tx_reset_n_p0) 
            avst_sop_d1_p0[j] <= 1'b0;
         else if (axist_tx_tready_delayed[0] && i_axist_tx_tvalid[0] && i_axist_tx_tkeep_segment[8*(j+1)-1:8*j] == 8'hff) begin
            if (active_segments == NUM_SEG)
            begin
               if ((j==0) && ((avst_sop_latch_p0[NUM_SEG-1] && axist_tx_tready_delayed[0]) || (axist_tx_tready_delayed_d1[0] && avst_tx_valid_d1_p0 && 
                   (axist_tx_tlast_segment_d1[NUM_SEG-1] || (axist_tx_tkeep_segment_d1[(8*NUM_SEG)-1:8*(NUM_SEG-1)] == 8'b0)))))   
                  avst_sop_d1_p0[j] <= 1'b1;  
               else if ((j!=0) && (i_axist_tx_tlast_segment[j-1] || (i_axist_tx_tkeep_segment[8*j-1:8*(j-1)] == 8'b0)))
                  avst_sop_d1_p0[j] <= 1'b1;
               else 
                  avst_sop_d1_p0[j] <= 1'b0; 
            end
            else  //for 1x25g reconfig group in and 1x50 base profile
            begin
               if ((j==0) && ((avst_sop_latch_p0[0] && axist_tx_tready_delayed[0]) || (axist_tx_tready_delayed_d1[0] && avst_tx_valid_d1_p0 && 
                   (axist_tx_tlast_segment_d1[0] || (axist_tx_tkeep_segment_d1[7:0] == 8'b0)))))   
                  avst_sop_d1_p0[j] <= 1'b1;
               // else if (((j!=0) && (j<active_segments)) && (i_axist_tx_tlast_segment[j-1] || (i_axist_tx_tkeep_segment[8*j-1:8*(j-1)] == 8'b0)))
                  // avst_sop_d1_p0[j] <= 1'b1;
               else 
                  avst_sop_d1_p0[j] <= 1'b0; 
            end                                              
         end
         else
            avst_sop_d1_p0[j] <= 1'b0;     
      end
end
else  //100G and NoN DR 100, 200, 400
begin: MS_1P_100G
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
      begin
         if (~i_tx_reset_n_p0) 
            avst_sop_d1_p0[j] <= 1'b0;
         else if (axist_tx_tready_delayed[0] && i_axist_tx_tvalid[0] && i_axist_tx_tkeep_segment[8*(j+1)-1:8*j] == 8'hff) begin
            if (active_segments == NUM_SEG)
            begin
               if ((j==0) && ((avst_sop_latch_p0[NUM_SEG-1] && axist_tx_tready_delayed[0]) || (axist_tx_tready_delayed_d1[0] && avst_tx_valid_d1_p0 && 
                  (axist_tx_tlast_segment_d1[NUM_SEG-1] || (axist_tx_tkeep_segment_d1[(8*NUM_SEG)-1:8*(NUM_SEG-1)] == 8'b0)))))   
                  avst_sop_d1_p0[j] <= 1'b1;
               else if ((j!=0) && (i_axist_tx_tlast_segment[j-1] || (i_axist_tx_tkeep_segment[8*j-1:8*(j-1)] == 8'b0)))
                  avst_sop_d1_p0[j] <= 1'b1;
               else 
                  avst_sop_d1_p0[j] <= 1'b0; 
            end
            else if (active_segments == NUM_SEG/2)      
            begin
               if ((j==0) && ((avst_sop_latch_p0[(NUM_SEG/2)-1] && axist_tx_tready_delayed[0]) || (axist_tx_tready_delayed_d1[0] && avst_tx_valid_d1_p0 && 
                   (axist_tx_tlast_segment_d1[(NUM_SEG/2)-1] || (axist_tx_tkeep_segment_d1[8*(NUM_SEG/2)-1:8*((NUM_SEG/2)-1)] == 8'b0)))))   
                  avst_sop_d1_p0[j] <= 1'b1;
               else if (((j!=0) && (j<active_segments)) && (i_axist_tx_tlast_segment[j-1] || (i_axist_tx_tkeep_segment[8*j-1:8*(j-1)] == 8'b0)))
                  avst_sop_d1_p0[j] <= 1'b1;
               else 
                  avst_sop_d1_p0[j] <= 1'b0; 
            end               
            else if (active_segments == NUM_SEG/4)      
            begin
               if ((j==0) && ((avst_sop_latch_p0[(NUM_SEG/4)-1] && axist_tx_tready_delayed[0]) || (axist_tx_tready_delayed_d1[0] && avst_tx_valid_d1_p0 && 
                   (axist_tx_tlast_segment_d1[(NUM_SEG/4)-1] || (axist_tx_tkeep_segment_d1[8*(NUM_SEG/4)-1:8*((NUM_SEG/4)-1)] == 8'b0)))))   
                  avst_sop_d1_p0[j] <= 1'b1;
               else if (((j!=0) && (j<active_segments)) && (i_axist_tx_tlast_segment[j-1] || (i_axist_tx_tkeep_segment[8*j-1:8*(j-1)] == 8'b0)))
                  avst_sop_d1_p0[j] <= 1'b1;
               else 
                  avst_sop_d1_p0[j] <= 1'b0; 
            end     
            else
               avst_sop_d1_p0[j] <= 1'b0;               
         end
         else
            avst_sop_d1_p0[j] <= 1'b0;     
      end
end   
        
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
      begin
         if (~i_tx_reset_n_p0)
            avst_tx_inframe_d2[j] <= 1'b0;
         else if (avst_sop_d1_p0[j])
            avst_tx_inframe_d2[j] <= 1'b1;
         else if (avst_eop_d1_p0[j])
            avst_tx_inframe_d2[j] <= 1'b0;
         else if (axist_tx_tready_delayed_d1[0] && avst_tx_valid_d1_p0 && (|axist_tx_tkeep_segment_d1[8*(j+1)-1:8*j]))
            avst_tx_inframe_d2[j] <= 1'b1;
         else 
            avst_tx_inframe_d2[j] <= 1'b0;
      end
      

      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
      begin
         if (~i_tx_reset_n_p0)
            avst_tx_data_valid_p0[j] <= 1'b0;
         else
            avst_tx_data_valid_p0[j] <= (avst_sop_d1_p0[j])? 1'b1 : (|avst_eop_d2_p0)? 1'b0 : 
                                        (axist_tx_tready_delayed_d1[0] && avst_tx_valid_d1_p0 && (|axist_tx_tkeep_segment_d1[8*(j+1)-1:8*j]))? 1'b1: avst_tx_data_valid_p0[j];
      end

      // assign avst_tx_data_valid_p0[j] = avst_tx_inframe_d2[j] | avst_eop_d2_p0[j];
      
      keep2empty #(
         .EMPTY_BITS  (3),
         .NO_OF_BYTES (8)
      )keep2empty_inst(
         .clk(i_tx_clk_p0),
         // .rst_n(i_tx_reset_n_p0),  //** check with sathish, if many changes required on tcl
         .keep_bits_in({{56{1'b0}},i_axist_tx_tkeep_segment[(j+1)*8-1:8*j]}), //To support 64 bit keep2empty conversion function
         .empty_bits_out_d1(keep2empty_d1[(j+1)*EMPTY_BITS-1:EMPTY_BITS*j])          
      );
   
      always @(*) 
      begin
         if (avst_tx_valid_d2_p0 && axist_tx_tlast_segment_d2[j]) 
            avst_tx_eop_empty_d2[(j+1)*EMPTY_BITS-1:EMPTY_BITS*j] = avst_tx_eop_empty_d1[(j+1)*EMPTY_BITS-1:EMPTY_BITS*j];
         else 
            avst_tx_eop_empty_d2[(j+1)*EMPTY_BITS-1:EMPTY_BITS*j] = {EMPTY_BITS{1'b0}};
      end 
   
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) begin
         if (~i_tx_reset_n_p0) begin
            tx_parity_detect_d1[j]       <= 1'b0;
            mac_tx_pkt_seg_parity_d1[j] <= 1'b0;
         end
         else begin
            tx_parity_detect_d1[j]       <= ^(axi_st_tx_seg_data[j]);
            mac_tx_pkt_seg_parity_d1[j] <= i_axist_tx_pkt_seg_parity[j];
         end
      end
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) begin
         if (~i_tx_reset_n_p0)
            tx_parity_error_d2[j] <= 1'b0;
         else if (mac_avst_sop_d1[j] && (tx_parity_detect_d1[j] == mac_tx_pkt_seg_parity_d1[j]))
            tx_parity_error_d2[j] <= 1'b1;  //(tx_parity_detect_d1[j] == mac_tx_pkt_seg_parity_d1[j]) ? 1'b1 : 1'b0;           
         else if (|mac_avst_eop_d2)
            tx_parity_error_d2[j] <= 1'b0;
         else if(avst_tx_valid_d1_p0 && axist_tx_tready_delayed_d1 && (tx_parity_detect_d1[j] == mac_tx_pkt_seg_parity_d1[j]))
            tx_parity_error_d2[j] <= 1'b1;  
         else
            tx_parity_error_d2[j] <= tx_parity_error_d2[j];
      end       
      
      always @(posedge i_tx_clk_p0) begin //* muxed reset based on i_active_port    
         avst_tx_eop_empty_d1[(j+1)*EMPTY_BITS-1:EMPTY_BITS*j] <= keep2empty_d1[(j+1)*EMPTY_BITS-1:EMPTY_BITS*j];
      end     
      
      assign mac_avst_tx_user_client[(2*j)+1] = avst_tx_user_client_d2_p0[(2*j)+1];  //1,3, 5,7
      assign mac_avst_tx_user_client[2*j]     = mac_avst_eop_d2[j] ? (avst_tx_user_client_d2_p0[2*j] | par_err_detected): avst_tx_user_client_d2_p0[2*j]; //0,2,4

      // assign avst_tx_eop_empty_d1[(j+1)*EMPTY_BITS-1:EMPTY_BITS*j] = keep2empty_d1[(j+1)*EMPTY_BITS-1:EMPTY_BITS*j];
      assign axi_st_tx_seg_data[j]                                 = i_axist_tx_tdata[64*(j+1)-1:64*j];
      
   end

end   

else if (AVST_MODE == "MAC_SEGMENTED" && (NUM_MAX_PORTS == 2)) begin : MAC_SEGMENTED_2P 
genvar k;

for (k=0; k<NUM_SEG; k=k+1) begin :TX_MS_2P_LOGIC
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) //* muxed reset based on i_active_port
      begin
         if (~i_tx_reset_n_p0) begin
            avst_eop_d1_p0[k] <= 1'b0;
            avst_sop_latch_p0[k] <= 1'b1;
         end
         else if (axist_tx_tready_delayed[0] && i_axist_tx_tvalid[0] && axist_tx_tlast_segment_p0[k]) begin
            avst_eop_d1_p0[k] <= 1'b1 ;
            avst_sop_latch_p0[k] <= 1'b1 ;
         end
         else if (axist_tx_tready_delayed[0] && i_axist_tx_tvalid[0]) begin
            avst_eop_d1_p0[k] <= 1'b0 ;
            avst_sop_latch_p0[k] <= 1'b0 ;
         end         
         else begin
            avst_eop_d1_p0[k] <= 1'b0;
            avst_sop_latch_p0[k] <= avst_sop_latch_p0[k];
         end         
      end     
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1) //* muxed reset based on i_active_port
      begin
         if (~i_tx_reset_n_p1) begin
            avst_eop_d1_p1[k] <= 1'b0;
            avst_sop_latch_p1[k] <= 1'b1;
         end
         else if (axist_tx_tready_delayed[1] && i_axist_tx_tvalid[1] && axist_tx_tlast_segment_p1[k]) begin
            avst_eop_d1_p1[k] <= 1'b1 ;
            avst_sop_latch_p1[k] <= 1'b1 ;
         end
         else if (axist_tx_tready_delayed[1] && i_axist_tx_tvalid[1]) begin
            avst_eop_d1_p1[k] <= 1'b0 ;
            avst_sop_latch_p1[k] <= 1'b0 ;
         end         
         else begin
            avst_eop_d1_p1[k] <= 1'b0;
            avst_sop_latch_p1[k] <= avst_sop_latch_p1[k];
         end         
      end
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) //* muxed reset based on i_active_port
      begin
         if (~i_tx_reset_n_p0) begin
            avst_eop_d2_p0[k] <= 1'b0;
         end
         else begin
            avst_eop_d2_p0[k] <= avst_eop_d1_p0[k];
         end
      end       
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1) //* muxed reset based on i_active_port
      begin
         if (~i_tx_reset_n_p1) begin
            avst_eop_d2_p1[k] <= 1'b0;
         end
         else begin
            avst_eop_d2_p1[k] <= avst_eop_d1_p1[k];
         end
      end             
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) //* muxed reset based on i_active_port //* Review SOP gen logic
      begin
         if (~i_tx_reset_n_p0) 
            avst_sop_d1_p0[k] <= 1'b0;
         else if (axist_tx_tready_delayed[0] && i_axist_tx_tvalid[0] && axist_tx_tkeep_segment_p0[8*(k+1)-1:8*k] == 8'hff) begin
            if (active_segments == NUM_SEG)
            begin
               if ((k==0) && ((avst_sop_latch_p0[NUM_SEG-1] && axist_tx_tready_delayed[0]) || (axist_tx_tready_delayed_d1[0] && 
                    avst_tx_valid_d1_p0 && (axist_tx_tlast_segment_p0_d1[NUM_SEG-1] || (axist_tx_tkeep_segment_p0_d1[(8*NUM_SEG)-1:8*(NUM_SEG-1)] == 8'b0)))))   
                  avst_sop_d1_p0[k] <= 1'b1;
               else if ((k!=0) && (axist_tx_tlast_segment_p0[k-1] || (axist_tx_tkeep_segment_p0[8*k-1:8*(k-1)] == 8'b0)))
                  avst_sop_d1_p0[k] <= 1'b1;
               else 
                  avst_sop_d1_p0[k] <= 1'b0; 
            end
            else if (active_segments == NUM_SEG/2)
            begin
               if ((k==0) && ((avst_sop_latch_p0[(NUM_SEG/2)-1] && axist_tx_tready_delayed[0]) || (axist_tx_tready_delayed_d1[0] && 
                    avst_tx_valid_d1_p0 && (axist_tx_tlast_segment_p0_d1[(NUM_SEG/2)-1] || (axist_tx_tkeep_segment_p0_d1[(8*(NUM_SEG/2))-1:8*((NUM_SEG/2)-1)] == 8'b0)))))   
                  avst_sop_d1_p0[k] <= 1'b1;
               else if (((k!=0) && (k<active_segments)) && (axist_tx_tlast_segment_p0[k-1] || (axist_tx_tkeep_segment_p0[8*k-1:8*(k-1)] == 8'b0)))
                  avst_sop_d1_p0[k] <= 1'b1;
               else 
                  avst_sop_d1_p0[k] <= 1'b0; 
            end         
            else if (active_segments == NUM_SEG/4)
            begin
               if ((k==0) && ((avst_sop_latch_p0[(NUM_SEG/4)-1] && axist_tx_tready_delayed[0]) || (axist_tx_tready_delayed_d1[0] && 
                    avst_tx_valid_d1_p0 && (axist_tx_tlast_segment_p0_d1[(NUM_SEG/4)-1] || (axist_tx_tkeep_segment_p0_d1[(8*(NUM_SEG/4))-1:8*((NUM_SEG/4)-1)] == 8'b0)))))   
                  avst_sop_d1_p0[k] <= 1'b1;
               else if (((k!=0) && (k<active_segments)) && (axist_tx_tlast_segment_p0[k-1] || (axist_tx_tkeep_segment_p0[8*k-1:8*(k-1)] == 8'b0)))
                  avst_sop_d1_p0[k] <= 1'b1;
               else 
                  avst_sop_d1_p0[k] <= 1'b0; 
            end                     
            else
               avst_sop_d1_p0[k] <= 1'b0;     
         end     
         else
            avst_sop_d1_p0[k] <= 1'b0;      
      end           

      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1) 
      begin
         if (~i_tx_reset_n_p1) 
            avst_sop_d1_p1[k] <= 1'b0;
         else if (axist_tx_tready_delayed[1] && i_axist_tx_tvalid[1] && axist_tx_tkeep_segment_p1[8*(k+1)-1:8*k] == 8'hff) begin
            if (active_segments == NUM_SEG)
            begin
               if ((k==0) && ((avst_sop_latch_p1[NUM_SEG-1] && axist_tx_tready_delayed[1]) || (axist_tx_tready_delayed_d1[1] && 
                    avst_tx_valid_d1_p1 && (axist_tx_tlast_segment_p1_d1[NUM_SEG-1] || (axist_tx_tkeep_segment_p1_d1[(8*NUM_SEG)-1:8*(NUM_SEG-1)] == 8'b0)))))   
                  avst_sop_d1_p1[k] <= 1'b1;
               else if ((k!=0) && (axist_tx_tlast_segment_p1[k-1] || (axist_tx_tkeep_segment_p1[8*k-1:8*(k-1)] == 8'b0)))
                  avst_sop_d1_p1[k] <= 1'b1;
               else 
                  avst_sop_d1_p1[k] <= 1'b0; 
            end
            else if (active_segments == NUM_SEG/2)
            begin
               if ((k==0) && ((avst_sop_latch_p1[(NUM_SEG/2)-1] && axist_tx_tready_delayed[1]) || (axist_tx_tready_delayed_d1[1] && 
                    avst_tx_valid_d1_p1 && (axist_tx_tlast_segment_p1_d1[(NUM_SEG/2)-1] || (axist_tx_tkeep_segment_p1_d1[(8*(NUM_SEG/2))-1:8*((NUM_SEG/2)-1)] == 8'b0)))))   
                  avst_sop_d1_p1[k] <= 1'b1;
               else if (((k!=0) && (k<active_segments)) && (axist_tx_tlast_segment_p1[k-1] || (axist_tx_tkeep_segment_p1[8*k-1:8*(k-1)] == 8'b0)))
                  avst_sop_d1_p1[k] <= 1'b1;
               else 
                  avst_sop_d1_p1[k] <= 1'b0; 
            end         
            else if (active_segments == NUM_SEG/4)
            begin
               if ((k==0) && ((avst_sop_latch_p1[(NUM_SEG/4)-1] && axist_tx_tready_delayed[1]) || (axist_tx_tready_delayed_d1[1] && 
                    avst_tx_valid_d1_p1 && (axist_tx_tlast_segment_p1_d1[(NUM_SEG/4)-1] || (axist_tx_tkeep_segment_p1_d1[(8*(NUM_SEG/4))-1:8*((NUM_SEG/4)-1)] == 8'b0)))))   
                  avst_sop_d1_p1[k] <= 1'b1;
               else if (((k!=0) && (k<active_segments)) && (axist_tx_tlast_segment_p1[k-1] || (axist_tx_tkeep_segment_p1[8*k-1:8*(k-1)] == 8'b0)))
                  avst_sop_d1_p1[k] <= 1'b1;
               else 
                  avst_sop_d1_p1[k] <= 1'b0; 
            end                     
            else
               avst_sop_d1_p1[k] <= 1'b0;     
         end     
         else
            avst_sop_d1_p1[k] <= 1'b0;      
      end           
            
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) //* muxed reset based on i_active_port
      begin
         if (~i_tx_reset_n_p0)
            avst_tx_inframe_d2_p0[k] <= 1'b0;
         else if (avst_sop_d1_p0[k])
            avst_tx_inframe_d2_p0[k] <= 1'b1;
         else if (avst_eop_d1_p0[k])
            avst_tx_inframe_d2_p0[k] <= 1'b0;
         else if (axist_tx_tready_delayed_d1[0] && avst_tx_valid_d1_p0 && (|axist_tx_tkeep_segment_p0_d1[8*(k+1)-1:8*k]))
            avst_tx_inframe_d2_p0[k] <= 1'b1;
         else 
            avst_tx_inframe_d2_p0[k] <= 1'b0;
      end 
   
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1) 
      begin
         if (~i_tx_reset_n_p1)
            avst_tx_inframe_d2_p1[k] <= 1'b0;
         else if (avst_sop_d1_p1[k])
            avst_tx_inframe_d2_p1[k] <= 1'b1;
         else if (avst_eop_d1_p1[k])
            avst_tx_inframe_d2_p1[k] <= 1'b0;
         else if (axist_tx_tready_delayed_d1[1] && avst_tx_valid_d1_p1 && (|axist_tx_tkeep_segment_p1_d1[8*(k+1)-1:8*k]))
            avst_tx_inframe_d2_p1[k] <= 1'b1;
         else 
            avst_tx_inframe_d2_p1[k] <= 1'b0;
      end     
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) //* muxed reset based on i_active_port
      begin
         if (~i_tx_reset_n_p0)
            avst_tx_data_valid_p0[k] <= 1'b0;
         else
            avst_tx_data_valid_p0[k] <= (avst_sop_d1_p0[k])? 1'b1 : (|avst_eop_d2_p0)? 1'b0 : 
                                        (axist_tx_tready_delayed_d1[0] && avst_tx_valid_d1_p0 && (|axist_tx_tkeep_segment_p0_d1[8*(k+1)-1:8*k]))? 1'b1: avst_tx_data_valid_p0[k];
      end
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1) 
      begin
         if (~i_tx_reset_n_p1)
            avst_tx_data_valid_p1[k] <= 1'b0;
         else
            avst_tx_data_valid_p1[k] <= (avst_sop_d1_p1[k])? 1'b1 : (|avst_eop_d2_p1)? 1'b0 : 
                                        (axist_tx_tready_delayed_d1[1] && avst_tx_valid_d1_p1 && (|axist_tx_tkeep_segment_p1_d1[8*(k+1)-1:8*k]))? 1'b1: avst_tx_data_valid_p1[k];
      end     

      keep2empty #(                                                         //* Port wise tkeep segment should be updated -> instance - not required
         .EMPTY_BITS  (3),                                                  //* use combo logic - function (check if it can be generic) 32 bit function after signal declaration tkeep2empty - done 
         .NO_OF_BYTES (8)
      )keep2empty_inst(
         .clk(i_tx_clk_p0),
         // .rst_n(i_tx_reset_n_p0), 
         .keep_bits_in({{56{1'b0}},i_axist_tx_tkeep_segment[(k+1)*8-1:8*k]}), 
         .empty_bits_out_d1(keep2empty_d1[(k+1)*EMPTY_BITS-1:EMPTY_BITS*k])          
      );
      
      always @(posedge i_tx_clk_p0) begin //* muxed reset based on i_active_port    
         avst_tx_eop_empty_d1[(k+1)*EMPTY_BITS-1:EMPTY_BITS*k] <= keep2empty_d1[(k+1)*EMPTY_BITS-1:EMPTY_BITS*k];
      end     
      
      assign tx_parity_detect_d1[k] = ^(axi_st_tx_seg_data[k]);
            
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) begin  //* muxed reset based on i_active_port
         if (~i_tx_reset_n_p0)
            tx_parity_error_d2_p0[k] <= 1'b0;
         else if (avst_sop_d1_p0[k] && (tx_parity_detect_d1_p0[k] == mac_tx_pkt_seg_parity_d1_p0[k]))
            tx_parity_error_d2_p0[k] <= 1'b1;  //(tx_parity_detect_d1[k] == mac_tx_pkt_seg_parity_d1[k]) ? 1'b1 : 1'b0;           
         else if (|avst_eop_d2_p0)
            tx_parity_error_d2_p0[k] <= 1'b0;
         else if(avst_tx_valid_d1_p0 && axist_tx_tready_delayed_d1[0] && (tx_parity_detect_d1_p0[k] == mac_tx_pkt_seg_parity_d1_p0[k]))
            tx_parity_error_d2_p0[k] <= 1'b1;  
         else
            tx_parity_error_d2_p0[k] <= tx_parity_error_d2_p0[k];
      end 
   
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1) begin //* muxed reset based on i_active_port
         if (~i_tx_reset_n_p1)
            tx_parity_error_d2_p1[k] <= 1'b0;
         else if (avst_sop_d1_p1[k] && (tx_parity_detect_d1_p1[k] == mac_tx_pkt_seg_parity_d1_p1[k]))
            tx_parity_error_d2_p1[k] <= 1'b1;  //(tx_parity_detect_d1[k] == mac_tx_pkt_seg_parity_d1[k]) ? 1'b1 : 1'b0;           
         else if (|avst_eop_d2_p1)
            tx_parity_error_d2_p1[k] <= 1'b0;
         else if(avst_tx_valid_d1_p1 && axist_tx_tready_delayed_d1[1] && (tx_parity_detect_d1_p1[k] == mac_tx_pkt_seg_parity_d1_p1[k]))
            tx_parity_error_d2_p1[k] <= 1'b1;  
         else
            tx_parity_error_d2_p1[k] <= tx_parity_error_d2_p1[k];
      end     

      // assign avst_tx_eop_empty_d1[(k+1)*EMPTY_BITS-1:EMPTY_BITS*k] = keep2empty_d1[(k+1)*EMPTY_BITS-1:EMPTY_BITS*k];  
      
      assign axi_st_tx_seg_data[k] = i_axist_tx_tdata[64*(k+1)-1:64*k];

      assign avst_tx_user_client_p0[(2*k)+1] = avst_tx_user_client_d2_p0[(2*k)+1];  //1,3, 5,7
      assign avst_tx_user_client_p1[(2*k)+1] = avst_tx_user_client_d2_p1[(2*k)+1];  //1,3, 5,7
      assign avst_tx_user_client_p0[2*k]     = avst_eop_d2_p0[k] ? (avst_tx_user_client_d2_p0[2*k] | par_err_detected_p0): avst_tx_user_client_d2_p0[2*k]; //0,2,4
      assign avst_tx_user_client_p1[2*k]     = avst_eop_d2_p1[k] ? (avst_tx_user_client_d2_p1[2*k] | par_err_detected_p1): avst_tx_user_client_d2_p1[2*k]; //0,2,4
end      
end     

else if (AVST_MODE == "MAC_SEGMENTED" && (NUM_MAX_PORTS == 4)) begin : MAC_SEGMENTED_4P 
genvar m;

for (m=0; m<NUM_SEG; m=m+1) begin :TX_MS_4P_LOGIC
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) begin
         if (~i_tx_reset_n_p0) begin
            avst_eop_d1_p0[m] <= 1'b0;
            avst_sop_latch_p0[m] <= 1'b1;
         end
         else if (axist_tx_tready_delayed[0] && i_axist_tx_tvalid[0] && axist_tx_tlast_segment_p0[m]) begin
            avst_eop_d1_p0[m] <= 1'b1 ;
            avst_sop_latch_p0[m] <= 1'b1 ;
         end
         else if (axist_tx_tready_delayed[0] && i_axist_tx_tvalid[0]) begin
            avst_eop_d1_p0[m] <= 1'b0 ;
            avst_sop_latch_p0[m] <= 1'b0 ;
         end         
         else begin
            avst_eop_d1_p0[m] <= 1'b0;
            avst_sop_latch_p0[m] <= avst_sop_latch_p0[m];
         end         
      end
   
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1) 
      begin
         if (~i_tx_reset_n_p1) begin
            avst_eop_d1_p1[m] <= 1'b0;
            avst_sop_latch_p1[m] <= 1'b1;
         end
         else if (axist_tx_tready_delayed[1] && i_axist_tx_tvalid[1] && axist_tx_tlast_segment_p1[m]) begin
            avst_eop_d1_p1[m] <= 1'b1 ;
            avst_sop_latch_p1[m] <= 1'b1 ;
         end
         else if (axist_tx_tready_delayed[1] && i_axist_tx_tvalid[1]) begin
            avst_eop_d1_p1[m] <= 1'b0 ;
            avst_sop_latch_p1[m] <= 1'b0 ;
         end         
         else begin
            avst_eop_d1_p1[m] <= 1'b0;
            avst_sop_latch_p1[m] <= avst_sop_latch_p1[m];
         end         
      end
   
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p2) 
      begin
         if (~i_tx_reset_n_p2) begin
            avst_eop_d1_p2[m] <= 1'b0;
            avst_sop_latch_p2[m] <= 1'b1;
         end
         else if (axist_tx_tready_delayed[2] && i_axist_tx_tvalid[2] && axist_tx_tlast_segment_p2[m]) begin
            avst_eop_d1_p2[m] <= 1'b1 ;
            avst_sop_latch_p2[m] <= 1'b1 ;
         end
         else if (axist_tx_tready_delayed[2] && i_axist_tx_tvalid[2]) begin
            avst_eop_d1_p2[m] <= 1'b0 ;
            avst_sop_latch_p2[m] <= 1'b0 ;
         end         
         else begin
            avst_eop_d1_p2[m] <= 1'b0;
            avst_sop_latch_p2[m] <= avst_sop_latch_p2[m];
         end         
      end
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p3) 
      begin
         if (~i_tx_reset_n_p3) begin
            avst_eop_d1_p3[m] <= 1'b0;
            avst_sop_latch_p3[m] <= 1'b1;
         end
         else if (axist_tx_tready_delayed[3] && i_axist_tx_tvalid[3] && axist_tx_tlast_segment_p3[m]) begin
            avst_eop_d1_p3[m] <= 1'b1 ;
            avst_sop_latch_p3[m] <= 1'b1 ;
         end
         else if (axist_tx_tready_delayed[3] && i_axist_tx_tvalid[3]) begin
            avst_eop_d1_p3[m] <= 1'b0 ;
            avst_sop_latch_p3[m] <= 1'b0 ;
         end         
         else begin
            avst_eop_d1_p3[m] <= 1'b0;
            avst_sop_latch_p3[m] <= avst_sop_latch_p3[m];
         end         
      end
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
      begin
         if (~i_tx_reset_n_p0) begin
            avst_eop_d2_p0[m] <= 1'b0;
         end
         else begin
            avst_eop_d2_p0[m] <= avst_eop_d1_p0[m];
         end
      end    

      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1) 
      begin
         if (~i_tx_reset_n_p1) begin
            avst_eop_d2_p1[m] <= 1'b0;
         end
         else begin
            avst_eop_d2_p1[m] <= avst_eop_d1_p1[m];
         end
      end 

      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p2) 
      begin
         if (~i_tx_reset_n_p2) begin
            avst_eop_d2_p2[m] <= 1'b0;
         end
         else begin
            avst_eop_d2_p2[m] <= avst_eop_d1_p2[m];
         end
      end 

      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p3) 
      begin
         if (~i_tx_reset_n_p3) begin
            avst_eop_d2_p3[m] <= 1'b0;
         end
         else begin
            avst_eop_d2_p3[m] <= avst_eop_d1_p3[m];
         end
      end     
   
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
      begin
         if (~i_tx_reset_n_p0) 
            avst_sop_d1_p0[m] <= 1'b0;
         else if (axist_tx_tready_delayed[0] && i_axist_tx_tvalid[0] && axist_tx_tkeep_segment_p0[8*(m+1)-1:8*m] == 8'hff) begin
            if (active_segments == NUM_SEG)
            begin
               if ((m==0) && ((avst_sop_latch_p0[NUM_SEG-1] && axist_tx_tready_delayed[0]) || (axist_tx_tready_delayed_d1[0] && 
                    avst_tx_valid_d1_p0 && (axist_tx_tlast_segment_p0_d1[NUM_SEG-1] || (axist_tx_tkeep_segment_p0_d1[(8*NUM_SEG)-1:8*(NUM_SEG-1)] == 8'b0)))))   
                  avst_sop_d1_p0[m] <= 1'b1;
               else if ((m!=0) && (axist_tx_tlast_segment_p0[m-1] || (axist_tx_tkeep_segment_p0[8*m-1:8*(m-1)] == 8'b0)))
                  avst_sop_d1_p0[m] <= 1'b1;
               else 
                  avst_sop_d1_p0[m] <= 1'b0; 
            end               
            else if (active_segments == NUM_SEG/2)
            begin
               if ((m==0) && ((avst_sop_latch_p0[(NUM_SEG/2)-1] && axist_tx_tready_delayed[0]) || (axist_tx_tready_delayed_d1[0] && 
                    avst_tx_valid_d1_p0 && (axist_tx_tlast_segment_p0_d1[(NUM_SEG/2)-1] || (axist_tx_tkeep_segment_p0_d1[(8*(NUM_SEG/2))-1:8*((NUM_SEG/2)-1)] == 8'b0)))))   
                  avst_sop_d1_p0[m] <= 1'b1;
               else if (((m!=0) && (m<active_segments)) && (axist_tx_tlast_segment_p0[m-1] || (axist_tx_tkeep_segment_p0[8*m-1:8*(m-1)] == 8'b0)))
                  avst_sop_d1_p0[m] <= 1'b1;
               else 
                  avst_sop_d1_p0[m] <= 1'b0; 
            end             
            else if (active_segments == NUM_SEG/4)
            begin         
               if ((m==0) && ((avst_sop_latch_p0[(NUM_SEG/4)-1] && axist_tx_tready_delayed[0]) || (axist_tx_tready_delayed_d1[0] && 
                    avst_tx_valid_d1_p0 && (axist_tx_tlast_segment_p0_d1[(NUM_SEG/4)-1] || (axist_tx_tkeep_segment_p0_d1[(8*(NUM_SEG/4))-1:8*((NUM_SEG/4)-1)] == 8'b0)))))   
                  avst_sop_d1_p0[m] <= 1'b1;
               else if (((m!=0) && (m<active_segments)) && (axist_tx_tlast_segment_p0[m-1] || (axist_tx_tkeep_segment_p0[8*m-1:8*(m-1)] == 8'b0)))
                  avst_sop_d1_p0[m] <= 1'b1;
               else 
                  avst_sop_d1_p0[m] <= 1'b0; 
            end             
            else
               avst_sop_d1_p0[m] <= 1'b0;     
         end
         else
            avst_sop_d1_p0[m] <= 1'b0;     
      end     
   
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1) 
      begin
         if (~i_tx_reset_n_p1) 
            avst_sop_d1_p1[m] <= 1'b0;
         else if (axist_tx_tready_delayed[1] && i_axist_tx_tvalid[1] && axist_tx_tkeep_segment_p1[8*(m+1)-1:8*m] == 8'hff) begin
            if (active_segments == NUM_SEG)
            begin
               if ((m==0) && ((avst_sop_latch_p1[NUM_SEG-1] && axist_tx_tready_delayed[1]) || (axist_tx_tready_delayed_d1[1] && 
                    avst_tx_valid_d1_p1 && (axist_tx_tlast_segment_p1_d1[NUM_SEG-1] || (axist_tx_tkeep_segment_p1_d1[(8*NUM_SEG)-1:8*(NUM_SEG-1)] == 8'b0)))))   
                  avst_sop_d1_p1[m] <= 1'b1;
               else if ((m!=0) && (axist_tx_tlast_segment_p1[m-1] || (axist_tx_tkeep_segment_p1[8*m-1:8*(m-1)] == 8'b0)))
                  avst_sop_d1_p1[m] <= 1'b1;
               else 
                  avst_sop_d1_p1[m] <= 1'b0; 
            end
            else if (active_segments == NUM_SEG/2)
            begin
               if ((m==0) && ((avst_sop_latch_p1[(NUM_SEG/2)-1] && axist_tx_tready_delayed[1]) || (axist_tx_tready_delayed_d1[1] && 
                    avst_tx_valid_d1_p1 && (axist_tx_tlast_segment_p1_d1[(NUM_SEG/2)-1] || (axist_tx_tkeep_segment_p1_d1[(8*(NUM_SEG/2))-1:8*((NUM_SEG/2)-1)] == 8'b0)))))   
                  avst_sop_d1_p1[m] <= 1'b1;
               else if (((m!=0) && (m<active_segments)) && (axist_tx_tlast_segment_p1[m-1] || (axist_tx_tkeep_segment_p1[8*m-1:8*(m-1)] == 8'b0)))
                  avst_sop_d1_p1[m] <= 1'b1;
               else 
                  avst_sop_d1_p1[m] <= 1'b0;            
            end
            else if (active_segments == NUM_SEG/4)
            begin           
               if ((m==0) && ((avst_sop_latch_p1[(NUM_SEG/4)-1] && axist_tx_tready_delayed[1]) || (axist_tx_tready_delayed_d1[1] && 
                    avst_tx_valid_d1_p1 && (axist_tx_tlast_segment_p1_d1[(NUM_SEG/4)-1] || (axist_tx_tkeep_segment_p1_d1[(8*(NUM_SEG/4))-1:8*((NUM_SEG/4)-1)] == 8'b0)))))   
                  avst_sop_d1_p1[m] <= 1'b1;
               else if (((m!=0) && (m<active_segments)) && (axist_tx_tlast_segment_p1[m-1] || (axist_tx_tkeep_segment_p1[8*m-1:8*(m-1)] == 8'b0)))
                  avst_sop_d1_p1[m] <= 1'b1;
               else 
                  avst_sop_d1_p1[m] <= 1'b0;            
            end            
            else
               avst_sop_d1_p1[m] <= 1'b0;              
         end
         else
            avst_sop_d1_p1[m] <= 1'b0;     
      end     
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p2) 
      begin
         if (~i_tx_reset_n_p2) 
            avst_sop_d1_p2[m] <= 1'b0;
         else if (axist_tx_tready_delayed[2] && i_axist_tx_tvalid[2] && axist_tx_tkeep_segment_p2[8*(m+1)-1:8*m] == 8'hff) begin
            if (active_segments == NUM_SEG)
            begin        
               if ((m==0) && ((avst_sop_latch_p2[NUM_SEG-1] && axist_tx_tready_delayed[2]) || (axist_tx_tready_delayed_d1[2] && 
                    avst_tx_valid_d1_p2 && (axist_tx_tlast_segment_p2_d1[NUM_SEG-1] || (axist_tx_tkeep_segment_p2_d1[(8*NUM_SEG)-1:8*(NUM_SEG-1)] == 8'b0)))))   
                  avst_sop_d1_p2[m] <= 1'b1;
               else if ((m!=0) && (axist_tx_tlast_segment_p2[m-1] || (axist_tx_tkeep_segment_p2[8*m-1:8*(m-1)] == 8'b0)))
                  avst_sop_d1_p2[m] <= 1'b1;
               else 
                  avst_sop_d1_p2[m] <= 1'b0; 
            end
            else if (active_segments == NUM_SEG/2)
            begin           
               if ((m==0) && ((avst_sop_latch_p2[(NUM_SEG/2)-1] && axist_tx_tready_delayed[2]) || (axist_tx_tready_delayed_d1[2] && 
                    avst_tx_valid_d1_p2 && (axist_tx_tlast_segment_p2_d1[(NUM_SEG/2)-1] || (axist_tx_tkeep_segment_p2_d1[(8*(NUM_SEG/2))-1:8*((NUM_SEG/2)-1)] == 8'b0)))))   
                  avst_sop_d1_p2[m] <= 1'b1;
               else if (((m!=0) && (m<active_segments)) && (axist_tx_tlast_segment_p2[m-1] || (axist_tx_tkeep_segment_p2[8*m-1:8*(m-1)] == 8'b0)))
                  avst_sop_d1_p2[m] <= 1'b1;
               else 
                  avst_sop_d1_p2[m] <= 1'b0;            
            end
            else if (active_segments == NUM_SEG/4)
            begin        
               if ((m==0) && ((avst_sop_latch_p2[(NUM_SEG/4)-1] && axist_tx_tready_delayed[2]) || (axist_tx_tready_delayed_d1[2] && 
                    avst_tx_valid_d1_p2 && (axist_tx_tlast_segment_p2_d1[(NUM_SEG/4)-1] || (axist_tx_tkeep_segment_p2_d1[(8*(NUM_SEG/4))-1:8*((NUM_SEG/4)-1)] == 8'b0)))))   
                  avst_sop_d1_p2[m] <= 1'b1;
               else if (((m!=0) && (m<active_segments)) && (axist_tx_tlast_segment_p2[m-1] || (axist_tx_tkeep_segment_p2[8*m-1:8*(m-1)] == 8'b0)))
                  avst_sop_d1_p2[m] <= 1'b1;
               else 
                  avst_sop_d1_p2[m] <= 1'b0;            
            end
            else
               avst_sop_d1_p2[m] <= 1'b0;  
         end               
         else
            avst_sop_d1_p2[m] <= 1'b0;     
      end
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p3) 
      begin
         if (~i_tx_reset_n_p3) 
            avst_sop_d1_p3[m] <= 1'b0;
         else if (axist_tx_tready_delayed[3] && i_axist_tx_tvalid[3] && axist_tx_tkeep_segment_p3[8*(m+1)-1:8*m] == 8'hff) begin
            if (active_segments == NUM_SEG)
            begin                
               if ((m==0) && ((avst_sop_latch_p3[NUM_SEG-1] && axist_tx_tready_delayed[3]) || (axist_tx_tready_delayed_d1[3] && 
                    avst_tx_valid_d1_p3 && (axist_tx_tlast_segment_p3_d1[NUM_SEG-1] || (axist_tx_tkeep_segment_p3_d1[(8*NUM_SEG)-1:8*(NUM_SEG-1)] == 8'b0)))))   
                  avst_sop_d1_p3[m] <= 1'b1;
               else if ((m!=0) && (axist_tx_tlast_segment_p3[m-1] || (axist_tx_tkeep_segment_p3[8*m-1:8*(m-1)] == 8'b0)))
                  avst_sop_d1_p3[m] <= 1'b1;
               else 
                  avst_sop_d1_p3[m] <= 1'b0; 
            end
            else if (active_segments == NUM_SEG/2)
            begin    
               if ((m==0) && ((avst_sop_latch_p3[(NUM_SEG/2)-1] && axist_tx_tready_delayed[3]) || (axist_tx_tready_delayed_d1[3] && 
                    avst_tx_valid_d1_p3 && (axist_tx_tlast_segment_p3_d1[(NUM_SEG/2)-1] || (axist_tx_tkeep_segment_p3_d1[(8*(NUM_SEG/2))-1:8*((NUM_SEG/2)-1)] == 8'b0)))))   
                  avst_sop_d1_p3[m] <= 1'b1;
               else if (((m!=0) && (m<active_segments)) && (axist_tx_tlast_segment_p3[m-1] || (axist_tx_tkeep_segment_p3[8*m-1:8*(m-1)] == 8'b0)))
                  avst_sop_d1_p3[m] <= 1'b1;
               else 
                  avst_sop_d1_p3[m] <= 1'b0; 
            end
            else if (active_segments == NUM_SEG/4)
            begin        
               if ((m==0) && ((avst_sop_latch_p3[(NUM_SEG/4)-1] && axist_tx_tready_delayed[3]) || (axist_tx_tready_delayed_d1[3] && 
                    avst_tx_valid_d1_p3 && (axist_tx_tlast_segment_p3_d1[(NUM_SEG/4)-1] || (axist_tx_tkeep_segment_p3_d1[(8*(NUM_SEG/4))-1:8*((NUM_SEG/4)-1)] == 8'b0)))))   
                  avst_sop_d1_p3[m] <= 1'b1;
               else if (((m!=0) && (m<active_segments)) && (axist_tx_tlast_segment_p3[m-1] || (axist_tx_tkeep_segment_p3[8*m-1:8*(m-1)] == 8'b0)))
                  avst_sop_d1_p3[m] <= 1'b1;
               else 
                  avst_sop_d1_p3[m] <= 1'b0; 
            end
            else
               avst_sop_d1_p3[m] <= 1'b0;  
         end
         else
            avst_sop_d1_p3[m] <= 1'b0;     
      end
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
      begin
         if (~i_tx_reset_n_p0)
            avst_tx_inframe_d2_p0[m] <= 1'b0;
         else if (avst_sop_d1_p0[m])
            avst_tx_inframe_d2_p0[m] <= 1'b1;
         else if (avst_eop_d1_p0[m])
            avst_tx_inframe_d2_p0[m] <= 1'b0;
         else if (axist_tx_tready_delayed_d1[0] && avst_tx_valid_d1_p0 && (|axist_tx_tkeep_segment_p0_d1[8*(m+1)-1:8*m]))
            avst_tx_inframe_d2_p0[m] <= 1'b1;
         else 
            avst_tx_inframe_d2_p0[m] <= 1'b0;
      end 
   
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1) 
      begin
         if (~i_tx_reset_n_p1)
            avst_tx_inframe_d2_p1[m] <= 1'b0;
         else if (avst_sop_d1_p1[m])
            avst_tx_inframe_d2_p1[m] <= 1'b1;
         else if (avst_eop_d1_p1[m])
            avst_tx_inframe_d2_p1[m] <= 1'b0;
         else if (axist_tx_tready_delayed_d1[1] && avst_tx_valid_d1_p1 && (|axist_tx_tkeep_segment_p1_d1[8*(m+1)-1:8*m]))
            avst_tx_inframe_d2_p1[m] <= 1'b1;
         else 
            avst_tx_inframe_d2_p1[m] <= 1'b0;
      end 
   
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p2) 
      begin
         if (~i_tx_reset_n_p2)
            avst_tx_inframe_d2_p2[m] <= 1'b0;
         else if (avst_sop_d1_p2[m])
            avst_tx_inframe_d2_p2[m] <= 1'b1;
         else if (avst_eop_d1_p2[m])
            avst_tx_inframe_d2_p2[m] <= 1'b0;
         else if (axist_tx_tready_delayed_d1[2] && avst_tx_valid_d1_p2 && (|axist_tx_tkeep_segment_p2_d1[8*(m+1)-1:8*m]))
            avst_tx_inframe_d2_p2[m] <= 1'b1;
         else 
            avst_tx_inframe_d2_p2[m] <= 1'b0;
      end         
   
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p3) 
      begin
         if (~i_tx_reset_n_p3)
            avst_tx_inframe_d2_p3[m] <= 1'b0;
         else if (avst_sop_d1_p3[m])
            avst_tx_inframe_d2_p3[m] <= 1'b1;
         else if (avst_eop_d1_p3[m])
            avst_tx_inframe_d2_p3[m] <= 1'b0;
         else if (axist_tx_tready_delayed_d1[3] && avst_tx_valid_d1_p3 && (|axist_tx_tkeep_segment_p3_d1[8*(m+1)-1:8*m]))
            avst_tx_inframe_d2_p3[m] <= 1'b1;
         else 
            avst_tx_inframe_d2_p3[m] <= 1'b0;
      end 
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
      begin
         if (~i_tx_reset_n_p0)
            avst_tx_data_valid_p0[m] <= 1'b0;
         else
            avst_tx_data_valid_p0[m] <=  (avst_sop_d1_p0[m])? 1'b1 : (|avst_eop_d2_p0)? 1'b0 : 
                                         (axist_tx_tready_delayed_d1[0] && avst_tx_valid_d1_p0 && (|axist_tx_tkeep_segment_p0_d1[8*(m+1)-1:8*m]))? 1'b1: avst_tx_data_valid_p0[m];
      end
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1) 
      begin
         if (~i_tx_reset_n_p1)
            avst_tx_data_valid_p1[m] <= 1'b0;
         else
            avst_tx_data_valid_p1[m] <= (avst_sop_d1_p1[m])? 1'b1 : (|avst_eop_d2_p1)? 1'b0 : 
                                        (axist_tx_tready_delayed_d1[1] && avst_tx_valid_d1_p1 && (|axist_tx_tkeep_segment_p1_d1[8*(m+1)-1:8*m]))? 1'b1 : avst_tx_data_valid_p1[m];
      end   

      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p2) 
      begin
         if (~i_tx_reset_n_p2)
            avst_tx_data_valid_p2[m] <= 1'b0;
         else
            avst_tx_data_valid_p2[m] <= (avst_sop_d1_p2[m])? 1'b1 : (|avst_eop_d2_p2)? 1'b0 : 
                                        (axist_tx_tready_delayed_d1[2] && avst_tx_valid_d1_p2 && (|axist_tx_tkeep_segment_p2_d1[8*(m+1)-1:8*m]))? 1'b1: avst_tx_data_valid_p2[m];
      end       

      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p3) 
      begin
         if (~i_tx_reset_n_p3)
            avst_tx_data_valid_p3[m] <= 1'b0;
         else
            avst_tx_data_valid_p3[m] <= (avst_sop_d1_p3[m])? 1'b1 : (|avst_eop_d2_p3)? 1'b0 :
                                        (axist_tx_tready_delayed_d1[3] && avst_tx_valid_d1_p3 && (|axist_tx_tkeep_segment_p3_d1[8*(m+1)-1:8*m]))? 1'b1: avst_tx_data_valid_p3[m];
      end              
   
      keep2empty #(
      .EMPTY_BITS  (3),
      .NO_OF_BYTES (8)
      )keep2empty_inst(
         .clk(i_tx_clk_p0),
         // .rst_n(i_tx_reset_n),
         .keep_bits_in({{56{1'b0}},i_axist_tx_tkeep_segment[(m+1)*8-1:8*m]}), 
         .empty_bits_out_d1(keep2empty_d1[(m+1)*EMPTY_BITS-1:EMPTY_BITS*m])          
      );
      
      always @(posedge i_tx_clk_p0) begin //* muxed reset based on i_active_port    
         avst_tx_eop_empty_d1[(m+1)*EMPTY_BITS-1:EMPTY_BITS*m] <= keep2empty_d1[(m+1)*EMPTY_BITS-1:EMPTY_BITS*m];
      end       
      
      assign tx_parity_detect_d1[m]  = ^(axi_st_tx_seg_data[m]);
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) begin
         if (~i_tx_reset_n_p0)
            tx_parity_error_d2_p0[m] <= 1'b0;
         else if (avst_sop_d1_p0[m] && (tx_parity_detect_d1_p0[m] == mac_tx_pkt_seg_parity_d1_p0[m]))
            tx_parity_error_d2_p0[m] <= 1'b1;  //(tx_parity_detect_d1[m] == mac_tx_pkt_seg_parity_d1[m]) ? 1'b1 : 1'b0;           
         else if (|avst_eop_d2_p0)
            tx_parity_error_d2_p0[m] <= 1'b0;
         else if(avst_tx_valid_d1_p0 && axist_tx_tready_delayed_d1[0] && (tx_parity_detect_d1_p0[m] == mac_tx_pkt_seg_parity_d1_p0[m]))
            tx_parity_error_d2_p0[m] <= 1'b1;  
         else
            tx_parity_error_d2_p0[m] <= tx_parity_error_d2_p0[m];
      end 
   
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1) begin
         if (~i_tx_reset_n_p1)
            tx_parity_error_d2_p1[m] <= 1'b0;
         else if (avst_sop_d1_p1[m] && (tx_parity_detect_d1_p1[m] == mac_tx_pkt_seg_parity_d1_p1[m]))
            tx_parity_error_d2_p1[m] <= 1'b1;  //(tx_parity_detect_d1[m] == mac_tx_pkt_seg_parity_d1[m]) ? 1'b1 : 1'b0;           
         else if (|avst_eop_d2_p1)
            tx_parity_error_d2_p1[m] <= 1'b0;
         else if(avst_tx_valid_d1_p1 && axist_tx_tready_delayed_d1[1] && (tx_parity_detect_d1_p1[m] == mac_tx_pkt_seg_parity_d1_p1[m]))
            tx_parity_error_d2_p1[m] <= 1'b1;  
         else
            tx_parity_error_d2_p1[m] <= tx_parity_error_d2_p1[m];
      end 
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p2) begin
         if (~i_tx_reset_n_p2)
            tx_parity_error_d2_p2[m] <= 1'b0;
         else if (avst_sop_d1_p2[m] && (tx_parity_detect_d1_p2[m] == mac_tx_pkt_seg_parity_d1_p2[m]))
            tx_parity_error_d2_p2[m] <= 1'b1;  //(tx_parity_detect_d1[m] == mac_tx_pkt_seg_parity_d1[m]) ? 1'b1 : 1'b0;           
         else if (|avst_eop_d2_p2)
            tx_parity_error_d2_p2[m] <= 1'b0;
         else if(avst_tx_valid_d1_p2 && axist_tx_tready_delayed_d1[2] && (tx_parity_detect_d1_p2[m] == mac_tx_pkt_seg_parity_d1_p2[m]))
            tx_parity_error_d2_p2[m] <= 1'b1;  
         else
            tx_parity_error_d2_p2[m] <= tx_parity_error_d2_p2[m];
      end 
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p3) begin
         if (~i_tx_reset_n_p3)
            tx_parity_error_d2_p3[m] <= 1'b0;
         else if (avst_sop_d1_p3[m] && (tx_parity_detect_d1_p3[m] == mac_tx_pkt_seg_parity_d1_p3[m]))
            tx_parity_error_d2_p3[m] <= 1'b1;  //(tx_parity_detect_d1[m] == mac_tx_pkt_seg_parity_d1[m]) ? 1'b1 : 1'b0;           
         else if (|avst_eop_d2_p3)
            tx_parity_error_d2_p3[m] <= 1'b0;
         else if(avst_tx_valid_d1_p3 && axist_tx_tready_delayed_d1[3] && (tx_parity_detect_d1_p3[m] == mac_tx_pkt_seg_parity_d1_p3[m]))
            tx_parity_error_d2_p3[m] <= 1'b1;  
         else
            tx_parity_error_d2_p3[m] <= tx_parity_error_d2_p3[m];
      end 
      
      // assign  avst_tx_eop_empty_d1[(m+1)*EMPTY_BITS-1:EMPTY_BITS*m] = keep2empty_d1[(m+1)*EMPTY_BITS-1:EMPTY_BITS*m];
      assign  axi_st_tx_seg_data[m] = i_axist_tx_tdata[64*(m+1)-1:64*m];
      
      assign avst_tx_user_client_p0[(2*m)+1] = avst_tx_user_client_d2_p0[(2*m)+1];  //1,3, 5,7
      assign avst_tx_user_client_p1[(2*m)+1] = avst_tx_user_client_d2_p1[(2*m)+1];  //1,3, 5,7
      assign avst_tx_user_client_p2[(2*m)+1] = avst_tx_user_client_d2_p2[(2*m)+1];  //1,3, 5,7
      assign avst_tx_user_client_p3[(2*m)+1] = avst_tx_user_client_d2_p3[(2*m)+1];  //1,3, 5,7
      
      assign avst_tx_user_client_p0[2*m]     = avst_eop_d2_p0[m] ? (avst_tx_user_client_d2_p0[2*m] | par_err_detected_p0): avst_tx_user_client_d2_p0[2*m]; //0,2,4
      assign avst_tx_user_client_p1[2*m]     = avst_eop_d2_p1[m] ? (avst_tx_user_client_d2_p1[2*m] | par_err_detected_p1): avst_tx_user_client_d2_p1[2*m]; //0,2,4
      assign avst_tx_user_client_p2[2*m]     = avst_eop_d2_p2[m] ? (avst_tx_user_client_d2_p2[2*m] | par_err_detected_p2): avst_tx_user_client_d2_p2[2*m]; //0,2,4
      assign avst_tx_user_client_p3[2*m]     = avst_eop_d2_p3[m] ? (avst_tx_user_client_d2_p3[2*m] | par_err_detected_p3): avst_tx_user_client_d2_p3[2*m]; //0,2,4    

end
end

else begin:SOP_ALIGNED
genvar n,p,q,r,s,t,u,v;

if (NUM_MAX_PORTS == 1) begin: TX_SOPA_TKEEP_1P //includes NoN DR and PPT

      keep2empty #(
         .EMPTY_BITS  (EMPTY_BITS), //EMPTY_BITS = 5 for PPT from wrapper
         .NO_OF_BYTES (8)  
         )keep2empty_inst(
            .clk              (i_tx_clk_p0), 
            // .rst_n            (i_tx_reset_n),
            .keep_bits_in     ({{(64-NO_OF_BYTES){1'b0}},i_axist_tx_tkeep}), 
            .empty_bits_out_d1(keep2empty_sopa_d1_p0)          
         );
end

else if (NUM_MAX_PORTS == 2) begin: TX_SOPA_TKEEP_2P

      keep2empty #(
         .EMPTY_BITS  (EMPTY_BITS), 
         .NO_OF_BYTES (8)  
         )keep2empty_inst_p0(
            .clk              (i_tx_clk_p0), 
            // .rst_n            (i_tx_reset_n),
            .keep_bits_in     ((i_port_data_width == 3'd0)? {{56{1'b0}},i_axist_tx_tkeep[7:0]} : (i_port_data_width == 3'd1)? {{48{1'b0}},i_axist_tx_tkeep[15:0]} : i_axist_tx_tkeep), 
            .empty_bits_out_d1(keep2empty_sopa_d1_p0)          
         );
         
      keep2empty #(
         .EMPTY_BITS  (EMPTY_BITS),
         .NO_OF_BYTES (8)  
         )keep2empty_inst_p1(
            .clk              (i_tx_clk_p1), 
            // .rst_n            (i_tx_reset_n),
            .keep_bits_in     ((i_port_data_width == 3'd0)? {{56{1'b0}},i_axist_tx_tkeep[15:8]} : (i_port_data_width == 3'd1)? {{48{1'b0}},i_axist_tx_tkeep[31:16]} : 64'd0), 
            .empty_bits_out_d1(keep2empty_sopa_d1_p1)          
         );      

end

else begin: TX_SOPA_TKEEP_4P

      keep2empty #(
         .EMPTY_BITS  (EMPTY_BITS), 
         .NO_OF_BYTES (8)  
         )keep2empty_inst_p0(
            .clk              (i_tx_clk_p0), 
            // .rst_n            (i_tx_reset_n),
            .keep_bits_in     ((i_port_data_width == 3'd0)? {{56{1'b0}},i_axist_tx_tkeep[7:0]} : (i_port_data_width == 3'd1)? {{48{1'b0}},i_axist_tx_tkeep[15:0]} : i_axist_tx_tkeep),  
            .empty_bits_out_d1(keep2empty_sopa_d1_p0)          
         );
         
      keep2empty #(
         .EMPTY_BITS  (EMPTY_BITS), 
         .NO_OF_BYTES (8)  
         )keep2empty_inst_p1(
            .clk              (i_tx_clk_p1), 
            // .rst_n            (i_tx_reset_n),
            .keep_bits_in     ((i_port_data_width == 3'd0)? {{56{1'b0}},i_axist_tx_tkeep[15:8]} : 64'd0), 
            .empty_bits_out_d1(keep2empty_sopa_d1_p1)          
         );     
         
      keep2empty #(
         .EMPTY_BITS  (EMPTY_BITS), 
         .NO_OF_BYTES (8)  
         )keep2empty_inst_p2(
            .clk              (i_tx_clk_p2), 
            // .rst_n            (i_tx_reset_n),
            .keep_bits_in     ((i_port_data_width == 3'd0)? {{56{1'b0}},i_axist_tx_tkeep[23:16]} : (i_port_data_width == 3'd1)? {{48{1'b0}},i_axist_tx_tkeep[31:16]} : 64'd0), 
            .empty_bits_out_d1(keep2empty_sopa_d1_p2)          
         );     

      keep2empty #(
         .EMPTY_BITS  (EMPTY_BITS), 
         .NO_OF_BYTES (8)  
         )keep2empty_inst_p3(
            .clk              (i_tx_clk_p3), 
            // .rst_n            (i_tx_reset_n),
            .keep_bits_in     ((i_port_data_width == 3'd0)? {{56{1'b0}},i_axist_tx_tkeep[31:24]} : 64'd0), 
            .empty_bits_out_d1(keep2empty_sopa_d1_p3)          
         );              

end 

    // assign axi_st_tx_sop_data = i_axist_tx_tdata;
   //** split avst_tx_user_client_d1 port wise
   if (NUM_MAX_PORTS == 1) begin: TX_SOPA_1P_TUSER
   
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
      begin
         if (~i_tx_reset_n_p0) begin
            avst_eop_d1    <= 1'b0;
            avst_sop_latch <= 1'b1;
         end
         else if (axist_tx_tready_delayed && i_axist_tx_tvalid && i_axist_tx_tlast) begin
            avst_eop_d1    <= 1'b1;
            avst_sop_latch <= 1'b1;
         end
         else if (axist_tx_tready_delayed && i_axist_tx_tvalid)
         begin
            avst_eop_d1    <= 1'b0;
            avst_sop_latch <= 1'b0;
         end
         else begin
            avst_eop_d1    <= 1'b0;
            avst_sop_latch <= avst_sop_latch;
         end         
      end
       
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
      begin
         if (~i_tx_reset_n_p0) 
            avst_sop_d1 <= 1'b0;
         else if (avst_sop_latch && axist_tx_tready_delayed && i_axist_tx_tvalid)
            avst_sop_d1 <= 1'b1;
         else 
            avst_sop_d1 <= 1'b0;        
      end
              
      assign  avst_sop_d0 = (avst_sop_latch && axist_tx_tready_delayed && i_axist_tx_tvalid)? 1'b1: 1'b0;
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) begin
          if (~i_tx_reset_n_p0)
              avst_tx_parity_error_d1 <= 1'b0;
          else if (avst_sop_d0)
              avst_tx_parity_error_d1 <= (tx_avst_parity_detect_d1 == i_axist_tx_pkt_seg_parity) ? 1'b1 : 1'b0; 
          else if (avst_eop_d1)
              avst_tx_parity_error_d1 <= 1'b0;
          else if(i_axist_tx_tvalid && axist_tx_tready_delayed && (tx_avst_parity_detect_d1 == i_axist_tx_pkt_seg_parity))
              avst_tx_parity_error_d1 <= 1'b1; 
          else 
              avst_tx_parity_error_d1 <= avst_tx_parity_error_d1;
      end     
      
      assign o_axist_tx_parity_error = PKT_SEG_PARITY_EN ? avst_tx_parity_error_d1 : 1'b0; //|avst_tx_parity_error_d1;   
      
      assign avst_tx_user_client[1]  = avst_tx_user_client_d1_p0[1];  
      assign avst_tx_user_client[0]  = avst_tx_user_client_d1_p0[0] | avst_tx_parity_error_d1[0]; 
      assign avst_tx_user_sp         = {avst_tx_user_client,avst_tx_user_d1_p0[1*TUSER-2*NUM_SEG-1:0]};
    
   end    
   
   else if (NUM_MAX_PORTS == 2) begin: TX_SOPA_2P_TUSER
   
   always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
   begin
      if (~i_tx_reset_n_p0) begin
         avst_eop_d1[0]    <= 1'b0;
         avst_sop_latch[0] <= 1'b1;
      end
      else if (axist_tx_tready_delayed[0] && i_axist_tx_tvalid[0] && i_axist_tx_tlast[0]) begin
         avst_eop_d1[0]    <= 1'b1;
         avst_sop_latch[0] <= 1'b1;
      end
      else if (axist_tx_tready_delayed[0] && i_axist_tx_tvalid[0])
      begin
         avst_eop_d1[0]    <= 1'b0;
         avst_sop_latch[0] <= 1'b0;
      end
      else begin
         avst_eop_d1[0]    <= 1'b0;
         avst_sop_latch[0] <= avst_sop_latch[0];
      end         
    end
    
   always @(posedge i_tx_clk_p1 or negedge i_tx_reset_n_p1) 
   begin
      if (~i_tx_reset_n_p1) begin
         avst_eop_d1[1]    <= 1'b0;
         avst_sop_latch[1] <= 1'b1;
      end
      else if (axist_tx_tready_delayed[1] && i_axist_tx_tvalid[1] && i_axist_tx_tlast[1]) begin
         avst_eop_d1[1]    <= 1'b1;
         avst_sop_latch[1] <= 1'b1;
      end
      else if (axist_tx_tready_delayed[1] && i_axist_tx_tvalid[1])
      begin
         avst_eop_d1[1]    <= 1'b0;
         avst_sop_latch[1] <= 1'b0;
      end
      else begin
         avst_eop_d1[1]    <= 1'b0;
         avst_sop_latch[1] <= avst_sop_latch[1];
      end         
    end 
    
    always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
    begin
       if (~i_tx_reset_n_p0) 
          avst_sop_d1[0] <= 1'b0;
       else if (avst_sop_latch[0] && axist_tx_tready_delayed[0] && i_axist_tx_tvalid[0])
          avst_sop_d1[0] <= 1'b1;
       else 
          avst_sop_d1[0] <= 1'b0;        
    end
    
    always @(posedge i_tx_clk_p1 or negedge i_tx_reset_n_p1) 
    begin
       if (~i_tx_reset_n_p1) 
          avst_sop_d1[1] <= 1'b0;
       else if (avst_sop_latch[1] && axist_tx_tready_delayed[1] && i_axist_tx_tvalid[1])
          avst_sop_d1[1] <= 1'b1;
       else 
          avst_sop_d1[1] <= 1'b0;        
    end 
            
    assign  avst_sop_d0[0] = (avst_sop_latch[0] && axist_tx_tready_delayed[0] && i_axist_tx_tvalid[0])? 1'b1: 1'b0;
    assign  avst_sop_d0[1] = (avst_sop_latch[1] && axist_tx_tready_delayed[1] && i_axist_tx_tvalid[1])? 1'b1: 1'b0;
    
    always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) begin
        if (~i_tx_reset_n_p0)
            avst_tx_parity_error_d1[0] <= 1'b0;
        else if (avst_sop_d0[0])
            avst_tx_parity_error_d1[0] <= (tx_avst_parity_detect_d1[0] == i_axist_tx_pkt_seg_parity[0]) ? 1'b1 : 1'b0; 
        else if (avst_eop_d1[0])
            avst_tx_parity_error_d1[0] <= 1'b0;     
        else if(i_axist_tx_tvalid[0] && axist_tx_tready_delayed[0] && (tx_avst_parity_detect_d1[0] == i_axist_tx_pkt_seg_parity[0]))
            avst_tx_parity_error_d1[0] <= 1'b1; 
        else 
            avst_tx_parity_error_d1[0] <= avst_tx_parity_error_d1[0];
    end     
    
    always @(posedge i_tx_clk_p1 or negedge i_tx_reset_n_p1) begin
        if (~i_tx_reset_n_p1)
            avst_tx_parity_error_d1[1] <= 1'b0;
        else if (avst_sop_d0[1])
            avst_tx_parity_error_d1[1] <= (tx_avst_parity_detect_d1[1] == i_axist_tx_pkt_seg_parity[1]) ? 1'b1 : 1'b0; 
        else if (avst_eop_d1[1])
            avst_tx_parity_error_d1[1] <= 1'b0;
        else if(i_axist_tx_tvalid[1] && axist_tx_tready_delayed[1] && (tx_avst_parity_detect_d1[1] == i_axist_tx_pkt_seg_parity[1]))
            avst_tx_parity_error_d1[1] <= 1'b1; 
        else 
            avst_tx_parity_error_d1[1] <= avst_tx_parity_error_d1[1];
    end         

    assign o_axist_tx_parity_error[0] = PKT_SEG_PARITY_EN ? avst_tx_parity_error_d1[0] : 1'b0; //|avst_tx_parity_error_d1;   
    assign o_axist_tx_parity_error[1] = PKT_SEG_PARITY_EN ? avst_tx_parity_error_d1[1] : 1'b0; //|avst_tx_parity_error_d1;   

    assign avst_tx_user_client[1]  = avst_tx_user_client_d1_p0[1];  
    assign avst_tx_user_client[0]  = avst_tx_user_client_d1_p0[0] | avst_tx_parity_error_d1[0];  
    assign avst_tx_user_client[3]  = avst_tx_user_client_d1_p1[1];  
    assign avst_tx_user_client[2]  = avst_tx_user_client_d1_p1[0] | avst_tx_parity_error_d1[1];
    assign avst_tx_user_sp         = {avst_tx_user_client[3:2],avst_tx_user_d1_p1[TUSER-(2*NUM_SEG)-1:0],
                                      avst_tx_user_client[1:0],avst_tx_user_d1_p0[TUSER-(2*NUM_SEG)-1:0]};
    end                            
    
    else  begin: TX_SOPA_4P_TUSER

   always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
   begin
      if (~i_tx_reset_n_p0) begin
         avst_eop_d1[0]    <= 1'b0;
         avst_sop_latch[0] <= 1'b1;
      end
      else if (axist_tx_tready_delayed[0] && i_axist_tx_tvalid[0] && i_axist_tx_tlast[0]) begin
         avst_eop_d1[0]    <= 1'b1;
         avst_sop_latch[0] <= 1'b1;
      end
      else if (axist_tx_tready_delayed[0] && i_axist_tx_tvalid[0])
      begin
         avst_eop_d1[0]    <= 1'b0;
         avst_sop_latch[0] <= 1'b0;
      end
      else begin
         avst_eop_d1[0]    <= 1'b0;
         avst_sop_latch[0] <= avst_sop_latch[0];
      end         
    end
    
   always @(posedge i_tx_clk_p1 or negedge i_tx_reset_n_p1) 
   begin
      if (~i_tx_reset_n_p1) begin
         avst_eop_d1[1]    <= 1'b0;
         avst_sop_latch[1] <= 1'b1;
      end
      else if (axist_tx_tready_delayed[1] && i_axist_tx_tvalid[1] && i_axist_tx_tlast[1]) begin
         avst_eop_d1[1]    <= 1'b1;
         avst_sop_latch[1] <= 1'b1;
      end
      else if (axist_tx_tready_delayed[1] && i_axist_tx_tvalid[1])
      begin
         avst_eop_d1[1]    <= 1'b0;
         avst_sop_latch[1] <= 1'b0;
      end
      else begin
         avst_eop_d1[1]    <= 1'b0;
         avst_sop_latch[1] <= avst_sop_latch[1];
      end         
    end 
    
   always @(posedge i_tx_clk_p2 or negedge i_tx_reset_n_p2) 
   begin
      if (~i_tx_reset_n_p2) begin
         avst_eop_d1[2]    <= 1'b0;
         avst_sop_latch[2] <= 1'b1;
      end
      else if (axist_tx_tready_delayed[2] && i_axist_tx_tvalid[2] && i_axist_tx_tlast[2]) begin
         avst_eop_d1[2]    <= 1'b1;
         avst_sop_latch[2] <= 1'b1;
      end
      else if (axist_tx_tready_delayed[2] && i_axist_tx_tvalid[2])
      begin
         avst_eop_d1[2]    <= 1'b0;
         avst_sop_latch[2] <= 1'b0;
      end
      else begin
         avst_eop_d1[2]    <= 1'b0;
         avst_sop_latch[2] <= avst_sop_latch[2];
      end         
    end     
    
   always @(posedge i_tx_clk_p3 or negedge i_tx_reset_n_p3) 
   begin
      if (~i_tx_reset_n_p3) begin
         avst_eop_d1[3]    <= 1'b0;
         avst_sop_latch[3] <= 1'b1;
      end
      else if (axist_tx_tready_delayed[3] && i_axist_tx_tvalid[3] && i_axist_tx_tlast[3]) begin
         avst_eop_d1[3]    <= 1'b1;
         avst_sop_latch[3] <= 1'b1;
      end
      else if (axist_tx_tready_delayed[3] && i_axist_tx_tvalid[3])
      begin
         avst_eop_d1[3]    <= 1'b0;
         avst_sop_latch[3] <= 1'b0;
      end
      else begin
         avst_eop_d1[3]    <= 1'b0;
         avst_sop_latch[3] <= avst_sop_latch[3];
      end         
    end     
    
    always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
    begin
       if (~i_tx_reset_n_p0) 
          avst_sop_d1[0] <= 1'b0;
       else if (avst_sop_latch[0] && axist_tx_tready_delayed[0] && i_axist_tx_tvalid[0])
          avst_sop_d1[0] <= 1'b1;
       else 
          avst_sop_d1[0] <= 1'b0;        
    end
    
    always @(posedge i_tx_clk_p1 or negedge i_tx_reset_n_p1) 
    begin
       if (~i_tx_reset_n_p1) 
          avst_sop_d1[1] <= 1'b0;
       else if (avst_sop_latch[1] && axist_tx_tready_delayed[1] && i_axist_tx_tvalid[1])
          avst_sop_d1[1] <= 1'b1;
       else 
          avst_sop_d1[1] <= 1'b0;        
    end 
    
    always @(posedge i_tx_clk_p2 or negedge i_tx_reset_n_p2) 
    begin
       if (~i_tx_reset_n_p2) 
          avst_sop_d1[2] <= 1'b0;
       else if (avst_sop_latch[2] && axist_tx_tready_delayed[2] && i_axist_tx_tvalid[2])
          avst_sop_d1[2] <= 1'b1;
       else 
          avst_sop_d1[2] <= 1'b0;        
    end 
    
    always @(posedge i_tx_clk_p3 or negedge i_tx_reset_n_p3) 
    begin
       if (~i_tx_reset_n_p3) 
          avst_sop_d1[3] <= 1'b0;
       else if (avst_sop_latch[3] && axist_tx_tready_delayed[3] && i_axist_tx_tvalid[3])
          avst_sop_d1[3] <= 1'b1;
       else 
          avst_sop_d1[3] <= 1'b0;        
    end     
            
    assign  avst_sop_d0[0] = (avst_sop_latch[0] && axist_tx_tready_delayed[0] && i_axist_tx_tvalid[0])? 1'b1: 1'b0;
    assign  avst_sop_d0[1] = (avst_sop_latch[1] && axist_tx_tready_delayed[1] && i_axist_tx_tvalid[1])? 1'b1: 1'b0;
    assign  avst_sop_d0[2] = (avst_sop_latch[2] && axist_tx_tready_delayed[2] && i_axist_tx_tvalid[2])? 1'b1: 1'b0;
    assign  avst_sop_d0[3] = (avst_sop_latch[3] && axist_tx_tready_delayed[3] && i_axist_tx_tvalid[3])? 1'b1: 1'b0;
    
    always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) begin
        if (~i_tx_reset_n_p0)
            avst_tx_parity_error_d1[0] <= 1'b0;
        else if (avst_sop_d0[0])
            avst_tx_parity_error_d1[0] <= (tx_avst_parity_detect_d1[0] == i_axist_tx_pkt_seg_parity[0]) ? 1'b1 : 1'b0; 
        else if (avst_eop_d1[0])
            avst_tx_parity_error_d1[0] <= 1'b0;
        else if(i_axist_tx_tvalid[0] && axist_tx_tready_delayed[0] && (tx_avst_parity_detect_d1[0] == i_axist_tx_pkt_seg_parity[0]))
            avst_tx_parity_error_d1[0] <= 1'b1; 
        else 
            avst_tx_parity_error_d1[0] <= avst_tx_parity_error_d1[0];
    end     
    
    always @(posedge i_tx_clk_p1 or negedge i_tx_reset_n_p1) begin
        if (~i_tx_reset_n_p1)
            avst_tx_parity_error_d1[1] <= 1'b0;
        else if (avst_sop_d0[1])
            avst_tx_parity_error_d1[1] <= (tx_avst_parity_detect_d1[1] == i_axist_tx_pkt_seg_parity[1]) ? 1'b1 : 1'b0; 
        else if (avst_eop_d1[1])
            avst_tx_parity_error_d1[1] <= 1'b0;
        else if(i_axist_tx_tvalid[1] && axist_tx_tready_delayed[1] && (tx_avst_parity_detect_d1[1] == i_axist_tx_pkt_seg_parity[1]))
            avst_tx_parity_error_d1[1] <= 1'b1; 
        else 
            avst_tx_parity_error_d1[1] <= avst_tx_parity_error_d1[1];
    end     
    
    always @(posedge i_tx_clk_p2 or negedge i_tx_reset_n_p2) begin
        if (~i_tx_reset_n_p2)
            avst_tx_parity_error_d1[2] <= 1'b0;
        else if (avst_sop_d0[2])
            avst_tx_parity_error_d1[2] <= (tx_avst_parity_detect_d1[2] == i_axist_tx_pkt_seg_parity[2]) ? 1'b1 : 1'b0; 
        else if (avst_eop_d1[2])
            avst_tx_parity_error_d1[2] <= 1'b0;     
        else if(i_axist_tx_tvalid[2] && axist_tx_tready_delayed[2] && (tx_avst_parity_detect_d1[2] == i_axist_tx_pkt_seg_parity[2]))
            avst_tx_parity_error_d1[2] <= 1'b1; 
        else 
            avst_tx_parity_error_d1[2] <= avst_tx_parity_error_d1[2];
    end     
    
    always @(posedge i_tx_clk_p3 or negedge i_tx_reset_n_p3) begin
        if (~i_tx_reset_n_p3)
            avst_tx_parity_error_d1[3] <= 1'b0;
        else if (avst_sop_d0[3])
            avst_tx_parity_error_d1[3] <= (tx_avst_parity_detect_d1[3] == i_axist_tx_pkt_seg_parity[3]) ? 1'b1 : 1'b0; 
        else if (avst_eop_d1[3])
            avst_tx_parity_error_d1[3] <= 1'b0;
        else if(i_axist_tx_tvalid[3] && axist_tx_tready_delayed[3] && (tx_avst_parity_detect_d1[3] == i_axist_tx_pkt_seg_parity[3]))
            avst_tx_parity_error_d1[3] <= 1'b1; 
        else 
            avst_tx_parity_error_d1[3] <= avst_tx_parity_error_d1[3];
    end     

    assign o_axist_tx_parity_error[0] = PKT_SEG_PARITY_EN ? avst_tx_parity_error_d1[0] : 1'b0; //|avst_tx_parity_error_d1;
    assign o_axist_tx_parity_error[1] = PKT_SEG_PARITY_EN ? avst_tx_parity_error_d1[1] : 1'b0; //|avst_tx_parity_error_d1;
    assign o_axist_tx_parity_error[2] = PKT_SEG_PARITY_EN ? avst_tx_parity_error_d1[2] : 1'b0; //|avst_tx_parity_error_d1;
    assign o_axist_tx_parity_error[3] = PKT_SEG_PARITY_EN ? avst_tx_parity_error_d1[3] : 1'b0; //|avst_tx_parity_error_d1;
       

    assign avst_tx_user_client[1]  = avst_tx_user_client_d1_p0[1];  
    assign avst_tx_user_client[0]  = avst_tx_user_client_d1_p0[0] | avst_tx_parity_error_d1[0];  
    assign avst_tx_user_client[3]  = avst_tx_user_client_d1_p1[1];  
    assign avst_tx_user_client[2]  = avst_tx_user_client_d1_p1[0] | avst_tx_parity_error_d1[1];  
    assign avst_tx_user_client[5]  = avst_tx_user_client_d1_p2[1];  
    assign avst_tx_user_client[4]  = avst_tx_user_client_d1_p2[0] | avst_tx_parity_error_d1[2]; 
    assign avst_tx_user_client[7]  = avst_tx_user_client_d1_p3[1];  
    assign avst_tx_user_client[6]  = avst_tx_user_client_d1_p3[0] | avst_tx_parity_error_d1[3]; 
    assign avst_tx_user_sp         = {avst_tx_user_client[7:6],avst_tx_user_d1_p3[TUSER-(2*NUM_SEG)-1:0],
                                      avst_tx_user_client[5:4],avst_tx_user_d1_p2[TUSER-(2*NUM_SEG)-1:0],
                                      avst_tx_user_client[3:2],avst_tx_user_d1_p1[TUSER-(2*NUM_SEG)-1:0],
                                      avst_tx_user_client[1:0],avst_tx_user_d1_p0[1*TUSER-(2*NUM_SEG)-1:0]};
    end
end

endgenerate

always @(*)
begin
   case (i_active_segments)
   3'd1: active_segments = 5'd1;
   3'd2: active_segments = 5'd2;
   3'd4: active_segments = 5'd4;
   3'd5: active_segments = 5'd8;
   3'd6: active_segments = 5'd16;
   default: active_segments = 5'd1;
   endcase
end

generate if (AVST_MODE == "MAC_SEGMENTED" && (NUM_MAX_PORTS == 1)) 
begin :MAC_SEGMENTED_1P_OP     
      assign mac_avst_eop_d1                  = avst_eop_d1_p0;
      assign mac_avst_eop_d2                  = avst_eop_d2_p0;
      assign mac_avst_sop_d1                  = avst_sop_d1_p0;
      
      assign tx_valid_parity_error_p0        = tx_parity_error_d2 & avst_tx_data_valid_p0;
      // assign par_err_detected             = |tx_parity_error_d2;
      assign par_err_detected             = |tx_valid_parity_error_p0;
      assign avst_tx_user_sp              = {mac_avst_tx_user_client,avst_tx_user_d2_p0[TUSER-2*NUM_SEG-1:0]};  //421:0
      assign o_axist_tx_parity_error      = PKT_SEG_PARITY_EN ? par_err_detected : 1'b0; //|tx_parity_error_d2;   
        
      assign avst_tx_ready0               =  i_avst_tx_ready[0];                                                                   
      assign fifo_wrreq0                  =  fifo_wrreq_d2[0];

      assign fifo_data_in0[AVST_USER-1:0]                                                              = (PKT_SEG_PARITY_EN) ? avst_tx_user_sp : avst_tx_user_d2_p0;
      assign fifo_data_in0[AVST_DW+AVST_USER-1:AVST_USER]                                              = avst_tx_data_d2;
      assign fifo_data_in0[NUM_SEG+AVST_DW+AVST_USER-1:AVST_DW+AVST_USER]                              = avst_tx_inframe_d2;               
      assign fifo_data_in0[(NUM_SEG*EMPTY_BITS)+NUM_SEG+AVST_DW+AVST_USER-1:NUM_SEG+AVST_DW+AVST_USER] = avst_tx_eop_empty_d2;
      assign fifo_data_in0[FIFO_WIDTH0-1]                                                               = avst_tx_valid_d2_p0; //not used in IP case, used in ED for valid 
      
      assign o_avst_tx_user               = fifo_data_out0[AVST_USER-1:0];                                    
      assign o_avst_tx_data               = fifo_data_out0[AVST_DW+AVST_USER-1:AVST_USER];                    
      assign o_avst_tx_inframe            = (av_st_tx_fifo_flag0 == 1'b0)? fifo_data_out0[NUM_SEG+AVST_DW+AVST_USER-1:AVST_DW+AVST_USER] : '0;    
      assign o_avst_tx_eop_empty          = fifo_data_out0[(NUM_SEG*EMPTY_BITS)+NUM_SEG+AVST_DW+AVST_USER-1:NUM_SEG+AVST_DW+AVST_USER];
      assign o_avst_tx_valid              = i_avst_tx_ready[0]; //fifo_data_out0[FIFO_WIDTH-1]; 
      // assign o_avst_tx_valid              = fifo_data_out0[FIFO_WIDTH-1] && i_avst_tx_ready[0] && ~av_st_tx_fifo_empty0; //To be tested 
      assign o_avst_tx_valid_pkt_client   = fifo_data_out0[FIFO_WIDTH0-1] && i_avst_tx_ready[0] && ~av_st_tx_fifo_empty0;
      assign o_avst_tx_startofpacket      = 1'b0;
      assign o_avst_tx_endofpacket        = 1'b0; 
end
else if (AVST_MODE == "MAC_SEGMENTED" && (NUM_MAX_PORTS == 2)) begin : MAC_SEGMENTED_2P_OP 
      assign tx_valid_parity_error_p0        = tx_parity_error_d2_p0 & avst_tx_data_valid_p0;
      assign tx_valid_parity_error_p1        = tx_parity_error_d2_p1 & avst_tx_data_valid_p1;
      
      assign par_err_detected_p0             = |tx_valid_parity_error_p0;   
      assign par_err_detected_p1             = |tx_valid_parity_error_p1;   
                                             
      assign avst_tx_user_sp                 = {avst_tx_user_client_p1,avst_tx_user_d2_p1[TUSER-NUM_SEG_BITS-1:0], 
                                                avst_tx_user_client_p0,avst_tx_user_d2_p0[TUSER-NUM_SEG_BITS-1:0]};  //421:0   

      assign o_axist_tx_parity_error         = PKT_SEG_PARITY_EN ? {par_err_detected_p1,par_err_detected_p0} : 2'd0; //|tx_parity_error_d2;                                                 
 
      // assign avst_tx_ready0                  =  i_avst_tx_ready[0];
      // assign avst_tx_ready1                  = (i_active_ports == 3'd1)? i_avst_tx_ready[0]: i_avst_tx_ready[1];     
      
      assign avst_tx_ready0                  =  i_avst_tx_ready[0];
      assign avst_tx_ready1                  =  i_avst_tx_ready[1];       
                                                                 
      assign fifo_wrreq0                     =  fifo_wrreq_d2[0];
      assign fifo_wrreq1                     =  fifo_wrreq_d2[1]; 
 
      assign fifo_data_in0[AVST_USER-1:0]                                                                        = (PKT_SEG_PARITY_EN) ? avst_tx_user_sp[AVST_USER-1:0] : avst_tx_user_d2_p0;                                                  //429:0
      assign fifo_data_in0[AVST_DW+AVST_USER-1:AVST_USER]                                                        = (i_active_ports == 3'd1)? avst_tx_data_d2 : {{AVST_DW_BY_MAX_PORTS{1'b0}},avst_tx_data_d2[AVST_DW_BY_MAX_PORTS-1:0]};       //685:430 <= (AP = 1)? -> 255:0 : {128'd0,127:0}
      assign fifo_data_in0[NUM_SEG+AVST_DW+AVST_USER-1:AVST_DW+AVST_USER]                                        = (i_active_ports == 3'd1)? avst_tx_inframe_d2 :{{NUM_SEG_BY_MAX_PORTS{1'b0}}, avst_tx_inframe_d2[NUM_SEG_BY_MAX_PORTS-1:0]}; //689:686 <= (AP =1)? -> 3:0 : {2'd0, 1:0}              
      assign fifo_data_in0[(NUM_SEG*EMPTY_BITS)+NUM_SEG+AVST_DW+AVST_USER-1:NUM_SEG+AVST_DW+AVST_USER]           = (i_active_ports == 3'd1)? avst_tx_eop_empty_d2 : {{EMPTY_BY_MAX_PORTS{1'b0}},avst_tx_eop_empty_d2[EMPTY_BY_MAX_PORTS-1:0]}; //701:690 <= (AP =1)? -> 11:0 : {6'd0, 5:0}   
      assign fifo_data_in0[FIFO_WIDTH0-1]                                                                        = avst_tx_valid_d2_p0; //not used in IP case, used in ED for valid //702 <= 0:0
       
      assign fifo_data_in1[AVST_USER-1:0]                                                                        = (PKT_SEG_PARITY_EN) ? avst_tx_user_sp[(2*AVST_USER)-1:AVST_USER] : avst_tx_user_d2_p1;                                      //429:0 <= 847:424
      assign fifo_data_in1[AVST_DW_BY_MAX_PORTS+AVST_USER-1:AVST_USER]                                           = avst_tx_data_d2[(2*AVST_DW_BY_MAX_PORTS)-1:AVST_DW_BY_MAX_PORTS];                                                           //557:430 <= 255:128
      assign fifo_data_in1[NUM_SEG_BY_MAX_PORTS+AVST_DW_BY_MAX_PORTS+AVST_USER-1:AVST_DW_BY_MAX_PORTS+AVST_USER] = avst_tx_inframe_d2[(2*NUM_SEG_BY_MAX_PORTS)-1:NUM_SEG_BY_MAX_PORTS];                                                        //559:558 <= 3:2              
      assign fifo_data_in1[EMPTY_BY_MAX_PORTS+NUM_SEG_BY_MAX_PORTS+AVST_DW_BY_MAX_PORTS+AVST_USER-1:                                                                                                                                           
                            NUM_SEG_BY_MAX_PORTS+AVST_DW_BY_MAX_PORTS+AVST_USER]                                 = avst_tx_eop_empty_d2[(2*EMPTY_BY_MAX_PORTS)-1:EMPTY_BY_MAX_PORTS];                                                          //565:560 <= 11:6
      // assign fifo_data_in1[FIFO_WIDTH-1]                                                                         = (i_active_ports == 3'd1)? avst_tx_valid_d2[0]: avst_tx_valid_d2[1]; //not used in IP case, used in ED for valid
      assign fifo_data_in1[FIFO_WIDTH1-1]                                                                        = avst_tx_valid_d2_p1; //not used in IP case, used in ED for valid                                                            //566
      
      assign o_avst_tx_user               = {fifo_data_out1[AVST_USER-1:0],fifo_data_out0[AVST_USER-1:0]};                                                                                                                                     //430-1:0                                
      assign o_avst_tx_data               = (i_active_ports == 3'd1)? (fifo_data_out0[AVST_DW+AVST_USER-1:AVST_USER]) :                                                                                                                        //(AP = 1)? -> 685:430 : {557:430, 557:430}  
                                                                      {fifo_data_out1[AVST_DW_BY_MAX_PORTS+AVST_USER-1:AVST_USER], fifo_data_out0[AVST_DW_BY_MAX_PORTS+AVST_USER-1:AVST_USER]};          
      assign o_avst_tx_inframe            = (i_active_ports == 3'd1)? ((!av_st_tx_fifo_flag0)? fifo_data_out0[NUM_SEG+AVST_DW+AVST_USER-1:AVST_DW+AVST_USER] : '0) :
                                                                      {((!av_st_tx_fifo_flag1)? fifo_data_out1[NUM_SEG_BY_MAX_PORTS+AVST_DW_BY_MAX_PORTS+AVST_USER-1:AVST_DW_BY_MAX_PORTS+AVST_USER] : '0),                                     //(AP = 1)? -> 689:686 : {559:558, 687:686}
                                                                      ((!av_st_tx_fifo_flag0)? fifo_data_out0[NUM_SEG_BY_MAX_PORTS+AVST_DW+AVST_USER-1:AVST_DW+AVST_USER] : '0)};  
                                             
      assign o_avst_tx_eop_empty          = (i_active_ports == 3'd1)? fifo_data_out0[(NUM_SEG*EMPTY_BITS)+NUM_SEG+AVST_DW+AVST_USER-1: NUM_SEG+AVST_DW+AVST_USER]:                                                                             //(AP = 1)? -> 701:690 : {565:560, 695:690}
                                                                     {fifo_data_out1[EMPTY_BY_MAX_PORTS+NUM_SEG_BY_MAX_PORTS+AVST_DW_BY_MAX_PORTS+AVST_USER-1: NUM_SEG_BY_MAX_PORTS+AVST_DW_BY_MAX_PORTS+AVST_USER], 
                                                                      fifo_data_out0[EMPTY_BY_MAX_PORTS+NUM_SEG+AVST_DW+AVST_USER-1: NUM_SEG+AVST_DW+AVST_USER]};          
      
      assign o_avst_tx_valid              = i_avst_tx_ready;      
      // assign o_avst_tx_valid[0]           = fifo_data_out0[FIFO_WIDTH-1] && i_avst_tx_ready[0] && ~av_st_tx_fifo_empty0;                                                   
      // assign o_avst_tx_valid[1]           = fifo_data_out1[FIFO_WIDTH-1] && i_avst_tx_ready[1] && ~av_st_tx_fifo_empty1; 
      
      assign o_avst_tx_valid_pkt_client[0]= fifo_data_out0[FIFO_WIDTH0-1] && i_avst_tx_ready[0] && ~av_st_tx_fifo_empty0;
      assign o_avst_tx_valid_pkt_client[1]= fifo_data_out1[FIFO_WIDTH1-1] && i_avst_tx_ready[1] && ~av_st_tx_fifo_empty1;
      
      assign o_avst_tx_startofpacket      = 1'b0;
      assign o_avst_tx_endofpacket        = 1'b0; 
end   
else if (AVST_MODE == "MAC_SEGMENTED" && (NUM_MAX_PORTS == 4)) begin : MAC_SEGMENTED_4P_OP      

      assign tx_valid_parity_error_p0        = tx_parity_error_d2_p0 & avst_tx_data_valid_p0;
      assign tx_valid_parity_error_p1        = tx_parity_error_d2_p1 & avst_tx_data_valid_p1;
      assign tx_valid_parity_error_p2        = tx_parity_error_d2_p2 & avst_tx_data_valid_p2;
      assign tx_valid_parity_error_p3        = tx_parity_error_d2_p3 & avst_tx_data_valid_p3;

      assign par_err_detected_p0             = |tx_valid_parity_error_p0;   
      assign par_err_detected_p1             = |tx_valid_parity_error_p1;   
      assign par_err_detected_p2             = |tx_valid_parity_error_p2;   
      assign par_err_detected_p3             = |tx_valid_parity_error_p3;   
                                             
      assign avst_tx_user_sp                 = {avst_tx_user_client_p3,avst_tx_user_d2_p3[TUSER-NUM_SEG_BITS-1:0],
                                                avst_tx_user_client_p2,avst_tx_user_d2_p2[TUSER-NUM_SEG_BITS-1:0],
                                                avst_tx_user_client_p1,avst_tx_user_d2_p1[TUSER-NUM_SEG_BITS-1:0], 
                                                avst_tx_user_client_p0,avst_tx_user_d2_p0[TUSER-NUM_SEG_BITS-1:0]};  //421:0 

      assign o_axist_tx_parity_error         = PKT_SEG_PARITY_EN ? {par_err_detected_p3,par_err_detected_p2,par_err_detected_p1,par_err_detected_p0} : 4'd0;                                                

      // assign avst_tx_ready0           =  i_avst_tx_ready[0];
      // assign avst_tx_ready1           = (i_active_ports == 3'd4)? i_avst_tx_ready[1]:i_avst_tx_ready[0]; //(i_active_ports == 3'b2)? i_avst_tx_ready[0]: i_avst_tx_ready[0];    
      // assign avst_tx_ready2           = (i_active_ports == 3'd1)? i_avst_tx_ready[0]: i_avst_tx_ready[2];    
      // assign avst_tx_ready3           = (i_active_ports == 3'd4)? i_avst_tx_ready[3]:(i_active_ports == 3'd2)? i_avst_tx_ready[2]: i_avst_tx_ready[0];   

      assign avst_tx_ready0           =  i_avst_tx_ready[0];
      assign avst_tx_ready1           =  i_avst_tx_ready[1]; 
      assign avst_tx_ready2           =  i_avst_tx_ready[2];    
      assign avst_tx_ready3           =  i_avst_tx_ready[3];          
      
      // assign fifo_wrreq0              =  fifo_wrreq_d2[0];
      // assign fifo_wrreq1              = (i_active_ports == 3'd4)? fifo_wrreq_d2[1]:fifo_wrreq_d2[0]; 
      // assign fifo_wrreq2              = (i_active_ports == 3'd1)? fifo_wrreq_d2[0]: fifo_wrreq_d2[2];    
      // assign fifo_wrreq3              = (i_active_ports == 3'd4)? fifo_wrreq_d2[3]:(i_active_ports == 3'd2)? fifo_wrreq_d2[2]: fifo_wrreq_d2[0];    
      
      assign fifo_wrreq0              =  fifo_wrreq_d2[0];
      assign fifo_wrreq1              =  fifo_wrreq_d2[1]; 
      assign fifo_wrreq2              =  fifo_wrreq_d2[2];    
      assign fifo_wrreq3              =  fifo_wrreq_d2[3];        

      assign fifo_data_in0[AVST_USER-1:0]                                                                        = (PKT_SEG_PARITY_EN) ? avst_tx_user_sp[AVST_USER-1:0] : avst_tx_user_d2_p0;                                                               //429:0   <= 429:0                                                        
      assign fifo_data_in0[AVST_DW+AVST_USER-1:AVST_USER]                                                        = (i_active_ports == 3'd1)? avst_tx_data_d2 : (i_active_ports == 3'd2)?      {{AVST_DW_BY_TWO{1'b0}},avst_tx_data_d2[AVST_DW_BY_TWO-1:0]} :            //685:430 <= (ap = 1)? 255:0 : (ap=2)? {128'd0,127:0} :
                                                                                                                                                                                              {{AVST_DW_BY_FOURX3{1'b0}},avst_tx_data_d2[AVST_DW_BY_MAX_PORTS-1:0]};    //           (ap = 4)? {192'b0, [63:0]}
      assign fifo_data_in0[NUM_SEG+AVST_DW+AVST_USER-1:AVST_DW+AVST_USER]                                        = (i_active_ports == 3'd1)? avst_tx_inframe_d2 : (i_active_ports == 3'd2)?   {{NUM_SEG_BY_TWO{1'b0}},avst_tx_inframe_d2[NUM_SEG_BY_TWO-1:0]} :         //689:686 <= (ap = 1)? [3:0] : (ap=2)? {2'd0,1:0} :
                                                                                                                                                                                              {{NUM_SEG_BY_FOURX3{1'b0}},avst_tx_inframe_d2[NUM_SEG_BY_MAX_PORTS-1:0]}; //           (ap = 4)? {3'b0,0:0}              
      assign fifo_data_in0[(NUM_SEG*EMPTY_BITS)+NUM_SEG+AVST_DW+AVST_USER-1: NUM_SEG+AVST_DW+AVST_USER]          = (i_active_ports == 3'd1)? avst_tx_eop_empty_d2 : (i_active_ports == 3'd2)? {{EMPTY_BY_TWO{1'b0}},avst_tx_eop_empty_d2[EMPTY_BY_TWO-1:0]} :           //701:690 <= (ap = 1)? [11:0] : (ap=2)? {6'd0,5:0} :
                                                                                                                                                                                              {{EMPTY_BY_FOURX3{1'b0}},avst_tx_eop_empty_d2[EMPTY_BY_MAX_PORTS-1:0]};   //           (ap = 4)? {9'b0,2:0}      
      assign fifo_data_in0[FIFO_WIDTH0-1]                                                                         = avst_tx_valid_d2_p0; //not used in IP case, used in ED for valid
       
      assign fifo_data_in1[AVST_USER-1:0]                                                                        = (PKT_SEG_PARITY_EN) ? avst_tx_user_sp[(2*AVST_USER)-1:AVST_USER] : avst_tx_user_d2_p1;                                                               //429:0   <= 859:430
      assign fifo_data_in1[AVST_DW_BY_MAX_PORTS+AVST_USER-1:AVST_USER]                                           = avst_tx_data_d2[(2*AVST_DW_BY_MAX_PORTS)-1:AVST_DW_BY_MAX_PORTS];                                                                                    //493:430 <= 127:64
      assign fifo_data_in1[NUM_SEG_BY_MAX_PORTS+AVST_DW_BY_MAX_PORTS+AVST_USER-1:AVST_DW_BY_MAX_PORTS+AVST_USER] = avst_tx_inframe_d2[(2*NUM_SEG_BY_MAX_PORTS)-1:NUM_SEG_BY_MAX_PORTS]; //3:2                                                                           //494:494 <= 1:1
      assign fifo_data_in1[(EMPTY_BY_MAX_PORTS)+NUM_SEG_BY_MAX_PORTS+AVST_DW_BY_MAX_PORTS+AVST_USER-1:                                                                                                                                                                  
                            NUM_SEG_BY_MAX_PORTS+AVST_DW_BY_MAX_PORTS+AVST_USER]                                 = avst_tx_eop_empty_d2[(2*EMPTY_BY_MAX_PORTS)-1:EMPTY_BY_MAX_PORTS];//11:6                                                                             //497:495 <= 5:3
      assign fifo_data_in1[FIFO_WIDTH1-1]                                                                         = avst_tx_valid_d2_p1; //not used in IP case, used in ED for valid

      assign fifo_data_in2[AVST_USER-1:0]                                                                        = (PKT_SEG_PARITY_EN) ? avst_tx_user_sp[(3*AVST_USER)-1:(2*AVST_USER)] : avst_tx_user_d2_p2;                                                           //429:0 <= 1289:860 
      assign fifo_data_in2[AVST_DW_BY_TWO+AVST_USER-1:AVST_USER]                                                 = (i_active_ports == 3'd2)? avst_tx_data_d2[AVST_DW-1:AVST_DW_BY_TWO] : 
                                                                                                                                             {{AVST_DW_BY_MAX_PORTS{1'b0}},avst_tx_data_d2[(3*AVST_DW_BY_MAX_PORTS)-1:(2*AVST_DW_BY_MAX_PORTS)]};                       //557:430 <= (ap = 2)? 255:128 : (ap=4)? {64'd0, 191:128}
      assign fifo_data_in2[NUM_SEG_BY_TWO+AVST_DW_BY_TWO+AVST_USER-1:AVST_DW_BY_TWO+AVST_USER]                   = (i_active_ports == 3'd2)? avst_tx_inframe_d2[NUM_SEG-1:NUM_SEG_BY_TWO] : 
                                                                                                                                             {{NUM_SEG_BY_MAX_PORTS{1'b0}},avst_tx_inframe_d2[(3*NUM_SEG_BY_MAX_PORTS)-1:(2*NUM_SEG_BY_MAX_PORTS)]};                    //559:558 <= (ap = 2)? 3:2 : (ap=4)? {1'b0, 2:2}    
      assign fifo_data_in2[(EMPTY_BY_TWO)+NUM_SEG_BY_TWO+AVST_DW_BY_TWO+AVST_USER-1:
                            NUM_SEG_BY_TWO+AVST_DW_BY_TWO+AVST_USER]                                             = (i_active_ports == 3'd2)? avst_tx_eop_empty_d2[(NUM_SEG*EMPTY_BITS)-1:EMPTY_BY_TWO] :
                                                                                                                                             {{EMPTY_BY_MAX_PORTS{1'b0}}, avst_tx_eop_empty_d2[(3*EMPTY_BY_MAX_PORTS)-1:(2*EMPTY_BY_MAX_PORTS)]};                       //562:560 <= (ap = 2)? 11:6 : (ap=4)? {3'd0, 8:6}   
      assign fifo_data_in2[FIFO_WIDTH2-1]                                                                         = avst_tx_valid_d2_p2; //not used in IP case, used in ED for valid
       
      assign fifo_data_in3[AVST_USER-1:0]                                                                        = (PKT_SEG_PARITY_EN) ? avst_tx_user_sp[(4*AVST_USER)-1:(3*AVST_USER)] : avst_tx_user_d2_p3;                                                           //429:0 <= 1719:290 
      assign fifo_data_in3[AVST_DW_BY_MAX_PORTS+AVST_USER-1:AVST_USER]                                           = avst_tx_data_d2[(4*AVST_DW_BY_MAX_PORTS)-1:(3*AVST_DW_BY_MAX_PORTS)];                                                                                //493:430 <= 255:192
      assign fifo_data_in3[NUM_SEG_BY_MAX_PORTS+AVST_DW_BY_MAX_PORTS+AVST_USER-1:AVST_DW_BY_MAX_PORTS+AVST_USER] = avst_tx_inframe_d2[(4*NUM_SEG_BY_MAX_PORTS)-1:(3*NUM_SEG_BY_MAX_PORTS)];                                                                             //494:494 <= 3:3                                                             
      assign fifo_data_in3[(EMPTY_BY_MAX_PORTS)+NUM_SEG_BY_MAX_PORTS+AVST_DW_BY_MAX_PORTS+AVST_USER-1:
                            NUM_SEG_BY_MAX_PORTS+AVST_DW_BY_MAX_PORTS+AVST_USER]                                 = avst_tx_eop_empty_d2[(4*EMPTY_BY_MAX_PORTS)-1:(3*EMPTY_BY_MAX_PORTS)];                                                                               //497:495 <= 11:9
      assign fifo_data_in3[FIFO_WIDTH3-1]                                                                         = avst_tx_valid_d2_p3; //not used in IP case, used in ED for valid
   


      assign o_avst_tx_user               = {fifo_data_out3[AVST_USER-1:0],fifo_data_out2[AVST_USER-1:0],
                                             fifo_data_out1[AVST_USER-1:0],fifo_data_out0[AVST_USER-1:0]};                                                                                                   //429:0  
                                                                                                                                                                                                             
      assign o_avst_tx_data               = (i_active_ports == 3'd1)? fifo_data_out0[AVST_DW+AVST_USER-1:AVST_USER] :                                                                                        //ap =1? 685:430
                                            (i_active_ports == 3'd2)? {fifo_data_out2[AVST_DW_BY_TWO+AVST_USER-1:AVST_USER], fifo_data_out0[AVST_DW_BY_TWO+AVST_USER-1:AVST_USER]}:                          //ap =2? {557:430,557:430}
                                                                      {fifo_data_out3[AVST_DW_BY_MAX_PORTS+AVST_USER-1:AVST_USER], fifo_data_out2[AVST_DW_BY_MAX_PORTS+AVST_USER-1:AVST_USER],               
                                                                       fifo_data_out1[AVST_DW_BY_MAX_PORTS+AVST_USER-1:AVST_USER], fifo_data_out0[AVST_DW_BY_MAX_PORTS+AVST_USER-1:AVST_USER]};              //ap =4? {493:430}             
                                                                                                                                                                                                             
      assign o_avst_tx_inframe            = (i_active_ports == 3'd1)? ((!av_st_tx_fifo_flag0)? fifo_data_out0[NUM_SEG+AVST_DW+AVST_USER-1:AVST_DW+AVST_USER] : '0):                                          //ap =1? 689:686
                                                                                                                                                                                                             
                                            (i_active_ports == 3'd2)? {((!av_st_tx_fifo_flag2)? fifo_data_out2[NUM_SEG_BY_TWO+AVST_DW_BY_TWO+AVST_USER-1:AVST_DW_BY_TWO+AVST_USER] : '0),                    //ap =2? {[559:558],[687:686]}
                                                                       ((!av_st_tx_fifo_flag0)? fifo_data_out0[NUM_SEG_BY_TWO+AVST_DW+AVST_USER-1:AVST_DW+AVST_USER] : '0)} :
                                                                       
                                                                      {((!av_st_tx_fifo_flag3)? fifo_data_out3[NUM_SEG_BY_MAX_PORTS+AVST_DW_BY_MAX_PORTS+AVST_USER-1:AVST_DW_BY_MAX_PORTS+AVST_USER] : '0),  //ap = 4? {[494:494], [558:558], [494:494], [686:686]}  
                                                                       ((!av_st_tx_fifo_flag2)? fifo_data_out2[NUM_SEG_BY_MAX_PORTS+AVST_DW_BY_TWO+AVST_USER-1:AVST_DW_BY_TWO+AVST_USER] : '0),
                                                                       ((!av_st_tx_fifo_flag1)? fifo_data_out1[NUM_SEG_BY_MAX_PORTS+AVST_DW_BY_MAX_PORTS+AVST_USER-1:AVST_DW_BY_MAX_PORTS+AVST_USER] : '0),  
                                                                       ((!av_st_tx_fifo_flag0)? fifo_data_out0[NUM_SEG_BY_MAX_PORTS+AVST_DW+AVST_USER-1:AVST_DW+AVST_USER] : '0)}; //4+1696+ 256 
                                             
      assign o_avst_tx_eop_empty          = (i_active_ports == 3'd1)? fifo_data_out0[(NUM_SEG*EMPTY_BITS)+NUM_SEG+AVST_DW+AVST_USER-1: NUM_SEG+AVST_DW+AVST_USER]:                                           //ap =1? 701:690
 
                                            (i_active_ports == 3'd2)? {fifo_data_out2[EMPTY_BY_TWO+NUM_SEG_BY_TWO+AVST_DW_BY_TWO+AVST_USER-1: NUM_SEG_BY_TWO+AVST_DW_BY_TWO+AVST_USER],                      //ap =2?  {565:560, 695:690}
                                                                       fifo_data_out0[EMPTY_BY_TWO+NUM_SEG+AVST_DW+AVST_USER-1: NUM_SEG+AVST_DW+AVST_USER]} :                                                
                                                                                                                                                                                                             
                                            {fifo_data_out3[EMPTY_BY_MAX_PORTS+NUM_SEG_BY_MAX_PORTS+AVST_DW_BY_MAX_PORTS+AVST_USER-1: NUM_SEG_BY_MAX_PORTS+AVST_DW_BY_MAX_PORTS+AVST_USER],                  //ap =4? {[497:495],[562:560],[497:495],[692:690]}
                                             fifo_data_out2[EMPTY_BY_MAX_PORTS+NUM_SEG_BY_TWO+AVST_DW_BY_TWO+AVST_USER-1: NUM_SEG_BY_TWO+AVST_DW_BY_TWO+AVST_USER],               
                                             fifo_data_out1[EMPTY_BY_MAX_PORTS+NUM_SEG_BY_MAX_PORTS+AVST_DW_BY_MAX_PORTS+AVST_USER-1: NUM_SEG_BY_MAX_PORTS+AVST_DW_BY_MAX_PORTS+AVST_USER], 
                                             fifo_data_out0[EMPTY_BY_MAX_PORTS+NUM_SEG+AVST_DW+AVST_USER-1: NUM_SEG+AVST_DW+AVST_USER]};          
      
      assign o_avst_tx_valid              = i_avst_tx_ready;      
      
      assign o_avst_tx_valid_pkt_client[0]= fifo_data_out0[FIFO_WIDTH0-1] && i_avst_tx_ready[0] && ~av_st_tx_fifo_empty0;
      assign o_avst_tx_valid_pkt_client[1]= fifo_data_out1[FIFO_WIDTH1-1] && i_avst_tx_ready[1] && ~av_st_tx_fifo_empty1;
      assign o_avst_tx_valid_pkt_client[2]= fifo_data_out2[FIFO_WIDTH2-1] && i_avst_tx_ready[2] && ~av_st_tx_fifo_empty2;
      assign o_avst_tx_valid_pkt_client[3]= fifo_data_out3[FIFO_WIDTH3-1] && i_avst_tx_ready[3] && ~av_st_tx_fifo_empty3;
      
      assign o_avst_tx_startofpacket      = 1'b0;
      assign o_avst_tx_endofpacket        = 1'b0;  
end
else if (AVST_MODE == "SOP_ALIGNED" && (NUM_MAX_PORTS == 1)) begin: TX_SOPA_1P_FIFO  //25g-1, 50g-1, 100g-1
    
    assign fifo_wrreq0                                                                  = fifo_wrreq_d1[0];
    assign avst_tx_ready0                                                               = i_avst_tx_ready[0];
      
    assign fifo_data_in0[AVST_USER-1:0]                                                 = (PKT_SEG_PARITY_EN) ? avst_tx_user_sp : avst_tx_user_d1_p0; //423:0
    if ((PORT_PROFILE == "100GAUI-1") && (DR_ENABLE == 1))    begin : SOPA_1P_100G_DATA
       assign fifo_data_in0[AVST_DW+AVST_USER-1:AVST_USER]                              = (i_port_data_width == 3'd2)? avst_tx_swiped_data_d2_0 : (i_port_data_width == 3'd1)? {{AVST_DW_BY_FOURX3{1'b0}},avst_tx_swiped_data_128_p0}: {{(AVST_DW-AVST_DW_BY_EIGHT){1'b0}},avst_tx_swiped_data_64_p0}; //for 1x100, 1x50 and 1x25
    end
    else begin : SOPA_1P_25G_DATA //DR-25g, 50g and non-dr
       assign fifo_data_in0[AVST_DW+AVST_USER-1:AVST_USER]                              = avst_tx_swapped_data; //128+424-1:424 -> 551:424
    end
    
    if ((PORT_PROFILE == "100GAUI-1") && (DR_ENABLE == 1)) begin : SOPA_1P_100G_EMP
       assign fifo_data_in0[EMPTY_BITS+AVST_DW+AVST_USER-1:AVST_DW+AVST_USER]           = (i_port_data_width == 3'd2)? {6'd0,keep2empty_sopa_d1_p0[5:0]} : (i_port_data_width == 3'd1)? {8'd0,keep2empty_sopa_d1_p0[3:0]}: {9'd0,keep2empty_sopa_d1_p0[2:0]};
    end
    else if ((PORT_PROFILE == "50GAUI-1") && (DR_ENABLE == 1)) begin :  SOPA_1P_50G_EMP
       assign fifo_data_in0[EMPTY_BITS+AVST_DW+AVST_USER-1:AVST_DW+AVST_USER]           = (i_port_data_width == 3'd1)? {2'd0,keep2empty_sopa_d1_p0[3:0]} : {3'd0,keep2empty_sopa_d1_p0[2:0]};   //4+128+424-1:64+424 ->555:552  
    end
    else begin : SOPA_1P_25G_NONDR_EMP //25g and non-dr
       assign fifo_data_in0[EMPTY_BITS+AVST_DW+AVST_USER-1:AVST_DW+AVST_USER]           = keep2empty_sopa_d1_p0;   //4+128+424-1:64+424 ->555:552
    end 
    
    assign fifo_data_in0[EMPTY_BITS+AVST_DW+AVST_USER:EMPTY_BITS+AVST_DW+AVST_USER]     = avst_sop_d1;            // 556
    assign fifo_data_in0[EMPTY_BITS+AVST_DW+AVST_USER+1:EMPTY_BITS+AVST_DW+AVST_USER+1] = avst_eop_d1;            // 557
    
    assign fifo_data_in0[EMPTY_BITS+AVST_DW+AVST_USER+2:EMPTY_BITS+AVST_DW+AVST_USER+2] = avst_tx_valid_d1_p0;    // 558 -> [983:0] //** Needs change - done
    
    assign o_avst_tx_user               = fifo_data_out0[AVST_USER-1:0];                                    
    assign o_avst_tx_data               = fifo_data_out0[AVST_DW+AVST_USER-1:AVST_USER];                    
    assign o_avst_tx_eop_empty          = fifo_data_out0[EMPTY_BITS+AVST_DW+AVST_USER-1:AVST_DW+AVST_USER]; 
    assign o_avst_tx_startofpacket      = fifo_data_out0[EMPTY_BITS+AVST_DW+AVST_USER:EMPTY_BITS+AVST_DW+AVST_USER];
    assign o_avst_tx_endofpacket        = fifo_data_out0[EMPTY_BITS+AVST_DW+AVST_USER+1:EMPTY_BITS+AVST_DW+AVST_USER+1];
    assign o_avst_tx_valid              = fifo_data_out0[EMPTY_BITS+AVST_DW+AVST_USER+2:EMPTY_BITS+AVST_DW+AVST_USER+2] && i_avst_tx_ready[0] && ~av_st_tx_fifo_empty0; //TB
    assign o_avst_tx_valid_pkt_client   = fifo_data_out0[EMPTY_BITS+AVST_DW+AVST_USER+2:EMPTY_BITS+AVST_DW+AVST_USER+2] && i_avst_tx_ready[0] && ~av_st_tx_fifo_empty0;
    assign o_avst_tx_inframe            = {NUM_SEG{1'b0}}; 
    
    end
else if (AVST_MODE == "SOP_ALIGNED" && (NUM_MAX_PORTS == 2)) begin: TX_SOPA_2P_FIFO

    assign fifo_wrreq0                = fifo_wrreq_d1[0];
    assign fifo_wrreq1                = fifo_wrreq_d1[1]; 
    // assign fifo_wrreq4                = fifo_wrreq_d1[1] | fifo_wrreq_d1[0]; 

    assign avst_tx_ready0           =  i_avst_tx_ready[0];
    assign avst_tx_ready1           =  i_avst_tx_ready[1];
    // assign avst_tx_ready4           =  i_avst_tx_ready[0] | i_avst_tx_ready[1];

    assign fifo_data_in0[AVST_USER-1:0]                                                         = (PKT_SEG_PARITY_EN) ? avst_tx_user_sp[AVST_USER-1:0] : avst_tx_user_d1_p0; //423:0
    assign fifo_data_in0[AVST_DW+AVST_USER-1:AVST_USER]                                         = (i_port_data_width == 3'd2)? avst_tx_swiped_data_d2_0 : (i_port_data_width == 3'd1)? {{AVST_DW_BY_FOURX3{1'b0}},avst_tx_swiped_data_128_p0} : {{(AVST_DW-AVST_DW_BY_EIGHT){1'b0}},avst_tx_swiped_data_64_p0};   //25g {191:128, 63:0}  -> to split data into two ports
    assign fifo_data_in0[AVST_DW+AVST_USER  :AVST_DW+AVST_USER]                                 = avst_sop_d1[0];            // 556
    assign fifo_data_in0[AVST_DW+AVST_USER+1:AVST_DW+AVST_USER+1]                               = avst_eop_d1[0];            // 557
    assign fifo_data_in0[AVST_DW+AVST_USER+2:AVST_DW+AVST_USER+2]                               = avst_tx_valid_d1_p0;       // 558 -> [983:0]  //** Needs Change - done
    assign fifo_data_in0[EMPTY_BITS+AVST_DW+AVST_USER+2:AVST_DW+AVST_USER+3]                    = (i_port_data_width == 3'd0)? {9'd0,keep2empty_sopa_d1_p0[2:0]} : (i_port_data_width == 3'd1)? {8'd0,keep2empty_sopa_d1_p0[3:0]} : keep2empty_sopa_d1_p0;       
    
    assign fifo_data_in1[AVST_USER-1:0]                                                         = (PKT_SEG_PARITY_EN) ? avst_tx_user_sp[(2*AVST_USER)-1:AVST_USER] : avst_tx_user_d1_p1; //423:0
    assign fifo_data_in1[AVST_DW_BY_FOUR+AVST_USER-1:AVST_USER]                                 = (i_port_data_width == 3'd0)? {{AVST_DW_BY_EIGHT{1'b0}},avst_tx_swiped_data_64_p1} :  avst_tx_swiped_data_128_p1; //AXI_DW = 128                                                                                                 
    assign fifo_data_in1[AVST_DW_BY_FOUR+AVST_USER  :AVST_DW_BY_FOUR+AVST_USER]                 = avst_sop_d1[1];            // 556
    assign fifo_data_in1[AVST_DW_BY_FOUR+AVST_USER+1:AVST_DW_BY_FOUR+AVST_USER+1]               = avst_eop_d1[1];            // 557
    assign fifo_data_in1[AVST_DW_BY_FOUR+AVST_USER+2:AVST_DW_BY_FOUR+AVST_USER+2]               = avst_tx_valid_d1_p1;       // 558 -> [983:0] //** Needs Change - done
    assign fifo_data_in1[EMPTY_BITS+AVST_DW_BY_FOUR+AVST_USER+2:AVST_DW_BY_FOUR+AVST_USER+3]    = (i_port_data_width == 3'd0)? {9'd0,keep2empty_sopa_d1_p1[2:0]} : (i_port_data_width == 3'd1)? {8'd0,keep2empty_sopa_d1_p1[3:0]} : 12'd0; 

    // assign fifo_data_in4                                                                        = avst_tx_swapped_data [511:256]; //256 bits
    
    assign s_avst_tx_eop_empty_p1           =  fifo_data_out1[EMPTY_BITS+AVST_DW_BY_FOUR+AVST_USER+2:AVST_DW_BY_FOUR+AVST_USER+3];
    assign s_avst_tx_eop_empty_p0           =  fifo_data_out0[EMPTY_BITS+AVST_DW+AVST_USER+2:AVST_DW+AVST_USER+3];
                                             
    assign o_avst_tx_user                   = {fifo_data_out1[AVST_USER-1:0],fifo_data_out0[AVST_USER-1:0]};       
                                            
    assign o_avst_tx_data                   = (i_port_data_width == 3'd2)? fifo_data_out0[AVST_DW+AVST_USER-1:AVST_USER] :
                                              (i_port_data_width == 3'd1)? {256'd0, fifo_data_out1[AVST_DW_BY_FOUR+AVST_USER-1:AVST_USER], fifo_data_out0[AVST_DW_BY_FOUR+AVST_USER-1:AVST_USER]}:
                                              {384'd0,fifo_data_out1[AVST_DW_BY_EIGHT+AVST_USER-1:AVST_USER], fifo_data_out0[AVST_DW_BY_EIGHT+AVST_USER-1:AVST_USER]};                                            
                                            
    assign o_avst_tx_eop_empty              = (i_port_data_width == 3'd0)? {6'd0,s_avst_tx_eop_empty_p1[2:0],s_avst_tx_eop_empty_p0[2:0]}:
                                              (i_port_data_width == 3'd1)? {4'd0,s_avst_tx_eop_empty_p1[3:0],s_avst_tx_eop_empty_p0[3:0]}: s_avst_tx_eop_empty_p0;
                                            
    assign o_avst_tx_startofpacket          = {fifo_data_out1[AVST_DW_BY_FOUR+AVST_USER:AVST_DW_BY_FOUR+AVST_USER],
                                               fifo_data_out0[AVST_DW+AVST_USER:AVST_DW+AVST_USER]};
                                               
    assign o_avst_tx_endofpacket            = {fifo_data_out1[AVST_DW_BY_FOUR+AVST_USER+1:AVST_DW_BY_FOUR+AVST_USER+1],
                                               fifo_data_out0[AVST_DW+AVST_USER+1:AVST_DW+AVST_USER+1]};
                                               
    assign o_avst_tx_valid[0]               = fifo_data_out0[AVST_DW+AVST_USER+2:AVST_DW+AVST_USER+2] && i_avst_tx_ready[0] && ~av_st_tx_fifo_empty0;
    assign o_avst_tx_valid[1]               = fifo_data_out1[AVST_DW_BY_FOUR+AVST_USER+2:AVST_DW_BY_FOUR+AVST_USER+2] && i_avst_tx_ready[1] && ~av_st_tx_fifo_empty1;
                                            
    assign o_avst_tx_valid_pkt_client[0]    = fifo_data_out0[AVST_DW+AVST_USER+2:AVST_DW+AVST_USER+2] && i_avst_tx_ready[0] && ~av_st_tx_fifo_empty0;
    assign o_avst_tx_valid_pkt_client[1]    = fifo_data_out1[AVST_DW_BY_FOUR+AVST_USER+2:AVST_DW_BY_FOUR+AVST_USER+2] && i_avst_tx_ready[1] && ~av_st_tx_fifo_empty1;
                                            
    assign o_avst_tx_inframe                = {NUM_SEG{1'b0}}; 
    
    end
else if (AVST_MODE == "SOP_ALIGNED" && (NUM_MAX_PORTS == 4)) begin: TX_SOPA_4P_FIFO //100-4 - SOPA
    
    assign fifo_wrreq0              =  fifo_wrreq_d1[0];
    assign fifo_wrreq1              =  fifo_wrreq_d1[1]; 
    assign fifo_wrreq2              =  fifo_wrreq_d1[2];    
    assign fifo_wrreq3              =  fifo_wrreq_d1[3]; 
    // assign fifo_wrreq4              = fifo_wrreq_d1[3] | fifo_wrreq_d1[2] | fifo_wrreq_d1[1] | fifo_wrreq_d1[0]; 
    
    assign avst_tx_ready0           =  i_avst_tx_ready[0];
    assign avst_tx_ready1           =  i_avst_tx_ready[1];   
    assign avst_tx_ready2           =  i_avst_tx_ready[2];    
    assign avst_tx_ready3           =  i_avst_tx_ready[3]; 
    // assign avst_tx_ready4           = i_avst_tx_ready[0]|i_avst_tx_ready[1]|i_avst_tx_ready[2]|i_avst_tx_ready[3]; 

    assign fifo_data_in0[AVST_USER-1:0]                                                         = (PKT_SEG_PARITY_EN) ? avst_tx_user_sp[AVST_USER-1:0] : avst_tx_user_d1_p0; //423:0
    // assign fifo_data_in0[AVST_DW+AVST_USER-1:AVST_USER]                                         = avst_tx_swapped_data[AVST_DW_BY_EIGHT-1:0]; //64+424-1:424 -> 488:424
    assign fifo_data_in0[AVST_DW+AVST_USER-1:AVST_USER]                                         = (i_port_data_width == 3'd2)? avst_tx_swiped_data_d2_0 : (i_port_data_width == 3'd1)? {{AVST_DW_BY_FOURX3{1'b0}},avst_tx_swiped_data_128_p0}: {{(AVST_DW-AVST_DW_BY_EIGHT){1'b0}},avst_tx_swiped_data_64_p0}; //64+424-1:424 -> 488:424
    assign fifo_data_in0[AVST_DW+AVST_USER  :AVST_DW+AVST_USER]                                 = avst_sop_d1[0];            // 556
    assign fifo_data_in0[AVST_DW+AVST_USER+1:AVST_DW+AVST_USER+1]                               = avst_eop_d1[0];            // 557
    assign fifo_data_in0[AVST_DW+AVST_USER+2:AVST_DW+AVST_USER+2]                               = avst_tx_valid_d1_p0;       // 558 -> [983:0] //** Needs Change - done
    assign fifo_data_in0[EMPTY_BITS+AVST_DW+AVST_USER+2:AVST_DW+AVST_USER+3]                    = (i_port_data_width == 3'd0)? {9'd0,keep2empty_sopa_d1_p0[2:0]} : (i_port_data_width == 3'd1)? {8'd0,keep2empty_sopa_d1_p0[3:0]} : keep2empty_sopa_d1_p0;
    
    assign fifo_data_in1[AVST_USER-1:0]                                                         = (PKT_SEG_PARITY_EN) ? avst_tx_user_sp[(2*AVST_USER)-1:AVST_USER] : avst_tx_user_d1_p1; //423:0
    // assign fifo_data_in1[AVST_DW_BY_EIGHT+AVST_USER-1:AVST_USER]                                = avst_tx_swapped_data[(2*AVST_DW_BY_EIGHT)-1:AVST_DW_BY_EIGHT]; //64+424-1:424 -> 488:424
    assign fifo_data_in1[AVST_DW_BY_EIGHT+AVST_USER-1:AVST_USER]                                = avst_tx_swiped_data_64_p1; //64+424-1:424 -> 488:424
    assign fifo_data_in1[AVST_DW_BY_EIGHT+AVST_USER  :AVST_DW_BY_EIGHT+AVST_USER]               = avst_sop_d1[1];            // 556
    assign fifo_data_in1[AVST_DW_BY_EIGHT+AVST_USER+1:AVST_DW_BY_EIGHT+AVST_USER+1]             = avst_eop_d1[1];            // 557
    assign fifo_data_in1[AVST_DW_BY_EIGHT+AVST_USER+2:AVST_DW_BY_EIGHT+AVST_USER+2]             = avst_tx_valid_d1_p1;       // 558 -> [983:0]  //** Needs Change - done
    assign fifo_data_in1[EMPTY_BITS+AVST_DW_BY_EIGHT+AVST_USER+2:AVST_DW_BY_EIGHT+AVST_USER+3]  = (i_port_data_width == 3'd0)? {9'd0,keep2empty_sopa_d1_p1[2:0]} : 12'd0;
                                                                                                                  
    assign fifo_data_in2[AVST_USER-1:0]                                                         = (PKT_SEG_PARITY_EN) ? avst_tx_user_sp[(3*AVST_USER)-1:(2*AVST_USER)] : avst_tx_user_d1_p2; //423:0
    assign fifo_data_in2[AVST_DW_BY_FOUR+AVST_USER-1:AVST_USER]                                 = (i_port_data_width == 3'd0)? {{AVST_DW_BY_EIGHT{1'b0}},avst_tx_swiped_data_64_p2}: avst_tx_swiped_data_128_p2; //64+424-1:424 -> 488:424
    assign fifo_data_in2[AVST_DW_BY_FOUR+AVST_USER  :AVST_DW_BY_FOUR+AVST_USER]                 = avst_sop_d1[2];            // 556
    assign fifo_data_in2[AVST_DW_BY_FOUR+AVST_USER+1:AVST_DW_BY_FOUR+AVST_USER+1]               = avst_eop_d1[2];            // 557
    assign fifo_data_in2[AVST_DW_BY_FOUR+AVST_USER+2:AVST_DW_BY_FOUR+AVST_USER+2]               = avst_tx_valid_d1_p2;       // 558 -> [983:0] //** Needs Change - done
    assign fifo_data_in2[EMPTY_BITS+AVST_DW_BY_FOUR+AVST_USER+2:AVST_DW_BY_FOUR+AVST_USER+3]    = (i_port_data_width == 3'd0)? {9'd0,keep2empty_sopa_d1_p2[2:0]} : (i_port_data_width == 3'd1)? {8'd0,keep2empty_sopa_d1_p2[3:0]} : 12'd0;
    
    assign fifo_data_in3[AVST_USER-1:0]                                                         = (PKT_SEG_PARITY_EN) ? avst_tx_user_sp[(4*AVST_USER)-1:(3*AVST_USER)] : avst_tx_user_d1_p3; //423:0
    assign fifo_data_in3[AVST_DW_BY_EIGHT+AVST_USER-1:AVST_USER]                                = avst_tx_swiped_data_64_p3; //64+424-1:424 -> 488:424
    assign fifo_data_in3[AVST_DW_BY_EIGHT+AVST_USER  :AVST_DW_BY_EIGHT+AVST_USER]               = avst_sop_d1[3];            // 556
    assign fifo_data_in3[AVST_DW_BY_EIGHT+AVST_USER+1:AVST_DW_BY_EIGHT+AVST_USER+1]             = avst_eop_d1[3];            // 5572
    assign fifo_data_in3[AVST_DW_BY_EIGHT+AVST_USER+2:AVST_DW_BY_EIGHT+AVST_USER+2]             = avst_tx_valid_d1_p3;       // 558 -> [983:0]  //** Needs Change - done
    assign fifo_data_in3[EMPTY_BITS+AVST_DW_BY_EIGHT+AVST_USER+2:AVST_DW_BY_EIGHT+AVST_USER+3]  = (i_port_data_width == 3'd0)? {9'd0,keep2empty_sopa_d1_p3[2:0]} : 12'd0;

    // assign fifo_data_in4                                                                        = avst_tx_swapped_data [511:256]; //256 bits 
    
    assign s_avst_tx_eop_empty_p3        =  fifo_data_out3[EMPTY_BITS+AVST_DW_BY_EIGHT+AVST_USER+2:AVST_DW_BY_EIGHT+AVST_USER+3];
    assign s_avst_tx_eop_empty_p2        =  fifo_data_out2[EMPTY_BITS+AVST_DW_BY_FOUR+AVST_USER+2:AVST_DW_BY_FOUR+AVST_USER+3];
    assign s_avst_tx_eop_empty_p1        =  fifo_data_out1[EMPTY_BITS+AVST_DW_BY_EIGHT+AVST_USER+2:AVST_DW_BY_EIGHT+AVST_USER+3];
    assign s_avst_tx_eop_empty_p0        =  fifo_data_out0[EMPTY_BITS+AVST_DW+AVST_USER+2:AVST_DW+AVST_USER+3];
  
    assign o_avst_tx_user                = {fifo_data_out3[AVST_USER-1:0],fifo_data_out2[AVST_USER-1:0],fifo_data_out1[AVST_USER-1:0],fifo_data_out0[AVST_USER-1:0]}; 
                                         
    assign o_avst_tx_data                = (i_port_data_width == 3'd2)? fifo_data_out0[AVST_DW+AVST_USER-1:AVST_USER]:
                                           (i_port_data_width == 3'd1)? {256'd0,fifo_data_out2[AVST_DW_BY_FOUR+AVST_USER-1:AVST_USER],fifo_data_out0[AVST_DW_BY_FOUR+AVST_USER-1:AVST_USER]} :
                                                                        {256'd0,fifo_data_out3[AVST_DW_BY_EIGHT+AVST_USER-1:AVST_USER],fifo_data_out2[AVST_DW_BY_EIGHT+AVST_USER-1:AVST_USER],
                                                                         fifo_data_out1[AVST_DW_BY_EIGHT+AVST_USER-1:AVST_USER],fifo_data_out0[AVST_DW_BY_EIGHT+AVST_USER-1:AVST_USER]};  
                                            
    assign o_avst_tx_eop_empty           = (i_port_data_width == 3'd0)? {s_avst_tx_eop_empty_p3[2:0],s_avst_tx_eop_empty_p2[2:0],s_avst_tx_eop_empty_p1[2:0],s_avst_tx_eop_empty_p0[2:0]}:
                                           (i_port_data_width == 3'd1)? {4'd0,s_avst_tx_eop_empty_p2[3:0],s_avst_tx_eop_empty_p0[3:0]}: s_avst_tx_eop_empty_p0;
                                         
    assign o_avst_tx_startofpacket       = {fifo_data_out3[AVST_DW_BY_EIGHT+AVST_USER:AVST_DW_BY_EIGHT+AVST_USER],fifo_data_out2[AVST_DW_BY_FOUR+AVST_USER:AVST_DW_BY_FOUR+AVST_USER],
                                            fifo_data_out1[AVST_DW_BY_EIGHT+AVST_USER:AVST_DW_BY_EIGHT+AVST_USER],fifo_data_out0[AVST_DW+AVST_USER:AVST_DW+AVST_USER]};
                                            
    assign o_avst_tx_endofpacket         = {fifo_data_out3[AVST_DW_BY_EIGHT+AVST_USER+1:AVST_DW_BY_EIGHT+AVST_USER+1],fifo_data_out2[AVST_DW_BY_FOUR+AVST_USER+1:AVST_DW_BY_FOUR+AVST_USER+1],
                                            fifo_data_out1[AVST_DW_BY_EIGHT+AVST_USER+1:AVST_DW_BY_EIGHT+AVST_USER+1],fifo_data_out0[AVST_DW+AVST_USER+1:AVST_DW+AVST_USER+1]};
                                         
    assign o_avst_tx_valid[0]            = fifo_data_out0[AVST_DW+AVST_USER+2:AVST_DW+AVST_USER+2] && i_avst_tx_ready[0] && ~av_st_tx_fifo_empty0;
    assign o_avst_tx_valid[1]            = fifo_data_out1[AVST_DW_BY_EIGHT+AVST_USER+2:AVST_DW_BY_EIGHT+AVST_USER+2] && i_avst_tx_ready[1] && ~av_st_tx_fifo_empty1;
    assign o_avst_tx_valid[2]            = fifo_data_out2[AVST_DW_BY_FOUR+AVST_USER+2:AVST_DW_BY_FOUR+AVST_USER+2] && i_avst_tx_ready[2] && ~av_st_tx_fifo_empty2;
    assign o_avst_tx_valid[3]            = fifo_data_out3[AVST_DW_BY_EIGHT+AVST_USER+2:AVST_DW_BY_EIGHT+AVST_USER+2] && i_avst_tx_ready[3] && ~av_st_tx_fifo_empty3;
                                         
                                         
    assign o_avst_tx_valid_pkt_client[0] = fifo_data_out0[AVST_DW+AVST_USER+2:AVST_DW+AVST_USER+2] && i_avst_tx_ready[0] && ~av_st_tx_fifo_empty0;
    assign o_avst_tx_valid_pkt_client[1] = fifo_data_out1[AVST_DW_BY_EIGHT+AVST_USER+2:AVST_DW_BY_EIGHT+AVST_USER+2] && i_avst_tx_ready[1] && ~av_st_tx_fifo_empty1;
    assign o_avst_tx_valid_pkt_client[2] = fifo_data_out2[AVST_DW_BY_FOUR+AVST_USER+2:AVST_DW_BY_FOUR+AVST_USER+2] && i_avst_tx_ready[2] && ~av_st_tx_fifo_empty2;
    assign o_avst_tx_valid_pkt_client[3] = fifo_data_out3[AVST_DW_BY_EIGHT+AVST_USER+2:AVST_DW_BY_EIGHT+AVST_USER+2] && i_avst_tx_ready[3] && ~av_st_tx_fifo_empty3;
    assign o_avst_tx_inframe             = {NUM_SEG{1'b0}}; 

  end
else begin:b
    assign fifo_wrreq0   = 1'b0;
    assign fifo_wrreq1   = 1'b0;
    assign fifo_wrreq2   = 1'b0;
    assign fifo_wrreq3   = 1'b0; 
    // assign fifo_wrreq4   = 1'b0;
end 
endgenerate

generate if (AVST_MODE == "MAC_SEGMENTED" && (NUM_MAX_PORTS == 1)) 
begin :MAC_SEGMENTED_1P_EMPTY
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0)
      begin
         if (~i_tx_reset_n_p0) begin   
            avst_tx_user_client_d2_p0  <= {NUM_SEG_BITS {1'b0}};
         end
         else
         begin
            avst_tx_user_client_d2_p0  <= avst_tx_user_client_d1_p0; //7:0 / 15:0
         end
      end
end
else if (AVST_MODE == "MAC_SEGMENTED" && (NUM_MAX_PORTS == 2)) begin : MAC_SEGMENTED_2P_EMPTY
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0)  //* muxed reset based on i_active_port
      begin
         if (~i_tx_reset_n_p0) begin   
            avst_tx_user_client_d2_p0  <= {NUM_SEG_BITS {1'b0}};
         end
         else
         begin
            avst_tx_user_client_d2_p0  <= avst_tx_user_client_d1_p0; //7:0 / 15:0 //4 segments, 8 bits
         end
      end
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1)  //* muxed reset based on i_active_port
      begin
         if (~i_tx_reset_n_p1) begin   
            avst_tx_user_client_d2_p1  <= {NUM_SEG_BITS {1'b0}};
         end
         else
         begin
            avst_tx_user_client_d2_p1  <= avst_tx_user_client_d1_p1; //15:8 / 31:16
         end
      end     

      always @(*) begin
         case (i_active_ports)             //* concatenate or use the port wise split signal from input pipeline
         3'd1:  //same logic for 1 port, irrespective of segment
         begin  
            axist_tx_tlast_segment_p0    = i_axist_tx_tlast_segment;
            axist_tx_tlast_segment_p1    = {NUM_SEG{1'b0}};
            axist_tx_tkeep_segment_p0    = i_axist_tx_tkeep_segment;
            axist_tx_tkeep_segment_p1    = {NUM_SEG*8{1'b0}};            
         end 
         3'd2:
         begin  
            axist_tx_tlast_segment_p0    = {{NUM_SEG_BY_TWO{1'b0}},i_axist_tx_tlast_segment[NUM_SEG_BY_TWO-1:0]};
            axist_tx_tlast_segment_p1    = {{NUM_SEG_BY_TWO{1'b0}},i_axist_tx_tlast_segment[NUM_SEG-1:NUM_SEG_BY_TWO]};
            axist_tx_tkeep_segment_p0    = {{(NUM_SEG_BY_TWO*8){1'b0}},i_axist_tx_tkeep_segment[(NUM_SEG_BY_TWO*8)-1:0]}; //15:0, 31:0
            axist_tx_tkeep_segment_p1    = {{(NUM_SEG_BY_TWO*8){1'b0}},i_axist_tx_tkeep_segment[(NUM_SEG*8)-1:(NUM_SEG_BY_TWO*8)]}; //31:16, 63:32
         end        
         default: begin 
            axist_tx_tlast_segment_p0    = {NUM_SEG{1'b0}};
            axist_tx_tlast_segment_p1    = {NUM_SEG{1'b0}};   
            axist_tx_tkeep_segment_p0    = {NUM_SEG*8{1'b0}};
            axist_tx_tkeep_segment_p1    = {NUM_SEG*8{1'b0}};           
         end
         endcase
      end     
      
      // always @(*) begin //* no change
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
      begin   
         if (~i_tx_reset_n_p0) begin
            tx_parity_detect_d1_p0      <= '0;
            mac_tx_pkt_seg_parity_d1_p0 <= '0;
         end
         else begin       
            case (i_active_ports)
            3'd1:  //same logic for 1 port, irrespective of segment
            begin  
               tx_parity_detect_d1_p0         <= tx_parity_detect_d1;            
               mac_tx_pkt_seg_parity_d1_p0    <= i_axist_tx_pkt_seg_parity;
            end 
            3'd2:
            begin  
               tx_parity_detect_d1_p0         <= {{NUM_SEG_BY_TWO{1'b0}},tx_parity_detect_d1[NUM_SEG_BY_TWO-1:0]};
               mac_tx_pkt_seg_parity_d1_p0    <= {{NUM_SEG_BY_TWO{1'b0}},i_axist_tx_pkt_seg_parity[NUM_SEG_BY_TWO-1:0]};
            end        
            default: begin 
               tx_parity_detect_d1_p0         <= {NUM_SEG{1'b0}};
               mac_tx_pkt_seg_parity_d1_p0    <= {NUM_SEG{1'b0}};    
            end
            endcase
         end
      end 

      // always @(*) begin //* no change
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1) 
      begin
         if (~i_tx_reset_n_p1) begin
            tx_parity_detect_d1_p1      <= '0;
            mac_tx_pkt_seg_parity_d1_p1 <= '0;                      
         end
         else begin 
            case (i_active_ports)
            3'd1:  //same logic for 1 port, irrespective of segment
            begin  
               tx_parity_detect_d1_p1         <= {NUM_SEG{1'b0}};         
               mac_tx_pkt_seg_parity_d1_p1    <= {NUM_SEG{1'b0}};               
            end 
            3'd2:
            begin  
               tx_parity_detect_d1_p1         <= {{NUM_SEG_BY_TWO{1'b0}},tx_parity_detect_d1[NUM_SEG-1:NUM_SEG_BY_TWO]};
               mac_tx_pkt_seg_parity_d1_p1    <= {{NUM_SEG_BY_TWO{1'b0}},i_axist_tx_pkt_seg_parity[NUM_SEG-1:NUM_SEG_BY_TWO]};           
            end        
            default: begin 
               tx_parity_detect_d1_p1         <= {NUM_SEG{1'b0}};    
               mac_tx_pkt_seg_parity_d1_p1    <= {NUM_SEG{1'b0}};    
            end
            endcase
         end      
      end     
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0)
      begin
         if (~i_tx_reset_n_p0) begin
            axist_tx_tlast_segment_p0_d1 <= {NUM_SEG{1'b0}};
            axist_tx_tkeep_segment_p0_d1 <= {NUM_SEG*8{1'b0}};
         end
         else begin
            axist_tx_tlast_segment_p0_d1 <= axist_tx_tlast_segment_p0;
            axist_tx_tkeep_segment_p0_d1 <= axist_tx_tkeep_segment_p0;
         end
      end 

      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1) 
      begin
         if (~i_tx_reset_n_p1) begin
            axist_tx_tlast_segment_p1_d1 <= {NUM_SEG{1'b0}};
            axist_tx_tkeep_segment_p1_d1 <= {NUM_SEG*8{1'b0}};                      
         end
         else begin
            axist_tx_tlast_segment_p1_d1 <= axist_tx_tlast_segment_p1;
            axist_tx_tkeep_segment_p1_d1 <= axist_tx_tkeep_segment_p1;
         end
      end 
      
      always @(*) begin  //* check how this can be handled
         case (i_active_ports)
         3'b001: //1port,4seg -> 1x100g , //1port,2seg -> 1x50g
         begin  
            avst_tx_inframe_d2  = avst_tx_inframe_d2_p0;
         end // same condition for 1x50. ideally tlast_seg 2 & 3 should not be 1
         3'b010:  //2port,2seg -> 2x50g, //2port,1seg -> 2x25
         begin  
            avst_tx_inframe_d2 = {avst_tx_inframe_d2_p1[NUM_SEG_BY_TWO-1:0],avst_tx_inframe_d2_p0[NUM_SEG_BY_TWO-1:0]};  //3:0 3:0, 1:0 1:0 - port wise inframe is stored in LSB of p0 and p1 register
         end        
         default: begin avst_tx_inframe_d2 = {NUM_SEG{1'd0}}; end
         endcase
      end         
           
      if (PORT_PROFILE == "100GAUI-2") begin:TX_MS_2P_100G_2  //* re-structure this logic since tkeep to empty conversion is done based on port wise tkeep
                                                                  //* combo have p0 and p1, concat for act_port=1, use p0 , p1 seperately for act_port =2 
      always @(*)  begin                //** valid needs to be updated
         case (i_active_ports)
         3'd1: //1port,2seg -> 1x50g
         begin  
            avst_tx_eop_empty_d2[2:0]  = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[0])? avst_tx_eop_empty_d1[2:0] : 3'd0;
            avst_tx_eop_empty_d2[5:3]  = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[1])? avst_tx_eop_empty_d1[5:3] : 3'd0;
            avst_tx_eop_empty_d2[8:6]  = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[2])? avst_tx_eop_empty_d1[8:6] : 3'd0;
            avst_tx_eop_empty_d2[11:9] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[3])? avst_tx_eop_empty_d1[11:9]: 3'd0;
         end // same condition for 1x50. ideally tlast_seg 2 & 3 should not be 1
         3'd2: //2port,1seg -> 2x25
         begin  
            avst_tx_eop_empty_d2[2:0]  = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[0])? avst_tx_eop_empty_d1[2:0] : 3'd0;
            avst_tx_eop_empty_d2[5:3]  = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[1])? avst_tx_eop_empty_d1[5:3] : 3'd0;
            avst_tx_eop_empty_d2[8:6]  = (avst_tx_valid_d2_p1 & axist_tx_tlast_segment_d2[2])? avst_tx_eop_empty_d1[8:6] : 3'd0;
            avst_tx_eop_empty_d2[11:9] = (avst_tx_valid_d2_p1 & axist_tx_tlast_segment_d2[3])? avst_tx_eop_empty_d1[11:9]: 3'd0;
         end         
         default: begin avst_tx_eop_empty_d2 = {(NUM_SEG*EMPTY_BITS){1'b0}}; end
         endcase
      end            

      end
      else if (PORT_PROFILE == "200GAUI-2") begin:TX_MS_2P_200G_2  
     
      always @(*) begin
         case (i_active_ports)
         3'd1: //1port,2seg -> 1x50g
         begin  
            avst_tx_eop_empty_d2[2 :0 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[0])? avst_tx_eop_empty_d1[2 :0 ]: 3'd0;
            avst_tx_eop_empty_d2[5 :3 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[1])? avst_tx_eop_empty_d1[5 :3 ]: 3'd0;
            avst_tx_eop_empty_d2[8 :6 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[2])? avst_tx_eop_empty_d1[8 :6 ]: 3'd0;
            avst_tx_eop_empty_d2[11:9 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[3])? avst_tx_eop_empty_d1[11:9 ]: 3'd0;
            avst_tx_eop_empty_d2[14:12] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[4])? avst_tx_eop_empty_d1[14:12]: 3'd0;
            avst_tx_eop_empty_d2[17:15] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[5])? avst_tx_eop_empty_d1[17:15]: 3'd0;
            avst_tx_eop_empty_d2[20:18] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[6])? avst_tx_eop_empty_d1[20:18]: 3'd0;
            avst_tx_eop_empty_d2[23:21] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[7])? avst_tx_eop_empty_d1[23:21]: 3'd0;
         end // same condition for 1x50. ideally tlast_seg 2 & 3 should not be 1
         3'd2: //2port,2seg -> 2x50g
         begin  
            avst_tx_eop_empty_d2[2 :0 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[0])? avst_tx_eop_empty_d1[2 :0 ]: 3'd0;
            avst_tx_eop_empty_d2[5 :3 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[1])? avst_tx_eop_empty_d1[5 :3 ]: 3'd0;
            avst_tx_eop_empty_d2[8 :6 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[2])? avst_tx_eop_empty_d1[8 :6 ]: 3'd0;
            avst_tx_eop_empty_d2[11:9 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[3])? avst_tx_eop_empty_d1[11:9 ]: 3'd0;
            avst_tx_eop_empty_d2[14:12] = (avst_tx_valid_d2_p1 & axist_tx_tlast_segment_d2[4])? avst_tx_eop_empty_d1[14:12]: 3'd0;
            avst_tx_eop_empty_d2[17:15] = (avst_tx_valid_d2_p1 & axist_tx_tlast_segment_d2[5])? avst_tx_eop_empty_d1[17:15]: 3'd0;
            avst_tx_eop_empty_d2[20:18] = (avst_tx_valid_d2_p1 & axist_tx_tlast_segment_d2[6])? avst_tx_eop_empty_d1[20:18]: 3'd0;
            avst_tx_eop_empty_d2[23:21] = (avst_tx_valid_d2_p1 & axist_tx_tlast_segment_d2[7])? avst_tx_eop_empty_d1[23:21]: 3'd0;
         end         
         default: begin avst_tx_eop_empty_d2 = {(NUM_SEG*EMPTY_BITS){1'b0}}; end
         endcase
      end      
          
   end

end   
else if (AVST_MODE == "MAC_SEGMENTED" && (NUM_MAX_PORTS == 4)) begin : MAC_SEGMENTED_4P_EMPTY 
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0)
      begin
         if (~i_tx_reset_n_p0) begin   
            avst_tx_user_client_d2_p0  <= {NUM_SEG_BITS{1'b0}};
         end
         else
         begin
            avst_tx_user_client_d2_p0  <= avst_tx_user_client_d1_p0; //7:0 / 15:0 / 31:0
         end
      end     
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1)
      begin
         if (~i_tx_reset_n_p1) begin   
            avst_tx_user_client_d2_p1  <= {NUM_SEG_BITS{1'b0}};
         end
         else
         begin
            avst_tx_user_client_d2_p1  <= avst_tx_user_client_d1_p1; //15:8 / 31:16 / 63:32
         end
      end 

      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p2)
      begin
         if (~i_tx_reset_n_p2) begin   
            avst_tx_user_client_d2_p2  <= {NUM_SEG_BITS{1'b0}};
         end
         else
         begin
            avst_tx_user_client_d2_p2  <= avst_tx_user_client_d1_p2; //23:26 / 47:32 / 95:64
         end
      end 

      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p3)
      begin
         if (~i_tx_reset_n_p3) begin   
            avst_tx_user_client_d2_p3  <= {NUM_SEG_BITS{1'b0}};
         end
         else
         begin
            avst_tx_user_client_d2_p3  <= avst_tx_user_client_d1_p3; //31:24 / 63:48 /127:96
         end
      end     
      
      always @(*) begin
         case (i_active_ports)
         3'd1:  //same logic for 1 port, irrespective of segment
         begin  
            axist_tx_tlast_segment_p0    = i_axist_tx_tlast_segment;
            axist_tx_tlast_segment_p1    = {NUM_SEG{1'b0}};
            axist_tx_tlast_segment_p2    = {NUM_SEG{1'b0}};
            axist_tx_tlast_segment_p3    = {NUM_SEG{1'b0}};
            
            axist_tx_tkeep_segment_p0    = i_axist_tx_tkeep_segment;
            axist_tx_tkeep_segment_p1    = {NUM_SEG*8{1'b0}};            
            axist_tx_tkeep_segment_p2    = {NUM_SEG*8{1'b0}};            
            axist_tx_tkeep_segment_p3    = {NUM_SEG*8{1'b0}};            
         end 
         3'd2:
         begin  
            axist_tx_tlast_segment_p0    = {{NUM_SEG_BY_TWO{1'b0}},i_axist_tx_tlast_segment[NUM_SEG_BY_TWO-1:0]};
            axist_tx_tlast_segment_p1    = {NUM_SEG{1'b0}};
            axist_tx_tlast_segment_p2    = {{NUM_SEG_BY_TWO{1'b0}},i_axist_tx_tlast_segment[NUM_SEG-1:NUM_SEG_BY_TWO]};
            axist_tx_tlast_segment_p3    = {NUM_SEG{1'b0}};
            
            axist_tx_tkeep_segment_p0    = {{(NUM_SEG_BY_TWO*8){1'b0}},i_axist_tx_tkeep_segment[(NUM_SEG_BY_TWO*8)-1:0]}; //15:0, 31:0
            axist_tx_tkeep_segment_p1    = {NUM_SEG*8{1'b0}};
            axist_tx_tkeep_segment_p2    = {{(NUM_SEG_BY_TWO*8){1'b0}},i_axist_tx_tkeep_segment[(NUM_SEG*8)-1:(NUM_SEG_BY_TWO*8)]}; //31:16, 63:32
            axist_tx_tkeep_segment_p3    = {NUM_SEG*8{1'b0}};
         end        
         3'd4:
         begin  
            axist_tx_tlast_segment_p0    = {{NUM_SEG_BY_FOURX3{1'b0}},i_axist_tx_tlast_segment[NUM_SEG_BY_FOUR-1:0]}; //0
            axist_tx_tlast_segment_p1    = {{NUM_SEG_BY_FOURX3{1'b0}},i_axist_tx_tlast_segment[NUM_SEG_BY_TWO-1:NUM_SEG_BY_FOUR]}; //1
            axist_tx_tlast_segment_p2    = {{NUM_SEG_BY_FOURX3{1'b0}},i_axist_tx_tlast_segment[NUM_SEG_BY_FOURX3-1:NUM_SEG_BY_TWO]}; //2
            axist_tx_tlast_segment_p3    = {{NUM_SEG_BY_FOURX3{1'b0}},i_axist_tx_tlast_segment[NUM_SEG-1:NUM_SEG_BY_FOURX3]};//3    
            
            axist_tx_tkeep_segment_p0    = {{(NUM_SEG_BY_FOURX3*8){1'b0}},i_axist_tx_tkeep_segment[(NUM_SEG_BY_FOUR*8)-1:0]}; //7:0
            axist_tx_tkeep_segment_p1    = {{(NUM_SEG_BY_FOURX3*8){1'b0}},i_axist_tx_tkeep_segment[(NUM_SEG_BY_TWO*8)-1:(NUM_SEG_BY_FOUR*8)]}; //15:8
            axist_tx_tkeep_segment_p2    = {{(NUM_SEG_BY_FOURX3*8){1'b0}},i_axist_tx_tkeep_segment[(NUM_SEG_BY_FOURX3*8)-1:(NUM_SEG_BY_TWO*8)]}; //23:16
            axist_tx_tkeep_segment_p3    = {{(NUM_SEG_BY_FOURX3*8){1'b0}},i_axist_tx_tkeep_segment[(NUM_SEG*8)-1:(NUM_SEG_BY_FOURX3*8)]}; //31:24
         end                 
         default: begin 
            axist_tx_tlast_segment_p0    = {NUM_SEG{1'b0}};
            axist_tx_tlast_segment_p1    = {NUM_SEG{1'b0}};   
            axist_tx_tlast_segment_p2    = {NUM_SEG{1'b0}};   
            axist_tx_tlast_segment_p3    = {NUM_SEG{1'b0}};   
            axist_tx_tkeep_segment_p0    = {NUM_SEG*8{1'b0}};
            axist_tx_tkeep_segment_p1    = {NUM_SEG*8{1'b0}};           
            axist_tx_tkeep_segment_p2    = {NUM_SEG*8{1'b0}};           
            axist_tx_tkeep_segment_p3    = {NUM_SEG*8{1'b0}};           
         end
         endcase
      end     
      
      // always @(*) begin
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
      begin
         if (~i_tx_reset_n_p0) begin
            tx_parity_detect_d1_p0 <= '0;
            mac_tx_pkt_seg_parity_d1_p0 <= '0;
         end
         else begin   
            case (i_active_ports)
            3'd1:  //same logic for 1 port, irrespective of segment
            begin  
               tx_parity_detect_d1_p0         <= tx_parity_detect_d1;
               mac_tx_pkt_seg_parity_d1_p0    <= i_axist_tx_pkt_seg_parity;
            end 
            3'd2:
            begin  
               tx_parity_detect_d1_p0         <= {{NUM_SEG_BY_TWO{1'b0}},tx_parity_detect_d1[NUM_SEG_BY_TWO-1:0]};
               mac_tx_pkt_seg_parity_d1_p0    <= {{NUM_SEG_BY_TWO{1'b0}},i_axist_tx_pkt_seg_parity[NUM_SEG_BY_TWO-1:0]};           
            end        
            3'd4:
            begin  
               tx_parity_detect_d1_p0         <= {{NUM_SEG_BY_FOURX3{1'b0}},tx_parity_detect_d1[NUM_SEG_BY_FOUR-1:0]}; //0
               mac_tx_pkt_seg_parity_d1_p0    <= {{NUM_SEG_BY_FOURX3{1'b0}},i_axist_tx_pkt_seg_parity[NUM_SEG_BY_FOUR-1:0]}; //0
            end                 
            default: begin 
               tx_parity_detect_d1_p0         <= {NUM_SEG{1'b0}};
               mac_tx_pkt_seg_parity_d1_p0    <= {NUM_SEG{1'b0}};
            end
            endcase
         end     
      end     
      
      // always @(*) begin
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1) 
      begin
         if (~i_tx_reset_n_p1) begin
            tx_parity_detect_d1_p1 <= '0;
            mac_tx_pkt_seg_parity_d1_p1 <= '0;                      
         end
         else begin   
            case (i_active_ports)
            3'd1:  //same logic for 1 port, irrespective of segment
            begin  
               tx_parity_detect_d1_p1         <= {NUM_SEG{1'b0}};
               mac_tx_pkt_seg_parity_d1_p1    <= {NUM_SEG{1'b0}};
            end 
            3'd2:
            begin  
               tx_parity_detect_d1_p1         <= {NUM_SEG{1'b0}};
               mac_tx_pkt_seg_parity_d1_p1    <= {NUM_SEG{1'b0}};
            end        
            3'd4:
            begin  
               tx_parity_detect_d1_p1         <= {{NUM_SEG_BY_FOURX3{1'b0}},tx_parity_detect_d1[NUM_SEG_BY_TWO-1:NUM_SEG_BY_FOUR]}; //1
               mac_tx_pkt_seg_parity_d1_p1    <= {{NUM_SEG_BY_FOURX3{1'b0}},i_axist_tx_pkt_seg_parity[NUM_SEG_BY_TWO-1:NUM_SEG_BY_FOUR]}; //1
            end                 
            default: begin 
               tx_parity_detect_d1_p1         <= {NUM_SEG{1'b0}};   
               mac_tx_pkt_seg_parity_d1_p1    <= {NUM_SEG{1'b0}};   
            end
            endcase
         end     
      end        

      // always @(*) begin
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p2) 
      begin
         if (~i_tx_reset_n_p2) begin
            tx_parity_detect_d1_p2 <= '0;
            mac_tx_pkt_seg_parity_d1_p2 <= '0;                      
         end
         else begin   
            case (i_active_ports)
            3'd1:  //same logic for 1 port, irrespective of segment
            begin  
               tx_parity_detect_d1_p2         <= {NUM_SEG{1'b0}};
               mac_tx_pkt_seg_parity_d1_p2    <= {NUM_SEG{1'b0}};
            end 
            3'd2:
            begin  
               tx_parity_detect_d1_p2         <= {{NUM_SEG_BY_TWO{1'b0}},tx_parity_detect_d1[NUM_SEG-1:NUM_SEG_BY_TWO]};
               mac_tx_pkt_seg_parity_d1_p2    <= {{NUM_SEG_BY_TWO{1'b0}},i_axist_tx_pkt_seg_parity[NUM_SEG-1:NUM_SEG_BY_TWO]};
            end        
            3'd4:
            begin  
               tx_parity_detect_d1_p2         <= {{NUM_SEG_BY_FOURX3{1'b0}},tx_parity_detect_d1[NUM_SEG_BY_FOURX3-1:NUM_SEG_BY_TWO]}; //2
               mac_tx_pkt_seg_parity_d1_p2    <= {{NUM_SEG_BY_FOURX3{1'b0}},i_axist_tx_pkt_seg_parity[NUM_SEG_BY_FOURX3-1:NUM_SEG_BY_TWO]}; //2
            end                 
            default: begin 
               tx_parity_detect_d1_p2         <= {NUM_SEG{1'b0}};   
               mac_tx_pkt_seg_parity_d1_p2    <= {NUM_SEG{1'b0}};   
            end
            endcase
         end    
      end       

      // always @(*) begin
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p3) 
      begin
         if (~i_tx_reset_n_p3) begin
            tx_parity_detect_d1_p3 <= '0;
            mac_tx_pkt_seg_parity_d1_p3 <= '0;                      
         end
         else begin   
            case (i_active_ports)
            3'd1:  //same logic for 1 port, irrespective of segment
            begin  
               tx_parity_detect_d1_p3         <= {NUM_SEG{1'b0}};
               mac_tx_pkt_seg_parity_d1_p3    <= {NUM_SEG{1'b0}};                      
            end 
            3'd2:
            begin  
               tx_parity_detect_d1_p3         <= {NUM_SEG{1'b0}};
               mac_tx_pkt_seg_parity_d1_p3    <= {NUM_SEG{1'b0}};                       
            end        
            3'd4:
            begin  
               tx_parity_detect_d1_p3         <= {{NUM_SEG_BY_FOURX3{1'b0}},tx_parity_detect_d1[NUM_SEG-1:NUM_SEG_BY_FOURX3]};//3    
               mac_tx_pkt_seg_parity_d1_p3    <= {{NUM_SEG_BY_FOURX3{1'b0}},i_axist_tx_pkt_seg_parity[NUM_SEG-1:NUM_SEG_BY_FOURX3]};//3                          
            end                 
            default: begin 
               tx_parity_detect_d1_p3         <= {NUM_SEG{1'b0}};     
               mac_tx_pkt_seg_parity_d1_p3    <= {NUM_SEG{1'b0}};                 
            end
            endcase
         end          
      end             
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
      begin
         if (~i_tx_reset_n_p0) begin
            axist_tx_tlast_segment_p0_d1 <= {NUM_SEG{1'b0}};
            axist_tx_tkeep_segment_p0_d1 <= {NUM_SEG*8{1'b0}};
         end
         else begin
            axist_tx_tlast_segment_p0_d1 <= axist_tx_tlast_segment_p0;
            axist_tx_tkeep_segment_p0_d1 <= axist_tx_tkeep_segment_p0;
         end
      end   

      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p1) 
      begin
         if (~i_tx_reset_n_p1) begin
            axist_tx_tlast_segment_p1_d1 <= {NUM_SEG{1'b0}};
            axist_tx_tkeep_segment_p1_d1 <= {NUM_SEG*8{1'b0}};                      
         end
         else begin
            axist_tx_tlast_segment_p1_d1 <= axist_tx_tlast_segment_p1;
            axist_tx_tkeep_segment_p1_d1 <= axist_tx_tkeep_segment_p1;
         end
      end     
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p2) 
      begin
         if (~i_tx_reset_n_p2) begin
            axist_tx_tlast_segment_p2_d1 <= {NUM_SEG{1'b0}};
            axist_tx_tkeep_segment_p2_d1 <= {NUM_SEG*8{1'b0}};                      
         end
         else begin
            axist_tx_tlast_segment_p2_d1 <= axist_tx_tlast_segment_p2;
            axist_tx_tkeep_segment_p2_d1 <= axist_tx_tkeep_segment_p2;
         end
      end     
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p3) 
      begin
         if (~i_tx_reset_n_p3) begin
            axist_tx_tlast_segment_p3_d1 <= {NUM_SEG{1'b0}};
            axist_tx_tkeep_segment_p3_d1 <= {NUM_SEG*8{1'b0}};                      
         end
         else begin
            axist_tx_tlast_segment_p3_d1 <= axist_tx_tlast_segment_p3;
            axist_tx_tkeep_segment_p3_d1 <= axist_tx_tkeep_segment_p3;
         end
      end         
      
      always @(*) begin
         case (i_active_ports)
         3'd1: //1port,2seg -> 1x50g/1x40g
         begin  
            avst_tx_inframe_d2 = avst_tx_inframe_d2_p0;
         end 
         3'd2: //2port,2seg -> 2x50g
         begin  
            avst_tx_inframe_d2 = {avst_tx_inframe_d2_p2[NUM_SEG_BY_TWO-1:0],avst_tx_inframe_d2_p0[NUM_SEG_BY_TWO-1:0]};
         end  
         3'd4: //4port,1seg -> 4x25g
         begin  
            avst_tx_inframe_d2 = {avst_tx_inframe_d2_p3[NUM_SEG_BY_FOUR-1:0],avst_tx_inframe_d2_p2[NUM_SEG_BY_FOUR-1:0],
                                  avst_tx_inframe_d2_p1[NUM_SEG_BY_FOUR-1:0],avst_tx_inframe_d2_p0[NUM_SEG_BY_FOUR-1:0]};
         end             
         default: begin avst_tx_inframe_d2 = {NUM_SEG{1'd0}}; end
         endcase
      end

     if (PORT_PROFILE == "100GCAUI-4") begin: TX_MS_4P_100G_4
        always @(*) begin
              case (i_active_ports)
              3'd1: //1port,2seg -> 1x50g/1x40g
              begin  
                 avst_tx_eop_empty_d2[2:0]  = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[0])? avst_tx_eop_empty_d1[2:0] : 3'd0;
                 avst_tx_eop_empty_d2[5:3]  = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[1])? avst_tx_eop_empty_d1[5:3] : 3'd0;
                 avst_tx_eop_empty_d2[8:6]  = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[2])? avst_tx_eop_empty_d1[8:6] : 3'd0;
                 avst_tx_eop_empty_d2[11:9] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[3])? avst_tx_eop_empty_d1[11:9]: 3'd0;
              end 
              3'd2: //2port,2seg -> 2x50g
              begin  
                 avst_tx_eop_empty_d2[2:0]  = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[0])? avst_tx_eop_empty_d1[2:0] : 3'd0;
                 avst_tx_eop_empty_d2[5:3]  = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[1])? avst_tx_eop_empty_d1[5:3] : 3'd0;
                 avst_tx_eop_empty_d2[8:6]  = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[2])? avst_tx_eop_empty_d1[8:6] : 3'd0;
                 avst_tx_eop_empty_d2[11:9] = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[3])? avst_tx_eop_empty_d1[11:9]: 3'd0;
              end  
              3'd4: //4port,1seg -> 4x25g
              begin  
                 avst_tx_eop_empty_d2[2:0]  = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[0])? avst_tx_eop_empty_d1[2:0] : 3'd0;
                 avst_tx_eop_empty_d2[5:3]  = (avst_tx_valid_d2_p1 & axist_tx_tlast_segment_d2[1])? avst_tx_eop_empty_d1[5:3] : 3'd0;
                 avst_tx_eop_empty_d2[8:6]  = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[2])? avst_tx_eop_empty_d1[8:6] : 3'd0;
                 avst_tx_eop_empty_d2[11:9] = (avst_tx_valid_d2_p3 & axist_tx_tlast_segment_d2[3])? avst_tx_eop_empty_d1[11:9]: 3'd0;
              end             
              default: begin avst_tx_eop_empty_d2 = {(NUM_SEG*EMPTY_BITS){1'b0}}; end
              endcase
           end
     end   
     else if (PORT_PROFILE == "400GAUI-8" ||PORT_PROFILE == "400GAUI-4") begin: TX_MS_4P_400G_8
     
        always @(*) begin
            case (i_active_ports)
            3'd1: //1port,8seg -> 1x200g
            begin  
               avst_tx_eop_empty_d2[2 :0 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[0 ])? avst_tx_eop_empty_d1[2 :0 ]: 3'd0;
               avst_tx_eop_empty_d2[5 :3 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[1 ])? avst_tx_eop_empty_d1[5 :3 ]: 3'd0;
               avst_tx_eop_empty_d2[8 :6 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[2 ])? avst_tx_eop_empty_d1[8 :6 ]: 3'd0;
               avst_tx_eop_empty_d2[11:9 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[3 ])? avst_tx_eop_empty_d1[11:9 ]: 3'd0;
               avst_tx_eop_empty_d2[14:12] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[4 ])? avst_tx_eop_empty_d1[14:12]: 3'd0;
               avst_tx_eop_empty_d2[17:15] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[5 ])? avst_tx_eop_empty_d1[17:15]: 3'd0;
               avst_tx_eop_empty_d2[20:18] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[6 ])? avst_tx_eop_empty_d1[20:18]: 3'd0;
               avst_tx_eop_empty_d2[23:21] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[7 ])? avst_tx_eop_empty_d1[23:21]: 3'd0;
               avst_tx_eop_empty_d2[26:24] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[8 ])? avst_tx_eop_empty_d1[26:24]: 3'd0;
               avst_tx_eop_empty_d2[29:27] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[9 ])? avst_tx_eop_empty_d1[29:27]: 3'd0;
               avst_tx_eop_empty_d2[32:30] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[10])? avst_tx_eop_empty_d1[32:30]: 3'd0;
               avst_tx_eop_empty_d2[35:33] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[11])? avst_tx_eop_empty_d1[35:33]: 3'd0;
               avst_tx_eop_empty_d2[38:36] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[12])? avst_tx_eop_empty_d1[38:36]: 3'd0;
               avst_tx_eop_empty_d2[41:39] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[13])? avst_tx_eop_empty_d1[41:39]: 3'd0;
               avst_tx_eop_empty_d2[44:42] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[14])? avst_tx_eop_empty_d1[44:42]: 3'd0;
               avst_tx_eop_empty_d2[47:45] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[15])? avst_tx_eop_empty_d1[47:45]: 3'd0;            
            end         
            
            3'd2: //2port,4seg -> 2x100g
            begin  
               avst_tx_eop_empty_d2[2 :0 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[0 ])? avst_tx_eop_empty_d1[2 :0 ]: 3'd0;
               avst_tx_eop_empty_d2[5 :3 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[1 ])? avst_tx_eop_empty_d1[5 :3 ]: 3'd0;
               avst_tx_eop_empty_d2[8 :6 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[2 ])? avst_tx_eop_empty_d1[8 :6 ]: 3'd0;
               avst_tx_eop_empty_d2[11:9 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[3 ])? avst_tx_eop_empty_d1[11:9 ]: 3'd0;
               avst_tx_eop_empty_d2[14:12] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[4 ])? avst_tx_eop_empty_d1[14:12]: 3'd0;
               avst_tx_eop_empty_d2[17:15] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[5 ])? avst_tx_eop_empty_d1[17:15]: 3'd0;
               avst_tx_eop_empty_d2[20:18] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[6 ])? avst_tx_eop_empty_d1[20:18]: 3'd0;
               avst_tx_eop_empty_d2[23:21] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[7 ])? avst_tx_eop_empty_d1[23:21]: 3'd0;
               avst_tx_eop_empty_d2[26:24] = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[8 ])? avst_tx_eop_empty_d1[26:24]: 3'd0;
               avst_tx_eop_empty_d2[29:27] = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[9 ])? avst_tx_eop_empty_d1[29:27]: 3'd0;
               avst_tx_eop_empty_d2[32:30] = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[10])? avst_tx_eop_empty_d1[32:30]: 3'd0;
               avst_tx_eop_empty_d2[35:33] = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[11])? avst_tx_eop_empty_d1[35:33]: 3'd0;
               avst_tx_eop_empty_d2[38:36] = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[12])? avst_tx_eop_empty_d1[38:36]: 3'd0;
               avst_tx_eop_empty_d2[41:39] = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[13])? avst_tx_eop_empty_d1[41:39]: 3'd0;
               avst_tx_eop_empty_d2[44:42] = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[14])? avst_tx_eop_empty_d1[44:42]: 3'd0;
               avst_tx_eop_empty_d2[47:45] = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[15])? avst_tx_eop_empty_d1[47:45]: 3'd0;   
            end 
            
            3'd4: //4port,4seg -> 4x100g
            begin  
               avst_tx_eop_empty_d2[2 :0 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[0 ])? avst_tx_eop_empty_d1[2 :0 ]: 3'd0;
               avst_tx_eop_empty_d2[5 :3 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[1 ])? avst_tx_eop_empty_d1[5 :3 ]: 3'd0;
               avst_tx_eop_empty_d2[8 :6 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[2 ])? avst_tx_eop_empty_d1[8 :6 ]: 3'd0;
               avst_tx_eop_empty_d2[11:9 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[3 ])? avst_tx_eop_empty_d1[11:9 ]: 3'd0;
               avst_tx_eop_empty_d2[14:12] = (avst_tx_valid_d2_p1 & axist_tx_tlast_segment_d2[4 ])? avst_tx_eop_empty_d1[14:12]: 3'd0;
               avst_tx_eop_empty_d2[17:15] = (avst_tx_valid_d2_p1 & axist_tx_tlast_segment_d2[5 ])? avst_tx_eop_empty_d1[17:15]: 3'd0;
               avst_tx_eop_empty_d2[20:18] = (avst_tx_valid_d2_p1 & axist_tx_tlast_segment_d2[6 ])? avst_tx_eop_empty_d1[20:18]: 3'd0;
               avst_tx_eop_empty_d2[23:21] = (avst_tx_valid_d2_p1 & axist_tx_tlast_segment_d2[7 ])? avst_tx_eop_empty_d1[23:21]: 3'd0;
               avst_tx_eop_empty_d2[26:24] = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[8 ])? avst_tx_eop_empty_d1[26:24]: 3'd0;
               avst_tx_eop_empty_d2[29:27] = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[9 ])? avst_tx_eop_empty_d1[29:27]: 3'd0;
               avst_tx_eop_empty_d2[32:30] = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[10])? avst_tx_eop_empty_d1[32:30]: 3'd0;
               avst_tx_eop_empty_d2[35:33] = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[11])? avst_tx_eop_empty_d1[35:33]: 3'd0;
               avst_tx_eop_empty_d2[38:36] = (avst_tx_valid_d2_p3 & axist_tx_tlast_segment_d2[12])? avst_tx_eop_empty_d1[38:36]: 3'd0;
               avst_tx_eop_empty_d2[41:39] = (avst_tx_valid_d2_p3 & axist_tx_tlast_segment_d2[13])? avst_tx_eop_empty_d1[41:39]: 3'd0;
               avst_tx_eop_empty_d2[44:42] = (avst_tx_valid_d2_p3 & axist_tx_tlast_segment_d2[14])? avst_tx_eop_empty_d1[44:42]: 3'd0;
               avst_tx_eop_empty_d2[47:45] = (avst_tx_valid_d2_p3 & axist_tx_tlast_segment_d2[15])? avst_tx_eop_empty_d1[47:45]: 3'd0;
            end  
                
            default: begin avst_tx_eop_empty_d2 = {(NUM_SEG*EMPTY_BITS){1'b0}}; end
            endcase
         end

      
      end
      else if (PORT_PROFILE == "200GAUI-4") begin: TX_MS_4P_200G_4
      
        always @(*) begin
            case (i_active_ports)
            3'd1: //1port,4seg -> 1x100g
            begin  
               avst_tx_eop_empty_d2[2 :0 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[0])? avst_tx_eop_empty_d1[2 :0 ]: 3'd0;
               avst_tx_eop_empty_d2[5 :3 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[1])? avst_tx_eop_empty_d1[5 :3 ]: 3'd0;
               avst_tx_eop_empty_d2[8 :6 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[2])? avst_tx_eop_empty_d1[8 :6 ]: 3'd0;
               avst_tx_eop_empty_d2[11:9 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[3])? avst_tx_eop_empty_d1[11:9 ]: 3'd0;
               avst_tx_eop_empty_d2[14:12] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[4])? avst_tx_eop_empty_d1[14:12]: 3'd0;
               avst_tx_eop_empty_d2[17:15] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[5])? avst_tx_eop_empty_d1[17:15]: 3'd0;
               avst_tx_eop_empty_d2[20:18] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[6])? avst_tx_eop_empty_d1[20:18]: 3'd0;
               avst_tx_eop_empty_d2[23:21] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[7])? avst_tx_eop_empty_d1[23:21]: 3'd0;        
            end         
            
            3'd2: //2port,2seg -> 2x50g
            begin  
               avst_tx_eop_empty_d2[2 :0 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[0])? avst_tx_eop_empty_d1[2 :0 ]: 3'd0;
               avst_tx_eop_empty_d2[5 :3 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[1])? avst_tx_eop_empty_d1[5 :3 ]: 3'd0;
               avst_tx_eop_empty_d2[8 :6 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[2])? avst_tx_eop_empty_d1[8 :6 ]: 3'd0;
               avst_tx_eop_empty_d2[11:9 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[3])? avst_tx_eop_empty_d1[11:9 ]: 3'd0;
               avst_tx_eop_empty_d2[14:12] = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[4])? avst_tx_eop_empty_d1[14:12]: 3'd0;
               avst_tx_eop_empty_d2[17:15] = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[5])? avst_tx_eop_empty_d1[17:15]: 3'd0;
               avst_tx_eop_empty_d2[20:18] = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[6])? avst_tx_eop_empty_d1[20:18]: 3'd0;
               avst_tx_eop_empty_d2[23:21] = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[7])? avst_tx_eop_empty_d1[23:21]: 3'd0;
            end 
            
            3'd4: //4port,2seg -> 4x50g
            begin  
               avst_tx_eop_empty_d2[2 :0 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[0])? avst_tx_eop_empty_d1[2 :0 ]: 3'd0;
               avst_tx_eop_empty_d2[5 :3 ] = (avst_tx_valid_d2_p0 & axist_tx_tlast_segment_d2[1])? avst_tx_eop_empty_d1[5 :3 ]: 3'd0;
               avst_tx_eop_empty_d2[8 :6 ] = (avst_tx_valid_d2_p1 & axist_tx_tlast_segment_d2[2])? avst_tx_eop_empty_d1[8 :6 ]: 3'd0;
               avst_tx_eop_empty_d2[11:9 ] = (avst_tx_valid_d2_p1 & axist_tx_tlast_segment_d2[3])? avst_tx_eop_empty_d1[11:9 ]: 3'd0;
               avst_tx_eop_empty_d2[14:12] = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[4])? avst_tx_eop_empty_d1[14:12]: 3'd0;
               avst_tx_eop_empty_d2[17:15] = (avst_tx_valid_d2_p2 & axist_tx_tlast_segment_d2[5])? avst_tx_eop_empty_d1[17:15]: 3'd0;
               avst_tx_eop_empty_d2[20:18] = (avst_tx_valid_d2_p3 & axist_tx_tlast_segment_d2[6])? avst_tx_eop_empty_d1[20:18]: 3'd0;
               avst_tx_eop_empty_d2[23:21] = (avst_tx_valid_d2_p3 & axist_tx_tlast_segment_d2[7])? avst_tx_eop_empty_d1[23:21]: 3'd0;
            end  
                
            default: begin avst_tx_eop_empty_d2 = {(NUM_SEG*EMPTY_BITS){1'b0}}; end
            endcase
         end                  
      end
end
else begin:z
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0)
      begin
         if (~i_tx_reset_n_p0) begin   
            avst_tx_user_client_d2_p0  <= {NUM_SEG_BITS{1'b0}};
         end
         else
         begin
            avst_tx_user_client_d2_p0  <= avst_tx_user_client_d2_p0;
         end
      end   
      
      always @(posedge i_tx_clk_p1 or negedge i_tx_reset_n_p1)
      begin
         if (~i_tx_reset_n_p1) begin   
            avst_tx_user_client_d2_p1  <= {NUM_SEG_BITS{1'b0}};
         end
         else
         begin
            avst_tx_user_client_d2_p1  <= avst_tx_user_client_d2_p1;
         end
      end 

      always @(posedge i_tx_clk_p2 or negedge i_tx_reset_n_p2)
      begin
         if (~i_tx_reset_n_p2) begin   
            avst_tx_user_client_d2_p2  <= {NUM_SEG_BITS{1'b0}};
         end
         else
         begin
            avst_tx_user_client_d2_p2  <= avst_tx_user_client_d2_p2;
         end
      end 

      always @(posedge i_tx_clk_p3 or negedge i_tx_reset_n_p3)
      begin
         if (~i_tx_reset_n_p3) begin   
            avst_tx_user_client_d2_p3  <= {NUM_SEG_BITS{1'b0}};
         end
         else
         begin
            avst_tx_user_client_d2_p3  <= avst_tx_user_client_d2_p3;
         end
      end     
end
endgenerate

generate if (AVST_MODE == "SOP_ALIGNED" && (PORT_PROFILE == "25GbE" || PORT_PROFILE == "10GbE" || (DR_ENABLE == 0))) //max ports = 1 for non -dr cases
begin:TX_SOPA_25GbE
  genvar n;
  for (n=0; n<AVST_DW/8; n=n+1) begin :TX_SOPA_25GbE_SWAP

      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0)begin 
         if (~i_tx_reset_n_p0)
            avst_tx_swiped_data_d2_0[((n+1)*8)-1:(n*8)] <= 8'b0;   
         else
            avst_tx_swiped_data_d2_0[((n+1)*8)-1:(n*8)] <= i_axist_tx_tdata[(AVST_DW-(n*8)-1):(AVST_DW-((n+1)*8))];
      end
   end

   always_comb begin
      avst_tx_swapped_data     = avst_tx_swiped_data_d2_0;
   end
    
    assign tx_avst_parity_detect_d1 = ^(i_axist_tx_tdata);
    
end

else if (AVST_MODE == "SOP_ALIGNED" && (PORT_PROFILE == "50GAUI-1" || PORT_PROFILE == "40GCAUI-4" || PORT_PROFILE == "50GAUI-2")) //supports 1x50g and 1x25g 
begin:TX_SOPA_50G_1
genvar p,q;
for (p=0; p<AVST_DW/8; p=p+1) begin :TX_SOPA_50G_1_SWAP1
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0)begin  
         if (~i_tx_reset_n_p0)
            avst_tx_swiped_data_d2_0[((p+1)*8)-1:(p*8)] <= 8'd0;   
         else     
            avst_tx_swiped_data_d2_0[((p+1)*8)-1:(p*8)] <= i_axist_tx_tdata[(AVST_DW-(p*8)-1):((AVST_DW)-((p+1)*8))]; //p0 clk used. no reset condition added w..r.t port_data_width
      end
end

if (AXI_DW != 256) begin:SOPA_DATA_NON_PPT
   for (q=0; q<AVST_DW/16; q=q+1) begin :TX_SOPA_50G_1_SWAP2
         always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) begin  
            if (~i_tx_reset_n_p0) begin
               avst_tx_swiped_data_64_p0[((q+1)*8)-1:(q*8)] <= 8'd0;   
            end 
            else     
            begin
               avst_tx_swiped_data_64_p0[((q+1)*8)-1:(q*8)]<= i_axist_tx_tdata[((AVST_DW_BY_TWO)-(q*8)-1):((AVST_DW_BY_TWO)-(q+1)*8)]; //p0 clk used. no reset condition added w..r.t port_data_width
            end      
         end      
   end
end   

if (AXI_DW == 256) begin:SOPA_PPT_ENABLE
   always_comb begin //256 bits -> 40G or 50G preamble pass through - 5 bits
      avst_tx_swapped_data     = avst_tx_swiped_data_d2_0;
   end
end 
else if (DR_ENABLE == 0) begin: SOPA_NON_DR_PPT_DISABLE
   always_comb begin
      avst_tx_swapped_data     = avst_tx_swiped_data_d2_0;
   end 
end
else begin:SOPA_PPT_DISABLE
   always_comb begin
      if (i_port_data_width == 3'd1) //128 bits
      begin
      avst_tx_swapped_data     = avst_tx_swiped_data_d2_0;
      end 
      else
      begin
      avst_tx_swapped_data     = {64'd0,avst_tx_swiped_data_64_p0};
      end
   end
end   

if (DR_ENABLE == 0) begin: SOPA_NON_DR_PARITY_50G
   assign tx_avst_parity_detect_d1 = (^(i_axist_tx_tdata)); // handles PPT enable 
end
else begin: SOPA_DR_PARITY_50G
    assign tx_avst_parity_detect_d1 = (i_port_data_width == 3'd0)? (^(i_axist_tx_tdata[63:0])): (^(i_axist_tx_tdata)); //else condition handles PPT enable 
end

end

else if (AVST_MODE == "SOP_ALIGNED" && (PORT_PROFILE == "100GCAUI-4" || PORT_PROFILE == "100GAUI-2" || PORT_PROFILE == "100GAUI-1")) //* port wise restructing? Fifo write muxing will change
begin:TX_SOPA_100G
genvar r,s,t;
//100g-2,100g-1,100g-4
//reverse 512 bit blocks
for (r=0; r<AVST_DW/8; r=r+1) begin :TX_SOPA_100G_SWAP1
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0)begin  //* remove reset and reversal is based on 1,2,4 clks
         if (~i_tx_reset_n_p0)
            avst_tx_swiped_data_d2_0[((r+1)*8)-1:(r*8)] <= 8'd0;   
         else         
            avst_tx_swiped_data_d2_0[((r+1)*8)-1:(r*8)] <= (i_port_data_width == 3'd2)? i_axist_tx_tdata[(AVST_DW-(r*8)-1):(AVST_DW-((r+1)*8))] : '0;
      end
end

//reverse 128 bit blocks
for (s=0; s<AVST_DW/32; s=s+1) begin :TX_SOPA_100G_SWAP2 
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) begin 
         if (~i_tx_reset_n_p0)begin
            avst_tx_swiped_data_128_p0[((s+1)*8)-1:s*8]  <= 8'd0; 
         end
         else begin       
            avst_tx_swiped_data_128_p0[((s+1)*8)-1:s*8]  <= (i_port_data_width == 3'd1)? i_axist_tx_tdata[((AVST_DW_BY_FOUR)-(s*8)-1):((AVST_DW_BY_FOUR)-(s+1)*8)] : '0; //7:0 <= 127:120, 127:120<=7:0
         end      
      end      

   if (PORT_PROFILE == "100GAUI-2") begin:SOPA_100G2_DATA_SWAP_TX         
      always @(posedge i_tx_clk_p1 or negedge i_tx_reset_n_p1) begin 
         if (~i_tx_reset_n_p1)begin
            avst_tx_swiped_data_128_p1[((s+1)*8)-1:s*8]  <= 8'd0; 
         end
         else begin       
            avst_tx_swiped_data_128_p1[((s+1)*8)-1:s*8]  <= (i_port_data_width == 3'd1)? i_axist_tx_tdata[((AVST_DW_BY_TWO)-(s*8)-1):((AVST_DW_BY_TWO)-(s+1)*8)] : '0; //7:0 <= 255:248
         end      
      end   
   end   

      always @(posedge i_tx_clk_p2 or negedge i_tx_reset_n_p2) begin 
         if (~i_tx_reset_n_p2)begin
            avst_tx_swiped_data_128_p2[((s+1)*8)-1:s*8]  <= 8'd0; 
         end
         else begin       
            avst_tx_swiped_data_128_p2[((s+1)*8)-1:s*8]  <= (i_port_data_width == 3'd1)? i_axist_tx_tdata[((AVST_DW_BY_TWO)-(s*8)-1):((AVST_DW_BY_TWO)-(s+1)*8)] : '0; //7:0 <= 255:248
         end      
      end         
      
end

//reverse 64 bit blocks
for (t=0; t<8; t=t+1) begin :TX_SOPA_100G_SWAP3
      
      always @(posedge i_tx_clk_p0 or negedge i_tx_reset_n_p0) 
      begin  
         if (~i_tx_reset_n_p0) begin
            avst_tx_swiped_data_64_p0[((t+1)*8)-1:t*8] <= 8'd0;    
         end
         else begin       
            avst_tx_swiped_data_64_p0[((t+1)*8)-1:t*8] <= !(|i_port_data_width)? i_axist_tx_tdata[(AVST_DW_BY_EIGHT-(t*8)-1):((AVST_DW_BY_EIGHT)-(t+1)*8)] : '0;    //7:0, 63: 56
         end      
      end      
      
      always @(posedge i_tx_clk_p1 or negedge i_tx_reset_n_p1) 
      begin  
         if (~i_tx_reset_n_p1) begin
            avst_tx_swiped_data_64_p1[((t+1)*8)-1:t*8] <= 8'd0;
         end
         else begin       
            avst_tx_swiped_data_64_p1[((t+1)*8)-1:t*8] <= !(|i_port_data_width)? i_axist_tx_tdata[(AVST_DW_BY_FOUR-(t*8)-1):((AVST_DW_BY_FOUR)-(t+1)*8)] : '0;    //71:64, 127:120
         end      
      end     

      always @(posedge i_tx_clk_p2 or negedge i_tx_reset_n_p2) 
      begin  
         if (~i_tx_reset_n_p2) begin
            avst_tx_swiped_data_64_p2[((t+1)*8)-1:t*8] <= 8'd0;
         end
         else begin       
            avst_tx_swiped_data_64_p2[((t+1)*8)-1:t*8] <= !(|i_port_data_width)? i_axist_tx_tdata[((3*AVST_DW_BY_EIGHT)-(t*8)-1):((3*AVST_DW_BY_EIGHT)-(t+1)*8)] : '0;    //135:128, 191:184
         end      
      end        

      always @(posedge i_tx_clk_p3 or negedge i_tx_reset_n_p3) 
      begin  
         if (~i_tx_reset_n_p3) begin
            avst_tx_swiped_data_64_p3[((t+1)*8)-1:t*8] <= 8'd0;
         end
         else begin       
            avst_tx_swiped_data_64_p3[((t+1)*8)-1:t*8] <= !(|i_port_data_width)? i_axist_tx_tdata[(AVST_DW_BY_TWO-(t*8)-1):((AVST_DW_BY_TWO)-(t+1)*8)] : '0;    //199:192, 255:248
         end      
      end         
      
end

if (DR_ENABLE == 0) begin: SOPA_PARITY_NON_DR_100G
    assign tx_avst_parity_detect_d1 = (^(i_axist_tx_tdata));
end
else begin: SOPA_PARITY_DR_100G
   if (PORT_PROFILE == "100GCAUI-4") begin:SOPA_PARITY_DETECT_100G4
       assign tx_avst_parity_detect_d1 = (i_port_data_width == 3'd2)? {3'd0,^(i_axist_tx_tdata)}:    //512 bits
                                         (i_port_data_width == 3'd1)? {1'b0, (^i_axist_tx_tdata[255:128]),1'b0,(^i_axist_tx_tdata[127:0])}: //128 bits 2x50,1x50
                                                                      {(^i_axist_tx_tdata[255:192]),(^i_axist_tx_tdata[191:128]),(^i_axist_tx_tdata[127:64]),(^i_axist_tx_tdata[63:0])}; //64 bits 4x25
   end
   else if (PORT_PROFILE == "100GAUI-2") begin:SOPA_PARITY_DETECT_100G2                                                                   
       assign tx_avst_parity_detect_d1 = (i_port_data_width == 3'd2)? {1'b0, (^(i_axist_tx_tdata))}:    //512 bits
                                         (i_port_data_width == 3'd1)? {(^i_axist_tx_tdata[255:128]),(^i_axist_tx_tdata[127:0])}: //128 bits 2x50,1x50
                                                                      {(^i_axist_tx_tdata[127:64]),(^i_axist_tx_tdata[63:0])}; //64 bits 4x25
   
   end
   else begin:SOPA_PARITY_DETECT_100G1                                                            
       assign tx_avst_parity_detect_d1 = (i_port_data_width == 3'd2)? (^(i_axist_tx_tdata)):      //512 bits
                                         (i_port_data_width == 3'd1)? (^i_axist_tx_tdata[127:0]): //128 bits 1x50
                                                                      (^i_axist_tx_tdata[63:0]);  //64 bits 1x25
   end
end

end
else begin:a
   
   assign tx_avst_parity_detect_d1 = {PKT_SEG_PARITY_WIDTH{1'b0}};   
   
end
endgenerate

generate
begin
if (NUM_MAX_PORTS == 1)  begin:DCFIFO_ECC_1P
   if (ENABLE_ECC)
      assign o_fifo_eccstatus = ecc_status0;
   else
      assign o_fifo_eccstatus = 2'd0;
end
else if (NUM_MAX_PORTS == 2) begin:DCFIFO_ECC_2P
   if (ENABLE_ECC)
      // assign o_fifo_eccstatus = (AVST_MODE == "SOP_ALIGNED")? {(ecc_status4 | ecc_status1),ecc_status0}: {ecc_status1,ecc_status0};
      assign o_fifo_eccstatus = {ecc_status1,ecc_status0};
   else
      assign o_fifo_eccstatus = 4'd0;
end
else begin:DCFIFO_ECC_4P
   if (ENABLE_ECC)
      // assign o_fifo_eccstatus = (AVST_MODE == "SOP_ALIGNED")? {(ecc_status4 | ecc_status3),ecc_status2,ecc_status1,ecc_status0}: {ecc_status3,ecc_status2,ecc_status1,ecc_status0};
      assign o_fifo_eccstatus = {ecc_status3,ecc_status2,ecc_status1,ecc_status0};
   else
      assign o_fifo_eccstatus = 8'd0; 
end
end
endgenerate

generate if (AVST_MODE == "SOP_ALIGNED") 
begin: SOPA_FIFO
if (NUM_MAX_PORTS == 1) begin: DCFIFO_1P
      // if (ENABLE_ECC) begin : DCFIFO_WITH_ECC_1P
      hssi_scfifo  # (
         .SIM_EMULATE              (SIM_EMULATE),
         .enable_ecc               (EN_ECC),
         .intended_device_family   ("Agilex"),
         .lpm_hint                 ("RAM_BLOCK_TYPE=M20K"),
         .lpm_width                (FIFO_WIDTH0),
         .lpm_widthu               (FIFO_DEPTH),
         .lpm_numwords             (2**FIFO_DEPTH),
         .lpm_type                 ("scfifo"),
         .lpm_showahead            ("OFF"),
         .overflow_checking        ("OFF"),
         // .rdsync_delaypipe         (4),
         // .wrsync_delaypipe         (4),
         .underflow_checking       ("OFF"),
         // .clocks_are_synchronized  ("TRUE"),         
         .almost_full_value        (FIFO_LEVEL_CHECK),         
         .use_eab                  ("ON")
      ) U_av_st_rdy_lat_fifo_0 (
         .clock                    (i_tx_clk_p0),
         .data                     (fifo_data_in0),
         .wrreq                    (fifo_wrreq0),
         .rdreq                    (avst_tx_ready0 && ~av_st_tx_fifo_empty0), 
         // .rdreq                    (avst_tx_ready0 && ~av_st_tx_fifo_ae0), 
         .empty                    (av_st_tx_fifo_empty0),
         .full                     (),
         .q                        (fifo_data_out0),
         .usedw                    (), //not required avst_tx_fifo_lvl[0]
         .aclr                     (~i_tx_reset_n_p0),
         .almost_empty             (av_st_tx_fifo_ae0),
         .almost_full              (av_st_tx_fifo_af[0]),
         .eccstatus                (ecc_status0),
         .sclr                     (1'b0),
         .flag                     (av_st_tx_fifo_flag0)
         );
    end
    
else if (NUM_MAX_PORTS == 2) begin :DCFIFO_2P
      // if (ENABLE_ECC) begin : DCFIFO_WITH_ECC_2P       
      hssi_scfifo  # (                      
         .SIM_EMULATE              (SIM_EMULATE),
         .enable_ecc               (EN_ECC),
         .intended_device_family   ("Agilex"),
         .lpm_hint                 ("RAM_BLOCK_TYPE=M20K"),
         .lpm_width                (FIFO_WIDTH0),
         .lpm_widthu               (FIFO_DEPTH),
         .lpm_numwords             (2**FIFO_DEPTH),
         .lpm_type                 ("scfifo"),
         .lpm_showahead            ("OFF"),
         .overflow_checking        ("OFF"),
         .underflow_checking       ("OFF"), 
         .almost_full_value        (FIFO_LEVEL_CHECK),         
         .use_eab                  ("ON")
         ) U_av_st_rdy_lat_fifo_0 (
         .clock                    (i_tx_clk_p0),
         .data                     (fifo_data_in0),
         .wrreq                    (fifo_wrreq0),
         .rdreq                    (avst_tx_ready0 && ~av_st_tx_fifo_empty0), 
         .empty                    (av_st_tx_fifo_empty0),
         .full                     (),
         .q                        (fifo_data_out0),
         .usedw                    (), 
         .aclr                     (~i_tx_reset_n_p0),
         .almost_empty             (av_st_tx_fifo_ae0),
         .almost_full              (av_st_tx_fifo_af[0]),
         .eccstatus                (ecc_status0),
         .sclr                     (1'b0),
         .flag                     (av_st_tx_fifo_flag0)         
         );
         
      hssi_scfifo  # (                                 
         .SIM_EMULATE              (SIM_EMULATE),
         .enable_ecc               (EN_ECC),
         .intended_device_family   ("Agilex"),
         .lpm_hint                 ("RAM_BLOCK_TYPE=M20K"),
         .lpm_width                (FIFO_WIDTH1),
         .lpm_widthu               (FIFO_DEPTH),
         .lpm_numwords             (2**FIFO_DEPTH),
         .lpm_type                 ("scfifo"),
         .lpm_showahead            ("OFF"),
         .overflow_checking        ("OFF"),
         .underflow_checking       ("OFF"), 
         .almost_full_value        (FIFO_LEVEL_CHECK),         
         .use_eab                  ("ON")
         ) U_av_st_rdy_lat_fifo_1 (
         .clock                    (i_tx_clk_p1),
         .data                     (fifo_data_in1),
         .wrreq                    (fifo_wrreq1),
         .rdreq                    (avst_tx_ready1 && ~av_st_tx_fifo_empty1), 
         .empty                    (av_st_tx_fifo_empty1),
         .full                     (),
         .q                        (fifo_data_out1),
         .usedw                    (), 
         .aclr                     (~i_tx_reset_n_p1),
         .almost_empty             (av_st_tx_fifo_ae1),
         .almost_full              (av_st_tx_fifo_af[1]),
         .eccstatus                (ecc_status1),
         .sclr                     (1'b0),
         .flag                     (av_st_tx_fifo_flag1)         
         );

end

else begin: DCFIFO_4P
 //if {NUM_MAX_PORTS == 4} {
      // if (ENABLE_ECC == 1) begin : DCFIFO_WITH_ECC_4P
      hssi_scfifo  # (                      
         .SIM_EMULATE              (SIM_EMULATE),
         .enable_ecc               (EN_ECC),
         .intended_device_family   ("Agilex"),
         .lpm_hint                 ("RAM_BLOCK_TYPE=M20K"),
         .lpm_width                (FIFO_WIDTH0),
         .lpm_widthu               (FIFO_DEPTH),
         .lpm_numwords             (2**FIFO_DEPTH),
         .lpm_type                 ("scfifo"),
         .lpm_showahead            ("OFF"),
         .overflow_checking        ("OFF"),
         .underflow_checking       ("OFF"), 
         .almost_full_value        (FIFO_LEVEL_CHECK),         
         .use_eab                  ("ON")
         ) U_av_st_rdy_lat_fifo_0 (
         .clock                    (i_tx_clk_p0),
         .data                     (fifo_data_in0),
         .wrreq                    (fifo_wrreq0),
         .rdreq                    (avst_tx_ready0 && ~av_st_tx_fifo_empty0), //delay this
         .empty                    (av_st_tx_fifo_empty0),
         .full                     (),
         .q                        (fifo_data_out0),
         .usedw                    (), 
         .aclr                     (~i_tx_reset_n_p0),
         .almost_empty             (av_st_tx_fifo_ae0),
         .almost_full              (av_st_tx_fifo_af[0]),
         .eccstatus                (ecc_status0),
         .sclr                     (1'b0),
         .flag                     (av_st_tx_fifo_flag0)         
         );

      hssi_scfifo  # (                                 
         .SIM_EMULATE              (SIM_EMULATE),
         .enable_ecc               (EN_ECC),
         .intended_device_family   ("Agilex"),
         .lpm_hint                 ("RAM_BLOCK_TYPE=M20K"),
         .lpm_width                (FIFO_WIDTH1),
         .lpm_widthu               (FIFO_DEPTH),
         .lpm_numwords             (2**FIFO_DEPTH),
         .lpm_type                 ("scfifo"),
         .lpm_showahead            ("OFF"),
         .overflow_checking        ("OFF"),
         .underflow_checking       ("OFF"), 
         .almost_full_value        (FIFO_LEVEL_CHECK),         
         .use_eab                  ("ON")
         ) U_av_st_rdy_lat_fifo_1 (
         .clock                    (i_tx_clk_p1),
         .data                     (fifo_data_in1),
         .wrreq                    (fifo_wrreq1),
         .rdreq                    (avst_tx_ready1 && ~av_st_tx_fifo_empty1), //delay this
         .empty                    (av_st_tx_fifo_empty1),
         .full                     (),
         .q                        (fifo_data_out1),
         .usedw                    (), 
         .aclr                     (~i_tx_reset_n_p1),
         .almost_empty             (av_st_tx_fifo_ae1),
         .almost_full              (av_st_tx_fifo_af[1]),
         .eccstatus                (ecc_status1),
         .sclr                     (1'b0),
         .flag                     (av_st_tx_fifo_flag1)         
         );
      
      hssi_scfifo  # (                                 
         .SIM_EMULATE              (SIM_EMULATE),
         .enable_ecc               (EN_ECC),
         .intended_device_family   ("Agilex"),
         .lpm_hint                 ("RAM_BLOCK_TYPE=M20K"),
         .lpm_width                (FIFO_WIDTH2),
         .lpm_widthu               (FIFO_DEPTH),
         .lpm_numwords             (2**FIFO_DEPTH),
         .lpm_type                 ("scfifo"),
         .lpm_showahead            ("OFF"),
         .overflow_checking        ("OFF"),
         .underflow_checking       ("OFF"), 
         .almost_full_value        (FIFO_LEVEL_CHECK),         
         .use_eab                  ("ON")
         ) U_av_st_rdy_lat_fifo_2 (
         .clock                    (i_tx_clk_p2),
         .data                     (fifo_data_in2),
         .wrreq                    (fifo_wrreq2),
         .rdreq                    (avst_tx_ready2 && ~av_st_tx_fifo_empty2), //delay this
         .empty                    (av_st_tx_fifo_empty2),
         .full                     (),
         .q                        (fifo_data_out2),
         .usedw                    (), 
         .aclr                     (~i_tx_reset_n_p2),
         .almost_empty             (av_st_tx_fifo_ae2),
         .almost_full              (av_st_tx_fifo_af[2]),
         .eccstatus                (ecc_status2),
         .sclr                     (1'b0),
         .flag                     (av_st_tx_fifo_flag2)         
         );
 
      hssi_scfifo  # (                                 
         .SIM_EMULATE              (SIM_EMULATE),
         .enable_ecc               (EN_ECC),
         .intended_device_family   ("Agilex"),
         .lpm_hint                 ("RAM_BLOCK_TYPE=M20K"),
         .lpm_width                (FIFO_WIDTH3),
         .lpm_widthu               (FIFO_DEPTH),
         .lpm_numwords             (2**FIFO_DEPTH),
         .lpm_type                 ("scfifo"),
         .lpm_showahead            ("OFF"),
         .overflow_checking        ("OFF"),
         .underflow_checking       ("OFF"), 
         .almost_full_value        (FIFO_LEVEL_CHECK),         
         .use_eab                  ("ON")
         ) U_av_st_rdy_lat_fifo_3 (
         .clock                    (i_tx_clk_p3),
         .data                     (fifo_data_in3),
         .wrreq                    (fifo_wrreq3),
         .rdreq                    (avst_tx_ready3 && ~av_st_tx_fifo_empty3), //delay this
         .empty                    (av_st_tx_fifo_empty3),
         .full                     (),
         .q                        (fifo_data_out3),
         .usedw                    (), 
         .aclr                     (~i_tx_reset_n_p3),
         .almost_empty             (av_st_tx_fifo_ae3),
         .almost_full              (av_st_tx_fifo_af[3]),
         .eccstatus                (ecc_status3),
         .sclr                     (1'b0),
         .flag                     (av_st_tx_fifo_flag3)         
         );
end

end
else begin : MS_FIFO

if (NUM_MAX_PORTS == 1) begin: DCFIFO_1P
      // if (ENABLE_ECC) begin : DCFIFO_WITH_ECC_1P
      hssi_scfifo  # (
         .SIM_EMULATE              (SIM_EMULATE),
         .enable_ecc               (EN_ECC),
         .intended_device_family   ("Agilex"),
         .lpm_hint                 ("RAM_BLOCK_TYPE=M20K"),
         .lpm_width                (FIFO_WIDTH0),
         .lpm_widthu               (FIFO_DEPTH),
         .lpm_numwords             (2**FIFO_DEPTH),
         .lpm_type                 ("scfifo"),
         .lpm_showahead            ("OFF"),
         .overflow_checking        ("OFF"),
         // .rdsync_delaypipe         (4),
         // .wrsync_delaypipe         (4),
         .underflow_checking       ("OFF"),
         // .clocks_are_synchronized  ("TRUE"),         
         .almost_full_value        (FIFO_LEVEL_CHECK),         
         .use_eab                  ("ON")
      ) U_av_st_rdy_lat_fifo_0 (
         .clock                    (i_tx_clk_p0),
         .data                     (fifo_data_in0),
         .wrreq                    (fifo_wrreq0),
         .rdreq                    (avst_tx_ready0 && ~av_st_tx_fifo_empty0), 
         // .rdreq                    (avst_tx_ready0 && ~av_st_tx_fifo_ae0), 
         .empty                    (av_st_tx_fifo_empty0),
         .full                     (),
         .q                        (fifo_data_out0),
         .usedw                    (), //not required avst_tx_fifo_lvl[0]
         .aclr                     (~i_tx_reset_n_p0),
         .almost_empty             (av_st_tx_fifo_ae0),
         .almost_full              (av_st_tx_fifo_af[0]),
         .eccstatus                (ecc_status0),
         .sclr                     (1'b0),
         .flag                     (av_st_tx_fifo_flag0)
         );
    end
    
else if (NUM_MAX_PORTS == 2) begin :DCFIFO_2P
      // if (ENABLE_ECC) begin : DCFIFO_WITH_ECC_2P       
      hssi_scfifo  # (                      
         .SIM_EMULATE              (SIM_EMULATE),
         .enable_ecc               (EN_ECC),
         .intended_device_family   ("Agilex"),
         .lpm_hint                 ("RAM_BLOCK_TYPE=M20K"),
         .lpm_width                (FIFO_WIDTH0),
         .lpm_widthu               (FIFO_DEPTH),
         .lpm_numwords             (2**FIFO_DEPTH),
         .lpm_type                 ("scfifo"),
         .lpm_showahead            ("OFF"),
         .overflow_checking        ("OFF"),
         .underflow_checking       ("OFF"), 
         .almost_full_value        (FIFO_LEVEL_CHECK),         
         .use_eab                  ("ON")
         ) U_av_st_rdy_lat_fifo_0 (
         .clock                    (i_tx_clk_p0),
         .data                     (fifo_data_in0),
         .wrreq                    (fifo_wrreq0),
         .rdreq                    (avst_tx_ready0 && ~av_st_tx_fifo_empty0), 
         .empty                    (av_st_tx_fifo_empty0),
         .full                     (),
         .q                        (fifo_data_out0),
         .usedw                    (), 
         .aclr                     (~i_tx_reset_n_p0),
         .almost_empty             (av_st_tx_fifo_ae0),
         .almost_full              (av_st_tx_fifo_af[0]),
         .eccstatus                (ecc_status0),
         .sclr                     (1'b0),
         .flag                     (av_st_tx_fifo_flag0)         
         );
         
      hssi_scfifo  # (                                 
         .SIM_EMULATE              (SIM_EMULATE),
         .enable_ecc               (EN_ECC),
         .intended_device_family   ("Agilex"),
         .lpm_hint                 ("RAM_BLOCK_TYPE=M20K"),
         .lpm_width                (FIFO_WIDTH1),
         .lpm_widthu               (FIFO_DEPTH),
         .lpm_numwords             (2**FIFO_DEPTH),
         .lpm_type                 ("scfifo"),
         .lpm_showahead            ("OFF"),
         .overflow_checking        ("OFF"),
         .underflow_checking       ("OFF"), 
         .almost_full_value        (FIFO_LEVEL_CHECK),         
         .use_eab                  ("ON")
         ) U_av_st_rdy_lat_fifo_1 (
         .clock                    (i_tx_clk_p0),
         .data                     (fifo_data_in1),
         .wrreq                    (fifo_wrreq1),
         .rdreq                    (avst_tx_ready1 && ~av_st_tx_fifo_empty1), 
         .empty                    (av_st_tx_fifo_empty1),
         .full                     (),
         .q                        (fifo_data_out1),
         .usedw                    (), 
         .aclr                     (~i_tx_reset_n_p1),
         .almost_empty             (av_st_tx_fifo_ae1),
         .almost_full              (av_st_tx_fifo_af[1]),
         .eccstatus                (ecc_status1),
         .sclr                     (1'b0),
         .flag                     (av_st_tx_fifo_flag1)         
         );

end

else begin: DCFIFO_4P
 //if {NUM_MAX_PORTS == 4} {
      // if (ENABLE_ECC == 1) begin : DCFIFO_WITH_ECC_4P
      hssi_scfifo  # (                      
         .SIM_EMULATE              (SIM_EMULATE),
         .enable_ecc               (EN_ECC),
         .intended_device_family   ("Agilex"),
         .lpm_hint                 ("RAM_BLOCK_TYPE=M20K"),
         .lpm_width                (FIFO_WIDTH0),
         .lpm_widthu               (FIFO_DEPTH),
         .lpm_numwords             (2**FIFO_DEPTH),
         .lpm_type                 ("scfifo"),
         .lpm_showahead            ("OFF"),
         .overflow_checking        ("OFF"),
         .underflow_checking       ("OFF"), 
         .almost_full_value        (FIFO_LEVEL_CHECK),         
         .use_eab                  ("ON")
         ) U_av_st_rdy_lat_fifo_0 (
         .clock                    (i_tx_clk_p0),
         .data                     (fifo_data_in0),
         .wrreq                    (fifo_wrreq0),
         .rdreq                    (avst_tx_ready0 && ~av_st_tx_fifo_empty0), //delay this
         .empty                    (av_st_tx_fifo_empty0),
         .full                     (),
         .q                        (fifo_data_out0),
         .usedw                    (), 
         .aclr                     (~i_tx_reset_n_p0),
         .almost_empty             (av_st_tx_fifo_ae0),
         .almost_full              (av_st_tx_fifo_af[0]),
         .eccstatus                (ecc_status0),
         .sclr                     (1'b0),
         .flag                     (av_st_tx_fifo_flag0)         
         );

      hssi_scfifo  # (                                 
         .SIM_EMULATE              (SIM_EMULATE),
         .enable_ecc               (EN_ECC),
         .intended_device_family   ("Agilex"),
         .lpm_hint                 ("RAM_BLOCK_TYPE=M20K"),
         .lpm_width                (FIFO_WIDTH1),
         .lpm_widthu               (FIFO_DEPTH),
         .lpm_numwords             (2**FIFO_DEPTH),
         .lpm_type                 ("scfifo"),
         .lpm_showahead            ("OFF"),
         .overflow_checking        ("OFF"),
         .underflow_checking       ("OFF"), 
         .almost_full_value        (FIFO_LEVEL_CHECK),         
         .use_eab                  ("ON")
         ) U_av_st_rdy_lat_fifo_1 (
         .clock                    (i_tx_clk_p0),
         .data                     (fifo_data_in1),
         .wrreq                    (fifo_wrreq1),
         .rdreq                    (avst_tx_ready1 && ~av_st_tx_fifo_empty1), //delay this
         .empty                    (av_st_tx_fifo_empty1),
         .full                     (),
         .q                        (fifo_data_out1),
         .usedw                    (), 
         .aclr                     (~i_tx_reset_n_p1),
         .almost_empty             (av_st_tx_fifo_ae1),
         .almost_full              (av_st_tx_fifo_af[1]),
         .eccstatus                (ecc_status1),
         .sclr                     (1'b0),
         .flag                     (av_st_tx_fifo_flag1)         
         );
      
      hssi_scfifo  # (                                 
         .SIM_EMULATE              (SIM_EMULATE),
         .enable_ecc               (EN_ECC),
         .intended_device_family   ("Agilex"),
         .lpm_hint                 ("RAM_BLOCK_TYPE=M20K"),
         .lpm_width                (FIFO_WIDTH2),
         .lpm_widthu               (FIFO_DEPTH),
         .lpm_numwords             (2**FIFO_DEPTH),
         .lpm_type                 ("scfifo"),
         .lpm_showahead            ("OFF"),
         .overflow_checking        ("OFF"),
         .underflow_checking       ("OFF"), 
         .almost_full_value        (FIFO_LEVEL_CHECK),         
         .use_eab                  ("ON")
         ) U_av_st_rdy_lat_fifo_2 (
         .clock                    (i_tx_clk_p0),
         .data                     (fifo_data_in2),
         .wrreq                    (fifo_wrreq2),
         .rdreq                    (avst_tx_ready2 && ~av_st_tx_fifo_empty2), //delay this
         .empty                    (av_st_tx_fifo_empty2),
         .full                     (),
         .q                        (fifo_data_out2),
         .usedw                    (), 
         .aclr                     (~i_tx_reset_n_p2),
         .almost_empty             (av_st_tx_fifo_ae2),
         .almost_full              (av_st_tx_fifo_af[2]),
         .eccstatus                (ecc_status2),
         .sclr                     (1'b0),
         .flag                     (av_st_tx_fifo_flag2)         
         );
 
      hssi_scfifo  # (                                 
         .SIM_EMULATE              (SIM_EMULATE),
         .enable_ecc               (EN_ECC),
         .intended_device_family   ("Agilex"),
         .lpm_hint                 ("RAM_BLOCK_TYPE=M20K"),
         .lpm_width                (FIFO_WIDTH3),
         .lpm_widthu               (FIFO_DEPTH),
         .lpm_numwords             (2**FIFO_DEPTH),
         .lpm_type                 ("scfifo"),
         .lpm_showahead            ("OFF"),
         .overflow_checking        ("OFF"),
         .underflow_checking       ("OFF"), 
         .almost_full_value        (FIFO_LEVEL_CHECK),         
         .use_eab                  ("ON")
         ) U_av_st_rdy_lat_fifo_3 (
         .clock                    (i_tx_clk_p0),
         .data                     (fifo_data_in3),
         .wrreq                    (fifo_wrreq3),
         .rdreq                    (avst_tx_ready3 && ~av_st_tx_fifo_empty3), //delay this
         .empty                    (av_st_tx_fifo_empty3),
         .full                     (),
         .q                        (fifo_data_out3),
         .usedw                    (), 
         .aclr                     (~i_tx_reset_n_p3),
         .almost_empty             (av_st_tx_fifo_ae3),
         .almost_full              (av_st_tx_fifo_af[3]),
         .eccstatus                (ecc_status3),
         .sclr                     (1'b0),
         .flag                     (av_st_tx_fifo_flag3)         
         );


end
end
endgenerate

endmodule
