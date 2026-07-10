//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//########################################################################
// Description:
// This sequence exercises few CSR addresses to showcase reads to register
// space of hssi block

`ifndef SM_PTP_HSSI_CSR_SEQ__SV
`define SM_PTP_HSSI_CSR_SEQ__SV

class sm_ptp_hssi_csr_seq extends sm_ptp_basic_seq;
  `uvm_object_utils(sm_ptp_hssi_csr_seq)

  // ----------------------------------------------------------------------
  function new (string name = "sm_ptp_hssi_csr_seq");
    super.new(name);
  endfunction: new

  // ----------------------------------------------------------------------
  virtual task body();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data [];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] reg_data[];
	 bit [`SVT_AXI_WSTRB_WIDTH-1:0] wstrb[];
    super.body();
    
	 reg_data = new[1];
    reg_data[0] = 'h1;
	 
	 wstrb = new[1];
    wstrb[0] = 'hFF;
	 
	 axi_master_write(
            .address('h4035_0074),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(reg_data),
            .burst_length(1),
            .wstrb(wstrb)
    );
	 
	   axi_master_read(
            .address('h4035_0074),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .burst_length(1),
            .data(data)
    );
	 
    axi_master_read(
            .address(`SM_PTP_HSSI_CSR_PORT0_HARD_IP),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .burst_length(1),
            .data(data)
    );

    axi_master_read(
            .address('h403C_FFF0),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .burst_length(1),
            .data(data)
    );

   axi_master_read(
           .address('h403C_FFFC),
           .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
           .burst_length(1),
           .data(data)
   );

  endtask: body
endclass: sm_ptp_hssi_csr_seq

`endif // SM_PTP_HSSI_CSR_SEQ__SV
