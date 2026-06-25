//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//########################################################################
// Description:
// Showcases the scenario where traffic is generated from all the dma ports
// and user client  ports simultaneously
// This sequence enables prefetcher for all channels of both ports 1 and 2
// of DMA. For each channel, the payload length for each eth packet is 90B.
// user client 0 and 1 are enabled to generate random number of packets
// Also, the packet switch are configured to route the packets to intended dma
// and user port. The key used is a unique combination of SA and DA of eth
// packet for each of the ports

`ifndef SM_PTP_ALL_PORTS_TRAFFIC_90B_SEQ__SV
`define SM_PTP_ALL_PORTS_TRAFFIC_90B_SEQ__SV

class sm_ptp_all_ports_traffic_90B_seq extends sm_ptp_basic_seq;

  `uvm_object_utils(sm_ptp_all_ports_traffic_90B_seq)

  sm_ptp_basic_data_path_seq     seq_h;

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  function new(name = "sm_ptp_all_ports_traffic_90B_seq");
    super.new(name);
  endfunction: new

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task body();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] key [3];
    bit [47:0] sa [`SM_PTP_MAX_CHANNELS];
    bit [47:0] da [`SM_PTP_MAX_CHANNELS];

    super.body();

    `uvm_info(get_full_name(), "config rules for dma port ", UVM_LOW)
`ifdef NUM_CHANNELS_2
    //---------------------------------------------------
    // KEY is 5555 and  DMA DATA is dddd
    key[0] = 'h5555_5555;
    key[1] = 'h8888_5555;
    key[2] = 'h8888_8888;
    configure_tcam0(1, key, 0);
    key[0] = 'hdddd_dddd;
    key[1] = 'haaaa_dddd;
    key[2] = 'haaaa_aaaa;
    da[0] = {key[1][15:0], key[0][31:0]};
    sa[0] = {key[2][31:0], key[1][31:16]};
    //---------------------------------------------------

    //---------------------------------------------------
    // KEY is CCCC and  DMA DATA is 4444
    key[0] = 'hcccc_cccc;
    key[1] = 'hbbbb_cccc;
    key[2] = 'hbbbb_bbbb;
    configure_tcam0(2, key, 1);
    key[0] = 'h4444_4444;
    key[1] = 'h7777_4444;
    key[2] = 'h7777_7777;
    da[1] = {key[1][15:0], key[0][31:0]};
    sa[1] = {key[2][31:0], key[1][31:16]};
    //---------------------------------------------------


    //---------------------------------------------------
    // KEY is 4444 and  DMA DATA is cccc
    key[0] = 'h4444_4444;
    key[1] = 'h7777_4444;
    key[2] = 'h7777_7777;
    configure_tcam1(1, key, 0);
    key[0] = 'hcccc_cccc;
    key[1] = 'hbbbb_cccc;
    key[2] = 'hbbbb_bbbb;
    da[2] = {key[1][15:0], key[0][31:0]};
    sa[2] = {key[2][31:0], key[1][31:16]};
    //---------------------------------------------------

    //---------------------------------------------------
    // KEY is dddd and  DMA DATA is 5555
    key[0] = 'hdddd_dddd;
    key[1] = 'haaaa_dddd;
    key[2] = 'haaaa_aaaa;
    configure_tcam1(2, key, 1);
    key[0] = 'h5555_5555;
    key[1] = 'h8888_5555;
    key[2] = 'h8888_8888;
    da[3] = {key[1][15:0], key[0][31:0]};
    sa[3] = {key[2][31:0], key[1][31:16]};
    //---------------------------------------------------
`else
    key[0] = 'hdddd_dddd;
    key[1] = 'haaaa_dddd;
    key[2] = 'haaaa_aaaa;
    configure_tcam0(1, key, 0);
    da[0] = {key[1][15:0], key[0][31:0]};
    sa[0] = {key[2][31:0], key[1][31:16]};
`endif

    `uvm_info(get_full_name(), "config dma port to start traffic", UVM_LOW)
    `uvm_do_with(seq_h, {
                         h2d_en == 4'b1111;
                         d2h_en == 4'b1111;
                         foreach (num_of_h2d_desc[i]) num_of_h2d_desc[i] == 4;
                         foreach (num_of_d2h_desc[i]) num_of_d2h_desc[i] == 4;
                         foreach (h2d_pyld_len[i])
                           foreach (h2d_pyld_len[i][j])
                             h2d_pyld_len[i][j] == 90;
                         foreach (d2h_pyld_len[i])
                           foreach (d2h_pyld_len[i][j])
                             d2h_pyld_len[i][j] == 90;
                         h2d_poll_en == 0;
                         d2h_poll_en == 0;
                         foreach (dma_da[i]) dma_da[i] == da[i];
                         foreach (dma_sa[i]) dma_sa[i] == sa[i];
                        })
    poll_eth_stats();
  endtask: body
endclass: sm_ptp_all_ports_traffic_90B_seq

`endif // SM_PTP_ALL_PORTS_TRAFFIC_90B_SEQ__SV
