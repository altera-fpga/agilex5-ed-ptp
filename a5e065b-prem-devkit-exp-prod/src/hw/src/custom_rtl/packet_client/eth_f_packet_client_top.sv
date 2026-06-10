//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

`timescale 1 ps / 1 ps
 
module eth_f_packet_client_top #(
        parameter PKT_CYL                = 0,
        parameter CLIENT_IF_TYPE         = 0,   // 0:Segmented; 1:AvST;
        parameter READY_LATENCY          = 0,
 	    parameter DATA_WIDTH       	     = 64, 
        parameter WORDS                  = 8,
        parameter EMPTY_WIDTH            = 6
     //   parameter PKT_ROM_INIT_FILE      = "eth_f_hw_pkt_gen_rom_init.hex"
    )(
        input   logic                             i_arst_tx,
        input   logic                             i_arst_rx,
        input   logic                             i_clk_tx,
        input   logic                             i_clk_rx,
        input   logic                             i_clk_status,
        input   logic                             i_clk_status_rst,

        //---Avst TX/RX IF---
        input   logic                             i_tx_ready,
        output  logic                             o_tx_valid,
        output  logic                             o_tx_sop,
        output  logic                             o_tx_eop,
        output  logic   [EMPTY_WIDTH-1:0]         o_tx_empty,
        output  logic   [WORDS*64-1:0]            o_tx_data,
        output  logic                             o_tx_error,
        output  logic                             o_tx_skip_crc,
        output  logic   [64-1:0]                  o_tx_preamble,   // for 40/50G;

        input   logic                             i_rx_valid,
        input   logic                             i_rx_sop,
        input   logic                             i_rx_eop,
        input   logic   [EMPTY_WIDTH-1:0]         i_rx_empty,
        input   logic   [WORDS*64-1:0]            i_rx_data,
        input   logic   [64-1:0]                  i_rx_preamble,   // for 40/50G;
        input   logic   [6:0]                     i_rx_error,
        input   logic                             i_rxstatus_valid,
        input   logic   [40-1:0]                  i_rxstatus_data,

        axi4lite_if.slave                         pktcli_csr_if_slv,
        output  logic                             o_cold_rst_csr,
		
        input   logic                             i_sadb_config_done,
        input   logic   [ 3:0]                    i_system_status
);


//---------------------------------------------------------------
logic                      cfg_tx_select_pkt_gen;
logic                      cfg_pkt_gen_tx_en;
logic                      cfg_pkt_gen_cont_mode;

logic                      tx_reset;

//---------------------------------------------------------------
logic [19:0]           cfg_pkt_client_ctrl, cfg_pkt_client_ctrl_sync;
logic [7:0]            stat_tx_sop_cnt, stat_tx_eop_cnt, stat_tx_err_cnt;
logic [7:0]            stat_tx_sop_cnt_d, stat_tx_eop_cnt_d, stat_tx_err_cnt_d;
//logic [7:0]            m0_stat_tx_sop_cnt, m0_stat_tx_eop_cnt, m0_stat_tx_err_cnt;
logic [7:0]            m1_stat_tx_sop_cnt, m1_stat_tx_eop_cnt, m1_stat_tx_err_cnt;
logic [7:0]            stat_tx_sop_cnt_sync, stat_tx_eop_cnt_sync, stat_tx_err_cnt_sync;
logic [7:0]            stat_rx_sop_cnt, stat_rx_eop_cnt, stat_rx_err_cnt;
logic [7:0]            stat_rx_sop_cnt_sync, stat_rx_eop_cnt_sync, stat_rx_err_cnt_sync;
logic                  stat_tx_cnt_clr, stat_rx_cnt_clr, stat_rx_cnt_clr_cdc_cdc, stat_rx_cnt_clr_cdc;
logic [1:0]            stat_rx_cnt_clr_sync, stat_tx_cnt_clr_sync;
logic                  loopback_fifo_wr_full_err, loopback_fifo_rd_empty_err;
logic                  stat_tx_cnt_vld,m0_stat_tx_cnt_vld,m1_stat_tx_cnt_vld, stat_tx_cnt_vld_d;

logic [47:0]               dyn_dmac_addr,dyn_dmac_addr_sync;
logic [47:0]               dyn_smac_addr,dyn_smac_addr_sync;
logic [31:0]               dyn_pkt_num,dyn_pkt_num_sync;
logic [13:0]               dyn_pkt_start_size,dyn_pkt_start_size_sync;
logic [13:0]               dyn_pkt_end_size,dyn_pkt_end_size_sync;

logic  [33:0] checker_status_reg; //logic  [3:0] checker_status_reg;

logic  [33:0] data_err_reg;

logic                    pktgen_srst;


logic [63:0]  rx_byte_cnt   ;
logic [63:0]  tx_byte_cnt   ;
logic [63:0]  tx_num_ticks  ;
logic [63:0]  rx_num_ticks  ;
logic [63:0]  tx_bw_cnt, rx_bw_cnt ;
 
//---------------------------------------------------------------
assign      o_tx_preamble = 64'hFB55_5555_5555_55D5;

assign pktcli_avm_csr_if.response = 'd0;
assign pktcli_avm_csr_if.readdata[63:32]=32'd0;
assign pktcli_avm_csr_if.writeresponsevalid=1'b0;

//---------------------------------------------------------------

avmm_if        pktcli_avm_csr_if();

// axi4lite_to_avmm_bridge
axi4lite2avmm_bridge pktcli_axi2avmm (
    .i_clk                                 ( i_clk_status ),
    .i_rstn                                (!i_clk_status_rst  ),
    .axilite_slv                           ( pktcli_csr_if_slv ),
    .avmm_mst                              ( pktcli_avm_csr_if )
  );

//---------------------------------------------------------------
//-----------------TX MAC Ready Latency -----------------
logic   [10:0]           tx_rdy_latency;
logic   [11:0]           tx_rdy_latency_all;
logic                    tx_rdy;
logic                    tx_ready_seg, tx_ready_avst;
logic                    tx_ready_latency;
logic                    tx_valid, tx_mac_valid;
/*logic                    m0_tx_valid;
logic                    m0_tx_sop;
logic                    m0_tx_eop;
logic   [EMPTY_WIDTH-1:0]m0_tx_empty;
logic   [WORDS*64-1:0]   m0_tx_data;
logic                    m0_tx_error;
logic                    m0_tx_skip_crc;*/
logic                    m1_tx_valid;
logic                    m1_tx_sop;
logic                    m1_tx_eop;
logic   [EMPTY_WIDTH-1:0]m1_tx_empty;
logic   [WORDS*64-1:0]   m1_tx_data;
logic                    m1_tx_error;
logic                    m1_tx_skip_crc;
//logic                    pktgen_srst;
logic                    checker_srst;
logic   [1:0]            dyn_pattern_mode;
logic                    dyn_ipg_sel;
logic   [7:0]            ipg_cycles;
logic   [31:0]            num_words;

assign tx_rdy = i_tx_ready;
always @(posedge i_clk_tx) tx_rdy_latency <= {tx_rdy_latency[8:0], tx_rdy};
assign tx_rdy_latency_all = {tx_rdy_latency, tx_rdy};
assign tx_ready_latency = tx_rdy_latency_all[READY_LATENCY];

//assign m0_tx_ready  = tx_ready_latency; 
assign m1_tx_ready   = tx_ready_latency; 
assign o_tx_valid    = cfg_tx_select_pkt_gen? m1_tx_valid    : 'd0;//: m0_tx_valid;
assign o_tx_sop      = cfg_tx_select_pkt_gen? m1_tx_sop      : 'd0;//: m0_tx_sop;
assign o_tx_eop      = cfg_tx_select_pkt_gen? m1_tx_eop      : 'd0;//: m0_tx_eop;
assign o_tx_empty    = cfg_tx_select_pkt_gen? m1_tx_empty    : 'd0;//: m0_tx_empty;
assign o_tx_data     = cfg_tx_select_pkt_gen? m1_tx_data     : 'd0;//: m0_tx_data;
assign o_tx_error    = cfg_tx_select_pkt_gen? m1_tx_error    : 'd0;//: m0_tx_error;
assign o_tx_skip_crc = cfg_tx_select_pkt_gen? m1_tx_skip_crc : 'd0;//: m0_tx_skip_crc;

assign m1_tx_error = 0;
assign m1_tx_skip_crc = 0;



assign stat_tx_cnt_vld = cfg_tx_select_pkt_gen? m1_stat_tx_cnt_vld:'d0;// m0_stat_tx_cnt_vld;
assign stat_tx_sop_cnt = cfg_tx_select_pkt_gen? m1_stat_tx_sop_cnt:'d0;// m0_stat_tx_sop_cnt;
assign stat_tx_eop_cnt = cfg_tx_select_pkt_gen? m1_stat_tx_eop_cnt:'d0;// m0_stat_tx_eop_cnt;
assign stat_tx_err_cnt = cfg_tx_select_pkt_gen? m1_stat_tx_err_cnt:'d0;// m0_stat_tx_err_cnt;

always @ (posedge i_clk_tx) begin
	stat_tx_sop_cnt_d <= stat_tx_sop_cnt;
	stat_tx_eop_cnt_d <= stat_tx_eop_cnt;
    stat_tx_err_cnt_d <= stat_tx_err_cnt;
	stat_tx_cnt_vld_d <= stat_tx_cnt_vld;
end

  case (WORDS)
   'd1: begin
      assign num_words = 32'h00000001;
	end
   'd2: begin
      assign num_words = 32'h00000002;
	end
   'd4: begin
      assign num_words = 32'h00000004;
    end
    default: begin
      assign num_words = 32'h00000001;
	end
	endcase
	

//------------------------------------------------------
//
//------------------------------------------------------

eth_f_pkt_gen_dyn_25G #(
  .WORDS               ( WORDS ),
  //.WIDTH               ( 64 ),
  .WIDTH               ( DATA_WIDTH ),
  .EMPTY_WIDTH         ( EMPTY_WIDTH ),
  .SOP_ON_LANE0        ( 1'b0 )
  ) pkt_gen_dyn (
  .arst                ( tx_reset | pktgen_srst),
  .tx_pkt_gen_en       ( cfg_pkt_gen_tx_en & cfg_tx_select_pkt_gen ),
  .pattern_mode        ( dyn_pattern_mode ),
  .start_addr          ( dyn_pkt_start_size_sync ),
  .end_addr            ( dyn_pkt_end_size_sync ),
  .pkt_num             ( dyn_pkt_num_sync ),
  .end_sel	           ( cfg_pkt_gen_cont_mode ),
  .ipg_sel             ( dyn_ipg_sel ),
  .ipg_cycles          ( ipg_cycles ),
  .DEST_ADDR           ( dyn_dmac_addr_sync ),
  .SRC_ADDR            ( dyn_smac_addr_sync ),
  
  .clk_tx              ( i_clk_tx ),
  .tx_ack              ( m1_tx_ready ),
  .tx_data             ( m1_tx_data ),
  .tx_start            ( m1_tx_sop ),
  .tx_end_pos          ( m1_tx_eop ),
  .tx_valid            ( m1_tx_valid ),
  .tx_empty            ( m1_tx_empty),
  //---csr interface---
  .stat_tx_cnt_clr     (stat_tx_cnt_clr_sync[1]),
  .stat_tx_cnt_vld     (m1_stat_tx_cnt_vld),
  .stat_tx_sop_cnt     (m1_stat_tx_sop_cnt),
  .stat_tx_eop_cnt     (m1_stat_tx_eop_cnt),
  .stat_tx_err_cnt     (m1_stat_tx_err_cnt)
);

//---------------------------------------------------------------
assign loopback_fifo_wr_full_err=1'b0;
// Fix DA CDC 50001
eth_f_multibit_sync #(
    .WIDTH(26)
) lpbk_cli_stat_sync_inst (
    .clk (i_clk_status),
    .reset_n (1'b1),
    .din ({loopback_fifo_wr_full_err, stat_rx_cnt_vld, stat_rx_sop_cnt, stat_rx_eop_cnt, stat_rx_err_cnt}),
    .dout ({loopback_fifo_wr_full_err_sync, stat_rx_cnt_vld_sync, stat_rx_sop_cnt_sync, stat_rx_eop_cnt_sync, stat_rx_err_cnt_sync})
);

eth_f_multibit_sync #(
    .WIDTH(25)
) pkt_cli_txif_stat_sync_inst (
    .clk (i_clk_status),
    .reset_n (1'b1),
    .din ({ stat_tx_cnt_vld_d, stat_tx_sop_cnt_d, stat_tx_eop_cnt_d, stat_tx_err_cnt_d}),
    .dout ({stat_tx_cnt_vld_sync, stat_tx_sop_cnt_sync, stat_tx_eop_cnt_sync, stat_tx_err_cnt_sync})
);


eth_f_packet_client_csr packet_client_csr (
        .i_clk_status            (i_clk_status),
        .i_clk_status_rst        (i_clk_status_rst),

        // status register bus
        .i_status_addr           (pktcli_avm_csr_if.address[22:0]),
        .i_status_read           (pktcli_avm_csr_if.read),
        .i_status_write          (pktcli_avm_csr_if.write),
        .i_status_writedata      (pktcli_avm_csr_if.writedata[31:0]),
        .o_status_readdata       (pktcli_avm_csr_if.readdata[31:0]),
        .o_status_readdata_valid (pktcli_avm_csr_if.readdatavalid),
        .o_status_waitrequest    (pktcli_avm_csr_if.waitrequest),

        //---csr ctrl---
        .cfg_pkt_client_ctrl     (cfg_pkt_client_ctrl),
        .dyn_dmac_addr           (dyn_dmac_addr),
        .dyn_smac_addr           (dyn_smac_addr),
        .dyn_pkt_num             (dyn_pkt_num),
        .dyn_pkt_start_size      (dyn_pkt_start_size),
        .dyn_pkt_end_size        (dyn_pkt_end_size),
        .cold_rst_csr            (o_cold_rst_csr),
		
        //---stat interface---
        .stat_tx_cnt_clr         (stat_tx_cnt_clr),
        .stat_tx_cnt_vld         (stat_tx_cnt_vld_sync),
        .stat_tx_sop_cnt         (stat_tx_sop_cnt_sync),
        .stat_tx_eop_cnt         (stat_tx_eop_cnt_sync),
        .stat_tx_err_cnt         (stat_tx_err_cnt_sync),

        .stat_rx_cnt_clr         (stat_rx_cnt_clr),
        .stat_rx_cnt_vld         (stat_rx_cnt_vld_sync),
        .stat_rx_sop_cnt         (stat_rx_sop_cnt_sync),
        .stat_rx_eop_cnt         (stat_rx_eop_cnt_sync),
        .stat_rx_err_cnt         (stat_rx_err_cnt_sync),
        .i_loopback_fifo_wr_full_err           ('0),
        .i_loopback_fifo_rd_empty_err          ('0),
        .stat_cntr_snapshot      (stat_cntr_snapshot),
        .stat_cntr_clear         (stat_cntr_clear),
        .sadb_config_done        (i_sadb_config_done),
        .system_status           (i_system_status),
        .checker_status          (checker_status_reg),
        .num_words               (num_words),
        .rx_byte_cnt(rx_byte_cnt),
        .tx_byte_cnt(tx_byte_cnt),
        .tx_num_ticks(tx_num_ticks),
        .rx_num_ticks(rx_num_ticks), 
        .tx_bw_cnt(tx_bw_cnt),
        .rx_bw_cnt(rx_bw_cnt)		  
);
defparam packet_client_csr.CLIENT_IF_TYPE     = CLIENT_IF_TYPE;
defparam packet_client_csr.STATUS_BASE_ADDR   = 16'h0;
defparam packet_client_csr.SIM_EMULATE        = 0;

//---------------------------------------------------------------
eth_f_multibit_sync #(
    .WIDTH(20)
) cfg_pkt_client_ctrl_sync_inst (
    .clk (i_clk_tx),
    .reset_n (1'b1),
    .din (cfg_pkt_client_ctrl),
    .dout (cfg_pkt_client_ctrl_sync)
);

eth_f_multibit_sync #(
    .WIDTH(48*2+32+14*2)
) cfg_dyn_data_sync_inst (
    .clk (i_clk_tx),
    .reset_n (1'b1),
    .din ({dyn_dmac_addr, dyn_smac_addr, dyn_pkt_num,dyn_pkt_start_size,dyn_pkt_end_size}),
    .dout({dyn_dmac_addr_sync, dyn_smac_addr_sync, dyn_pkt_num_sync,dyn_pkt_start_size_sync,dyn_pkt_end_size_sync})
);

assign cfg_pkt_gen_tx_en        = cfg_pkt_client_ctrl_sync[0];
assign cfg_pkt_gen_cont_mode =  cfg_pkt_client_ctrl_sync[2];
assign cfg_tx_select_pkt_gen    = cfg_pkt_client_ctrl_sync[4];
assign stat_cntr_snapshot = cfg_pkt_client_ctrl_sync[6];
assign stat_cntr_clear = cfg_pkt_client_ctrl_sync[7];
assign checker_srst    = cfg_pkt_client_ctrl_sync[3];
assign pktgen_srst    = cfg_pkt_client_ctrl_sync[3];
assign dyn_pattern_mode = cfg_pkt_client_ctrl_sync[11:10];
assign dyn_ipg_sel      = cfg_pkt_client_ctrl_sync[9];
assign ipg_cycles       = cfg_pkt_client_ctrl_sync[19:12];

 eth_f_altera_std_synchronizer_nocut inst_stat_rx_cnt_clr_sync (
     .clk        (i_clk_rx),
     .reset_n    (1'b1),
     .din        (stat_rx_cnt_clr),          // cold boot reset ackn
     .dout       (stat_rx_cnt_clr_cdc)
 );
  eth_f_altera_std_synchronizer_nocut inst_stat_tx_cnt_clr_sync (
     .clk        (i_clk_rx),
     .reset_n    (1'b1),
     .din        (stat_tx_cnt_clr),          // cold boot reset ackn
     .dout       (stat_tx_cnt_clr_cdc)
 );
//---------------------------------------------------------------
always @ (posedge i_clk_rx) begin
    stat_rx_cnt_clr_sync <= {stat_rx_cnt_clr_sync[0], stat_rx_cnt_clr_cdc};
end
always @ (posedge i_clk_tx) begin
    stat_tx_cnt_clr_sync <= {stat_tx_cnt_clr_sync[0], stat_tx_cnt_clr_cdc};
end

//---------------------------------------------------------------
eth_f_reset_synchronizer rstx (
        .aclr       (i_arst_tx),
        .clk        (i_clk_tx),
        .aclr_sync  (tx_reset)
);

eth_f_reset_synchronizer rsrx (
        .aclr       (i_arst_rx),
        .clk        (i_clk_rx),
        .aclr_sync  (rx_reset)
);

//////////////////////////////////////////////////////////////////// data checker	
  eth_f_packet_client_data_check_25G 
    #(
	   .WORDS (WORDS),
	   .WIDTH (DATA_WIDTH),
	   .EMPTY_WIDTH (EMPTY_WIDTH)
       ) 
	   
	   port_data_checker(
        .i_reset(i_arst_rx | checker_srst),
        .i_clk(i_clk_rx),
        .i_rx_sop(i_rx_sop),
        .i_rx_eop(i_rx_eop),
        .i_rx_empty(i_rx_empty),
        .i_rx_valid(i_rx_valid),
		  .i_rx_error(i_rx_error),
        //.i_rx_data(i_rx_data[WORDS*64-1:0]),
        .i_rx_data(i_rx_data[WORDS*DATA_WIDTH-1:0]),    //added on Nov14
        .i_tx_sop(o_tx_sop),
        .i_tx_eop(o_tx_eop),
        .i_tx_valid(o_tx_valid),
		  .i_tx_ready(m1_tx_ready),
        .i_cfg_pkt_gen_tx_en(cfg_pkt_gen_tx_en),
        .i_cfg_pkt_gen_cont_mode(cfg_pkt_gen_cont_mode),
        .i_cfg_tx_select_pkt_gen(cfg_tx_select_pkt_gen),
        .i_dyn_pkt_num_sync(dyn_pkt_num_sync),
        //.i_tx_data(o_tx_data[WORDS*64-1:0]),
        .i_tx_data(o_tx_data[WORDS*DATA_WIDTH-1:0]),	 //added on Nov14
        .o_data_error(data_err_reg[32]),
        .o_pkt_cnt_error(data_err_reg[33]),
        .o_packet_cnt(data_err_reg[31:0]),
        .stat_rx_cnt_clr(stat_rx_cnt_clr_sync[1]),
        .stat_rx_cnt_vld(stat_rx_cnt_vld),
        .stat_rx_sop_cnt(stat_rx_sop_cnt[7:0]),
        .stat_rx_eop_cnt(stat_rx_eop_cnt[7:0]),
        .stat_rx_err_cnt(stat_rx_err_cnt[7:0]),
        .rx_byte_cnt(rx_byte_cnt),
        .tx_byte_cnt(tx_byte_cnt),
        .tx_num_ticks(tx_num_ticks),
        .rx_num_ticks(rx_num_ticks), 
        .tx_bw_cnt(tx_bw_cnt),
        .rx_bw_cnt(rx_bw_cnt)
    );



eth_f_multibit_sync #(
    .WIDTH(34)
) checker_sync_inst (
    .clk (i_clk_status),
    .reset_n (1'b1),
    .din (data_err_reg),
    .dout (checker_status_reg)
);


endmodule


