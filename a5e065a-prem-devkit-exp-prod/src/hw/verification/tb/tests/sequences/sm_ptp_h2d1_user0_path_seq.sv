//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//########################################################################
// Description:
// Showcases the scenario where traffic is generated from all the channels of
// dma port port 1 and user client 0 simultaneously.
// This sequence enables prefetcher for all channels of DMA port 1.
// For each channel, the payload length for each eth packet is random.
// User client 0 is configured to generate random number of eth packets
// Also, the packet switch are configured to route the packets to intended dma
// port. The key used is a unique combination of SA and DA of eth
// packet for each of the port channels

`ifndef SM_PTP_H2D1_USER0_PATH_SEQ__SV
`define SM_PTP_H2D1_USER0_PATH_SEQ__SV

class sm_ptp_h2d1_user0_path_seq extends sm_ptp_basic_seq;


  `uvm_object_utils(sm_ptp_h2d1_user0_path_seq)

  sm_ptp_basic_data_path_seq     seq_h;

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  function new(name = "sm_ptp_h2d1_user0_path_seq");
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

    `uvm_info(get_full_name(), "config rules for user client ", UVM_LOW)
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
                             foreach (h2d_poll_en[i,j]) h2d_poll_en[i][j] == 0;
                             foreach (d2h_poll_en[i,j]) d2h_poll_en[i][j] == 0;
                             foreach (dma_da[i,j]) dma_da[i][j] == da[i][j];
                             foreach (dma_sa[i,j]) dma_sa[i][j] == sa[i][j];
                            })
        `uvm_info(get_full_name(), "config done dma port 0 to start traffic", UVM_LOW)
      end
      begin
        bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data [];
        bit [`SVT_AXI_WSTRB_WIDTH-1:0]    wstrb [];
  
        data = new[1];
        wstrb = new[1];

        wait (seq_h.csr_cfg_done == 1);
        `uvm_info(get_full_name(), "config pkt client0 to start traffic", UVM_LOW)
        configure_pkt_client0(
                .sa(user_sa[0]), .da(user_da[0]), .num_pkts(num_pkts), .soft_rst(0),
                .fxd_gap(fxd_gap), .len_mode(mode), .idle_cycles(idle_cycles)
        );
        `uvm_info(get_full_name(), "config done pkt client0 to start traffic", UVM_LOW)
        
        wstrb[0] = 'hf;
        data[0]  = 0;
        data[0][4] = 'h1;
        data[0][5] = 'h1;
        axi_master_write(
                .address(`SM_PTP_PKTCLI1_CFG_PKT_CL_CTRL),
                .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                .data(data), .burst_length(1), .wstrb(wstrb));
      end
    join

    wait_for_pkts_to_complete(0, num_pkts);
    match_sop_eop(0);
    `uvm_info(get_full_name(), "Read pkt client 0 perf stats", UVM_LOW)
    read_pkt_client_perf_stats(0);
`ifndef SM_PTP_PORT_LEVEL_LOOPBACK
    read_pkt_client_perf_stats(1);
`endif
    poll_eth_stats();
  endtask: body
endclass: sm_ptp_h2d1_user0_path_seq

`endif // SM_PTP_H2D1_USER0_PATH_SEQ__SV
