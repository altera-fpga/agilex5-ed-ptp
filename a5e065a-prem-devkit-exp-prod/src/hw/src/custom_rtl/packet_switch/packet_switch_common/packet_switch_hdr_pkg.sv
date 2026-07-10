//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


package packet_switch_hdr_pkg;

    //----------------------------------------------------------------------------------------
    // etype
    typedef enum logic [15:0] {
	// Ethernet types defined in https://tools.ietf.org/html/rfc7042, Appendix B
 	ETYPE_VLAN_CTAG       = 16'h8100, 	  // double VALN inner VLAN tag
 	ETYPE_VLAN_STAG       = 16'h88A8, 	  // 802.ad vlan stacking
 	ETYPE_VLAN_CTAG9100   = 16'h9100,         // 802.1Q stacking
    ETYPE_VLAN_CTAG9200   = 16'h9200,         // 802.1Q stacking
	ETYPE_VLAN_CTAG9300   = 16'h9300,         // 802.1Q stacking
 	ETYPE_IPV4            = 16'h0800,  
 	ETYPE_IPV6            = 16'h86DD,
 	ETYPE_PTP             = 16'h88F7,	  // 1588 precision time protocol
	ETYPE_NULL            = 16'h0
    } ETYPE_e;
    //----------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------------
    // protocol type
    typedef enum logic [7:0] {
        IP_PROTO_ICMP         = 8'd1,
 	IP_PROTO_IPV4         = 8'd4,
 	IP_PROTO_TCP          = 8'd6,
 	IP_PROTO_UDP          = 8'd17,
 	IP_PROTO_IPV6         = 8'd41,  // IP-in-IP
 	IP_PROTO_GRE          = 8'd47,  // All GRE forms
 	IP_PROTO_ESP          = 8'd50,
 	IP_PROTO_ICMPV6       = 8'd58,
 	IP_PROTO_SCTP         = 8'd132
    } IP_PROTOCOL_e;
   
    typedef enum logic [7:0] {
	// IPv6 extension headers.  Each one is 8 bytes long, except ESP.
 	IP_PROTO_EXT_HOP      = 8'd0,   // Hop-by-hop options
 	IP_PROTO_EXT_ROUTING  = 8'd43,  // Routing
 	IP_PROTO_EXT_FRAG     = 8'd44,  // Fragment
 	IP_PROTO_EXT_ESP      = 8'd50,  // Encap Security Protocol
 	IP_PROTO_EXT_AH       = 8'd51,  // Authentication header
 	IP_PROTO_EXT_DESTOPT  = 8'd60,  // Dest options
 	IP_PROTO_EXT_MOBL     = 8'd135, // Mobile IPv6
 	IP_PROTO_EXT_HIPV2    = 8'd139, // Host Identity Protocol v2
 	IP_PROTO_EXT_SHIM6    = 8'd140  // Site Multi-homing   
      			
    } IP_EXT_PROTOCOL_e;
    //----------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------------
    // UDP ports assignment
    typedef enum logic [15:0] {
	UDP_PORT_VXLAN     = 16'd4789,
	UDP_PORT_VXLAN_GPE = 16'd4790,
	UDP_PORT_ROCEV2    = 16'd4791,
	UDP_PORT_ROCEV2_2  = 16'd4792,
	UDP_PORT_GENEVE    = 16'd6081,
	UDP_PORT_NSH       = 16'd6633,
    UDP_PORT_GTPC      = 16'd2123,
    UDP_PORT_GTPU      = 16'd2152,
	UDP_PORT_L2TP      = 16'd1701,
	UDP_PORT_PTP_EVENT = 16'd319,
	UDP_PORT_PTP_GENERAL = 16'd320
    } UDP_PORT_e;
    //----------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------------
    // header identification
    typedef enum logic [4:0] {
     ETH_IPV4_UDP_PTP   = 5'd0
    ,DOT1Q_IPV4_UDP_PTP  = 5'd1
    ,DOT2Q_IPV4_UDP_PTP = 5'd2
	
    ,ETH_IPV4_UDP   = 5'd3
    ,DOT1Q_IPV4_UDP  = 5'd4
    ,DOT2Q_IPV4_UDP = 5'd5
	
    ,ETH_IPV4_TCP   = 5'd6
    ,DOT1Q_IPV4_TCP  = 5'd7
    ,DOT2Q_IPV4_TCP = 5'd8
	
    ,ETH_IPV4   = 5'd9
    ,DOT1Q_IPV4  = 5'd10
    ,DOT2Q_IPV4 = 5'd11
	
    ,ETH_IPV6_UDP_PTP   = 5'd12
    ,DOT1Q_IPV6_UDP_PTP  = 5'd13
    ,DOT2Q_IPV6_UDP_PTP = 5'd14
	
    ,ETH_IPV6_UDP   = 5'd15 
    ,DOT1Q_IPV6_UDP  = 5'd16
    ,DOT2Q_IPV6_UDP = 5'd17
	
    ,ETH_IPV6_TCP   = 5'd18
    ,DOT1Q_IPV6_TCP  = 5'd19
    ,DOT2Q_IPV6_TCP = 5'd20
	
    ,ETH_IPV6   = 5'd21
    ,DOT1Q_IPV6  = 5'd22
    ,DOT2Q_IPV6 = 5'd23
	
    ,ETH_PTP   = 5'd24
    ,DOT1Q_PTP  = 5'd25
    ,DOT2Q_PTP = 5'd26
	
    ,ETH   = 5'd27
    ,DOT1Q  = 5'd28
    ,DOT2Q = 5'd29
    } HDR_ID_e;

     parameter hdr_id_width = $bits(HDR_ID_e);
    //----------------------------------------------------------------------------------------


    //----------------------------------------------------------------------------------------
    // hdr templates
    //----------------------------------------------------------------------------------------

   //----------------------------------------------------------------------------------------
   // eth
    typedef struct packed {
	logic [47:0]     da;     // destination address
	logic [47:0]     sa;     // source address
        ETYPE_e          etype;  
	
    } eth_hdr_t;
    //----------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------------
    // vlan
    typedef struct packed {
	logic [15:0]      tci;   // Tag control info
	ETYPE_e           etype; // Ethertype field
    } vlan_hdr_t;
    //----------------------------------------------------------------------------------------
    
    //----------------------------------------------------------------------------------------
    // ipv4 hdr
    typedef struct  packed { 
      logic [3:0]        version;
      logic [3:0]        ihl;
      logic [5:0]        dscp;
      logic [1:0]        ecn;
      logic [15:0]       total_length;
      logic [15:0]       identification;
      logic [2:0]        flags;
      logic [12:0]       fragment_offset;
      logic [7:0]        ttl;
      IP_PROTOCOL_e      protocol;
      logic [15:0]       csum;
      logic [31:0]       src_ip;
      logic [31:0]       dst_ip;
      logic [44*8-1:0]   rsvd;
    } ipv4_t;
    //----------------------------------------------------------------------------------------


    //----------------------------------------------------------------------------------------
    // ipv6 hdr
    typedef struct   packed { 
      logic [3:0]        version;
      logic [5:0]        dscp;
      logic [1:0]        ecn;
      logic [19:0]       flow_label;
      logic [15:0]       payload_len;
      IP_PROTOCOL_e      next_header;
      logic [7:0]        hoplimit;
      logic [127:0]      src_ip;
      logic [127:0]      dst_ip;
      logic [24*8-1:0]   rsvd;
    } ipv6_t;
    //----------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------------
    // ipv6 extension hdr
    typedef struct packed {
	IP_PROTOCOL_e    next_header;
        logic [7:0]      length;
        logic [47:0]     other;     // remainder of 64-bit extension header
        logic [56*8-1:0] rsvd;
    } ipv6_ext_hdr_t;
    //----------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------------
    // tcp hdr
    // tcp flags
    typedef struct packed {
	logic              tcp_ns;	// ECN nonce concealment protection (bit 8)
	logic              tcp_cwr;	// Congestion window reduced flag
	logic              tcp_ece;	// ECN-Echo.If tcp_syn=1 TCP peer is ECN else
                                        // indicates n/w congestion to tcp sender 
	logic              tcp_urg;	// Indicates Urgent pointer bit is significant
	logic              tcp_ack;	// Indicates Acknowledgment field is significant
	logic              tcp_psh;	// Push function.Asks to push buffered data to 
                                        // receiving application
	logic              tcp_rst;	// Reset the connection
	logic              tcp_syn;	// Synchronize sequence number
	logic              tcp_fin;	// Indicates no more data from sender (bit0)
    } TCP_FLAG_s; 
 
    // TCP hdr:
    typedef struct   packed { 
      logic [15:0]       src_port;
      logic [15:0]       dst_port;
      logic [31:0]       seq;
      logic [31:0]       ack;
      logic [3:0]        ihl;
      logic [2:0]        tcp_rsvd;
      TCP_FLAG_s         flags;
      logic [15:0]       window;
      logic [15:0]       csum;
      logic [15:0]       urgent;
      logic [44*8-1:0]   rsvd;
    } tcp_t;
    //----------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------------
    // udp hdr
    typedef struct packed {
	logic [15:0]     sport;
	UDP_PORT_e       dport;
	logic [15:0]     length;
	logic [15:0]     csum;
	logic [56*8-1:0] rsvd;
    } udp_t;    
    //----------------------------------------------------------------------------------------	

  
    //----------------------------------------------------------------------------------------
    // ipv4 hdr
    typedef struct  packed { 
      logic [3:0]        version;
      logic [3:0]        ihl;
      logic [5:0]        dscp;
      logic [1:0]        ecn;
      logic [15:0]       total_length;
      logic [15:0]       identification;
      logic [2:0]        flags;
      logic [12:0]       fragment_offset;
      logic [7:0]        ttl;
      IP_PROTOCOL_e      protocol;
      logic [15:0]       csum;
      logic [31:0]       src_ip;
      logic [31:0]       dst_ip;
    } ipv4_hdr_t;
    //----------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------------
    // ipv6 hdr
    typedef struct   packed { 
      logic [3:0]        version;
      logic [5:0]        dscp;
      logic [1:0]        ecn;
      logic [19:0]       flow_label;
      logic [15:0]       payload_len;
      IP_PROTOCOL_e      next_header;
      logic [7:0]        hoplimit;
      logic [127:0]      src_ip;
      logic [127:0]      dst_ip;      
    } ipv6_hdr_t;
    //----------------------------------------------------------------------------------------

    // tcp hdr:
    typedef struct   packed { 
      logic [15:0]       src_port;
      logic [15:0]       dst_port;
      logic [31:0]       seq;
      logic [31:0]       ack;
      logic [3:0]        ihl;
      logic [2:0]        tcp_rsvd;
      TCP_FLAG_s         flags;
      logic [15:0]       window;
      logic [15:0]       csum;
      logic [15:0]       urgent;
    } tcp_hdr_t;
    //----------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------------
    // udp hdr
    typedef struct packed {
	logic [15:0]     sport;
	logic [15:0]     dport;
	logic [15:0]     length;
	logic [15:0]     csum;
    } udp_hdr_t;    
    //----------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------------
    // ptp hdr
    typedef struct packed {
	logic [3:0]     transportSpecific;
	logic [3:0]     messageType;
	logic [3:0]     reserved_0;
	logic [3:0]     versionPTP;
	logic [15:0]    messageLength;
	logic [7:0]     domainNumber;
	logic [7:0]     reserved_1;
	logic [15:0]    flagField;
	logic [63:0]    correctionField;
	logic [31:0]    reserved_2;
	logic [79:0]    sourcePortIdentity;
	logic [15:0]    sequenceId;
	logic [7:0]     controlField;
	logic [7:0]     logMessageInterval;
    } ptp_hdr_t;    

    //----------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------------
    // macsec sectag
    typedef struct packed {
	ETYPE_e          etype;
        logic 	   tci_v;
        logic 	   tci_es;
        logic 	   tci_sc;
        logic 	   tci_scb;
        logic 	   tci_sh;
        logic 	   tci_e;
        logic [1:0] an;
        logic [7:0]  sl;
        logic [31:0] pn;
        logic [63:0] sci;
    } macsec_sectag_t; 
    //----------------------------------------------------------------------------------------
    // Each header structs below equates to 128B.

	typedef struct packed {
	eth_hdr_t          eth;  // 14B
	vlan_hdr_t         vlan; // 4B
	ipv4_hdr_t         ipv4; // 20B
	logic [26*8-1:0]   rsvd;
    logic [64*8-1:0]   rsvd_64B;
    } dot1q_ipv4_t;   

	typedef struct packed {
	eth_hdr_t          eth;  // 14B
	vlan_hdr_t         vlan; // 4B
	ipv4_hdr_t         ipv4; // 20B
    udp_hdr_t          udp;  // 8B
	logic [18*8-1:0]   rsvd;
    logic [64*8-1:0]   rsvd_64B;
    } dot1q_ipv4_udp_t; 

	typedef struct packed {
	eth_hdr_t          eth;  // 14B
	vlan_hdr_t         vlan; // 4B
	ipv4_hdr_t         ipv4; // 20B
    udp_hdr_t          udp;  // 8B
    ptp_hdr_t          ptp;  // 34B
	logic [48*8-1:0]   rsvd;
    } dot1q_ipv4_udp_ptp_t; 

	typedef struct packed {
	eth_hdr_t          eth;  // 14B
	vlan_hdr_t         vlan; // 4B
	ipv4_hdr_t         ipv4; // 20B
    tcp_hdr_t          tcp;  // 20B
	logic [6*8-1:0]    rsvd;
    logic [64*8-1:0]   rsvd_64B;
    } dot1q_ipv4_tcp_t; 

	typedef struct packed {
	eth_hdr_t          eth;  // 14B
	vlan_hdr_t         vlan; // 4B
	ipv6_hdr_t         ipv6; // 40B
	logic [6*8-1:0]    rsvd;
    logic [64*8-1:0]   rsvd_64B;
    } dot1q_ipv6_t;   

	typedef struct packed {
	eth_hdr_t          eth;  // 14B
	vlan_hdr_t         vlan; // 4B
	ipv6_hdr_t         ipv6; // 40B
    udp_hdr_t          udp;  // 8B
	logic [62*8-1:0]   rsvd;
    } dot1q_ipv6_udp_t;   

	typedef struct packed {
	eth_hdr_t          eth;  // 14B
	vlan_hdr_t         vlan; // 4B
	ipv6_hdr_t         ipv6; // 40B
    udp_hdr_t          udp;  // 8B
    ptp_hdr_t          ptp;  // 34B
	logic [28*8-1:0]   rsvd;
    } dot1q_ipv6_udp_ptp_t;   

	typedef struct packed {
	eth_hdr_t          eth;  // 14B
	vlan_hdr_t         vlan; // 4B
	ipv6_hdr_t         ipv6; // 40B
    tcp_hdr_t          tcp;  // 20B
	logic [50*8-1:0]   rsvd;
    } dot1q_ipv6_tcp_t;   

    //----------------------------------------------------------------------------------------
    // dot2q
    typedef struct packed {
	eth_hdr_t          eth;    // 14B
	vlan_hdr_t         vlan;   // 4B
	vlan_hdr_t         vlan_1; // 4B
	logic [42*8-1:0]   rsvd;
    logic [64*8-1:0]   rsvd_64B;
    } dot2q_t;

    typedef struct packed {
	eth_hdr_t          eth;    // 14B
	vlan_hdr_t         vlan;   // 4B
	vlan_hdr_t         vlan_1; // 4B
    ptp_hdr_t          ptp;    // 34B
	logic [8*8-1:0]    rsvd;
    logic [64*8-1:0]   rsvd_64B;
    } dot2q_ptp_t;
    
	typedef struct packed {
	eth_hdr_t          eth;    // 14B
	vlan_hdr_t         vlan;   // 4B
	vlan_hdr_t         vlan_1; // 4B
	ipv4_hdr_t         ipv4;   // 20B
    udp_hdr_t          udp;    // 8B
	logic [14*8-1:0]   rsvd;
    logic [64*8-1:0]   rsvd_64B;
    } dot2q_ipv4_udp_t;   

	typedef struct packed {
	eth_hdr_t          eth;    // 14B
	vlan_hdr_t         vlan;   // 4B
	vlan_hdr_t         vlan_1; // 4B
	ipv4_hdr_t         ipv4;   // 20B
    udp_hdr_t          udp;    // 8B
    ptp_hdr_t          ptp;    // 34B
	logic [44*8-1:0]   rsvd;
    } dot2q_ipv4_udp_ptp_t;   

	typedef struct packed {
	eth_hdr_t          eth;    // 14B
	vlan_hdr_t         vlan;   // 4B
	vlan_hdr_t         vlan_1; // 4B
	ipv4_hdr_t         ipv4;   // 20B
    tcp_hdr_t          tcp;    // 20B
	logic [2*8-1:0]    rsvd;
    logic [64*8-1:0]   rsvd_64B;
    } dot2q_ipv4_tcp_t;   

	typedef struct packed {
	eth_hdr_t          eth;    // 14B
	vlan_hdr_t         vlan;   // 4B
	vlan_hdr_t         vlan_1; // 4B
	ipv6_hdr_t         ipv6;   // 40B
    udp_hdr_t          udp;    // 8B
	logic [58*8-1:0]   rsvd;
    } dot2q_ipv6_udp_t;   

	typedef struct packed {
	eth_hdr_t          eth;    // 14B
	vlan_hdr_t         vlan;   // 4B
	vlan_hdr_t         vlan_1; // 4B
	ipv6_hdr_t         ipv6;   // 40B
    udp_hdr_t          udp;    // 8B
    ptp_hdr_t          ptp;    // 34B
	logic [24*8-1:0]   rsvd;
    } dot2q_ipv6_udp_ptp_t;  

	typedef struct packed {
	eth_hdr_t          eth;    // 14B
	vlan_hdr_t         vlan;   // 4B
	vlan_hdr_t         vlan_1; // 4B
	ipv6_hdr_t         ipv6;   // 40B
    tcp_hdr_t          tcp;    // 20B
	logic [46*8-1:0]   rsvd;
    } dot2q_ipv6_tcp_t; 
	
    //----------------------------------------------------------------------------------------
    // dot1q_ptp
	typedef struct packed {
	eth_hdr_t          eth;    // 14B
	vlan_hdr_t         vlan;   // 4B
    ptp_hdr_t          ptp;    // 34B
	logic [12*8-1:0]   rsvd;
    logic [64*8-1:0]   rsvd_64B;
    } dot1q_ptp_t; 

    //----------------------------------------------------------------------------------------
    // eth_ptp
    typedef struct packed {
	eth_hdr_t          eth;  // 14B
	ptp_hdr_t          ptp;  // 34B
	logic [16*8-1:0]   rsvd;
    logic [64*8-1:0]   rsvd_64B;
    }eth_ptp_t;

    //----------------------------------------------------------------------------------------
    // eth_ipv4_udp
    typedef struct packed {
	eth_hdr_t          eth;  // 14B
	ipv4_hdr_t         ipv4; // 20B
	udp_hdr_t          udp;  // 8B
	logic [22*8-1:0]   rsvd;
    logic [64*8-1:0]   rsvd_64B;
    }eth_ipv4_udp_t;

    //----------------------------------------------------------------------------------------
    // eth_ipv4_udp_ptp
    typedef struct packed {
	eth_hdr_t          eth;  // 14B
	ipv4_hdr_t         ipv4; // 20B
	udp_hdr_t          udp;  // 8B
	ptp_hdr_t          ptp;  // 34B
	logic [52*8-1:0]   rsvd;
    }eth_ipv4_udp_ptp_t;

    //----------------------------------------------------------------------------------------
    // eth_ipv4_tcp
    typedef struct packed {
	eth_hdr_t          eth;  // 14B
	ipv4_hdr_t         ipv4; // 20B
	tcp_hdr_t          tcp;  // 20B
	logic [10*8-1:0]   rsvd;
    logic [64*8-1:0]   rsvd_64B;
    }eth_ipv4_tcp_t;

    //----------------------------------------------------------------------------------------
    // eth_ipv6_udp
    typedef struct packed {
	eth_hdr_t          eth;  // 14B
	ipv6_hdr_t         ipv6; // 40B
	udp_hdr_t          udp;  // 8B
	logic [2*8-1:0]    rsvd;
    logic [64*8-1:0]   rsvd_64B;
    }eth_ipv6_udp_t;

    //----------------------------------------------------------------------------------------
    // eth_ipv6_udp_ptp
    typedef struct packed {
	eth_hdr_t          eth;  // 14B
	ipv6_hdr_t         ipv6; // 40B
	udp_hdr_t          udp;  // 8B
    ptp_hdr_t          ptp;  // 34B
	logic [32*8-1:0]   rsvd;
    }eth_ipv6_udp_ptp_t;

    //----------------------------------------------------------------------------------------
    // eth_ipv6_tcp
    typedef struct packed {
	eth_hdr_t          eth;  // 14B
	ipv6_hdr_t         ipv6; // 40B
	tcp_hdr_t          tcp;  // 20B
	logic [54*8-1:0]   rsvd;
    }eth_ipv6_tcp_t;

endpackage // packet_switch_pkg