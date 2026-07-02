
# ######################################################################## 
# Copyright (C) 2025 Altera Corporation.
# SPDX-License-Identifier: MIT
# ######################################################################## 
# -------------------------------------------------------------------------- #
set_time_format -unit ns -decimal_places 3

set qsfp_csr_clk soc_inst|iopll_0|iopll_csr_clk
set zl_clk l4_sp_clk_src

set hps_clk_grp      soc_inst|iopll_0|iopll_hps_clk
set hssi_clk_p0_grp  gen_mulit_inst[0].hssi_ss_top|u0|intel_eth_gts_0|sip_inst|ptp_tx_clkout
set hssi_clk_p1_grp  gen_mulit_inst[1].hssi_ss_top|u0|intel_eth_gts_0|sip_inst|ptp_tx_clkout
set dma_clk_grp      soc_inst|iopll_0|iopll_clk_150
set csr_clk_grp      soc_inst|iopll_0|iopll_csr_clk
set iopll_refclk_grp soc_inst|iopll_0|iopll_refclk
set tennm_refclk_grp soc_inst|iopll_0|iopll|tennm_ph2_iopll|ref_clk0
set tod_ppsclk_grp   todsync_sampl_pll|iopll_0_pps_sampling
set tod_samplclk_grp todsync_sampl_pll|iopll_0_refclk

set_clock_groups -asynchronous -group [get_clocks $hps_clk_grp] -group [get_clocks $hssi_clk_p0_grp]
set_clock_groups -asynchronous -group [get_clocks $hps_clk_grp] -group [get_clocks $hssi_clk_p1_grp]
set_clock_groups -asynchronous -group [get_clocks $dma_clk_grp] -group [get_clocks $hssi_clk_p0_grp]
set_clock_groups -asynchronous -group [get_clocks $dma_clk_grp] -group [get_clocks $hssi_clk_p1_grp]
set_clock_groups -asynchronous -group [get_clocks $csr_clk_grp] -group [get_clocks $hssi_clk_p0_grp]
set_clock_groups -asynchronous -group [get_clocks $csr_clk_grp] -group [get_clocks $hssi_clk_p1_grp]
set_clock_groups -asynchronous -group [get_clocks $hps_clk_grp] -group [get_clocks $dma_clk_grp]
set_clock_groups -asynchronous -group [get_clocks $hps_clk_grp] -group [get_clocks $iopll_refclk_grp]
set_clock_groups -asynchronous -group [get_clocks $tennm_refclk_grp] -group [get_clocks $hssi_clk_p0_grp]
set_clock_groups -asynchronous -group [get_clocks $tennm_refclk_grp] -group [get_clocks $hssi_clk_p1_grp]
set_clock_groups -asynchronous -group [get_clocks $tod_ppsclk_grp]   -group [get_clocks $tod_samplclk_grp]
set_clock_groups -asynchronous -group [get_clocks $tennm_refclk_grp] -group [get_clocks $dma_clk_grp]
set_clock_groups -asynchronous -group [get_clocks $csr_clk_grp] -group [get_clocks $iopll_refclk_grp]
set_clock_groups -asynchronous -group [get_clocks $tennm_refclk_grp] -group [get_clocks $csr_clk_grp]
set_clock_groups -asynchronous -group [get_clocks $hps_clk_grp] -group [get_clocks $tod_samplclk_grp]


set_input_delay   -source_latency_included 1 -clock $qsfp_csr_clk  [get_ports qsfp_i2c_sda]
set_output_delay  -source_latency_included 1 -clock $qsfp_csr_clk [get_ports qsfp_i2c_scl]
set_output_delay  -source_latency_included 1 -clock $qsfp_csr_clk  [get_ports {qsfpa_modeseln[*]}]
set_output_delay  -source_latency_included 1 -clock $qsfp_csr_clk  [get_ports {qsfpa_lpmode[*]}]
set_output_delay  -source_latency_included 1 -clock $qsfp_csr_clk  [get_ports {qsfpa_resetn[*]}]
set_output_delay  -source_latency_included 1 -clock $qsfp_csr_clk [get_ports {o_ptp_pps}]
set_input_delay   -source_latency_included 1 -clock $zl_clk [get_ports zl_i2c_sda]
set_output_delay  -source_latency_included 1 -clock $zl_clk  [get_ports zl_i2c_scl]

set_false_path -from [get_ports {qsfp_i2c_scl}] -to *
set_false_path -from * -to [get_ports {qsfp_i2c_scl}]
set_false_path -from [get_ports {zl_i2c_scl}] -to *
set_false_path -from * -to [get_ports {zl_i2c_scl}]
set_false_path -from [get_ports {qsfp_i2c_sda}] -to *
set_false_path -from * -to [get_ports {qsfp_i2c_sda}]
set_false_path -from [get_ports {zl_i2c_sda}] -to *
set_false_path -from * -to [get_ports {zl_i2c_sda}]
set_false_path -from [get_ports {qsfpa_modprsln[*]}] -to *
set_false_path -from [get_ports {intn_qsfp}] -to *
set_false_path -from * -to [get_ports {qsfpa_modeseln[*]}]
set_false_path -from * -to [get_ports {qsfpa_lpmode[*]}]
set_false_path -from * -to [get_ports {qsfpa_resetn[*]}]
set_false_path -from * -to [get_ports {o_ptp_pps}]
set_false_path -from * -to [get_ports {o_clk_rec_div_66}]
set_false_path -from * -to [get_ports {o_clk_rec_div_66(n)}]


