//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//########################################################################
// Description:
// Showcases the scenario where traffic is generated from all the dma ports
// and user clinet 0 port simultaneously
// This sequence enables prefetcher for all channels of both ports 1 and 2
// of DMA. For each channel, the number of descriptors and payload length is random.
// user client 0 is enabled to generate random number of packets
// Also, the packet switch are configured to route the packets to intended dma
// and user port. The key used is SA and DA of ether packet

`ifndef SM_PTP_ALL_DMA_USER0_PATH_SEQ__SV
`define SM_PTP_ALL_DMA_USER0_PATH_SEQ__SV

class sm_ptp_all_dma_user0_path_seq extends sm_ptp_basic_seq;

  `uvm_object_utils(sm_ptp_all_dma_user0_path_seq)

  sm_ptp_basic_data_path_seq     seq_h;

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  function new(name = "sm_ptp_all_dma_user0_path_seq");
    super.new(name);
  endfunction: new

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task body();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] key [3];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] sa [`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] da [`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] user_sa [`SM_PTP_MAX_PORTS];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] user_da [`SM_PTP_MAX_PORTS];
    int num_pkts;
    bit fxd_gap;
    bit [1:0] mode;
    bit [7:0] idle_cycles;

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

    key[0] = 'hbbbb_bbbb;
    key[1] = 'haaaa_bbbb;
    key[2] = 'haaaa_aaaa;
`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
    configure_tcam0(3, key, 8);
`else
    configure_tcam1(3, key, 8);
`endif
    user_da[0] = {key[1][15:0], key[0][31:0]};
    user_sa[0] = {key[2][31:0], key[1][31:16]};

    if (!std::randomize(num_pkts, fxd_gap, mode, idle_cycles) with {
                                num_pkts inside {[100:500]};
                                fxd_gap inside {0, 1};
                                mode inside {2'b01, 2'b10};
                                idle_cycles inside {[8:16]};
                               })
      `uvm_error(get_full_name(), "std:: randomize call failed...")

    fork
      begin
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
                             foreach (h2d_poll_en[i,j]) h2d_poll_en[i][j] == 0;
                             foreach (d2h_poll_en[i,j]) d2h_poll_en[i][j] == 0;
                             foreach (dma_da[i,j]) dma_da[i][j] == da[i][j];
                             foreach (dma_sa[i,j]) dma_sa[i][j] == sa[i][j];
                            })
        `uvm_info(get_full_name(), "config done dma port 0 to start traffic", UVM_LOW)
      end
      begin
        wait (seq_h.csr_cfg_done == 1);
        `uvm_info(get_full_name(), "config pkt client0 to start traffic", UVM_LOW)
        configure_pkt_client0(
                .sa(user_sa[0]), .da(user_da[0]), .num_pkts(num_pkts), .soft_rst(0),
                .fxd_gap(fxd_gap), .len_mode(mode), .idle_cycles(idle_cycles)
        );
        `uvm_info(get_full_name(), "config done pkt client0 to start traffic", UVM_LOW)
      end
    join

    wait_for_pkts_to_complete(0, num_pkts);
    `uvm_info(get_full_name(), "Read pkt client perf stats", UVM_LOW)
    read_pkt_client_perf_stats(0);
`ifndef SM_PTP_PORT_LEVEL_LOOPBACK
    read_pkt_client_perf_stats(1);
`endif
    
    match_sop_eop(0);
    poll_eth_stats();
  endtask: body
endclass: sm_ptp_all_dma_user0_path_seq

`endif // SM_PTP_ALL_DMA_USER0_PATH_SEQ__SV
