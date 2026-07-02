//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//########################################################################
// Description:
// This sequence enables prefetcher for all channels of both ports 1 and 2
// of DMA. For each channel, fixed number of descriptors are configured with
// 64B payload length for each.
// Also, the packet switch are configured to route the packets to intended dma
// port. The key used is SA and DA of ether packet

`ifndef SM_PTP_ALL_DMA_PORTS_64B_TRAFFIC_SEQ__SV
`define SM_PTP_ALL_DMA_PORTS_64B_TRAFFIC_SEQ__SV

class sm_ptp_all_dma_ports_64B_traffic_seq extends sm_ptp_basic_seq;

  `uvm_object_utils(sm_ptp_all_dma_ports_64B_traffic_seq)

  sm_ptp_basic_data_path_seq     seq_h;

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  function new(name = "sm_ptp_all_dma_ports_64B_traffic_seq");
    super.new(name);
  endfunction: new

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task body();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] key [3];
    bit [47:0] sa [`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
    bit [47:0] da [`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];

    super.body();

    `uvm_info(get_full_name(), "config rules for dma port ", UVM_LOW)
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

    key[0] = 'heeee_eeee;
    key[1] = 'haaaa_eeee;
    key[2] = 'haaaa_aaaa;
`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
    configure_tcam1(1, key, 0);
`else
    configure_tcam0(1, key, 0);
`endif
    da[1][0] = {key[1][15:0], key[0][31:0]};
    sa[1][0] = {key[2][31:0], key[1][31:16]};
    key[0] = 'hffff_ffff;
    key[1] = 'hbbbb_ffff;
    key[2] = 'hbbbb_bbbb;
`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
    configure_tcam1(2, key, 1);
`else
    configure_tcam0(2, key, 1);
`endif
    da[1][1] = {key[1][15:0], key[0][31:0]};
    sa[1][1] = {key[2][31:0], key[1][31:16]};

    `uvm_info(get_full_name(), "config dma port to start traffic", UVM_LOW)
    `uvm_do_with(seq_h, {
                         h2d_en[0][0] == 1;
                         h2d_en[0][1] == 1;
                         h2d_en[1][0] == 1;
                         h2d_en[1][1] == 1;
                         d2h_en[0][0] == 1;
                         d2h_en[0][1] == 1;
                         d2h_en[1][0] == 1;
                         d2h_en[1][1] == 1;
                         foreach (num_of_h2d_desc[i,j]) num_of_h2d_desc[i][j] == 4;
                         foreach (num_of_d2h_desc[i,j]) num_of_d2h_desc[i][j] == 4;
                         foreach (h2d_pyld_len[i,j,k])
                           h2d_pyld_len[i][j][k] == 64;
                         foreach (d2h_pyld_len[i,j,k])
                           d2h_pyld_len[i][j][k] == 64;
                         foreach (h2d_poll_en[i,j]) h2d_poll_en[i][j] == 0;
                         foreach (d2h_poll_en[i,j]) d2h_poll_en[i][j] == 0;
                         foreach (dma_da[i,j]) dma_da[i][j] == da[i][j];
                         foreach (dma_sa[i,j]) dma_sa[i][j] == sa[i][j];
                        })
    poll_eth_stats();
  endtask: body
endclass: sm_ptp_all_dma_ports_64B_traffic_seq

`endif // SM_PTP_ALL_DMA_PORTS_64B_TRAFFIC_SEQ__SV
