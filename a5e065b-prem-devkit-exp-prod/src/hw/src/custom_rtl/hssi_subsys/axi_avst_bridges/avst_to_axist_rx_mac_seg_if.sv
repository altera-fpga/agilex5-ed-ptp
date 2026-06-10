//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


// ==========================================================================
// Project           : HSSI Subsystem 
// Module            : avst_to_axist_rx_mac_seg_if.sv
// Description       : 
// Author            : 
// Created           : 
// Changes           : 
//                   : 
// ==========================================================================

// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

module avst_to_axist_rx_mac_seg_if #(
    parameter SIM_EMULATE           = 1,
    parameter AVST_MODE             = "MAC_SEGMENTED",
    parameter AVST_DW               = 64,
    parameter PORT_PROFILE          = "400GBE",
    parameter NUM_SEG               = (AVST_MODE == "SOP_ALIGNED")?1:(AVST_DW/64),         //8 bytes per segment
    parameter EMPTY_BITS            = (AVST_MODE == "SOP_ALIGNED")? $clog2(AVST_DW/8) : 3, //3*num_seg for mac seg, SOP DR - 25-2:0,50-5:0,100-11:0, SOP Non DR 25-2:0,50-3:0,100-5:0
    parameter AVST_USER             = 2, 
    // parameter AXI_MODE           = "MULTI_PACKET", 
    parameter AXI_DW                = 64,
    parameter NO_OF_BYTES           = AXI_DW/8, 
    parameter TUSER                 = 2, 
    parameter NUM_MAX_PORTS         = 4,  
    parameter PKT_SEG_PARITY_EN     = 0,  
    parameter PKT_SEG_PARITY_WIDTH  = 4,         //macseg - [NUM_SEG-1:0], sopa - [(NUM_MAX_PORTS-1:0]
    parameter DR_ENABLE             = 1         
) ( 
    input                                     i_rx_clk_p0, 
    input                                     i_rx_clk_p1, 
    input                                     i_rx_clk_p2, 
    input                                     i_rx_clk_p3, 
    input                                     i_rx_reset_n_p0,
    input                                     i_rx_reset_n_p1,
    input                                     i_rx_reset_n_p2,
    input                                     i_rx_reset_n_p3,
    //CSR
    input      [NUM_MAX_PORTS-1:0]            i_port_active_mask,       //current profile parameters based on profile_sel_reg
    input      [2:0]                          i_active_ports,           //current profile parameters based on profile_sel_reg 
    input      [2:0]                          i_active_segments,        //current profile parameters based on profile_sel_reg - valid for mac seg only
    input      [2:0]                          i_port_data_width,        //current profile parameters based on profile_sel_reg - valid for sopa only
                        
    //Avalon Stream Rx, MAC side interface    
    input      [NUM_MAX_PORTS-1:0]            i_avst_rx_valid,
    input      [AVST_DW-1:0]                  i_avst_rx_data,
    input      [NUM_SEG-1:0]                  i_avst_rx_inframe,
    input      [NUM_SEG*EMPTY_BITS-1:0]       i_avst_rx_eop_empty,
    input      [NUM_MAX_PORTS*AVST_USER-1:0]  i_avst_rx_user,
    input      [NUM_MAX_PORTS-1:0]            i_avst_rx_startofpacket,
    input      [NUM_MAX_PORTS-1:0]            i_avst_rx_endofpacket,
                                            
    //AXI Stream Rx, User side interface           
    output reg [NUM_MAX_PORTS-1:0]            o_axist_rx_tvalid,
    output     [AXI_DW-1:0]                   o_axist_rx_tdata,
    output     [NUM_SEG-1:0]                  o_axist_rx_tlast_segment,
    output     [NO_OF_BYTES-1:0]              o_axist_rx_tkeep,
    output reg [NUM_SEG*8-1:0]                o_axist_rx_tkeep_segment,
    output reg [NUM_MAX_PORTS-1:0]            o_axist_rx_tlast,
    output     [NUM_MAX_PORTS*TUSER-1:0]      o_axist_rx_tuser,
    output reg [NUM_MAX_PORTS-1:0]            o_axist_rx_tuser_valid,
    output reg [NUM_MAX_PORTS-1:0]            o_axist_rx_tuser_valid_p2,
    output reg [PKT_SEG_PARITY_WIDTH-1:0]     o_axist_rx_pkt_seg_parity 
);

//***********************************************************
//***********************************************************

localparam NUM_SEG_BY_TWO       = NUM_SEG/2;
localparam NUM_SEG_BY_FOUR      = NUM_SEG/4;
localparam NUM_SEG_BY_FOURX3    = 3*(NUM_SEG/4);
localparam AVST_DW_BY_TWO       = AVST_DW/2;
localparam AVST_DW_BY_FOUR      = AVST_DW/4;
localparam AVST_DW_BY_EIGHT     = AVST_DW/8;
localparam NUM_SEG_BY_TWOXEB    = (NUM_SEG/2)*EMPTY_BITS;
localparam NUM_SEGXEB           = NUM_SEG*EMPTY_BITS;
localparam NUM_SEG_BY_FOURXEB   = (NUM_SEG/4)*EMPTY_BITS;
localparam NUM_SEG_BY_FOURXEBX3 = 3*(NUM_SEG/4)*EMPTY_BITS;

localparam AVST_DW_BY_FOURX3    = 3*(AVST_DW/4);
localparam AVST_DW_BY_EIGHTX3   = 3*(AVST_DW/8);

localparam AVST_DW_P1 = (AVST_MODE == "MAC_SEGMENTED")? ((NUM_MAX_PORTS == 4)? AVST_DW_BY_FOUR : AVST_DW_BY_TWO):
                                                        ((NUM_MAX_PORTS == 4)? AVST_DW_BY_EIGHT : AVST_DW_BY_FOUR);
                                             
localparam AVST_DW_P2 = (AVST_MODE == "MAC_SEGMENTED")? AVST_DW_BY_TWO : AVST_DW_BY_FOUR;   

localparam AVST_DW_P3 = (AVST_MODE == "MAC_SEGMENTED")? AVST_DW_BY_FOUR : AVST_DW_BY_EIGHT; 

    reg        [NUM_SEG-1:0]                  tlast_segment_d1;
    reg        [7:0]                          tkeep_d6;
    reg        [15:0]                         tkeep_d7;
                                              
    reg        [NUM_MAX_PORTS-1:0]            axist_rx_tlast_d1;
    reg        [NUM_MAX_PORTS-1:0]            axist_rx_tuser_valid_d1;

    reg                                       avst_rx_ms_valid_d1_p0;
    reg                                       avst_rx_ms_valid_d1_p1;
    reg                                       avst_rx_ms_valid_d1_p2;
    reg                                       avst_rx_ms_valid_d1_p3;
    reg        [AVST_DW-1:0]                  avst_rx_data_d1;
                                              
    reg        [NUM_SEG*EMPTY_BITS-1:0]       avst_rx_eop_empty_d1_p0;
    reg        [NUM_SEG*EMPTY_BITS-1:0]       avst_rx_eop_empty_d1_p1;
    reg        [NUM_SEG*EMPTY_BITS-1:0]       avst_rx_eop_empty_d1_p2;
    reg        [NUM_SEG*EMPTY_BITS-1:0]       avst_rx_eop_empty_d1_p3;
                                              
    reg        [AVST_DW-1:0]                  avst_rx_swiped_data_d2_0;       
                                              
    reg        [NUM_SEG-1:0]                  avst_rx_eop_d1_p0;
    reg        [NUM_SEG-1:0]                  avst_rx_eop_d1_p1;
    reg        [NUM_SEG-1:0]                  avst_rx_eop_d1_p2;
    reg        [NUM_SEG-1:0]                  avst_rx_eop_d1_p3;
                                              
    reg        [NUM_SEG-1:0]                  avst_rx_sop_d1_p0;
    reg        [NUM_SEG-1:0]                  avst_rx_sop_d1_p1;
    reg        [NUM_SEG-1:0]                  avst_rx_sop_d1_p2;
    reg        [NUM_SEG-1:0]                  avst_rx_sop_d1_p3;
                                              
    reg        [NUM_SEG-1:0]                  tlast_segment_d1_p0;
    reg        [NUM_SEG-1:0]                  tlast_segment_d1_p1;
    reg        [NUM_SEG-1:0]                  tlast_segment_d1_p2;
    reg        [NUM_SEG-1:0]                  tlast_segment_d1_p3;

    reg        [NUM_SEG-1:0]                  tlast_segment_d2_p0;
    reg        [NUM_SEG-1:0]                  tlast_segment_d2_p1;
    reg        [NUM_SEG-1:0]                  tlast_segment_d2_p2;
    reg        [NUM_SEG-1:0]                  tlast_segment_d2_p3;  
                                                  
    reg        [NUM_SEG*8-1:0]                axist_rx_tkeep_segment_p0;
    reg        [NUM_SEG*8-1:0]                axist_rx_tkeep_segment_p1;
    reg        [NUM_SEG*8-1:0]                axist_rx_tkeep_segment_p2;
    reg        [NUM_SEG*8-1:0]                axist_rx_tkeep_segment_p3;
                                              
    logic      [AVST_DW-1:0]                  axist_rx_data;
    
    logic      [PKT_SEG_PARITY_WIDTH-1:0]     rx_parity_detect;
    reg        [NUM_SEG-1:0]                  avst_rx_inframe_p0 ;
    reg        [NUM_SEG-1:0]                  avst_rx_inframe_p1 ;
    reg        [NUM_SEG-1:0]                  avst_rx_inframe_p2 ;
    reg        [NUM_SEG-1:0]                  avst_rx_inframe_p3;   
    reg        [NUM_SEG-1:0]                  avst_rx_inframe_p0_d1 ;
    reg        [NUM_SEG-1:0]                  avst_rx_inframe_p1_d1 ;
    reg        [NUM_SEG-1:0]                  avst_rx_inframe_p2_d1 ;
    reg        [NUM_SEG-1:0]                  avst_rx_inframe_p3_d1 ;
    
    reg        [NO_OF_BYTES-1:0]              tkeep_d4;
    reg        [NO_OF_BYTES/2-1:0]            tkeep_d2;
    reg        [NO_OF_BYTES/2-1:0]            tkeep_d3; 
    reg        [NO_OF_BYTES/4-1:0]            tkeep_d5; 
    
    reg        [4:0]                          active_segments; 
    
    reg        [AVST_DW_BY_FOUR-1:0]          avst_rx_swiped_data_128_p0;
    reg        [AVST_DW_BY_FOUR-1:0]          avst_rx_swiped_data_128_p1;
    reg        [AVST_DW_BY_FOUR-1:0]          avst_rx_swiped_data_128_p2;
               
    reg        [63:0]                         avst_rx_swiped_data_64_p0;  //used in 50GAUI and 100GAUI 
    reg        [AVST_DW_BY_EIGHT-1:0]         avst_rx_swiped_data_64_p1;
    reg        [AVST_DW_BY_EIGHT-1:0]         avst_rx_swiped_data_64_p2;
    reg        [AVST_DW_BY_EIGHT-1:0]         avst_rx_swiped_data_64_p3;    
    
    reg                                       avst_rx_valid_d1_p0;
    reg                                       avst_rx_valid_d1_p1;
    reg                                       avst_rx_valid_d1_p2;
    reg                                       avst_rx_valid_d1_p3;
    
    reg        [AVST_DW-1:0]                  avst_rx_data_d1_p0;
    reg        [AVST_DW_P1-1:0]               avst_rx_data_d1_p1;
    reg        [AVST_DW_P2-1:0]               avst_rx_data_d1_p2;
    reg        [AVST_DW_P3-1:0]               avst_rx_data_d1_p3;
    
    reg        [AVST_DW-1:0]                  avst_rx_data_d2_p0; //Only used for MAC SEG. Bit widths are correct
    reg        [AVST_DW_P1-1:0]               avst_rx_data_d2_p1;
    reg        [AVST_DW_P2-1:0]               avst_rx_data_d2_p2;
    reg        [AVST_DW_P3-1:0]               avst_rx_data_d2_p3;
    
    reg        [TUSER-1:0]                    avst_rx_user_d1_p0;
    reg        [TUSER-1:0]                    avst_rx_user_d1_p1;
    reg        [TUSER-1:0]                    avst_rx_user_d1_p2;
    reg        [TUSER-1:0]                    avst_rx_user_d1_p3;
    
    reg        [TUSER-1:0]                    avst_rx_user_d2_p0;
    reg        [TUSER-1:0]                    avst_rx_user_d2_p1;   
    reg        [TUSER-1:0]                    avst_rx_user_d2_p2;   
    reg        [TUSER-1:0]                    avst_rx_user_d2_p3;   
    
    reg        [NO_OF_BYTES-1:0]              tkeep_d4_d1;
    reg        [NO_OF_BYTES/2-1:0]            tkeep_d2_d1;
    reg        [NO_OF_BYTES/2-1:0]            tkeep_d3_d1; 
    reg        [NO_OF_BYTES/4-1:0]            tkeep_d5_d1;  
    reg        [7:0]                          tkeep_d6_d1;
    reg        [15:0]                         tkeep_d7_d1;                                           

generate if (AVST_MODE == "MAC_SEGMENTED")
begin : RX_MS_TVALID_MUX                             
   
   if (NUM_MAX_PORTS == 4) begin: RX_TVALID_MUX_4P
      
      assign o_axist_rx_tuser = {avst_rx_user_d2_p3,avst_rx_user_d2_p2,avst_rx_user_d2_p1,avst_rx_user_d2_p0};
   
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
          if (~i_rx_reset_n_p0) begin
              avst_rx_valid_d1_p0             <= 1'b0;
              avst_rx_user_d1_p0              <= '0;  
              avst_rx_user_d2_p0              <= '0;              
          end
          else begin
              avst_rx_valid_d1_p0             <= i_avst_rx_valid[0];           
              avst_rx_user_d1_p0              <= i_avst_rx_user[AVST_USER-1:0];
              avst_rx_user_d2_p0              <= avst_rx_user_d1_p0;              
          end
      end
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1) 
      begin
          if (~i_rx_reset_n_p1) begin
              avst_rx_valid_d1_p1             <= 1'b0;
              avst_rx_user_d1_p1              <= '0;  
              avst_rx_user_d2_p1              <= '0;              
          end
          else begin
              avst_rx_valid_d1_p1             <= i_avst_rx_valid[1];           
              avst_rx_user_d1_p1              <= i_avst_rx_user[(2*AVST_USER)-1:AVST_USER];
              avst_rx_user_d2_p1              <= avst_rx_user_d1_p1;              
          end
      end    
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p2) 
      begin
          if (~i_rx_reset_n_p2) begin
              avst_rx_valid_d1_p2             <= 1'b0;
              avst_rx_user_d1_p2              <= '0;  
              avst_rx_user_d2_p2              <= '0;              
          end
          else begin
              avst_rx_valid_d1_p2             <= i_avst_rx_valid[2];           
              avst_rx_user_d1_p2              <= i_avst_rx_user[(3*AVST_USER)-1:(2*AVST_USER)];
              avst_rx_user_d2_p2              <= avst_rx_user_d1_p2;              
          end
      end     
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p3) 
      begin
          if (~i_rx_reset_n_p3) begin
              avst_rx_valid_d1_p3             <= 1'b0;
              avst_rx_user_d1_p3              <= '0;  
              avst_rx_user_d2_p3              <= '0;              
          end
          else begin
              avst_rx_valid_d1_p3             <= i_avst_rx_valid[3];           
              avst_rx_user_d1_p3              <= i_avst_rx_user[(4*AVST_USER)-1:(3*AVST_USER)];
              avst_rx_user_d2_p3              <= avst_rx_user_d1_p3;              
          end
      end      
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
      begin
         if (~i_rx_reset_n_p0) begin
             o_axist_rx_tvalid[0]         <= 1'b0;
         end
         else begin
             o_axist_rx_tvalid[0]         <= avst_rx_ms_valid_d1_p0;                                                                                    
         end
      end   
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1)
      begin 
         if (~i_rx_reset_n_p1) begin
             o_axist_rx_tvalid[1]         <= 1'b0;
         end
         else begin
             o_axist_rx_tvalid[1]         <= avst_rx_ms_valid_d1_p1;                                                                                    
         end
      end       

      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p2)
      begin 
         if (~i_rx_reset_n_p2) begin
             o_axist_rx_tvalid[2]         <= 1'b0;
         end
         else begin
             o_axist_rx_tvalid[2]         <= avst_rx_ms_valid_d1_p2;                                                                                    
         end
      end   

      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p3)
      begin 
         if (~i_rx_reset_n_p3) begin
             o_axist_rx_tvalid[3]         <= 1'b0;
         end
         else begin
             o_axist_rx_tvalid[3]         <= avst_rx_ms_valid_d1_p3;                                                                                    
         end
      end             
      
   end   
   
   else if (NUM_MAX_PORTS == 2) begin: RX_TVALID_MUX_2P
    
      assign o_axist_rx_tuser = {avst_rx_user_d2_p1,avst_rx_user_d2_p0};
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
          if (~i_rx_reset_n_p0) begin
              avst_rx_valid_d1_p0             <= 1'b0;
              avst_rx_user_d1_p0              <= '0;  
              avst_rx_user_d2_p0              <= '0;              
          end
          else begin
              avst_rx_valid_d1_p0             <= i_avst_rx_valid[0];           
              avst_rx_user_d1_p0              <= i_avst_rx_user[AVST_USER-1:0];
              avst_rx_user_d2_p0              <= avst_rx_user_d1_p0;              
          end
      end
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1) 
      begin
          if (~i_rx_reset_n_p1) begin
              avst_rx_valid_d1_p1             <= 1'b0;
              avst_rx_user_d1_p1              <= '0;  
              avst_rx_user_d2_p1              <= '0; 
          end
          else begin
              avst_rx_valid_d1_p1             <= i_avst_rx_valid[1];           
              avst_rx_user_d1_p1              <= i_avst_rx_user[(2*AVST_USER)-1:AVST_USER];
              avst_rx_user_d2_p1              <= avst_rx_user_d1_p1;                          
          end
      end  
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
      begin
         if (~i_rx_reset_n_p0) begin
             o_axist_rx_tvalid[0]         <= 1'b0;
         end
         else begin
             o_axist_rx_tvalid[0]         <= avst_rx_ms_valid_d1_p0;                                                                                    
         end
      end   
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1)
      begin 
         if (~i_rx_reset_n_p1) begin
             o_axist_rx_tvalid[1]         <= 1'b0;
         end
         else begin
             o_axist_rx_tvalid[1]         <= avst_rx_ms_valid_d1_p1;                                                                                    
         end
      end         
            
   end
   
   else begin : RX_TVALID_MUX_1P
   
      assign o_axist_rx_tuser = avst_rx_user_d2_p0;
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
          if (~i_rx_reset_n_p0) begin
              avst_rx_valid_d1_p0             <= 1'b0;
              avst_rx_user_d1_p0              <= '0;  
              avst_rx_user_d2_p0              <= '0;              
          end
          else begin
              avst_rx_valid_d1_p0             <= i_avst_rx_valid;          
              avst_rx_user_d1_p0              <= i_avst_rx_user;
              avst_rx_user_d2_p0              <= avst_rx_user_d1_p0;              
         end
      end
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
      begin
         if (~i_rx_reset_n_p0) begin
             o_axist_rx_tvalid         <= 1'b0;
         end
         else begin
             o_axist_rx_tvalid         <= avst_rx_ms_valid_d1_p0;                                                                                    
         end
      end  
      
   end       

end

else begin : RX_SOPA_TVALID_MUX

   if (NUM_MAX_PORTS == 4) begin: RX_TVALID_MUX_4P
   
      assign o_axist_rx_tuser = {avst_rx_user_d2_p3,avst_rx_user_d2_p2,avst_rx_user_d2_p1,avst_rx_user_d2_p0};
   
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
          if (~i_rx_reset_n_p0) begin
              avst_rx_valid_d1_p0             <= 1'b0;
              avst_rx_user_d1_p0              <= '0;  
              avst_rx_user_d2_p0              <= '0;
          end
          else begin
              avst_rx_valid_d1_p0             <= i_avst_rx_valid[0];           
              avst_rx_user_d1_p0              <= i_avst_rx_user[AVST_USER-1:0];
              avst_rx_user_d2_p0              <= avst_rx_user_d1_p0;
          end
      end
      
      always @(posedge i_rx_clk_p1 or negedge i_rx_reset_n_p1) 
      begin
          if (~i_rx_reset_n_p1) begin
              avst_rx_valid_d1_p1             <= 1'b0;
              avst_rx_user_d1_p1              <= '0;  
              avst_rx_user_d2_p1              <= '0;  
          end
          else begin
              avst_rx_valid_d1_p1             <= i_avst_rx_valid[1];           
              avst_rx_user_d1_p1              <= i_avst_rx_user[(2*AVST_USER)-1:AVST_USER];
              avst_rx_user_d2_p1              <= avst_rx_user_d1_p1;              
          end
      end    
      
      always @(posedge i_rx_clk_p2 or negedge i_rx_reset_n_p2) 
      begin
          if (~i_rx_reset_n_p2) begin
              avst_rx_valid_d1_p2             <= 1'b0;
              avst_rx_user_d1_p2              <= '0;  
              avst_rx_user_d2_p2              <= '0;  
          end
          else begin
              avst_rx_valid_d1_p2             <= i_avst_rx_valid[2];           
              avst_rx_user_d1_p2              <= i_avst_rx_user[(3*AVST_USER)-1:(2*AVST_USER)];
              avst_rx_user_d2_p2              <= avst_rx_user_d1_p2;   
          end
      end     
      
      always @(posedge i_rx_clk_p3 or negedge i_rx_reset_n_p3) 
      begin
          if (~i_rx_reset_n_p3) begin
              avst_rx_valid_d1_p3             <= 1'b0;
              avst_rx_user_d1_p3              <= '0;  
              avst_rx_user_d2_p3              <= '0; 
          end
          else begin
              avst_rx_valid_d1_p3             <= i_avst_rx_valid[3];           
              avst_rx_user_d1_p3              <= i_avst_rx_user[(4*AVST_USER)-1:(3*AVST_USER)];
              avst_rx_user_d2_p3              <= avst_rx_user_d1_p3;       
          end
      end      
      
     always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
     begin
         if (~i_rx_reset_n_p0) begin
             axist_rx_tlast_d1[0] <= 1'b0;
             o_axist_rx_tlast [0] <= 1'b0;
         end
         else if (i_avst_rx_valid[0]) begin
             axist_rx_tlast_d1[0] <= i_avst_rx_endofpacket[0];
             o_axist_rx_tlast[0]  <= axist_rx_tlast_d1[0];
         end
         else begin
             axist_rx_tlast_d1[0] <= 1'b0;
             o_axist_rx_tlast[0]  <= axist_rx_tlast_d1[0];
         end
     end
     
     always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
     begin
         if (~i_rx_reset_n_p0) begin
             axist_rx_tuser_valid_d1[0] <= 1'b0;
             o_axist_rx_tuser_valid [0] <= 1'b0;
         end
         else begin
           axist_rx_tuser_valid_d1[0] <= (i_avst_rx_valid[0] & i_avst_rx_startofpacket[0]);
           o_axist_rx_tuser_valid[0] <= axist_rx_tuser_valid_d1[0];
         end
     end 
     
     always @(posedge i_rx_clk_p1 or negedge i_rx_reset_n_p1)
     begin
         if (~i_rx_reset_n_p1) begin
             axist_rx_tlast_d1[1] <= 1'b0;
             o_axist_rx_tlast [1] <= 1'b0;
         end
         else if (i_avst_rx_valid[1]) begin
             axist_rx_tlast_d1[1] <= i_avst_rx_endofpacket[1];
             o_axist_rx_tlast[1]  <= axist_rx_tlast_d1[1];
         end
         else begin
             axist_rx_tlast_d1[1] <= 1'b0;
             o_axist_rx_tlast[1]  <= axist_rx_tlast_d1[1];
         end
     end
     
     always @(posedge i_rx_clk_p1 or negedge i_rx_reset_n_p1)
     begin
         if (~i_rx_reset_n_p1) begin
             axist_rx_tuser_valid_d1[1] <= 1'b0;
             o_axist_rx_tuser_valid [1] <= 1'b0;
         end
         else begin
           axist_rx_tuser_valid_d1[1] <= (i_avst_rx_valid[1] & i_avst_rx_startofpacket[1]);
           o_axist_rx_tuser_valid[1] <= axist_rx_tuser_valid_d1[1];
         end
     end 
     
     always @(posedge i_rx_clk_p2 or negedge i_rx_reset_n_p2)
     begin
         if (~i_rx_reset_n_p2) begin
             axist_rx_tlast_d1[2] <= 1'b0;
             o_axist_rx_tlast [2] <= 1'b0;
         end
         else if (i_avst_rx_valid[2]) begin
             axist_rx_tlast_d1[2] <= i_avst_rx_endofpacket[2];
             o_axist_rx_tlast[2]  <= axist_rx_tlast_d1[2];
         end
         else begin
             axist_rx_tlast_d1[2] <= 1'b0;
             o_axist_rx_tlast[2]  <= axist_rx_tlast_d1[2];
         end
     end
     
     always @(posedge i_rx_clk_p2 or negedge i_rx_reset_n_p2)
     begin
         if (~i_rx_reset_n_p2) begin
             axist_rx_tuser_valid_d1[2] <= 1'b0;
             o_axist_rx_tuser_valid [2] <= 1'b0;
         end
         else begin
           axist_rx_tuser_valid_d1[2] <= (i_avst_rx_valid[2] & i_avst_rx_startofpacket[2]);
           o_axist_rx_tuser_valid[2]  <= axist_rx_tuser_valid_d1[2];
         end
     end 
     
     always @(posedge i_rx_clk_p3 or negedge i_rx_reset_n_p3)
     begin
         if (~i_rx_reset_n_p3) begin
             axist_rx_tlast_d1[3] <= 1'b0;
             o_axist_rx_tlast [3] <= 1'b0;
         end
         else if (i_avst_rx_valid[3]) begin
             axist_rx_tlast_d1[3] <= i_avst_rx_endofpacket[3];
             o_axist_rx_tlast[3]  <= axist_rx_tlast_d1[3];
         end
         else begin
             axist_rx_tlast_d1[3] <= 1'b0;
             o_axist_rx_tlast[3]  <= axist_rx_tlast_d1[3];
         end
     end
     
     always @(posedge i_rx_clk_p3 or negedge i_rx_reset_n_p3)
     begin
         if (~i_rx_reset_n_p3) begin
             axist_rx_tuser_valid_d1[3] <= 1'b0;
             o_axist_rx_tuser_valid [3] <= 1'b0;
         end
         else begin
           axist_rx_tuser_valid_d1[3] <= (i_avst_rx_valid[3] & i_avst_rx_startofpacket[3]);
           o_axist_rx_tuser_valid[3] <= axist_rx_tuser_valid_d1[3];
         end
     end
     
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
      begin
         if (~i_rx_reset_n_p0) begin
             o_axist_rx_tvalid[0]         <= 1'b0;
         end
         else begin
             o_axist_rx_tvalid[0]         <= avst_rx_valid_d1_p0;                                                                                    
         end
      end   
      
      always @(posedge i_rx_clk_p1 or negedge i_rx_reset_n_p1)
      begin 
         if (~i_rx_reset_n_p1) begin
             o_axist_rx_tvalid[1]         <= 1'b0;
         end
         else begin
             o_axist_rx_tvalid[1]         <= avst_rx_valid_d1_p1;                                                                                    
         end
      end       

      always @(posedge i_rx_clk_p2 or negedge i_rx_reset_n_p2)
      begin 
         if (~i_rx_reset_n_p2) begin
             o_axist_rx_tvalid[2]         <= 1'b0;
         end
         else begin
             o_axist_rx_tvalid[2]         <= avst_rx_valid_d1_p2;                                                                                    
         end
      end   

      always @(posedge i_rx_clk_p3 or negedge i_rx_reset_n_p3)
      begin 
         if (~i_rx_reset_n_p3) begin
             o_axist_rx_tvalid[3]         <= 1'b0;
         end
         else begin
             o_axist_rx_tvalid[3]         <= avst_rx_valid_d1_p3;                                                                                    
         end
      end         
     
   end   
   else if (NUM_MAX_PORTS == 2) begin: RX_TVALID_MUX_2P
   
      assign o_axist_rx_tuser = {avst_rx_user_d2_p1,avst_rx_user_d2_p0};
          
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
          if (~i_rx_reset_n_p0) begin
              avst_rx_valid_d1_p0             <= 1'b0;
              avst_rx_user_d1_p0              <= '0;  
              avst_rx_user_d2_p0              <= '0;     
          end
          else begin
              avst_rx_valid_d1_p0             <= i_avst_rx_valid[0];           
              avst_rx_user_d1_p0              <= i_avst_rx_user[AVST_USER-1:0];
              avst_rx_user_d2_p0              <= avst_rx_user_d1_p0;    
          end
      end
      
      always @(posedge i_rx_clk_p1 or negedge i_rx_reset_n_p1) 
      begin
          if (~i_rx_reset_n_p1) begin
              avst_rx_valid_d1_p1             <= 1'b0;
              avst_rx_user_d1_p1              <= '0;  
              avst_rx_user_d2_p1              <= '0; 
          end
          else begin
              avst_rx_valid_d1_p1             <= i_avst_rx_valid[1];           
              avst_rx_user_d1_p1              <= i_avst_rx_user[(2*AVST_USER)-1:AVST_USER];
              avst_rx_user_d2_p1              <= avst_rx_user_d1_p1;   
          end
      end  
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
      begin
          if (~i_rx_reset_n_p0) begin
              axist_rx_tlast_d1[0] <= 1'b0;
              o_axist_rx_tlast [0] <= 1'b0;
          end
          else if (i_avst_rx_valid[0]) begin
              axist_rx_tlast_d1[0] <= i_avst_rx_endofpacket[0];
              o_axist_rx_tlast[0]  <= axist_rx_tlast_d1[0];
          end
          else begin
              axist_rx_tlast_d1[0] <= 1'b0;
              o_axist_rx_tlast[0]  <= axist_rx_tlast_d1[0];
          end
      end
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
      begin
          if (~i_rx_reset_n_p0) begin
              axist_rx_tuser_valid_d1[0] <= 1'b0;
              o_axist_rx_tuser_valid [0] <= 1'b0;
          end
          else begin
            axist_rx_tuser_valid_d1[0] <= (i_avst_rx_valid[0] & i_avst_rx_startofpacket[0]);
            o_axist_rx_tuser_valid[0] <= axist_rx_tuser_valid_d1[0];
          end
      end 

      always @(posedge i_rx_clk_p1 or negedge i_rx_reset_n_p1)
      begin
          if (~i_rx_reset_n_p1) begin
              axist_rx_tlast_d1[1] <= 1'b0;
              o_axist_rx_tlast [1] <= 1'b0;
          end
          else if (i_avst_rx_valid[1]) begin
              axist_rx_tlast_d1[1] <= i_avst_rx_endofpacket[1];
              o_axist_rx_tlast[1]  <= axist_rx_tlast_d1[1];
          end
          else begin
              axist_rx_tlast_d1[1] <= 1'b0;
              o_axist_rx_tlast[1]  <= axist_rx_tlast_d1[1];
          end
      end
      
      always @(posedge i_rx_clk_p1 or negedge i_rx_reset_n_p1)
      begin
          if (~i_rx_reset_n_p1) begin
              axist_rx_tuser_valid_d1[1] <= 1'b0;
              o_axist_rx_tuser_valid [1] <= 1'b0;
          end
          else begin
            axist_rx_tuser_valid_d1[1] <= (i_avst_rx_valid[1] & i_avst_rx_startofpacket[1]);
            o_axist_rx_tuser_valid[1] <= axist_rx_tuser_valid_d1[1];
          end
      end     
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
      begin
         if (~i_rx_reset_n_p0) begin
             o_axist_rx_tvalid[0]         <= 1'b0;
         end
         else begin
             o_axist_rx_tvalid[0]         <= avst_rx_valid_d1_p0;                                                                                    
         end
      end   
      
      always @(posedge i_rx_clk_p1 or negedge i_rx_reset_n_p1)
      begin 
         if (~i_rx_reset_n_p1) begin
             o_axist_rx_tvalid[1]         <= 1'b0;
         end
         else begin
             o_axist_rx_tvalid[1]         <= avst_rx_valid_d1_p1;                                                                                    
         end
      end   
        
   end
   
   else begin : RX_TVALID_MUX_1P
   
      assign o_axist_rx_tuser = avst_rx_user_d2_p0;      
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
          if (~i_rx_reset_n_p0) begin
              avst_rx_valid_d1_p0             <= 1'b0;
              avst_rx_user_d1_p0              <= '0;  
              avst_rx_user_d2_p0              <= '0;     
          end
          else begin
              avst_rx_valid_d1_p0             <= i_avst_rx_valid;          
              avst_rx_user_d1_p0              <= i_avst_rx_user;
              avst_rx_user_d2_p0              <= avst_rx_user_d1_p0;    
         end
      end
            
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
      begin
          if (~i_rx_reset_n_p0) begin
              axist_rx_tlast_d1 <= 1'b0;
              o_axist_rx_tlast  <= 1'b0;
          end
          else if (i_avst_rx_valid) begin
              axist_rx_tlast_d1 <= i_avst_rx_endofpacket;
              o_axist_rx_tlast  <= axist_rx_tlast_d1;
          end
          else begin
              axist_rx_tlast_d1 <= 1'b0;
              o_axist_rx_tlast  <= axist_rx_tlast_d1;
          end
      end
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
      begin
          if (~i_rx_reset_n_p0) begin
              axist_rx_tuser_valid_d1 <= 1'b0;
              o_axist_rx_tuser_valid  <= 1'b0;
          end
          else begin
            axist_rx_tuser_valid_d1 <= (i_avst_rx_valid & i_avst_rx_startofpacket);
            o_axist_rx_tuser_valid <= axist_rx_tuser_valid_d1;
          end
      end         
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
      begin
         if (~i_rx_reset_n_p0) begin
             o_axist_rx_tvalid         <= 1'b0;
         end
         else begin
             o_axist_rx_tvalid         <= avst_rx_valid_d1_p0;                                                                                    
         end
      end     
      
   end       
end

endgenerate   

generate if (AVST_MODE == "MAC_SEGMENTED")  
begin : TDATA_LATCH_MS     
   if (NUM_MAX_PORTS == 4) begin: TVALID_MUX_4P
   
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
         if (~i_rx_reset_n_p0) begin
            avst_rx_data_d1_p0 <= '0;
            avst_rx_data_d2_p0 <= '0;
         end
         else begin   
            avst_rx_data_d2_p0                <= avst_rx_data_d1_p0;                         
            case (i_active_ports)
            3'd1:  
            begin  
               avst_rx_data_d1_p0             <= i_avst_rx_data; //1024
            end 
            3'd2:
            begin  
               avst_rx_data_d1_p0             <= {{AVST_DW_BY_TWO{1'b0}},i_avst_rx_data[AVST_DW_BY_TWO-1:0]}; //511:0                                                                          
            end        
            3'd4:
            begin  
               avst_rx_data_d1_p0             <= {{AVST_DW_BY_FOURX3{1'b0}},i_avst_rx_data[AVST_DW_BY_FOUR-1:0]}; //255:0
            end                 
            default: begin 
               avst_rx_data_d1_p0             <= {AXI_DW{1'b0}};
            end
            endcase
         end     
      end  
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1) 
      begin
         if (~i_rx_reset_n_p1) begin
            avst_rx_data_d1_p1 <= '0;
            avst_rx_data_d2_p1 <= '0;
         end
         else begin   
            avst_rx_data_d2_p1                <= avst_rx_data_d1_p1;             
            case (i_active_ports)
            3'd1,
            3'd2:
            begin  
               avst_rx_data_d1_p1             <= {AVST_DW_BY_FOUR{1'b0}};    
            end   
            3'd4:
            begin  
               avst_rx_data_d1_p1             <= i_avst_rx_data[AVST_DW_BY_TWO-1:AVST_DW_BY_FOUR]; //511:256
            end                 
            default: begin 
               avst_rx_data_d1_p1             <= {AVST_DW_BY_FOUR{1'b0}};
            end
            endcase
         end     
      end     
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p2) 
      begin
         if (~i_rx_reset_n_p2) begin
            avst_rx_data_d1_p2 <= '0;
            avst_rx_data_d2_p2 <= '0;
         end
         else begin   
            avst_rx_data_d2_p2                <= avst_rx_data_d1_p2;             
            case (i_active_ports)
            3'd1:  
            begin  
               avst_rx_data_d1_p2             <= {AVST_DW_BY_TWO{1'b0}};    
            end 
            3'd2:
            begin  
               avst_rx_data_d1_p2             <= i_avst_rx_data[AXI_DW-1:AVST_DW_BY_TWO]; //1023:512                                                                  
            end        
            3'd4:
            begin  
               avst_rx_data_d1_p2             <= {{AVST_DW_BY_FOUR{1'b0}},i_avst_rx_data[AVST_DW_BY_FOURX3-1:AVST_DW_BY_TWO]}; //767:512
            end                 
            default: begin 
               avst_rx_data_d1_p2             <= {AVST_DW_BY_TWO{1'b0}};
            end
            endcase
         end     
      end     
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p3) 
      begin
         if (~i_rx_reset_n_p3) begin
            avst_rx_data_d1_p3 <= '0;
            avst_rx_data_d2_p3 <= '0;
         end
         else begin   
            avst_rx_data_d2_p3                <= avst_rx_data_d1_p3;             
            case (i_active_ports)
            3'd1,  
            3'd2:
            begin  
               avst_rx_data_d1_p3             <= {AVST_DW_BY_FOUR{1'b0}};    
            end 
            3'd4:
            begin  
               avst_rx_data_d1_p3             <= i_avst_rx_data[AVST_DW-1:AVST_DW_BY_FOURX3]; //1023:768
            end                 
            default: begin 
               avst_rx_data_d1_p3             <= {AVST_DW_BY_FOUR{1'b0}};
            end
            endcase
         end     
      end     
      
   end   
   
   else if (NUM_MAX_PORTS == 2) begin: TVALID_MUX_2P
   
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
         if (~i_rx_reset_n_p0) begin
            avst_rx_data_d1_p0 <= '0;
            avst_rx_data_d2_p0 <= '0;
         end
         else begin   
            avst_rx_data_d2_p0                <= avst_rx_data_d1_p0;             
            case (i_active_ports)
            3'd1: 
            begin  
               avst_rx_data_d1_p0             <= i_avst_rx_data;    //1024
            end 
            3'd2:
            begin  
               avst_rx_data_d1_p0             <= {{AVST_DW_BY_TWO{1'b0}},i_avst_rx_data[AVST_DW_BY_TWO-1:0]}; //511:0                                                                          
            end                 
            default: begin 
               avst_rx_data_d1_p0             <= {AXI_DW{1'b0}};
            end
            endcase
         end     
      end  
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1) 
      begin
         if (~i_rx_reset_n_p1) begin
            avst_rx_data_d1_p1 <= '0;
            avst_rx_data_d2_p1 <= '0;
         end
         else begin   
            avst_rx_data_d2_p1                <= avst_rx_data_d1_p1;             
            case (i_active_ports)
            3'd1:  
            begin  
               avst_rx_data_d1_p1             <= {AVST_DW_BY_TWO{1'b0}};    //0
            end 
            3'd2:
            begin  
               avst_rx_data_d1_p1             <= {{AVST_DW_BY_TWO{1'b0}},i_avst_rx_data[AXI_DW-1:AVST_DW_BY_TWO]}; //1023:512                                                                     
            end                  
            default: begin 
               avst_rx_data_d1_p1             <= {AVST_DW_BY_TWO{1'b0}};
            end
            endcase
         end     
      end     
   
   end
   
   else begin : TVALID_MUX_1P
   
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
          if (~i_rx_reset_n_p0) begin
              avst_rx_data_d1_p0             <= '0;
              avst_rx_data_d2_p0             <= '0;      
          end
          else begin
              avst_rx_data_d1_p0             <= i_avst_rx_data;          
              avst_rx_data_d2_p0             <= avst_rx_data_d1_p0;                 
          end
      end
   end                        
end
else begin:TDATA_LATCH_SOPA
   
   if (NUM_MAX_PORTS == 4) begin: SOPA_TVALID_MUX_4P
   
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
         if (~i_rx_reset_n_p0) begin
            avst_rx_data_d1_p0 <= '0;
         end
         else begin   
            case (i_active_ports)
            3'd1:  
            begin  
               avst_rx_data_d1_p0             <= i_avst_rx_data;    
            end 
            3'd2:
            begin  
               avst_rx_data_d1_p0             <= (i_port_data_width == 1) ? {{AVST_DW_BY_FOURX3{1'b0}},i_avst_rx_data[AVST_DW_BY_FOUR-1:0]}: //127:0
                                                                            {{(AXI_DW-AVST_DW_BY_EIGHT){1'b0}},i_avst_rx_data[AVST_DW_BY_EIGHT-1:0]}; //63:0
            end        
            3'd4:
            begin  
               avst_rx_data_d1_p0             <= {{(AXI_DW-AVST_DW_BY_EIGHT){1'b0}},i_avst_rx_data[AVST_DW_BY_EIGHT-1:0]}; //63:0
            end                 
            default: begin 
               avst_rx_data_d1_p0             <= {AXI_DW{1'b0}};
            end
            endcase
         end     
      end  
      
      always @(posedge i_rx_clk_p1 or negedge i_rx_reset_n_p1) 
      begin
         if (~i_rx_reset_n_p1) begin
            avst_rx_data_d1_p1 <= '0;
         end
         else begin   
            case (i_active_ports)
            3'd1,
            3'd2:           
            begin  
               avst_rx_data_d1_p1             <= {AVST_DW_BY_EIGHT{1'b0}};    
            end  
            3'd4:
            begin  
               avst_rx_data_d1_p1             <= {{AVST_DW_BY_EIGHT{1'b0}},i_avst_rx_data[AVST_DW_BY_FOUR-1:AVST_DW_BY_EIGHT]}; //64'd0, 127:64
            end                 
            default: begin 
               avst_rx_data_d1_p1             <= {AVST_DW_BY_EIGHT{1'b0}};
            end
            endcase
         end     
      end     
      
      always @(posedge i_rx_clk_p2 or negedge i_rx_reset_n_p2) 
      begin
         if (~i_rx_reset_n_p2) begin
            avst_rx_data_d1_p2 <= '0;
         end
         else begin   
            case (i_active_ports)
            3'd1:  
            begin  
               avst_rx_data_d1_p2             <= {AVST_DW_BY_FOUR{1'b0}};    
            end 
            3'd2:
            begin  
               avst_rx_data_d1_p2             <= {i_avst_rx_data[AVST_DW_BY_TWO-1:AVST_DW_BY_FOUR]}; //255:128 no 2x25 in UMR3 
                                                                                               
            end        
            3'd4:
            begin  
               avst_rx_data_d1_p2             <= {{AVST_DW_BY_EIGHT{1'b0}},i_avst_rx_data[AVST_DW_BY_EIGHTX3-1:AVST_DW_BY_FOUR]}; //191:128
            end                 
            default: begin 
               avst_rx_data_d1_p2             <= {AVST_DW_BY_FOUR{1'b0}};
            end
            endcase
         end     
      end     
      
      always @(posedge i_rx_clk_p3 or negedge i_rx_reset_n_p3) 
      begin
         if (~i_rx_reset_n_p3) begin
            avst_rx_data_d1_p3 <= '0;
         end
         else begin   
            case (i_active_ports)
            3'd1:  
            begin  
               avst_rx_data_d1_p3             <= {AVST_DW_BY_EIGHT{1'b0}};    
            end 
            3'd2:
            begin  
               avst_rx_data_d1_p3             <= {AVST_DW_BY_EIGHT{1'b0}};                                                                       
            end        
            3'd4:
            begin  
               avst_rx_data_d1_p3             <= i_avst_rx_data[AVST_DW_BY_TWO-1:AVST_DW_BY_EIGHTX3]; //255:192
            end                 
            default: begin 
               avst_rx_data_d1_p3             <= {AVST_DW_BY_EIGHT{1'b0}};
            end
            endcase
         end     
      end     
      
   end   
   
   else if (NUM_MAX_PORTS == 2) begin: SOPA_TVALID_MUX_2P
   
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
         if (~i_rx_reset_n_p0) begin
            avst_rx_data_d1_p0 <= '0;
         end
         else begin   
            case (i_active_ports)
            3'd1: 
            begin  
               avst_rx_data_d1_p0             <= i_avst_rx_data;    
            end 
            3'd2:
            begin  
               avst_rx_data_d1_p0             <= (i_port_data_width == 1) ? {{AVST_DW_BY_FOURX3{1'b0}},i_avst_rx_data[AVST_DW_BY_FOUR-1:0]}: //127:0
                                                                            {{(AXI_DW-AVST_DW_BY_EIGHT){1'b0}},i_avst_rx_data[AVST_DW_BY_EIGHT-1:0]}; //63:0
            end                 
            default: begin 
               avst_rx_data_d1_p0             <= {AXI_DW{1'b0}};
            end
            endcase
         end     
      end  
      
      always @(posedge i_rx_clk_p1 or negedge i_rx_reset_n_p1) 
      begin
         if (~i_rx_reset_n_p1) begin
            avst_rx_data_d1_p1 <= '0;
         end
         else begin   
            case (i_active_ports)
            3'd1:  
            begin  
               avst_rx_data_d1_p1             <= {AVST_DW_BY_FOUR{1'b0}};    
            end 
            3'd2:
            begin  
               avst_rx_data_d1_p1             <= (i_port_data_width == 1) ? i_avst_rx_data[AVST_DW_BY_TWO-1:AVST_DW_BY_FOUR]: //255:128
                                                                            {{AVST_DW_BY_EIGHT{1'b0}},i_avst_rx_data[AVST_DW_BY_FOUR-1:AVST_DW_BY_EIGHT]}; //127:64 2x25 config
            end                  
            default: begin 
               avst_rx_data_d1_p1             <= {AVST_DW_BY_FOUR{1'b0}};
            end
            endcase
         end     
      end     
   
   end
   
   else begin : SOPA_TVALID_MUX_1P
   
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
          if (~i_rx_reset_n_p0) begin
              avst_rx_data_d1_p0             <= '0;
          end
          else begin
              avst_rx_data_d1_p0             <= i_avst_rx_data;          
          end
      end
   end       

end
endgenerate

generate if (AVST_MODE == "MAC_SEGMENTED" && ((PORT_PROFILE == "25GbE" || PORT_PROFILE == "50GAUI-1") || ((DR_ENABLE == 0) && (PORT_PROFILE == "10GbE" || PORT_PROFILE == "40GCAUI-4" || PORT_PROFILE == "50GAUI-2")))) 
begin :MAC_SEGMENTED_1P

    genvar i;
    
for (i=0; i<NUM_SEG; i=i+1) begin :BRIDGE_MS2MP_1P_25G

      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
         if (~i_rx_reset_n_p0)
            avst_rx_eop_d1_p0[i] <= 1'b0;
         else if (i_avst_rx_valid) begin
            if (active_segments == NUM_SEG)
            begin
               if ((i==0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0_d1[NUM_SEG-1])                       
                  avst_rx_eop_d1_p0[i] <= 1'b1;
               else if ((i!=0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0[i-1])                                     
                  avst_rx_eop_d1_p0[i] <= 1'b1;
               else    
                  avst_rx_eop_d1_p0[i] <= 1'b0;                   
            end   
            else 
            begin //for 1x25g reconfig group in 1x100 and 1x50 base profile
               if ((i==0) && !avst_rx_inframe_p0[0] && avst_rx_inframe_p0_d1[0])              
                  avst_rx_eop_d1_p0[i] <= 1'b1;
               // else if ((i!=0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0[i-1]) //invalid for i=1,2,3 for 2x50g config in 1x100g (BMR4) 
                  // avst_rx_eop_d1_p0[i] <= 1'b1;                                      
               else    
                  avst_rx_eop_d1_p0[i] <= 1'b0;
            end               
         end
         else
            avst_rx_eop_d1_p0[i] <= 1'b0;
      end
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
         if (~i_rx_reset_n_p0)
            avst_rx_sop_d1_p0[i] <= 1'b0;
         else if (i_avst_rx_valid) begin
            if (active_segments == NUM_SEG)
            begin
               if ((i==0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0_d1[NUM_SEG-1])                       
                  avst_rx_sop_d1_p0[i] <= 1'b1;
               else if ((i!=0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0[i-1])                                     
                  avst_rx_sop_d1_p0[i] <= 1'b1;
               else    
                  avst_rx_sop_d1_p0[i] <= 1'b0;                  
            end    
            else 
            begin //for 1x25g reconfig group in 1x100 and 1x50 base profile
               if ((i==0) && avst_rx_inframe_p0[0] && !avst_rx_inframe_p0_d1[0])              
                  avst_rx_sop_d1_p0[i] <= 1'b1;
               else if ((i!=0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0[i-1]) //invalid for i=1,2,3 for 2x50g config in 1x100g (BMR4) 
                  avst_rx_sop_d1_p0[i] <= 1'b1;                                      
               else    
                  avst_rx_sop_d1_p0[i] <= 1'b0;
            end               
         end
         else
            avst_rx_sop_d1_p0[i] <= 1'b0;
      end     
       
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
         if (~i_rx_reset_n_p0)
            axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= 8'd0;                
         else if (avst_rx_ms_valid_d1_p0) begin
            if (tlast_segment_d1_p0[i])
               axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {(8){1'b1}} >> avst_rx_eop_empty_d1_p0[(i+1)*EMPTY_BITS-1:EMPTY_BITS*i];
            else if (avst_rx_inframe_p0_d1[i])
               axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {8{1'b1}}; //8'd1; 
            else 
               axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {8{1'b0}}; //8'd0; 
         end
         else
              axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {8{1'b0}}; //8'd0;   
      end    
      
      assign o_axist_rx_tlast_segment[i] = tlast_segment_d1[i];
      assign tlast_segment_d1_p0[i] = (avst_rx_eop_d1_p0[i]) ? 1'b1 : 1'b0; 
                
end

    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
    begin
        if (~i_rx_reset_n_p0) begin
           avst_rx_eop_empty_d1_p0 <= {NUM_SEG*EMPTY_BITS{1'b0}};
        end
        else begin
           avst_rx_eop_empty_d1_p0 <=  i_avst_rx_eop_empty;
       end
    end
    
    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
    begin
        if (~i_rx_reset_n_p0) begin
           tlast_segment_d2_p0 <= '0;
        end
        else begin
           tlast_segment_d2_p0 <=  tlast_segment_d1_p0;
       end
    end 

    always @(*) begin
      case (i_active_ports)
      3'd1:  //same logic for 1 port, irrespective of segment
      begin  
         avst_rx_inframe_p0       = i_avst_rx_inframe; //4 bits
         tlast_segment_d1         = tlast_segment_d2_p0;
         o_axist_rx_tkeep_segment = axist_rx_tkeep_segment_p0;
      end    
      default: begin 
         avst_rx_inframe_p0       = {NUM_SEG{1'b0}};
         tlast_segment_d1         = {NUM_SEG{1'd0}};
         o_axist_rx_tkeep_segment = {(NUM_SEG*8){1'b0}};             
      end
      endcase
   end 
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
   begin
       if (~i_rx_reset_n_p0) begin
          avst_rx_inframe_p0_d1 <= {NUM_SEG{1'b0}};
       end            
       else 
       begin 
          avst_rx_inframe_p0_d1 <= i_avst_rx_valid[0]? avst_rx_inframe_p0:avst_rx_inframe_p0_d1;
       end       
   end   
   
   always_comb begin
      o_axist_rx_tlast = |(tlast_segment_d1);
   end
        
     always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
     begin
        if (~i_rx_reset_n_p0) begin
           o_axist_rx_tuser_valid <= 1'b0; 
           o_axist_rx_tuser_valid_p2 <= 1'b0;  
        end
        else begin 
           o_axist_rx_tuser_valid <= (avst_rx_valid_d1_p0 && (|avst_rx_sop_d1_p0)) ? 1'b1 : 1'b0;
           o_axist_rx_tuser_valid_p2 <= 1'b0;  
        end
     end
     
     assign  o_axist_rx_tkeep = {NO_OF_BYTES{1'b0}};
     assign  o_axist_rx_tdata = avst_rx_data_d2_p0; 
     assign  avst_rx_ms_valid_d1_p0 = avst_rx_valid_d1_p0 && ((|avst_rx_inframe_p0_d1) || (|avst_rx_eop_d1_p0));     
end

else if (AVST_MODE == "MAC_SEGMENTED" && ((PORT_PROFILE == "100GAUI-1") || ((DR_ENABLE == 0) && (PORT_PROFILE != "400GAUI-4" && PORT_PROFILE != "400GAUI-8")))) //All Non DR case except 400G and 100G DR case
begin :MAC_SEGMENTED_100G_1P_NON_DR
    genvar i;
    
for (i=0; i<NUM_SEG; i=i+1) begin :BRIDGE_MS2MP_1P
            
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
         if (~i_rx_reset_n_p0)
            avst_rx_eop_d1_p0[i] <= 1'b0;
         else if (i_avst_rx_valid) begin
            if (active_segments == NUM_SEG)
            begin
               if ((i==0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0_d1[NUM_SEG-1])                       
                  avst_rx_eop_d1_p0[i] <= 1'b1;
               else if ((i!=0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0[i-1])                                     
                  avst_rx_eop_d1_p0[i] <= 1'b1;
               else    
                  avst_rx_eop_d1_p0[i] <= 1'b0;                    
            end
            else if (active_segments == NUM_SEG/2) //1x50 in 1x100 base profile
            begin
               if ((i==0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0_d1[(NUM_SEG/2)-1])                       
                  avst_rx_eop_d1_p0[i] <= 1'b1;
               else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0[i-1]) //invalid for i=2,3 for 2x50g config in 1x100g (BMR4)                                    
                  avst_rx_eop_d1_p0[i] <= 1'b1;                                      
               else    
                  avst_rx_eop_d1_p0[i] <= 1'b0;                  
            end     
            else if (active_segments == NUM_SEG/4)
            begin //for 1x25g reconfig group in 1x100 base profile
               if ((i==0) && !avst_rx_inframe_p0[0] && avst_rx_inframe_p0_d1[0])              
                  avst_rx_eop_d1_p0[i] <= 1'b1;
               // else if ((i!=0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0[i-1]) //invalid for i=1,2,3 for 2x50g config in 1x100g (BMR4) 
                  // avst_rx_eop_d1_p0[i] <= 1'b1;                                      
               else    
                  avst_rx_eop_d1_p0[i] <= 1'b0;
            end    
            else
            begin
               avst_rx_eop_d1_p0[i] <= 1'b0;
            end           
         end
         else
            avst_rx_eop_d1_p0[i] <= 1'b0;
      end
            
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
         if (~i_rx_reset_n_p0)
            avst_rx_sop_d1_p0[i] <= 1'b0;
         else if (i_avst_rx_valid) begin
            if (active_segments == NUM_SEG)
            begin
               if ((i==0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0_d1[NUM_SEG-1])                       
                  avst_rx_sop_d1_p0[i] <= 1'b1;
               else if ((i!=0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0[i-1])                                     
                  avst_rx_sop_d1_p0[i] <= 1'b1;
               else    
                  avst_rx_sop_d1_p0[i] <= 1'b0;                   
            end
            else if (active_segments == NUM_SEG/2)
            begin
               if ((i==0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0_d1[(NUM_SEG/2)-1])                       
                  avst_rx_sop_d1_p0[i] <= 1'b1;
               else if ((i!=0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0[i-1]) //invalid for i=2,3 for 2x50g config in 1x100g (BMR4)                                    
                  avst_rx_sop_d1_p0[i] <= 1'b1;                                      
               else    
                  avst_rx_sop_d1_p0[i] <= 1'b0;                   
            end     
            else if (active_segments == NUM_SEG/4)
            begin //for 1x25g reconfig group in 1x100 and 1x50 base profile
               if ((i==0) && avst_rx_inframe_p0[0] && !avst_rx_inframe_p0_d1[0])              
                  avst_rx_sop_d1_p0[i] <= 1'b1;
               else if ((i!=0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0[i-1]) //invalid for i=1,2,3 for 2x50g config in 1x100g (BMR4) 
                  avst_rx_sop_d1_p0[i] <= 1'b1;                                      
               else    
                  avst_rx_sop_d1_p0[i] <= 1'b0;
            end   
            else
            begin
               avst_rx_sop_d1_p0[i] <= 1'b0;
            end              
         end
         else
            avst_rx_sop_d1_p0[i] <= '0;
      end                 
        
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
         if (~i_rx_reset_n_p0)
            axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= 8'd0;                
         else if (avst_rx_ms_valid_d1_p0) begin
            if (tlast_segment_d1_p0[i])
               axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {(8){1'b1}} >> avst_rx_eop_empty_d1_p0[(i+1)*EMPTY_BITS-1:EMPTY_BITS*i];
            else if (avst_rx_inframe_p0_d1[i])
               axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {8{1'b1}}; //8'd1; 
            else 
               axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {8{1'b0}}; //8'd0; 
         end
         else
              axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {8{1'b0}}; //8'd0;   
      end    
      
      assign o_axist_rx_tlast_segment[i]  = tlast_segment_d1[i];  
      assign tlast_segment_d1_p0[i] = (avst_rx_eop_d1_p0[i]) ? 1'b1 : 1'b0; 
                
end

    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
    begin
        if (~i_rx_reset_n_p0) begin
           avst_rx_eop_empty_d1_p0 <= {NUM_SEG*EMPTY_BITS{1'b0}};
        end
        else begin
           avst_rx_eop_empty_d1_p0 <=  i_avst_rx_eop_empty;
       end
    end

    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
    begin
        if (~i_rx_reset_n_p0) begin
           tlast_segment_d2_p0 <= '0;
        end
        else begin
           tlast_segment_d2_p0 <=  tlast_segment_d1_p0;
       end
    end     
        
    always @(*) begin
      case (i_active_ports)
      3'd1:  //same logic for 1 port, irrespective of segment
      begin  
         avst_rx_inframe_p0       = i_avst_rx_inframe; //4 bits
         tlast_segment_d1         = tlast_segment_d2_p0;
         o_axist_rx_tkeep_segment = axist_rx_tkeep_segment_p0;
      end    
      default: begin 
         avst_rx_inframe_p0       = {NUM_SEG{1'b0}};
         tlast_segment_d1         = {NUM_SEG{1'd0}};
         o_axist_rx_tkeep_segment = {(NUM_SEG*8){1'b0}};             
      end
      endcase
   end 
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
   begin
       if (~i_rx_reset_n_p0) begin
          avst_rx_inframe_p0_d1 <= {NUM_SEG{1'b0}};
       end            
       else 
       begin 
          avst_rx_inframe_p0_d1 <=  i_avst_rx_valid[0]? avst_rx_inframe_p0:avst_rx_inframe_p0_d1;
       end       
   end   
   
   always_comb begin
      o_axist_rx_tlast = |(tlast_segment_d1);
   end   
        
     always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
     begin
        if (~i_rx_reset_n_p0) begin
           o_axist_rx_tuser_valid <= 1'b0; 
           o_axist_rx_tuser_valid_p2 <= 1'b0;          
        end
        else begin 
           o_axist_rx_tuser_valid <= (avst_rx_valid_d1_p0 && (|avst_rx_sop_d1_p0)) ? 1'b1 : 1'b0;
           o_axist_rx_tuser_valid_p2 <= 1'b0;  
        end
     end
     
     assign  o_axist_rx_tkeep = {NO_OF_BYTES{1'b0}};     
     assign  o_axist_rx_tdata = avst_rx_data_d2_p0;
     assign  avst_rx_ms_valid_d1_p0 = avst_rx_valid_d1_p0 && ((|avst_rx_inframe_p0_d1) || (|avst_rx_eop_d1_p0));     
end

else if (AVST_MODE == "MAC_SEGMENTED" && DR_ENABLE == 0 && (PORT_PROFILE == "400GAUI-4" || PORT_PROFILE == "400GAUI-8")) begin :MAC_SEGMENTED_400G_1P_NON_DR //400G Non DR case 
    genvar i;
    
for (i=0; i<NUM_SEG; i=i+1) begin :BRIDGE_MS2MP_1P
            
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
         if (~i_rx_reset_n_p0)
            avst_rx_eop_d1_p0[i] <= 1'b0;
         else if (i_avst_rx_valid) begin //Non-DR case (1 port). All segments will be considered
            if ((i==0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0_d1[NUM_SEG-1])                       
               avst_rx_eop_d1_p0[i] <= 1'b1;
            else if ((i!=0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0[i-1])                                     
               avst_rx_eop_d1_p0[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p0[i] <= 1'b0;                           
         end
         else
            avst_rx_eop_d1_p0[i] <= 1'b0;
      end
            
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
         if (~i_rx_reset_n_p0)
            avst_rx_sop_d1_p0[i] <= 1'b0;
         else if (i_avst_rx_valid) begin //Non-DR case (1 port). All segments will be considered
            if ((i==0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0_d1[NUM_SEG-1])                       
               avst_rx_sop_d1_p0[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0[i-1])                                     
               avst_rx_sop_d1_p0[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p0[i] <= 1'b0;                               
         end
         else
            avst_rx_sop_d1_p0[i] <= '0;
      end                 
        
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
         if (~i_rx_reset_n_p0)
            axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= 8'd0;                
         else if (avst_rx_ms_valid_d1_p0) begin
            if (tlast_segment_d1_p0[i])
               axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {(8){1'b1}} >> avst_rx_eop_empty_d1_p0[(i+1)*EMPTY_BITS-1:EMPTY_BITS*i];
            else if (avst_rx_inframe_p0_d1[i])
               axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {8{1'b1}}; //8'd1; 
            else 
               axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {8{1'b0}}; //8'd0; 
         end
         else
              axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {8{1'b0}}; //8'd0;   
      end    
            
      assign o_axist_rx_tlast_segment[i] = tlast_segment_d1[i]; 
      assign tlast_segment_d1_p0[i] = (avst_rx_eop_d1_p0[i]) ? 1'b1 : 1'b0; 
                
end

    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
    begin
        if (~i_rx_reset_n_p0) begin
           avst_rx_eop_empty_d1_p0 <= {NUM_SEG*EMPTY_BITS{1'b0}};
        end
        else begin
           avst_rx_eop_empty_d1_p0 <=  i_avst_rx_eop_empty;
       end
    end
    
    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
    begin
        if (~i_rx_reset_n_p0) begin
           tlast_segment_d2_p0 <= '0;
        end
        else begin
           tlast_segment_d2_p0 <=  tlast_segment_d1_p0;
       end
    end     

    always @(*) begin
      case (i_active_ports)
      3'd1:  //same logic for 1 port, irrespective of segment
      begin  
         avst_rx_inframe_p0       = i_avst_rx_inframe; //4 bits
         tlast_segment_d1         = tlast_segment_d2_p0;
         o_axist_rx_tkeep_segment = axist_rx_tkeep_segment_p0;
      end    
      default: begin 
         avst_rx_inframe_p0       = {NUM_SEG{1'b0}};
         tlast_segment_d1         = {NUM_SEG{1'd0}};
         o_axist_rx_tkeep_segment = {(NUM_SEG*8){1'b0}};             
      end
      endcase
   end 
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
   begin
       if (~i_rx_reset_n_p0) begin
          avst_rx_inframe_p0_d1 <= {NUM_SEG{1'b0}};
       end            
       else 
       begin 
          avst_rx_inframe_p0_d1 <=  i_avst_rx_valid[0]? avst_rx_inframe_p0:avst_rx_inframe_p0_d1;
       end       
   end   
   
   always_comb begin
      o_axist_rx_tlast = |(tlast_segment_d1);
   end    
        
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
   begin
      if (~i_rx_reset_n_p0) begin
         o_axist_rx_tuser_valid <= 1'b0; 
         o_axist_rx_tuser_valid_p2 <= 1'b0;  
      end
      else begin 
         o_axist_rx_tuser_valid <= (avst_rx_valid_d1_p0 && (|avst_rx_sop_d1_p0[7:0])) ? 1'b1 : 1'b0;
         o_axist_rx_tuser_valid_p2 <= (avst_rx_valid_d1_p0 && (|avst_rx_sop_d1_p0[15:8])) ? 1'b1 : 1'b0;
      end
   end
   
   assign  o_axist_rx_tkeep = {NO_OF_BYTES{1'b0}};   
   assign  o_axist_rx_tdata = avst_rx_data_d2_p0;
   assign  avst_rx_ms_valid_d1_p0 = avst_rx_valid_d1_p0 && ((|avst_rx_inframe_p0_d1) || (|avst_rx_eop_d1_p0));  
   
end

else if (AVST_MODE == "MAC_SEGMENTED" && ((PORT_PROFILE == "100GAUI-2") || (PORT_PROFILE == "200GAUI-2"))) begin : MAC_SEGMENTED_2P 
  genvar i; //j,k;

for (i=0; i<NUM_SEG; i=i+1) begin :BRIDGE_MS2MP_2P
            
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
   begin
      if (~i_rx_reset_n_p0)
         avst_rx_eop_d1_p0[i] <= 1'b0;
      else if (i_avst_rx_valid[0]) begin
         if (active_segments == NUM_SEG)
         begin     
            if ((i==0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0_d1[NUM_SEG-1])                       
               avst_rx_eop_d1_p0[i] <= 1'b1;
            else if ((i!=0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0[i-1])                                     
               avst_rx_eop_d1_p0[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p0[i] <= 1'b0;                    
         end
         else if (active_segments == NUM_SEG/2)
         begin     
            if ((i==0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0_d1[(NUM_SEG/2)-1])                       
               avst_rx_eop_d1_p0[i] <= 1'b1;
            else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0[i-1])                                     
               avst_rx_eop_d1_p0[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p0[i] <= 1'b0;                   
         end         
         else if (active_segments == NUM_SEG/4)
         begin     
            if ((i==0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0_d1[(NUM_SEG/4)-1])                       
               avst_rx_eop_d1_p0[i] <= 1'b1;
            else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0[i-1])                                     
               avst_rx_eop_d1_p0[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p0[i] <= 1'b0;                  
         end 
         else
         begin
            avst_rx_eop_d1_p0[i] <= 1'b0;
         end
      end            
      else begin
         avst_rx_eop_d1_p0[i] <= 1'b0;
      end
   end
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1) 
   begin
      if (~i_rx_reset_n_p1)
         avst_rx_eop_d1_p1[i] <= 1'b0;
      else if (i_avst_rx_valid[1]) begin
         if (active_segments == NUM_SEG)
         begin     
            if ((i==0) && !avst_rx_inframe_p1[i] && avst_rx_inframe_p1_d1[NUM_SEG-1])                       
               avst_rx_eop_d1_p1[i] <= 1'b1;
            else if ((i!=0) && !avst_rx_inframe_p1[i] && avst_rx_inframe_p1[i-1])                                     
               avst_rx_eop_d1_p1[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p1[i] <= 1'b0;                    
         end
         else if (active_segments == NUM_SEG/2)
         begin     
            if ((i==0) && !avst_rx_inframe_p1[i] && avst_rx_inframe_p1_d1[(NUM_SEG/2)-1])                       
               avst_rx_eop_d1_p1[i] <= 1'b1;
            else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p1[i] && avst_rx_inframe_p1[i-1])                                     
               avst_rx_eop_d1_p1[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p1[i] <= 1'b0;                   
         end         
         else if (active_segments == NUM_SEG/4)
         begin     
            if ((i==0) && !avst_rx_inframe_p1[i] && avst_rx_inframe_p1_d1[(NUM_SEG/4)-1])                       
               avst_rx_eop_d1_p1[i] <= 1'b1;
            else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p1[i] && avst_rx_inframe_p1[i-1])                                     
               avst_rx_eop_d1_p1[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p1[i] <= 1'b0;                   
         end 
         else
         begin
            avst_rx_eop_d1_p1[i] <= 1'b0;
         end
      end            
      else begin
         avst_rx_eop_d1_p1[i] <= 1'b0;
      end
   end  

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
   begin
      if (~i_rx_reset_n_p0)
         avst_rx_sop_d1_p0[i] <= 1'b0;
      else if (i_avst_rx_valid[0]) begin
         if (active_segments == NUM_SEG)
         begin     
            if ((i==0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0_d1[NUM_SEG-1])                       
               avst_rx_sop_d1_p0[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0[i-1])                                     
               avst_rx_sop_d1_p0[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p0[i] <= 1'b0;                    
         end
         else if (active_segments == NUM_SEG/2)
         begin     
            if ((i==0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0_d1[(NUM_SEG/2)-1])                       
               avst_rx_sop_d1_p0[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0[i-1])                                     
               avst_rx_sop_d1_p0[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p0[i] <= 1'b0;                    
         end         
         else if (active_segments == NUM_SEG/4)
         begin     
            if ((i==0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0_d1[(NUM_SEG/4)-1])                       
               avst_rx_sop_d1_p0[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0[i-1])                                     
               avst_rx_sop_d1_p0[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p0[i] <= '0;                    
         end 
         else
         begin
            avst_rx_sop_d1_p0[i] <= 1'b0;
         end
      end            
      else begin
         avst_rx_sop_d1_p0[i] <= 1'b0;
      end
   end   
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1) 
   begin
      if (~i_rx_reset_n_p1)
         avst_rx_sop_d1_p1[i] <= 1'b0;
      else if (i_avst_rx_valid[1]) begin
         if (active_segments == NUM_SEG)
         begin     
            if ((i==0) && avst_rx_inframe_p1[i] && !avst_rx_inframe_p1_d1[NUM_SEG-1])                       
               avst_rx_sop_d1_p1[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p1[i] && !avst_rx_inframe_p1[i-1])                                     
               avst_rx_sop_d1_p1[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p1[i] <= 1'b0;                   
         end
         else if (active_segments == NUM_SEG/2)
         begin     
            if ((i==0) && avst_rx_inframe_p1[i] && !avst_rx_inframe_p1_d1[(NUM_SEG/2)-1])                       
               avst_rx_sop_d1_p1[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p1[i] && !avst_rx_inframe_p1[i-1])                                     
               avst_rx_sop_d1_p1[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p1[i] <= 1'b0;                    
         end         
         else if (active_segments == NUM_SEG/4)
         begin     
            if ((i==0) && avst_rx_inframe_p1[i] && !avst_rx_inframe_p1_d1[(NUM_SEG/4)-1])                       
               avst_rx_sop_d1_p1[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p1[i] && !avst_rx_inframe_p1[i-1])                                     
               avst_rx_sop_d1_p1[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p1[i] <= 1'b0;                   
         end 
         else
         begin
            avst_rx_sop_d1_p1[i] <= 1'b0;
         end
      end            
      else begin
         avst_rx_sop_d1_p1[i] <= 1'b0;
      end
   end             

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
   begin
      if (~i_rx_reset_n_p0)
         axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {8{1'b0}};               
      else if (avst_rx_ms_valid_d1_p0) begin
         if (tlast_segment_d1_p0[i])
            axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {(8){1'b1}} >> avst_rx_eop_empty_d1_p0[(i+1)*EMPTY_BITS-1:EMPTY_BITS*i];
         else if (avst_rx_inframe_p0_d1[i])
            axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {(8){1'b1}};
         else 
            axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {8{1'b0}};
      end
      else
         axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {8{1'b0}};   
   end

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1) 
   begin
      if (~i_rx_reset_n_p1)
         axist_rx_tkeep_segment_p1[(i+1)*8-1:8*i] <= {8{1'b0}};               
      else if (avst_rx_ms_valid_d1_p1) begin
         if (tlast_segment_d1_p1[i])
            axist_rx_tkeep_segment_p1[(i+1)*8-1:8*i] <= {(8){1'b1}} >> avst_rx_eop_empty_d1_p1[(i+1)*EMPTY_BITS-1:EMPTY_BITS*i];
         else if (avst_rx_inframe_p1_d1[i])
            axist_rx_tkeep_segment_p1[(i+1)*8-1:8*i] <= {(8){1'b1}};
         else 
            axist_rx_tkeep_segment_p1[(i+1)*8-1:8*i] <= {8{1'b0}};
      end
      else
           axist_rx_tkeep_segment_p1[(i+1)*8-1:8*i] <= {8{1'b0}};   
   end
   
   assign o_axist_rx_tlast_segment[i] = tlast_segment_d1[i]; 
   
   assign tlast_segment_d1_p0[i] = (avst_rx_eop_d1_p0[i]) ? 1'b1 : 1'b0; 
   assign tlast_segment_d1_p1[i] = (avst_rx_eop_d1_p1[i]) ? 1'b1 : 1'b0;    

end         

    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
    begin
        if (~i_rx_reset_n_p0) begin
           avst_rx_eop_empty_d1_p0 <= {NUM_SEGXEB{1'b0}};
        end
        else begin
           case (i_active_ports)
           3'd1:  
           begin  
              avst_rx_eop_empty_d1_p0 <=  i_avst_rx_eop_empty;
           end
           3'd2:
           begin    
              avst_rx_eop_empty_d1_p0 <=  {{NUM_SEG_BY_TWOXEB{1'b0}},i_avst_rx_eop_empty[NUM_SEG_BY_TWOXEB-1:0]}; //5:0
           end         
           default: begin 
              avst_rx_eop_empty_d1_p0 <= {NUM_SEGXEB{1'b0}};
           end
           endcase         
       end
    end
    
    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1)
    begin
        if (~i_rx_reset_n_p1) begin
           avst_rx_eop_empty_d1_p1 <= {NUM_SEGXEB{1'b0}};
        end
        else begin
           case (i_active_ports)
           3'd1:  
           begin  
              avst_rx_eop_empty_d1_p1 <=  {NUM_SEGXEB{1'b0}};
           end
           3'd2:
           begin    
              avst_rx_eop_empty_d1_p1 <=  {{NUM_SEG_BY_TWOXEB{1'b0}},i_avst_rx_eop_empty[NUM_SEGXEB-1:NUM_SEG_BY_TWOXEB]}; //11:6      
           end         
           default: begin 
              avst_rx_eop_empty_d1_p1 <= {NUM_SEGXEB{1'b0}};          
           end
           endcase         
       end
    end 

    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
    begin
        if (~i_rx_reset_n_p0) begin
           tlast_segment_d2_p0 <= '0;
        end
        else begin
           tlast_segment_d2_p0 <= tlast_segment_d1_p0;
        end
     end
     
    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1)
    begin
        if (~i_rx_reset_n_p1) begin
           tlast_segment_d2_p1 <= '0;
        end
        else begin
           tlast_segment_d2_p1 <= tlast_segment_d1_p1;
        end
     end     

     always @(*) begin
        case (i_active_ports)
        3'd1:
        begin  
           o_axist_rx_tlast = {1'b0, |tlast_segment_d1};
        end // same condition for 1x50. ideally tlast_seg 2 & 3 should not be 1
        3'd2:
        begin  
           o_axist_rx_tlast = {|tlast_segment_d1[NUM_SEG-1:NUM_SEG_BY_TWO],|tlast_segment_d1[NUM_SEG_BY_TWO-1:0]};
        end         
        
        default: begin o_axist_rx_tlast = {NUM_SEG{1'b0}}; end
        endcase
     end         
        
   always @(*) begin
      case (i_active_ports)
      3'd1:  //same logic for 1 port, irrespective of segment
      begin  
         avst_rx_inframe_p0       = i_avst_rx_inframe; //4 bits
         avst_rx_inframe_p1       = {NUM_SEG{1'b0}};
         tlast_segment_d1         = tlast_segment_d2_p0;
         o_axist_rx_tkeep_segment = axist_rx_tkeep_segment_p0;
      end 
      3'd2:
      begin  
         avst_rx_inframe_p0       = {{NUM_SEG_BY_TWO{1'b0}},i_avst_rx_inframe[NUM_SEG_BY_TWO-1:0]};
         avst_rx_inframe_p1       = {{NUM_SEG_BY_TWO{1'b0}},i_avst_rx_inframe[NUM_SEG-1:NUM_SEG_BY_TWO]};
         tlast_segment_d1         = {tlast_segment_d2_p1[NUM_SEG_BY_TWO-1:0],tlast_segment_d2_p0[NUM_SEG_BY_TWO-1:0]};
         o_axist_rx_tkeep_segment = {axist_rx_tkeep_segment_p1[(NUM_SEG_BY_TWO*8)-1:0],axist_rx_tkeep_segment_p0[(NUM_SEG_BY_TWO*8)-1:0]};
      end        
      default: begin 
         avst_rx_inframe_p0 = {NUM_SEG{1'b0}};
         avst_rx_inframe_p1 = {NUM_SEG{1'b0}};
         tlast_segment_d1   = {NUM_SEG{1'd0}};
         o_axist_rx_tkeep_segment = {(NUM_SEG*8){1'b0}};             
      end
      endcase
   end 
      
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
   begin
       if (~i_rx_reset_n_p0) begin
          avst_rx_inframe_p0_d1 <= {NUM_SEG{1'b0}};
       end            
       else 
       begin 
          avst_rx_inframe_p0_d1 <= i_avst_rx_valid[0]? avst_rx_inframe_p0:avst_rx_inframe_p0_d1;
       end       
   end
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1)
   begin
       if (~i_rx_reset_n_p1) begin
          avst_rx_inframe_p1_d1 <= {NUM_SEG{1'b0}};
       end            
       else 
       begin 
          avst_rx_inframe_p1_d1 <= i_avst_rx_valid[1]? avst_rx_inframe_p1:avst_rx_inframe_p1_d1;           
       end       
   end   
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
   begin
      if (~i_rx_reset_n_p0) begin
         o_axist_rx_tuser_valid[0] <= '0; 
         o_axist_rx_tuser_valid_p2[0] <= '0;  
      end
      else begin 
         o_axist_rx_tuser_valid[0] <= (avst_rx_valid_d1_p0 && (|avst_rx_sop_d1_p0)) ? 1'b1 : 1'b0; //logic TBV
         o_axist_rx_tuser_valid_p2[0] <= 1'b0;     
      end
   end
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1) 
   begin
      if (~i_rx_reset_n_p1) begin
         o_axist_rx_tuser_valid[1] <= '0; 
         o_axist_rx_tuser_valid_p2[1] <= '0;  
      end
      else begin 
         o_axist_rx_tuser_valid[1] <= (avst_rx_valid_d1_p1 && (|avst_rx_sop_d1_p1)) ? 1'b1 : 1'b0; //logic TBV
         o_axist_rx_tuser_valid_p2[1] <= 1'b0;     
      end
   end   
     
     assign  o_axist_rx_tkeep = {NO_OF_BYTES{1'b0}};     
     assign  o_axist_rx_tdata = (i_active_ports == 3'b1)? avst_rx_data_d2_p0 : {avst_rx_data_d2_p1[AVST_DW_BY_TWO-1:0],avst_rx_data_d2_p0[AVST_DW_BY_TWO-1:0]};
     
     assign  avst_rx_ms_valid_d1_p0 = avst_rx_valid_d1_p0 && ((|avst_rx_inframe_p0_d1) || (|avst_rx_eop_d1_p0));     
     assign  avst_rx_ms_valid_d1_p1 = avst_rx_valid_d1_p1 && ((|avst_rx_inframe_p1_d1) || (|avst_rx_eop_d1_p1));     

end

else if (AVST_MODE == "MAC_SEGMENTED" && ((PORT_PROFILE == "100GCAUI-4") || (PORT_PROFILE == "200GAUI-4"))) begin : MAC_SEGMENTED_4P 
genvar i;

for (i=0; i<NUM_SEG; i=i+1) begin :BRIDGE_MS2MP_4P

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
   begin
      if (~i_rx_reset_n_p0)
         avst_rx_eop_d1_p0[i] <= 1'b0;
      else if (i_avst_rx_valid[0]) begin
         if (active_segments == NUM_SEG)
         begin     
            if ((i==0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0_d1[NUM_SEG-1])                       
               avst_rx_eop_d1_p0[i] <= 1'b1;
            else if ((i!=0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0[i-1])                                     
               avst_rx_eop_d1_p0[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p0[i] <= 1'b0;                   
         end
         else if (active_segments == NUM_SEG/2)
         begin     
            if ((i==0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0_d1[(NUM_SEG/2)-1])                       
               avst_rx_eop_d1_p0[i] <= 1'b1;
            else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0[i-1])                                     
               avst_rx_eop_d1_p0[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p0[i] <= 1'b0;                   
         end         
         else if (active_segments == NUM_SEG/4)
         begin     
            if ((i==0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0_d1[(NUM_SEG/4)-1])                       
               avst_rx_eop_d1_p0[i] <= 1'b1;
            else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0[i-1])                                     
               avst_rx_eop_d1_p0[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p0[i] <= 1'b0;                    
         end 
         else
         begin
            avst_rx_eop_d1_p0[i] <= 1'b0;
         end
      end            
      else begin
         avst_rx_eop_d1_p0[i] <= 1'b0;
      end
   end
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1) 
   begin
      if (~i_rx_reset_n_p1)
         avst_rx_eop_d1_p1[i] <= 1'b0;
      else if (i_avst_rx_valid[1]) begin
         if (active_segments == NUM_SEG)
         begin     
            if ((i==0) && !avst_rx_inframe_p1[i] && avst_rx_inframe_p1_d1[NUM_SEG-1])                       
               avst_rx_eop_d1_p1[i] <= 1'b1;
            else if ((i!=0) && !avst_rx_inframe_p1[i] && avst_rx_inframe_p1[i-1])                                     
               avst_rx_eop_d1_p1[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p1[i] <= 1'b0;                   
         end
         else if (active_segments == NUM_SEG/2)
         begin     
            if ((i==0) && !avst_rx_inframe_p1[i] && avst_rx_inframe_p1_d1[(NUM_SEG/2)-1])                       
               avst_rx_eop_d1_p1[i] <= 1'b1;
            else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p1[i] && avst_rx_inframe_p1[i-1])                                     
               avst_rx_eop_d1_p1[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p1[i] <= 1'b0;                    
         end         
         else if (active_segments == NUM_SEG/4)
         begin     
            if ((i==0) && !avst_rx_inframe_p1[i] && avst_rx_inframe_p1_d1[(NUM_SEG/4)-1])                       
               avst_rx_eop_d1_p1[i] <= 1'b1;
            else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p1[i] && avst_rx_inframe_p1[i-1])                                     
               avst_rx_eop_d1_p1[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p1[i] <= 1'b0;                   
         end 
         else
         begin
            avst_rx_eop_d1_p1[i] <= 1'b0;
         end
      end            
      else begin
         avst_rx_eop_d1_p1[i] <= 1'b0;
      end
   end  

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p2) 
   begin
      if (~i_rx_reset_n_p2)
         avst_rx_eop_d1_p2[i] <= 1'b0;
      else if (i_avst_rx_valid[2]) begin
         if (active_segments == NUM_SEG)
         begin     
            if ((i==0) && !avst_rx_inframe_p2[i] && avst_rx_inframe_p2_d1[NUM_SEG-1])                       
               avst_rx_eop_d1_p2[i] <= 1'b1;
            else if ((i!=0) && !avst_rx_inframe_p2[i] && avst_rx_inframe_p2[i-1])                                     
               avst_rx_eop_d1_p2[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p2[i] <= 1'b0;                   
         end
         else if (active_segments == NUM_SEG/2)
         begin     
            if ((i==0) && !avst_rx_inframe_p2[i] && avst_rx_inframe_p2_d1[(NUM_SEG/2)-1])                       
               avst_rx_eop_d1_p2[i] <= 1'b1;
            else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p2[i] && avst_rx_inframe_p2[i-1])                                     
               avst_rx_eop_d1_p2[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p2[i] <= 1'b0;                    
         end         
         else if (active_segments == NUM_SEG/4)
         begin     
            if ((i==0) && !avst_rx_inframe_p2[i] && avst_rx_inframe_p2_d1[(NUM_SEG/4)-1])                       
               avst_rx_eop_d1_p2[i] <= 1'b1;
            else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p2[i] && avst_rx_inframe_p2[i-1])                                     
               avst_rx_eop_d1_p2[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p2[i] <= 1'b0;                    
         end 
         else
         begin
            avst_rx_eop_d1_p2[i] <= 1'b0;
         end
      end            
      else begin
         avst_rx_eop_d1_p2[i] <= 1'b0;
      end
   end 
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p3) 
   begin
      if (~i_rx_reset_n_p3)
         avst_rx_eop_d1_p3[i] <= 1'b0;
      else if (i_avst_rx_valid[3]) begin
         if (active_segments == NUM_SEG)
         begin     
            if ((i==0) && !avst_rx_inframe_p3[i] && avst_rx_inframe_p3_d1[NUM_SEG-1])                       
               avst_rx_eop_d1_p3[i] <= 1'b1;
            else if ((i!=0) && !avst_rx_inframe_p3[i] && avst_rx_inframe_p3[i-1])                                     
               avst_rx_eop_d1_p3[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p3[i] <= 1'b0;                 
         end
         else if (active_segments == NUM_SEG/2)
         begin     
            if ((i==0) && !avst_rx_inframe_p3[i] && avst_rx_inframe_p3_d1[(NUM_SEG/2)-1])                       
               avst_rx_eop_d1_p3[i] <= 1'b1;
            else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p3[i] && avst_rx_inframe_p3[i-1])                                     
               avst_rx_eop_d1_p3[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p3[i] <= 1'b0;                  
         end         
         else if (active_segments == NUM_SEG/4)
         begin     
            if ((i==0) && !avst_rx_inframe_p3[i] && avst_rx_inframe_p3_d1[(NUM_SEG/4)-1])                       
               avst_rx_eop_d1_p3[i] <= 1'b1;
            else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p3[i] && avst_rx_inframe_p3[i-1])                                     
               avst_rx_eop_d1_p3[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p3[i] <= 1'b0;                 
         end 
         else
         begin
            avst_rx_eop_d1_p3[i] <= 1'b0;
         end
      end            
      else begin
         avst_rx_eop_d1_p3[i] <= 1'b0;
      end
   end 
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
   begin
      if (~i_rx_reset_n_p0)
         avst_rx_sop_d1_p0[i] <= 1'b0;
      else if (i_avst_rx_valid[0]) begin
         if (active_segments == NUM_SEG)
         begin     
            if ((i==0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0_d1[NUM_SEG-1])                       
               avst_rx_sop_d1_p0[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0[i-1])                                     
               avst_rx_sop_d1_p0[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p0[i] <= 1'b0;                   
         end
         else if (active_segments == NUM_SEG/2)
         begin     
            if ((i==0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0_d1[(NUM_SEG/2)-1])                       
               avst_rx_sop_d1_p0[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0[i-1])                                     
               avst_rx_sop_d1_p0[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p0[i] <= 1'b0;                  
         end         
         else if (active_segments == NUM_SEG/4)
         begin     
            if ((i==0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0_d1[(NUM_SEG/4)-1])                       
               avst_rx_sop_d1_p0[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0[i-1])                                     
               avst_rx_sop_d1_p0[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p0[i] <= 1'b0;                   
         end 
         else
         begin
            avst_rx_sop_d1_p0[i] <= 1'b0;
         end
      end            
      else begin
         avst_rx_sop_d1_p0[i] <= 1'b0;
      end
   end   
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1) 
   begin
      if (~i_rx_reset_n_p1)
         avst_rx_sop_d1_p1[i] <= 1'b0;
      else if (i_avst_rx_valid[1]) begin
         if (active_segments == NUM_SEG)
         begin     
            if ((i==0) && avst_rx_inframe_p1[i] && !avst_rx_inframe_p1_d1[NUM_SEG-1])                       
               avst_rx_sop_d1_p1[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p1[i] && !avst_rx_inframe_p1[i-1])                                     
               avst_rx_sop_d1_p1[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p1[i] <= 1'b0;                   
         end
         else if (active_segments == NUM_SEG/2)
         begin     
            if ((i==0) && avst_rx_inframe_p1[i] && !avst_rx_inframe_p1_d1[(NUM_SEG/2)-1])                       
               avst_rx_sop_d1_p1[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p1[i] && !avst_rx_inframe_p1[i-1])                                     
               avst_rx_sop_d1_p1[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p1[i] <= 1'b0;                    
         end         
         else if (active_segments == NUM_SEG/4)
         begin     
            if ((i==0) && avst_rx_inframe_p1[i] && !avst_rx_inframe_p1_d1[(NUM_SEG/4)-1])                       
               avst_rx_sop_d1_p1[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p1[i] && !avst_rx_inframe_p1[i-1])                                     
               avst_rx_sop_d1_p1[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p1[i] <= 1'b0;                   
         end 
         else
         begin
            avst_rx_sop_d1_p1[i] <= 1'b0;
         end
      end            
      else begin
         avst_rx_sop_d1_p1[i] <= 1'b0;
      end
   end     

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p2) 
   begin
      if (~i_rx_reset_n_p2)
         avst_rx_sop_d1_p2[i] <= 1'b0;
      else if (i_avst_rx_valid[2]) begin
         if (active_segments == NUM_SEG)
         begin     
            if ((i==0) && avst_rx_inframe_p2[i] && !avst_rx_inframe_p2_d1[NUM_SEG-1])                       
               avst_rx_sop_d1_p2[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p2[i] && !avst_rx_inframe_p2[i-1])                                     
               avst_rx_sop_d1_p2[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p2[i] <= 1'b0;                   
         end
         else if (active_segments == NUM_SEG/2)
         begin     
            if ((i==0) && avst_rx_inframe_p2[i] && !avst_rx_inframe_p2_d1[(NUM_SEG/2)-1])                       
               avst_rx_sop_d1_p2[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p2[i] && !avst_rx_inframe_p2[i-1])                                     
               avst_rx_sop_d1_p2[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p2[i] <= 1'b0;                    
         end         
         else if (active_segments == NUM_SEG/4)
         begin     
            if ((i==0) && avst_rx_inframe_p2[i] && !avst_rx_inframe_p2_d1[(NUM_SEG/4)-1])                       
               avst_rx_sop_d1_p2[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p2[i] && !avst_rx_inframe_p2[i-1])                                     
               avst_rx_sop_d1_p2[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p2[i] <= 1'b0;                    
         end 
         else
         begin
            avst_rx_sop_d1_p2[i] <= 1'b0;
         end
      end            
      else begin
         avst_rx_sop_d1_p2[i] <= 1'b0;
      end
   end 

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p3) 
   begin
      if (~i_rx_reset_n_p3)
         avst_rx_sop_d1_p3[i] <= 1'b0;
      else if (i_avst_rx_valid[3]) begin
         if (active_segments == NUM_SEG)
         begin     
            if ((i==0) && avst_rx_inframe_p3[i] && !avst_rx_inframe_p3_d1[NUM_SEG-1])                       
               avst_rx_sop_d1_p3[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p3[i] && !avst_rx_inframe_p3[i-1])                                     
               avst_rx_sop_d1_p3[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p3[i] <= 1'b0;                   
         end
         else if (active_segments == NUM_SEG/2)
         begin     
            if ((i==0) && avst_rx_inframe_p3[i] && !avst_rx_inframe_p3_d1[(NUM_SEG/2)-1])                       
               avst_rx_sop_d1_p3[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p3[i] && !avst_rx_inframe_p3[i-1])                                     
               avst_rx_sop_d1_p3[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p3[i] <= 1'b0;                   
         end         
         else if (active_segments == NUM_SEG/4)
         begin     
            if ((i==0) && avst_rx_inframe_p3[i] && !avst_rx_inframe_p3_d1[(NUM_SEG/4)-1])                       
               avst_rx_sop_d1_p3[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p3[i] && !avst_rx_inframe_p3[i-1])                                     
               avst_rx_sop_d1_p3[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p3[i] <= 1'b0;                   
         end 
         else
         begin
            avst_rx_sop_d1_p3[i] <= 1'b0;
         end
      end            
      else begin
         avst_rx_sop_d1_p3[i] <= 1'b0;
      end
   end      
      
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
   begin
      if (~i_rx_reset_n_p0)
         axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {8{1'b0}};               
      else if (avst_rx_ms_valid_d1_p0) begin
         if (tlast_segment_d1_p0[i])
            axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {(8){1'b1}} >> avst_rx_eop_empty_d1_p0[(i+1)*EMPTY_BITS-1:EMPTY_BITS*i];
         else if (avst_rx_inframe_p0_d1[i])
            axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {(8){1'b1}};
         else 
            axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {8{1'b0}};
      end
      else
         axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {8{1'b0}};   
   end

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1) 
   begin
      if (~i_rx_reset_n_p1)
         axist_rx_tkeep_segment_p1[(i+1)*8-1:8*i] <= {8{1'b0}};               
      else if (avst_rx_ms_valid_d1_p1) begin
         if (tlast_segment_d1_p1[i])
            axist_rx_tkeep_segment_p1[(i+1)*8-1:8*i] <= {(8){1'b1}} >> avst_rx_eop_empty_d1_p1[(i+1)*EMPTY_BITS-1:EMPTY_BITS*i];
         else if (avst_rx_inframe_p1_d1[i])
            axist_rx_tkeep_segment_p1[(i+1)*8-1:8*i] <= {(8){1'b1}};
         else 
            axist_rx_tkeep_segment_p1[(i+1)*8-1:8*i] <= {8{1'b0}};
      end
      else
           axist_rx_tkeep_segment_p1[(i+1)*8-1:8*i] <= {8{1'b0}};   
   end
      
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p2) 
   begin
      if (~i_rx_reset_n_p2)
         axist_rx_tkeep_segment_p2[(i+1)*8-1:8*i] <= {8{1'b0}};               
      else if (avst_rx_ms_valid_d1_p2) begin
         if (tlast_segment_d1_p2[i])
            axist_rx_tkeep_segment_p2[(i+1)*8-1:8*i] <= {(8){1'b1}} >> avst_rx_eop_empty_d1_p2[(i+1)*EMPTY_BITS-1:EMPTY_BITS*i];
         else if (avst_rx_inframe_p2_d1[i])
            axist_rx_tkeep_segment_p2[(i+1)*8-1:8*i] <= {(8){1'b1}};
         else 
            axist_rx_tkeep_segment_p2[(i+1)*8-1:8*i] <= {8{1'b0}};
      end
      else
           axist_rx_tkeep_segment_p2[(i+1)*8-1:8*i] <= {8{1'b0}};   
   end    

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p3) 
   begin
      if (~i_rx_reset_n_p3)
         axist_rx_tkeep_segment_p3[(i+1)*8-1:8*i] <= {8{1'b0}};               
      else if (avst_rx_ms_valid_d1_p3) begin
         if (tlast_segment_d1_p3[i])
            axist_rx_tkeep_segment_p3[(i+1)*8-1:8*i] <= {(8){1'b1}} >> avst_rx_eop_empty_d1_p3[(i+1)*EMPTY_BITS-1:EMPTY_BITS*i];
         else if (avst_rx_inframe_p3_d1[i])
            axist_rx_tkeep_segment_p3[(i+1)*8-1:8*i] <= {(8){1'b1}};
         else 
            axist_rx_tkeep_segment_p3[(i+1)*8-1:8*i] <= {8{1'b0}};
      end
      else
           axist_rx_tkeep_segment_p3[(i+1)*8-1:8*i] <= {8{1'b0}};   
   end   

      assign o_axist_rx_tlast_segment[i] = tlast_segment_d1[i];  
      
      assign tlast_segment_d1_p0[i] = (avst_rx_eop_d1_p0[i]) ? 1'b1 : 1'b0; 
      assign tlast_segment_d1_p1[i] = (avst_rx_eop_d1_p1[i]) ? 1'b1 : 1'b0; 
      assign tlast_segment_d1_p2[i] = (avst_rx_eop_d1_p2[i]) ? 1'b1 : 1'b0; 
      assign tlast_segment_d1_p3[i] = (avst_rx_eop_d1_p3[i]) ? 1'b1 : 1'b0; 
      
end 

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
   begin
       if (~i_rx_reset_n_p0) begin
          avst_rx_eop_empty_d1_p0 <= {NUM_SEGXEB{1'b0}};
       end
       else begin
          case (i_active_ports)
          3'd1:  
          begin  
             avst_rx_eop_empty_d1_p0 <=  i_avst_rx_eop_empty;
          end
          3'd2:
          begin    
             avst_rx_eop_empty_d1_p0 <=  {{NUM_SEG_BY_TWOXEB{1'b0}},i_avst_rx_eop_empty[NUM_SEG_BY_TWOXEB-1:0]}; //5:0, 11:0
          end        
          3'd4:
          begin    
             avst_rx_eop_empty_d1_p0 <=  {{NUM_SEG_BY_FOURXEBX3{1'b0}},i_avst_rx_eop_empty[NUM_SEG_BY_FOURXEB-1:0]}; //2:0, 5:0
          end         
          default: begin 
             avst_rx_eop_empty_d1_p0 <= {NUM_SEGXEB{1'b0}};
          end
          endcase         
      end
   end   
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1)
   begin
       if (~i_rx_reset_n_p1) begin
          avst_rx_eop_empty_d1_p1 <= {NUM_SEGXEB{1'b0}};
       end
       else begin
          case (i_active_ports)
          3'd1:  
          begin  
             avst_rx_eop_empty_d1_p1 <=  {NUM_SEGXEB{1'b0}};
          end
          3'd2:
          begin    
             avst_rx_eop_empty_d1_p1 <=  {NUM_SEGXEB{1'b0}};
          end        
          3'd4:
          begin    
             avst_rx_eop_empty_d1_p1 <=  {{NUM_SEG_BY_FOURXEBX3{1'b0}},i_avst_rx_eop_empty[NUM_SEG_BY_TWOXEB-1:NUM_SEG_BY_FOURXEB]}; //5:3, 11:6
          end         
          default: begin 
             avst_rx_eop_empty_d1_p1 <= {NUM_SEGXEB{1'b0}};          
          end
          endcase         
      end
   end      
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p2)
   begin
       if (~i_rx_reset_n_p2) begin
          avst_rx_eop_empty_d1_p2 <= {NUM_SEGXEB{1'b0}};
       end
       else begin
          case (i_active_ports)
          3'd1:  
          begin  
             avst_rx_eop_empty_d1_p2 <=  {NUM_SEGXEB{1'b0}};
          end
          3'd2:
          begin    
             avst_rx_eop_empty_d1_p2 <=  {{NUM_SEG_BY_TWOXEB{1'b0}},i_avst_rx_eop_empty[NUM_SEGXEB-1:NUM_SEG_BY_TWOXEB]}; //11:6, 23:12
          end        
          3'd4:
          begin    
             avst_rx_eop_empty_d1_p2 <=  {{NUM_SEG_BY_FOURXEBX3{1'b0}},i_avst_rx_eop_empty[NUM_SEG_BY_FOURXEBX3-1:NUM_SEG_BY_TWOXEB]}; //8:6, 17:12      
          end         
          default: begin 
             avst_rx_eop_empty_d1_p2 <= {NUM_SEGXEB{1'b0}};          
          end
          endcase         
      end
   end  

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p3)
   begin
       if (~i_rx_reset_n_p3) begin
          avst_rx_eop_empty_d1_p3 <= {NUM_SEGXEB{1'b0}};
       end
       else begin
          case (i_active_ports)
          3'd1:  
          begin  
             avst_rx_eop_empty_d1_p3 <=  {NUM_SEGXEB{1'b0}};
          end
          3'd2:
          begin    
             avst_rx_eop_empty_d1_p3 <=  {NUM_SEGXEB{1'b0}};
          end        
          3'd4:
          begin    
             avst_rx_eop_empty_d1_p3 <=  {{NUM_SEG_BY_FOURXEBX3{1'b0}},i_avst_rx_eop_empty[NUM_SEGXEB-1:NUM_SEG_BY_FOURXEBX3]}; //11:9, 23:18 
          end         
          default: begin 
             avst_rx_eop_empty_d1_p3 <= {NUM_SEGXEB{1'b0}};          
          end
          endcase         
      end
   end   

    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
    begin
        if (~i_rx_reset_n_p0) begin
           tlast_segment_d2_p0 <= '0;
        end
        else begin
           tlast_segment_d2_p0 <= tlast_segment_d1_p0;
        end
     end
     
    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1)
    begin
        if (~i_rx_reset_n_p1) begin
           tlast_segment_d2_p1 <= '0;
        end
        else begin
           tlast_segment_d2_p1 <= tlast_segment_d1_p1;
        end
     end   

    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p2)
    begin
        if (~i_rx_reset_n_p2) begin
           tlast_segment_d2_p2 <= '0;
        end
        else begin
           tlast_segment_d2_p2 <= tlast_segment_d1_p2;
        end
     end      
     
    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p3)
    begin
        if (~i_rx_reset_n_p3) begin
           tlast_segment_d2_p3 <= '0;
        end
        else begin
           tlast_segment_d2_p3 <= tlast_segment_d1_p3;
        end
     end     
       
      always @(*) begin
         case (i_active_ports)
         3'b001: //1port,2seg -> 1x50g/1x40g
         begin  
            o_axist_rx_tlast  = {3'b0, |tlast_segment_d1};
         end 
         3'b010: //2port,2seg -> 2x50g
         begin  
            o_axist_rx_tlast  = {1'b0,|tlast_segment_d1[NUM_SEG-1:NUM_SEG_BY_TWO], 1'b0, |tlast_segment_d1[NUM_SEG_BY_TWO-1:0]};   
         end  
         3'b100: //4port,1seg -> 4x25g
         begin  
            o_axist_rx_tlast  = {|tlast_segment_d1[NUM_SEG-1:NUM_SEG_BY_FOURX3],|tlast_segment_d1[NUM_SEG_BY_FOURX3-1:NUM_SEG_BY_TWO],
                                  |tlast_segment_d1[NUM_SEG_BY_TWO-1:NUM_SEG_BY_FOUR],|tlast_segment_d1[NUM_SEG_BY_FOUR-1:0]};
         end             
         default: begin 
            o_axist_rx_tlast = {NUM_SEG{1'd0}}; 
         end
         endcase          
      end          

   always @(*) begin
      case (i_active_ports)
      3'd1:  //same logic for 1 port, irrespective of segment
      begin  
         avst_rx_inframe_p0       = i_avst_rx_inframe; //4 bits
         avst_rx_inframe_p1       = {NUM_SEG{1'b0}};
         avst_rx_inframe_p2       = {NUM_SEG{1'b0}};
         avst_rx_inframe_p3       = {NUM_SEG{1'b0}};
         tlast_segment_d1         = tlast_segment_d2_p0;
         o_axist_rx_tkeep_segment = axist_rx_tkeep_segment_p0;
      end 
      3'd2:
      begin  
         avst_rx_inframe_p0       = {{NUM_SEG_BY_TWO{1'b0}},i_avst_rx_inframe[NUM_SEG_BY_TWO-1:0]};       
         avst_rx_inframe_p1       = {NUM_SEG{1'b0}};
         avst_rx_inframe_p2       = {{NUM_SEG_BY_TWO{1'b0}},i_avst_rx_inframe[NUM_SEG-1:NUM_SEG_BY_TWO]};
         avst_rx_inframe_p3       = {NUM_SEG{1'b0}};
         tlast_segment_d1         = {tlast_segment_d2_p2[NUM_SEG_BY_TWO-1:0],tlast_segment_d2_p0[NUM_SEG_BY_TWO-1:0]}; //valid bits are in LSB of P0 and P1 signals         
         o_axist_rx_tkeep_segment = {axist_rx_tkeep_segment_p2[(NUM_SEG_BY_TWO*8)-1:0],axist_rx_tkeep_segment_p0[(NUM_SEG_BY_TWO*8)-1:0]};
      end        
      3'd4:
      begin  
         avst_rx_inframe_p0       = {{NUM_SEG_BY_FOURX3{1'b0}},i_avst_rx_inframe[NUM_SEG_BY_FOUR-1:0]};
         avst_rx_inframe_p1       = {{NUM_SEG_BY_FOURX3{1'b0}},i_avst_rx_inframe[NUM_SEG_BY_TWO-1:NUM_SEG_BY_FOUR]};
         avst_rx_inframe_p2       = {{NUM_SEG_BY_FOURX3{1'b0}},i_avst_rx_inframe[NUM_SEG_BY_FOURX3-1:NUM_SEG_BY_TWO]};
         avst_rx_inframe_p3       = {{NUM_SEG_BY_FOURX3{1'b0}},i_avst_rx_inframe[NUM_SEG-1:NUM_SEG_BY_FOURX3]};         
         tlast_segment_d1         = {tlast_segment_d2_p3[NUM_SEG_BY_FOUR-1:0],tlast_segment_d2_p2[NUM_SEG_BY_FOUR-1:0],
                                     tlast_segment_d2_p1[NUM_SEG_BY_FOUR-1:0],tlast_segment_d2_p0[NUM_SEG_BY_FOUR-1:0]};         
         o_axist_rx_tkeep_segment = {axist_rx_tkeep_segment_p3[(NUM_SEG_BY_FOUR*8)-1:0],axist_rx_tkeep_segment_p2[(NUM_SEG_BY_FOUR*8)-1:0],
                                     axist_rx_tkeep_segment_p1[(NUM_SEG_BY_FOUR*8)-1:0],axist_rx_tkeep_segment_p0[(NUM_SEG_BY_FOUR*8)-1:0]};
      end         
      default: begin 
         avst_rx_inframe_p0 = {NUM_SEG{1'b0}};
         avst_rx_inframe_p1 = {NUM_SEG{1'b0}};
         avst_rx_inframe_p2 = {NUM_SEG{1'b0}};
         avst_rx_inframe_p3 = {NUM_SEG{1'b0}};
         tlast_segment_d1   = {NUM_SEG{1'd0}};
         o_axist_rx_tkeep_segment = {(NUM_SEG*8){1'b0}};             
      end
      endcase
   end 
      
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
   begin
       if (~i_rx_reset_n_p0) begin
          avst_rx_inframe_p0_d1 <= {NUM_SEG{1'b0}};
       end            
       else 
       begin 
          avst_rx_inframe_p0_d1 <= i_avst_rx_valid[0]? avst_rx_inframe_p0:avst_rx_inframe_p0_d1;
       end       
   end        

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1)
   begin
       if (~i_rx_reset_n_p1) begin
          avst_rx_inframe_p1_d1 <= {NUM_SEG{1'b0}};
       end            
       else 
       begin 
          avst_rx_inframe_p1_d1 <= i_avst_rx_valid[1]? avst_rx_inframe_p1:avst_rx_inframe_p1_d1;            
       end       
   end     

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p2)
   begin
       if (~i_rx_reset_n_p2) begin
          avst_rx_inframe_p2_d1 <= {NUM_SEG{1'b0}};
       end            
       else 
       begin 
          avst_rx_inframe_p2_d1 <= i_avst_rx_valid[2]? avst_rx_inframe_p2:avst_rx_inframe_p2_d1;            
       end       
   end   
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p3)
   begin
       if (~i_rx_reset_n_p3) begin
          avst_rx_inframe_p3_d1 <= {NUM_SEG{1'b0}};
       end            
       else 
       begin 
          avst_rx_inframe_p3_d1 <= i_avst_rx_valid[3]? avst_rx_inframe_p3:avst_rx_inframe_p3_d1;            
       end       
   end      
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
   begin
      if (~i_rx_reset_n_p0) begin
         o_axist_rx_tuser_valid[0] <= '0; 
         o_axist_rx_tuser_valid_p2[0] <= '0;  
      end
      else begin 
         o_axist_rx_tuser_valid[0] <= (avst_rx_valid_d1_p0 && |avst_rx_sop_d1_p0) ? 1'b1 : 1'b0;
         o_axist_rx_tuser_valid_p2[0] <= 1'b0;       
      end
   end
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1) 
   begin
      if (~i_rx_reset_n_p1) begin
         o_axist_rx_tuser_valid[1] <= '0; 
         o_axist_rx_tuser_valid_p2[1] <= '0;  
      end
      else begin 
         o_axist_rx_tuser_valid[1] <= (avst_rx_valid_d1_p1 && |avst_rx_sop_d1_p1) ? 1'b1 : 1'b0;
         o_axist_rx_tuser_valid_p2[1] <= 1'b0;  
      end
   end   
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p2) 
   begin
      if (~i_rx_reset_n_p2) begin
         o_axist_rx_tuser_valid[2] <= '0; 
         o_axist_rx_tuser_valid_p2[2] <= '0;  
      end
      else begin 
         o_axist_rx_tuser_valid[2] <= (avst_rx_valid_d1_p2 && |avst_rx_sop_d1_p2) ? 1'b1 : 1'b0;  
         o_axist_rx_tuser_valid_p2[2] <= 1'b0;      
      end
   end    

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p3) 
   begin
      if (~i_rx_reset_n_p3) begin
         o_axist_rx_tuser_valid[3] <= '0; 
         o_axist_rx_tuser_valid_p2[3] <= '0;  
      end
      else begin 
         o_axist_rx_tuser_valid[3] <= (avst_rx_valid_d1_p3 && |avst_rx_sop_d1_p3) ? 1'b1 : 1'b0;
         o_axist_rx_tuser_valid_p2[3] <= '0;
      end
   end      
   
   assign  o_axist_rx_tkeep = {NO_OF_BYTES{1'b0}};   
   assign  o_axist_rx_tdata = (i_active_ports == 3'd1)? avst_rx_data_d2_p0 : (i_active_ports == 3'd2)? {avst_rx_data_d2_p2[AVST_DW_BY_TWO-1:0],avst_rx_data_d2_p0[AVST_DW_BY_TWO-1:0]} :
                              {avst_rx_data_d2_p3[AVST_DW_BY_FOUR-1:0],avst_rx_data_d2_p2[AVST_DW_BY_FOUR-1:0],avst_rx_data_d2_p1[AVST_DW_BY_FOUR-1:0],avst_rx_data_d2_p0[AVST_DW_BY_FOUR-1:0]};
   
   assign  avst_rx_ms_valid_d1_p0 = avst_rx_valid_d1_p0 && ((|avst_rx_inframe_p0_d1) || (|avst_rx_eop_d1_p0));     
   assign  avst_rx_ms_valid_d1_p1 = avst_rx_valid_d1_p1 && ((|avst_rx_inframe_p1_d1) || (|avst_rx_eop_d1_p1));     
   assign  avst_rx_ms_valid_d1_p2 = avst_rx_valid_d1_p2 && ((|avst_rx_inframe_p2_d1) || (|avst_rx_eop_d1_p2));     
   assign  avst_rx_ms_valid_d1_p3 = avst_rx_valid_d1_p3 && ((|avst_rx_inframe_p3_d1) || (|avst_rx_eop_d1_p3));    

end

else if (AVST_MODE == "MAC_SEGMENTED" && ((PORT_PROFILE == "400GAUI-8") || (PORT_PROFILE == "400GAUI-4"))) begin : MAC_SEGMENTED_4P_400G 
genvar i;

for (i=0; i<NUM_SEG; i=i+1) begin :BRIDGE_MS2MP_4P

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
   begin
      if (~i_rx_reset_n_p0)
         avst_rx_eop_d1_p0[i] <= 1'b0;
      else if (i_avst_rx_valid[0]) begin
         if (active_segments == NUM_SEG)
         begin     
            if ((i==0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0_d1[NUM_SEG-1])                       
               avst_rx_eop_d1_p0[i] <= 1'b1;
            else if ((i!=0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0[i-1])                                     
               avst_rx_eop_d1_p0[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p0[i] <= 1'b0;                   
         end
         else if (active_segments == NUM_SEG/2)
         begin     
            if ((i==0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0_d1[(NUM_SEG/2)-1])                       
               avst_rx_eop_d1_p0[i] <= 1'b1;
            else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0[i-1])                                     
               avst_rx_eop_d1_p0[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p0[i] <= 1'b0;                   
         end         
         else if (active_segments == NUM_SEG/4)
         begin     
            if ((i==0) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0_d1[(NUM_SEG/4)-1])                       
               avst_rx_eop_d1_p0[i] <= 1'b1;
            else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p0[i] && avst_rx_inframe_p0[i-1])                                     
               avst_rx_eop_d1_p0[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p0[i] <= 1'b0;                    
         end 
         else
         begin
            avst_rx_eop_d1_p0[i] <= 1'b0;
         end
      end            
      else begin
         avst_rx_eop_d1_p0[i] <= 1'b0;
      end
   end
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1) 
   begin
      if (~i_rx_reset_n_p1)
         avst_rx_eop_d1_p1[i] <= 1'b0;
      else if (i_avst_rx_valid[1]) begin
         if (active_segments == NUM_SEG)
         begin     
            if ((i==0) && !avst_rx_inframe_p1[i] && avst_rx_inframe_p1_d1[NUM_SEG-1])                       
               avst_rx_eop_d1_p1[i] <= 1'b1;
            else if ((i!=0) && !avst_rx_inframe_p1[i] && avst_rx_inframe_p1[i-1])                                     
               avst_rx_eop_d1_p1[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p1[i] <= 1'b0;                   
         end
         else if (active_segments == NUM_SEG/2)
         begin     
            if ((i==0) && !avst_rx_inframe_p1[i] && avst_rx_inframe_p1_d1[(NUM_SEG/2)-1])                       
               avst_rx_eop_d1_p1[i] <= 1'b1;
            else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p1[i] && avst_rx_inframe_p1[i-1])                                     
               avst_rx_eop_d1_p1[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p1[i] <= 1'b0;                    
         end         
         else if (active_segments == NUM_SEG/4)
         begin     
            if ((i==0) && !avst_rx_inframe_p1[i] && avst_rx_inframe_p1_d1[(NUM_SEG/4)-1])                       
               avst_rx_eop_d1_p1[i] <= 1'b1;
            else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p1[i] && avst_rx_inframe_p1[i-1])                                     
               avst_rx_eop_d1_p1[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p1[i] <= 1'b0;                   
         end 
         else
         begin
            avst_rx_eop_d1_p1[i] <= 1'b0;
         end
      end            
      else begin
         avst_rx_eop_d1_p1[i] <= 1'b0;
      end
   end  

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p2) 
   begin
      if (~i_rx_reset_n_p2)
         avst_rx_eop_d1_p2[i] <= 1'b0;
      else if (i_avst_rx_valid[2]) begin
         if (active_segments == NUM_SEG)
         begin     
            if ((i==0) && !avst_rx_inframe_p2[i] && avst_rx_inframe_p2_d1[NUM_SEG-1])                       
               avst_rx_eop_d1_p2[i] <= 1'b1;
            else if ((i!=0) && !avst_rx_inframe_p2[i] && avst_rx_inframe_p2[i-1])                                     
               avst_rx_eop_d1_p2[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p2[i] <= 1'b0;                   
         end
         else if (active_segments == NUM_SEG/2)
         begin     
            if ((i==0) && !avst_rx_inframe_p2[i] && avst_rx_inframe_p2_d1[(NUM_SEG/2)-1])                       
               avst_rx_eop_d1_p2[i] <= 1'b1;
            else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p2[i] && avst_rx_inframe_p2[i-1])                                     
               avst_rx_eop_d1_p2[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p2[i] <= 1'b0;                    
         end         
         else if (active_segments == NUM_SEG/4)
         begin     
            if ((i==0) && !avst_rx_inframe_p2[i] && avst_rx_inframe_p2_d1[(NUM_SEG/4)-1])                       
               avst_rx_eop_d1_p2[i] <= 1'b1;
            else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p2[i] && avst_rx_inframe_p2[i-1])                                     
               avst_rx_eop_d1_p2[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p2[i] <= 1'b0;                    
         end 
         else
         begin
            avst_rx_eop_d1_p2[i] <= 1'b0;
         end
      end            
      else begin
         avst_rx_eop_d1_p2[i] <= 1'b0;
      end
   end 
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p3) 
   begin
      if (~i_rx_reset_n_p3)
         avst_rx_eop_d1_p3[i] <= 1'b0;
      else if (i_avst_rx_valid[3]) begin
         if (active_segments == NUM_SEG)
         begin     
            if ((i==0) && !avst_rx_inframe_p3[i] && avst_rx_inframe_p3_d1[NUM_SEG-1])                       
               avst_rx_eop_d1_p3[i] <= 1'b1;
            else if ((i!=0) && !avst_rx_inframe_p3[i] && avst_rx_inframe_p3[i-1])                                     
               avst_rx_eop_d1_p3[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p3[i] <= 1'b0;                 
         end
         else if (active_segments == NUM_SEG/2)
         begin     
            if ((i==0) && !avst_rx_inframe_p3[i] && avst_rx_inframe_p3_d1[(NUM_SEG/2)-1])                       
               avst_rx_eop_d1_p3[i] <= 1'b1;
            else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p3[i] && avst_rx_inframe_p3[i-1])                                     
               avst_rx_eop_d1_p3[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p3[i] <= 1'b0;                  
         end         
         else if (active_segments == NUM_SEG/4)
         begin     
            if ((i==0) && !avst_rx_inframe_p3[i] && avst_rx_inframe_p3_d1[(NUM_SEG/4)-1])                       
               avst_rx_eop_d1_p3[i] <= 1'b1;
            else if (((i!=0) && (i<active_segments)) && !avst_rx_inframe_p3[i] && avst_rx_inframe_p3[i-1])                                     
               avst_rx_eop_d1_p3[i] <= 1'b1;
            else    
               avst_rx_eop_d1_p3[i] <= 1'b0;                 
         end 
         else
         begin
            avst_rx_eop_d1_p3[i] <= 1'b0;
         end
      end            
      else begin
         avst_rx_eop_d1_p3[i] <= 1'b0;
      end
   end 
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
   begin
      if (~i_rx_reset_n_p0)
         avst_rx_sop_d1_p0[i] <= 1'b0;
      else if (i_avst_rx_valid[0]) begin
         if (active_segments == NUM_SEG)
         begin     
            if ((i==0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0_d1[NUM_SEG-1])                       
               avst_rx_sop_d1_p0[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0[i-1])                                     
               avst_rx_sop_d1_p0[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p0[i] <= 1'b0;                   
         end
         else if (active_segments == NUM_SEG/2)
         begin     
            if ((i==0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0_d1[(NUM_SEG/2)-1])                       
               avst_rx_sop_d1_p0[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0[i-1])                                     
               avst_rx_sop_d1_p0[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p0[i] <= 1'b0;                  
         end         
         else if (active_segments == NUM_SEG/4)
         begin     
            if ((i==0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0_d1[(NUM_SEG/4)-1])                       
               avst_rx_sop_d1_p0[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p0[i] && !avst_rx_inframe_p0[i-1])                                     
               avst_rx_sop_d1_p0[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p0[i] <= 1'b0;                   
         end 
         else
         begin
            avst_rx_sop_d1_p0[i] <= 1'b0;
         end
      end            
      else begin
         avst_rx_sop_d1_p0[i] <= 1'b0;
      end
   end   
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1) 
   begin
      if (~i_rx_reset_n_p1)
         avst_rx_sop_d1_p1[i] <= 1'b0;
      else if (i_avst_rx_valid[1]) begin
         if (active_segments == NUM_SEG)
         begin     
            if ((i==0) && avst_rx_inframe_p1[i] && !avst_rx_inframe_p1_d1[NUM_SEG-1])                       
               avst_rx_sop_d1_p1[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p1[i] && !avst_rx_inframe_p1[i-1])                                     
               avst_rx_sop_d1_p1[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p1[i] <= 1'b0;                   
         end
         else if (active_segments == NUM_SEG/2)
         begin     
            if ((i==0) && avst_rx_inframe_p1[i] && !avst_rx_inframe_p1_d1[(NUM_SEG/2)-1])                       
               avst_rx_sop_d1_p1[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p1[i] && !avst_rx_inframe_p1[i-1])                                     
               avst_rx_sop_d1_p1[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p1[i] <= 1'b0;                    
         end         
         else if (active_segments == NUM_SEG/4)
         begin     
            if ((i==0) && avst_rx_inframe_p1[i] && !avst_rx_inframe_p1_d1[(NUM_SEG/4)-1])                       
               avst_rx_sop_d1_p1[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p1[i] && !avst_rx_inframe_p1[i-1])                                     
               avst_rx_sop_d1_p1[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p1[i] <= 1'b0;                   
         end 
         else
         begin
            avst_rx_sop_d1_p1[i] <= 1'b0;
         end
      end            
      else begin
         avst_rx_sop_d1_p1[i] <= 1'b0;
      end
   end     

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p2) 
   begin
      if (~i_rx_reset_n_p2)
         avst_rx_sop_d1_p2[i] <= 1'b0;
      else if (i_avst_rx_valid[2]) begin
         if (active_segments == NUM_SEG)
         begin     
            if ((i==0) && avst_rx_inframe_p2[i] && !avst_rx_inframe_p2_d1[NUM_SEG-1])                       
               avst_rx_sop_d1_p2[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p2[i] && !avst_rx_inframe_p2[i-1])                                     
               avst_rx_sop_d1_p2[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p2[i] <= 1'b0;                   
         end
         else if (active_segments == NUM_SEG/2)
         begin     
            if ((i==0) && avst_rx_inframe_p2[i] && !avst_rx_inframe_p2_d1[(NUM_SEG/2)-1])                       
               avst_rx_sop_d1_p2[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p2[i] && !avst_rx_inframe_p2[i-1])                                     
               avst_rx_sop_d1_p2[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p2[i] <= 1'b0;                    
         end         
         else if (active_segments == NUM_SEG/4)
         begin     
            if ((i==0) && avst_rx_inframe_p2[i] && !avst_rx_inframe_p2_d1[(NUM_SEG/4)-1])                       
               avst_rx_sop_d1_p2[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p2[i] && !avst_rx_inframe_p2[i-1])                                     
               avst_rx_sop_d1_p2[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p2[i] <= 1'b0;                    
         end 
         else
         begin
            avst_rx_sop_d1_p2[i] <= 1'b0;
         end
      end            
      else begin
         avst_rx_sop_d1_p2[i] <= 1'b0;
      end
   end 

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p3) 
   begin
      if (~i_rx_reset_n_p3)
         avst_rx_sop_d1_p3[i] <= 1'b0;
      else if (i_avst_rx_valid[3]) begin
         if (active_segments == NUM_SEG)
         begin     
            if ((i==0) && avst_rx_inframe_p3[i] && !avst_rx_inframe_p3_d1[NUM_SEG-1])                       
               avst_rx_sop_d1_p3[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p3[i] && !avst_rx_inframe_p3[i-1])                                     
               avst_rx_sop_d1_p3[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p3[i] <= 1'b0;                   
         end
         else if (active_segments == NUM_SEG/2)
         begin     
            if ((i==0) && avst_rx_inframe_p3[i] && !avst_rx_inframe_p3_d1[(NUM_SEG/2)-1])                       
               avst_rx_sop_d1_p3[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p3[i] && !avst_rx_inframe_p3[i-1])                                     
               avst_rx_sop_d1_p3[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p3[i] <= 1'b0;                   
         end         
         else if (active_segments == NUM_SEG/4)
         begin     
            if ((i==0) && avst_rx_inframe_p3[i] && !avst_rx_inframe_p3_d1[(NUM_SEG/4)-1])                       
               avst_rx_sop_d1_p3[i] <= 1'b1;
            else if ((i!=0) && avst_rx_inframe_p3[i] && !avst_rx_inframe_p3[i-1])                                     
               avst_rx_sop_d1_p3[i] <= 1'b1;
            else    
               avst_rx_sop_d1_p3[i] <= 1'b0;                   
         end 
         else
         begin
            avst_rx_sop_d1_p3[i] <= 1'b0;
         end
      end            
      else begin
         avst_rx_sop_d1_p3[i] <= 1'b0;
      end
   end      
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin
         if (~i_rx_reset_n_p0)
            axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {8{1'b0}};               
         else if (avst_rx_ms_valid_d1_p0) begin
            if (tlast_segment_d1_p0[i])
               axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {(8){1'b1}} >> avst_rx_eop_empty_d1_p0[(i+1)*EMPTY_BITS-1:EMPTY_BITS*i];
            else if (avst_rx_inframe_p0_d1[i])
               axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {(8){1'b1}};
            else 
               axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {8{1'b0}};
         end
         else
            axist_rx_tkeep_segment_p0[(i+1)*8-1:8*i] <= {8{1'b0}};   
      end

      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1) 
      begin
         if (~i_rx_reset_n_p1)
            axist_rx_tkeep_segment_p1[(i+1)*8-1:8*i] <= {8{1'b0}};               
         else if (avst_rx_ms_valid_d1_p1) begin
            if (tlast_segment_d1_p1[i])
               axist_rx_tkeep_segment_p1[(i+1)*8-1:8*i] <= {(8){1'b1}} >> avst_rx_eop_empty_d1_p1[(i+1)*EMPTY_BITS-1:EMPTY_BITS*i];
            else if (avst_rx_inframe_p1_d1[i])
               axist_rx_tkeep_segment_p1[(i+1)*8-1:8*i] <= {(8){1'b1}};
            else 
               axist_rx_tkeep_segment_p1[(i+1)*8-1:8*i] <= {8{1'b0}};
         end
         else
              axist_rx_tkeep_segment_p1[(i+1)*8-1:8*i] <= {8{1'b0}};   
      end
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p2) 
      begin
         if (~i_rx_reset_n_p2)
            axist_rx_tkeep_segment_p2[(i+1)*8-1:8*i] <= {8{1'b0}};               
         else if (avst_rx_ms_valid_d1_p2) begin
            if (tlast_segment_d1_p2[i])
               axist_rx_tkeep_segment_p2[(i+1)*8-1:8*i] <= {(8){1'b1}} >> avst_rx_eop_empty_d1_p2[(i+1)*EMPTY_BITS-1:EMPTY_BITS*i];
            else if (avst_rx_inframe_p2_d1[i])
               axist_rx_tkeep_segment_p2[(i+1)*8-1:8*i] <= {(8){1'b1}};
            else 
               axist_rx_tkeep_segment_p2[(i+1)*8-1:8*i] <= {8{1'b0}};
         end
         else
              axist_rx_tkeep_segment_p2[(i+1)*8-1:8*i] <= {8{1'b0}};   
      end    

      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p3) 
      begin
         if (~i_rx_reset_n_p3)
            axist_rx_tkeep_segment_p3[(i+1)*8-1:8*i] <= {8{1'b0}};               
         else if (avst_rx_ms_valid_d1_p3) begin
            if (tlast_segment_d1_p3[i])
               axist_rx_tkeep_segment_p3[(i+1)*8-1:8*i] <= {(8){1'b1}} >> avst_rx_eop_empty_d1_p3[(i+1)*EMPTY_BITS-1:EMPTY_BITS*i];
            else if (avst_rx_inframe_p3_d1[i])
               axist_rx_tkeep_segment_p3[(i+1)*8-1:8*i] <= {(8){1'b1}};
            else 
               axist_rx_tkeep_segment_p3[(i+1)*8-1:8*i] <= {8{1'b0}};
         end
         else
              axist_rx_tkeep_segment_p3[(i+1)*8-1:8*i] <= {8{1'b0}};   
      end   
      
      assign o_axist_rx_tlast_segment[i] = tlast_segment_d1[i];
      
      assign tlast_segment_d1_p0[i] = (avst_rx_eop_d1_p0[i]) ? 1'b1 : 1'b0; 
      assign tlast_segment_d1_p1[i] = (avst_rx_eop_d1_p1[i]) ? 1'b1 : 1'b0; 
      assign tlast_segment_d1_p2[i] = (avst_rx_eop_d1_p2[i]) ? 1'b1 : 1'b0; 
      assign tlast_segment_d1_p3[i] = (avst_rx_eop_d1_p3[i]) ? 1'b1 : 1'b0; 
      
end 

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
   begin
       if (~i_rx_reset_n_p0) begin
          avst_rx_eop_empty_d1_p0 <= {NUM_SEGXEB{1'b0}};
       end
       else begin
          case (i_active_ports)
          3'd1:  
          begin  
             avst_rx_eop_empty_d1_p0 <=  i_avst_rx_eop_empty;
          end
          3'd2:
          begin    
             avst_rx_eop_empty_d1_p0 <=  {{NUM_SEG_BY_TWOXEB{1'b0}},i_avst_rx_eop_empty[NUM_SEG_BY_TWOXEB-1:0]}; //5:0, 11:0
          end        
          3'd4:
          begin    
             avst_rx_eop_empty_d1_p0 <=  {{NUM_SEG_BY_FOURXEBX3{1'b0}},i_avst_rx_eop_empty[NUM_SEG_BY_FOURXEB-1:0]}; //2:0, 5:0
          end         
          default: begin 
             avst_rx_eop_empty_d1_p0 <= {NUM_SEGXEB{1'b0}};
          end
          endcase         
      end
   end   
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1)
   begin
       if (~i_rx_reset_n_p1) begin
          avst_rx_eop_empty_d1_p1 <= {NUM_SEGXEB{1'b0}};
       end
       else begin
          case (i_active_ports)
          3'd1:  
          begin  
             avst_rx_eop_empty_d1_p1 <=  {NUM_SEGXEB{1'b0}};
          end
          3'd2:
          begin    
             avst_rx_eop_empty_d1_p1 <=  {NUM_SEGXEB{1'b0}};
          end        
          3'd4:
          begin    
             avst_rx_eop_empty_d1_p1 <=  {{NUM_SEG_BY_FOURXEBX3{1'b0}},i_avst_rx_eop_empty[NUM_SEG_BY_TWOXEB-1:NUM_SEG_BY_FOURXEB]}; //5:3, 11:6
          end         
          default: begin 
             avst_rx_eop_empty_d1_p1 <= {NUM_SEGXEB{1'b0}};          
          end
          endcase         
      end
   end      
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p2)
   begin
       if (~i_rx_reset_n_p2) begin
          avst_rx_eop_empty_d1_p2 <= {NUM_SEGXEB{1'b0}};
       end
       else begin
          case (i_active_ports)
          3'd1:  
          begin  
             avst_rx_eop_empty_d1_p2 <=  {NUM_SEGXEB{1'b0}};
          end
          3'd2:
          begin    
             avst_rx_eop_empty_d1_p2 <=  {{NUM_SEG_BY_TWOXEB{1'b0}},i_avst_rx_eop_empty[NUM_SEGXEB-1:NUM_SEG_BY_TWOXEB]}; //11:6, 23:12
          end        
          3'd4:
          begin    
             avst_rx_eop_empty_d1_p2 <=  {{NUM_SEG_BY_FOURXEBX3{1'b0}},i_avst_rx_eop_empty[NUM_SEG_BY_FOURXEBX3-1:NUM_SEG_BY_TWOXEB]}; //8:6, 17:12      
          end         
          default: begin 
             avst_rx_eop_empty_d1_p2 <= {NUM_SEGXEB{1'b0}};          
          end
          endcase         
      end
   end     

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p3)
   begin
       if (~i_rx_reset_n_p3) begin
          avst_rx_eop_empty_d1_p3 <= {NUM_SEGXEB{1'b0}};
       end
       else begin
          case (i_active_ports)
          3'd1:  
          begin  
             avst_rx_eop_empty_d1_p3 <=  {NUM_SEGXEB{1'b0}};
          end
          3'd2:
          begin    
             avst_rx_eop_empty_d1_p3 <=  {NUM_SEGXEB{1'b0}};
          end        
          3'd4:
          begin    
             avst_rx_eop_empty_d1_p3 <=  {{NUM_SEG_BY_FOURXEBX3{1'b0}},i_avst_rx_eop_empty[NUM_SEGXEB-1:NUM_SEG_BY_FOURXEBX3]}; //11:9, 23:18 
          end         
          default: begin 
             avst_rx_eop_empty_d1_p3 <= {NUM_SEGXEB{1'b0}};          
          end
          endcase         
      end
   end        

    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
    begin
        if (~i_rx_reset_n_p0) begin
           tlast_segment_d2_p0 <= '0;
        end
        else begin
           tlast_segment_d2_p0 <= tlast_segment_d1_p0;
        end
     end
     
    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1)
    begin
        if (~i_rx_reset_n_p1) begin
           tlast_segment_d2_p1 <= '0;
        end
        else begin
           tlast_segment_d2_p1 <= tlast_segment_d1_p1;
        end
     end   

    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p2)
    begin
        if (~i_rx_reset_n_p2) begin
           tlast_segment_d2_p2 <= '0;
        end
        else begin
           tlast_segment_d2_p2 <= tlast_segment_d1_p2;
        end
     end      
     
    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p3)
    begin
        if (~i_rx_reset_n_p3) begin
           tlast_segment_d2_p3 <= '0;
        end
        else begin
           tlast_segment_d2_p3 <= tlast_segment_d1_p3;
        end
     end     
     
   always @(*) begin
      case (i_active_ports)
      3'b001: //1port,2seg -> 1x50g/1x40g
      begin  
         o_axist_rx_tlast  = {3'b0, |tlast_segment_d1};
      end 
      3'b010: //2port,2seg -> 2x50g
      begin  
         o_axist_rx_tlast  = {1'b0,|tlast_segment_d1[NUM_SEG-1:NUM_SEG_BY_TWO], 1'b0, |tlast_segment_d1[NUM_SEG_BY_TWO-1:0]};   
      end  
      3'b100: //4port,1seg -> 4x25g
      begin  
         o_axist_rx_tlast  = {|tlast_segment_d1[NUM_SEG-1:NUM_SEG_BY_FOURX3],|tlast_segment_d1[NUM_SEG_BY_FOURX3-1:NUM_SEG_BY_TWO],
                               |tlast_segment_d1[NUM_SEG_BY_TWO-1:NUM_SEG_BY_FOUR],|tlast_segment_d1[NUM_SEG_BY_FOUR-1:0]};
      end             
      default: begin 
         o_axist_rx_tlast = {NUM_SEG{1'd0}}; 
      end
      endcase          
   end            

   always @(*) begin
      case (i_active_ports)
      3'd1:  //same logic for 1 port, irrespective of segment
      begin  
         avst_rx_inframe_p0       = i_avst_rx_inframe; //4 bits
         avst_rx_inframe_p1       = {NUM_SEG{1'b0}};
         avst_rx_inframe_p2       = {NUM_SEG{1'b0}};
         avst_rx_inframe_p3       = {NUM_SEG{1'b0}};
         tlast_segment_d1         = tlast_segment_d2_p0;
         o_axist_rx_tkeep_segment = axist_rx_tkeep_segment_p0;
      end 
      3'd2:
      begin  
         avst_rx_inframe_p0       = {{NUM_SEG_BY_TWO{1'b0}},i_avst_rx_inframe[NUM_SEG_BY_TWO-1:0]};       
         avst_rx_inframe_p1       = {NUM_SEG{1'b0}};
         avst_rx_inframe_p2       = {{NUM_SEG_BY_TWO{1'b0}},i_avst_rx_inframe[NUM_SEG-1:NUM_SEG_BY_TWO]};
         avst_rx_inframe_p3       = {NUM_SEG{1'b0}};
         tlast_segment_d1         = {tlast_segment_d2_p2[NUM_SEG_BY_TWO-1:0],tlast_segment_d2_p0[NUM_SEG_BY_TWO-1:0]}; //valid bits are in LSB of P0 and P1 signals         
         o_axist_rx_tkeep_segment = {axist_rx_tkeep_segment_p2[(NUM_SEG_BY_TWO*8)-1:0],axist_rx_tkeep_segment_p0[(NUM_SEG_BY_TWO*8)-1:0]};
      end        
      3'd4:
      begin  
         avst_rx_inframe_p0       = {{NUM_SEG_BY_FOURX3{1'b0}},i_avst_rx_inframe[NUM_SEG_BY_FOUR-1:0]};
         avst_rx_inframe_p1       = {{NUM_SEG_BY_FOURX3{1'b0}},i_avst_rx_inframe[NUM_SEG_BY_TWO-1:NUM_SEG_BY_FOUR]};
         avst_rx_inframe_p2       = {{NUM_SEG_BY_FOURX3{1'b0}},i_avst_rx_inframe[NUM_SEG_BY_FOURX3-1:NUM_SEG_BY_TWO]};
         avst_rx_inframe_p3       = {{NUM_SEG_BY_FOURX3{1'b0}},i_avst_rx_inframe[NUM_SEG-1:NUM_SEG_BY_FOURX3]};         
         tlast_segment_d1         = {tlast_segment_d2_p3[NUM_SEG_BY_FOUR-1:0],tlast_segment_d2_p2[NUM_SEG_BY_FOUR-1:0],
                                     tlast_segment_d2_p1[NUM_SEG_BY_FOUR-1:0],tlast_segment_d2_p0[NUM_SEG_BY_FOUR-1:0]};         
         o_axist_rx_tkeep_segment = {axist_rx_tkeep_segment_p3[(NUM_SEG_BY_FOUR*8)-1:0],axist_rx_tkeep_segment_p2[(NUM_SEG_BY_FOUR*8)-1:0],
                                     axist_rx_tkeep_segment_p1[(NUM_SEG_BY_FOUR*8)-1:0],axist_rx_tkeep_segment_p0[(NUM_SEG_BY_FOUR*8)-1:0]};
      end         
      default: begin 
         avst_rx_inframe_p0 = {NUM_SEG{1'b0}};
         avst_rx_inframe_p1 = {NUM_SEG{1'b0}};
         avst_rx_inframe_p2 = {NUM_SEG{1'b0}};
         avst_rx_inframe_p3 = {NUM_SEG{1'b0}};
         tlast_segment_d1   = {NUM_SEG{1'd0}};
         o_axist_rx_tkeep_segment = {(NUM_SEG*8){1'b0}};             
      end
      endcase
   end 
      
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)
   begin
       if (~i_rx_reset_n_p0) begin
          avst_rx_inframe_p0_d1 <= {NUM_SEG{1'b0}};
       end            
       else 
       begin 
          avst_rx_inframe_p0_d1 <= i_avst_rx_valid[0]? avst_rx_inframe_p0: avst_rx_inframe_p0_d1;
       end       
   end  

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1)
   begin
       if (~i_rx_reset_n_p1) begin
          avst_rx_inframe_p1_d1 <= {NUM_SEG{1'b0}};
       end            
       else 
       begin 
          avst_rx_inframe_p1_d1 <= i_avst_rx_valid[1]? avst_rx_inframe_p1: avst_rx_inframe_p1_d1;            
       end       
   end   

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p2)
   begin
       if (~i_rx_reset_n_p2) begin
          avst_rx_inframe_p2_d1 <= {NUM_SEG{1'b0}};
       end            
       else 
       begin 
          avst_rx_inframe_p2_d1 <= i_avst_rx_valid[2]? avst_rx_inframe_p2: avst_rx_inframe_p2_d1;            
       end       
   end   

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p3)
   begin
       if (~i_rx_reset_n_p3) begin
          avst_rx_inframe_p3_d1 <= {NUM_SEG{1'b0}};
       end            
       else 
       begin 
          avst_rx_inframe_p3_d1 <= i_avst_rx_valid[3]? avst_rx_inframe_p3: avst_rx_inframe_p3_d1;            
       end       
   end      
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
   begin
      if (~i_rx_reset_n_p0) begin
         o_axist_rx_tuser_valid[0]    <= '0; 
         o_axist_rx_tuser_valid_p2[0] <= '0;  
      end
      else begin 
         o_axist_rx_tuser_valid[0]    <= (avst_rx_valid_d1_p0 && |avst_rx_sop_d1_p0[7:0])? 1'b1 : 1'b0;         
         o_axist_rx_tuser_valid_p2[0] <= (avst_rx_valid_d1_p0 && |avst_rx_sop_d1_p0[15:8])? 1'b1 : 1'b0;
      end
   end   

   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p1) 
   begin
      if (~i_rx_reset_n_p1) begin
         o_axist_rx_tuser_valid[1]    <= '0; 
         o_axist_rx_tuser_valid_p2[1] <= '0;  
      end
      else begin 
         o_axist_rx_tuser_valid[1]    <= (avst_rx_valid_d1_p1 && |avst_rx_sop_d1_p1[7:0])? 1'b1 : 1'b0;       
         o_axist_rx_tuser_valid_p2[1] <= (avst_rx_valid_d1_p1 && |avst_rx_sop_d1_p1[15:8])? 1'b1 : 1'b0;
      end
   end   
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p2) 
   begin
      if (~i_rx_reset_n_p2) begin
         o_axist_rx_tuser_valid[2]    <= '0; 
         o_axist_rx_tuser_valid_p2[2] <= '0;  
      end
      else begin 
         o_axist_rx_tuser_valid[2]    <= (avst_rx_valid_d1_p2 && |avst_rx_sop_d1_p2[7:0])? 1'b1 : 1'b0;  
         o_axist_rx_tuser_valid_p2[2] <= (avst_rx_valid_d1_p2 && |avst_rx_sop_d1_p2[15:8])? 1'b1 : 1'b0;  
      end
   end     
   
   always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p3) 
   begin
      if (~i_rx_reset_n_p3) begin
         o_axist_rx_tuser_valid[3]    <= '0; 
         o_axist_rx_tuser_valid_p2[3] <= '0;  
      end
      else begin 
         o_axist_rx_tuser_valid[3]    <= (avst_rx_valid_d1_p3 && |avst_rx_sop_d1_p3[7:0])? 1'b1 : 1'b0;
         o_axist_rx_tuser_valid_p2[3] <= (avst_rx_valid_d1_p3 && |avst_rx_sop_d1_p3[15:8])? 1'b1 : 1'b0;          
      end
   end        
  
   assign  o_axist_rx_tkeep = {NO_OF_BYTES{1'b0}};  
   assign  o_axist_rx_tdata = (i_active_ports == 3'd1)? avst_rx_data_d2_p0 : (i_active_ports == 3'd2)? {avst_rx_data_d2_p2[AVST_DW_BY_TWO-1:0],avst_rx_data_d2_p0[AVST_DW_BY_TWO-1:0]} :
                              {avst_rx_data_d2_p3[AVST_DW_BY_FOUR-1:0],avst_rx_data_d2_p2[AVST_DW_BY_FOUR-1:0],avst_rx_data_d2_p1[AVST_DW_BY_FOUR-1:0],avst_rx_data_d2_p0[AVST_DW_BY_FOUR-1:0]};

   assign  avst_rx_ms_valid_d1_p0 = avst_rx_valid_d1_p0 && ((|avst_rx_inframe_p0_d1) || (|avst_rx_eop_d1_p0));     
   assign  avst_rx_ms_valid_d1_p1 = avst_rx_valid_d1_p1 && ((|avst_rx_inframe_p1_d1) || (|avst_rx_eop_d1_p1));     
   assign  avst_rx_ms_valid_d1_p2 = avst_rx_valid_d1_p2 && ((|avst_rx_inframe_p2_d1) || (|avst_rx_eop_d1_p2));     
   assign  avst_rx_ms_valid_d1_p3 = avst_rx_valid_d1_p3 && ((|avst_rx_inframe_p3_d1) || (|avst_rx_eop_d1_p3));   

end

else begin:SOP_ALIGNED
genvar i,j,k,l,m,n;
    
if (DR_ENABLE == 0 || PORT_PROFILE == "25GbE" || PORT_PROFILE == "10GbE") begin:SOP_25G

for (i=0; i<AVST_DW/8; i=i+1) begin:SOP_25G_1P
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)begin //10gbe for non-DR. DR_ENABLE == 0 PPT is handled here
         if (~i_rx_reset_n_p0)
            avst_rx_swiped_data_d2_0[((i+1)*8)-1:(i*8)] <= 8'd0;   
         else
            avst_rx_swiped_data_d2_0[((i+1)*8)-1:(i*8)] <= avst_rx_data_d1_p0[(AVST_DW-(i*8)-1):(AVST_DW-((i+1)*8))];
      end
end

assign o_axist_rx_tdata = avst_rx_swiped_data_d2_0;
    
end 
    
else if (PORT_PROFILE == "50GAUI-1" || PORT_PROFILE == "50GAUI-2" || PORT_PROFILE == "40GCAUI-4") begin:SOP_50G

for (i=0; i<AVST_DW/8; i=i+1) begin:SOP_50G_1P
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)begin  //50-2,40-4 for non-dr
         if (~i_rx_reset_n_p0)
            avst_rx_swiped_data_d2_0[((i+1)*8)-1:(i*8)] <= 8'd0;   
         else     
            avst_rx_swiped_data_d2_0[((i+1)*8)-1:(i*8)] <=  avst_rx_data_d1_p0[(AVST_DW-(i*8)-1):((AVST_DW)-((i+1)*8))]; //p0 clk used. no reset condition added w..r.t port_data_width
      end
end   

for (j=0; j<AVST_DW/16; j=j+1) begin:SOP_50G_2P
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) begin  
         if (~i_rx_reset_n_p0)
         begin
            avst_rx_swiped_data_64_p0[((j+1)*8)-1:(j*8)] <= 8'd0; 
         end            
         else  
         begin       
            avst_rx_swiped_data_64_p0[((j+1)*8)-1:(j*8)] <=  avst_rx_data_d1_p0[((AVST_DW_BY_TWO)-(j*8)-1):((AVST_DW_BY_TWO)-(j+1)*8)]; //p0 clk used. no reset condition added w..r.t port_data_width
         end
      end         
end

assign o_axist_rx_tdata = (i_port_data_width == 3'd0)? {{(AXI_DW-AVST_DW_BY_EIGHT){1'b0}},avst_rx_swiped_data_64_p0}:avst_rx_swiped_data_d2_0; //else condition handles preamble pass through;

end 
    
else begin:SOP_100G
//100g-2,100g-1,100g-4
//reverse 512 bit blocks
for (i=0; i<AVST_DW/8; i=i+1) begin:SOP_100G_1P  //* split data port wise 
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)begin  
         if (~i_rx_reset_n_p0)
            avst_rx_swiped_data_d2_0[((i+1)*8)-1:(i*8)] <= 8'd0;   
         else         
            avst_rx_swiped_data_d2_0[((i+1)*8)-1:(i*8)] <= (i_port_data_width == 3'd2)? avst_rx_data_d1_p0[(AVST_DW-(i*8)-1):(AVST_DW-((i+1)*8))] : '0;
      end
end

//reverse 128 bit blocks
for (j=0; j<AVST_DW/32; j=j+1) begin:SOP_100G_2P

      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)begin 
         if (~i_rx_reset_n_p0) begin
            avst_rx_swiped_data_128_p0[((j+1)*8)-1:j*8]   <= 8'd0;  
         end    
         else begin       
            avst_rx_swiped_data_128_p0[((j+1)*8)-1:j*8]   <= (i_port_data_width == 3'd1)? avst_rx_data_d1_p0[((AVST_DW_BY_FOUR)-(j*8)-1):((AVST_DW_BY_FOUR)-(j+1)*8)] : '0; //127:120 ..
         end      
      end   
      
      if (PORT_PROFILE == "100GAUI-2") begin: SOPA_100GAUI_2_DATA_SWAP 
         always @(posedge i_rx_clk_p1 or negedge i_rx_reset_n_p1)begin 
            if (~i_rx_reset_n_p1) begin
               avst_rx_swiped_data_128_p1[((j+1)*8)-1:j*8] <= 8'd0;
            end    
            else begin       
               avst_rx_swiped_data_128_p1[((j+1)*8)-1:j*8] <= (i_port_data_width == 3'd1)? avst_rx_data_d1_p1[((AVST_DW_BY_FOUR)-(j*8)-1):((AVST_DW_BY_FOUR)-(j+1)*8)] : '0; //127:120 ..
            end      
         end     
      end     

      always @(posedge i_rx_clk_p2 or negedge i_rx_reset_n_p2)begin 
         if (~i_rx_reset_n_p2) begin
            avst_rx_swiped_data_128_p2[((j+1)*8)-1:j*8] <= 8'd0;
         end    
         else begin       
            avst_rx_swiped_data_128_p2[((j+1)*8)-1:j*8] <= (i_port_data_width == 3'd1)? avst_rx_data_d1_p2[((AVST_DW_BY_FOUR)-(j*8)-1):((AVST_DW_BY_FOUR)-(j+1)*8)] : '0; //127:120 ..
         end      
      end   
      
end

//reverse 64 bit blocks
for (k=0; k<8; k=k+1) begin:SOP_100G_4P
      
      always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0) 
      begin  
         if (~i_rx_reset_n_p0) begin
            avst_rx_swiped_data_64_p0[((k+1)*8)-1:k*8] <= 8'd0;    
         end
         else begin       
            avst_rx_swiped_data_64_p0[((k+1)*8)-1:k*8] <= (i_port_data_width == 3'd0)? avst_rx_data_d1_p0[(AVST_DW_BY_EIGHT-(k*8)-1):((AVST_DW_BY_EIGHT)-(k+1)*8)] : '0   ;    //7:0, 63: 56
         end      
      end   
      
      always @(posedge i_rx_clk_p1 or negedge i_rx_reset_n_p1) 
      begin  
         if (~i_rx_reset_n_p1) begin
            avst_rx_swiped_data_64_p1[((k+1)*8)-1:k*8] <= 8'd0;
         end
         else begin       
            avst_rx_swiped_data_64_p1[((k+1)*8)-1:k*8] <= (i_port_data_width == 3'd0)? avst_rx_data_d1_p1[(AVST_DW_BY_EIGHT-(k*8)-1):((AVST_DW_BY_EIGHT)-(k+1)*8)] : '0 ;    //7:0, 127:120
         end      
      end        

      always @(posedge i_rx_clk_p2 or negedge i_rx_reset_n_p2) 
      begin  
         if (~i_rx_reset_n_p2) begin
            avst_rx_swiped_data_64_p2[((k+1)*8)-1:k*8]   <= 8'd0;
         end
         else begin       
            avst_rx_swiped_data_64_p2[((k+1)*8)-1:k*8] <= (i_port_data_width == 3'd0)? avst_rx_data_d1_p2[(AVST_DW_BY_EIGHT-(k*8)-1):((AVST_DW_BY_EIGHT)-(k+1)*8)] : '0;    //7:0, 191:184
         end      
      end       

      always @(posedge i_rx_clk_p3 or negedge i_rx_reset_n_p3) 
      begin  
         if (~i_rx_reset_n_p3) begin
            avst_rx_swiped_data_64_p3[((k+1)*8)-1:k*8] <= 8'd0;
         end
         else begin       
            avst_rx_swiped_data_64_p3[((k+1)*8)-1:k*8] <= (i_port_data_width == 3'd0)? avst_rx_data_d1_p3[(AVST_DW_BY_EIGHT-(k*8)-1):((AVST_DW_BY_EIGHT)-(k+1)*8)] : '0;    //7:0, 255:248
         end      
      end     
            
end


if (PORT_PROFILE == "100GAUI-1") begin: SOPA_100GAUI_1
     assign o_axist_rx_tdata  = (i_port_data_width == 3'd2)? avst_rx_swiped_data_d2_0: 
                                (i_port_data_width == 3'd1)? {256'd0,128'd0,avst_rx_swiped_data_128_p0}:
                                                             {256'd0,64'd0,64'd0,64'd0,avst_rx_swiped_data_64_p0};                         
end
else if (PORT_PROFILE == "100GAUI-2") begin: SOPA_100GAUI_2
     assign o_axist_rx_tdata  = (i_port_data_width == 3'd2)? avst_rx_swiped_data_d2_0: 
                                (i_port_data_width == 3'd1)? {256'd0,avst_rx_swiped_data_128_p1,avst_rx_swiped_data_128_p0}:
                                                             {256'd0,64'd0,64'd0,avst_rx_swiped_data_64_p1,avst_rx_swiped_data_64_p0};                         
end
else begin: SOPA_100GCAUI_4
     assign o_axist_rx_tdata  = (i_port_data_width == 3'd2)? avst_rx_swiped_data_d2_0: 
                                (i_port_data_width == 3'd1)? {256'd0,avst_rx_swiped_data_128_p2,avst_rx_swiped_data_128_p0}:
                                                             {256'd0,avst_rx_swiped_data_64_p3,avst_rx_swiped_data_64_p2,avst_rx_swiped_data_64_p1,avst_rx_swiped_data_64_p0};                         
end
end

if (NUM_MAX_PORTS == 1) begin:SOP_1P
    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)  //25g-1,50g-1,100g-1
    begin
       if (~i_rx_reset_n_p0)
           tkeep_d4 <= {(NO_OF_BYTES){1'b0}};
       else if (i_avst_rx_valid[0]) begin
           if (i_avst_rx_endofpacket[0])
               tkeep_d4[NO_OF_BYTES-1:0] <= {(NO_OF_BYTES){1'b1}} >> i_avst_rx_eop_empty[EMPTY_BITS-1:0];
           else 
               tkeep_d4[NO_OF_BYTES-1:0] <= {(NO_OF_BYTES){1'b1}};
       end
       else 
           tkeep_d4 <= {(NO_OF_BYTES){1'b0}};
    end
    
    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)  //25g-1,50g-1,100g-1
    begin
       if(~i_rx_reset_n_p0)
          tkeep_d4_d1 <= {(NO_OF_BYTES){1'b0}};
       else begin   
          tkeep_d4_d1 <= tkeep_d4;
       end    
    end    
    
    if (PORT_PROFILE == "50GAUI-1" || PORT_PROFILE == "100GAUI-1") begin:SOP_50G_100G_TKEEP 
    
        always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)  //25g-1 in 100GAUI-1 and 50GAUI-1
        begin
           if (~i_rx_reset_n_p0)
               tkeep_d6 <= 8'd0;
           else if (i_avst_rx_valid[0]) begin
               if (i_avst_rx_endofpacket[0])
                   tkeep_d6 <= {8{1'b1}} >> i_avst_rx_eop_empty[2:0];
               else 
                   tkeep_d6 <= {8{1'b1}};
           end
           else 
               tkeep_d6 <= 8'd0;
        end 
        
        always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)  //50g-1 in 100GAUI-1
        begin
           if (~i_rx_reset_n_p0)
               tkeep_d7 <= 16'd0;
           else if (i_avst_rx_valid[0]) begin
               if (i_avst_rx_endofpacket[0])
                   tkeep_d7 <= {16{1'b1}} >> i_avst_rx_eop_empty[3:0];
               else 
                   tkeep_d7 <= {16{1'b1}};
           end
           else 
               tkeep_d7 <= 16'd0;
        end 
    
        always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)  //25g-1,50g-1,100g-1
        begin
           if(~i_rx_reset_n_p0)
              tkeep_d6_d1 <= 8'd0;
           else begin   
              tkeep_d6_d1 <= tkeep_d6;
           end    
        end   
    
        always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)  //25g-1,50g-1,100g-1
        begin
           if(~i_rx_reset_n_p0)
              tkeep_d7_d1 <= 16'd0;
           else begin   
              tkeep_d7_d1 <= tkeep_d7;
           end    
        end       
    end

    if ((PORT_PROFILE == "25GbE") || (DR_ENABLE ==0)) begin: SOPA_NON_DR_25G_TKEEP
          assign o_axist_rx_tkeep = tkeep_d4_d1;
    end   
    else if (PORT_PROFILE == "50GAUI-1")begin: SOPA_50G_1P_TKEEP
          assign o_axist_rx_tkeep = (i_port_data_width == 3'd0)? {8'd0,tkeep_d6_d1} : tkeep_d4_d1; //16 bits
    end   
    else begin:SOPA_100G_1P_TKEEP
          assign o_axist_rx_tkeep = (i_port_data_width == 3'd0)? {56'd0,tkeep_d6_d1} : (i_port_data_width == 3'd1)? {48'd0,tkeep_d7_d1} : tkeep_d4_d1; //64 bits
    end

end
else if (NUM_MAX_PORTS == 4) begin:SOP_4P
    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)  //1x100g-4
    begin
       if (~i_rx_reset_n_p0)
           tkeep_d4 <= {(NO_OF_BYTES){1'b0}};
       else if (i_avst_rx_valid[0]) begin
           if (i_avst_rx_endofpacket[0])
               tkeep_d4[NO_OF_BYTES-1:0] <= (i_port_data_width == 3'd2)? {(NO_OF_BYTES){1'b1}} >> i_avst_rx_eop_empty[EMPTY_BITS-1:0] : '0;
           else 
               tkeep_d4[NO_OF_BYTES-1:0] <= (i_port_data_width == 3'd2)? {(NO_OF_BYTES){1'b1}} : '0;
       end
       else 
           tkeep_d4 <= {(NO_OF_BYTES){1'b0}};
    end
    
    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)  
    begin
       if(~i_rx_reset_n_p0)
          tkeep_d4_d1 <= {(NO_OF_BYTES){1'b0}};
       else begin   
          tkeep_d4_d1 <= tkeep_d4;
       end    
    end 
    
    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)  //4x25g,2x25g
    begin
       if (~i_rx_reset_n_p0)
           tkeep_d2[7:0] <= 8'd0;
       else if (i_avst_rx_valid[0]) begin
           if (i_avst_rx_endofpacket[0])
               tkeep_d2[7:0] <= (i_port_data_width == 3'd0)? {8{1'b1}} >> i_avst_rx_eop_empty[2:0] : '0;
           else 
               tkeep_d2[7:0] <= (i_port_data_width == 3'd0)? {8{1'b1}} : '0;
       end
       else 
            tkeep_d2[7:0] <= 8'd0;
    end
    
    always @(posedge i_rx_clk_p1 or negedge i_rx_reset_n_p1)  //4x25g,2x25g
    begin
       if (~i_rx_reset_n_p1)
           tkeep_d2[15:8] <= 8'd0;
       else if (i_avst_rx_valid[1]) begin
           if (i_avst_rx_endofpacket[1])
               tkeep_d2[15:8] <= (i_port_data_width == 3'd0)? {8{1'b1}} >> i_avst_rx_eop_empty[5:3] : '0;
           else 
               tkeep_d2[15:8] <= (i_port_data_width == 3'd0)? {8{1'b1}} : '0;
       end
       else 
            tkeep_d2[15:8] <= 8'd0;
    end
    
    always @(posedge i_rx_clk_p2 or negedge i_rx_reset_n_p2)  //4x25g,2x25g
    begin
       if (~i_rx_reset_n_p2)
           tkeep_d2[23:16] <= 8'd0;
       else if (i_avst_rx_valid[2]) begin
           if (i_avst_rx_endofpacket[2])
               tkeep_d2[23:16] <= (i_port_data_width == 3'd0)? {8{1'b1}} >> i_avst_rx_eop_empty[8:6] : '0;
           else 
               tkeep_d2[23:16] <= (i_port_data_width == 3'd0)? {8{1'b1}} : '0;
       end
       else 
            tkeep_d2[23:16] <= 8'd0;
    end 
    
    always @(posedge i_rx_clk_p3 or negedge i_rx_reset_n_p3)  //4x25g,2x25g
    begin
       if (~i_rx_reset_n_p3)
           tkeep_d2[31:24] <= 8'd0;
       else if (i_avst_rx_valid[3]) begin
           if (i_avst_rx_endofpacket[3])
               tkeep_d2[31:24] <= (i_port_data_width == 3'd0)? {8{1'b1}} >> i_avst_rx_eop_empty[11:9] : '0;
           else 
               tkeep_d2[31:24] <= (i_port_data_width == 3'd0)? {8{1'b1}} : '0;
       end
       else 
            tkeep_d2[31:24] <= 8'd0;
    end     
    
    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)  //25g-1,50g-1,100g-1
    begin
       if(~i_rx_reset_n_p0)
          tkeep_d2_d1[7:0] <= 8'd0;
       else begin   
          tkeep_d2_d1[7:0] <= tkeep_d2[7:0];
       end    
    end     
    
    always @(posedge i_rx_clk_p1 or negedge i_rx_reset_n_p1)  //25g-1,50g-1,100g-1
    begin
       if(~i_rx_reset_n_p1)
          tkeep_d2_d1[15:8] <= 8'd0;
       else begin   
          tkeep_d2_d1[15:8] <= tkeep_d2[15:8];
       end    
    end         
    
    always @(posedge i_rx_clk_p2 or negedge i_rx_reset_n_p2)  //25g-1,50g-1,100g-1
    begin
       if(~i_rx_reset_n_p2)
          tkeep_d2_d1[23:16] <= 8'd0;
       else begin   
          tkeep_d2_d1[23:16] <= tkeep_d2[23:16];
       end    
    end         
    
    always @(posedge i_rx_clk_p3 or negedge i_rx_reset_n_p3)  //25g-1,50g-1,100g-1
    begin
       if(~i_rx_reset_n_p3)
          tkeep_d2_d1[31:24] <= 8'd0;
       else begin   
          tkeep_d2_d1[31:24] <= tkeep_d2[31:24];
       end    
    end 

    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)  //2x50g, 1x50g
    begin
       if (~i_rx_reset_n_p0)
           tkeep_d3[15:0] <= 16'd0;
       else if (i_avst_rx_valid[0]) begin //bit 0 and bit 2 -> 2x50 config for UMR3
           if (i_avst_rx_endofpacket[0])
               tkeep_d3[15:0] <= (i_port_data_width == 3'd1)? {16{1'b1}} >> i_avst_rx_eop_empty[3:0] : '0;
           else 
               tkeep_d3[15:0] <= (i_port_data_width == 3'd1)? {16{1'b1}} : '0;
       end
       else 
            tkeep_d3[15:0] <= 16'd0;
    end
    
    always @(posedge i_rx_clk_p2 or negedge i_rx_reset_n_p2)  //2x50g, 1x50g
    begin
       if (~i_rx_reset_n_p2)
           tkeep_d3[31:16] <= 16'd0;
       else if (i_avst_rx_valid[2]) begin //bit 0 and bit 2 -> 2x50 config for UMR3
           if (i_avst_rx_endofpacket[2])
               tkeep_d3[31:16] <= (i_port_data_width == 3'd1)? {16{1'b1}} >> i_avst_rx_eop_empty[7:4] : '0;
           else 
               tkeep_d3[31:16] <= (i_port_data_width == 3'd1)? {16{1'b1}} : '0;
       end
       else 
            tkeep_d3[31:16] <= 16'd0;
    end 
    
    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)  //25g-1,50g-1,100g-1
    begin
       if(~i_rx_reset_n_p0)
          tkeep_d3_d1[15:0] <= 16'd0;
       else begin   
          tkeep_d3_d1[15:0] <= tkeep_d3[15:0];
       end    
    end     
   
    always @(posedge i_rx_clk_p2 or negedge i_rx_reset_n_p2)  //25g-1,50g-1,100g-1
    begin
       if(~i_rx_reset_n_p2)
          tkeep_d3_d1[31:16] <= 16'd0;
       else begin   
          tkeep_d3_d1[31:16] <= tkeep_d3[31:16];
       end    
    end     

    assign o_axist_rx_tkeep = (i_port_data_width == 3'd2)? tkeep_d4_d1: (i_port_data_width == 3'd1)? {32'd0,tkeep_d3_d1}: {32'd0,tkeep_d2_d1};

end

else begin:SOP_2P
    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)  //1x100g-2
    begin
       if (~i_rx_reset_n_p0)
           tkeep_d4 <= {(NO_OF_BYTES){1'b0}};
       else if (i_avst_rx_valid[0]) begin
           if (i_avst_rx_endofpacket[0])
               tkeep_d4[NO_OF_BYTES-1:0] <= (i_port_data_width == 3'd2)? {(NO_OF_BYTES){1'b1}} >> i_avst_rx_eop_empty[EMPTY_BITS-1:0] : '0;
           else 
               tkeep_d4[NO_OF_BYTES-1:0] <= (i_port_data_width == 3'd2)?{(NO_OF_BYTES){1'b1}} : '0;
       end
       else 
           tkeep_d4 <= {(NO_OF_BYTES){1'b0}};
    end
    
    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)  //25g-1,50g-1,100g-1
    begin
       if(~i_rx_reset_n_p0)
          tkeep_d4_d1 <= {(NO_OF_BYTES){1'b0}};
       else begin   
          tkeep_d4_d1 <= tkeep_d4;
       end    
    end     
    
    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)  //1x25g,2x25g 
    begin
       if (~i_rx_reset_n_p0)
           tkeep_d5[7:0] <= 8'd0;
       else if (i_avst_rx_valid[0]) begin
           if (i_avst_rx_endofpacket[0])
               tkeep_d5[7:0] <= (i_port_data_width == 3'd0)? {8{1'b1}} >> i_avst_rx_eop_empty[2:0] : '0;
           else 
               tkeep_d5[7:0] <= (i_port_data_width == 3'd0)? {8{1'b1}} : '0;
       end
       else 
            tkeep_d5[7:0] <= 8'd0;
    end

    always @(posedge i_rx_clk_p1 or negedge i_rx_reset_n_p1)  //1x25g,2x25g 
    begin
       if (~i_rx_reset_n_p1)
           tkeep_d5[15:8] <= 8'd0;
       else if (i_avst_rx_valid[1]) begin
           if (i_avst_rx_endofpacket[1])
               tkeep_d5[15:8] <= (i_port_data_width == 3'd0)? {8{1'b1}} >> i_avst_rx_eop_empty[5:3] : '0;
           else 
               tkeep_d5[15:8] <= (i_port_data_width == 3'd0)? {8{1'b1}} : '0;
       end
       else 
            tkeep_d5[15:8] <= 8'd0;
    end 
    
    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)  //25g-1,50g-1,100g-1
    begin
       if(~i_rx_reset_n_p0)
          tkeep_d5_d1[7:0] <= 8'd0;
       else begin   
          tkeep_d5_d1[7:0] <= tkeep_d5[7:0];
       end    
    end     

    always @(posedge i_rx_clk_p1 or negedge i_rx_reset_n_p1)  //25g-1,50g-1,100g-1
    begin
       if(~i_rx_reset_n_p1)
          tkeep_d5_d1[15:8] <= 8'd0;
       else begin   
          tkeep_d5_d1[15:8] <= tkeep_d5[15:8];
       end    
    end         

    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)  //2x50g, 1x50g
    begin
       if (~i_rx_reset_n_p0)
           tkeep_d3[15:0] <= 16'd0;
       else if (i_avst_rx_valid[0]) begin
           if (i_avst_rx_endofpacket[0])
               tkeep_d3[15:0] <= (i_port_data_width == 3'd1)? {16{1'b1}} >> i_avst_rx_eop_empty[3:0] : '0;
           else 
               tkeep_d3[15:0] <= (i_port_data_width == 3'd1)? {16{1'b1}} : '0;
       end
       else 
            tkeep_d3[15:0] <= 16'd0;
    end
    
    always @(posedge i_rx_clk_p1 or negedge i_rx_reset_n_p1)  //2x50g, 1x50g
    begin
       if (~i_rx_reset_n_p1)
           tkeep_d3[31:16] <= 16'd0;
       else if (i_avst_rx_valid[1]) begin
           if (i_avst_rx_endofpacket[1])
               tkeep_d3[31:16] <= (i_port_data_width == 3'd1)? {16{1'b1}} >> i_avst_rx_eop_empty[7:4] : '0;
           else 
               tkeep_d3[31:16] <= (i_port_data_width == 3'd1)? {16{1'b1}} : '0;
       end
       else 
            tkeep_d3[31:16] <= 16'd0;
    end 
    
    always @(posedge i_rx_clk_p0 or negedge i_rx_reset_n_p0)  //25g-1,50g-1,100g-1
    begin
       if(~i_rx_reset_n_p0)
          tkeep_d3_d1[15:0] <= 16'd0;
       else begin   
          tkeep_d3_d1[15:0] <= tkeep_d3[15:0];
       end    
    end 

    always @(posedge i_rx_clk_p1 or negedge i_rx_reset_n_p1)  //25g-1,50g-1,100g-1
    begin
       if(~i_rx_reset_n_p1)
          tkeep_d3_d1[31:16] <= 16'd0;
       else begin   
          tkeep_d3_d1[31:16] <= tkeep_d3[31:16];
       end    
    end     

    assign o_axist_rx_tkeep = (i_port_data_width == 3'd2)? tkeep_d4_d1: (i_port_data_width == 3'd1)? {32'd0,tkeep_d3_d1}: {32'd0,tkeep_d5_d1};
    
end

    always_comb begin
       o_axist_rx_tkeep_segment     = {8*NUM_SEG{1'b0}};
       o_axist_rx_tuser_valid_p2    = {NUM_MAX_PORTS{1'b0}};
    end
        
    assign o_axist_rx_tlast_segment = {NUM_SEG{1'b0}};

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

generate 
begin :RX_PARITY_GEN
genvar rx_sp;
if (PKT_SEG_PARITY_EN) begin:RX_PARITY_CALC

    if (AVST_MODE == "MAC_SEGMENTED") begin 
    
       always_comb begin
           axist_rx_data = (NUM_MAX_PORTS == 1)? avst_rx_data_d2_p0: 
                           (NUM_MAX_PORTS == 2)? ((i_active_ports == 3'd1)? avst_rx_data_d2_p0 : {avst_rx_data_d2_p1[AVST_DW_BY_TWO-1:0],avst_rx_data_d2_p0[AVST_DW_BY_TWO-1:0]}):
                                                 ((i_active_ports == 3'd1)? avst_rx_data_d2_p0 : (i_active_ports == 3'd2)? {avst_rx_data_d2_p2[AVST_DW_BY_TWO-1:0],avst_rx_data_d2_p0[AVST_DW_BY_TWO-1:0]} :
                                                  {avst_rx_data_d2_p3[AVST_DW_BY_FOUR-1:0],avst_rx_data_d2_p2[AVST_DW_BY_FOUR-1:0],avst_rx_data_d2_p1[AVST_DW_BY_FOUR-1:0],avst_rx_data_d2_p0[AVST_DW_BY_FOUR-1:0]});
       end     
       
       for (rx_sp=0; rx_sp<NUM_SEG; rx_sp=rx_sp+1)begin :RX_SEG_DATA
          always_comb begin
              rx_parity_detect[rx_sp] = ^(axist_rx_data[64*(rx_sp+1)-1:64*rx_sp]);
          end 


       if (SIM_EMULATE) begin:RX_PARITY_CALC_SIM_MS          
          assign o_axist_rx_pkt_seg_parity[rx_sp] = ~rx_parity_detect[rx_sp] & o_axist_rx_tkeep_segment[rx_sp*8];
       end
       else begin : RX_PARITY_CALC_HW_MS
          assign o_axist_rx_pkt_seg_parity[rx_sp] = ~rx_parity_detect[rx_sp];      
       end
     
    end
    end
    else begin
    
       if (PORT_PROFILE == "25GbE" || (DR_ENABLE ==0)) begin:SOP_25G_DATA_PARITY
           assign axist_rx_data = avst_rx_swiped_data_d2_0;
       end         
       else if (PORT_PROFILE == "50GAUI-1") begin:SOP_50G_DATA_PARITY         
           assign axist_rx_data = (i_port_data_width == 3'd0)?  {{64{1'b0}},avst_rx_swiped_data_64_p0}:avst_rx_swiped_data_d2_0; 
       end
       else if (PORT_PROFILE == "100GAUI-1") begin: SOPA_100GAUI_1_PARITY
           assign axist_rx_data  = (i_port_data_width == 3'd2)? avst_rx_swiped_data_d2_0: 
                                   (i_port_data_width == 3'd1)? {256'd0,128'd0,avst_rx_swiped_data_128_p0}:
                                                                {256'd0,64'd0,64'd0,64'd0,avst_rx_swiped_data_64_p0};                         
       end
       else if (PORT_PROFILE == "100GAUI-2") begin: SOPA_100GAUI_2_PARITY
            assign axist_rx_data  = (i_port_data_width == 3'd2)? avst_rx_swiped_data_d2_0: 
                                    (i_port_data_width == 3'd1)? {256'd0,avst_rx_swiped_data_128_p1,avst_rx_swiped_data_128_p0}:
                                                                 {256'd0,64'd0,64'd0,avst_rx_swiped_data_64_p1,avst_rx_swiped_data_64_p0};                         
       end
       else begin: SOPA_100GCAUI_4_PARITY
            assign axist_rx_data  = (i_port_data_width == 3'd2)? avst_rx_swiped_data_d2_0: 
                                    (i_port_data_width == 3'd1)? {256'd0,avst_rx_swiped_data_128_p2,avst_rx_swiped_data_128_p0}:
                                                                 {256'd0,avst_rx_swiped_data_64_p3,avst_rx_swiped_data_64_p2,avst_rx_swiped_data_64_p1,avst_rx_swiped_data_64_p0};                         
       end       
    
       if (NUM_MAX_PORTS == 2) begin:SOPA_PARITY_2P  
            always_comb begin //100g-2
                if (i_active_ports == 3'd2) begin
                   rx_parity_detect = (i_port_data_width == 3'd1)? {^axist_rx_data[AVST_DW_BY_TWO-1:AVST_DW_BY_FOUR], ^axist_rx_data[AVST_DW_BY_FOUR-1:0]}:    //255:128, 127:0
                                                                   {^axist_rx_data[AVST_DW_BY_FOUR-1:AVST_DW_BY_EIGHT], ^axist_rx_data[AVST_DW_BY_EIGHT-1:0]}; //127:64, 63:0
                end
                else begin
                   rx_parity_detect = {1'b0,^(axist_rx_data)};
                end
            end
       end
       else if (NUM_MAX_PORTS == 4) begin:SOPA_PARITY_4P  
            always_comb begin //100g-4
                if (i_active_ports == 3'd4) begin
                   rx_parity_detect = {^axist_rx_data[AVST_DW_BY_TWO-1:(3*AVST_DW/8)], ^axist_rx_data[(3*AVST_DW/8)-1:AVST_DW_BY_FOUR], //191:128, 255:192
                                       ^axist_rx_data[AVST_DW_BY_FOUR-1:AVST_DW_BY_EIGHT], ^axist_rx_data[AVST_DW_BY_EIGHT-1:0]}; //63:0, 127:64
                end
                else if (i_active_ports == 3'd2) begin
                   rx_parity_detect = {1'b0, (^axist_rx_data[AVST_DW_BY_TWO-1:AVST_DW_BY_FOUR]), 1'b0, (^axist_rx_data[AVST_DW_BY_FOUR-1:0])}; //127:0,255:128
                end
                else begin //i_active_ports = 1
                   rx_parity_detect = {3'd0, ^(axist_rx_data)};
                end
            end
       end
       else begin:SOPA_PARITY_1P   //(NUM_MAX_PORTS == 1) :SOPA_PARITY_1P  
            always_comb begin //25g-1, 50g-1, 100g-1
                rx_parity_detect = ^(axist_rx_data);
            end
       end 


   if (SIM_EMULATE) begin:RX_PARITY_CALC_SIM
       assign o_axist_rx_pkt_seg_parity = ~rx_parity_detect & o_axist_rx_tvalid;  
   end
   else begin : RX_PARITY_CALC_HW
       assign o_axist_rx_pkt_seg_parity = ~rx_parity_detect;     
   end
   
end
        
end
else begin : RX_NO_PARITY
      assign o_axist_rx_pkt_seg_parity = '0;
end

end

endgenerate     
        
endmodule
