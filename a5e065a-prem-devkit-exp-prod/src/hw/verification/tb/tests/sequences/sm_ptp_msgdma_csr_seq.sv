//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//########################################################################

`ifndef SM_PTP_MSGDMA_CSR_SEQ__SV
`define SM_PTP_MSGDMA_CSR_SEQ__SV

class sm_ptp_msgdma_csr_seq extends sm_ptp_basic_seq;
  `uvm_object_utils(sm_ptp_msgdma_csr_seq)

  // ----------------------------------------------------------------------
  function new (string name = "sm_ptp_msgdma_csr_seq");
    super.new(name);
  endfunction: new

  // ----------------------------------------------------------------------
  virtual task body();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data [];

    super.body();
    
    repeat (100) begin
      int test_addr;

      std::randomize(test_addr) with {
              test_addr inside {[`SM_PTP_SSGDMA_CSR_ADDR:`SM_PTP_SSGDMA_CSR_ADDR+'hFF]};
              test_addr%4 == 0;
      };

      `uvm_info(get_full_name(),
                $sformatf("Reading address %0h", test_addr),
                UVM_LOW)
      axi_master_read(
                      .address(test_addr),
                      .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                      .burst_length(1),
                      .data(data)
      );
    end
  endtask: body
endclass: sm_ptp_msgdma_csr_seq

`endif // SM_PTP_MSGDMA_CSR_SEQ__SV
