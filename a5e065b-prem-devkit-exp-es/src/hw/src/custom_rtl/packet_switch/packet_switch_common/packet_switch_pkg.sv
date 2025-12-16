//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


package packet_switch_pkg;

   parameter MAX_PKT_SIZE = 1024*9;

   parameter MAX_DMA_CH = 8;

   parameter MAX_HSSI_PORTS = 8;

   parameter MAX_USER_PORTS = MAX_HSSI_PORTS;

   //------------------------------------------------------------------------------------------
   // CSR addresses

   parameter PORT_OFFSET            = 'h4100; // each port's offset after port 0

   parameter GEN_START_ADDR         = 'h0;
   parameter GEN_END_ADDR           = 'h10;
   parameter GEN_RSVD_START_ADDR    = 'h14; // general + rsvd
   parameter GEN_RSVD_END_ADDR      = 'h3C; // general + rsvd

   // addresses for first instance
   parameter TX_IGR_ARB_START_ADDR  = 'h40;
   parameter TX_IGR_ARB_END_ADDR    = 'h48;

   parameter RX_EGR_DMUX_START_ADDR = 'h4C;
   parameter RX_EGR_DMUX_END_ADDR   = 'h70;

   parameter RX_IGR_WADJ_START_ADDR = 'h74;
   parameter RX_IGR_WADJ_END_ADDR   = 'h7C;

   parameter RX_EGR_WADJ_START_ADDR = 'h80;
   parameter RX_EGR_WADJ_END_ADDR   = 'h88;

   parameter TCAM_START_ADDR        = 'h100;
   parameter TCAM_END_ADDR          = 'h40FC;

   parameter RSVD_0_START_ADDR      = 'h8C;
   parameter RSVD_0_END_ADDR        = 'hFC;

   parameter TX_DBG_CNT_START_ADDR  = 'h8C;
   parameter TX_DBG_CNT_END_ADDR    = 'hA8;

   parameter RX_DBG_CNT_START_ADDR  = 'hAC;
   parameter RX_DBG_CNT_END_ADDR    = 'hE8;

   parameter DBG_CNT_RSVD_START_ADDR= 'hEC;

   parameter RSVD_1_START_ADDR      = 'h4100;
   parameter RSVD_1_END_ADDR        = 'h413C;

   //------------------------------------------------------------------------------------------
   // Port/Channel definition
   parameter PORTS_WIDTH = 4;

   typedef enum logic [PORTS_WIDTH-1:0]
     {
       MSGDMA_0  = 'd0
      ,MSGDMA_1  = 'd1
      ,MSGDMA_2  = 'd2
      ,MSGDMA_3  = 'd3
      ,MSGDMA_4  = 'd4
      ,MSGDMA_5  = 'd5
      ,MSGDMA_6  = 'd6
      ,MSGDMA_7  = 'd7
      ,USER_0    = 'd8
      } PORT_E;

   //------------------------------------------------------------------------------------------
   // tuser segment info: Indicates the segment info
   typedef struct packed {
      logic [15:0]           multicast_port; // multicast_port
      logic                  multicast_en;   // multicast_en
      logic 	             sop;           // start of packet
      logic                  eop;           // end of packet
      logic 	             sos;           // start of segment
      logic 	             eos;           // end of segments
      logic [7:0]            bytesvld;      // number of bytes vld
      logic 	             hdr_segment;   // hdr segment
      logic 	             payld_segment; // payld segment
      PORT_E                 igr_port;      // ingress port
      PORT_E                 egr_port;      // egress port
      // logic [1:0]            egr_dma_priolvl; // egress DMA priority level
   } SEGMENT_INFO_S;
   parameter SEGMENT_INFO_WIDTH = $bits(SEGMENT_INFO_S);

   //------------------------------------------------------------------------------------------
   // tuple map: to be used for key
   typedef struct packed {
      logic [31:0]          rsvd; 

      //---------------------------------------------------------------------------------------
      // flagField, messageType key extraction:
      // ptp.flagField
      // ptp.messageType
      logic [15:0]         flagField;

      logic [3:0]          messageType;

      //---------------------------------------------------------------------------------------
      // ip_protocol key extraction:
      // ip_protocol = ipv4.protocol; or ipv6.next_header;
      logic [7:0]          ip_protocol; 

      //---------------------------------------------------------------------------------------
      // ethtype, tci_vlana, tci_vlanb key extraction:
      // Non ifc header: 
      //  dot2q: (eth.{da,sa,etype})/(vlana.{tci,etype})/(vlanb.{tci,etype})
      //   ethtype = eth.etype; tci_vlana = vlana.tci; tci_vlanb = vlanb.tci          
      //
      //  dot1q: (eth.{da,sa,etype})/(vlana.{tci,etype})
      //   ethtype = eth.etype; tci_vlana = vlana.tci; tci_vlanb ='0;
      //
      //  eth: (eth.{da,sa,etype})
      //   ethtype = eth.etype; tci_vlana = '0; tci_vlanb ='0;
      //
	  
      logic [15:0]         ethtype;                         
      logic [15:0]         tci_vlana; 
      logic [15:0]         tci_vlanb; 

      //---------------------------------------------------------------------------------------
      // l4_src_port, l4_dst_port, src_ip, dst_ip, src_mac, dst_mac key extraction:
      // l4_src_port = tcp.src_port; or udp.sport;
      // l4_dst_port = tcp.dst_port; or udp.dport;
	  
      // ipv4/ipv6:
      // src_ip[31:0]  = ipv4.src_ip; src_ip[127:32] = '0;
      // dst_ip[31:0]  = ipv4.dst_ip; dst_ip[127:32] = '0;
      // src_ip[127:0] = ipv6.src_ip;
      // dst_ip[127:0] = ipv6.dst_ip;
	  
      // src_mac = eth.da;
      // dst_mac = eth.sa;
	  
      logic [15:0]         l4_src_port;
      logic [15:0]         l4_dst_port;
      logic [127:0]        src_ip;                                               
      logic [127:0]        dst_ip;    
      logic [47:0]         src_mac;    
      logic [47:0]         dst_mac;    

   } tuple_map_S;
   parameter tuple_map_width = $bits(tuple_map_S);

   //------------------------------------------------------------------------------------------
   // tcam result: to be used for result
   typedef struct packed {
      //---------------------------------------------------------------------------------------
      // Reserved
      logic [9:0] rsvd;

      //---------------------------------------------------------------------------------------
      // Multi-cast port
      logic [15:0] multicast_port;

      //---------------------------------------------------------------------------------------
      // Multi-cast enable
      logic        multicast_en;

      //---------------------------------------------------------------------------------------
      // Drop packet
      logic        drop;

      //---------------------------------------------------------------------------------------
      // Egress port
      PORT_E       egr_port;

      //---------------------------------------------------------------------------------------
      // Egress DMA priority levels. 0 is highest priority, and 3 is lowest priority
      // logic [1:0]  egr_dma_priolvl;

   } TCAM_RESULT_S;
   parameter TCAM_RESULT_WIDTH = $bits(TCAM_RESULT_S);

   
   //------------------------------------------------------------------------------------------

   function automatic [0:63][7:0] fn_mask_bytesvld_64
     (
      input [6:0]       bytesvld
      );

      begin
	 if (bytesvld == 'd64)
	   fn_mask_bytesvld_64 = '1;
	 else 
	 case (bytesvld[6:0])
	   
	   'd64: fn_mask_bytesvld_64 = '1;
       'd1:  fn_mask_bytesvld_64 = { {{1*8}{1'b1}},  {63*8{1'b0}}};
       'd2:  fn_mask_bytesvld_64 = { {{2*8}{1'b1}},  {62*8{1'b0}}};
       'd3:  fn_mask_bytesvld_64 = { {{3*8}{1'b1}},  {61*8{1'b0}}};
       'd4:  fn_mask_bytesvld_64 = { {{4*8}{1'b1}},  {60*8{1'b0}}};
       'd5:  fn_mask_bytesvld_64 = { {{5*8}{1'b1}},  {59*8{1'b0}}};
       'd6:  fn_mask_bytesvld_64 = { {{6*8}{1'b1}},  {58*8{1'b0}}};
       'd7:  fn_mask_bytesvld_64 = { {{7*8}{1'b1}},  {57*8{1'b0}}};
       'd8:  fn_mask_bytesvld_64 = { {{8*8}{1'b1}},  {56*8{1'b0}}};
       'd9:  fn_mask_bytesvld_64 = { {{9*8}{1'b1}},  {55*8{1'b0}}};
       'd10: fn_mask_bytesvld_64 = { {{10*8}{1'b1}},  {54*8{1'b0}}};
       
       'd11: fn_mask_bytesvld_64 = { {{11*8}{1'b1}},  {53*8{1'b0}}};
       'd12: fn_mask_bytesvld_64 = { {{12*8}{1'b1}},  {52*8{1'b0}}};
       'd13: fn_mask_bytesvld_64 = { {{13*8}{1'b1}},  {51*8{1'b0}}};
       'd14: fn_mask_bytesvld_64 = { {{14*8}{1'b1}},  {50*8{1'b0}}};
       'd15: fn_mask_bytesvld_64 = { {{15*8}{1'b1}},  {49*8{1'b0}}};
       'd16: fn_mask_bytesvld_64 = { {{16*8}{1'b1}},  {48*8{1'b0}}};
       'd17: fn_mask_bytesvld_64 = { {{17*8}{1'b1}},  {47*8{1'b0}}};
       'd18: fn_mask_bytesvld_64 = { {{18*8}{1'b1}},  {46*8{1'b0}}};
       'd19: fn_mask_bytesvld_64 = { {{19*8}{1'b1}},  {45*8{1'b0}}};
       'd20: fn_mask_bytesvld_64 = { {{20*8}{1'b1}},  {44*8{1'b0}}};
       
       'd21: fn_mask_bytesvld_64 = { {{21*8}{1'b1}},  {43*8{1'b0}}};
       'd22: fn_mask_bytesvld_64 = { {{22*8}{1'b1}},  {42*8{1'b0}}};
       'd23: fn_mask_bytesvld_64 = { {{23*8}{1'b1}},  {41*8{1'b0}}};
       'd24: fn_mask_bytesvld_64 = { {{24*8}{1'b1}},  {40*8{1'b0}}};
       'd25: fn_mask_bytesvld_64 = { {{25*8}{1'b1}},  {39*8{1'b0}}};
       'd26: fn_mask_bytesvld_64 = { {{26*8}{1'b1}},  {38*8{1'b0}}};
       'd27: fn_mask_bytesvld_64 = { {{27*8}{1'b1}},  {37*8{1'b0}}};
       'd28: fn_mask_bytesvld_64 = { {{28*8}{1'b1}},  {36*8{1'b0}}};
       'd29: fn_mask_bytesvld_64 = { {{29*8}{1'b1}},  {35*8{1'b0}}};
       'd30: fn_mask_bytesvld_64 = { {{30*8}{1'b1}},  {34*8{1'b0}}};
       
       'd31: fn_mask_bytesvld_64 = { {{31*8}{1'b1}},  {33*8{1'b0}}};
       'd32: fn_mask_bytesvld_64 = { {{32*8}{1'b1}},  {32*8{1'b0}}};
       'd33: fn_mask_bytesvld_64 = { {{33*8}{1'b1}},  {31*8{1'b0}}};
       'd34: fn_mask_bytesvld_64 = { {{34*8}{1'b1}},  {30*8{1'b0}}};
       'd35: fn_mask_bytesvld_64 = { {{35*8}{1'b1}},  {29*8{1'b0}}};
       'd36: fn_mask_bytesvld_64 = { {{36*8}{1'b1}},  {28*8{1'b0}}};
       'd37: fn_mask_bytesvld_64 = { {{37*8}{1'b1}},  {27*8{1'b0}}};
       'd38: fn_mask_bytesvld_64 = { {{38*8}{1'b1}},  {26*8{1'b0}}};
       'd39: fn_mask_bytesvld_64 = { {{39*8}{1'b1}},  {25*8{1'b0}}};
       'd40: fn_mask_bytesvld_64 = { {{40*8}{1'b1}},  {24*8{1'b0}}};
       
       'd41: fn_mask_bytesvld_64 = { {{41*8}{1'b1}},  {23*8{1'b0}}};
       'd42: fn_mask_bytesvld_64 = { {{42*8}{1'b1}},  {22*8{1'b0}}};
       'd43: fn_mask_bytesvld_64 = { {{43*8}{1'b1}},  {21*8{1'b0}}};
       'd44: fn_mask_bytesvld_64 = { {{44*8}{1'b1}},  {20*8{1'b0}}};
       'd45: fn_mask_bytesvld_64 = { {{45*8}{1'b1}},  {19*8{1'b0}}};
       'd46: fn_mask_bytesvld_64 = { {{46*8}{1'b1}},  {18*8{1'b0}}};
       'd47: fn_mask_bytesvld_64 = { {{47*8}{1'b1}},  {17*8{1'b0}}};
       'd48: fn_mask_bytesvld_64 = { {{48*8}{1'b1}},  {16*8{1'b0}}};
       'd49: fn_mask_bytesvld_64 = { {{49*8}{1'b1}},  {15*8{1'b0}}};
       'd50: fn_mask_bytesvld_64 = { {{50*8}{1'b1}},  {14*8{1'b0}}};
       
       'd51: fn_mask_bytesvld_64 = { {{51*8}{1'b1}},  {13*8{1'b0}}};
       'd52: fn_mask_bytesvld_64 = { {{52*8}{1'b1}},  {12*8{1'b0}}};
       'd53: fn_mask_bytesvld_64 = { {{53*8}{1'b1}},  {11*8{1'b0}}};
       'd54: fn_mask_bytesvld_64 = { {{54*8}{1'b1}},  {10*8{1'b0}}};
       'd55: fn_mask_bytesvld_64 = { {{55*8}{1'b1}},  {9*8{1'b0}}};
       'd56: fn_mask_bytesvld_64 = { {{56*8}{1'b1}},  {8*8{1'b0}}};
       'd57: fn_mask_bytesvld_64 = { {{57*8}{1'b1}},  {7*8{1'b0}}};
       'd58: fn_mask_bytesvld_64 = { {{58*8}{1'b1}},  {6*8{1'b0}}};
       'd59: fn_mask_bytesvld_64 = { {{59*8}{1'b1}},  {5*8{1'b0}}};
       'd60: fn_mask_bytesvld_64 = { {{60*8}{1'b1}},  {4*8{1'b0}}};
       
       'd61: fn_mask_bytesvld_64 = { {{61*8}{1'b1}},  {3*8{1'b0}}};
       'd62: fn_mask_bytesvld_64 = { {{62*8}{1'b1}},  {2*8{1'b0}}};
       'd63: fn_mask_bytesvld_64 = { {{63*8}{1'b1}},  {1*8{1'b0}}};

	   default: fn_mask_bytesvld_64 = '1;
	 endcase	
	   
      end
   endfunction // fn_mask_bytesvld_64

  
endpackage // packet_switch_pkg
