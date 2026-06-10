set_global_assignment -name QSYS_FILE ../src/qsys/qsfp_ctrl.qsys
set_global_assignment -name QSYS_FILE ../src/qsys/reset_req.qsys
set_global_assignment -name QSYS_FILE ../src/qsys/axi_to_avmm_qsfp_cntlr.qsys
set_global_assignment -name QSYS_FILE ../src/qsys/hps_subsys.qsys
set_global_assignment -name QSYS_FILE ../src/qsys/qsys_top.qsys
set_global_assignment -name QSYS_FILE ../src/qsys/subsys_msgdma.qsys
set_global_assignment -name QSYS_FILE ../src/qsys/subsys_msgdma_ch2.qsys
set_global_assignment -name QSYS_FILE ../src/qsys/csr_bridges.qsys

set_global_assignment -name IP_FILE ../src/ip/hps_subsys/agilex_hps.ip
set_global_assignment -name IP_FILE ../src/ip/hps_subsys/hps_subsys_f2sdram_adapter_0.ip
set_global_assignment -name IP_FILE ../src/ip/hps_subsys/emif_io96b_hps.ip

set_global_assignment -name IP_FILE ../src/ip/subsys_hssi/gts_reset_sequencer.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_hssi/gts_systempll.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_hssi/ethernet_hip.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_hssi/sync_tod_iopll.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_hssi/master_tod_adv_mode.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_hssi/phase_iopll.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_hssi/emif_calib.ip


set_global_assignment -name IP_FILE ../src/ip/csr_bridges/qsfp_cntlr_axi_bdg.ip
set_global_assignment -name IP_FILE ../src/ip/csr_bridges/csr_bridges_reset_in.ip
set_global_assignment -name IP_FILE ../src/ip/csr_bridges/user_space_csr.ip
set_global_assignment -name IP_FILE ../src/ip/csr_bridges/csr_bridges_clock_in.ip
set_global_assignment -name IP_FILE ../src/ip/csr_bridges/qhip_port_0.ip
set_global_assignment -name IP_FILE ../src/ip/csr_bridges/qsfp_cntlr_axi_bdg.ip
set_global_assignment -name IP_FILE ../src/ip/csr_bridges/axi4lite_pktcli_0.ip
set_global_assignment -name IP_FILE ../src/ip/csr_bridges/axi4lite_pktcli_1.ip
set_global_assignment -name IP_FILE ../src/ip/csr_bridges/csr_bridges_axi4lite_pktcli_2.ip
set_global_assignment -name IP_FILE ../src/ip/csr_bridges/axi4lite_ptpbridge.ip
set_global_assignment -name IP_FILE ../src/ip/csr_bridges/axi4lite_pktcli_0.ip
set_global_assignment -name IP_FILE ../src/ip/csr_bridges/axi4lite_ptpbridge.ip
set_global_assignment -name IP_FILE ../src/ip/csr_bridges/qhip_port_0.ip
set_global_assignment -name IP_FILE ../src/ip/csr_bridges/qhip_port_1.ip
set_global_assignment -name IP_FILE ../src/ip/csr_bridges/master_tod_csr.ip

set_global_assignment -name IP_FILE ../src/ip/axi_to_avmm_qsfp_cntlr/axi_to_avmm_qsfp_cntlr_clock_in.ip
set_global_assignment -name IP_FILE ../src/ip/axi_to_avmm_qsfp_cntlr/axi_to_avmm_qsfp_cntlr_reset_in.ip
set_global_assignment -name IP_FILE ../src/ip/axi_to_avmm_qsfp_cntlr/axi_bdg.ip
set_global_assignment -name IP_FILE ../src/ip/axi_to_avmm_qsfp_cntlr/avmm_bdg_0.ip

set_global_assignment -name IP_FILE ../src/ip/qsfp_contlr/qsfp_ctrl_clock_in.ip
set_global_assignment -name IP_FILE ../src/ip/qsfp_contlr/qsfp_ctrl_i2c_0.ip
set_global_assignment -name IP_FILE ../src/ip/qsfp_contlr/qsfp_ctrl_reset_in.ip
set_global_assignment -name IP_FILE ../src/ip/qsfp_contlr/i2c_slv_to_avmm.ip
set_global_assignment -name IP_FILE ../src/ip/qsfp_contlr/ip_qsfp_shadow_reg/ocm2_0.ip
set_global_assignment -name IP_FILE ../src/ip/qsfp_contlr/ip_qsfp_shadow_reg/qsfp_shadow_reg_clock_in.ip
set_global_assignment -name IP_FILE ../src/ip/qsfp_contlr/ip_qsfp_shadow_reg/qsfp_shadow_reg_reset_in.ip
set_global_assignment -name IP_FILE ../src/ip/qsfp_contlr/reset_req/reset_req_clock_in.ip
set_global_assignment -name IP_FILE ../src/ip/qsfp_contlr/reset_req/reset_req_reset_in.ip
set_global_assignment -name IP_FILE ../src/ip/qsfp_contlr/reset_req/reset_req_cntlr.ip

set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/axi4lite_rst_bdg.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/host_clk_bdg.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/host_rstn.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/hssi_ets_ts_adapter_0.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/subsys_msgdma_prefetcher_0.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/subsys_msgdma_dispatcher_0.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/subsys_msgdma_read_master_0.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/subsys_msgdma_prefetcher_1.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/subsys_msgdma_dispatcher_1.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/subsys_msgdma_write_master_0.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/subsys_msgdma_ts_chs_compl_0.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/tx_dma_fifo_0.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/tx_dma_fifo_0_ch2.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/tx_dma_csr.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/avst_axist_bridge_0.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/rx_dma_fifo_0.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/rx_dma_fifo_0_ch2.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/hssi_rst_rx.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/subsys_msgdma_avst_axist_bridge_1.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/axi4lite_clk_bdg.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/rst_user_bdg.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_msgdma/fifo_user_rst_rx.ip

set_global_assignment -name IP_FILE ../src/ip/qsys_top/clk_100.ip
set_global_assignment -name IP_FILE ../src/ip/qsys_top/rst_in.ip
set_global_assignment -name IP_FILE ../src/ip/qsys_top/user_rst_clkgate_0.ip
set_global_assignment -name IP_FILE ../src/ip/qsys_top/iopll.ip
set_global_assignment -name IP_FILE ../src/ip/qsys_top/rst_bdg_100.ip
set_global_assignment -name IP_FILE ../src/ip/qsys_top/clk_bdg_100.ip
set_global_assignment -name IP_FILE ../src/ip/qsys_top/clk_bdg_161.ip
set_global_assignment -name IP_FILE ../src/ip/qsys_top/qsys_top_mm_ccb_0.ip
set_global_assignment -name IP_FILE ../src/ip/qsys_top/clk_bdg_161_1.ip
set_global_assignment -name IP_FILE ../src/ip/qsys_top/clk_bdg_125.ip
set_global_assignment -name IP_FILE ../src/ip/qsys_top/rst_bdg_125.ip
set_global_assignment -name IP_FILE ../src/ip/qsys_top/f2h_avmm_bridge.ip
set_global_assignment -name IP_FILE ../src/ip/cdr_clk_gpio.ip
set_global_assignment -name IP_FILE ../src/ip/qsys_top/cdc_tod_125_100M.ip
set_global_assignment -name IP_FILE ../src/ip/qsys_top/qsys_top_iopll_1.ip

