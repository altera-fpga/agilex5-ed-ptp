//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//########################################################################
// Description:
// This sequence showcases transactions from user client 1
// The user client 1 is configured to generate random number of ethernet
// packets.
// Also, the packet switch are configured to route the packets to intended
// user port. The key used is a unique combination of SA and DA of eth
// packet for each of the ports

`ifndef SM_PTP_USER1_SEQ__SV
`define SM_PTP_USER1_SEQ__SV

class sm_ptp_user1_seq extends sm_ptp_basic_seq;
    
  `uvm_object_utils(sm_ptp_user1_seq)

  function new (string name = "sm_ptp_user1_seq");
   super.new(name);
  endfunction : new

    
  task body();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] key [3];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] sa [`SM_PTP_MAX_PORTS];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] da [`SM_PTP_MAX_PORTS];
    int num_pkts;
    bit fxd_gap;
    bit [1:0] mode;
    bit [7:0] idle_cycles;
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data [];
    bit [`SVT_AXI_WSTRB_WIDTH-1:0]    wstrb [];

    super.body();

    `uvm_info(get_full_name(), "Body: Entered...", UVM_DEBUG)

    key[0] = 'hcccc_cccc;
    key[1] = 'hbbbb_cccc;
    key[2] = 'hbbbb_bbbb;
`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
    configure_tcam1(2, key, 8);
`else
    configure_tcam0(2, key, 8);
`endif
    da[1] = {key[1][15:0], key[0][31:0]};
    sa[1] = {key[2][31:0], key[1][31:16]};

    if (!std::randomize(num_pkts, fxd_gap, mode, idle_cycles) with {
                                num_pkts inside {[100:500]};
                                fxd_gap inside {0, 1};
                                mode inside {2'b01, 2'b10};
                                idle_cycles inside {[8:16]};
                               })
      `uvm_error(get_full_name(), "std:: randomize call failed...")

    configure_pkt_client1(
            .sa(sa[1]), .da(da[1]), .num_pkts(num_pkts), .soft_rst(0),
            .fxd_gap(fxd_gap), .len_mode(mode), .idle_cycles(idle_cycles)
    );
  
    data = new[1];
    wstrb = new[1];
        
    wstrb[0] = 'hf;
    data[0]  = 0;
    data[0][4] = 'h1;
    data[0][5] = 'h1;
    axi_master_write(
            .address(`SM_PTP_PKTCLI0_CFG_PKT_CL_CTRL),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(data), .burst_length(1), .wstrb(wstrb));

    wait_for_pkts_to_complete(1, num_pkts);
    read_pkt_client_perf_stats(1);
`ifndef SM_PTP_PORT_LEVEL_LOOPBACK
    read_pkt_client_perf_stats(0);
`endif
    match_sop_eop(1);
    poll_eth_stats();
    `uvm_info(get_full_name(), "Body: CFG PKT CLIENT0 ENDS...", UVM_DEBUG)
  endtask: body
endclass:sm_ptp_user1_seq 

`endif
