//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//########################################################################

`ifndef SM_PTP_RANDOM_SEQ__SV
`define SM_PTP_RANDOM_SEQ__SV

class sm_ptp_random_seq extends sm_ptp_basic_seq;

  `uvm_object_utils(sm_ptp_random_seq)

  sm_ptp_basic_data_path_seq     seq_h;

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  function new(name = "sm_ptp_random_seq");
    super.new(name);
  endfunction: new

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task body();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] key [3];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] sa [2];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] da [2];
    int pkt_count;

    super.body();

    `uvm_info(get_full_name(), "config rules for user client 0", UVM_LOW)
    key[0] = 'heeee_eeee;
    key[1] = 'hbbbb_eeee;
    key[2] = 'hbbbb_bbbb;
    configure_tcam0(1, key, 8);

    `uvm_info(get_full_name(), "config rules for dma port 0", UVM_LOW)
    key[0] = 'hdddd_dddd;
    key[1] = 'haaaa_dddd;
    key[2] = 'haaaa_aaaa;
    configure_tcam0(2, key, 0);

    fork
      begin
        `uvm_info(get_full_name(), "config dma port 0 to start traffic", UVM_LOW)
        `uvm_do_with(seq_h, {
                            })
        `uvm_info(get_full_name(), "config done dma port 0 to start traffic", UVM_LOW)
      end
      begin
        std::randomize(pkt_count) with {pkt_count inside {[10:500]};};

        wait (seq_h.csr_cfg_done == 1);
        `uvm_info(get_full_name(), "config pkt client0 to start traffic", UVM_LOW)
        da[0] = 'hEEEE_EEEE;
        da[1] = 'hEEEE;
        sa[0] = 'hBBBB_BBBB;
        sa[1] = 'hBBBB;
        configure_pkt_client0(sa, da, pkt_count);
        `uvm_info(get_full_name(), "config done pkt client0 to start traffic", UVM_LOW)
      end
    join

    wait_for_pkts_to_complete(0, pkt_count);
    `uvm_info(get_full_name(), "Read pkt client perf stats", UVM_LOW)
    read_pkt_client0_perf_stats();
    match_sop_eop(0);
    poll_eth_stats();
  endtask: body

endclass: sm_ptp_random_seq

`endif // SM_PTP_RANDOM_SEQ__SV
