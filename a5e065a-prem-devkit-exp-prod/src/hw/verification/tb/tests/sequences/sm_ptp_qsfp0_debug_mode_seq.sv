//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//#########################################################################

`ifndef SM_PTP_QSFP0_DEBUG_MODE_SEQ__SV
  `define SM_PTP_QSFP0_DEBUG_MODE_SEQ__SV

class sm_ptp_qsfp0_debug_mode_seq extends sm_ptp_qsfp_basic_seq;
  rand bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] addr;
  `uvm_object_utils(sm_ptp_qsfp0_debug_mode_seq)

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  function new(name = "sm_ptp_qsfp0_debug_mode_seq");
    super.new(name);
  endfunction: new
 // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task body();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] wr_data [];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] rd_data [];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] rd_data0 [];
    bit [`SVT_AXI_WSTRB_WIDTH-1:0] 	  wstrb [];


    init_sfp();
	wr_data = new[1];
    wstrb   = new[1];
    #40us;
   wr_data[0] = 64'h0000_0000_0000_0004; // QSFP selected

    wstrb[0]   = 8'hFF;
    axi_master_write(.address(`SM_PTP_QSFP0_SYSTEM_OFFSET + 'h20),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_64BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));
    #1us;
	

    repeat(1) begin
     int addr;

     std::randomize(addr) with {addr inside {[0:127]};};

     read_a0(addr);
     #14us;

     axi_master_read(.address(`SM_PTP_QSFP0_SYSTEM_OFFSET + 'h44),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                     .data(rd_data), .burst_length(1));
     foreach (rd_data[r])
       `uvm_info(get_full_name(),
                 $sformatf("data read from QSFP0 FIFO register is rdata[%0d] %0h", r, rd_data[r]),
                 UVM_LOW)
    end
    #1us;

  endtask: body
endclass: sm_ptp_qsfp0_debug_mode_seq

`endif
