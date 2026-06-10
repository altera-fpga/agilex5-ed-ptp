// ######################################################################## 
// Copyright (C) 2025 Altera Corporation.
// SPDX-License-Identifier: MIT
// ######################################################################## 
// -------------------------------------------------------------------------- #

import sm_ptp_pkg::*;

module hssi_ss_top #(
  parameter                  TILES       = "F",
  parameter                  NO_OF_BYTES = 8,
  parameter                  EMPTY_BITS = 3, //3 for 10G & 25G
  parameter                  PKT_SEG_PARITY_WIDTH = 1, 
  parameter                  TX_TUSER_CLIENT_WIDTH = 2,
  parameter                  RX_TUSER_CLIENT_WIDTH = 7,
  parameter                  RX_TUSER_STATS_WIDTH = 5,
  parameter                  RX_TUSER_EXTENDED = 32,
  
  
  parameter                  TX_EGRESS = 128, 
  parameter                  RX_EGRESS = 96, 
  parameter                  TOD_DATA = 96,
  parameter                  DEBUG_ENABLE=1,
  parameter                  PTP_FP_WIDTH=32
  )

(
  //input  wire                                i_refclk2pll_p,
  input  wire                                i_clk_sys,
  input  wire                                i_pll_lock,
  input  wire                                i_reconfig_clk,
  input wire  	                              i_clk_ref_p,
               
  input  wire                                i_rx_serial_data,
  input  wire                                i_rx_serial_data_n,
  output wire                                o_tx_serial_data,
  output wire                                o_tx_serial_data_n,
               
  input  wire                                i_rst_n,
  input  wire                                i_tx_rst_n,
  input  wire                                i_rx_rst_n,
               
  output wire                                rst_ack_n,
  output wire                                tx_rst_ack_n,
  output wire                                rx_rst_ack_n,
               
  input  wire                                i_reconfig_reset, 
  
  input  wire                                eth_user_tx_rst_n, 
  input  wire                                eth_user_rx_rst_n, 
  
  output wire                                o_clk_pll_161m,
               
  output wire                                o_cdr_lock       ,
  output wire                                o_tx_pll_locked  ,
  output wire                                o_tx_lanes_stable,
  output wire                                o_rx_pcs_ready   ,
  output wire                                o_clk_rec_div64  ,
                              
  output wire                                o_rx_block_lock          ,
  //output wire                                o_rx_am_lock             ,
  output wire                                o_local_fault_status     ,
  output wire                                o_remote_fault_status    ,
  input wire                                 i_stats_snapshot         ,  //In ED driving it as "0"
  output wire                                o_rx_hi_ber              ,
  output wire                                o_rx_pcs_fully_aligned  ,

  input  logic                              i_clk_tx_tod,
  input  logic                              i_clk_rx_tod,
  input  logic                              i_clk_ptp_sample,
 
  /////////// TX ports ////////////////////                                                                                  
    //AXI Stream Tx, from User interface                       
    //SINGLE PACKET    
	
    output                                   pp_app_ss_st_tx_tready,
    input                                    app_pp_ss_st_tx_tvalid,
    input       [TDATA_WIDTH-1:0]            app_pp_ss_st_tx_tdata,
    input                                    app_pp_ss_st_tx_tlast,
    input       [NO_OF_BYTES-1:0]            app_pp_ss_st_tx_tkeep,
    input       [TX_TUSER_CLIENT_WIDTH-1:0]  app_pp_ss_st_tx_client,
    input       [(1*94)-1:0]                 app_pp_ss_st_tx_ptp,  
    input       [(1*328)-1:0]                app_pp_ss_st_tx_ptp_extended,
	input       [PKT_SEG_PARITY_WIDTH-1:0]    app_pp_ss_st_tx_seg_parity,
 
  /////////// TX Egress ///////////////
   output                                    axi_st_txegrts_tvalid_o,
   output [TX_EGRESS-1:0]                    axi_st_txegrts_tdata_o,
  
  /////////// RX ports ////////////////////                                                                                  
    //AXI Stream Rx, from SS interface                       
    //SINGLE PACKET      
	
   output                                     ss_pp_app_rx_tvalid,
   output  [TDATA_WIDTH-1:0]                  ss_pp_app_rx_tdata,
   output  [(TDATA_WIDTH/8)-1:0]              ss_pp_app_rx_tkeep,
   output                                     ss_pp_app_rx_tlast,
   output [RX_TUSER_CLIENT_WIDTH-1:0]         ss_pp_app_rx_tuser_client,
   output [RX_TUSER_STATS_WIDTH-1:0]          ss_pp_app_rx_tuser_sts,
   output [RX_TUSER_EXTENDED-1:0]             ss_pp_app_rx_tuser_sts_extended,
   output [PKT_SEG_PARITY_WIDTH-1:0]          ss_pp_app_st_rx_tuser_pkt_seg_parity,
 
   /////////// RX Ingress /////////////// 
   output                                     axi_st_rxingrts_tvalid_o,
   output [RX_EGRESS-1:0]                     axi_st_rxingrts_tdata_o,
  
  /////////// TX TOD ///////////////   
   input                                      axi_st_txtod_tvalid_i,
   input [TOD_DATA-1:0]                       axi_st_txtod_tdata_i ,
  
  /////////// RX TOD ///////////////   
   input                                      axi_st_rxtod_tvalid,
   input [TOD_DATA-1:0]                       axi_st_rxtod_tdata ,
   
   output                                     o_clk_tx_div_66 ,
   output                                     o_clk_rec_div_66 ,
   
   input                                      i_tx_pause ,
   output                                     o_rx_pause ,
   
   input [7:0]                                i_tx_pfc ,
   output[7:0]                                o_rx_pfc ,
   
   
   
   input [18-1:0]                           i_reconfig_eth_addr           ,
   input [4-1:0]                            i_reconfig_eth_byteenable     ,
   output                                   o_reconfig_eth_readdata_valid ,
   input                                    i_reconfig_eth_read           ,
   input                                    i_reconfig_eth_write          ,
   output[32-1:0]                           o_reconfig_eth_readdata       ,
   input [32-1:0]                           i_reconfig_eth_writedata      ,
   output                                   o_reconfig_eth_waitrequest ,  
   
  input                                     i_src_rs_grant,
  input                                     i_pma_cu_clk,
  output                                    o_src_rs_req,
  output reg  [63:0]                        hssi_in_counter,hssi_out_counter

);

    wire i_clk_tx;
    wire i_clk_rx;
    wire o_clk_pll;
	//wire  i_clk_sys;
	wire  o_pll_lock;
	  
   wire [TDATA_WIDTH-1:0]              o_tx_avst_data          ;  
   wire                                o_tx_avst_valid         ;
   wire                                o_tx_avst_startofpacket ;
   wire                                o_tx_avst_endofpacket   ;
   wire [EMPTY_BITS-1:0]               o_tx_avst_empty         ;
   wire                                o_tx_avst_error         ;
   wire                                o_tx_avst_skip_crc      ;
   wire [64-1:0]                       o_tx_avst_preamble      ;
   wire                                i_tx_avst_ready         ;
   
   
   wire  [TDATA_WIDTH-1:0]              i_rx_avst_data          ;   
   wire                                 i_rx_avst_valid         ;
   wire                                 i_rx_avst_startofpacket ;
   wire                                 i_rx_avst_endofpacket   ;
   wire  [EMPTY_BITS-1:0]               i_rx_avst_empty         ;
   wire  [5:0]                          i_rx_avst_error         ;
   wire  [39:0]                         i_rxstatus_avst_data    ;
   wire                                 i_rxstatus_avst_valid   ;
  // wire  [64-1:0]                       i_rx_avst_preamble    ;

	   logic                      ptp_ts_req;
	   logic                      ptp_ts_valid; 
	   logic                      ptp_ins_ets;
		logic [PTP_FP_WIDTH-1:0]   tx_ptp_fp,ptp_ets_fp;
		logic                      ptp_ins_cf;
		logic [RX_EGRESS -1:0]     ptp_tx_its;
		logic [7-1:0]              ptp_asym_p2p_idx;
		logic                      ptp_asym_sign;
		logic                      ptp_asym;
		logic                      ptp_p2p;
		logic                      ptp_ins_update_eb;
		logic                      ptp_ins_zero_csum;
		logic [16 -1:0]            ptp_ins_csum_offset;
      logic [16 -1:0]            ptp_ins_cf_offset  ;
		logic [16 -1:0]            ptp_ins_ts_offset  ;
		logic [96-1:0]             ptp_rx_its;
	   logic [RX_EGRESS-1:0]      ptp_ets;
	   logic                      ptp_ets_valid;
		logic o_tx_ptp_offset_data_valid,o_rx_ptp_offset_data_valid,o_tx_ptp_ready,o_rx_ptp_ready;
 
 hssi_axist_to_avst_bridge_wrapper #(
     
      .TDATA_WIDTH                   (TDATA_WIDTH),
      .DATA_WIDTH                    (TDATA_WIDTH),
      .TILES                         (TILES),
      .PREAMBLE_PASS_TH_EN           (0),
      .DR_ENABLE                     (0),
      .PKT_SEG_PARITY_WIDTH          (PKT_SEG_PARITY_WIDTH),
      .TX_TUSER_CLIENT_WIDTH         (TX_TUSER_CLIENT_WIDTH),
      .RX_TUSER_CLIENT_WIDTH         (RX_TUSER_CLIENT_WIDTH),
      .RX_TUSER_STATS_WIDTH          (RX_TUSER_STATS_WIDTH)
      //.RX_TUSER_EXTENDED             (RX_TUSER_EXTENDED)
 
    ) U_st_bridge_instance (
      .i_tx_clk_p0                    (o_clk_pll), 
      .i_tx_clk_p1                    (o_clk_pll), 
      .i_tx_clk_p2                    (o_clk_pll), 
      .i_tx_clk_p3                    (o_clk_pll), 
      .i_rx_clk_p0                    (o_clk_pll),
      .i_rx_clk_p1                    (o_clk_pll),
      .i_rx_clk_p2                    (o_clk_pll),
      .i_rx_clk_p3                    (o_clk_pll),
      .i_tx_rst_n_p0                  (eth_user_tx_rst_n),
      .i_tx_rst_n_p1                  (eth_user_tx_rst_n),
      .i_tx_rst_n_p2                  (eth_user_tx_rst_n),
      .i_tx_rst_n_p3                  (eth_user_tx_rst_n),
      .i_rx_rst_n_p0                  (eth_user_rx_rst_n),
      .i_rx_rst_n_p1                  (eth_user_rx_rst_n),
      .i_rx_rst_n_p2                  (eth_user_rx_rst_n),
      .i_rx_rst_n_p3                  (eth_user_rx_rst_n),
      .i_profile_sel_reg              ('d0),
      .o_port_active_mask_reg         (),
      .o_data_width                   (),
      .o_speed_sel                    (),
   
   //AXI Stream Tx, from User interface
      .o_axi_st_tx_tready             (pp_app_ss_st_tx_tready),
      .i_axi_st_tx_tvalid             (app_pp_ss_st_tx_tvalid),
      .i_axi_st_tx_tdata              (app_pp_ss_st_tx_tdata),
      .i_axi_st_tx_tlast              (app_pp_ss_st_tx_tlast),
      .i_axi_st_tx_tkeep              (app_pp_ss_st_tx_tkeep),
      .i_axi_st_tx_tuser_client       (app_pp_ss_st_tx_client),
      .i_axi_st_tx_tuser_ptp          (app_pp_ss_st_tx_ptp),
      .i_axi_st_tx_tuser_ptp_extended (app_pp_ss_st_tx_ptp_extended),  
	  .i_axi_st_tx_pkt_seg_parity      (app_pp_ss_st_tx_seg_parity),
  //-------------------------------------------------------------------------
  
    //  .i_axi_st_tx_tlast_segment      (app_ss_st_tx_mux_tuser_last_segment),      
     // .i_axi_st_tx_tkeep_segment      (app_ss_st_tx_mux_tkeep_segment),      
        // Passed same value of tkeep to both tkeep & tkeep_segment to bridge. SEG is handled by bridge
      //     .i_axi_st_tx_tkeep_segment      (app_ss_tx_mux_tkeep[7:0]),       

  //-------------------------------------------------
  
      .i_axi_st_tx_tid                ('0),//app_ss_st_tx_mux_tid
      //AXI Stream Rx, to User interface
      .o_axi_st_rx_tvalid             (ss_pp_app_rx_tvalid),
      .o_axi_st_rx_tdata              (ss_pp_app_rx_tdata),
      .o_axi_st_rx_tlast              (ss_pp_app_rx_tlast),
      .o_axi_st_rx_tkeep              (ss_pp_app_rx_tkeep),
      .o_axi_st_rx_tuser_client       (ss_pp_app_rx_tuser_client),
      .o_axi_st_rx_tuser_sts          (ss_pp_app_rx_tuser_sts),
      .o_axi_st_rx_tuser_sts_extended (ss_pp_app_rx_tuser_sts_extended),
     
	   .o_axi_st_rx_ingrts0_tvalid     (axi_st_rxingrts_tvalid_o),
      //.o_axi_st_rx_ingrts1_tvalid     (ss_pp_app_st_rxingrts1_tvalid),
      .o_axi_st_rx_ingrts0_tdata      (axi_st_rxingrts_tdata_o),
     // .o_axi_st_rx_ingrts1_tdata      (ss_pp_app_st_rxingrts1_tdata),
     //------------------------------------------- 
      .o_axi_st_rx_tlast_segment      (),
      .o_axi_st_rx_tkeep_segment      (),//ss_app_st_rx_tkeep_segment,
      .o_axi_st_rx_pkt_seg_parity     (ss_pp_app_st_rx_tuser_pkt_seg_parity),
      .o_axi_st_rx_tid                (),
     //----------------------------------------------  
      //Uncomment after DINKER adds
		  //.o_axi_st_rx_ingrts1_tvalid     (ss_app_st_rxingrts1_tvalid),
      //.o_axi_st_rx_ingrts1_tdata      (ss_app_st_rxingrts1_tdata),
      //hac //MULTI PACKET COMPATIBLE SIGNALS		
      // o_axi_st_rx_tlast_segment(),
      // o_axi_st_rx_tkeep_segment()
    
    //hac MULTI PACKET COMPATIBLE SIGNALS		
	  	//i_axi_st_tx_tlast_segment (),
    	//i_axi_st_tx_tkeep_segment(),
    	//i_axi_st_tx_tuser_sts(),

     // .o_tx_fifo_eccstatus		     (tx_fifo_eccstatus),
    //  .o_axi_st_tx_parity_error    (axi_st_tx_parity_error),
      //AVST SOP aligned interface signals
    //  .o_tx_avst_data                   (o_tx_avst_data         ),         
      .o_tx_avst_data                   (o_tx_avst_data         ),         
      .o_tx_avst_valid                  (o_tx_avst_valid         ),
      .o_tx_avst_startofpacket          (o_tx_avst_startofpacket ),
      .o_tx_avst_endofpacket            (o_tx_avst_endofpacket   ),
      .o_tx_avst_empty                  (o_tx_avst_empty         ),
      .o_tx_avst_error                  (o_tx_avst_error         ),
      .o_tx_avst_skip_crc               (o_tx_avst_skip_crc      ),
      .o_tx_avst_preamble               (o_tx_avst_preamble      ),
      .i_tx_avst_ready                  (i_tx_avst_ready        ),
	  
      .i_rx_avst_data                   (i_rx_avst_data         ),
      .i_rx_avst_valid                  (i_rx_avst_valid        ),
      .i_rx_avst_startofpacket          (i_rx_avst_startofpacket),
      .i_rx_avst_endofpacket            (i_rx_avst_endofpacket  ),
      .i_rx_avst_empty                  (i_rx_avst_empty        ),
      .i_rx_avst_error                  (i_rx_avst_error        ),
      .i_rx_avst_preamble               ('d0     ),
      .i_rxstatus_avst_data             (i_rxstatus_avst_data   ),
      .i_rxstatus_avst_valid            (i_rxstatus_avst_valid  ),
	  
    //tx_ptp avalon side
    .o_av_st_tx_ptp_ts_valid        (ptp_ts_valid), 
    .o_av_st_tx_ptp_ts_req          (ptp_ts_req),
    .o_av_st_tx_ptp_ins_ets         (ptp_ins_ets),
    .o_av_st_tx_ptp_fp              (tx_ptp_fp),
    .o_av_st_tx_ptp_ins_cf          (ptp_ins_cf),
    .o_av_st_tx_ptp_tx_its          (ptp_tx_its),
    .o_av_st_tx_ptp_asym_p2p_idx    (ptp_asym_p2p_idx),
    .o_av_st_tx_ptp_asym_sign       (ptp_asym_sign),
    .o_av_st_tx_ptp_asym            (ptp_asym),
    .o_av_st_tx_ptp_p2p             (ptp_p2p),
    //
    .o_av_st_tx_ptp_ts_format       (),//o_av_st_tx_ptp_ts_format), 
    .o_av_st_tx_ptp_update_eb       (ptp_ins_update_eb), 
    .o_av_st_tx_ptp_zero_csum       (o_av_st_tx_ptp_zero_csum), 
    .o_av_st_tx_ptp_eb_offset       (),//o_av_st_tx_ptp_eb_offset), 
    .o_av_st_tx_ptp_csum_offset     (ptp_ins_csum_offset), 
    .o_av_st_tx_ptp_cf_offset       (ptp_ins_cf_offset), 
    .o_av_st_tx_ptp_ts_offset       (ptp_ins_ts_offset), 
    .i_rx_avst_ptp_rx_its           (ptp_rx_its)   //input
   ////
     //Not Required below signals
    //Avalon Stream Tx, to EHIP/MAC interface
      //.i_av_st_tx_ready               (i_av_st_tx_ready),
      //.o_av_st_tx_valid               (o_av_st_tx_valid),
      //.o_av_st_tx_data                (o_av_st_tx_data),
      //.o_av_st_tx_startofpacket       (o_av_st_tx_startofpacket),
      //.o_av_st_tx_endofpacket         (o_av_st_tx_endofpacket),
      //.o_av_st_tx_empty               (o_av_st_tx_empty),
      //.o_av_st_tx_error               (o_av_st_tx_error),
      //.o_av_st_tx_skip_crc            (o_av_st_tx_skip_crc),
      ////hac //MAC_SEGMENTED COMPATIBLE SIGNALS		
      //.o_av_st_tx_inframe             (o_av_st_tx_inframe),
      //.o_av_st_tx_eop_empty           (o_av_st_tx_eop_empty),
      //.o_av_st_tx_mac_error           (o_av_st_tx_mac_error),
    //output reg  [MAC_STS-1:0]          				o_av_st_txstatus_data
    
    //Avalon Stream Rx, from EHIP/MAC interface
      //.i_av_st_rx_valid               (i_av_st_rx_valid),
      //.i_av_st_rx_data                (i_av_st_rx_data),
      //.i_av_st_rx_startofpacket       (i_av_st_rx_startofpacket),
      //.i_av_st_rx_endofpacket         (i_av_st_rx_endofpacket),
      //.i_av_st_rx_empty               (i_av_st_rx_empty),
      //.i_av_st_rx_error               (i_av_st_rx_error),
      //.i_av_st_rxstatus_data          (i_av_st_rxstatus_data),
      //.i_av_st_rxstatus_valid         (i_av_st_rxstatus_valid),
      
      ////hac	//MAC_SEGMENTED COMPATIBLE SIGNALS		
      //.i_av_st_rx_inframe             (i_av_st_rx_inframe),
      //.i_av_st_rx_eop_empty           (i_av_st_rx_eop_empty),
      //.i_av_st_rx_mac_error           (i_av_st_rx_mac_error),
      //.i_av_st_rx_fcs_error           (i_av_st_rx_fcs_error),
      //.i_av_st_rx_mac_status          (i_av_st_rx_mac_status),
    );

//---------------------------------------------------------------
//Added for shoreline Sequencer
//---------------------------------------------------------------
// gts_reset_sequencer reset_sequencer (
		// .o_src_rs_grant    (i_src_rs_grant),    //  output,  width = 2,    o_src_rs_grant.src_rs_grant
		// .i_src_rs_priority (1'b0),              //   input,  width = 2, i_src_rs_priority.src_rs_priority
		// .i_src_rs_req      (o_src_rs_req),      //   input,  width = 2,      i_src_rs_req.src_rs_req
		// .o_pma_cu_clk      (i_pma_cu_clk)       //  output,  width = 2,      o_pma_cu_clk.clk
	// );

//gts_systempll system_pll (
//		.o_pll_lock     (o_pll_lock),     //  output,  width = 1,   o_pll_lock.o_pll_lock
//		.o_syspll_c0    (i_clk_sys),    //  output,  width = 1,  o_syspll_c0.clk
//		.i_refclk       (i_refclk2pll_p),       //   input,  width = 1,  refclk_xcvr.clk
//		.i_refclk_ready (1'b1)  //   input,  width = 1, i_refclk_rdy.data
//	);
 assign  o_clk_pll_161m = o_clk_pll;

	ethernet_hip u0 (
		.i_clk_tx                      (o_clk_pll),                      //   input,   width = 1,           i_tx_clk.clk
		.i_clk_rx                      (o_clk_pll),                      //   input,   width = 1,           i_rx_clk.clk
		.o_clk_pll                     (o_clk_pll),                     //  output,   width = 1,          o_clk_pll.clk
		.i_reconfig_clk                (i_reconfig_clk),                //   input,   width = 1,     i_reconfig_clk.clk
		
		.i_reconfig_reset              (i_reconfig_reset),              //   input,   width = 1,   i_reconfig_reset.reset
		.o_sys_pll_locked              (o_sys_pll_locked),              //  output,   width = 1,   o_sys_pll_locked.o_sys_pll_locked
		.i_syspll_lock                 (i_pll_lock),                 //   input,   width = 1,      i_syspll_lock.i_syspll_lock
		.i_pma_cu_clk                  (i_pma_cu_clk),                  //   input,   width = 1,       i_pma_cu_clk.clk
		
		.o_tx_serial_data              (o_tx_serial_data      ),              //  output,   width = 1,             serial.o_tx_serial_data
		.i_rx_serial_data              (i_rx_serial_data      ),              //   input,   width = 1,                   .i_rx_serial_data
		.o_tx_serial_data_n            (o_tx_serial_data_n    ),            //  output,   width = 1,                   .o_tx_serial_data_n
		.i_rx_serial_data_n            (i_rx_serial_data_n    ),            //   input,   width = 1,                   .i_rx_serial_data_n
		
		.i_clk_ref_p                   (i_clk_ref_p),                   //   input,   width = 1,        i_clk_ref_p.clk
		.i_clk_sys                     (i_clk_sys),                     //   input,   width = 1,          i_clk_sys.clk
		
		.o_src_rs_req                  (o_src_rs_req),                  //  output,   width = 1,         src_rs_req.src_rs_req
		.i_src_rs_grant                (i_src_rs_grant),                //   input,   width = 1,       src_rs_grant.src_rs_grant
		
		.i_reconfig_eth_addr           (i_reconfig_eth_addr          ),           //   input,  width = 18, reconfig_eth_slave.address
		.i_reconfig_eth_byteenable     (i_reconfig_eth_byteenable     ),     //   input,   width = 4,                   .byteenable
		.o_reconfig_eth_readdata_valid (o_reconfig_eth_readdata_valid ), //  output,   width = 1,                   .readdatavalid
		.i_reconfig_eth_read           (i_reconfig_eth_read          ),           //   input,   width = 1,                   .read
		.i_reconfig_eth_write          (i_reconfig_eth_write          ),          //   input,   width = 1,                   .write
		.o_reconfig_eth_readdata       (o_reconfig_eth_readdata       ),       //  output,  width = 32,                   .readdata
		.i_reconfig_eth_writedata      (i_reconfig_eth_writedata      ),      //   input,  width = 32,                   .writedata
		.o_reconfig_eth_waitrequest    (o_reconfig_eth_waitrequest    ),    //  output,   width = 1,                   .waitrequest
		
		.i_rst_n                       (i_rst_n   ),                       //   input,   width = 1,            i_rst_n.reset_n
		.i_tx_rst_n                    (i_tx_rst_n),                    //   input,   width = 1,         i_tx_rst_n.reset_n
		.i_rx_rst_n                    (i_rx_rst_n),                    //   input,   width = 1,         i_rx_rst_n.reset_n
		.o_rst_ack_n                   (rst_ack_n   ),                   //  output,   width = 1, reset_status_ports.o_rst_ack_n
		.o_tx_rst_ack_n                (tx_rst_ack_n),                //  output,   width = 1,                   .o_tx_rst_ack_n
		.o_rx_rst_ack_n                (rx_rst_ack_n),                //  output,   width = 1,                   .o_rx_rst_ack_n
		.o_cdr_lock                    (o_cdr_lock       ),                    //  output,   width = 1, clock_status_ports.o_cdr_lock
		.o_tx_pll_locked               (o_tx_pll_locked  ),               //  output,   width = 1,                   .o_tx_pll_locked
		.o_tx_lanes_stable             (o_tx_lanes_stable),             //  output,   width = 1,                   .o_tx_lanes_stable
		.o_rx_pcs_ready                (o_rx_pcs_ready   ),                //  output,   width = 1,                   .o_rx_pcs_ready
		.o_clk_tx_div                  (o_clk_tx_div_66),                                //  output,   width = 1,         clk_tx_div.clk
		.o_clk_rec_div64               (o_clk_rec_div64),               //  output,   width = 1,      clk_rec_div64.clk
		.o_clk_rec_div                 (o_clk_rec_div_66),                 //  output,   width = 1,        clk_rec_div.clk
		.o_rx_block_lock               (o_rx_block_lock         ),               //  output,   width = 1,       status_ports.o_rx_block_lock
		//.o_rx_am_lock                  (o_rx_am_lock            ),                  //  output,   width = 1,                   .o_rx_am_lock
		.o_local_fault_status          (o_local_fault_status    ),          //  output,   width = 1,                   .o_local_fault_status
		.o_remote_fault_status         (o_remote_fault_status   ),         //  output,   width = 1,                   .o_remote_fault_status
		.i_stats_snapshot              (i_stats_snapshot        ),              //   input,   width = 1,                   .i_stats_snapshot
		.o_rx_hi_ber                   (o_rx_hi_ber             ),                   //  output,   width = 1,                   .o_rx_hi_ber
		.o_rx_pcs_fully_aligned        (o_rx_pcs_fully_aligned ),        //  output,   width = 1,                   .o_rx_pcs_fully_aligned
		
		
		.i_tx_data                     (o_tx_avst_data),                     //   input,  width = 64,       tx_streaming.data
		.i_tx_valid                    (o_tx_avst_valid),                    //   input,   width = 1,                   .valid
		.i_tx_startofpacket            (o_tx_avst_startofpacket),            //   input,   width = 1,                   .startofpacket
		.i_tx_endofpacket              (o_tx_avst_endofpacket),              //   input,   width = 1,                   .endofpacket
		.i_tx_error                    (o_tx_avst_error),                    //   input,   width = 1,                   .error
		.o_tx_ready                    (i_tx_avst_ready),                    //  output,   width = 1,                   .ready
		.i_tx_empty                    (o_tx_avst_empty),                    //   input,   width = 3,                   .empty
		.i_tx_skip_crc                 (o_tx_avst_skip_crc),                 //   input,   width = 1,           tx_ports.i_tx_skip_crc
				
		.o_rx_data                     (i_rx_avst_data         ),                     //  output,  width = 64,       rx_streaming.data
		.o_rx_valid                    (i_rx_avst_valid        ),                    //  output,   width = 1,                   .valid
		.o_rx_startofpacket            (i_rx_avst_startofpacket),            //  output,   width = 1,                   .startofpacket
		.o_rx_endofpacket              (i_rx_avst_endofpacket  ),              //  output,   width = 1,                   .endofpacket
		.o_rx_error                    (i_rx_avst_error),                    //  output,   width = 6,                   .error
		.o_rx_empty                    (i_rx_avst_empty),                    //  output,   width = 3,                   .empty
		.o_rxstatus_data               (i_rxstatus_avst_data),               //  output,  width = 40,           rx_ports.o_rxstatus_data
		.o_rxstatus_valid              (i_rxstatus_avst_valid),              //  output,   width = 1,                   .o_rxstatus_valid
		
		.i_tx_pfc                      (i_tx_pfc),                      //   input,   width = 8,          pfc_ports.i_tx_pfc
		.o_rx_pfc                      (o_rx_pfc),                      //  output,   width = 8,                   .o_rx_pfc
		.i_tx_pause                    (i_tx_pause),                    //   input,   width = 1,          sfc_ports.i_tx_pause
		.o_rx_pause                    (o_rx_pause),//,                  //  output,   width = 1,                   .o_rx_pause
// Drives internal clock. Use this clock only when PTP and asynchronous modes are enabled. Connect o_clk_pll of chosen intel_eth_gts to this clock
		//.i_clk_pll                     (_connected_to_i_clk_pll_)
		//   input,   width = 1,          i_clk_pll.clk
		
	 .i_clk_tx_tod                            (i_clk_tx_tod                  ),
    .i_clk_rx_tod                            (i_clk_rx_tod                  ),
    .i_clk_ptp_sample                        (i_clk_ptp_sample            ),
    .i_ptp_tx_tod_valid                      (axi_st_txtod_tvalid_i            ),
    .i_ptp_tx_tod                            (axi_st_txtod_tdata_i        ),
    .i_ptp_rx_tod_valid                      (axi_st_rxtod_tvalid       ),
    .i_ptp_rx_tod                            (axi_st_rxtod_tdata                   ),
    .i_ptp_ins_ets                           (ptp_ins_ets                 ),
    .i_ptp_ins_cf                            (ptp_ins_cf                  ),
    .i_ptp_zero_csum                         (ptp_ins_zero_csum           ),
    .i_ptp_update_eb                         (ptp_ins_update_eb           ),
    .i_ptp_p2p                               (ptp_p2p                     ),
    .i_ptp_asym                              (ptp_asym                    ),
    .i_ptp_asym_sign                         (ptp_asym_sign               ),
    .i_ptp_asym_p2p_idx                      (ptp_asym_p2p_idx            ),
    .i_ptp_ts_offset                         (ptp_ins_ts_offset           ),
    .i_ptp_cf_offset                         (ptp_ins_cf_offset           ),
    .i_ptp_csum_offset                       (ptp_ins_csum_offset         ),
    .i_ptp_ts_req                            (ptp_ts_req                  ),
    .i_ptp_tx_its                            (ptp_tx_its                  ),
    .i_ptp_fp                                (tx_ptp_fp                      ),

    .o_ptp_ets_valid                         (ptp_ets_valid               ),
    .o_ptp_ets                               (ptp_ets                     ),
    .o_ptp_ets_fp                            (ptp_ets_fp                  ),
    .o_ptp_rx_its                            (ptp_rx_its                  ),
    .o_tx_ptp_offset_data_valid              (o_tx_ptp_offset_data_valid  ),
    .o_rx_ptp_offset_data_valid              (o_rx_ptp_offset_data_valid  ),
    .o_tx_ptp_ready                          (o_tx_ptp_ready              ),
    .o_rx_ptp_ready                          (o_rx_ptp_ready              )
	);
		
	assign axi_st_txegrts_tvalid_o = ptp_ets_valid;
	assign axi_st_txegrts_tdata_o = {ptp_ets_fp,ptp_ets};
	
		 //`ifndef ALTERA_RESERVED_QIS  
	  
	  generate if(DEBUG_ENABLE==1) begin
	 
	  always@(posedge o_clk_pll or negedge i_tx_rst_n) begin
	  if(!i_tx_rst_n)
	  hssi_in_counter <='d0;
	  else if(o_tx_avst_valid & i_tx_avst_ready & o_tx_avst_endofpacket)
	  hssi_in_counter <= hssi_in_counter + 1'b1;
	  else
	  hssi_in_counter <= hssi_in_counter;
	  end
	  
	  	always@(posedge o_clk_pll or negedge i_rx_rst_n) begin
	  if(!i_rx_rst_n)
	  hssi_out_counter <=0;
	  else if(i_rx_avst_endofpacket & i_rx_avst_valid)
	  hssi_out_counter <= hssi_out_counter +1'b1;
	  else
	  hssi_out_counter <= hssi_out_counter;
	  end
	  
	  end endgenerate
	  
	//  `endif

endmodule
