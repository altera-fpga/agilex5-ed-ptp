//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//#########################################################################

`ifndef SM_PTP_EHIP_PORT_MONITOR__SV
`define SM_PTP_EHIP_PORT_MONITOR__SV

class sm_ptp_ehip_port_monitor extends uvm_monitor;

  sm_ptp_ehip_port_tr p_n_pkt[`SM_PTP_MAX_CHANNELS];
  sm_ptp_ehip_port_tr p_e_pkt[`SM_PTP_MAX_CHANNELS];
  virtual sm_ptp_ehip_port_if vif;

  uvm_analysis_port #(sm_ptp_ehip_port_tr) port_p_n[`SM_PTP_MAX_CHANNELS];
  uvm_analysis_port #(sm_ptp_ehip_port_tr) port_p_e[`SM_PTP_MAX_CHANNELS];

  bit p_n_first_sop[`SM_PTP_MAX_CHANNELS];
  bit p_e_first_sop[`SM_PTP_MAX_CHANNELS];

  `uvm_component_utils(sm_ptp_ehip_port_monitor)

  //---------------------------------------------------------------------------
  function new(string name="sm_ptp_ehip_port_monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction: new

  //---------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    foreach (port_p_n[i]) port_p_n[i] = new($sformatf("port_p_n[%0d]", i), this);
    foreach (port_p_e[i]) port_p_e[i] = new($sformatf("port_p_e[%0d]", i), this);
    foreach (p_e_pkt[i]) p_e_pkt[i] = new($sformatf("p_e_pkt[%0d]", i));
    foreach (p_n_pkt[i]) p_n_pkt[i] = new($sformatf("p_n_pkt[%0d]", i));
    if(!uvm_config_db#(virtual sm_ptp_ehip_port_if)::get(this, "", "vif", vif))
       `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
  endfunction: build_phase

  //---------------------------------------------------------------------------
  task run();
    foreach (p_n_first_sop[i]) p_n_first_sop[i] = 0;
    foreach (p_e_first_sop[i]) p_e_first_sop[i] = 0;

    for (bit [2:0] j=0; j<`SM_PTP_NUM_CHANNELS; j++) begin
      fork 
        collect_ingress(j);
        collect_ingress_ptp(j);
        collect_egress(j);
        collect_egress_ptp(j);
      join_none
      #0;
    end
  endtask: run

  //---------------------------------------------------------------------------
  task collect_ingress(bit [2:0] port_num);
    p_n_pkt[port_num].port = port_num;
    forever begin
      `uvm_info(get_full_name(), $sformatf("p%0d ingress: wait for SOP", port_num), UVM_LOW)
      wait (vif.p_ingress_sop[port_num]);
      `uvm_info(get_full_name(), $sformatf("p%0d ingress: wait for SOP to be valid", port_num), UVM_LOW)
      wait ((vif.p_ingress_valid[port_num] == 1) && (vif.p_ingress_ready[port_num] == 1));
      if (p_n_first_sop[port_num] == 0) begin
        p_n_pkt[port_num].sop_time = ($realtime/1ns);
        p_n_first_sop[port_num] = 1;
        `uvm_info(get_full_name(),
                  $sformatf("p%0d ingress: p_n_pkt.sop_time %0t", port_num, p_n_pkt[port_num].sop_time),
                  UVM_LOW)
        if (vif.p_ingress_eop[port_num] === 1) begin
          `uvm_info(get_full_name(), $sformatf("p%0d ingress: EOP detected w/ SOP", port_num), UVM_LOW)
          p_n_pkt[port_num].eop_time = ($realtime/1ns);
        end
        p_n_pkt[port_num].data.push_back(vif.p_ingress_data[port_num]);
        `uvm_info(get_full_name(), $sformatf("p%0d ingress: data collected", port_num), UVM_LOW)
      end
      while (vif.p_ingress_eop[port_num] !== 1) begin
        @ (posedge vif.p_ingress_clk[port_num]);
        `uvm_info(get_full_name(), $sformatf("p%0d ingress: wait for valid ready", port_num), UVM_LOW)
        wait ((vif.p_ingress_valid[port_num] == 1) && (vif.p_ingress_ready[port_num] == 1));
        if (vif.p_ingress_eop[port_num] === 1) begin
          `uvm_info(get_full_name(), $sformatf("p%0d ingress: EOP detected", port_num), UVM_LOW)
          p_n_pkt[port_num].eop_time = ($realtime/1ns);
        end
        p_n_pkt[port_num].data.push_back(vif.p_ingress_data[port_num]);
        `uvm_info(get_full_name(), $sformatf("p%0d ingress: data collected", port_num), UVM_LOW)
      end
      `uvm_info(get_full_name(), $sformatf("p%0d ingress: write to TLM", port_num), UVM_LOW)
      port_p_n[port_num].write(p_n_pkt[port_num]);
    end
  endtask: collect_ingress

  //---------------------------------------------------------------------------
  task collect_ingress_ptp(bit [2:0] port_num);
    p_n_pkt[port_num].port = port_num;
    p_n_pkt[port_num].ptp_pkt = 1;

    forever begin
      `uvm_info(get_full_name(),
                $sformatf("p%0d ingress ptp: wait for ptp valid and ready", port_num), UVM_LOW)
      wait (vif.p_ingress_ets_valid[port_num] && vif.p_ingress_ets_ready[port_num]);
      p_n_pkt[port_num].ptp_ets = vif.p_ingress_ets[port_num];
      `uvm_info(get_full_name(), $sformatf("p%0d ingress ptp: write to TLM", port_num), UVM_LOW)
      port_p_n[port_num].write(p_n_pkt[port_num]);
    end
  endtask: collect_ingress_ptp

  //---------------------------------------------------------------------------
  task collect_egress(bit [2:0] port_num);
    p_e_pkt[port_num].port = port_num;
    forever begin
      `uvm_info(get_full_name(), $sformatf("p%0d egress: wait for SOP at", port_num), UVM_LOW)
      wait (vif.p_egress_sop[port_num]);
      if (p_e_first_sop[port_num] == 0) begin
        p_e_pkt[port_num].sop_time = ($realtime/1ns);
        p_e_first_sop[port_num] = 1;
        `uvm_info(get_full_name(),
                  $sformatf("p%0d egress: p_e_pkt.sop_time %0t", port_num, p_e_pkt[port_num].sop_time),
                  UVM_LOW)
        if (vif.p_egress_eop[port_num] === 1) begin
          `uvm_info(get_full_name(), $sformatf("p%0d egress: EOP detected w/ SOP", port_num), UVM_LOW)
          p_e_pkt[port_num].eop_time = ($realtime/1ns);
        end
        p_e_pkt[port_num].data.push_back(vif.p_egress_data[port_num]);
        `uvm_info(get_full_name(), $sformatf("p%0d egress: data collected", port_num), UVM_LOW)
      end
      while (vif.p_egress_eop[port_num] !== 1) begin
        @ (posedge vif.p_egress_clk[port_num]);
        `uvm_info(get_full_name(), $sformatf("p%0d egress: wait for valid", port_num), UVM_LOW)
        wait (vif.p_egress_valid[port_num] == 1);
        if (vif.p_egress_eop[port_num] === 1) begin
          `uvm_info(get_full_name(), $sformatf("p%0d egress: EOP detected", port_num), UVM_LOW)
          p_e_pkt[port_num].eop_time = ($realtime/1ns);
        end
        p_e_pkt[port_num].data.push_back(vif.p_egress_data[port_num]);
        `uvm_info(get_full_name(), $sformatf("p%0d egress: data collected", port_num), UVM_LOW)
      end
      `uvm_info(get_full_name(), $sformatf("p%0d egress: write to TLM", port_num), UVM_LOW)
      port_p_e[port_num].write(p_e_pkt[port_num]);
    end
  endtask: collect_egress

  //---------------------------------------------------------------------------
  task collect_egress_ptp(bit [2:0] port_num);
    p_e_pkt[port_num].port = port_num;
    p_e_pkt[port_num].ptp_pkt = 1;

    forever begin
      `uvm_info(get_full_name(),
                $sformatf("p%0d egress ptp: wait for ptp valid and ready", port_num), UVM_LOW)
      wait (vif.p_egress_ets_valid[port_num] && vif.p_egress_ets_ready[port_num]);
      p_e_pkt[port_num].ptp_ets = vif.p_egress_ets[port_num];
      `uvm_info(get_full_name(), $sformatf("p%0d egress ptp: write to TLM", port_num), UVM_LOW)
      port_p_e[port_num].write(p_e_pkt[port_num]);
    end
  endtask: collect_egress_ptp
endclass: sm_ptp_ehip_port_monitor

`endif
