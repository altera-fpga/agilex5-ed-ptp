# ######################################################################## 
# Copyright (C) 2025 Altera Corporation.
# SPDX-License-Identifier: MIT
# ######################################################################## 
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_subsys.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_wadj/packet_switch_tx_igr_wadj.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_wadj/packet_switch_rx_igr_wadj.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_wadj/packet_switch_igr_wadj.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_wadj/packet_switch_egr_wadj.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_wadj/packet_switch_axi_wdj_lg2sm.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_wadj/igr_wadj_csr_intf.sv
set_global_assignment -name VERILOG_FILE         ../src/custom_rtl/packet_switch/packet_switch_wadj/igr_wadj_csr.v
set_global_assignment -name VERILOG_FILE         ../src/custom_rtl/packet_switch/packet_switch_wadj/igr_wadj_10G_csr.v
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_wadj/egr_wadj_seg_split.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_wadj/egr_wadj_csr_intf.sv
set_global_assignment -name VERILOG_FILE         ../src/custom_rtl/packet_switch/packet_switch_wadj/egr_wadj_csr.v
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_top/packet_switch_tx.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_top/packet_switch_top.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_top/packet_switch_rx.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_top/general_csr_intf.sv
set_global_assignment -name VERILOG_FILE         ../src/custom_rtl/packet_switch/packet_switch_top/general_csr.v
set_global_assignment -name VERILOG_FILE         ../src/custom_rtl/packet_switch/packet_switch_tcam_mem_ss_cam_0/synth/ptp_bridge_tcam_mem_ss_cam_0.v
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_tcam_mem_ss_cam_0/mem_ss_cam_400/synth/ms_tcam_toggle_synchronizer.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_tcam_mem_ss_cam_0/mem_ss_cam_400/synth/ms_tcam_scsdpram.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_tcam_mem_ss_cam_0/mem_ss_cam_400/synth/ms_tcam_scfifo.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_tcam_mem_ss_cam_0/mem_ss_cam_400/synth/ms_tcam_reset_sequencer.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_tcam_mem_ss_cam_0/mem_ss_cam_400/synth/ms_tcam_reset_manager.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_tcam_mem_ss_cam_0/mem_ss_cam_400/synth/ms_tcam_regs_pkg.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_tcam_mem_ss_cam_0/mem_ss_cam_400/synth/ms_tcam_regs.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_tcam_mem_ss_cam_0/mem_ss_cam_400/synth/ms_tcam_prio.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_tcam_mem_ss_cam_0/mem_ss_cam_400/synth/ms_tcam_ppbb.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_tcam_mem_ss_cam_0/mem_ss_cam_400/synth/ms_tcam_pkg.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_tcam_mem_ss_cam_0/mem_ss_cam_400/synth/ms_tcam_div.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_tcam_mem_ss_cam_0/mem_ss_cam_400/synth/ms_tcam_dcfifo.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_tcam_mem_ss_cam_0/mem_ss_cam_400/synth/ms_tcam_core.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_tcam_mem_ss_cam_0/mem_ss_cam_400/synth/ms_tcam_clk_extender.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_tcam_mem_ss_cam_0/mem_ss_cam_400/synth/ms_tcam_axi_streaming.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_tcam_mem_ss_cam_0/mem_ss_cam_400/synth/ms_tcam_altera_std_synchronizer_nocut.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_tcam_mem_ss_cam_0/mem_ss_cam_400/synth/mem_ss_cam_top.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_parse_class/packet_switch_parse_class.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_parse_class/parse_class_l2l3l4.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_parse_class/parse_class_igr_intf.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_misc/packet_switch_pipe_dly.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_misc/packet_switch_ipbb_sfw_fifo.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_misc/packet_switch_ipbb_sdc_fifo_inff.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_misc/packet_switch_axi_lt_avmm.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_misc/packet_switch_avmm_addr_chk.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_misc/ipbb_sfw_fifo.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_misc/ipbb_scfifo_inff.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_misc/ipbb_pipe.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_misc/ipbb_axi_lite_to_avmm_range_check_cdc.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_misc/ipbb_axi_lite_to_avmm_range_check.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_misc/ipbb_asyn_to_syn_rst.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_lkup/packet_switch_lkup.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_lkup/lkup_tcam_intf.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_lkup/lkup_ccm.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_igr_arb/packet_switch_ipbb_pref_rrarb.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_igr_arb/packet_switch_igr_arb.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_igr_arb/ipbb_rrarb.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_igr_arb/ipbb_priority_rr.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_igr_arb/igr_arb_csr_intf.sv
set_global_assignment -name VERILOG_FILE         ../src/custom_rtl/packet_switch/packet_switch_igr_arb/igr_arb_csr.v
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_dmux/packet_switch_dma_ts_dmux.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_dmux/packet_switch_dma_rx_dmux.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_dmux/dma_rx_dmux_csr_intf.sv
set_global_assignment -name VERILOG_FILE         ../src/custom_rtl/packet_switch/packet_switch_dmux/dma_rx_dmux_csr.v
set_global_assignment -name VERILOG_FILE         ../src/custom_rtl/packet_switch/packet_switch_dbg_components/tx_dbg_csr.v
set_global_assignment -name VERILOG_FILE         ../src/custom_rtl/packet_switch/packet_switch_dbg_components/rx_dbg_csr.v
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_dbg_components/packet_switch_tx_dbg_cntr_intf.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_dbg_components/packet_switch_tx_dbg.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_dbg_components/packet_switch_tx_avmm_addr_chk.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_dbg_components/packet_switch_rx_dbg_cntr_intf.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_dbg_components/packet_switch_rx_dbg.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_dbg_components/packet_switch_rx_avmm_addr_chk.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_dbg_components/packet_switch_dbg_cntr.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_common/packet_switch_pkg.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/packet_switch/packet_switch_common/packet_switch_hdr_pkg.sv

set_global_assignment -name VERILOG_FILE       ../src/custom_ip/debounce/debounce.v
set_global_assignment -name VERILOG_FILE       ../src/custom_ip/reset_sync/altera_reset_synchronizer.v

set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/common/axis_if.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/common/sm_ptp_pkg.sv

set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/hssi_subsys/axi_avst_bridges/hssi_axist_to_avst_bridge_wrapper.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/hssi_subsys/axi_avst_bridges/axist_to_avst_bridge.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/hssi_subsys/axi_avst_bridges/avst_to_axist_rx_mac_seg_if.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/hssi_subsys/axi_avst_bridges/axist_to_avst_tx_mac_seg_if.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/hssi_subsys/axi_avst_bridges/hssi_ss_delay_reg.v
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/hssi_subsys/axi_avst_bridges/keep2empty.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/hssi_subsys/axi_avst_bridges/hssi_scfifo.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/hssi_subsys/srd_rst_ctrl/srd_rst_ctrl.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/hssi_subsys/srd_rst_ctrl/srd_rst_seq.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/hssi_subsys/srd_rst_ctrl/eth_f_altera_std_synchronizer_nocut.v
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/hssi_subsys/top/hssi_ss_top.sv

set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/user_space_csr/top_user_space_csr.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/user_space_csr/user_csr_space.v


set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/packet_client/eth_f_packet_client_csr_pkt_cnt.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/packet_client/axi4lite2avmm_bridge.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/packet_client/eth_f_packet_client_csr.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/packet_client/eth_f_pkt_stat_counter.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/packet_client/avmm_if.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/packet_client/eth_f_pkt_gen_dyn_25G.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/packet_client/eth_f_pkt_gen_dyn_100G.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/packet_client/eth_f_packet_client_top_axi_adaptor.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/packet_client/eth_f_packet_client_top.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/packet_client/eth_f_packet_client_data_check_25G.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/packet_client/eth_f_packet_client_data_check_100G.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/packet_client/avst_data_merger.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/packet_client/axi4lite_if.sv
set_global_assignment -name VERILOG_FILE       ../src/custom_rtl/packet_client/eth_f_multibit_sync.v
set_global_assignment -name VERILOG_FILE       ../src/custom_rtl/packet_client/eth_f_reset_synchronizer.v



set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/qsfp_contlr/qsfp_com.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/qsfp_contlr/i2c_init_done_check.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/qsfp_contlr/shadow_reg.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/qsfp_contlr/poller_fsm.sv
set_global_assignment -name SYSTEMVERILOG_FILE   ../src/custom_rtl/qsfp_contlr/qsfp_top.sv

set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/components_8chs/components_pkg.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/components_8chs/tx_dma_fifo.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/components_8chs/ts_pack.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/components_8chs/ts_chs_compl.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/components_8chs/s10_memory.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/components_8chs/rx_dma_fifo.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/components_8chs/period_bus_sync.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/components_8chs/parameter_scfifo.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/components_8chs/packet_mux_pd_8chs.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/components_8chs/packet_mux.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/components_8chs/packet_demux_pd_8chs.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/components_8chs/packet_demux.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/components_8chs/dc_fifo_param.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/components_8chs/clock_bus.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/components_8chs/cdc_toggle_synchronizer.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/components_8chs/cdc_synchronizer.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/components_8chs/cdc_packet_fifo.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/components_8chs/cdc_avmm_sync_v2.sv

set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/tod_subsys/intel_eth_gts_ptp_mtod_top.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../src/custom_rtl/tod_subsys/intel_eth_gts_ptp_stod_top.sv

set_global_assignment -name SYSTEMVERILOG_FILE ../src/top.sv
