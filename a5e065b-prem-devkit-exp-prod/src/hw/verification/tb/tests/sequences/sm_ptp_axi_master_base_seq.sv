//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//#########################################################################
// Description:
// This is base sequence used in to initiate Write/Read transactions on the
// CSR space of each block in the design via AXI interface

`ifndef SM_PTP_AXI_MASTER_BASE_SEQ__SV
`define SM_PTP_AXI_MASTER_BASE_SEQ__SV

class sm_ptp_axi_master_base_seq extends svt_axi_master_base_sequence;

  rand bit [`SVT_AXI_MAX_ADDR_WIDTH-1:0]        addr;
  rand int                                      addr_valid_delay;
  rand svt_axi_transaction::xact_type_enum    	xact_type;
  rand bit [`SVT_AXI_MAX_BURST_LENGTH_WIDTH:0]  burst_length;
  rand svt_axi_transaction::burst_size_enum   	burst_size;
  rand svt_axi_transaction::burst_type_enum   	burst_type;
  rand bit 	                                    data_before_addr;
  rand bit [`SVT_AXI_WSTRB_WIDTH-1:0] 	        wstrb [];
  rand bit [`SVT_AXI_MAX_DATA_WIDTH-1:0]        data [];
  rand svt_axi_transaction::resp_type_enum      bresp;

  `uvm_object_utils_begin(sm_ptp_axi_master_base_seq)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(burst_length, UVM_ALL_ON)
    `uvm_field_enum(svt_axi_transaction::xact_type_enum, xact_type, UVM_ALL_ON)
    `uvm_field_enum(svt_axi_transaction::burst_size_enum, burst_size, UVM_ALL_ON)
    `uvm_field_enum(svt_axi_transaction::burst_type_enum, burst_type, UVM_ALL_ON)
  `uvm_object_utils_end

  function new (string name = "sm_ptp_axi_master_base_seq");
    super.new(name);
  endfunction: new

  virtual task body();
    svt_configuration get_cfg;

    `uvm_info(get_full_name(), "Body: Entered...", UVM_DEBUG)

    /** Obtain a handle to the port configuration */
    p_sequencer.get_cfg(get_cfg);
    if (!$cast(cfg, get_cfg)) begin
      `uvm_fatal("body", "Unable to $cast the configuration to a svt_axi_port_configuration class");
    end

    `uvm_create_on(req, p_sequencer)
    `uvm_info(get_full_name(), "Body: req object created on p_sequencer", UVM_DEBUG)

      `uvm_info(get_full_name(),
                $sformatf(" mst_seq received with \naddr %0d\nxact_type %0s",
                            addr, xact_type),
                UVM_DEBUG)

      req.atomic_type      = svt_axi_transaction::NORMAL;
      req.burst_type       = svt_axi_transaction::INCR; // this.burst_type;
      req.addr_valid_delay = 0;
      req.data_before_addr = 0;
      req.addr             = addr; //32'h100;
      req.xact_type        = xact_type; //svt_axi_transaction::READ;
      req.burst_length     = burst_length; /* 1; */
      req.burst_size       = burst_size; // svt_axi_transaction::BURST_SIZE_32BIT;

      req.port_cfg = cfg;
      req.rready_delay = new[req.burst_length];
      foreach (req.rready_delay[i]) 
        req.rready_delay[i] = 0; // this.rready_delay[i];
      req.rresp        = new[req.burst_length];
      req.data         = new[req.burst_length];
      req.data_user    = new[req.burst_length];
      req.wstrb        = new[req.burst_length];

      if (req.xact_type == svt_axi_transaction::WRITE) begin
        req.wvalid_delay = new[req.burst_length];
        foreach (req.data[i]) req.data[i] = data[i];
        foreach (req.wstrb[i]) req.wstrb[i] = wstrb[i]; // 'h000f;
        req.rresp        = new[0];
      end

      `uvm_info(get_full_name(),
                $sformatf(" mst_seq was received with \naddr %0d\nxact_type %0s",
                            addr, xact_type),
                UVM_DEBUG)

      `uvm_info(get_full_name(), "Body: req is randomized", UVM_DEBUG)

      `uvm_info(get_full_name(),
                $sformatf(" req object randomized with\n%s", req.sprint()),
                UVM_DEBUG)
    // end

    `uvm_send(req)

    `uvm_info(get_full_name(), "get response", UVM_DEBUG);
    get_response(rsp);

    `uvm_info(get_full_name(),
              $sformatf(" req object post uvm_send\n%s", req.sprint()),
              UVM_DEBUG)

    `uvm_info(get_full_name(), "Body: Exiting...", UVM_DEBUG)
  endtask: body

  virtual function bit is_applicable(svt_configuration cfg);
    return 1;
  endfunction : is_applicable
endclass: sm_ptp_axi_master_base_seq

`endif // SM_PTP_AXI_MASTER_BASE_SEQ__SV
