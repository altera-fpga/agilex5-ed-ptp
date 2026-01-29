//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//#########################################################################

`ifndef SM_PTP_BASE_TEST_SV
`define SM_PTP_BASE_TEST_SV

/* include test package */
`include "uvm_pkg.sv"
`include "uvm_macros.svh"

class sm_ptp_base_test extends uvm_test;

  /** Instance of the sm_ptp_env */
  sm_ptp_env env;

  /* place holder */
  //report_catcher scoreboard_report_catcher;

  /** Customized configuration */
  cust_svt_axi_system_configuration cfg;
  
  `uvm_component_utils_begin(sm_ptp_base_test)
    `uvm_field_object(env, UVM_ALL_ON)
    `uvm_field_object(cfg, UVM_ALL_ON)
  `uvm_component_utils_end
  
  //======================================================
  // new
  //======================================================
  function new(string name = "sm_ptp_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  //======================================================
  // build
  //======================================================
  virtual function void build_phase(uvm_phase phase);
    `uvm_info("build_phase", "base test: Entered...", UVM_LOW)
    super.build_phase(phase);
    
    /** Create the configuration object */
    cfg = cust_svt_axi_system_configuration::type_id::create("cfg");

    /** Set configuration in environment */
    uvm_config_db#(cust_svt_axi_system_configuration)::set(this, "env", "cfg", this.cfg);

    env = sm_ptp_env::type_id::create("env", this);

    // `ifdef DEMOTE_ENABLE
    // /** place holder -  Create the report catcher object */
    // scoreboard_report_catcher = report_catcher::type_id::create("scoreboard_report_catcher",this);
    // uvm_report_cb::add(null,scoreboard_report_catcher);
    // `endif

    uvm_config_db#(uvm_object_wrapper)::set(this, "env.axi_system_env.sequencer.main_phase", "default_sequence", sm_ptp_null_virtual_seq::type_id::get());

    /** Apply the default reset sequence */
    uvm_config_db#(uvm_object_wrapper)::set(this, "env.rst_sequencer.reset_phase", "default_sequence", sm_ptp_simple_reset_seq::type_id::get());

    uvm_config_db#(uvm_object_wrapper)::set(this, "env.axi_system_env.master*.sequencer.main_phase", "default_sequence", sm_ptp_null_virtual_seq::type_id::get());

    `uvm_info ("build_phase", "base test: Exiting...",UVM_LOW)
  endfunction

  virtual task reset_phase(uvm_phase phase);
    super.reset_phase(phase);
    `uvm_info("reset_phase", "Entered...", UVM_LOW)
    // phase.raise_objection(this);

    if (`SM_PTP_DUT_IOPLL.locked !== 1) disable_axi_monitor();

    // phase.drop_objection(this);
    `uvm_info("reset_phase", "Exiting...", UVM_LOW)
  endtask

  function void end_of_elaboration_phase(uvm_phase phase);
    `SVT_XVM(root) root = `SVT_XVM(root)::get();
    `uvm_info("end_of_elaboration_phase", "Entered...", UVM_LOW)
    root.print_topology();
    `uvm_info("end_of_elaboration_phase", "Exiting...", UVM_LOW)
  endfunction: end_of_elaboration_phase

  //======================================================
  // run 
  //======================================================
  // TODO::to move all to build phase
  virtual task main_phase(uvm_phase phase);
  
    // run the sequence
    uvm_object    tmp_object;
    uvm_factory   m_factory;
    uvm_sequence  exec_seq;
    
    string seq_name;

    phase.raise_objection(this);
    
    `uvm_info("main_phase", "Entered...", UVM_LOW)
    m_factory = uvm_factory::get();
    
    wait (`SM_PTP_QSYS_TOP.csr_bridges_0.reset_in.out_reset_n === 1);
    repeat(3) @(posedge tb_top.dut.clk_bdg_100_clk);
    enable_axi_monitor();

    if($value$plusargs("seqname=%s", seq_name)) begin
        `uvm_info(get_full_name(), $sformatf("Sequence Name = %s",seq_name), UVM_LOW)   
        tmp_object = m_factory.create_object_by_name(seq_name);
        assert($cast(exec_seq,tmp_object));
        exec_seq.start(env.axi_system_env.sequencer,null);
    end else
      `uvm_fatal("", $psprintf("There is no sequence from command line, please review run command"));

    `uvm_info("main_phase", "Exiting...", UVM_LOW);
    phase.drop_objection(this);
  endtask 

  function disable_axi_monitor();
    foreach (env.axi_system_env.slave[i]) begin
      env.axi_system_env.slave[i].monitor.checks.disable_check(env.axi_system_env.slave[i].monitor.checks.arvalid_low_when_reset_is_active_check);
      env.axi_system_env.slave[i].monitor.checks.disable_check(env.axi_system_env.slave[i].monitor.checks.awvalid_low_when_reset_is_active_check);
      env.axi_system_env.slave[i].monitor.checks.disable_check(env.axi_system_env.slave[i].monitor.checks.wvalid_low_when_reset_is_active_check);
      env.axi_system_env.slave[i].monitor.checks.disable_check(env.axi_system_env.slave[i].monitor.checks.signal_valid_awvalid_check_during_reset);
      env.axi_system_env.slave[i].monitor.checks.disable_check(env.axi_system_env.slave[i].monitor.checks.signal_valid_wvalid_check_during_reset);
      env.axi_system_env.slave[i].monitor.checks.disable_check(env.axi_system_env.slave[i].monitor.checks.signal_valid_arvalid_check_during_reset);
      // env.axi_system_env.slave[i].monitor.checks.disable_check(env.axi_system_env.slave[i].monitor.checks.rvalid_low_when_reset_is_active_check);
      // env.axi_system_env.slave[i].monitor.checks.disable_check(env.axi_system_env.slave[i].monitor.checks.bvalid_low_when_reset_is_active_check);
      // env.axi_system_env.slave[i].monitor.checks.disable_check(env.axi_system_env.slave[i].monitor.checks.signal_valid_rvalid_check_during_reset);
      // env.axi_system_env.slave[i].monitor.checks.disable_check(env.axi_system_env.slave[i].monitor.checks.signal_valid_bvalid_check_during_reset);
    end

      env.axi_system_env.master[0].monitor.checks.disable_check(env.axi_system_env.master[0].monitor.checks.signal_valid_rvalid_check);
      // env.axi_system_env.master[0].monitor.checks.disable_check(env.axi_system_env.master[0].monitor.checks.signal_valid_rvalid_check_during_reset);
      // env.axi_system_env.master[0].monitor.checks.disable_check(env.axi_system_env.master[0].monitor.checks.rvalid_low_when_reset_is_active_check);
      env.axi_system_env.master[0].monitor.checks.disable_check(env.axi_system_env.master[0].monitor.checks.signal_valid_bvalid_check);
      // env.axi_system_env.master[0].monitor.checks.disable_check(env.axi_system_env.master[0].monitor.checks.signal_valid_bvalid_check_during_reset);
      // env.axi_system_env.master[0].monitor.checks.disable_check(env.axi_system_env.master[0].monitor.checks.bvalid_low_when_reset_is_active_check);
      env.axi_system_env.master[0].monitor.checks.disable_check(env.axi_system_env.master[0].monitor.checks.signal_valid_arready_when_arvalid_high_check);
  endfunction: disable_axi_monitor

  function enable_axi_monitor();
    foreach (env.axi_system_env.slave[i]) begin
      env.axi_system_env.slave[i].monitor.checks.enable_check(env.axi_system_env.slave[i].monitor.checks.arvalid_low_when_reset_is_active_check);
      env.axi_system_env.slave[i].monitor.checks.enable_check(env.axi_system_env.slave[i].monitor.checks.awvalid_low_when_reset_is_active_check);
      env.axi_system_env.slave[i].monitor.checks.enable_check(env.axi_system_env.slave[i].monitor.checks.wvalid_low_when_reset_is_active_check);
      env.axi_system_env.slave[i].monitor.checks.enable_check(env.axi_system_env.slave[i].monitor.checks.signal_valid_awvalid_check_during_reset);
      env.axi_system_env.slave[i].monitor.checks.enable_check(env.axi_system_env.slave[i].monitor.checks.signal_valid_wvalid_check_during_reset);
      env.axi_system_env.slave[i].monitor.checks.enable_check(env.axi_system_env.slave[i].monitor.checks.signal_valid_arvalid_check_during_reset);
      // env.axi_system_env.slave[i].monitor.checks.enable_check(env.axi_system_env.slave[i].monitor.checks.rvalid_low_when_reset_is_active_check);
      // env.axi_system_env.slave[i].monitor.checks.enable_check(env.axi_system_env.slave[i].monitor.checks.bvalid_low_when_reset_is_active_check);
      // env.axi_system_env.slave[i].monitor.checks.enable_check(env.axi_system_env.slave[i].monitor.checks.signal_valid_rvalid_check_during_reset);
      // env.axi_system_env.slave[i].monitor.checks.enable_check(env.axi_system_env.slave[i].monitor.checks.signal_valid_bvalid_check_during_reset);
    end

      env.axi_system_env.master[0].monitor.checks.enable_check(env.axi_system_env.master[0].monitor.checks.signal_valid_rvalid_check);
      // env.axi_system_env.master[0].monitor.checks.enable_check(env.axi_system_env.master[0].monitor.checks.signal_valid_rvalid_check_during_reset);
      // env.axi_system_env.master[0].monitor.checks.enable_check(env.axi_system_env.master[0].monitor.checks.rvalid_low_when_reset_is_active_check);
      env.axi_system_env.master[0].monitor.checks.enable_check(env.axi_system_env.master[0].monitor.checks.signal_valid_bvalid_check);
      // env.axi_system_env.master[0].monitor.checks.enable_check(env.axi_system_env.master[0].monitor.checks.signal_valid_bvalid_check_during_reset);
      // env.axi_system_env.master[0].monitor.checks.enable_check(env.axi_system_env.master[0].monitor.checks.bvalid_low_when_reset_is_active_check);
      env.axi_system_env.master[0].monitor.checks.enable_check(env.axi_system_env.master[0].monitor.checks.signal_valid_arready_when_arvalid_high_check);
  endfunction: enable_axi_monitor

  // --------------------------------------------------------------------------
  // --------------------------------------------------------------------------
  function void final_phase(uvm_phase phase);
    uvm_report_server svr;
    `uvm_info("final_phase", "Entered...",UVM_LOW)

    super.final_phase(phase);

    svr = uvm_report_server::get_server();

    if (svr.get_severity_count(UVM_FATAL) +
        svr.get_severity_count(UVM_ERROR) +
        svr.get_severity_count(UVM_WARNING) > 0)
      `uvm_info("final_phase", "\nSvtTestEpilog: Failed\n", UVM_LOW)
    else
      `uvm_info("final_phase", "\nSvtTestEpilog: Passed\n", UVM_LOW)
    `uvm_info("final_phase", "Exiting...", UVM_LOW)
  endfunction: final_phase
endclass
`endif //SM_PTP_BASE_TEST_SV
