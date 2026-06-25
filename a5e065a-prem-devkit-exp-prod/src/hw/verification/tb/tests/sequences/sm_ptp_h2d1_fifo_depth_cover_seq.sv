//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//########################################################################
// Description:
// Showcases the scenario where traffic is generated from all the channels of
// dma port port 1 such that the Tx/Rx FIFO depth is exercised
// This sequence enables prefetcher for all channels of DMA port 1.
// For each channel, the number of descriptors is 180 and the payload length
// for each eth packet is 1500B.
// Also, the packet switch are configured to route the packets to intended dma
// port. The key used is a unique combination of SA and DA of eth
// packet for each of the port channels

`ifndef SM_PTP_H2D1_FIFO_DEPTH_COVER_SEQ__SV
`define SM_PTP_H2D1_FIFO_DEPTH_COVER_SEQ__SV

class sm_ptp_h2d1_fifo_depth_cover_seq extends sm_ptp_basic_seq;


  `uvm_object_utils(sm_ptp_h2d1_fifo_depth_cover_seq)

  sm_ptp_basic_data_path_seq     seq_h;

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  function new(name = "sm_ptp_h2d1_fifo_depth_cover_seq");
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
    configure_tcam1(1, key, 0);
`else
    configure_tcam0(1, key, 0);
`endif
    da[1][0] = {key[1][15:0], key[0][31:0]};
    sa[1][0] = {key[2][31:0], key[1][31:16]};
    key[0] = 'hcccc_cccc;
    key[1] = 'hbbbb_cccc;
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
                         h2d_en[0][0] == 0;
                         h2d_en[0][1] == 0;
                         h2d_en[1][0] == 1;
                         h2d_en[1][1] == 1;
`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
                         d2h_en[0][0] == 0;
                         d2h_en[0][1] == 0;
                         d2h_en[1][0] == 1;
                         d2h_en[1][1] == 1;
`else
                         d2h_en[0][0] == 1;
                         d2h_en[0][1] == 1;
                         d2h_en[1][0] == 0;
                         d2h_en[1][1] == 0;
`endif
                         foreach (num_of_h2d_desc[i,j]) num_of_h2d_desc[i][j] == 180;
                         foreach (num_of_d2h_desc[i,j]) num_of_h2d_desc[i][j] == 180;
                         foreach (h2d_pyld_len[i,j,k])
                           h2d_pyld_len[i][j][k] == 1500;
                         foreach (d2h_pyld_len[i,j,k])
                           d2h_pyld_len[i][j][k] == 1500;
                         foreach (h2d_poll_en[i,j]) h2d_poll_en[i][j] == 0;
                         foreach (d2h_poll_en[i,j]) d2h_poll_en[i][j] == 0;
                         foreach (dma_da[i,j]) dma_da[i][j] == da[i][j];
                         foreach (dma_sa[i,j]) dma_sa[i][j] == sa[i][j];
                        })
  endtask: body
endclass: sm_ptp_h2d1_fifo_depth_cover_seq

`endif // SM_PTP_H2D1_FIFO_DEPTH_COVER_SEQ__SV
