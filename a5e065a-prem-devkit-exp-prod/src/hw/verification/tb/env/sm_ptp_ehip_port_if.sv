//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//#########################################################################

`ifndef SM_PTP_EHIP_PORT_IF__SV
`define SM_PTP_EHIP_PORT_IF__SV

interface sm_ptp_ehip_port_if;
  // port ingress
  logic p_ingress_clk[`SM_PTP_MAX_PORTS];
  logic p_ingress_data[`SM_PTP_MAX_PORTS];
  logic p_ingress_valid[`SM_PTP_MAX_PORTS];
  logic p_ingress_ready[`SM_PTP_MAX_PORTS];
  logic p_ingress_sop[`SM_PTP_MAX_PORTS];
  logic p_ingress_eop[`SM_PTP_MAX_PORTS];
  logic p_ingress_error[`SM_PTP_MAX_PORTS];
  //ptp signals
  logic p_ingress_ets_valid[`SM_PTP_MAX_PORTS];
  logic p_ingress_ets_ready[`SM_PTP_MAX_PORTS];
  logic [95:0] p_ingress_ets[`SM_PTP_MAX_PORTS];

  // port egress
  logic p_egress_clk[`SM_PTP_MAX_PORTS];
  logic p_egress_data[`SM_PTP_MAX_PORTS];
  logic p_egress_valid[`SM_PTP_MAX_PORTS];
  logic p_egress_ready[`SM_PTP_MAX_PORTS];
  logic p_egress_sop[`SM_PTP_MAX_PORTS];
  logic p_egress_eop[`SM_PTP_MAX_PORTS];
  logic p_egress_error[`SM_PTP_MAX_PORTS];
  //ptp signals
  logic p_egress_ets_valid[`SM_PTP_MAX_PORTS];
  logic p_egress_ets_ready[`SM_PTP_MAX_PORTS];
  logic [95:0] p_egress_ets[`SM_PTP_MAX_PORTS];
endinterface

`endif
