//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//########################################################################
// Description:
// This sequence exercises few CSR addresses to showcase reads to register
// space of user CSR space

`ifndef SM_PTP_USER_CSR_SEQ__SV
`define SM_PTP_USER_CSR_SEQ__SV

class sm_ptp_user_csr_seq extends sm_ptp_basic_seq;
  `uvm_object_utils(sm_ptp_user_csr_seq)

  // ----------------------------------------------------------------------
  function new (string name = "sm_ptp_user_csr_seq");
    super.new(name);
  endfunction: new

  // ----------------------------------------------------------------------
  virtual task body();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data [];

    super.body();
    
	 
    for (int addr=`SM_PTP_USER_CSR; addr<`SM_PTP_USER_CSR+12; addr=addr+4) begin
      axi_master_read(
                      .address(addr),
                      .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                      .burst_length(1),
                      .data(data)
      );
    end
	
  endtask: body
endclass: sm_ptp_user_csr_seq

`endif // SM_PTP_USER_CSR_SEQ__SV
