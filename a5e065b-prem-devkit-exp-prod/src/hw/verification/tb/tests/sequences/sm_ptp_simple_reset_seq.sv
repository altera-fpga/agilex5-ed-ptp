//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//########################################################################

`ifndef SM_PTP_SIMPLE_RESET_SEQ__SV
`define SM_PTP_SIMPLE_RESET_SEQ__SV

class sm_ptp_simple_reset_seq extends uvm_sequence;
  `uvm_declare_p_sequencer(sm_ptp_reset_sequencer)

  int wait_for_clk_cycles = 10;
  int rst_width_in_clk_cycles = 10;
  bit rst_cycle_complete = 0;

  `uvm_object_utils(sm_ptp_simple_reset_seq)

  function new (string name = "sm_ptp_simple_reset_seq");
    super.new(name);
  endfunction: new

  virtual task pre_body();
    uvm_phase starting_phase;

    `uvm_info(get_full_name(), "pre_body: enter get_Starting_phase", UVM_DEBUG)
    starting_phase = get_starting_phase();
    `uvm_info(get_full_name(), "pre_body: exit get_Starting_phase", UVM_DEBUG)
    if (starting_phase != null) begin
      `uvm_info(get_full_name(),
                $sformatf("%s pre_body() raising %s objection",
                           get_sequence_path(), starting_phase.get_name()),
                UVM_DEBUG)
      starting_phase.raise_objection(this);
    end else
      `uvm_info(get_full_name(), "pre_body : starting phase is null", UVM_DEBUG)
  endtask
  
  virtual task body();

    `uvm_info(get_full_name(), "body: Entered ...", UVM_LOW)

    rst_cycle_complete = 0;
    wait (p_sequencer.reset_mp.ninit_done == 0);

    p_sequencer.reset_mp.resetn <= 1;
    repeat (wait_for_clk_cycles) @(posedge p_sequencer.reset_mp.clk);
    #2;
    p_sequencer.reset_mp.resetn <= 0;
    repeat (rst_width_in_clk_cycles) @(posedge p_sequencer.reset_mp.clk);
    p_sequencer.reset_mp.resetn <= 1;
    #100ns;
    rst_cycle_complete = 1;
    `uvm_info(get_full_name(), "body: Exiting ...", UVM_LOW)
  endtask: body

  virtual task post_body();
    uvm_phase starting_phase;

    `uvm_info(get_full_name(), "post_body: enter get_Starting_phase", UVM_DEBUG)
    starting_phase = get_starting_phase();
    `uvm_info(get_full_name(), "post_body: exit get_Starting_phase", UVM_DEBUG)
    if (starting_phase != null) begin
      `uvm_info(get_type_name(),
                $sformatf("%s post_body() dropping %s objection",
                          get_sequence_path(), starting_phase.get_name()),
                UVM_MEDIUM);
      starting_phase.drop_objection(this);
    end else
      `uvm_info(get_full_name(), "post_body : starting phase is null", UVM_DEBUG)
  endtask
endclass: sm_ptp_simple_reset_seq

`endif // SM_PTP_SIMPLE_RESET_SEQ__SV
