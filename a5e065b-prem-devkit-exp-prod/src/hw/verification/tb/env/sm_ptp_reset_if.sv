//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//#########################################################################

/**
 * Abstract:
 * Defines an interface that provides access to a reset signal.  This
 * interface can be used to write sequences to drive the reset logic.
 */

`ifndef SM_PTP_RESET_IF__SV
`define SM_PTP_RESET_IF__SV

interface sm_ptp_reset_if();

  logic resetn;
  logic clk;
  logic ninit_done;

  modport axi_reset_modport (input clk, input ninit_done, output resetn);

endinterface

`endif // SM_PTP_RESET_IF__SV
