//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//#########################################################################
//# FETH Scoreboard
//# On TX Side, Input packets are collected in queu and on RX Side Output packets
//# are collected in queue and data comparion is done. If data mismatches happens
//# error is reported.   
//#########################################################################

`ifndef SM_PTP_MSGDMA_SUBSCRIBER__SV
`define SM_PTP_MSGDMA_SUBSCRIBER__SV

`uvm_analysis_imp_decl(_axi_port)
`uvm_analysis_imp_decl(_p_ingress)
`uvm_analysis_imp_decl(_p_egress)

class sm_ptp_msgdma_subscriber extends uvm_scoreboard;

  svt_axi_transaction axi_trans;
  
  bit [`SM_MSGDMA_DESCR_LENGTH-1:0] h2d_descr [`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][*];
  bit [`SM_MSGDMA_DESCR_LENGTH-1:0] d2h_descr [`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][*];
  bit [(`SM_MSGDMA_DESCR_LENGTH/2)-1:0] h2d_wrbk_descr [`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][*];
  bit [(`SM_MSGDMA_DESCR_LENGTH/2)-1:0] d2h_wrbk_descr [`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][*];

  bit [7:0] h2d_payload [`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][*];
  bit [7:0] d2h_payload [`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][*];

  bit [63:0] h2d_pyld_addr[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][$];
  bit [63:0] d2h_pyld_addr[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][$];
  bit [`SVT_AXI_MAX_ADDR_WIDTH-1:0] h2d_desc_addr[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][$];
  bit [`SVT_AXI_MAX_ADDR_WIDTH-1:0] d2h_desc_addr[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][$];

  int agent_type;
  int data_type;
  int port_num;
  int chan_num;

  int polling_requests;
  int pending_h2d_bytes[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  int skip_h2d_bytes[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  int cfgd_h2d_pyld_bytes[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][$];
  int cfgd_d2h_pyld_bytes[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][$];

  bit [95:0] h2d_wrbk_ts[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][$];
  bit [95:0] d2h_wrbk_ts[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][$];
  
  realtime h2d_desc_fetch_start_time[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT]; 
  realtime d2h_desc_fetch_start_time[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT]; 
  realtime h2d_last_resp_desc_time[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  realtime d2h_last_resp_desc_time[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];

  sm_ptp_ehip_port_tr p_n_tr[`SM_PTP_MAX_PORTS];
  sm_ptp_ehip_port_tr p_e_tr[`SM_PTP_MAX_PORTS];
  sm_ptp_ehip_port_tr p_n_ptp_tr[`SM_PTP_MAX_PORTS][$];
  sm_ptp_ehip_port_tr p_e_ptp_tr[`SM_PTP_MAX_PORTS][$];

  `uvm_component_utils(sm_ptp_msgdma_subscriber)

  uvm_analysis_imp_axi_port  #(svt_axi_transaction, sm_ptp_msgdma_subscriber) axi_port;
  uvm_analysis_imp_p_ingress #(sm_ptp_ehip_port_tr, sm_ptp_msgdma_subscriber) item_p_n[`SM_PTP_MAX_PORTS];
  uvm_analysis_imp_p_egress  #(sm_ptp_ehip_port_tr, sm_ptp_msgdma_subscriber) item_p_e[`SM_PTP_MAX_PORTS];

  //---------------------------------------------------------------------------
  // new - constructor
  //---------------------------------------------------------------------------
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new
 
  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi_port  = new("axi_port", this);
    for (bit [2:0] i=0; i<`SM_PTP_NUM_PORTS; i++) begin
      item_p_n[i] = new($sformatf("item_p_n[%0d]", i), this);
      item_p_e[i] = new($sformatf("item_p_e[%0d]", i), this);
      p_e_tr[i] = new();
      p_n_tr[i] = new();
    end
  endfunction: build_phase
   
  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  virtual function void write_p_ingress(sm_ptp_ehip_port_tr tr);
    sm_ptp_ehip_port_tr ptp_pkt;
    // p0_n_tr.push_back(tr);
    p_n_tr[tr.port] = new();
    p_n_tr[tr.port].copy(tr);
    `uvm_info(get_full_name(),
              $sformatf("p%0d ingress: timestamp for pkt sop %0t, eop %0t",
                        tr.port, tr.sop_time, tr.eop_time),
              UVM_LOW)
    if (tr.ptp_pkt == 1) begin
      ptp_pkt = new();
      ptp_pkt.copy(tr);
      p_n_ptp_tr[tr.port].push_back(ptp_pkt);
    end
  endfunction: write_p_ingress

  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  virtual function void write_p_egress(sm_ptp_ehip_port_tr tr);
    sm_ptp_ehip_port_tr ptp_pkt;
    // p0_e_tr.push_back(tr);
    p_e_tr[tr.port] = new();
    p_e_tr[tr.port].copy(tr);
    `uvm_info(get_full_name(),
              $sformatf("p%0d egress: timestamp for pkt sop %0t, eop %0t",
                        tr.port, tr.sop_time, tr.eop_time),
              UVM_LOW)
    if (tr.ptp_pkt == 1) begin
      ptp_pkt = new();
      ptp_pkt.copy(tr);
      p_e_ptp_tr[tr.port].push_back(ptp_pkt);
    end
  endfunction: write_p_egress

  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  virtual function void write_axi_port(svt_axi_transaction trans);
    $cast(axi_trans , trans.clone());

    data_type = axi_trans.addr[30:28];
    agent_type = axi_trans.addr[27];
    chan_num = axi_trans.addr[26:25];
    port_num = axi_trans.addr[24:23];

    `uvm_info(get_type_name(),
              $sformatf(" SCB:: Pkt received \n%s",axi_trans.sprint()),
              UVM_LOW)

    if (axi_trans.xact_type == svt_axi_transaction::READ) begin
      if (data_type == `DESCR) begin
        if (axi_trans.burst_length == 2)
          load_descriptor_data(axi_trans);
        else if (axi_trans.burst_length == 1)
          polling_requests = polling_requests+1;
      end else if (data_type == `DMA_DATA) begin
        load_h2d_dma_data(axi_trans);
      end
    end if (axi_trans.xact_type == svt_axi_transaction::WRITE) begin
      if (data_type == `DESCR) begin
        load_wrbk_descriptor_data(axi_trans);
      end else if (data_type == `DMA_DATA) begin
        load_d2h_dma_data(axi_trans);
      end
    end
  endfunction :write_axi_port

  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  function void load_descriptor_data(svt_axi_transaction tr);
    int length;
    bit [`SM_MSGDMA_DESCR_LENGTH-1:0] data;

    if (agent_type == `H2D_ST_AGENT) begin
      for (int i=0; i<tr.burst_length; i++) begin
        h2d_descr[port_num][chan_num][tr.addr][i*`SVT_AXI_MAX_DATA_WIDTH+:`SVT_AXI_MAX_DATA_WIDTH] = tr.data[i];
        `uvm_info(get_full_name(),
                  $sformatf("h2d_descr[%0d][%0d][%0h] = %0h",
                             port_num, chan_num, tr.addr, h2d_descr[port_num][chan_num][tr.addr]),
                  UVM_LOW)
      end
      if (tr.burst_length == 2) begin
        h2d_pyld_addr[port_num][chan_num].push_back({h2d_descr[port_num][chan_num][tr.addr][319:288], h2d_descr[port_num][chan_num][tr.addr][31:0]});
        h2d_desc_addr[port_num][chan_num].push_back(tr.addr);
      end
      if (h2d_descr[port_num][chan_num].num() == 1) begin
         h2d_desc_fetch_start_time[port_num][chan_num] = ($realtime/1ns);
         `uvm_info(get_full_name(),
                   $sformatf("Received first DESCR Read rquest on H2D @ %0t ns", ($realtime/1ns)), UVM_NONE)
      end
      cfgd_h2d_pyld_bytes[port_num][chan_num].push_back(h2d_descr[port_num][chan_num][tr.addr][95:64]);
    end else if (agent_type == `D2H_ST_AGENT) begin
      for (int i=0; i<tr.burst_length; i++) begin
        d2h_descr[port_num][chan_num][tr.addr][i*`SVT_AXI_MAX_DATA_WIDTH+:`SVT_AXI_MAX_DATA_WIDTH] = tr.data[i];
        `uvm_info(get_full_name(),
                  $sformatf("d2h_descr[%0d][%0d][%0h] = %0h",
                             port_num, chan_num, tr.addr, d2h_descr[port_num][chan_num][tr.addr]),
                  UVM_LOW)
      end
      if (tr.burst_length == 2) begin
        d2h_pyld_addr[port_num][chan_num].push_back({d2h_descr[port_num][chan_num][tr.addr][319:288], d2h_descr[port_num][chan_num][tr.addr][31:0]});
        d2h_desc_addr[port_num][chan_num].push_back(tr.addr);
      end
      if (d2h_descr[port_num][chan_num].num() == 1) begin
         d2h_desc_fetch_start_time[port_num][chan_num] = ($realtime/1ns);
         `uvm_info(get_full_name(),
                   $sformatf("Received first DESCR Read rquest on D2H @ %0t ns", ($realtime/1ns)), UVM_NONE)
      end
      cfgd_d2h_pyld_bytes[port_num][chan_num].push_back(d2h_descr[port_num][chan_num][tr.addr][95:64]);
    end
  endfunction

  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  function void load_h2d_dma_data(svt_axi_transaction tr);
    int burst_size_bytes;
    bit [63:0] pyld_addr;
    bit [`SVT_AXI_MAX_ADDR_WIDTH-1:0] desc_addr;

    `uvm_info(get_full_name(), $sformatf("SCB:: Loading H2D[%0d][%0d] data from \n%s", port_num, chan_num, tr.sprint()), UVM_DEBUG)

    burst_size_bytes = 2**tr.burst_size;
    `uvm_info(get_full_name(),
              $sformatf("pending_h2d_bytes[%0d][%0d] %0d", port_num, chan_num, pending_h2d_bytes[port_num][chan_num]),
              UVM_DEBUG)
    if (pending_h2d_bytes[port_num][chan_num] == 0) begin
      pyld_addr = h2d_pyld_addr[port_num][chan_num].pop_front();
      desc_addr = h2d_desc_addr[port_num][chan_num].pop_front();
      if (pyld_addr !== tr.addr) begin
        skip_h2d_bytes[port_num][chan_num] = pyld_addr - tr.addr;
        `uvm_info(get_full_name(),
                  $sformatf("assuming unaligned payload addr, skipping %0d bytes for port %0d, chan %0d", skip_h2d_bytes[port_num][chan_num], port_num, chan_num),
                  UVM_DEBUG)
      end

      if (h2d_descr[port_num][chan_num].exists(desc_addr) == 1) begin
        `uvm_info(get_full_name(),
                  $sformatf("pyld_addr %0h, desc_addr %0h, h2d_descr[%0d][%0d][%0h][31:0]=%0h",
                            pyld_addr, desc_addr, port_num, chan_num, desc_addr,
                            h2d_descr[port_num][chan_num][desc_addr][31:0]),
                  UVM_DEBUG)
        if ((h2d_descr[port_num][chan_num][desc_addr][31:0] == pyld_addr)
            && (pyld_addr == (tr.addr+skip_h2d_bytes[port_num][chan_num]))) begin
          pending_h2d_bytes[port_num][chan_num] = h2d_descr[port_num][chan_num][desc_addr][95:64];
          `uvm_info(get_full_name(),
                    $sformatf("pending_h2d_bytes[%0d][%0d] %0d renewed @ addr %0h",
                              port_num, chan_num, pending_h2d_bytes[port_num][chan_num], tr.addr),
                    UVM_DEBUG)
        end else
          `uvm_warning(get_full_name(),
                       $sformatf("pending_h2d_bytes[%0d][%0d] not renewed @ addr %0h", port_num, chan_num, tr.addr))
      end else begin
        `uvm_warning(get_full_name(),
                     $sformatf("h2d_descr[%0d][%0d][%0h] doesn't exist", port_num, chan_num, tr.addr))
      end
    end

    for (int l=0; l<tr.burst_length; l++) begin
      for (int b=0; b<burst_size_bytes; b++) begin
        if ((pending_h2d_bytes[port_num][chan_num] !== 0) && (skip_h2d_bytes[port_num][chan_num] == 0)) begin
          if (h2d_payload[port_num][chan_num].exists(tr.addr+(burst_size_bytes*l)+b))
            `uvm_info(get_full_name(),
                      $sformatf("data for h2d_payload[%0d][%0d][%0h] already captured",
                                port_num, chan_num, tr.addr+(burst_size_bytes*l)+b),
                      UVM_DEBUG)
          else
            pending_h2d_bytes[port_num][chan_num] = pending_h2d_bytes[port_num][chan_num]-1;

          h2d_payload[port_num][chan_num][tr.addr+(burst_size_bytes*l)+b] = tr.data[l][8*b+:8];
          `uvm_info(get_full_name(),
                    $sformatf("h2d_payload[%0d][%0d][%0h] = %0h, h2d_payload[%0d][%0d] size %0d",
                               port_num, chan_num, tr.addr+(burst_size_bytes*l)+b,
                               h2d_payload[port_num][chan_num][tr.addr+(burst_size_bytes*l)+b],
                               port_num, chan_num, h2d_payload[port_num][chan_num].size()),
                    UVM_DEBUG)
        end else if (skip_h2d_bytes[port_num][chan_num] !== 0) begin
          `uvm_info(get_full_name(),
                    $sformatf("skipping byte tr.data[%0d][%0d:%0d]", l, (8*b)+7, 8*b),
                    UVM_DEBUG)
          skip_h2d_bytes[port_num][chan_num] = skip_h2d_bytes[port_num][chan_num]-1;
        end
      end
    end
  endfunction: load_h2d_dma_data

  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  function void load_d2h_dma_data(svt_axi_transaction tr);
    int burst_size_bytes;

    burst_size_bytes = 2**tr.burst_size;

    for (int l=0; l<tr.burst_length; l++) begin
      `uvm_info(get_full_name(),
                $sformatf("tr.data[%0d] = %0h, wstrb[%0d]=%0h",
                           l, tr.data[l], l, tr.wstrb[l]),
                UVM_DEBUG)
      for (int b=0; b<burst_size_bytes; b++) begin
        if (tr.wstrb[l][b] == 1) begin
          d2h_payload[port_num][chan_num][tr.addr+(burst_size_bytes*l)+b] = tr.data[l][8*b+:8];
          `uvm_info(get_full_name(),
                    $sformatf("d2h_payload[%0d][%0d][%0h] = %0h, d2h_payload[%0d][%0d] size %0d",
                               port_num, chan_num, tr.addr+(burst_size_bytes*l)+b,
                               d2h_payload[port_num][chan_num][tr.addr+(burst_size_bytes*l)+b],
                               port_num, chan_num, d2h_payload[port_num][chan_num].size()),
                    UVM_DEBUG)
        end
      end
    end
  endfunction: load_d2h_dma_data

  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  function void load_wrbk_descriptor_data(svt_axi_transaction tr);
    int length;
    bit [`SM_MSGDMA_DESCR_LENGTH-1:0] data;

    if (agent_type == `H2D_ST_AGENT) begin
      for (int i=0; i<tr.burst_length; i++) begin
        h2d_wrbk_descr[port_num][chan_num][tr.addr][i*`SVT_AXI_MAX_DATA_WIDTH+:`SVT_AXI_MAX_DATA_WIDTH] = tr.data[i];
        `uvm_info(get_full_name(),
                  $sformatf("h2d_wrbk_descr[%0d][%0d][%0h] = %0h",
                             port_num, chan_num, tr.addr, h2d_wrbk_descr[port_num][chan_num][tr.addr]),
                  UVM_DEBUG)
      end
      h2d_last_resp_desc_time[port_num][chan_num] = ($realtime/1ns);
      if (tr.addr[5:0] == 'h20) begin
        h2d_wrbk_ts[port_num][chan_num].push_back(h2d_wrbk_descr[port_num][chan_num][tr.addr][223:128]);
        `uvm_info(get_full_name(), $sformatf("revecived TS for H2D[%0d][%0d]=%0h", port_num, chan_num, h2d_wrbk_descr[port_num][chan_num][tr.addr][223:128]), UVM_DEBUG)
        foreach(h2d_wrbk_ts[port_num][chan_num][i])
          `uvm_info(get_full_name(), $sformatf("h2d_wrbk_ts[%0d]%0d][%0d]=%0h", port_num, chan_num, i, h2d_wrbk_ts[port_num][chan_num][i]), UVM_DEBUG)
      end
    end else if (agent_type == `D2H_ST_AGENT) begin
      for (int i=0; i<tr.burst_length; i++) begin
        d2h_wrbk_descr[port_num][chan_num][tr.addr][i*`SVT_AXI_MAX_DATA_WIDTH+:`SVT_AXI_MAX_DATA_WIDTH] = tr.data[i];
        `uvm_info(get_full_name(),
                  $sformatf("d2h_wrbk_descr[%0d][%0d][%0h] = %0h",
                             port_num, chan_num, tr.addr, d2h_wrbk_descr[port_num][chan_num][tr.addr]),
                  UVM_DEBUG)
      end
      d2h_last_resp_desc_time[port_num][chan_num] = ($realtime/1ns);
      if (tr.addr[5:0] == 'h20) begin
        `uvm_info(get_full_name(), $sformatf("revecived TS for D2H[%0d][%0d]=%0h", port_num, chan_num, d2h_wrbk_descr[port_num][chan_num][tr.addr][223:128]), UVM_DEBUG)
        d2h_wrbk_ts[port_num][chan_num].push_back(d2h_wrbk_descr[port_num][chan_num][tr.addr][223:128]);
        foreach(d2h_wrbk_ts[port_num][chan_num][i])
          `uvm_info(get_full_name(), $sformatf("d2h_wrbk_ts[%0d]%0d][%0d]=%0h", port_num, chan_num, i, d2h_wrbk_ts[port_num][chan_num][i]), UVM_DEBUG)
      end
    end
  endfunction

  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
  endtask

  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  virtual function void report_phase(uvm_phase phase);
    real h2pn_perf_data[`SM_PTP_MAX_PORTS];
    real pe2h_perf_data[`SM_PTP_MAX_PORTS];

    super.final_phase(phase);

    // data integrity check
    if (`SM_PTP_NUM_PORTS == 2) begin
`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
      compare_data_bw_ports(.h2d_port(0), .h2d_ch(0), .d2h_port(0), .d2h_ch(0));
      compare_data_bw_ports(.h2d_port(0), .h2d_ch(1), .d2h_port(0), .d2h_ch(1));
      compare_data_bw_ports(.h2d_port(1), .h2d_ch(0), .d2h_port(1), .d2h_ch(0));
      compare_data_bw_ports(.h2d_port(1), .h2d_ch(1), .d2h_port(1), .d2h_ch(1));
`else
      compare_data_bw_ports(.h2d_port(0), .h2d_ch(0), .d2h_port(1), .d2h_ch(0));
      compare_data_bw_ports(.h2d_port(0), .h2d_ch(1), .d2h_port(1), .d2h_ch(1));
      compare_data_bw_ports(.h2d_port(1), .h2d_ch(0), .d2h_port(0), .d2h_ch(0));
      compare_data_bw_ports(.h2d_port(1), .h2d_ch(1), .d2h_port(0), .d2h_ch(1));
`endif
    end else
      compare_data_bw_ports(.h2d_port(0), .h2d_ch(0), .d2h_port(0), .d2h_ch(0));

    // calculate performance data
    if (`SM_PTP_NUM_PORTS == 2) begin
      h2h_perf_data(.h2d_port(0), .h2d_ch(0), .d2h_port(1), .d2h_ch(0));
      h2h_perf_data(.h2d_port(0), .h2d_ch(1), .d2h_port(1), .d2h_ch(1));
      h2h_perf_data(.h2d_port(1), .h2d_ch(0), .d2h_port(0), .d2h_ch(0));
      h2h_perf_data(.h2d_port(1), .h2d_ch(1), .d2h_port(0), .d2h_ch(1));
    end else
      h2h_perf_data(.h2d_port(0), .h2d_ch(0), .d2h_port(0), .d2h_ch(0));

    // TBD
    // for (bit [2:0] i=0; i<`SM_PTP_NUM_PORTS; i++) begin
    //   h2pn_perf_data[i] = (h2d_payload[i].num()*8) / (p_n_tr[i].eop_time-h2d_desc_fetch_start_time[i]);
    //   pe2h_perf_data[i] = (d2h_payload[i].num()*8) / (d2h_last_resp_desc_time[i]-p_e_tr[i].sop_time);

    //   `uvm_info(get_full_name(),
    //             $sformatf({"\nPERFORMACE DATA:\n",
    //                        "Host to P%0d ingress performance = %.4f Gb/s\n",
    //                        "P%0d egress to Host performance  = %.4f Gb/s"},
    //                        i, h2pn_perf_data[i], i, pe2h_perf_data[i]),
    //             UVM_NONE)

    //   `uvm_info(get_full_name(),
    //             $sformatf({"\np%0d_n_tr.eop for last pkt %t ns",
    //                        "\np%0d_e_tr.sop for first pkt %t ns"},
    //                        i, p_n_tr[i].eop_time, i, p_e_tr[i].sop_time),
    //             UVM_NONE)
    // end

    for (bit [1:0] port=0; port<`SM_PTP_NUM_PORTS; port++) begin
      for (bit [1:0] chan=0; chan<`SM_MSGDMA_NUM_CHANN_PER_PORT; chan++) begin
      `uvm_info(get_full_name(),
                $sformatf({"\nh2d_desc_fetch_start_time[%0d][%0d] %t ns",
                           "\nd2h_desc_fetch_start_time[%0d][%0d] %t ns",
                           "\nh2d_last_resp_desc_time[%0d][%0d] %t ns",
                           "\nd2h_last_resp_desc_time[%0d][%0d] %t ns"},
                           port, chan, h2d_desc_fetch_start_time[port][chan],
                           port, chan, d2h_desc_fetch_start_time[port][chan],
                           port, chan, h2d_last_resp_desc_time[port][chan],
                           port, chan, d2h_last_resp_desc_time[port][chan]),
                UVM_NONE)
      end
    end

    `uvm_info(get_full_name(), $sformatf("\nnumber of descr polling requests %0d", polling_requests), UVM_NONE)
  endfunction

  // --------------------------------------------------------------------------
  // --------------------------------------------------------------------------
  virtual function void compare_data_bw_ports(
    bit [1:0] h2d_port, bit [1:0] h2d_ch,
    bit [1:0] d2h_port, bit [1:0] d2h_ch
  );
    int h2d_buff_addr[$];
    int d2h_buff_addr[$];
    int h2d_addr, d2h_addr;
    bit [95:0] d2h_ts, h2d_ts;
    bit [95:0] ts_diff;
    bit [95:0] d2h_eth_ts, h2d_eth_ts;
    int compare_bytes_h2d_descr;
    int compare_bytes_d2h_descr;
    int ts_compare_size;

    compare_bytes_h2d_descr = cfgd_h2d_pyld_bytes[h2d_port][h2d_ch].sum with (item.index inside {[0:h2d_descr[h2d_port][h2d_ch].num()-2]} ? item:0);
    compare_bytes_d2h_descr = cfgd_h2d_pyld_bytes[h2d_port][h2d_ch].sum with (item.index inside {[0:d2h_descr[d2h_port][d2h_ch].num()-2]} ? item:0);

    // To be fixed
    if ((d2h_descr[d2h_port][d2h_ch].num() >= h2d_descr[h2d_port][h2d_ch].num()) &&
        // (d2h_payload[d2h_port][d2h_ch].num() != h2d_payload[h2d_port][h2d_ch].num()))
        (d2h_payload[d2h_port][d2h_ch].num() != compare_bytes_h2d_descr))
      `uvm_error(get_full_name(),
                 $sformatf({"\n%0d D2H descriptors fetched for port %0d, ch %0d >= %0d H2D Descriptors fetched for port %0d, ch %0d\n",
                            "No of bytes %0d received at d2h port %0d, ch %0d is not same as transferred %0d bytes from h2d port %0d, ch %0d"},
                           d2h_descr[d2h_port][d2h_ch].num(), d2h_port, d2h_ch, h2d_descr[h2d_port][h2d_ch].num(), h2d_port, h2d_ch,
                           d2h_payload[d2h_port][d2h_ch].num(), d2h_port, d2h_ch, compare_bytes_h2d_descr, h2d_port, h2d_ch))
                           // d2h_payload[d2h_port][d2h_ch].num(), d2h_port, d2h_ch, h2d_payload[h2d_port][h2d_ch].num(), h2d_port, h2d_ch))
    else if ((d2h_descr[d2h_port][d2h_ch].num() < h2d_descr[h2d_port][h2d_ch].num()) &&
             (d2h_payload[d2h_port][d2h_ch].num() != compare_bytes_d2h_descr))
     `uvm_error(get_full_name(),
                 $sformatf({"\n%0d D2H descriptors fetched for port %0d, ch %0d < %0d H2D Descriptors fetched for port %0d, ch %0d\n",
                            "No of bytes %0d received at d2h port %0d, ch %0d is not same as transferred %0d bytes from h2d port %0d, ch %0d"},
                           d2h_descr[d2h_port][d2h_ch].num(), d2h_port, d2h_ch, h2d_descr[h2d_port][h2d_ch].num(), h2d_port, h2d_ch,
                           d2h_payload[d2h_port][d2h_ch].num(), d2h_port, d2h_ch, compare_bytes_d2h_descr, h2d_port, h2d_ch))
    else begin
      if (d2h_descr[d2h_port][d2h_ch].num() >= h2d_descr[h2d_port][h2d_ch].num()) begin
        `uvm_info(get_full_name(),
                  $sformatf("\nNo of bytes recvd %0d @ d2h[%0d][%0d] is same as transferred %0d from h2d[%0d][%0d]",
                            d2h_payload[d2h_port][d2h_ch].num(), d2h_port, d2h_ch, compare_bytes_h2d_descr, h2d_port, h2d_ch),
                            // d2h_payload[d2h_port][d2h_ch].num(), d2h_port, d2h_ch, h2d_payload[h2d_port][h2d_ch].num(), h2d_port, h2d_ch),
                  UVM_NONE)
      end else begin
        `uvm_info(get_full_name(),
                  $sformatf("\nNo of bytes recvd %0d @ d2h[%0d][%0d] is same as transferred %0d from h2d[%0d][%0d]",
                            d2h_payload[d2h_port][d2h_ch].num(), d2h_port, d2h_ch, compare_bytes_d2h_descr, h2d_port, h2d_ch),
                            // d2h_payload[d2h_port][d2h_ch].num(), d2h_port, d2h_ch, h2d_payload[h2d_port][h2d_ch].num(), h2d_port, h2d_ch),
                  UVM_NONE)
      end
    end

    foreach (h2d_payload[h2d_port][h2d_ch][j]) begin
      `uvm_info(get_full_name(), $sformatf("next H2D[%0d][%0d] mem ptr is @ %0h", h2d_port, h2d_ch, j), UVM_DEBUG)
      h2d_buff_addr.push_back(j);
    end

    foreach (d2h_payload[d2h_port][d2h_ch][j]) begin
      `uvm_info(get_full_name(), $sformatf("next D2H[%0d][%0d] mem ptr is @ %0h", d2h_port, d2h_ch, j), UVM_DEBUG)
      d2h_buff_addr.push_back(j);
    end

    repeat (d2h_payload[d2h_port][d2h_ch].num()) begin
      h2d_addr = h2d_buff_addr.pop_front();
      d2h_addr = d2h_buff_addr.pop_front();

      `uvm_info(get_full_name(),
                $sformatf("POPPED:\nh2d_addr %0h\nd2h addr %0h", h2d_addr, d2h_addr), UVM_DEBUG)

      if (d2h_payload[d2h_port][d2h_ch][d2h_addr] !== h2d_payload[h2d_port][h2d_ch][h2d_addr])
        `uvm_error(get_full_name(),
                   $sformatf("\nPayload received at port%0d, chan %0d @ %0h = %0h, not same as tx at port%0d, chan %0d @ %0h = %0h",
                             d2h_port, d2h_ch, d2h_addr, d2h_payload[d2h_port][d2h_ch][d2h_addr],
                             h2d_port, h2d_ch, h2d_addr, h2d_payload[h2d_port][h2d_ch][h2d_addr]))
      else
        `uvm_info(get_full_name(),
                  $sformatf("\nPayload received at port%0d, chan %0d @ %0h = %0h, same as tx at port%0d, chan %0d @ %0h = %0h",
                            d2h_port, d2h_ch, d2h_addr, d2h_payload[d2h_port][d2h_ch][d2h_addr],
                            h2d_port, h2d_ch, h2d_addr, h2d_payload[h2d_port][h2d_ch][h2d_addr]),
                  UVM_DEBUG)
    end

`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
    // TS comparison
    ts_compare_size = d2h_wrbk_ts[d2h_port][d2h_ch].size();
    for (int i=0; i<ts_compare_size; i++) begin
      d2h_ts = d2h_wrbk_ts[d2h_port][d2h_ch].pop_front();
      h2d_ts = h2d_wrbk_ts[h2d_port][h2d_ch].pop_front();
      if (d2h_ts[47:16] > h2d_ts[47:16]) ts_diff = d2h_ts[47:16] - h2d_ts[47:16];
      else ts_diff = h2d_ts[47:16] - d2h_ts[47:16];

      // TBD
      if (ts_diff > `SM_PTP_TS_TOLERANCE)
        `uvm_error(get_full_name(),
                   $sformatf({"The difference b/w H2D TS %0d:%0d:%0d (port %0d, chan %0d)",
                              " and D2H TS %0d:%0d:%0d (port %0d, chan %0d) is (%0d) greater than",
                              " expected %d for %0d descriptor"},
                             h2d_ts[95:48], h2d_ts[47:16], h2d_ts[15:0], h2d_port, h2d_ch,
                             d2h_ts[95:48], d2h_ts[47:16], d2h_ts[15:0], d2h_port, d2h_ch,
                             ts_diff, `SM_PTP_TS_TOLERANCE, i))
      else
        `uvm_info(get_full_name(),
                  $sformatf({"The difference b/w H2D TS %0d:%0d:%0d (port %0d, chan %0d)",
                             " and D2H TS %0d:%0d:%0d (port %0d, chan %0d) is (%0d) expected for %0d descriptor"},
                            h2d_ts[95:48], h2d_ts[47:16], h2d_ts[15:0], h2d_port, h2d_ch,
                            d2h_ts[95:48], d2h_ts[47:16], d2h_ts[15:0], d2h_port, d2h_ch, ts_diff, i),
                  UVM_LOW)
        // TBD
        // d2h_eth_ts = p_e_ptp_tr[d2h_port].pop_front();
        // h2d_eth_ts = p_n_ptp_tr[h2d_port].pop_front();
        // if (d2h_ts !== d2h_eth_ts)
        //   `uvm_error(get_full_name(),
        //              $sformatf("TS at Rx WrBk %d is not same as TS at Eth port %d for %0d pkt",
        //                        d2h_ts, d2h_eth_ts, i))
        // if (h2d_ts !== h2d_eth_ts)
        //   `uvm_error(get_full_name(),
        //              $sformatf("TS at Tx WrBk %d is not same as TS at Eth port %d for %0d pkt",
        //                        h2d_ts, h2d_eth_ts, i))
    end
`endif
  endfunction: compare_data_bw_ports

  // --------------------------------------------------------------------------
  // --------------------------------------------------------------------------
  virtual function void h2h_perf_data(
    bit [1:0] h2d_port, bit [1:0] h2d_ch,
    bit [1:0] d2h_port, bit [1:0] d2h_ch
  );
    real h2h_perf_data;

    h2h_perf_data = (h2d_payload[h2d_port][h2d_ch].num()*8) / (d2h_last_resp_desc_time[d2h_port][d2h_ch]-h2d_desc_fetch_start_time[h2d_port][h2d_ch]);

    `uvm_info(get_full_name(),
              $sformatf({"PERFORMACE DATA:\n",
                         "port %0d, chan %0d to port %0d, chan %0d performance = %.4f Gb/s\n"},
                        h2d_port, h2d_ch, d2h_port, d2h_ch, h2h_perf_data), 
              UVM_NONE)
  endfunction: h2h_perf_data

  // --------------------------------------------------------------------------
  // --------------------------------------------------------------------------
  function void final_phase(uvm_phase phase);
    super.final_phase(phase);
  endfunction: final_phase

endclass : sm_ptp_msgdma_subscriber

`endif
