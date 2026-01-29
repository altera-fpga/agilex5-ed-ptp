//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//########################################################################
// Description:
// This sequence is the basic sequence used to derive all other sequences.
// This sequence also contains definitions of various tasks that are utilised
// in all child sequences

`ifndef SM_PTP_BASIC_SEQ__SV
`define SM_PTP_BASIC_SEQ__SV

class sm_ptp_basic_seq extends uvm_sequence;
  `uvm_declare_p_sequencer(svt_axi_system_sequencer)

  sm_ptp_axi_master_base_seq mst_seq;

  `uvm_object_utils(sm_ptp_basic_seq)

  logic [30:0] tx_port0_const_delay;
  logic        tx_port0_const_delay_sign;
  logic [30:0] tx_port0_apulse_offset;
  logic        tx_port0_apulse_offset_sign;
  logic [19:0] tx_port0_apulse_wdelay;
  logic [28:0] tx_port0_apulse_time;
  logic [31:0] tx_port0_tam_adjust;
  logic [31:0] tx_port0_tam_adjust_2c;
  logic [31:0] tx_port0_extra_latency;

  logic [30:0] rx_port0_const_delay;
  logic        rx_port0_const_delay_sign;
  logic [30:0] rx_port0_apulse_offset;
  logic        rx_port0_apulse_offset_sign;
  logic [19:0] rx_port0_apulse_wdelay;
  logic [28:0] rx_port0_apulse_time;
  logic [31:0] rx_port0_tam_adjust;
  logic [31:0] rx_port0_tam_adjust_2c;
  logic [31:0] rx_port0_extra_latency;

  logic [30:0] tx_port1_const_delay;
  logic        tx_port1_const_delay_sign;
  logic [30:0] tx_port1_apulse_offset;
  logic        tx_port1_apulse_offset_sign;
  logic [19:0] tx_port1_apulse_wdelay;
  logic [28:0] tx_port1_apulse_time;
  logic [31:0] tx_port1_tam_adjust;
  logic [31:0] tx_port1_tam_adjust_2c;
  logic [31:0] tx_port1_extra_latency;
				  
  logic [30:0] rx_port1_const_delay;
  logic        rx_port1_const_delay_sign;
  logic [30:0] rx_port1_apulse_offset;
  logic        rx_port1_apulse_offset_sign;
  logic [19:0] rx_port1_apulse_wdelay;
  logic [28:0] rx_port1_apulse_time;
  logic [31:0] rx_port1_tam_adjust;
  logic [31:0] rx_port1_tam_adjust_2c;
  logic [31:0] rx_port1_extra_latency;

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  function new(name = "sm_ptp_basic_seq");
    super.new(name);
  endfunction: new

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  virtual task body();
    super.body();

    wait_for_eth_ready();
    // --------------------------------------------------------------------
    wait_for_data_offset_valid();
    ptp_tx_initialise();
    ptp_rx_initialise();
    notify_soft_ptp_user_cfg_done();
    wait_for_ptp_ready();
    // --------------------------------------------------------------------
    enable_user_client_chkr(0);
    enable_user_client_chkr(1);
  endtask: body

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task wait_for_eth_ready();
    `uvm_info(get_full_name(), "poll for eth ready...", UVM_LOW)
    // replace with polling through RAL status csr
    wait ((`SM_PTP_HSSI_SS0_PATH.o_tx_lanes_stable === 1) && (`SM_PTP_HSSI_SS0_PATH.o_rx_pcs_ready === 1));
    if (`SM_PTP_NUM_PORTS == 2)
      wait ((`SM_PTP_HSSI_SS1_PATH.o_tx_lanes_stable === 1) && (`SM_PTP_HSSI_SS1_PATH.o_rx_pcs_ready === 1));
    `uvm_info(get_full_name(), "eth is ready", UVM_LOW)
  endtask: wait_for_eth_ready

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task axi_master_write(
    bit [`SVT_AXI_MAX_ADDR_WIDTH-1:0]        address,
    svt_axi_transaction::burst_size_enum     burst_sz,
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0]        data [],
    bit [`SVT_AXI_MAX_BURST_LENGTH_WIDTH:0]  burst_length,
    bit [`SVT_AXI_WSTRB_WIDTH-1:0] 	         wstrb []
  );

    `uvm_create_on(mst_seq, p_sequencer.master_sequencer[0])

    if (!mst_seq.randomize() with {
            addr == address; // 'h100;
            xact_type == svt_axi_transaction::WRITE;
            burst_size == burst_sz; // svt_axi_transaction::BURST_SIZE_32BIT;
    }) `uvm_error(get_full_name(), "Randomization failure...")
    else begin
      mst_seq.burst_length = burst_length;
      mst_seq.data  = new[mst_seq.burst_length];
      mst_seq.wstrb = new[mst_seq.burst_length];
      foreach (mst_seq.data[i]) mst_seq.data[i] = data[i];
      foreach (mst_seq.wstrb[i]) mst_seq.wstrb[i] = wstrb[i];
      `uvm_info(get_full_name(),
                $sformatf(" mst_seq randomized with addr %0d\nxact_type %0s",
                            mst_seq.addr, mst_seq.xact_type),
                UVM_DEBUG)
      `uvm_info(get_full_name(), "Body: req is randomized", UVM_MEDIUM)
    end

    `uvm_send(mst_seq)
  endtask: axi_master_write

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task axi_master_read(
    bit [`SVT_AXI_MAX_ADDR_WIDTH-1:0]        address,
    svt_axi_transaction::burst_size_enum     burst_sz,
    bit [`SVT_AXI_MAX_BURST_LENGTH_WIDTH:0]  burst_length,
    output bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data []
  );

    `uvm_create_on(mst_seq, p_sequencer.master_sequencer[0])

    if (!mst_seq.randomize() with {
            addr == address; // 'h100;
            xact_type == svt_axi_transaction::READ;
            burst_size == burst_sz; // svt_axi_transaction::BURST_SIZE_32BIT;
    }) `uvm_error(get_full_name(), "Randomization failure...")
    else begin
      mst_seq.burst_length = burst_length;
      `uvm_info(get_full_name(),
                $sformatf(" mst_seq randomized with addr %0d\nxact_type %0s",
                            mst_seq.addr, mst_seq.xact_type),
                UVM_DEBUG)
      `uvm_info(get_full_name(), "Body: req is randomized", UVM_DEBUG)
    end

    `uvm_send(mst_seq)

    $display($time, "wait for response object to be fetched");
    wait (mst_seq.rsp !== null);
    `uvm_info(get_full_name(),
              $sformatf(" print response object \n%s", mst_seq.rsp.sprint()),
              UVM_LOW
             )
    data = mst_seq.rsp.data;

  endtask: axi_master_read

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task poll_eth_stats();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data [];

    for (int addr = 'h4035_0334; addr < 'h4035_0454; addr = addr+4) begin
      axi_master_read(
              .address(addr),
              .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
              .burst_length(1), .data(data)
      );
      `uvm_info(get_full_name(),
                $sformatf("rx stat: addr = %0h, data = %0h", addr, data[0]),
                UVM_LOW)
    end

    for (int addr = 'h4035_0200; addr < 'h4035_0330; addr = addr+4) begin
      axi_master_read(
              .address(addr),
              .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
              .burst_length(1), .data(data)
      );
      `uvm_info(get_full_name(),
                $sformatf("tx stat: addr = %0h, data = %0h", addr, data[0]),
                UVM_LOW)
    end
  endtask

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task configure_tcam0(
          int entry,
          bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] key [3],
          int egr_port
  );
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data [];
    bit [`SVT_AXI_WSTRB_WIDTH-1:0]    wstrb [];
  
    data = new[1];
    wstrb = new[1];
    wstrb[0] = 'hf;
          
    // TCAM Entry at 0030
    data[0] = entry;
    axi_master_write(
             .address(`SM_PTP_BRIDGE_TCAM0_CSR_BASE +'h30),
             .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
             .data(data), .burst_length(1), .wstrb(wstrb)
    );

    // Key register
    data[0] = key[0];
    axi_master_write(
             .address(`SM_PTP_BRIDGE_TCAM0_KEY_CSR_ADDR),
             .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
             .data(data), .burst_length(1), .wstrb(wstrb)
    );

    data[0] = key[1];
    axi_master_write(
             .address(`SM_PTP_BRIDGE_TCAM0_KEY_CSR_ADDR+4),
             .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
             .data(data), .burst_length(1), .wstrb(wstrb)
    );

    data[0] = key[2];
    axi_master_write(
             .address(`SM_PTP_BRIDGE_TCAM0_KEY_CSR_ADDR+8),
             .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
             .data(data), .burst_length(1), .wstrb(wstrb)
    );

    // Result register
    data[0] = egr_port;
    axi_master_write(
             .address(`SM_PTP_BRIDGE_TCAM0_RESULT_CSR_ADDR),
             .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
             .data(data), .burst_length(1), .wstrb(wstrb)
    );

    // Mask register
    for (int i=0; i<16; i=i+1) begin
      if (i < 3) begin
        data[0] = 'hFFFF_FFFF;
        axi_master_write(
                 .address(`SM_PTP_BRIDGE_TCAM0_MASK_CSR_ADDR+(i*4)),
                 .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                 .data(data), .burst_length(1), .wstrb(wstrb)
        );
      end else begin
        data[0] = 'h0;
        axi_master_write(
                 .address(`SM_PTP_BRIDGE_TCAM0_MASK_CSR_ADDR+(i*4)),
                 .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                 .data(data), .burst_length(1), .wstrb(wstrb)
        );
      end
    end

    // Checking whether the Entry successful or not
    data = new[1];
    data[0][31]=1;
    while (data[0][31]) begin
      #20ns;
      axi_master_read(
              .address(`SM_PTP_BRIDGE_TCAM0_CSR_BASE +'h20),
              .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
              .burst_length(1), .data(data)
      );
      if (!data[0][31])
        `uvm_info(get_full_name(), "TCAM0 IS NOT BUSY..", UVM_DEBUG)
      else
        `uvm_info(get_full_name(), "TCAM0 IS BUSY..", UVM_DEBUG)
    end

    // Insert the entry using Mgmt_ctrl register
    data[0] = 1;
    axi_master_write (
             .address(`SM_PTP_BRIDGE_TCAM0_CSR_BASE +'h20),
             .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
             .data(data), .burst_length(1), .wstrb(wstrb)
    );

    // Checking whether the Entry successful or not
    while (!data[0][8]) begin
      #20ns;
      axi_master_read(
              .address(`SM_PTP_BRIDGE_TCAM0_CSR_BASE +'h20),
              .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
              .burst_length(1), .data(data)
      );
      if (data[0][8])
        `uvm_info(get_full_name(), "INSERT KEY IS  SUCCESSFULL..", UVM_DEBUG)
    end
  endtask: configure_tcam0

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task configure_tcam1(
          int entry,
          bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] key [3],
          int egr_port
  );
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data [];
    bit [`SVT_AXI_WSTRB_WIDTH-1:0]    wstrb [];
  
    data = new[1];
    wstrb = new[1];
    wstrb[0] = 'hf;
          
    // TCAM Entry at 0030
    data[0] = entry;
    axi_master_write(
             .address(`SM_PTP_BRIDGE_TCAM1_CSR_BASE +'h30),
             .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
             .data(data), .burst_length(1), .wstrb(wstrb)
    );

    // Key register
    data[0] = key[0];
    axi_master_write(
             .address(`SM_PTP_BRIDGE_TCAM1_KEY_CSR_ADDR),
             .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
             .data(data), .burst_length(1), .wstrb(wstrb)
    );

    data[0] = key[1];
    axi_master_write(
             .address(`SM_PTP_BRIDGE_TCAM1_KEY_CSR_ADDR+4),
             .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
             .data(data), .burst_length(1), .wstrb(wstrb)
    );

    data[0] = key[2];
    axi_master_write(
             .address(`SM_PTP_BRIDGE_TCAM1_KEY_CSR_ADDR+8),
             .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
             .data(data), .burst_length(1), .wstrb(wstrb)
    );

    // Result register
    data[0] = egr_port;
    axi_master_write(
             .address(`SM_PTP_BRIDGE_TCAM1_RESULT_CSR_ADDR),
             .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
             .data(data), .burst_length(1), .wstrb(wstrb)
    );

    // Mask register
    for (int i=0; i<16; i=i+1) begin
      if (i < 3) begin
        data[0] = 'hFFFF_FFFF;
        axi_master_write(
                 .address(`SM_PTP_BRIDGE_TCAM1_MASK_CSR_ADDR+(i*4)),
                 .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                 .data(data), .burst_length(1), .wstrb(wstrb)
        );
      end else begin
        data[0] = 'h0;
        axi_master_write(
                 .address(`SM_PTP_BRIDGE_TCAM1_MASK_CSR_ADDR+(i*4)),
                 .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                 .data(data), .burst_length(1), .wstrb(wstrb)
        );
      end
    end

    // Checking whether the Entry successful or not
    data = new[1];
    data[0][31]=1;
    while (data[0][31]) begin
      #20ns;
      axi_master_read(
              .address(`SM_PTP_BRIDGE_TCAM1_CSR_BASE +'h20),
              .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
              .burst_length(1), .data(data)
      );
      if (!data[0][31])
        `uvm_info(get_full_name(), "TCAM1 IS NOT BUSY..", UVM_DEBUG)
      else
        `uvm_info(get_full_name(), "TCAM1 IS BUSY..", UVM_DEBUG)
    end

    // Insert the entry using Mgmt_ctrl register
    data[0] = 1;
    axi_master_write (
             .address(`SM_PTP_BRIDGE_TCAM1_CSR_BASE +'h20),
             .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
             .data(data), .burst_length(1), .wstrb(wstrb)
    );

    // Checking whether the Entry successful or not
    while (!data[0][8]) begin
      #20ns;
      axi_master_read(
              .address(`SM_PTP_BRIDGE_TCAM1_CSR_BASE +'h20),
              .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
              .burst_length(1), .data(data)
      );
      if (data[0][8])
        `uvm_info(get_full_name(), "INSERT KEY IS  SUCCESSFULL..", UVM_DEBUG)
    end
  endtask: configure_tcam1

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task configure_pkt_client0(
    bit [47:0] sa, bit [47:0] da,
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] num_pkts,
    bit soft_rst, bit fxd_gap, bit [1:0] len_mode, bit [7:0] idle_cycles
  );
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data [];
    bit [`SVT_AXI_WSTRB_WIDTH-1:0]    wstrb [];
  
    data = new[1];
    wstrb = new[1];
    wstrb[0] = 'hf;

    // Setting up SA & DA 
    data[0] = da[31:0];
    axi_master_write(
            .address(`SM_PTP_PKTCLI0_DYN_DMAC_ADDR_L),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(data), .burst_length(1), .wstrb(wstrb)
    );

    data[0][15:0] = da[47:32];
    axi_master_write(
            .address(`SM_PTP_PKTCLI0_DYN_DMAC_ADDR_U),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(data), .burst_length(1), .wstrb(wstrb)
    );

    data[0] = sa[31:0];
    axi_master_write(
            .address(`SM_PTP_PKTCLI0_DYN_SMAC_ADDR_L),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(data), .burst_length(1), .wstrb(wstrb)
    );

    data[0][15:0] = sa[47:32];
    axi_master_write(
            .address(`SM_PTP_PKTCLI0_DYN_SMAC_ADDR_U),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(data), .burst_length(1), .wstrb(wstrb)
    );

    // No. of packets to transmit
    data[0] = num_pkts;
    axi_master_write(
            .address(`SM_PTP_PKTCLI0_DYN_PKT_NUM),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(data), .burst_length(1), .wstrb(wstrb)
    );

    // Configuring the Packet size in bytes
    `uvm_info(get_full_name(), "PKTCLI0_CFG_DYN_PKT_SIZE_CFG...", UVM_DEBUG)
    data[0] = 0;
    data[0][29:16] = 'd1500;
    data[0][13:0] = 'd64;
    axi_master_write(
            .address(`SM_PTP_PKTCLI0_DYN_PKT_SIZE_CFG),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(data), .burst_length(1), .wstrb(wstrb)
    );

    // Configuring the Packet client control
    `uvm_info(get_full_name(), "PKTCLI0_CFG_PKT_CL_CTRL...", UVM_DEBUG)

    data[0] = 0;
    data[0][0] = 'h1;
    data[0][2:1] = 'h0;
    data[0][3] = soft_rst;
    data[0][4] = 'h1;
    data[0][5] = 'h1;
    data[0][8:6] = 'h0;
    data[0][9] = fxd_gap;
    data[0][11:10] = len_mode;
    data[0][19:12] = idle_cycles;
    axi_master_write(
            .address(`SM_PTP_PKTCLI0_CFG_PKT_CL_CTRL),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(data), .burst_length(1), .wstrb(wstrb)
    );
  endtask: configure_pkt_client0

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task configure_pkt_client1(
    bit [47:0] sa, bit [47:0] da,
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] num_pkts,
    bit soft_rst, bit fxd_gap, bit [1:0] len_mode, bit [7:0] idle_cycles
  );
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data [];
    bit [`SVT_AXI_WSTRB_WIDTH-1:0]    wstrb [];
  
    data = new[1];
    wstrb = new[1];
    wstrb[0] = 'hf;

    // Setting up SA & DA 
    data[0] = da[31:0];
    axi_master_write(
            .address(`SM_PTP_PKTCLI1_DYN_DMAC_ADDR_L),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(data), .burst_length(1), .wstrb(wstrb)
    );

    data[0][15:0] = da[47:32];
    axi_master_write(
            .address(`SM_PTP_PKTCLI1_DYN_DMAC_ADDR_U),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(data), .burst_length(1), .wstrb(wstrb)
    );

    data[0] = sa[31:0];
    axi_master_write(
            .address(`SM_PTP_PKTCLI1_DYN_SMAC_ADDR_L),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(data), .burst_length(1), .wstrb(wstrb)
    );

    data[0][15:0] = sa[47:32];
    axi_master_write(
            .address(`SM_PTP_PKTCLI1_DYN_SMAC_ADDR_U),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(data), .burst_length(1), .wstrb(wstrb)
    );

    // No. of packets to transmit
    data[0] = num_pkts;
    axi_master_write(
            .address(`SM_PTP_PKTCLI1_DYN_PKT_NUM),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(data), .burst_length(1), .wstrb(wstrb)
    );

    // Configuring the Packet size in bytes
    `uvm_info(get_full_name(), "PKTCLI1_CFG_DYN_PKT_SIZE_CFG...", UVM_DEBUG)
    data[0] = 0;
    data[0][29:16] = 'd1500;
    data[0][13:0] = 'd64;
    axi_master_write(
            .address(`SM_PTP_PKTCLI1_DYN_PKT_SIZE_CFG),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(data), .burst_length(1), .wstrb(wstrb)
    );

    // Configuring the Packet client control
    `uvm_info(get_full_name(), "PKTCLI1_CFG_PKT_CL_CTRL...", UVM_DEBUG)

    data[0] = 0;
    data[0][0] = 'h1;
    data[0][2:1] = 'h0;
    data[0][3] = soft_rst;
    data[0][4] = 'h1;
    data[0][5] = 'h1;
    data[0][8:6] = 'h0;
    data[0][9] = fxd_gap;
    data[0][11:10] = len_mode;
    data[0][19:12] = idle_cycles;
    axi_master_write(
            .address(`SM_PTP_PKTCLI1_CFG_PKT_CL_CTRL),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(data), .burst_length(1), .wstrb(wstrb)
    );
  endtask: configure_pkt_client1

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task wait_for_pkts_to_complete(bit port, int num_pkts);
    bit pkt_cnt_match;
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data [];
    bit [`SVT_AXI_MAX_ADDR_WIDTH-1:0] base_addr;

`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
    if (port == 0) base_addr = `SM_PTP_PKT_CLIENT_0_CSR_BASE;
    else if (port == 1) base_addr = `SM_PTP_PKT_CLIENT_1_CSR_BASE;
`else
    if (port == 0) base_addr = `SM_PTP_PKT_CLIENT_1_CSR_BASE;
    else if (port == 1) base_addr = `SM_PTP_PKT_CLIENT_0_CSR_BASE;
`endif

    fork
      while (pkt_cnt_match != 1) begin
        repeat (100) @(posedge tb_top.clk_100m);
        axi_master_read(
            .address(base_addr+'h5C),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .burst_length(1), .data(data)
        );
        pkt_cnt_match = (data[0] == num_pkts);
        foreach (data[i])
          `uvm_info(get_full_name(),
                    $sformatf("current packet count %0d, pkt_cnt_match %0d",
                              data[0], pkt_cnt_match),
                    UVM_LOW)
      end
      begin
        #500us;
        `uvm_error(get_full_name(), "timed out waiting for all transfers to complete")
      end
    join_any
    `uvm_info(get_full_name(), "Disabling fork", UVM_LOW)
    disable fork;
  endtask

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task read_pkt_client_perf_stats(bit port=0);
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data [];
    bit [`SVT_AXI_MAX_ADDR_WIDTH-1:0] base_addr;
    logic [63:0] rx_byte_cnt;
    logic [63:0] tx_byte_cnt;
    logic [63:0] tx_num_ticks;
    logic [63:0] rx_num_ticks;   

    real         tx_perf_data;
    real         rx_perf_data;

`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
    if (port == 0) base_addr = `SM_PTP_PKT_CLIENT_0_CSR_BASE;
    else if (port == 1) base_addr = `SM_PTP_PKT_CLIENT_1_CSR_BASE;
`else
    if (port == 0) base_addr = `SM_PTP_PKT_CLIENT_1_CSR_BASE;
    else if (port == 1) base_addr = `SM_PTP_PKT_CLIENT_0_CSR_BASE;
`endif

    axi_master_read(
        .address(base_addr+'h60),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    rx_byte_cnt[31:0] = data[0];

    axi_master_read(
        .address(base_addr+'h64),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    rx_byte_cnt[63:32] = data[0];

    axi_master_read(
        .address(base_addr+'h68),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    tx_byte_cnt[31:0] = data[0];

    axi_master_read(
        .address(base_addr+'h6C),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    tx_byte_cnt[63:32] = data[0];

    axi_master_read(
        .address(base_addr+'h70),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    tx_num_ticks[31:0] = data[0];

    axi_master_read(
        .address(base_addr+'h74),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    tx_num_ticks[63:32] = data[0];

    axi_master_read(
        .address(base_addr+'h78),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    rx_num_ticks[31:0] = data[0];

    axi_master_read(
        .address(base_addr+'h7C),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    rx_num_ticks[63:32] = data[0];

    // considering 6.2ns clk period fr 161MHz
    tx_perf_data = (tx_byte_cnt*8) / (6.2 * tx_num_ticks);
    `uvm_info($sformatf("*** CLIENT %0d TX PERFORMANCE MEASUREMENT *** ", port),
              $sformatf("no. of bytes = 0x%0h  num_ticks = 0x%0h perf_data = %.4f Gb/s",
                         tx_byte_cnt, tx_num_ticks, tx_perf_data),
              UVM_LOW)
    rx_perf_data = (rx_byte_cnt*8) / (6.2 * rx_num_ticks);
    `uvm_info($sformatf("*** CLIENT %0d RX PERFORMANCE MEASUREMENT *** ", port),
              $sformatf("no. of bytes = 0x%0h  num_ticks = 0x%0h perf_data = %.4f Gb/s",
                        rx_byte_cnt, rx_num_ticks, rx_perf_data),
              UVM_LOW)

    axi_master_read(
        .address(base_addr+'h58),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    foreach(data[i]) begin
      `uvm_info(get_full_name(),
                $sformatf("pkt client %0d: STAT_CHECKER_MISC %0h", port, data[i]), UVM_LOW)
      if (data[i][0] == 1)
        `uvm_error(get_full_name(), $sformatf("Data mismatch detected at pkt cli %0d", port))
    end
  endtask: read_pkt_client_perf_stats

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task match_sop_eop(bit port = 0);
    bit [63:0] p0_tx_sop, p0_tx_eop;
    bit [63:0] p0_rx_sop, p0_rx_eop;
    bit [63:0] p1_tx_sop, p1_tx_eop;
    bit [63:0] p1_rx_sop, p1_rx_eop;

    if (port == 0)
      read_p0_tx_sop_eop(p0_tx_sop, p0_tx_eop);
    else
      read_p1_tx_sop_eop(p1_tx_sop, p1_tx_eop);
`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
    if (port == 0) begin
      read_p0_rx_sop_eop(p0_rx_sop, p0_rx_eop);
      if (p0_tx_sop !== p0_rx_sop)
        `uvm_error(get_full_name(),
                   $sformatf("p0_tx_sop %0d not same as p0_rx_sop %0d",
                              p0_tx_sop, p0_rx_sop))
      if (p0_tx_eop !== p0_rx_eop)
        `uvm_error(get_full_name(),
                   $sformatf("p0_tx_eop %0d not same as p0_rx_eop %0d",
                              p0_tx_eop, p0_rx_eop))
    end else begin
      read_p1_rx_sop_eop(p1_rx_sop, p1_rx_eop);
      if (p1_tx_sop !== p1_rx_sop)
        `uvm_error(get_full_name(),
                   $sformatf("p1_tx_sop %0d not same as p1_rx_sop %0d",
                              p1_tx_sop, p1_rx_sop))
      if (p1_tx_eop !== p1_rx_eop)
        `uvm_error(get_full_name(),
                   $sformatf("p1_tx_eop %0d not same as p1_rx_eop %0d",
                              p1_tx_eop, p1_rx_eop))
    end
`else
    if (port == 0) begin
      read_p1_rx_sop_eop(p1_rx_sop, p1_rx_eop);
      if (p1_tx_sop !== p1_rx_sop)
        `uvm_error(get_full_name(),
                   $sformatf("p1_tx_sop %0d not same as p1_rx_sop %0d",
                              p1_tx_sop, p1_rx_sop))
      if (p1_tx_eop !== p1_rx_eop)
        `uvm_error(get_full_name(),
                   $sformatf("p1_tx_eop %0d not same as p1_rx_eop %0d",
                              p1_tx_eop, p1_rx_eop))
    end else begin
      read_p0_rx_sop_eop(p0_rx_sop, p0_rx_eop);
      if (p0_tx_sop !== p0_rx_sop)
        `uvm_error(get_full_name(),
                   $sformatf("p0_tx_sop %0d not same as p0_rx_sop %0d",
                              p0_tx_sop, p0_rx_sop))
      if (p0_tx_eop !== p0_rx_eop)
        `uvm_error(get_full_name(),
                   $sformatf("p0_tx_eop %0d not same as p0_rx_eop %0d",
                              p0_tx_eop, p0_rx_eop))
    end
`endif
  endtask

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task read_p0_tx_sop_eop(bit [63:0] p0_tx_sop, bit [63:0] p0_tx_eop);
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data [];

    bit [31:0] p0_tx_sop_l, p0_tx_sop_u;
    bit [31:0] p0_tx_eop_l, p0_tx_eop_u;

    axi_master_read(
        .address(`SM_PTP_PKTCLI0_STAT_TX_SOP_CNT_L),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    p0_tx_sop_l = data[0];

    axi_master_read(
        .address(`SM_PTP_PKTCLI0_STAT_TX_SOP_CNT_U),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    p0_tx_sop_u = data[0];

    axi_master_read(
        .address(`SM_PTP_PKTCLI0_STAT_TX_EOP_CNT_L),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    p0_tx_eop_l = data[0];

    axi_master_read(
        .address(`SM_PTP_PKTCLI0_STAT_TX_EOP_CNT_U),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    p0_tx_eop_u = data[0];

    p0_tx_sop = {p0_tx_sop_u, p0_tx_sop_l};
    p0_tx_eop = {p0_tx_eop_u, p0_tx_eop_l};
    `uvm_info(get_full_name(),
              $sformatf({"p0_tx_sop_u %0d, p0_tx_sop_l %0d\n",
                         "p0_tx_eop_u %0d, p0_tx_eop_l %0d\n",
                         "p0_tx_sop %0d, p0_tx_eop %0d"},
                        p0_tx_sop_u, p0_tx_sop_l, p0_tx_eop_u, p0_tx_eop_l, p0_tx_sop, p0_tx_eop),
              UVM_LOW)
  endtask

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task read_p0_rx_sop_eop(bit [63:0] p0_rx_sop, bit [63:0] p0_rx_eop);
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data [];

    bit [31:0] p0_rx_sop_l, p0_rx_sop_u;
    bit [31:0] p0_rx_eop_l, p0_rx_eop_u;

    axi_master_read(
        .address(`SM_PTP_PKTCLI0_STAT_RX_SOP_CNT_L),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    p0_rx_sop_l = data[0];

    axi_master_read(
        .address(`SM_PTP_PKTCLI0_STAT_RX_SOP_CNT_U),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    p0_rx_sop_u = data[0];

    axi_master_read(
        .address(`SM_PTP_PKTCLI0_STAT_RX_EOP_CNT_L),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    p0_rx_eop_l = data[0];

    axi_master_read(
        .address(`SM_PTP_PKTCLI0_STAT_RX_EOP_CNT_U),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    p0_rx_eop_u = data[0];

    p0_rx_sop = {p0_rx_sop_u, p0_rx_sop_l};
    p0_rx_eop = {p0_rx_eop_u, p0_rx_eop_l};
    `uvm_info(get_full_name(),
              $sformatf({"p0_rx_sop_u %0d, p0_rx_sop_l %0d\n",
                         "p0_rx_eop_u %0d, p0_rx_eop_l %0d\n",
                         "p0_rx_sop %0d, p0_rx_eop %0d"},
                        p0_rx_sop_u, p0_rx_sop_l, p0_rx_eop_u, p0_rx_eop_l, p0_rx_sop, p0_rx_eop),
              UVM_LOW)
  endtask

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task read_p1_tx_sop_eop(bit [63:0] p1_tx_sop, bit [63:0] p1_tx_eop);
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data [];

    bit [31:0] p1_tx_sop_l, p1_tx_sop_u;
    bit [31:0] p1_tx_eop_l, p1_tx_eop_u;

    axi_master_read(
        .address(`SM_PTP_PKTCLI1_STAT_TX_SOP_CNT_L),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    p1_tx_sop_l = data[0];

    axi_master_read(
        .address(`SM_PTP_PKTCLI1_STAT_TX_SOP_CNT_U),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    p1_tx_sop_u = data[0];

    axi_master_read(
        .address(`SM_PTP_PKTCLI1_STAT_TX_EOP_CNT_L),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    p1_tx_eop_l = data[0];

    axi_master_read(
        .address(`SM_PTP_PKTCLI1_STAT_TX_EOP_CNT_U),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    p1_tx_eop_u = data[0];

    p1_tx_sop = {p1_tx_sop_u, p1_tx_sop_l};
    p1_tx_eop = {p1_tx_eop_u, p1_tx_eop_l};
    `uvm_info(get_full_name(),
              $sformatf({"p1_tx_sop_u %0d, p1_tx_sop_l %0d\n",
                         "p1_tx_eop_u %0d, p1_tx_eop_l %0d\n",
                         "p1_tx_sop %0d, p1_tx_eop %0d"},
                        p1_tx_sop_u, p1_tx_sop_l, p1_tx_eop_u, p1_tx_eop_l, p1_tx_sop, p1_tx_eop),
              UVM_LOW)
  endtask

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task read_p1_rx_sop_eop(bit [63:0] p1_rx_sop, bit [63:0] p1_rx_eop);
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data [];

    bit [31:0] p1_rx_sop_l, p1_rx_sop_u;
    bit [31:0] p1_rx_eop_l, p1_rx_eop_u;

    axi_master_read(
        .address(`SM_PTP_PKTCLI1_STAT_RX_SOP_CNT_L),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    p1_rx_sop_l = data[0];

    axi_master_read(
        .address(`SM_PTP_PKTCLI1_STAT_RX_SOP_CNT_U),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    p1_rx_sop_u = data[0];

    axi_master_read(
        .address(`SM_PTP_PKTCLI1_STAT_RX_EOP_CNT_L),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    p1_rx_eop_l = data[0];

    axi_master_read(
        .address(`SM_PTP_PKTCLI1_STAT_RX_EOP_CNT_U),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1), .data(data)
    );
    p1_rx_eop_u = data[0];

    p1_rx_sop = {p1_rx_sop_u, p1_rx_sop_l};
    p1_rx_eop = {p1_rx_eop_u, p1_rx_eop_l};
    `uvm_info(get_full_name(),
              $sformatf({"p1_rx_sop_u %0d, p1_rx_sop_l %0d\n",
                         "p1_rx_eop_u %0d, p1_rx_eop_l %0d\n",
                         "p1_rx_sop %0d, p1_rx_eop %0d"},
                        p1_rx_sop_u, p1_rx_sop_l, p1_rx_eop_u, p1_rx_eop_l, p1_rx_sop, p1_rx_eop),
              UVM_LOW)
  endtask

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task wait_for_data_offset_valid();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data [];

    `uvm_info(get_full_name(), "wait ptp tx and rx offset data valid for port 0", UVM_LOW)
    while (data[0][1:0] !== 2'b11) begin
      axi_master_read(
              .address(`SM_PTP_HSSI_CSR_PORT0_SOFT_IP_PTP +'h30),
              .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
              .burst_length(1), .data(data));
    end

    data = new[1];

    if (`SM_PTP_NUM_PORTS == 2) begin
      `uvm_info(get_full_name(), "wait ptp tx and rx offset data valid for port 1", UVM_LOW)
      while (data[0][1:0] !== 2'b11) begin
        axi_master_read(
                .address(`SM_PTP_HSSI_CSR_PORT1_SOFT_IP_PTP +'h30),
                .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                .burst_length(1), .data(data));
      end
    end
  endtask: wait_for_data_offset_valid

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task ptp_tx_initialise();
    read_tx_port0_ptp_offset_data();
    calculate_tx_port0_offsets();
    write_calculated_tx_port0_offsets();

    if (`SM_PTP_NUM_PORTS == 2) begin
      read_tx_port1_ptp_offset_data();
      calculate_tx_port1_offsets();
      write_calculated_tx_port1_offsets();
    end
  endtask: ptp_tx_initialise

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task ptp_rx_initialise();
    read_rx_port0_ptp_offset_data();
    calculate_rx_port0_offsets();
    write_calculated_rx_port0_offsets();

    if (`SM_PTP_NUM_PORTS == 2) begin
      read_rx_port1_ptp_offset_data();
      calculate_rx_port1_offsets();
      write_calculated_rx_port1_offsets();
    end
  endtask: ptp_rx_initialise

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task read_tx_port0_ptp_offset_data;
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] ptp_tx_port0_data_constdelay_addr[];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] ptp_tx_port0_calc_data_offset_addr[];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] ptp_tx_port0_calc_data_time_addr[];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] ptp_tx_port0_calc_data_wiredelay_addr[];

    ptp_tx_port0_data_constdelay_addr = new[1];
    ptp_tx_port0_calc_data_offset_addr = new[1];
    ptp_tx_port0_calc_data_time_addr = new[1];
    ptp_tx_port0_calc_data_wiredelay_addr = new[1];

    axi_master_read(
        .address(`SM_PTP_HSSI_CSR_PORT0_SOFT_IP_PTP + 'hF0),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1),
        .data(ptp_tx_port0_data_constdelay_addr));

    `uvm_info(get_full_name(),
              $sformatf("Value of ptp_tx_port0_data_constdelay_addr: %0h", ptp_tx_port0_data_constdelay_addr[0]),
              UVM_LOW);

    tx_port0_const_delay      = ptp_tx_port0_data_constdelay_addr[0][30:0];
    tx_port0_const_delay_sign = ptp_tx_port0_data_constdelay_addr[0][31];

    axi_master_read(
        .address(`SM_PTP_HSSI_CSR_PORT0_SOFT_IP_PTP + 'h100),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1),
        .data(ptp_tx_port0_calc_data_offset_addr));

    `uvm_info(get_full_name(),
              $sformatf("Value of ptp_tx_port0_calc_data_offset_addr: %0h", ptp_tx_port0_calc_data_offset_addr[0]),
              UVM_LOW);

    tx_port0_apulse_offset      = ptp_tx_port0_calc_data_offset_addr[0][30:0];
    tx_port0_apulse_offset_sign = ptp_tx_port0_calc_data_offset_addr[0][31];
    
    axi_master_read(
        .address(`SM_PTP_HSSI_CSR_PORT0_SOFT_IP_PTP + 'h108),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1),
        .data(ptp_tx_port0_calc_data_time_addr));

    `uvm_info(get_full_name(),
              $sformatf("Value of ptp_tx_port0_calc_data_time_addr: %0h", ptp_tx_port0_calc_data_time_addr[0]),
              UVM_LOW);
    
    tx_port0_apulse_time = {1'b0, ptp_tx_port0_calc_data_time_addr[0][27:0]};
    
    axi_master_read(
        .address(`SM_PTP_HSSI_CSR_PORT0_SOFT_IP_PTP + 'h110),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1),
        .data(ptp_tx_port0_calc_data_wiredelay_addr));
    
    `uvm_info(get_full_name(),
              $sformatf("Value of ptp_tx_port0_calc_data_wiredelay_addr: %0h", ptp_tx_port0_calc_data_wiredelay_addr[0]),
              UVM_LOW);
    tx_port0_apulse_wdelay = ptp_tx_port0_calc_data_wiredelay_addr[0][19:0];
  endtask

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task calculate_tx_port0_offsets;
    logic [31:0] tx_pma_delay_ns_fns;
    logic [31:0] tx_external_phy_delay;

    $display("%0t Info: Calculate TX offsets", $time);
    // a) Calculate TX TAM adjust (twos complement)
    tx_port0_tam_adjust = (tx_port0_const_delay_sign ? -tx_port0_const_delay : tx_port0_const_delay)
                          + (tx_port0_apulse_offset_sign ? -tx_port0_apulse_offset : tx_port0_apulse_offset)
                          - (tx_port0_apulse_wdelay);
    
    tx_port0_tam_adjust_2c  = tx_port0_tam_adjust;

    // b) Calculate TX extra latency
    tx_pma_delay_ns_fns     = 43'((/*tx_pma_delay_ui*/79 * /*ui*/'h018D3019)) >> (28 - 16);
    tx_external_phy_delay   = 0;
    tx_port0_extra_latency[30:0]  = tx_pma_delay_ns_fns + tx_external_phy_delay;
    tx_port0_extra_latency[31]    = 1'b0;
  endtask

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task write_calculated_tx_port0_offsets();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] wdata [];
    bit [`SVT_AXI_WSTRB_WIDTH-1:0]    wstrb [];

    wdata = new[1];
    wstrb = new[1];
    wstrb[0] = 'hf;

    wdata[0] = tx_port0_extra_latency;
    axi_master_write(
            .address(`SM_PTP_HSSI_CSR_PORT0_HARD_IP_EMAC + 'hE0),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .burst_length(1), .data(wdata),	.wstrb(wstrb)
    );

    wdata[0] = tx_port0_tam_adjust_2c;
    axi_master_write(
            .address(`SM_PTP_HSSI_CSR_PORT0_SOFT_IP_PTP),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .burst_length(1), .data(wdata),	.wstrb(wstrb)
    );
  endtask: write_calculated_tx_port0_offsets

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task read_tx_port1_ptp_offset_data;
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] ptp_tx_port1_data_constdelay_addr[];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] ptp_tx_port1_calc_data_offset_addr[];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] ptp_tx_port1_calc_data_time_addr[];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] ptp_tx_port1_calc_data_wiredelay_addr[];

    ptp_tx_port1_data_constdelay_addr = new[1];
    ptp_tx_port1_calc_data_offset_addr = new[1];
    ptp_tx_port1_calc_data_time_addr = new[1];
    ptp_tx_port1_calc_data_wiredelay_addr = new[1];

    axi_master_read(
        .address(`SM_PTP_HSSI_CSR_PORT1_SOFT_IP_PTP + 'hF0),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1),
        .data(ptp_tx_port1_data_constdelay_addr));

    `uvm_info(get_full_name(),
              $sformatf("Value of ptp_tx_port1_data_constdelay_addr: %0h", ptp_tx_port1_data_constdelay_addr[0]),
              UVM_LOW);

    tx_port1_const_delay      = ptp_tx_port1_data_constdelay_addr[0][30:0];
    tx_port1_const_delay_sign = ptp_tx_port1_data_constdelay_addr[0][31];

    axi_master_read(
        .address(`SM_PTP_HSSI_CSR_PORT1_SOFT_IP_PTP + 'h100),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1),
        .data(ptp_tx_port1_calc_data_offset_addr));

    `uvm_info(get_full_name(),
              $sformatf("Value of ptp_tx_port1_calc_data_offset_addr: %0h", ptp_tx_port1_calc_data_offset_addr[0]),
              UVM_LOW);

    tx_port1_apulse_offset      = ptp_tx_port1_calc_data_offset_addr[0][30:0];
    tx_port1_apulse_offset_sign = ptp_tx_port1_calc_data_offset_addr[0][31];
    
    axi_master_read(
        .address(`SM_PTP_HSSI_CSR_PORT1_SOFT_IP_PTP + 'h108),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1),
        .data(ptp_tx_port1_calc_data_time_addr));

    `uvm_info(get_full_name(),
              $sformatf("Value of ptp_tx_port1_calc_data_time_addr: %0h", ptp_tx_port1_calc_data_time_addr[0]),
              UVM_LOW);
    
    tx_port1_apulse_time = {1'b0, ptp_tx_port1_calc_data_time_addr[0][27:0]};
    
    axi_master_read(
        .address(`SM_PTP_HSSI_CSR_PORT1_SOFT_IP_PTP + 'h110),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1),
        .data(ptp_tx_port1_calc_data_wiredelay_addr));
    
    `uvm_info(get_full_name(),
              $sformatf("Value of ptp_tx_port1_calc_data_wiredelay_addr: %0h", ptp_tx_port1_calc_data_wiredelay_addr[0]),
              UVM_LOW);
    tx_port1_apulse_wdelay = ptp_tx_port1_calc_data_wiredelay_addr[0][19:0];
  endtask

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task calculate_tx_port1_offsets;
    logic [30:0] tx_pma_delay_ns_fns;
    logic [30:0] tx_external_phy_delay;

    $display("%0t Info: Calculate TX offsets", $time);
    // a) Calculate TX TAM adjust (twos complement)
    tx_port1_tam_adjust = (tx_port1_const_delay_sign ? -tx_port1_const_delay : tx_port1_const_delay)
                          + (tx_port1_apulse_offset_sign ? -tx_port1_apulse_offset : tx_port1_apulse_offset)
                          - (tx_port1_apulse_wdelay);
    
    tx_port1_tam_adjust_2c  = tx_port1_tam_adjust;
        
    // b) Calculate TX extra latency
    tx_pma_delay_ns_fns     = 43'((/*tx_pma_delay_ui*/79 * /*ui*/'h018D3019)) >> (28 - 16);
    tx_external_phy_delay   = 0;
    tx_port1_extra_latency[30:0]  = tx_pma_delay_ns_fns + tx_external_phy_delay;
    tx_port1_extra_latency[31]    = 1'b0;
  endtask

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task write_calculated_tx_port1_offsets();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] wdata [];
    bit [`SVT_AXI_WSTRB_WIDTH-1:0]    wstrb [];

    wdata = new[1];
    wstrb = new[1];
    wstrb[0] = 'hf;

    wdata[0] = tx_port1_extra_latency;
    axi_master_write(
            .address(`SM_PTP_HSSI_CSR_PORT1_HARD_IP_EMAC + 'hE0),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .burst_length(1), .data(wdata),	.wstrb(wstrb)
    );

    wdata[0] = tx_port1_tam_adjust_2c;
    axi_master_write(
            .address(`SM_PTP_HSSI_CSR_PORT1_SOFT_IP_PTP),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .burst_length(1), .data(wdata),	.wstrb(wstrb)
    );
  endtask: write_calculated_tx_port1_offsets

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task read_rx_port0_ptp_offset_data;
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] ptp_rx_port0_data_constdelay_addr[];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] ptp_rx_port0_calc_data_offset_addr[];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] ptp_rx_port0_calc_data_time_addr[];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] ptp_rx_port0_calc_data_wiredelay_addr[];

    ptp_rx_port0_data_constdelay_addr = new[1];
    ptp_rx_port0_calc_data_offset_addr = new[1];
    ptp_rx_port0_calc_data_time_addr = new[1];
    ptp_rx_port0_calc_data_wiredelay_addr = new[1];

    axi_master_read(
        .address(`SM_PTP_HSSI_CSR_PORT0_SOFT_IP_PTP + 'hF4),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1),
        .data(ptp_rx_port0_data_constdelay_addr));

    `uvm_info(get_full_name(),
              $sformatf("Value of ptp_rx_port0_data_constdelay_addr: %0h", ptp_rx_port0_data_constdelay_addr[0]),
              UVM_LOW);

    rx_port0_const_delay      = ptp_rx_port0_data_constdelay_addr[0][30:0];
    rx_port0_const_delay_sign = ptp_rx_port0_data_constdelay_addr[0][31];

    axi_master_read(
        .address(`SM_PTP_HSSI_CSR_PORT0_SOFT_IP_PTP + 'h104),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1),
        .data(ptp_rx_port0_calc_data_offset_addr));

    `uvm_info(get_full_name(),
              $sformatf("Value of ptp_rx_port0_calc_data_offset_addr: %0h", ptp_rx_port0_calc_data_offset_addr[0]),
              UVM_LOW);

    rx_port0_apulse_offset      = ptp_rx_port0_calc_data_offset_addr[0][30:0];
    rx_port0_apulse_offset_sign = ptp_rx_port0_calc_data_offset_addr[0][31];
    
    axi_master_read(
        .address(`SM_PTP_HSSI_CSR_PORT0_SOFT_IP_PTP + 'h10C),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1),
        .data(ptp_rx_port0_calc_data_time_addr));

    `uvm_info(get_full_name(),
              $sformatf("Value of ptp_rx_port0_calc_data_time_addr: %0h", ptp_rx_port0_calc_data_time_addr[0]),
              UVM_LOW);
    
    rx_port0_apulse_time = {1'b0, ptp_rx_port0_calc_data_time_addr[0][27:0]};
    
    axi_master_read(
        .address(`SM_PTP_HSSI_CSR_PORT0_SOFT_IP_PTP + 'h114),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1),
        .data(ptp_rx_port0_calc_data_wiredelay_addr));
    
    `uvm_info(get_full_name(),
              $sformatf("Value of ptp_rx_port0_calc_data_wiredelay_addr: %0h", ptp_rx_port0_calc_data_wiredelay_addr[0]),
              UVM_LOW);
    rx_port0_apulse_wdelay = ptp_rx_port0_calc_data_wiredelay_addr[0][19:0];
  endtask

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task calculate_rx_port0_offsets;
    logic [31:0] rx_pma_delay_ns_fns;
    logic [31:0] rx_external_phy_delay;

    $display("%0t Info: Calculate TX offsets", $time);
    // a) Calculate TX TAM adjust (twos complement)
    rx_port0_tam_adjust = (rx_port0_const_delay_sign ? -rx_port0_const_delay : rx_port0_const_delay)
                          + (rx_port0_apulse_offset_sign ? -rx_port0_apulse_offset : rx_port0_apulse_offset)
                          - (rx_port0_apulse_wdelay);
    
    rx_port0_tam_adjust_2c  = rx_port0_tam_adjust;
        
    // b) Calculate TX extra latency
    rx_pma_delay_ns_fns     = 43'((/*rx_pma_delay_ui*/88 * /*ui*/'h018D3019)) >> (28 - 16);
    rx_external_phy_delay   = 0;
    rx_port0_extra_latency[30:0]  = rx_pma_delay_ns_fns + rx_external_phy_delay;
    rx_port0_extra_latency[31]    = 1'b1;
  endtask

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task write_calculated_rx_port0_offsets();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] wdata [];
    bit [`SVT_AXI_WSTRB_WIDTH-1:0]    wstrb [];

    wdata = new[1];
    wstrb = new[1];
    wstrb[0] = 'hf;

    wdata[0] = rx_port0_extra_latency;
    axi_master_write(
            .address(`SM_PTP_HSSI_CSR_PORT0_HARD_IP_EMAC + 'hFC),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .burst_length(1), .data(wdata),	.wstrb(wstrb)
    );

    wdata[0] = rx_port0_tam_adjust_2c;
    axi_master_write(
            .address(`SM_PTP_HSSI_CSR_PORT0_SOFT_IP_PTP + 'h4),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .burst_length(1), .data(wdata),	.wstrb(wstrb)
    );
  endtask: write_calculated_rx_port0_offsets

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task read_rx_port1_ptp_offset_data;
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] ptp_rx_port1_data_constdelay_addr[];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] ptp_rx_port1_calc_data_offset_addr[];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] ptp_rx_port1_calc_data_time_addr[];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] ptp_rx_port1_calc_data_wiredelay_addr[];

    ptp_rx_port1_data_constdelay_addr = new[1];
    ptp_rx_port1_calc_data_offset_addr = new[1];
    ptp_rx_port1_calc_data_time_addr = new[1];
    ptp_rx_port1_calc_data_wiredelay_addr = new[1];

    axi_master_read(
        .address(`SM_PTP_HSSI_CSR_PORT1_SOFT_IP_PTP + 'hF4),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1),
        .data(ptp_rx_port1_data_constdelay_addr));

    `uvm_info(get_full_name(),
              $sformatf("Value of ptp_rx_port1_data_constdelay_addr: %0h", ptp_rx_port1_data_constdelay_addr[0]),
              UVM_LOW);

    rx_port1_const_delay      = ptp_rx_port1_data_constdelay_addr[0][30:0];
    rx_port1_const_delay_sign = ptp_rx_port1_data_constdelay_addr[0][31];

    axi_master_read(
        .address(`SM_PTP_HSSI_CSR_PORT1_SOFT_IP_PTP + 'h104),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1),
        .data(ptp_rx_port1_calc_data_offset_addr));

    `uvm_info(get_full_name(),
              $sformatf("Value of ptp_rx_port1_calc_data_offset_addr: %0h", ptp_rx_port1_calc_data_offset_addr[0]),
              UVM_LOW);

    rx_port1_apulse_offset      = ptp_rx_port1_calc_data_offset_addr[0][30:0];
    rx_port1_apulse_offset_sign = ptp_rx_port1_calc_data_offset_addr[0][31];
    
    axi_master_read(
        .address(`SM_PTP_HSSI_CSR_PORT1_SOFT_IP_PTP + 'h10C),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1),
        .data(ptp_rx_port1_calc_data_time_addr));

    `uvm_info(get_full_name(),
              $sformatf("Value of ptp_rx_port1_calc_data_time_addr: %0h", ptp_rx_port1_calc_data_time_addr[0]),
              UVM_LOW);
    
    rx_port1_apulse_time = {1'b0, ptp_rx_port1_calc_data_time_addr[0][27:0]};
    
    axi_master_read(
        .address(`SM_PTP_HSSI_CSR_PORT1_SOFT_IP_PTP + 'h114),
        .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
        .burst_length(1),
        .data(ptp_rx_port1_calc_data_wiredelay_addr));
    
    `uvm_info(get_full_name(),
              $sformatf("Value of ptp_rx_port1_calc_data_wiredelay_addr: %0h", ptp_rx_port1_calc_data_wiredelay_addr[0]),
              UVM_LOW);
    rx_port1_apulse_wdelay = ptp_rx_port1_calc_data_wiredelay_addr[0][19:0];
  endtask

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task calculate_rx_port1_offsets;
    logic [31:0] rx_pma_delay_ns_fns;
    logic [31:0] rx_external_phy_delay;

    $display("%0t Info: Calculate TX offsets", $time);
    // a) Calculate TX TAM adjust (twos complement)
    rx_port1_tam_adjust = (rx_port1_const_delay_sign ? -rx_port1_const_delay : rx_port1_const_delay)
                          + (rx_port1_apulse_offset_sign ? -rx_port1_apulse_offset : rx_port1_apulse_offset)
                          - (rx_port1_apulse_wdelay);
    
    rx_port1_tam_adjust_2c  = rx_port1_tam_adjust;

    // b) Calculate TX extra latency
    rx_pma_delay_ns_fns     = 43'((/*rx_pma_delay_ui*/88 * /*ui*/'h018D3019)) >> (28 - 16);
    rx_external_phy_delay   = 0;
    rx_port1_extra_latency[30:0]  = rx_pma_delay_ns_fns + rx_external_phy_delay;
    rx_port1_extra_latency[31]    = 1'b1;
  endtask

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task write_calculated_rx_port1_offsets();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] wdata [];
    bit [`SVT_AXI_WSTRB_WIDTH-1:0]    wstrb [];

    wdata = new[1];
    wstrb = new[1];
    wstrb[0] = 'hf;

    wdata[0] = rx_port1_extra_latency;
    axi_master_write(
            .address(`SM_PTP_HSSI_CSR_PORT1_HARD_IP_EMAC + 'hFC),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .burst_length(1), .data(wdata),	.wstrb(wstrb)
    );

    wdata[0] = rx_port1_tam_adjust_2c;
    axi_master_write(
            .address(`SM_PTP_HSSI_CSR_PORT1_SOFT_IP_PTP + 'h4),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .burst_length(1), .data(wdata),	.wstrb(wstrb)
    );
  endtask: write_calculated_rx_port1_offsets

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task notify_soft_ptp_user_cfg_done();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] wdata [];
    bit [`SVT_AXI_WSTRB_WIDTH-1:0]    wstrb [];

    wdata = new[1];
    wstrb = new[1];
    wstrb[0] = 'hf;
    wdata[0][0] = 1;

    axi_master_write(
            .address(`SM_PTP_HSSI_CSR_PORT0_SOFT_IP_PTP+'h14),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(wdata), .burst_length(1), .wstrb(wstrb)
    );

    axi_master_write(
            .address(`SM_PTP_HSSI_CSR_PORT0_SOFT_IP_PTP+'h18),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(wdata), .burst_length(1), .wstrb(wstrb)
    );

    axi_master_write(
            .address(`SM_PTP_HSSI_CSR_PORT1_SOFT_IP_PTP+'h14),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(wdata), .burst_length(1), .wstrb(wstrb)
    );

    axi_master_write(
            .address(`SM_PTP_HSSI_CSR_PORT1_SOFT_IP_PTP+'h18),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(wdata), .burst_length(1), .wstrb(wstrb)
    );
  endtask: notify_soft_ptp_user_cfg_done

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task wait_for_ptp_ready();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data [];

    `uvm_info(get_full_name(), "wait ptp tx and rx are ready for port 0", UVM_LOW)
    while (data[0][3:2] !== 2'b11) begin
      axi_master_read(
              .address(`SM_PTP_HSSI_CSR_PORT0_SOFT_IP_PTP +'h30),
              .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
              .burst_length(1), .data(data));
    end

    data = new[1];

    `uvm_info(get_full_name(), "wait ptp tx and rx are ready for port 1", UVM_LOW)
    if (`SM_PTP_NUM_PORTS == 2) begin
      while (data[0][3:2] !== 2'b11) begin
        axi_master_read(
                .address(`SM_PTP_HSSI_CSR_PORT1_SOFT_IP_PTP +'h30),
                .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                .burst_length(1), .data(data));
      end
    end
    `uvm_info(get_full_name(), "wait ptp tx and rx are ready for all ports", UVM_LOW)
  endtask

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task enable_user_client_chkr(bit port=0);
    bit [`SVT_AXI_MAX_ADDR_WIDTH-1:0] base_addr;
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data [];
    bit [`SVT_AXI_WSTRB_WIDTH-1:0]    wstrb [];
  
    data = new[1];
    wstrb = new[1];
    wstrb[0] = 'hf;

    if (port == 0) base_addr = `SM_PTP_PKT_CLIENT_0_CSR_BASE;
    else if (port == 1) base_addr = `SM_PTP_PKT_CLIENT_1_CSR_BASE;

    data[0] = 0;
    data[0][5] = 1;
    axi_master_write(
            .address(base_addr),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(data), .burst_length(1), .wstrb(wstrb)
    );
  endtask: enable_user_client_chkr
endclass: sm_ptp_basic_seq

`endif // SM_PTP_BASIC_SEQ__SV
