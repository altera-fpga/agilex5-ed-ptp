//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//#########################################################################

/**
 * Abstract: 
 * class 'sm_ptp_env' is extended from uvm_env base class.  It implements
 * the build phase to construct the structural elements of this sm_ptp_env.
 *
 * sm_ptp_env is the testbench sm_ptp_env, which constructs the AXI System
 * ENV in the build_phase method using the UVM factory service.  The AXI System
 * ENV  is the top level component provided by the AXI VIP. The AXI System ENV
 * in turn, instantiates constructs the AXI Master and Slave agents. 
 *
 * axi_basic env also constructs the virtual sequencer. This virtual sequencer
 * in the testbench sm_ptp_env obtains a handle to the reset interface using
 * the config db.  This allows reset sequences to be written for this virtual
 * sequencer.
 *
 * The simulation ends after all the objections are dropped.  This is done by
 * using objections provided by phase arguments.
 */
`ifndef ENVIRONMENT_SV
`define ENVIRONMENT_SV

`include "sm_ptp_reset_sequencer.sv"
`include "cust_svt_axi_system_configuration.sv"
`include "sm_ptp_err_catcher.sv"

class sm_ptp_env extends uvm_env;

  /** AXI System ENV */
  svt_axi_system_env   axi_system_env;
  
  /** Reset Sequencer */
  sm_ptp_reset_sequencer rst_sequencer;
  
  /** AXI System Configuration */
  cust_svt_axi_system_configuration cfg;

  sm_ptp_msgdma_subscriber sm_sub;
  
  // QSFP Slave agent instance
  qsfp_slave_env         i2c_slv_env; 

  // sm_ptp_ehip_port_monitor ehip_port_mon;

  /** Report catcher */
  sm_ptp_err_catcher err_catcher;

  /** UVM Component Utility macro */
  `uvm_component_utils_begin(sm_ptp_env)
    `uvm_field_object(axi_system_env, UVM_ALL_ON)
    `uvm_field_object(rst_sequencer,  UVM_ALL_ON)
    `uvm_field_object(cfg,            UVM_ALL_ON)
    `uvm_field_object(sm_sub,         UVM_ALL_ON)
    `uvm_field_object(i2c_slv_env, UVM_ALL_ON)
  `uvm_component_utils_end

  //======================================================
  // new
  //======================================================
  function new (string name="sm_ptp_env", uvm_component parent=null);
    super.new (name, parent);
  endfunction

  //======================================================
  // build
  //======================================================
  virtual function void build_phase(uvm_phase phase);
    `uvm_info("build_phase", "Entered...",UVM_LOW)
    
    super.build_phase(phase);
    
    /**
    * Check if the configuration is passed to the sm_ptp_env.
    * If not then create the configuration and pass it to the agent.
    */
    if (uvm_config_db#(cust_svt_axi_system_configuration)::get(this, "", "cfg", cfg)) begin
      /** Apply the configuration to the System ENV */
      uvm_config_db#(svt_axi_system_configuration)::set(this, "axi_system_env", "cfg", cfg);
    end
    // No configuration passed from test
    else begin
      cfg = cust_svt_axi_system_configuration::type_id::create("cfg");
      /** Apply the configuration to the System ENV */
      uvm_config_db#(svt_axi_system_configuration)::set(this, "axi_system_env", "cfg", cfg);
      // `uvm_fatal(get_full_name(), "uvm config db :: get cfg failed ...")
    end

    /** Construct the reset_sequencer */
    rst_sequencer = sm_ptp_reset_sequencer::type_id::create("rst_sequencer", this);
    
    /** Construct the system agent */
    axi_system_env = svt_axi_system_env::type_id::create("axi_system_env", this);

    /** Construct sm eth subscriber */
    sm_sub = sm_ptp_msgdma_subscriber::type_id::create("sm_sub", this);

    /** Construct I2C Slave component*/
    i2c_slv_env = qsfp_slave_env::type_id::create("i2c_slv_env", this);
    
    // ehip_port_mon = sm_ptp_ehip_port_monitor::type_id::create("ehip_port_mon", this);
    
    /** Create report catcher to suppress expected error/warning messages */
    err_catcher = new({get_name(),".err_catcher"});
    uvm_report_cb::add(null,err_catcher);

    `uvm_info("build_phase", "Exiting...", UVM_LOW)
  endfunction

  //======================================================
  // connect
  //======================================================
  // Connect master & slave agent analysis ports to scoreboard and listener classes
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info("connect_phase", "Entered...",UVM_LOW)
    /*-------------------------------
     AXI4 Master [0] - host csr 
     AXI4 Slave [0] -  host slave w/ memory    
    -------------------------------*/

    axi_system_env.slave[0].monitor.item_observed_port.connect(sm_sub.axi_port);
    // for (bit [2:0] i=0; i<`SM_PTP_NUM_CHANNELS; i++) begin
    //   ehip_port_mon.port_p_n[i].connect(sm_sub.item_p_n[i]);
    //   ehip_port_mon.port_p_e[i].connect(sm_sub.item_p_e[i]);
    // end

    `uvm_info("connect_phase", "Exiting...", UVM_LOW)
  endfunction
endclass

`endif // ENVIRONMENT_SV
