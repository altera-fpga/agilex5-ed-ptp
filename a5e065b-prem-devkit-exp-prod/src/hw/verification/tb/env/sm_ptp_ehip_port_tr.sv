//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//#########################################################################

`ifndef SM_PTP_EHIP_PORT_TR__SV
`define SM_PTP_EHIP_PORT_TR__SV

class sm_ptp_ehip_port_tr extends uvm_transaction;

  bit [63:0] data[$];
  realtime sop_time;
  realtime eop_time;
  bit [2:0] port;
  // ptp
  bit ptp_pkt;
  bit [95:0] ptp_ets;

  `uvm_object_utils_begin(sm_ptp_ehip_port_tr)
    `uvm_field_queue_int(data, UVM_ALL_ON)
    `uvm_field_real(sop_time , UVM_ALL_ON)
    `uvm_field_real(eop_time , UVM_ALL_ON)
    `uvm_field_int(port      , UVM_ALL_ON)
    `uvm_field_int(ptp_pkt   , UVM_ALL_ON)
    `uvm_field_int(ptp_ets   , UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="sm_ptp_ehip_port_tr");
    super.new(name);
    `uvm_info(get_full_name(), "memory allocated to tr object handle", UVM_NONE)
  endfunction: new
endclass

`endif
