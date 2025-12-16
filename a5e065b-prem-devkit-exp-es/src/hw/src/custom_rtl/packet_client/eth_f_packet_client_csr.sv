//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


`timescale 1 ps / 1 ps

module eth_f_packet_client_csr #(
        parameter CLIENT_IF_TYPE        = 0,
        parameter STATUS_BASE_ADDR      = 16'b0,
        parameter SIM_EMULATE           = 0,
        parameter ROM_ADDR_WIDTH        = 8
    )(
        input  logic                  i_clk_status,
        input  logic                  i_clk_status_rst,

        // status register bus
        input  logic   [22:0]         i_status_addr,
        input  logic                  i_status_read,
        input  logic                  i_status_write,
        input  logic   [31:0]         i_status_writedata,
        output logic   [31:0]         o_status_readdata,
        output logic                  o_status_readdata_valid,
        output logic                  o_status_waitrequest,

        //---csr ctrl
        output logic [19:0]               cfg_pkt_client_ctrl,   // [0]: start/stop sending pkt; 0: stop sending pkt;
      //  output logic [ROM_ADDR_WIDTH-1:0] cfg_rom_start_addr,    // Rom start addr for packet data;
      //  output logic [ROM_ADDR_WIDTH-1:0] cfg_rom_end_addr,      // define how many rows in Rom for packet data;
      //  output logic [ROM_ADDR_WIDTH-1:0] cfg_test_loop_cnt,     // define how many loops in total to read from Rom;
        output logic                      stat_cntr_snapshot,
        output logic                      stat_cntr_clear,
        output logic [47:0]               dyn_dmac_addr,
        output logic [47:0]               dyn_smac_addr,
        output logic [31:0]               dyn_pkt_num,
        output logic [13:0]               dyn_pkt_start_size,
        output logic [13:0]               dyn_pkt_end_size,
		output logic                      cold_rst_csr,
		
        //---stat interface---
        output logic                  stat_tx_cnt_clr,
        input  logic                  stat_tx_cnt_vld,
        input  logic [7:0]            stat_tx_sop_cnt,
        input  logic [7:0]            stat_tx_eop_cnt,
        input  logic [7:0]            stat_tx_err_cnt,

        output logic                  stat_rx_cnt_clr,
        input  logic                  stat_rx_cnt_vld,
        input  logic [7:0]            stat_rx_sop_cnt,
        input  logic [7:0]            stat_rx_eop_cnt,
        input  logic [7:0]            stat_rx_err_cnt,

        input  logic                  i_loopback_fifo_wr_full_err,
        input  logic                  i_loopback_fifo_rd_empty_err,

        /// SADB status
        input  logic                  sadb_config_done,
        input  logic [ 3:0]           system_status,
        input  logic [33:0]           checker_status,

        input logic [63:0]            rx_byte_cnt,
	    input logic [63:0]            tx_byte_cnt,
	    input logic [63:0]            tx_num_ticks,
	    input logic [63:0]            rx_num_ticks,
        input logic [63:0]            tx_bw_cnt,
        input logic [63:0]            rx_bw_cnt
         
);

//---------------------------------------------
logic [63:0]  stat_tx_sop_cnt_all, stat_tx_eop_cnt_all, stat_tx_err_cnt_all;
logic [63:0]  stat_rx_sop_cnt_all, stat_rx_eop_cnt_all, stat_rx_err_cnt_all;
logic [63:0]  stat_tx_sop_cnt_all_shadow, stat_tx_eop_cnt_all_shadow, stat_tx_err_cnt_all_shadow;
logic [63:0]  stat_rx_sop_cnt_all_shadow, stat_rx_eop_cnt_all_shadow, stat_rx_err_cnt_all_shadow;

logic [63:0]  rx_byte_cnt_sync, tx_byte_cnt_sync, tx_num_ticks_sync, rx_num_ticks_sync, tx_bw_cnt_sync, rx_bw_cnt_sync;

logic         loopback_fifo_wr_full_err, loopback_fifo_rd_empty_err;

logic [7:0]   status_addr_r;
logic [31:0]  status_writedata_r;
logic         status_addr_sel, status_read, status_write;
logic         status_addr_sel_r, status_read_r, status_write_r;
logic         status_read_r2, status_write_r2;
logic         status_read_p, status_write_p;
logic         cfg_cnt_clr_clr;
logic         status_waitrequest, status_waitrequest_r;
logic [ 3:0]  system_status_r;

//---------------------------------------------
//---cfg_pkt_client_ctrl (reg_00)---
//---[0]: 1: start pkt generator; 0: stop pkt gen;
//---[4]: 0: send pkt generator data to MAC; 1: send loopback client data to MAC;
//---[8]: 1: clear pkt tx/rx counters; self-clean;

//---------------------------------------------
logic [31:0]  reg_00;   //---cfg_pkt_client_ctrl
logic [31:0]  reg_01;   //---cfg_test_loop_cnt
//logic [31:0]  reg_02;   //---Rom start/end address;
logic [31:0]  reg_02; // reserved
logic [31:0]  reg_03;   //---some status signals;
logic [31:0]  reg_04;   //---DMAC Address;
logic [31:0]  reg_05;   //---DMAC address;
logic [31:0]  reg_06;   //---SMAC ADdress;
logic [31:0]  reg_07;   //---SMAC Address;
logic [31:0]  reg_08;   //---packet number;
logic [31:0]  reg_09;   //---packet size config;
logic [31:0]  reg_20;   //---cold rst bit;

//---------------------------------------------
assign cfg_pkt_client_ctrl  = reg_00[19:0];
//assign cfg_test_loop_cnt    = reg_01[0+:ROM_ADDR_WIDTH];
//assign cfg_rom_start_addr   = reg_02[0+:ROM_ADDR_WIDTH];
//assign cfg_rom_end_addr     = reg_02[16+:ROM_ADDR_WIDTH];
assign dyn_dmac_addr        = {reg_03[15:0],reg_04};
assign dyn_smac_addr        = {reg_05[15:0],reg_06};
assign dyn_pkt_num          = reg_07[31:0];
assign dyn_pkt_start_size   = reg_08[13:0];
assign dyn_pkt_end_size     = reg_08[29:16];
assign cold_rst_csr         = reg_20[0];

//---------------------------------------------
assign status_addr_sel = ({i_status_addr[15:8], 8'b0} == STATUS_BASE_ADDR);
assign status_read  = i_status_read & status_addr_sel;
assign status_write = i_status_write & status_addr_sel;

assign status_read_p = status_read_r & !status_read_r2;
assign status_write_p = status_write_r & !status_write_r2;

//---------------------------------------------
always @(posedge i_clk_status) begin
        status_addr_r           <= i_status_addr[9:2];
        status_addr_sel_r       <= status_addr_sel;
        status_read_r           <= status_read;
        status_write_r          <= status_write;
        status_writedata_r      <= i_status_writedata;
        status_read_r2          <= status_read_r;
        status_write_r2         <= status_write_r;
end

always @(posedge i_clk_status) begin
    status_waitrequest_r <= status_waitrequest;
    if (i_clk_status_rst)     status_waitrequest <= 1'b1;
    else         status_waitrequest <= !(status_read_p | status_write_p);
end
assign o_status_waitrequest = status_waitrequest & status_waitrequest_r;

//---------------------------------------------
logic  stat_tx_sop_cnt_sel, stat_tx_eop_cnt_sel;
assign stat_tx_sop_cnt_sel = status_addr_sel_r & (status_addr_r == 8'h9);
assign stat_tx_eop_cnt_sel = status_addr_sel_r & (status_addr_r == 8'ha);

//---------------------------------------------
always @(posedge i_clk_status) begin
    if (i_clk_status_rst) begin
                   reg_00 <= 32'h0000_0000;
                  // reg_01 <= 32'h0000_0001;
                  // reg_02 <= 32'h007F_0000;
                   reg_03 <= 32'h0000_1234;
                   reg_04 <= 32'h5678_0ADD;
                   reg_05 <= 32'h0000_8765;
                   reg_06 <= 32'h4321_0ADD;
                   reg_07 <= 32'h0000_000A;
                   reg_08 <= 32'h2580_0040;
                   reg_20 <= 32'h0000_0000;
    end else if (status_write_r & status_addr_sel_r) begin
        case (status_addr_r)
            8'h00:  reg_00 <= status_writedata_r;
          //  8'h01:  reg_01 <= status_writedata_r;
           // 8'h02:  reg_02 <= status_writedata_r;
            8'h03:  reg_03 <= status_writedata_r;
            8'h04:  reg_04 <= status_writedata_r;
            8'h05:  reg_05 <= status_writedata_r;
            8'h06:  reg_06 <= status_writedata_r;
            8'h07:  reg_07 <= status_writedata_r;
            8'h08:  reg_08 <= status_writedata_r;
            8'h20:  reg_20 <= status_writedata_r;
        endcase
    end else begin
        if (cfg_cnt_clr_clr)  reg_00[8] <= 1'b0;
    end
end

//---------------------------------------------
always @(posedge i_clk_status) begin
        o_status_readdata_valid <= status_read_r2 & !status_waitrequest_r;
    if (status_read_p) begin
        if (status_addr_sel_r) begin
            case (status_addr_r)
       /*0x00*/ 8'h00:    o_status_readdata <= reg_00;
     //  /*0x04*/ 8'h01:    o_status_readdata <= reg_01;
     //  /*0x08*/ 8'h02:    o_status_readdata <= reg_02;
       /*0x0c*/ 8'h03:    o_status_readdata <= reg_03;
       /*0x10*/ 8'h04:    o_status_readdata <= reg_04;
       /*0x14*/ 8'h05:    o_status_readdata <= reg_05;
       /*0x18*/ 8'h06:    o_status_readdata <= reg_06;
       /*0x1c*/ 8'h07:    o_status_readdata <= reg_07;
       /*0x20*/ 8'h08:    o_status_readdata <= reg_08;

       /*0x24*/ 8'h09:    o_status_readdata <= stat_tx_sop_cnt_all_shadow[31:0];
       /*0x28*/ 8'h0a:    o_status_readdata <= stat_tx_sop_cnt_all_shadow[63:32];

       /*0x2c*/ 8'h0b:    o_status_readdata <= stat_tx_eop_cnt_all_shadow[31:0];
       /*0x30*/ 8'h0c:    o_status_readdata <= stat_tx_eop_cnt_all_shadow[63:32];

       /*0x34*/ 8'h0d:    o_status_readdata <= stat_tx_err_cnt_all_shadow[31:0];
       /*0x38*/ 8'h0e:    o_status_readdata <= stat_tx_err_cnt_all_shadow[63:32];

       /*0x3c*/ 8'h0f:    o_status_readdata <= stat_rx_sop_cnt_all_shadow[31:0];
       /*0x40*/ 8'h10:    o_status_readdata <= stat_rx_sop_cnt_all_shadow[63:32];

       /*0x44*/ 8'h11:    o_status_readdata <= stat_rx_eop_cnt_all_shadow[31:0];
       /*0x48*/ 8'h12:    o_status_readdata <= stat_rx_eop_cnt_all_shadow[63:32];

       /*0x4c*/ 8'h13:    o_status_readdata <= stat_rx_err_cnt_all_shadow[31:0];
       /*0x50*/ 8'h14:    o_status_readdata <= stat_rx_err_cnt_all_shadow[63:32];
       /*0x54*/ 8'h15:    o_status_readdata <= {27'h0, system_status_r,sadb_config_done};
       /*0x58*/ 8'h16:    o_status_readdata <= {31'b0,checker_status[32]};
       /*0x5C*/ 8'h17:    o_status_readdata <= checker_status[31:0];

    

       /*0x60*/ 8'h18:    o_status_readdata <= rx_byte_cnt_sync[31:0];
       /*0x64*/ 8'h19:    o_status_readdata <= rx_byte_cnt_sync[63:32];
	   
       /*0x68*/ 8'h1a:    o_status_readdata <= tx_byte_cnt_sync[31:0];
       /*0x6C*/ 8'h1b:    o_status_readdata <= tx_byte_cnt_sync[63:32];


       /*0x70*/ 8'h1c:    o_status_readdata <= tx_num_ticks_sync[31:0];
       /*0x74*/ 8'h1d:    o_status_readdata <= tx_num_ticks_sync[63:32];
	   
	   
       /*0x78*/ 8'h1e:    o_status_readdata <= rx_num_ticks_sync[31:0];
       /*0x7C*/ 8'h1f:    o_status_readdata <= rx_num_ticks_sync[63:32];   
       /*0x80*/ 8'h20:    o_status_readdata <= reg_20;   

       /*0x84*/ 8'h21:    o_status_readdata <= tx_bw_cnt_sync[31:0];   
       /*0x88*/ 8'h22:    o_status_readdata <= tx_bw_cnt_sync[63:32];   

       /*0x8C*/ 8'h23:    o_status_readdata <= rx_bw_cnt_sync[31:0];   
       /*0x90*/ 8'h24:    o_status_readdata <= rx_bw_cnt_sync[63:32];   

                default:  o_status_readdata <= 32'hdeadc0de;
            endcase
        end else begin
            o_status_readdata <= 32'hdeadc0de;
        end
    end
end

//---------------------------------------------
always @(posedge i_clk_status) begin
    loopback_fifo_wr_full_err  <= i_loopback_fifo_wr_full_err;
    loopback_fifo_rd_empty_err <= i_loopback_fifo_rd_empty_err;
end

//---------------------------------------------
logic [7:0] cfg_cnt_clr;
always @(posedge i_clk_status) begin
    cfg_cnt_clr <= {cfg_cnt_clr[6:0], reg_00[8]};
end

assign stat_rx_cnt_clr = reg_00[8];
assign stat_tx_cnt_clr = reg_00[8];
assign cfg_cnt_clr_clr = cfg_cnt_clr[7];   // for self-clear;
assign stat_cntr_snapshot = reg_00[6]; //for snapshot
assign stat_cntr_clear = reg_00[7]; //for clear


  always_ff @(posedge i_clk_status) begin
    if (stat_cntr_clear) begin
     stat_tx_sop_cnt_all_shadow <= 0;
     stat_tx_eop_cnt_all_shadow <= 0;
     stat_tx_err_cnt_all_shadow <= 0;
     stat_rx_sop_cnt_all_shadow <= 0;
     stat_rx_eop_cnt_all_shadow <= 0;
     stat_rx_err_cnt_all_shadow <= 0;
    end else begin
    if (stat_cntr_snapshot) begin
        stat_tx_sop_cnt_all_shadow  <= stat_tx_sop_cnt_all_shadow;
          stat_tx_eop_cnt_all_shadow  <= stat_tx_eop_cnt_all_shadow;
          stat_tx_err_cnt_all_shadow  <= stat_tx_err_cnt_all_shadow;
          stat_rx_sop_cnt_all_shadow  <= stat_rx_sop_cnt_all_shadow;
          stat_rx_eop_cnt_all_shadow  <= stat_rx_eop_cnt_all_shadow;
          stat_rx_err_cnt_all_shadow  <= stat_rx_err_cnt_all_shadow;
    end else begin
        stat_tx_sop_cnt_all_shadow  <= stat_tx_sop_cnt_all;
          stat_tx_eop_cnt_all_shadow  <= stat_tx_eop_cnt_all;
          stat_tx_err_cnt_all_shadow  <= stat_tx_err_cnt_all;
          stat_rx_sop_cnt_all_shadow  <= stat_rx_sop_cnt_all;
          stat_rx_eop_cnt_all_shadow  <= stat_rx_eop_cnt_all;
          stat_rx_err_cnt_all_shadow  <= stat_rx_err_cnt_all;
    end

  end
  end


//---------------------------------------------
eth_f_packet_client_csr_pkt_cnt  u_tx_sop_cnt (
        .clk        (i_clk_status),
        .rst        (i_clk_status_rst),
        .cnt_clr    (stat_tx_cnt_clr),
        .cnt_in_vld (stat_tx_cnt_vld),
        .cnt_in     (stat_tx_sop_cnt),
        .cnt_out    (stat_tx_sop_cnt_all)
);


eth_f_packet_client_csr_pkt_cnt  u_tx_eop_cnt (
        .clk        (i_clk_status),
        .rst        (i_clk_status_rst),
        .cnt_clr    (stat_tx_cnt_clr),
        .cnt_in_vld (stat_tx_cnt_vld),
        .cnt_in     (stat_tx_eop_cnt),
        .cnt_out    (stat_tx_eop_cnt_all)
);



eth_f_packet_client_csr_pkt_cnt  u_tx_err_cnt (
        .clk        (i_clk_status),
        .rst        (i_clk_status_rst),
        .cnt_clr    (stat_tx_cnt_clr),
        .cnt_in_vld (stat_tx_cnt_vld),
        .cnt_in     (stat_tx_err_cnt),
        .cnt_out    (stat_tx_err_cnt_all)
);


//---------------------------------------------
eth_f_packet_client_csr_pkt_cnt  u_rx_sop_cnt (
        .clk        (i_clk_status),
        .rst        (i_clk_status_rst),
        .cnt_clr    (stat_rx_cnt_clr),
        .cnt_in_vld (stat_rx_cnt_vld),
        .cnt_in     (stat_rx_sop_cnt),
        .cnt_out    (stat_rx_sop_cnt_all)
);


eth_f_packet_client_csr_pkt_cnt  u_rx_eop_cnt (
        .clk        (i_clk_status),
        .rst        (i_clk_status_rst),
        .cnt_clr    (stat_rx_cnt_clr),
        .cnt_in_vld (stat_rx_cnt_vld),
        .cnt_in     (stat_rx_eop_cnt),
        .cnt_out    (stat_rx_eop_cnt_all)
);

eth_f_packet_client_csr_pkt_cnt  u_rx_err_cnt (
        .clk        (i_clk_status),
        .rst        (i_clk_status_rst),
        .cnt_clr    (stat_rx_cnt_clr),
        .cnt_in_vld (stat_rx_cnt_vld),
        .cnt_in     (stat_rx_err_cnt),
        .cnt_out    (stat_rx_err_cnt_all)
);

//---------------------------------------------

// multi-bit synchronizers


eth_f_multibit_sync #(
    .WIDTH(4)
) sys_status_sync_inst (
    .clk (i_clk_status),
    .reset_n (1'b1),
    .din (system_status),
    .dout (system_status_r)
);

eth_f_multibit_sync #(
    .WIDTH(64)
) tx_byte_cnt_sync_inst (
    .clk (i_clk_status),
    .reset_n (1'b1),
    .din (tx_byte_cnt),
    .dout (tx_byte_cnt_sync)
);

eth_f_multibit_sync #(
    .WIDTH(64)
) rx_byte_cnt_sync_inst (
    .clk (i_clk_status),
    .reset_n (1'b1),
    .din (rx_byte_cnt),
    .dout (rx_byte_cnt_sync)
);

eth_f_multibit_sync #(
    .WIDTH(64)
) tx_num_ticks_sync_inst (
    .clk (i_clk_status),
    .reset_n (1'b1),
    .din (tx_num_ticks),
    .dout (tx_num_ticks_sync)
);

eth_f_multibit_sync #(
    .WIDTH(64)
) rx_num_ticks_sync_inst (
    .clk (i_clk_status),
    .reset_n (1'b1),
    .din (rx_num_ticks),
    .dout (rx_num_ticks_sync)
);

eth_f_multibit_sync #(
    .WIDTH(64)
) tx_bw_cnt_sync_inst (
    .clk (i_clk_status),
    .reset_n (1'b1),
    .din (tx_bw_cnt),
    .dout (tx_bw_cnt_sync)
);       

eth_f_multibit_sync #(
    .WIDTH(64)
) rx_bw_cnt_sync_inst (
    .clk (i_clk_status),
    .reset_n (1'b1),
    .din (rx_bw_cnt),
    .dout (rx_bw_cnt_sync)
);   

endmodule

