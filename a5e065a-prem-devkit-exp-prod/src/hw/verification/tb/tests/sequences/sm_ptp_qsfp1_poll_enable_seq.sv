`ifndef SM_PTP_QSFP1_POLL_ENABLE_SEQ__SV
  `define SM_PTP_QSFP1_POLL_ENABLE_SEQ__SV

class sm_ptp_qsfp1_poll_enable_seq extends sm_ptp_qsfp_basic_seq;
  rand bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] addr;
  `uvm_object_utils(sm_ptp_qsfp1_poll_enable_seq)

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  function new(name = "sm_ptp_qsfp1_poll_enable_seq");
    super.new(name);
  endfunction: new

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task body();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] rd_data [];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] wr_data[];
    bit [`SVT_AXI_WSTRB_WIDTH-1:0] 	  wstrb [];

    init_sfp();
    #40us;

    wr_data = new[1];
    wstrb   = new[1];

    wr_data[0] = 64'h0000_0000_0000_0014; // QSFP1 selected and poll enable

    wstrb[0]   = 8'hFF;
    axi_master_write(.address(`SM_PTP_QSFP1_SYSTEM_OFFSET + 'h20),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_64BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));
	
    
    while (rd_data[0][41] != 1) begin
      axi_master_read(.address(`SM_PTP_QSFP1_SYSTEM_OFFSET + 'h28),
                      .burst_sz(svt_axi_transaction::BURST_SIZE_64BIT),
                      .data(rd_data), .burst_length(1));
      foreach (rd_data[r])
        `uvm_info(get_full_name(),
                  $sformatf("data read from ReadData register CSR is rdata[%0d] %0h", r, rd_data[r]),
                  UVM_LOW)
    end

    //QSFP1 shadow register
    for (int i=0;i< 16; i++) begin
	  axi_master_read(.address(`SM_PTP_QSFP1_SYSTEM_OFFSET + 'h100 + (i*8)),
                    .burst_sz(svt_axi_transaction::BURST_SIZE_64BIT),
                    .data(rd_data), .burst_length(1));
      foreach (rd_data[r])
      `uvm_info(get_full_name(),
                $sformatf("data read from QSFP1 Shadow register is rdata[%0d] %0h", r, rd_data[r]),
                UVM_LOW)
    end

  endtask: body
endclass: sm_ptp_qsfp1_poll_enable_seq

`endif
