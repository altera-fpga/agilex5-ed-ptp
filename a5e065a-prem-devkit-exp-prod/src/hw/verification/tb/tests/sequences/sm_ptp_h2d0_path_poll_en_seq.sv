//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//########################################################################
// Description:
// Showcases the scenario where traffic is generated from all the channels of
// dma port port 0, with polling enabled for the prefetchers.
// This sequence enables prefetcher for all channels of DMA port 0.
// For each channel, the payload length for each eth packet is 64B
// Also, the packet switch are configured to route the packets to intended dma
// port. The key used is a unique combination of SA and DA of eth
// packet for each of the port channels

`ifndef SM_PTP_H2D0_PATH_POLL_EN_SEQ__SV
`define SM_PTP_H2D0_PATH_POLL_EN_SEQ__SV

class sm_ptp_h2d0_path_poll_en_seq extends sm_ptp_basic_seq;

  `uvm_object_utils(sm_ptp_h2d0_path_poll_en_seq)

  sm_ptp_basic_data_path_seq     seq_h;

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  function new(name = "sm_ptp_h2d0_path_poll_en_seq");
    super.new(name);
  endfunction: new

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task body();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] key [3];
    bit [47:0] sa [`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
    bit [47:0] da [`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];

    super.body();

    `uvm_info(get_full_name(), "config rules for dma port 0", UVM_LOW)
    key[0] = 'hdddd_dddd;
    key[1] = 'haaaa_dddd;
    key[2] = 'haaaa_aaaa;
`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
    configure_tcam0(1, key, 0);
`else
    configure_tcam1(1, key, 0);
`endif
    da[0][0] = {key[1][15:0], key[0][31:0]};
    sa[0][0] = {key[2][31:0], key[1][31:16]};
    key[0] = 'hcccc_cccc;
    key[1] = 'hbbbb_cccc;
    key[2] = 'hbbbb_bbbb;
`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
    configure_tcam0(2, key, 1);
`else
    configure_tcam1(2, key, 1);
`endif
    da[0][1] = {key[1][15:0], key[0][31:0]};
    sa[0][1] = {key[2][31:0], key[1][31:16]};

    `uvm_info(get_full_name(), "config dma port 0 to start traffic", UVM_LOW)
    `uvm_do_with(seq_h, {
                         h2d_en[0][0] == 1;
                         h2d_en[0][1] == 1;
                         h2d_en[1][0] == 0;
                         h2d_en[1][1] == 0;
`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
                         d2h_en[0][0] == 1;
                         d2h_en[0][1] == 1;
                         d2h_en[1][0] == 0;
                         d2h_en[1][1] == 0;
`else
                         d2h_en[0][0] == 0;
                         d2h_en[0][1] == 0;
                         d2h_en[1][0] == 1;
                         d2h_en[1][1] == 1;
`endif
                         h2d_poll_en[0][0] == 1;
                         h2d_poll_en[0][1] == 1;
                         h2d_poll_en[1][0] == 0;
                         h2d_poll_en[1][1] == 0;
`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
                         d2h_poll_en[0][0] == 1;
                         d2h_poll_en[0][1] == 1;
                         d2h_poll_en[1][0] == 0;
                         d2h_poll_en[1][1] == 0;
`else
                         d2h_poll_en[0][0] == 0;
                         d2h_poll_en[0][1] == 0;
                         d2h_poll_en[1][0] == 1;
                         d2h_poll_en[1][1] == 1;
`endif
                         foreach (sw_owned_h2d[i,j,k]) sw_owned_h2d[i][j][k] == 2;
                         foreach (sw_owned_d2h[i,j,k]) sw_owned_d2h[i][j][k] == 2;
                         foreach (num_of_h2d_desc[i,j]) num_of_h2d_desc[i][j] == 5;
                         foreach (num_of_d2h_desc[i,j]) num_of_d2h_desc[i][j] == 5;
                         foreach (h2d_pyld_len[i,j,k])
                           h2d_pyld_len[i][j][k] == 64;
                         foreach (dma_da[i,j]) dma_da[i][j] == da[i][j];
                         foreach (dma_sa[i,j]) dma_sa[i][j] == sa[i][j];
                        })
    `uvm_info(get_full_name(), "config done dma port 0 to start traffic", UVM_LOW)
    poll_eth_stats();
  endtask: body
endclass: sm_ptp_h2d0_path_poll_en_seq

`endif // SM_PTP_H2D0_PATH_POLL_EN_SEQ__SV
