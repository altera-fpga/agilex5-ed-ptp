//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

module packet_switch_dbg_cntr #(
    parameter CNTR_WIDTH=32,
    parameter NUM_CNTR=1
)(
   input logic                                    clk
  ,input logic                                    rst
  ,input logic [NUM_CNTR-1:0]                     enable
  ,input logic [NUM_CNTR-1:0] [CNTR_WIDTH-1:0]    cntr_i
  ,output logic [NUM_CNTR-1:0] [CNTR_WIDTH-1:0]   cntr_o
);

  always_comb begin
    for (int cntr_n = 0; cntr_n < NUM_CNTR; cntr_n++) begin
      cntr_o[cntr_n] = enable[cntr_n] ? cntr_i[cntr_n] + 1'b1 : cntr_i[cntr_n];
    end
  end

endmodule
