//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//########################################################################

// Base sqeuences
`include "axi_base_sequence_pkg.sv"
`include "sm_ptp_null_virtual_seq.sv"
`include "sm_ptp_simple_reset_seq.sv"
`include "sm_ptp_axi_master_base_seq.sv"
`include "sm_ptp_basic_seq.sv"
`include "sm_ptp_msgdma_cfg_seq.sv"
`include "sm_ptp_axi_slave_host_response_seq.sv"
`include "sm_ptp_basic_data_path_seq.sv"
// DMA only port 0 -> 1 sequences
// In 1 channel DUT, port 0 -> 0 loopback is tested
`include "sm_ptp_h2d0_90B_seq.sv"

// // Both DMA ports enabled sequences
`include "sm_ptp_all_dma_ports_64B_traffic_seq.sv"

// user client sequences
`include "sm_ptp_user1_user0_seq.sv"

// DMA and user client enabled sequences
`include "sm_ptp_all_ports_traffic_seq.sv"

// CSR sequences
`include "sm_ptp_hssi_csr_seq.sv"
