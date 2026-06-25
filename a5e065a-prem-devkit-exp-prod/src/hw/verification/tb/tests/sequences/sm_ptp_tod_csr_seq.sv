//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//########################################################################
// Description:
// This sequence exercises few CSR addresses to showcase reads to register
// space of master TOD block

`ifndef SM_PTP_TOD_CSR_SEQ__SV
`define SM_PTP_TOD_CSR_SEQ__SV

class sm_ptp_tod_csr_seq extends sm_ptp_basic_seq;
  `uvm_object_utils(sm_ptp_tod_csr_seq)

  // ----------------------------------------------------------------------
  function new (string name = "sm_ptp_tod_csr_seq");
    super.new(name);
  endfunction: new

  // ----------------------------------------------------------------------
  virtual task body();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data [];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] reg_data[];
	 bit [`SVT_AXI_WSTRB_WIDTH-1:0] wstrb[];

    //TOD Registers	 
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] temp_data[];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] tod_data[];

    super.body();
    
    temp_data = new[1];
    tod_data = new[17];
    reg_data = new[1];
    wstrb = new[1];
    wstrb[0] = 'hFF;
	 
   //TOD register read to check POR data
   for (int i=0;i< 18; i++) begin
	   axi_master_read(
            .address('h4405_0000 + (i*4)),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .burst_length(1),
            .data(temp_data)
           );

	   `uvm_info(get_full_name(),
      		     $sformatf("Check: TOD data read from CSR Addr:[%0h] Data:%0h", ('h4405_0000 + (i*4)), temp_data[0]),
                     UVM_LOW)

	   tod_data[i]=temp_data[0];
	end

	foreach(tod_data[i])begin
		`uvm_info(get_full_name(),
                          $sformatf("TOD data read from CSR Addr:[%0h] Data:%0h", ('h4405_0000 + (i*4)), tod_data[i]),
                          UVM_LOW)
		  end

    //TOD register read/write check
    reg_data[0] = 'h55555555;
    for (int i=0;i< 18; i++) begin
	    axi_master_write(
            .address('h4405_0000 + (i*4)),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(reg_data),
            .burst_length(1),
            .wstrb(wstrb)
    );
    end
    for (int i=0;i< 18; i++) begin
	   axi_master_read(
            .address('h4405_0000 + (i*4)),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .burst_length(1),
            .data(temp_data)
           );

	   `uvm_info(get_full_name(),
      		     $sformatf("After Write. Check: TOD data read from CSR Addr:[%0h] Data:%0h", ('h4405_0000 + (i*4)), temp_data[0]),
                     UVM_LOW)

	   tod_data[i]=temp_data[0];
	end

	foreach(tod_data[i])begin
		`uvm_info(get_full_name(),
                          $sformatf("After Write. TOD data read from CSR Addr:[%0h] Data:%0h", ('h4405_0000 + (i*4)), tod_data[i]),
                          UVM_LOW)
		  end
  endtask: body
endclass: sm_ptp_tod_csr_seq

`endif // SM_PTP_TOD_CSR_SEQ__SV
