//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//#########################################################################

// F2H AXI slave (Data path) connections
// ----------------------------------------------------------------------------------------------------------------
assign `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(awready) = axi_if.slave_if[0].awready;
assign axi_if.slave_if[0].awvalid = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(awvalid);
assign axi_if.slave_if[0].awaddr  = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(awaddr);
assign axi_if.slave_if[0].awlen   = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(awlen);
assign axi_if.slave_if[0].awburst = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(awburst);
assign axi_if.slave_if[0].awsize  = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(awsize);
assign axi_if.slave_if[0].awprot  = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(awprot);
assign axi_if.slave_if[0].awid    = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(awid);
assign axi_if.slave_if[0].awcache = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(awcache);

assign `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(wready) = axi_if.slave_if[0].wready;
assign axi_if.slave_if[0].wvalid = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(wvalid);
assign axi_if.slave_if[0].wdata  = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(wdata); 
assign axi_if.slave_if[0].wstrb  = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(wstrb); 
assign axi_if.slave_if[0].wlast  = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(wlast); 

assign axi_if.slave_if[0].bready = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(bready);
assign `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(bvalid) = axi_if.slave_if[0].bvalid;
assign `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(bresp)  = axi_if.slave_if[0].bresp;
assign `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(bid)    = axi_if.slave_if[0].bid;
assign `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(buser)  = axi_if.slave_if[0].buser;

assign `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(arready) = axi_if.slave_if[0].arready;
assign axi_if.slave_if[0].arvalid = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(arvalid);
assign axi_if.slave_if[0].araddr  = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(araddr);
assign axi_if.slave_if[0].arlen   = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(arlen);
assign axi_if.slave_if[0].arburst = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(arburst);
assign axi_if.slave_if[0].arsize  = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(arsize);
assign axi_if.slave_if[0].arprot  = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(arprot);
assign axi_if.slave_if[0].arid    = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(arid);
assign axi_if.slave_if[0].arcache = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(arcache);

assign axi_if.slave_if[0].rready = `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(rready);
assign `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(rvalid) = axi_if.slave_if[0].rvalid;
assign `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(rdata)  = axi_if.slave_if[0].rdata;
assign `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(rlast)  = axi_if.slave_if[0].rlast;
assign `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(rresp)  = axi_if.slave_if[0].rresp;
assign `SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(rid)    = axi_if.slave_if[0].rid;
// ----------------------------------------------------------------------------------------------------------------

// H2F AXI master (CSR path) connections
assign axi_if.master_if[0].awready     = `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_awready;
assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_awvalid = axi_if.master_if[0].awvalid;
assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_awaddr  = axi_if.master_if[0].awaddr;
assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_awlen   = axi_if.master_if[0].awlen;
assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_awburst = axi_if.master_if[0].awburst;
assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_awsize  = axi_if.master_if[0].awsize;
assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_awprot  = axi_if.master_if[0].awprot;
assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_awid    = axi_if.master_if[0].awid;
assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_awcache = axi_if.master_if[0].awcache;

assign axi_if.master_if[0].wready     = `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_wready;
assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_wvalid = axi_if.master_if[0].wvalid;
assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_wdata  = axi_if.master_if[0].wdata;
assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_wstrb  = axi_if.master_if[0].wstrb;
assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_wlast  = axi_if.master_if[0].wlast;

assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_bready = axi_if.master_if[0].bready;
assign axi_if.master_if[0].bvalid     = `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_bvalid;
assign axi_if.master_if[0].bresp      = `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_bresp;
assign axi_if.master_if[0].bid        = `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_bid;

assign axi_if.master_if[0].arready     = `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_arready;
assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_arvalid = axi_if.master_if[0].arvalid;
assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_araddr  = axi_if.master_if[0].araddr;
assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_arlen   = axi_if.master_if[0].arlen;
assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_arburst = axi_if.master_if[0].arburst;
assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_arsize  = axi_if.master_if[0].arsize;
assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_arprot  = axi_if.master_if[0].arprot;
assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_arid    = axi_if.master_if[0].arid;
assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_arcache = axi_if.master_if[0].arcache;

assign `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_rready = axi_if.master_if[0].rready;
assign axi_if.master_if[0].rvalid     = `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_rvalid;
assign axi_if.master_if[0].rdata      = `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_rdata;
assign axi_if.master_if[0].rlast      = `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_rlast;
assign axi_if.master_if[0].rresp      = `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_rresp;
assign axi_if.master_if[0].rid        = `SM_PTP_QSYS_TOP.subsys_hps_hps2fpga_rid;
// ----------------------------------------------------------------------------------------------------------------
// Ingress Port 0
assign ehip_if.p_ingress_clk[0]   = `SM_PTP_EHIP_PORT0.i_clk_tx;
assign ehip_if.p_ingress_data[0]  = `SM_PTP_EHIP_PORT0.i_tx_data;
assign ehip_if.p_ingress_valid[0] = `SM_PTP_EHIP_PORT0.i_tx_valid;
assign ehip_if.p_ingress_sop[0]   = `SM_PTP_EHIP_PORT0.i_tx_startofpacket;
assign ehip_if.p_ingress_eop[0]   = `SM_PTP_EHIP_PORT0.i_tx_endofpacket;
assign ehip_if.p_ingress_ready[0] = `SM_PTP_EHIP_PORT0.o_tx_ready;
assign ehip_if.p_ingress_error[0] = `SM_PTP_EHIP_PORT0.i_tx_error;
// TBD: PTP connections 
// assign ehip_if.p_ingress_ets_valid[0] = `SM_PTP_EHIP_PORT0.o_ptp_ets_valid;
// assign ehip_if.p_ingress_ets_ready[0] = `SM_PTP_EHIP_PORT0.o_ptp_ets_ready;
// assign ehip_if.p_ingress_ets[0]       = `SM_PTP_EHIP_PORT0.o_ptp_ets;

// Egress Port 0
assign ehip_if.p_egress_clk[0]   = `SM_PTP_EHIP_PORT0.i_clk_rx;
assign ehip_if.p_egress_data[0]  = `SM_PTP_EHIP_PORT0.o_rx_data;
assign ehip_if.p_egress_valid[0] = `SM_PTP_EHIP_PORT0.o_rx_valid;
assign ehip_if.p_egress_sop[0]   = `SM_PTP_EHIP_PORT0.o_rx_startofpacket;
assign ehip_if.p_egress_eop[0]   = `SM_PTP_EHIP_PORT0.o_rx_endofpacket;
assign ehip_if.p_egress_error[0] = `SM_PTP_EHIP_PORT0.o_rx_error;
// TBD: PTP connections 
// assign ehip_if.p_egress_ets_valid[0] = `SM_PTP_EHIP_PORT0.o_ptp_ets_valid;
// assign ehip_if.p_egress_ets_ready[0] = `SM_PTP_EHIP_PORT0.o_ptp_ets_ready;
// assign ehip_if.p_egress_ets[0]       = `SM_PTP_EHIP_PORT0.o_ptp_ets;

`ifdef NUM_CHANNELS_2
// Ingress Port 1
assign ehip_if.p_ingress_clk[1]   = `SM_PTP_EHIP_PORT1.i_clk_tx;
assign ehip_if.p_ingress_data[1]  = `SM_PTP_EHIP_PORT1.i_tx_data;
assign ehip_if.p_ingress_valid[1] = `SM_PTP_EHIP_PORT1.i_tx_valid;
assign ehip_if.p_ingress_sop[1]   = `SM_PTP_EHIP_PORT1.i_tx_startofpacket;
assign ehip_if.p_ingress_eop[1]   = `SM_PTP_EHIP_PORT1.i_tx_endofpacket;
assign ehip_if.p_ingress_ready[1] = `SM_PTP_EHIP_PORT1.o_tx_ready;
assign ehip_if.p_ingress_error[1] = `SM_PTP_EHIP_PORT1.i_tx_error;
// TBD: PTP connections 
// assign ehip_if.p_ingress_ets_valid[1] = `SM_PTP_EHIP_PORT1.o_ptp_ets_valid;
// assign ehip_if.p_ingress_ets_ready[1] = `SM_PTP_EHIP_PORT1.o_ptp_ets_ready;
// assign ehip_if.p_ingress_ets[1]       = `SM_PTP_EHIP_PORT1.o_ptp_ets;

// Egress Port 1
assign ehip_if.p_egress_clk[1]   = `SM_PTP_EHIP_PORT1.i_clk_rx;
assign ehip_if.p_egress_data[1]  = `SM_PTP_EHIP_PORT1.o_rx_data;
assign ehip_if.p_egress_valid[1] = `SM_PTP_EHIP_PORT1.o_rx_valid;
assign ehip_if.p_egress_sop[1]   = `SM_PTP_EHIP_PORT1.o_rx_startofpacket;
assign ehip_if.p_egress_eop[1]   = `SM_PTP_EHIP_PORT1.o_rx_endofpacket;
assign ehip_if.p_egress_error[1] = `SM_PTP_EHIP_PORT1.o_rx_error;
// TBD: PTP connections 
// assign ehip_if.p_egress_ets_valid[1] = `SM_PTP_EHIP_PORT1.o_ptp_ets_valid;
// assign ehip_if.p_egress_ets_ready[1] = `SM_PTP_EHIP_PORT1.o_ptp_ets_ready;
// assign ehip_if.p_egress_ets[1]       = `SM_PTP_EHIP_PORT1.o_ptp_ets;
`endif
// ----------------------------------------------------------------------------------------------------------------

// initial
//   force `SM_PTP_QSYS_TOP.reset_reset_n = sm_ptp_reset_if.resetn;
