//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 



//////////////////////////////////////////////////////////////////////////////////////////////
// Description:
// Parses and classifies a single cycle of 128B header.
//
// Updated Ethtype extraction:
// dot1q : DA - SA - VLAN - Ethtype
// dot2q : DA - SA - VLAN - VLAN - Ethtype
//
//////////////////////////////////////////////////////////////////////////////////////////////
//`default_nettype none
module parse_class_l2l3l4
   #( parameter TDATA_WIDTH                 = 512
     ,parameter SEGMENT_WIDTH               = 128
     ,parameter SEGMENT_DEPTH               = TDATA_WIDTH/SEGMENT_WIDTH // 4
   ) 

  (
    //----------------------------------------------------------------------------------------
    // Clocks
    input var logic                                   clk

    //----------------------------------------------------------------------------------------
    // Resets 
    ,input var logic                                   rst

    //----------------------------------------------------------------------------------------
    // parse_class_igr_intf interface
    ,input var logic                                   hdr_vld
    ,input var logic [SEGMENT_DEPTH*2-1:0]
                        [SEGMENT_WIDTH-1:0]            hdr_data
    ,input var packet_switch_pkg::SEGMENT_INFO_S          hdr_segment_info

    //----------------------------------------------------------------------------------------
    // classify interface
    ,output var logic                                  classify_tvalid
    ,output var packet_switch_pkg::tuple_map_S            classify_tuser_tuple_map
    ,output var packet_switch_hdr_pkg::HDR_ID_e           classify_hdr_id
   );
   import packet_switch_pkg::*;
   import packet_switch_hdr_pkg::*;

   // -----------------------------------------------------------
   // dot2q
   packet_switch_hdr_pkg::dot2q_t dot2q_hdr, dot2q_hdr_c1;

   packet_switch_hdr_pkg::dot2q_ptp_t dot2q_ptp_hdr;

   packet_switch_hdr_pkg::dot2q_ipv4_udp_t dot2q_ipv4_udp_hdr;
   packet_switch_hdr_pkg::dot2q_ipv6_udp_t dot2q_ipv6_udp_hdr;

   packet_switch_hdr_pkg::dot2q_ipv4_udp_ptp_t dot2q_ipv4_udp_ptp_hdr;
   packet_switch_hdr_pkg::dot2q_ipv6_udp_ptp_t dot2q_ipv6_udp_ptp_hdr;

   packet_switch_hdr_pkg::dot2q_ipv4_tcp_t dot2q_ipv4_tcp_hdr;
   packet_switch_hdr_pkg::dot2q_ipv6_tcp_t dot2q_ipv6_tcp_hdr;

   // -----------------------------------------------------------
   // dot1q
   packet_switch_hdr_pkg::dot1q_ptp_t dot1q_ptp_hdr;

   packet_switch_hdr_pkg::dot1q_ipv4_udp_t dot1q_ipv4_udp_hdr;
   packet_switch_hdr_pkg::dot1q_ipv6_udp_t dot1q_ipv6_udp_hdr;

   packet_switch_hdr_pkg::dot1q_ipv4_udp_ptp_t dot1q_ipv4_udp_ptp_hdr;
   packet_switch_hdr_pkg::dot1q_ipv6_udp_ptp_t dot1q_ipv6_udp_ptp_hdr;

   packet_switch_hdr_pkg::dot1q_ipv4_tcp_t dot1q_ipv4_tcp_hdr;
   packet_switch_hdr_pkg::dot1q_ipv6_tcp_t dot1q_ipv6_tcp_hdr;

   // ----------------------------------------------------------- 
   // eth
   packet_switch_hdr_pkg::eth_ptp_t eth_ptp_hdr;

   packet_switch_hdr_pkg::eth_ipv4_udp_t eth_ipv4_udp_hdr;
   packet_switch_hdr_pkg::eth_ipv6_udp_t eth_ipv6_udp_hdr;

   packet_switch_hdr_pkg::eth_ipv4_udp_ptp_t eth_ipv4_udp_ptp_hdr;
   packet_switch_hdr_pkg::eth_ipv6_udp_ptp_t eth_ipv6_udp_ptp_hdr;

   packet_switch_hdr_pkg::eth_ipv4_tcp_t eth_ipv4_tcp_hdr;
   packet_switch_hdr_pkg::eth_ipv6_tcp_t eth_ipv6_tcp_hdr;

   packet_switch_pkg::tuple_map_S extract_tuple_map;

   packet_switch_pkg::SEGMENT_INFO_S tuser_segment_info;

   packet_switch_hdr_pkg::HDR_ID_e hdr_id; 

   // -----------------------------------------------------------

   logic outer_tag_is_vlan, outer_tag_is_svlan, outer_tag_is_ipv4, outer_tag_is_ipv6,
         outer_tag_is_ptp, inner_tag_is_vlan, inner_tag_is_svlan, inner_tag_is_ipv4,
		 inner_tag_is_ipv6, inner_tag_is_ptp, tvalid, tvalid_c1, inner_tag_is_vlan_c1, 
         outer_tag_is_vlan_c1;

   logic [SEGMENT_DEPTH*2-1:0][SEGMENT_WIDTH-1:0] tdata;

   // cycle 1
   always_ff @(posedge clk) begin
     tvalid <= hdr_vld;
     tdata <= hdr_data;
     tuser_segment_info <= hdr_segment_info;
   end
   
   always_comb begin
     dot2q_hdr = tdata;
	 
     outer_tag_is_vlan  = '0;
     outer_tag_is_ipv4  = '0;
     outer_tag_is_ipv6  = '0;

     // determine outer_tag
     case (dot2q_hdr.eth.etype)
       // vlan detect
       packet_switch_hdr_pkg::ETYPE_e'(ETYPE_VLAN_CTAG):     outer_tag_is_vlan  = tvalid;
       packet_switch_hdr_pkg::ETYPE_e'(ETYPE_VLAN_STAG):     outer_tag_is_vlan  = tvalid;
       packet_switch_hdr_pkg::ETYPE_e'(ETYPE_VLAN_CTAG9100): outer_tag_is_vlan  = tvalid;
       packet_switch_hdr_pkg::ETYPE_e'(ETYPE_VLAN_CTAG9200): outer_tag_is_vlan  = tvalid;
       packet_switch_hdr_pkg::ETYPE_e'(ETYPE_VLAN_CTAG9300): outer_tag_is_vlan  = tvalid;
       
       // ipv4
      packet_switch_hdr_pkg::ETYPE_e'(ETYPE_IPV4):          outer_tag_is_ipv4  = tvalid;
    
       // ipv6
       packet_switch_hdr_pkg::ETYPE_e'(ETYPE_IPV6):          outer_tag_is_ipv6  = tvalid;
       default: begin
         outer_tag_is_vlan  = '0;
         outer_tag_is_ipv4  = '0;
         outer_tag_is_ipv6  = '0;
       end // case: default
     endcase // case (dot2q_hdr.eth.etype)
     
     inner_tag_is_vlan  = '0;
     inner_tag_is_ipv4  = '0;
     inner_tag_is_ipv6  = '0;

     // determine inner_tag
     case (dot2q_hdr.vlan.etype)
       // vlan detect
       ETYPE_e'(ETYPE_VLAN_CTAG):     inner_tag_is_vlan  = tvalid;
       ETYPE_e'(ETYPE_VLAN_STAG):     inner_tag_is_vlan  = tvalid;
       ETYPE_e'(ETYPE_VLAN_CTAG9100): inner_tag_is_vlan  = tvalid;
       ETYPE_e'(ETYPE_VLAN_CTAG9200): inner_tag_is_vlan  = tvalid;
       ETYPE_e'(ETYPE_VLAN_CTAG9300): inner_tag_is_vlan  = tvalid;

       // ipv4 detect
       ETYPE_e'(ETYPE_IPV4):          inner_tag_is_ipv4  = tvalid;
    
       // ipv6 detect
       ETYPE_e'(ETYPE_IPV6):          inner_tag_is_ipv6  = tvalid;
       default: begin
         inner_tag_is_vlan  = '0;
         inner_tag_is_ipv4  = '0;
         inner_tag_is_ipv6  = '0;
       end // case: default
     endcase // case (dot2q_hdr.eth.etype)
       
   end // always_ff

   always_comb begin
     // eth/dot1q/dot2q ptp
     eth_ptp_hdr   = tdata;
     dot1q_ptp_hdr = tdata;
     dot2q_ptp_hdr = tdata;

     // eth/dot1q/dot2q ipv4 udp
     eth_ipv4_udp_hdr   = tdata;
     dot1q_ipv4_udp_hdr = tdata;
     dot2q_ipv4_udp_hdr = tdata;

     // eth/dot1q/dot2q ipv4 udp ptp
     eth_ipv4_udp_ptp_hdr   = tdata;
     dot1q_ipv4_udp_ptp_hdr = tdata;
     dot2q_ipv4_udp_ptp_hdr = tdata;

     // eth/dot1q/dot2q ipv4 tcp
     eth_ipv4_tcp_hdr   = tdata;
     dot1q_ipv4_tcp_hdr = tdata;
     dot2q_ipv4_tcp_hdr = tdata;

     // eth/dot1q/dot2q ipv6 udp
     eth_ipv6_udp_hdr   = tdata;
     dot1q_ipv6_udp_hdr = tdata;
     dot2q_ipv6_udp_hdr = tdata;

     // eth/dot1q/dot2q ipv6 udp ptp
     eth_ipv6_udp_ptp_hdr   = tdata;
     dot1q_ipv6_udp_ptp_hdr = tdata;
     dot2q_ipv6_udp_ptp_hdr = tdata;

     // eth/dot1q/dot2q ipv6 tcp
     eth_ipv6_tcp_hdr   = tdata;
     dot1q_ipv6_tcp_hdr = tdata;
     dot2q_ipv6_tcp_hdr = tdata;
   end
   
   // cycle 2
   always_ff @(posedge clk) begin
     tvalid_c1 <= tvalid;   
     inner_tag_is_vlan_c1 <= inner_tag_is_vlan;
     outer_tag_is_vlan_c1 <= outer_tag_is_vlan;
   end

   always_ff @(posedge clk) begin
     // from igr_wadj block
     // extract_tuple_map.igr_ifid <= tuser_segment_info.igr_port;
      extract_tuple_map.rsvd <= '0;

     // dot2q detect
     if (outer_tag_is_vlan & inner_tag_is_vlan) begin
         // dot2q.ipv4
         if (dot2q_hdr.vlan_1.etype == ETYPE_e'(ETYPE_IPV4)) begin
              if (dot2q_ipv4_udp_hdr.ipv4.protocol == IP_PROTOCOL_e'(IP_PROTO_UDP)) begin
                // dot2q.ipv4.udp.ptp
                if ((dot2q_ipv4_udp_ptp_hdr.udp.dport == UDP_PORT_e'(UDP_PORT_PTP_EVENT)) | 
                    (dot2q_ipv4_udp_ptp_hdr.udp.dport == UDP_PORT_e'(UDP_PORT_PTP_GENERAL))) begin
                  extract_tuple_map.flagField      <= dot2q_ipv4_udp_ptp_hdr.ptp.flagField;
                  extract_tuple_map.messageType    <= dot2q_ipv4_udp_ptp_hdr.ptp.messageType;
                  extract_tuple_map.ip_protocol    <= dot2q_ipv4_udp_ptp_hdr.ipv4.protocol;
                  // extract_tuple_map.ethtype        <= dot2q_ipv4_udp_ptp_hdr.eth.etype;
                  extract_tuple_map.ethtype        <= dot2q_ipv4_udp_ptp_hdr.vlan_1.etype;
                  extract_tuple_map.tci_vlana      <= dot2q_ipv4_udp_ptp_hdr.vlan.tci;
                  extract_tuple_map.tci_vlanb      <= dot2q_ipv4_udp_ptp_hdr.vlan_1.tci;
                  extract_tuple_map.l4_src_port    <= dot2q_ipv4_udp_ptp_hdr.udp.sport;
                  extract_tuple_map.l4_dst_port    <= dot2q_ipv4_udp_ptp_hdr.udp.dport;
                  extract_tuple_map.src_ip[127:32] <= '0;
                  extract_tuple_map.src_ip[31:0]   <= dot2q_ipv4_udp_ptp_hdr.ipv4.src_ip;
                  extract_tuple_map.dst_ip[127:32] <= '0;
                  extract_tuple_map.dst_ip[31:0]   <= dot2q_ipv4_udp_ptp_hdr.ipv4.dst_ip;
                  extract_tuple_map.src_mac        <= dot2q_ipv4_udp_ptp_hdr.eth.sa;
                  extract_tuple_map.dst_mac        <= dot2q_ipv4_udp_ptp_hdr.eth.da;
                  hdr_id                           <= HDR_ID_e'(DOT2Q_IPV4_UDP_PTP);
                end else begin
                  extract_tuple_map.flagField      <= '0;
                  extract_tuple_map.messageType    <= '0;
                  extract_tuple_map.ip_protocol    <= dot2q_ipv4_udp_ptp_hdr.ipv4.protocol;
                  // extract_tuple_map.ethtype        <= dot2q_ipv4_udp_ptp_hdr.eth.etype;
                  extract_tuple_map.ethtype        <= dot2q_ipv4_udp_ptp_hdr.vlan_1.etype;
                  extract_tuple_map.tci_vlana      <= dot2q_ipv4_udp_ptp_hdr.vlan.tci;
                  extract_tuple_map.tci_vlanb      <= dot2q_ipv4_udp_ptp_hdr.vlan_1.tci;
                  extract_tuple_map.l4_src_port    <= dot2q_ipv4_udp_ptp_hdr.udp.sport;
                  extract_tuple_map.l4_dst_port    <= dot2q_ipv4_udp_ptp_hdr.udp.dport;
                  extract_tuple_map.src_ip[127:32] <= '0;
                  extract_tuple_map.src_ip[31:0]   <= dot2q_ipv4_udp_ptp_hdr.ipv4.src_ip;
                  extract_tuple_map.dst_ip[127:32] <= '0;
                  extract_tuple_map.dst_ip[31:0]   <= dot2q_ipv4_udp_ptp_hdr.ipv4.dst_ip;
                  extract_tuple_map.src_mac        <= dot2q_ipv4_udp_ptp_hdr.eth.sa;
                  extract_tuple_map.dst_mac        <= dot2q_ipv4_udp_ptp_hdr.eth.da;
                  hdr_id                           <= HDR_ID_e'(DOT2Q_IPV4_UDP);
                end
              // dot2q.ipv4.tcp
              end else if (dot2q_ipv4_tcp_hdr.ipv4.protocol == IP_PROTOCOL_e'(IP_PROTO_TCP)) begin
                extract_tuple_map.flagField      <= '0;
                extract_tuple_map.messageType    <= '0;
                extract_tuple_map.ip_protocol    <= dot2q_ipv4_tcp_hdr.ipv4.protocol;
                // extract_tuple_map.ethtype        <= dot2q_ipv4_tcp_hdr.eth.etype;
                extract_tuple_map.ethtype        <= dot2q_ipv4_tcp_hdr.vlan_1.etype;
                extract_tuple_map.tci_vlana      <= dot2q_ipv4_tcp_hdr.vlan.tci;
                extract_tuple_map.tci_vlanb      <= dot2q_ipv4_tcp_hdr.vlan_1.tci;
                extract_tuple_map.l4_src_port    <= dot2q_ipv4_tcp_hdr.tcp.src_port;
                extract_tuple_map.l4_dst_port    <= dot2q_ipv4_tcp_hdr.tcp.dst_port;
                extract_tuple_map.src_ip[127:32] <= '0;
                extract_tuple_map.src_ip[31:0]   <= dot2q_ipv4_tcp_hdr.ipv4.src_ip;
                extract_tuple_map.dst_ip[127:32] <= '0;
                extract_tuple_map.dst_ip[31:0]   <= dot2q_ipv4_tcp_hdr.ipv4.dst_ip;
                extract_tuple_map.src_mac        <= dot2q_ipv4_tcp_hdr.eth.sa;
                extract_tuple_map.dst_mac        <= dot2q_ipv4_tcp_hdr.eth.da;
                hdr_id                           <= HDR_ID_e'(DOT2Q_IPV4_TCP);

              // dot2q.ipv4
              end else begin
                extract_tuple_map.flagField      <= '0;
                extract_tuple_map.messageType    <= '0;
                extract_tuple_map.ip_protocol    <= dot2q_ipv4_udp_hdr.ipv4.protocol;
                // extract_tuple_map.ethtype        <= dot2q_ipv4_udp_hdr.eth.etype;
                extract_tuple_map.ethtype        <= dot2q_ipv4_udp_hdr.vlan_1.etype;
                extract_tuple_map.tci_vlana      <= dot2q_ipv4_udp_hdr.vlan.tci;
                extract_tuple_map.tci_vlanb      <= dot2q_ipv4_udp_hdr.vlan_1.tci;
                extract_tuple_map.l4_src_port    <= '0;
                extract_tuple_map.l4_dst_port    <= '0;
                extract_tuple_map.src_ip[127:32] <= '0;
                extract_tuple_map.src_ip[31:0]   <= dot2q_ipv4_udp_hdr.ipv4.src_ip;
                extract_tuple_map.dst_ip[127:32] <= '0;
                extract_tuple_map.dst_ip[31:0]   <= dot2q_ipv4_udp_hdr.ipv4.dst_ip;
                extract_tuple_map.src_mac        <= dot2q_ipv4_udp_hdr.eth.sa;
                extract_tuple_map.dst_mac        <= dot2q_ipv4_udp_hdr.eth.da;
                hdr_id                           <= HDR_ID_e'(DOT2Q_IPV4);
              end 
        end // if (dot2q_hdr.vlan_1.etype == ETYPE_e'(ETYPE_IPV4))

        // dot2q.ipv6
        else if (dot2q_hdr.vlan_1.etype == ETYPE_e'(ETYPE_IPV6)) begin         
              if (dot2q_ipv6_udp_hdr.ipv6.next_header == IP_PROTOCOL_e'(IP_PROTO_UDP)) begin
                // dot2q.ipv6.udp.ptp
                if ((dot2q_ipv6_udp_ptp_hdr.udp.dport == UDP_PORT_e'(UDP_PORT_PTP_EVENT)) | 
                    (dot2q_ipv6_udp_ptp_hdr.udp.dport == UDP_PORT_e'(UDP_PORT_PTP_GENERAL))) begin
                  extract_tuple_map.flagField    <= dot2q_ipv6_udp_ptp_hdr.ptp.flagField;
                  extract_tuple_map.messageType    <= dot2q_ipv6_udp_ptp_hdr.ptp.messageType;
                  extract_tuple_map.ip_protocol    <= dot2q_ipv6_udp_ptp_hdr.ipv6.next_header;
                  // extract_tuple_map.ethtype        <= dot2q_ipv6_udp_ptp_hdr.eth.etype;
                  extract_tuple_map.ethtype        <= dot2q_ipv6_udp_ptp_hdr.vlan_1.etype;
                  extract_tuple_map.tci_vlana      <= dot2q_ipv6_udp_ptp_hdr.vlan.tci;
                  extract_tuple_map.tci_vlanb      <= dot2q_ipv6_udp_ptp_hdr.vlan_1.tci;
                  extract_tuple_map.l4_src_port    <= dot2q_ipv6_udp_ptp_hdr.udp.sport;
                  extract_tuple_map.l4_dst_port    <= dot2q_ipv6_udp_ptp_hdr.udp.dport;
                  extract_tuple_map.src_ip         <= dot2q_ipv6_udp_ptp_hdr.ipv6.src_ip;
                  extract_tuple_map.dst_ip         <= dot2q_ipv6_udp_ptp_hdr.ipv6.dst_ip;
                  extract_tuple_map.src_mac        <= dot2q_ipv6_udp_ptp_hdr.eth.sa;
                  extract_tuple_map.dst_mac        <= dot2q_ipv6_udp_ptp_hdr.eth.da;
                  hdr_id                           <= HDR_ID_e'(DOT2Q_IPV6_UDP_PTP);
                // dot2q.ipv6.udp
                end else begin
                  extract_tuple_map.flagField      <= '0;
                  extract_tuple_map.messageType    <= '0;
                  extract_tuple_map.ip_protocol    <= dot2q_ipv6_udp_ptp_hdr.ipv6.next_header;
                  // extract_tuple_map.ethtype        <= dot2q_ipv6_udp_ptp_hdr.eth.etype;
                  extract_tuple_map.ethtype        <= dot2q_ipv6_udp_ptp_hdr.vlan_1.etype;
                  extract_tuple_map.tci_vlana      <= dot2q_ipv6_udp_ptp_hdr.vlan.tci;
                  extract_tuple_map.tci_vlanb      <= dot2q_ipv6_udp_ptp_hdr.vlan_1.tci;
                  extract_tuple_map.l4_src_port    <= dot2q_ipv6_udp_ptp_hdr.udp.sport;
                  extract_tuple_map.l4_dst_port    <= dot2q_ipv6_udp_ptp_hdr.udp.dport;
                  extract_tuple_map.src_ip         <= dot2q_ipv6_udp_ptp_hdr.ipv6.src_ip;
                  extract_tuple_map.dst_ip         <= dot2q_ipv6_udp_ptp_hdr.ipv6.dst_ip;
                  extract_tuple_map.src_mac        <= dot2q_ipv6_udp_ptp_hdr.eth.sa;
                  extract_tuple_map.dst_mac        <= dot2q_ipv6_udp_ptp_hdr.eth.da;
                  hdr_id                           <= HDR_ID_e'(DOT2Q_IPV6_UDP);
                end
              // dot2q.ipv6.tcp
              end else if (dot2q_ipv6_tcp_hdr.ipv6.next_header == IP_PROTOCOL_e'(IP_PROTO_TCP)) begin
                extract_tuple_map.flagField      <= '0;
                extract_tuple_map.messageType    <= '0;
                extract_tuple_map.ip_protocol    <= dot2q_ipv6_tcp_hdr.ipv6.next_header;
                // extract_tuple_map.ethtype        <= dot2q_ipv6_tcp_hdr.eth.etype;
                extract_tuple_map.ethtype        <= dot2q_ipv6_tcp_hdr.vlan_1.etype;
                extract_tuple_map.tci_vlana      <= dot2q_ipv6_tcp_hdr.vlan.tci;
                extract_tuple_map.tci_vlanb      <= dot2q_ipv6_tcp_hdr.vlan_1.tci;
                extract_tuple_map.l4_src_port    <= dot2q_ipv6_tcp_hdr.tcp.src_port;
                extract_tuple_map.l4_dst_port    <= dot2q_ipv6_tcp_hdr.tcp.dst_port;
                extract_tuple_map.src_ip         <= dot2q_ipv6_tcp_hdr.ipv6.src_ip;
                extract_tuple_map.dst_ip         <= dot2q_ipv6_tcp_hdr.ipv6.dst_ip;
                extract_tuple_map.src_mac        <= dot2q_ipv6_tcp_hdr.eth.sa;
                extract_tuple_map.dst_mac        <= dot2q_ipv6_tcp_hdr.eth.da;
                hdr_id                           <= HDR_ID_e'(DOT2Q_IPV6_TCP);

              // dot2q.ipv6
              end else begin
                extract_tuple_map.flagField      <= '0;
                extract_tuple_map.messageType    <= '0;
                extract_tuple_map.ip_protocol    <= dot2q_ipv6_udp_hdr.ipv6.next_header;
                // extract_tuple_map.ethtype        <= dot2q_ipv6_udp_hdr.eth.etype;
                extract_tuple_map.ethtype        <= dot2q_ipv6_udp_hdr.vlan_1.etype;
                extract_tuple_map.tci_vlana      <= dot2q_ipv6_udp_hdr.vlan.tci;
                extract_tuple_map.tci_vlanb      <= dot2q_ipv6_udp_hdr.vlan_1.tci;
                extract_tuple_map.l4_src_port    <= '0;
                extract_tuple_map.l4_dst_port    <= '0;
                extract_tuple_map.src_ip         <= dot2q_ipv6_udp_hdr.ipv6.src_ip;
                extract_tuple_map.dst_ip         <= dot2q_ipv6_udp_hdr.ipv6.dst_ip;
                extract_tuple_map.src_mac        <= dot2q_ipv6_udp_hdr.eth.sa;
                extract_tuple_map.dst_mac        <= dot2q_ipv6_udp_hdr.eth.da;
                hdr_id                           <= HDR_ID_e'(DOT2Q_IPV6);
              end
        end // if (dot2q_hdr.vlan_1.etype == ETYPE_e'(ETYPE_IPV6))

        // dot2q
        else begin
              // dot2q.ptp
              if (dot2q_ptp_hdr.vlan_1.etype == ETYPE_e'(ETYPE_PTP)) begin
                extract_tuple_map.flagField      <= dot2q_ptp_hdr.ptp.flagField;
                extract_tuple_map.messageType    <= dot2q_ptp_hdr.ptp.messageType;
                hdr_id                           <= HDR_ID_e'(DOT2Q_PTP);
              end else begin
              // dot2q
                extract_tuple_map.flagField      <= '0;
                extract_tuple_map.messageType    <= '0;
                hdr_id                           <= HDR_ID_e'(DOT2Q);
              end
                // dot2q
                extract_tuple_map.ip_protocol    <= '0;
                // extract_tuple_map.ethtype        <= dot2q_hdr.eth.etype;
                extract_tuple_map.ethtype        <= dot2q_hdr.vlan_1.etype;
                extract_tuple_map.tci_vlana      <= dot2q_hdr.vlan.tci;
                extract_tuple_map.tci_vlanb      <= dot2q_hdr.vlan_1.tci;
                extract_tuple_map.l4_src_port    <= '0;
                extract_tuple_map.l4_dst_port    <= '0;
                extract_tuple_map.src_ip         <= '0;
                extract_tuple_map.dst_ip         <= '0;
                extract_tuple_map.src_mac        <= dot2q_hdr.eth.sa;
                extract_tuple_map.dst_mac        <= dot2q_hdr.eth.da;
        end // outer_tag_is_vlan & inner_tag_is_vlan & !(ipv4 | ipv6)

     end // if (outer_tag_is_vlan & inner_tag_is_vlan)
 
     // dot1q detect
     else if (outer_tag_is_vlan) begin
           // dot1q.ipv4
           if (inner_tag_is_ipv4) begin
             if (dot1q_ipv4_udp_hdr.ipv4.protocol == IP_PROTOCOL_e'(IP_PROTO_UDP)) begin
               // dot1q.ipv4.udp.ptp
               if ((dot1q_ipv4_udp_ptp_hdr.udp.dport == UDP_PORT_e'(UDP_PORT_PTP_EVENT)) | 
                   (dot1q_ipv4_udp_ptp_hdr.udp.dport == UDP_PORT_e'(UDP_PORT_PTP_GENERAL))) begin
                 extract_tuple_map.flagField      <= dot1q_ipv4_udp_ptp_hdr.ptp.flagField;
                 extract_tuple_map.messageType    <= dot1q_ipv4_udp_ptp_hdr.ptp.messageType;
                 extract_tuple_map.ip_protocol    <= dot1q_ipv4_udp_ptp_hdr.ipv4.protocol;
                 // extract_tuple_map.ethtype        <= dot1q_ipv4_udp_ptp_hdr.eth.etype;
                 extract_tuple_map.ethtype        <= dot1q_ipv4_udp_ptp_hdr.vlan.etype;
                 extract_tuple_map.tci_vlana      <= dot1q_ipv4_udp_ptp_hdr.vlan.tci;
                 extract_tuple_map.tci_vlanb      <= '0;
                 extract_tuple_map.l4_src_port    <= dot1q_ipv4_udp_ptp_hdr.udp.sport;
                 extract_tuple_map.l4_dst_port    <= dot1q_ipv4_udp_ptp_hdr.udp.dport;
                 extract_tuple_map.src_ip[127:32] <= '0;
                 extract_tuple_map.src_ip[31:0]   <= dot1q_ipv4_udp_ptp_hdr.ipv4.src_ip;
                 extract_tuple_map.dst_ip[127:32] <= '0;
                 extract_tuple_map.dst_ip[31:0]   <= dot1q_ipv4_udp_ptp_hdr.ipv4.dst_ip;
                 extract_tuple_map.src_mac        <= dot1q_ipv4_udp_ptp_hdr.eth.sa;
                 extract_tuple_map.dst_mac        <= dot1q_ipv4_udp_ptp_hdr.eth.da;
                 hdr_id                           <= HDR_ID_e'(DOT1Q_IPV4_UDP_PTP);
               // dot1q.ipv4.udp
               end else begin
                 extract_tuple_map.flagField      <= '0;
                 extract_tuple_map.messageType    <= '0;
                 extract_tuple_map.ip_protocol    <= dot1q_ipv4_udp_ptp_hdr.ipv4.protocol;
                 // extract_tuple_map.ethtype        <= dot1q_ipv4_udp_ptp_hdr.eth.etype;
                 extract_tuple_map.ethtype        <= dot1q_ipv4_udp_ptp_hdr.vlan.etype;
                 extract_tuple_map.tci_vlana      <= dot1q_ipv4_udp_ptp_hdr.vlan.tci;
                 extract_tuple_map.tci_vlanb      <= '0;
                 extract_tuple_map.l4_src_port    <= dot1q_ipv4_udp_ptp_hdr.udp.sport;
                 extract_tuple_map.l4_dst_port    <= dot1q_ipv4_udp_ptp_hdr.udp.dport;
                 extract_tuple_map.src_ip[127:32] <= '0;
                 extract_tuple_map.src_ip[31:0]   <= dot1q_ipv4_udp_ptp_hdr.ipv4.src_ip;
                 extract_tuple_map.dst_ip[127:32] <= '0;
                 extract_tuple_map.dst_ip[31:0]   <= dot1q_ipv4_udp_ptp_hdr.ipv4.dst_ip;
                 extract_tuple_map.src_mac        <= dot1q_ipv4_udp_ptp_hdr.eth.sa;
                 extract_tuple_map.dst_mac        <= dot1q_ipv4_udp_ptp_hdr.eth.da;
                 hdr_id                           <= HDR_ID_e'(DOT1Q_IPV4_UDP);
               end

             // dot1q.ipv4.tcp
             end else if (dot1q_ipv4_tcp_hdr.ipv4.protocol == IP_PROTOCOL_e'(IP_PROTO_TCP)) begin
               extract_tuple_map.flagField      <= '0;
               extract_tuple_map.messageType    <= '0;
               extract_tuple_map.ip_protocol    <= dot1q_ipv4_tcp_hdr.ipv4.protocol;
               // extract_tuple_map.ethtype        <= dot1q_ipv4_tcp_hdr.eth.etype;
               extract_tuple_map.ethtype        <= dot1q_ipv4_tcp_hdr.vlan.etype;
               extract_tuple_map.tci_vlana      <= dot1q_ipv4_tcp_hdr.vlan.tci;
               extract_tuple_map.tci_vlanb      <= '0;
               extract_tuple_map.l4_src_port    <= dot1q_ipv4_tcp_hdr.tcp.src_port;
               extract_tuple_map.l4_dst_port    <= dot1q_ipv4_tcp_hdr.tcp.dst_port;
               extract_tuple_map.src_ip[127:32] <= '0;
               extract_tuple_map.src_ip[31:0]   <= dot1q_ipv4_tcp_hdr.ipv4.src_ip;
               extract_tuple_map.dst_ip[127:32] <= '0;
               extract_tuple_map.dst_ip[31:0]   <= dot1q_ipv4_tcp_hdr.ipv4.dst_ip;
               extract_tuple_map.src_mac        <= dot1q_ipv4_tcp_hdr.eth.sa;
               extract_tuple_map.dst_mac        <= dot1q_ipv4_tcp_hdr.eth.da;
               hdr_id                           <= HDR_ID_e'(DOT1Q_IPV4_TCP);

             // dot1q.ipv4
             end else begin
               extract_tuple_map.flagField      <= '0;
               extract_tuple_map.messageType    <= '0;
               extract_tuple_map.ip_protocol    <= dot1q_ipv4_udp_hdr.ipv4.protocol;
               // extract_tuple_map.ethtype        <= dot1q_ipv4_udp_hdr.eth.etype;
               extract_tuple_map.ethtype        <= dot1q_ipv4_udp_hdr.vlan.etype;
               extract_tuple_map.tci_vlana      <= dot1q_ipv4_udp_hdr.vlan.tci;
               extract_tuple_map.tci_vlanb      <= '0;
               extract_tuple_map.l4_src_port    <= '0;
               extract_tuple_map.l4_dst_port    <= '0;
               extract_tuple_map.src_ip[127:32] <= '0;
               extract_tuple_map.src_ip[31:0]   <= dot1q_ipv4_udp_hdr.ipv4.src_ip;
               extract_tuple_map.dst_ip[127:32] <= '0;
               extract_tuple_map.dst_ip[31:0]   <= dot1q_ipv4_udp_hdr.ipv4.dst_ip;
               extract_tuple_map.src_mac        <= dot1q_ipv4_udp_hdr.eth.sa;
               extract_tuple_map.dst_mac        <= dot1q_ipv4_udp_hdr.eth.da;
               hdr_id                           <= HDR_ID_e'(DOT1Q_IPV4);
             end

           end // if (inner_tag_is_ipv4)
           
           else if (inner_tag_is_ipv6) begin
             if (dot1q_ipv6_udp_hdr.ipv6.next_header == IP_PROTOCOL_e'(IP_PROTO_UDP)) begin
               // dot1q.ipv6.udp.ptp
               if ((dot1q_ipv6_udp_ptp_hdr.udp.dport == UDP_PORT_e'(UDP_PORT_PTP_EVENT)) | 
                   (dot1q_ipv6_udp_ptp_hdr.udp.dport == UDP_PORT_e'(UDP_PORT_PTP_GENERAL))) begin
                 extract_tuple_map.flagField      <= dot1q_ipv6_udp_ptp_hdr.ptp.flagField;
                 extract_tuple_map.messageType    <= dot1q_ipv6_udp_ptp_hdr.ptp.messageType;
                 extract_tuple_map.ip_protocol    <= dot1q_ipv6_udp_ptp_hdr.ipv6.next_header;
                 // extract_tuple_map.ethtype        <= dot1q_ipv6_udp_ptp_hdr.eth.etype;
                 extract_tuple_map.ethtype        <= dot1q_ipv6_udp_ptp_hdr.vlan.etype;
                 extract_tuple_map.tci_vlana      <= dot1q_ipv6_udp_ptp_hdr.vlan.tci;
                 extract_tuple_map.tci_vlanb      <= '0;
                 extract_tuple_map.l4_src_port    <= dot1q_ipv6_udp_ptp_hdr.udp.sport;
                 extract_tuple_map.l4_dst_port    <= dot1q_ipv6_udp_ptp_hdr.udp.dport;
                 extract_tuple_map.src_ip         <= dot1q_ipv6_udp_ptp_hdr.ipv6.src_ip;
                 extract_tuple_map.dst_ip         <= dot1q_ipv6_udp_ptp_hdr.ipv6.dst_ip;
                 extract_tuple_map.src_mac        <= dot1q_ipv6_udp_ptp_hdr.eth.sa;
                 extract_tuple_map.dst_mac        <= dot1q_ipv6_udp_ptp_hdr.eth.da;
                 hdr_id                           <= HDR_ID_e'(DOT1Q_IPV6_UDP_PTP);
               // dot1q.ipv6.udp
               end else begin
                 extract_tuple_map.flagField      <= '0;
                 extract_tuple_map.messageType    <= '0;
                 extract_tuple_map.ip_protocol    <= dot1q_ipv6_udp_ptp_hdr.ipv6.next_header;
                 // extract_tuple_map.ethtype        <= dot1q_ipv6_udp_ptp_hdr.eth.etype;
                 extract_tuple_map.ethtype        <= dot1q_ipv6_udp_ptp_hdr.vlan.etype;
                 extract_tuple_map.tci_vlana      <= dot1q_ipv6_udp_ptp_hdr.vlan.tci;
                 extract_tuple_map.tci_vlanb      <= '0;
                 extract_tuple_map.l4_src_port    <= dot1q_ipv6_udp_ptp_hdr.udp.sport;
                 extract_tuple_map.l4_dst_port    <= dot1q_ipv6_udp_ptp_hdr.udp.dport;
                 extract_tuple_map.src_ip         <= dot1q_ipv6_udp_ptp_hdr.ipv6.src_ip;
                 extract_tuple_map.dst_ip         <= dot1q_ipv6_udp_ptp_hdr.ipv6.dst_ip;
                 extract_tuple_map.src_mac        <= dot1q_ipv6_udp_ptp_hdr.eth.sa;
                 extract_tuple_map.dst_mac        <= dot1q_ipv6_udp_ptp_hdr.eth.da;
                 hdr_id                           <= HDR_ID_e'(DOT1Q_IPV6_UDP);
               end

             // dot1q.ipv6.tcp
             end else if (dot1q_ipv6_tcp_hdr.ipv6.next_header == IP_PROTOCOL_e'(IP_PROTO_TCP)) begin
               extract_tuple_map.flagField      <= '0;
               extract_tuple_map.messageType    <= '0;
               extract_tuple_map.ip_protocol    <= dot1q_ipv6_tcp_hdr.ipv6.next_header;
               // extract_tuple_map.ethtype        <= dot1q_ipv6_tcp_hdr.eth.etype;
               extract_tuple_map.ethtype        <= dot1q_ipv6_tcp_hdr.vlan.etype;
               extract_tuple_map.tci_vlana      <= dot1q_ipv6_tcp_hdr.vlan.tci;
               extract_tuple_map.tci_vlanb      <= '0;
               extract_tuple_map.l4_src_port    <= dot1q_ipv6_tcp_hdr.tcp.src_port;
               extract_tuple_map.l4_dst_port    <= dot1q_ipv6_tcp_hdr.tcp.dst_port;
               extract_tuple_map.src_ip         <= dot1q_ipv6_tcp_hdr.ipv6.src_ip;
               extract_tuple_map.dst_ip         <= dot1q_ipv6_tcp_hdr.ipv6.dst_ip;
               extract_tuple_map.src_mac        <= dot1q_ipv6_tcp_hdr.eth.sa;
               extract_tuple_map.dst_mac        <= dot1q_ipv6_tcp_hdr.eth.da;
               hdr_id                           <= HDR_ID_e'(DOT1Q_IPV6_TCP);

             // dot1q.ipv6
             end else begin
               extract_tuple_map.flagField      <= '0;
               extract_tuple_map.messageType    <= '0;
               extract_tuple_map.ip_protocol    <= dot1q_ipv6_udp_hdr.ipv6.next_header;
               // extract_tuple_map.ethtype        <= dot1q_ipv6_udp_hdr.eth.etype;
               extract_tuple_map.ethtype        <= dot1q_ipv6_udp_hdr.vlan.etype;
               extract_tuple_map.tci_vlana      <= dot1q_ipv6_udp_hdr.vlan.tci;
               extract_tuple_map.tci_vlanb      <= '0;
               extract_tuple_map.l4_src_port    <= '0;
               extract_tuple_map.l4_dst_port    <= '0;
               extract_tuple_map.src_ip         <= dot1q_ipv6_udp_hdr.ipv6.src_ip;
               extract_tuple_map.dst_ip         <= dot1q_ipv6_udp_hdr.ipv6.dst_ip;
               extract_tuple_map.src_mac        <= dot1q_ipv6_udp_hdr.eth.sa;
               extract_tuple_map.dst_mac        <= dot1q_ipv6_udp_hdr.eth.da;
               hdr_id                           <= HDR_ID_e'(DOT1Q_IPV6);
             end 
          end // if (inner_tag_is_ipv6)
          
          // dot1q
          else begin
               // dot1q.ptp
               if (dot1q_ptp_hdr.vlan.etype == ETYPE_e'(ETYPE_PTP)) begin
                 extract_tuple_map.flagField      <= dot1q_ptp_hdr.ptp.flagField;
                 extract_tuple_map.messageType    <= dot1q_ptp_hdr.ptp.messageType;
                 hdr_id                           <= HDR_ID_e'(DOT1Q_PTP);
               end else begin
               // dot1q
                 extract_tuple_map.flagField      <= '0;
                 extract_tuple_map.messageType    <= '0;
                 hdr_id                           <= HDR_ID_e'(DOT1Q);
               end
               // dot1q
               extract_tuple_map.ip_protocol    <= '0;
               // extract_tuple_map.ethtype        <= dot1q_ipv4_udp_hdr.eth.etype;
               extract_tuple_map.ethtype        <= dot1q_ipv4_udp_hdr.vlan.etype;
               extract_tuple_map.tci_vlana      <= dot1q_ipv4_udp_hdr.vlan.tci;
               extract_tuple_map.tci_vlanb      <= '0;
               extract_tuple_map.l4_src_port    <= '0;
               extract_tuple_map.l4_dst_port    <= '0;
               extract_tuple_map.src_ip         <= '0;
               extract_tuple_map.dst_ip         <= '0;
               extract_tuple_map.src_mac        <= dot1q_ipv4_udp_hdr.eth.sa;
               extract_tuple_map.dst_mac        <= dot1q_ipv4_udp_hdr.eth.da;
          end // outer_tag_is_vlan & !(inner_tag_is_ipv6) & ! (inner_tag_is_ipv4)

      end // if (outer_tag_is_vlan)

      else if (outer_tag_is_ipv4) begin
          if (eth_ipv4_udp_hdr.ipv4.protocol == IP_PROTOCOL_e'(IP_PROTO_UDP)) begin
            // eth.ipv4.udp.ptp
            if ((eth_ipv4_udp_ptp_hdr.udp.dport == UDP_PORT_e'(UDP_PORT_PTP_EVENT)) | 
                (eth_ipv4_udp_ptp_hdr.udp.dport == UDP_PORT_e'(UDP_PORT_PTP_GENERAL))) begin
              extract_tuple_map.flagField      <= eth_ipv4_udp_ptp_hdr.ptp.flagField;
              extract_tuple_map.messageType    <= eth_ipv4_udp_ptp_hdr.ptp.messageType;
              extract_tuple_map.ip_protocol    <= eth_ipv4_udp_ptp_hdr.ipv4.protocol;
              extract_tuple_map.ethtype        <= eth_ipv4_udp_ptp_hdr.eth.etype;
              extract_tuple_map.tci_vlana      <= '0;
              extract_tuple_map.tci_vlanb      <= '0;
              extract_tuple_map.l4_src_port    <= eth_ipv4_udp_ptp_hdr.udp.sport;
              extract_tuple_map.l4_dst_port    <= eth_ipv4_udp_ptp_hdr.udp.dport;
              extract_tuple_map.src_ip[127:32] <= '0;
              extract_tuple_map.src_ip[31:0]   <= eth_ipv4_udp_ptp_hdr.ipv4.src_ip;
              extract_tuple_map.dst_ip[127:32] <= '0;
              extract_tuple_map.dst_ip[31:0]   <= eth_ipv4_udp_ptp_hdr.ipv4.dst_ip;
              extract_tuple_map.src_mac        <= eth_ipv4_udp_ptp_hdr.eth.sa;
              extract_tuple_map.dst_mac        <= eth_ipv4_udp_ptp_hdr.eth.da;
              hdr_id                           <= HDR_ID_e'(ETH_IPV4_UDP_PTP);
            // eth.ipv4.udp
            end else begin
              extract_tuple_map.flagField      <= '0;
              extract_tuple_map.messageType    <= '0;
              extract_tuple_map.ip_protocol    <= eth_ipv4_udp_ptp_hdr.ipv4.protocol;
              extract_tuple_map.ethtype        <= eth_ipv4_udp_ptp_hdr.eth.etype;
              extract_tuple_map.tci_vlana      <= '0;
              extract_tuple_map.tci_vlanb      <= '0;
              extract_tuple_map.l4_src_port    <= eth_ipv4_udp_ptp_hdr.udp.sport;
              extract_tuple_map.l4_dst_port    <= eth_ipv4_udp_ptp_hdr.udp.dport;
              extract_tuple_map.src_ip[127:32] <= '0;
              extract_tuple_map.src_ip[31:0]   <= eth_ipv4_udp_ptp_hdr.ipv4.src_ip;
              extract_tuple_map.dst_ip[127:32] <= '0;
              extract_tuple_map.dst_ip[31:0]   <= eth_ipv4_udp_ptp_hdr.ipv4.dst_ip;
              extract_tuple_map.src_mac        <= eth_ipv4_udp_ptp_hdr.eth.sa;
              extract_tuple_map.dst_mac        <= eth_ipv4_udp_ptp_hdr.eth.da;
              hdr_id                           <= HDR_ID_e'(ETH_IPV4_UDP);
            end

          // eth.ipv4.tcp
          end else if (eth_ipv4_tcp_hdr.ipv4.protocol == IP_PROTOCOL_e'(IP_PROTO_TCP)) begin
            extract_tuple_map.flagField      <= '0;
            extract_tuple_map.messageType    <= '0;
            extract_tuple_map.ip_protocol    <= eth_ipv4_tcp_hdr.ipv4.protocol;
            extract_tuple_map.ethtype        <= eth_ipv4_tcp_hdr.eth.etype;
            extract_tuple_map.tci_vlana      <= '0;
            extract_tuple_map.tci_vlanb      <= '0;
            extract_tuple_map.l4_src_port    <= eth_ipv4_tcp_hdr.tcp.src_port;
            extract_tuple_map.l4_dst_port    <= eth_ipv4_tcp_hdr.tcp.dst_port;
            extract_tuple_map.src_ip[127:32] <= '0;
            extract_tuple_map.src_ip[31:0]   <= eth_ipv4_tcp_hdr.ipv4.src_ip;
            extract_tuple_map.dst_ip[127:32] <= '0;
            extract_tuple_map.dst_ip[31:0]   <= eth_ipv4_tcp_hdr.ipv4.dst_ip;
            extract_tuple_map.src_mac        <= eth_ipv4_tcp_hdr.eth.sa;
            extract_tuple_map.dst_mac        <= eth_ipv4_tcp_hdr.eth.da;
            hdr_id                           <= HDR_ID_e'(ETH_IPV4_TCP);

          // eth.ipv4
          end else begin
            extract_tuple_map.flagField      <= '0;
            extract_tuple_map.messageType    <= '0;
            extract_tuple_map.ip_protocol    <= eth_ipv4_udp_hdr.ipv4.protocol;
            extract_tuple_map.ethtype        <= eth_ipv4_udp_hdr.eth.etype;
            extract_tuple_map.tci_vlana      <= '0;
            extract_tuple_map.tci_vlanb      <= '0;
            extract_tuple_map.l4_src_port    <= '0;
            extract_tuple_map.l4_dst_port    <= '0;
            extract_tuple_map.src_ip[127:32] <= '0;
            extract_tuple_map.src_ip[31:0]   <= eth_ipv4_udp_hdr.ipv4.src_ip;
            extract_tuple_map.dst_ip[127:32] <= '0;
            extract_tuple_map.dst_ip[31:0]   <= eth_ipv4_udp_hdr.ipv4.dst_ip;
            extract_tuple_map.src_mac        <= eth_ipv4_udp_hdr.eth.sa;
            extract_tuple_map.dst_mac        <= eth_ipv4_udp_hdr.eth.da;
            hdr_id                           <= HDR_ID_e'(ETH_IPV4);
          end 

       end // if (outer_tag_is_ipv4)

       else if (outer_tag_is_ipv6) begin
          if (eth_ipv6_udp_hdr.ipv6.next_header == IP_PROTOCOL_e'(IP_PROTO_UDP)) begin
            // eth.ipv6.udp.ptp
            if ((eth_ipv6_udp_ptp_hdr.udp.dport == UDP_PORT_e'(UDP_PORT_PTP_EVENT)) | 
                (eth_ipv6_udp_ptp_hdr.udp.dport == UDP_PORT_e'(UDP_PORT_PTP_GENERAL))) begin
              extract_tuple_map.flagField      <= eth_ipv6_udp_ptp_hdr.ptp.flagField;
              extract_tuple_map.messageType    <= eth_ipv6_udp_ptp_hdr.ptp.messageType;
              extract_tuple_map.ip_protocol    <= eth_ipv6_udp_ptp_hdr.ipv6.next_header;
              extract_tuple_map.ethtype        <= eth_ipv6_udp_ptp_hdr.eth.etype;
              extract_tuple_map.tci_vlana      <= '0;
              extract_tuple_map.tci_vlanb      <= '0;
              extract_tuple_map.l4_src_port    <= eth_ipv6_udp_ptp_hdr.udp.sport;
              extract_tuple_map.l4_dst_port    <= eth_ipv6_udp_ptp_hdr.udp.dport;
              extract_tuple_map.src_ip         <= eth_ipv6_udp_ptp_hdr.ipv6.src_ip;
              extract_tuple_map.dst_ip         <= eth_ipv6_udp_ptp_hdr.ipv6.dst_ip;
              extract_tuple_map.src_mac        <= eth_ipv6_udp_ptp_hdr.eth.sa;
              extract_tuple_map.dst_mac        <= eth_ipv6_udp_ptp_hdr.eth.da;
              hdr_id                           <= HDR_ID_e'(ETH_IPV6_UDP_PTP);
            // eth.ipv6.udp
            end else begin
              extract_tuple_map.flagField      <= '0;
              extract_tuple_map.messageType    <= '0;
              extract_tuple_map.ip_protocol    <= eth_ipv6_udp_ptp_hdr.ipv6.next_header;
              extract_tuple_map.ethtype        <= eth_ipv6_udp_ptp_hdr.eth.etype;
              extract_tuple_map.tci_vlana      <= '0;
              extract_tuple_map.tci_vlanb      <= '0;
              extract_tuple_map.l4_src_port    <= eth_ipv6_udp_ptp_hdr.udp.sport;
              extract_tuple_map.l4_dst_port    <= eth_ipv6_udp_ptp_hdr.udp.dport;
              extract_tuple_map.src_ip         <= eth_ipv6_udp_ptp_hdr.ipv6.src_ip;
              extract_tuple_map.dst_ip         <= eth_ipv6_udp_ptp_hdr.ipv6.dst_ip;
              extract_tuple_map.src_mac        <= eth_ipv6_udp_ptp_hdr.eth.sa;
              extract_tuple_map.dst_mac        <= eth_ipv6_udp_ptp_hdr.eth.da;
              hdr_id                           <= HDR_ID_e'(ETH_IPV6_UDP);
            end

          // eth.ipv6.tcp
          end else if (eth_ipv6_tcp_hdr.ipv6.next_header == IP_PROTOCOL_e'(IP_PROTO_TCP)) begin
            extract_tuple_map.flagField      <= '0;
            extract_tuple_map.messageType    <= '0;
            extract_tuple_map.ip_protocol    <= eth_ipv6_tcp_hdr.ipv6.next_header;
            extract_tuple_map.ethtype        <= eth_ipv6_tcp_hdr.eth.etype;
            extract_tuple_map.tci_vlana      <= '0;
            extract_tuple_map.tci_vlanb      <= '0;
            extract_tuple_map.l4_src_port    <= eth_ipv6_tcp_hdr.tcp.src_port;
            extract_tuple_map.l4_dst_port    <= eth_ipv6_tcp_hdr.tcp.dst_port;
            extract_tuple_map.src_ip         <= eth_ipv6_tcp_hdr.ipv6.src_ip;
            extract_tuple_map.dst_ip         <= eth_ipv6_tcp_hdr.ipv6.dst_ip;
            extract_tuple_map.src_mac        <= eth_ipv6_tcp_hdr.eth.sa;
            extract_tuple_map.dst_mac        <= eth_ipv6_tcp_hdr.eth.da;
            hdr_id                           <= HDR_ID_e'(ETH_IPV6_TCP);
          
          // eth.ipv6
          end else begin
            extract_tuple_map.flagField      <= '0;
            extract_tuple_map.messageType    <= '0;
            extract_tuple_map.ip_protocol    <= eth_ipv6_udp_hdr.ipv6.next_header;
            extract_tuple_map.ethtype        <= eth_ipv6_udp_hdr.eth.etype;
            extract_tuple_map.tci_vlana      <= '0;
            extract_tuple_map.tci_vlanb      <= '0;
            extract_tuple_map.l4_src_port    <= '0;
            extract_tuple_map.l4_dst_port    <= '0;
            extract_tuple_map.src_ip         <= eth_ipv6_udp_hdr.ipv6.src_ip;
            extract_tuple_map.dst_ip         <= eth_ipv6_udp_hdr.ipv6.dst_ip;
            extract_tuple_map.src_mac        <= eth_ipv6_udp_hdr.eth.sa;
            extract_tuple_map.dst_mac        <= eth_ipv6_udp_hdr.eth.da;
            hdr_id                           <= HDR_ID_e'(ETH_IPV6);
          end 
        end // if (outer_tag_is_ipv6) 

        // eth
        else begin
            // eth.ptp
            if (eth_ptp_hdr.eth.etype == ETYPE_e'(ETYPE_PTP)) begin
              extract_tuple_map.flagField      <= eth_ptp_hdr.ptp.flagField;
              extract_tuple_map.messageType    <= eth_ptp_hdr.ptp.messageType;
              hdr_id                           <= HDR_ID_e'(ETH_PTP);
            end else begin
            // eth
              extract_tuple_map.flagField      <= '0;
              extract_tuple_map.messageType    <= '0;
              hdr_id                           <= HDR_ID_e'(ETH);
            end
            // eth
            extract_tuple_map.ip_protocol    <= '0;
            extract_tuple_map.ethtype        <= eth_ipv6_udp_hdr.eth.etype;
            extract_tuple_map.tci_vlana      <= '0;
            extract_tuple_map.tci_vlanb      <= '0;
            extract_tuple_map.l4_src_port    <= '0;
            extract_tuple_map.l4_dst_port    <= '0;
            extract_tuple_map.src_ip         <= '0;
            extract_tuple_map.dst_ip         <= '0;
            extract_tuple_map.src_mac        <= eth_ipv6_udp_hdr.eth.sa;
            extract_tuple_map.dst_mac        <= eth_ipv6_udp_hdr.eth.da;
        end
      end // always_ff

  always_comb begin
    classify_tvalid = tvalid_c1;
    classify_tuser_tuple_map = extract_tuple_map;
    classify_hdr_id = hdr_id;
  end

endmodule
