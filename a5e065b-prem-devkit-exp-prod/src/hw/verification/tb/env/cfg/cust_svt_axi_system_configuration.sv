//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//#########################################################################

/**
 * Abstract:
 * Class cust_svt_axi_system_configuration is used to encapsulate all the 
 * configuration information.  It extends the system configuration and 
 * set the appropriate fields like number of masters/slaves, create 
 * master/slave configurations etc..., which are required by System agent.
 */

`ifndef CUST_SVT_AXI_SYSTEM_CONFIGURATION_SV
`define CUST_SVT_AXI_SYSTEM_CONFIGURATION_SV

// ---------------------------------                
// Configure
// . num_masters = 1 for H2F CSR path
// . num_slaves  = 1 for F2H Data path
// . create port cfgs for master and slave
// ---------------------------------                
class cust_svt_axi_system_configuration extends svt_axi_system_configuration;

  /** UVM Object Utility macro */
  `uvm_object_utils (cust_svt_axi_system_configuration)
  
  /** Class Constructor */
  function new (string name = "cust_svt_axi_system_configuration");

    super.new(name);
    
    // H2F - CSR path
    this.num_masters = 1;
    // F2H - Data path
    this.num_slaves  = 1;
    this.system_monitor_enable = 0;

    this.common_clock_mode = 0;
    
    /** Create port configurations */
    this.create_sub_cfgs(this.num_masters,this.num_slaves);
    
    /** Enable protocol file generation for Protocol Analyzer */
    this.master_cfg[0].enable_xml_gen = 0;
    this.slave_cfg[0].enable_xml_gen = 0;
    
    // this.master_cfg[0].pa_format_type = svt_xml_writer::FSDB;
    // this.slave_cfg[0].pa_format_type= svt_xml_writer::FSDB;

    this.master_cfg[0].transaction_coverage_enable = 0;
    this.slave_cfg[0].transaction_coverage_enable = 0;

    // -----------------------------------------------
    // Connects to the Host CSR Interface.
    // -----------------------------------------------
    this.master_cfg[0].axi_interface_type = svt_axi_port_configuration::AXI4;
    this.slave_cfg[0].axi_interface_type = svt_axi_port_configuration::AXI4;
    master_cfg[0].data_width = 128;
    master_cfg[0].addr_width = 64;
    this.master_cfg[0].id_width = 8;
    
    // Include these will solve the "slave_cfg" error (even though these attributes
    // are not listed in the "AXI SVT UVM" Documentation). AXI4-LITE are not using
    // these signals.
    /*master_cfg[0].awlen_enable  	= 0;
    master_cfg[0].arlen_enable  	= 0;
    master_cfg[0].awsize_enable 	= 0;
    master_cfg[0].arsize_enable 	= 0;
    master_cfg[0].awburst_enable	= 0;
    master_cfg[0].arburst_enable	= 0; 
    master_cfg[0].awlock_enable 	= 0; 
    master_cfg[0].arlock_enable 	= 0; 
    master_cfg[0].awcache_enable	= 0;
    master_cfg[0].arcache_enable	= 0;
    master_cfg[0].wlast_enable   	= 0; 
    master_cfg[0].rlast_enable   	= 0;*/
    
    // -----------------------------------------------
    // Connects to the Host Memory Interface.
    // -----------------------------------------------
    /** Enable protocol file generation for Protocol Analyzer */
    foreach (slave_cfg[i]) begin
      this.slave_cfg[i].axi_interface_type = svt_axi_port_configuration::AXI4;
      slave_cfg[i].data_width = 256;
      slave_cfg[i].id_width = 8;
      slave_cfg[i].awlock_enable = 0;
      slave_cfg[i].awcache_enable = 0;
      slave_cfg[i].arlock_enable = 0;
      slave_cfg[i].arcache_enable = 0;
    end
    // setting secong slave agent as passive, to be only used to monitor
    // sSGDMA host interface as 'address expander' IP does not support
    // unalligned address which causes SB mismatches during READs
    // slave_cfg[1].is_active = 0;
    this.set_addr_range(0,64'h0,64'hffff_ffff_ffff_ffff);
  endfunction
endclass
`endif //CUST_SVT_AXI_SYSTEM_CONFIGURATION_SV
