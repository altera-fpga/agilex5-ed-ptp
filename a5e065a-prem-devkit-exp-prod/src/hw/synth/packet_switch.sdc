# ######################################################################## 
# Copyright (C) 2025 Altera Corporation.
# SPDX-License-Identifier: MIT
# ######################################################################## 
# -------------------------------------------------------------------------- #
# constraints for DCFIFO sdc
#
# top-level sdc
# convention for module sdc apply_sdc_<module_name>
#
proc apply_sdc_dcfifo {hier_path} {
# gray_rdptr
apply_sdc_dcfifo_rdptr $hier_path
# gray_wrptr
apply_sdc_dcfifo_wrptr $hier_path
}
#
# common constraint setting proc
#
proc apply_sdc_dcfifo_for_ptrs {from_node_list to_node_list} {
# control skew for bits
#set_max_skew -from $from_node_list -to $to_node_list -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8
set_max_skew -from $from_node_list -to $to_node_list -get_skew_value_from_clock_period min_clock_period -skew_value_multiplier 0.8
# path delay (exception for net delay)
if { ![string equal "quartus_syn" $::TimeQuestInfo(nameofexecutable)] } {
set_net_delay -from $from_node_list -to $to_node_list -max -get_value_from_clock_period dst_clock_period -value_multiplier 0.8
}
#relax setup and hold calculation
set_max_delay -from $from_node_list -to $to_node_list 100
set_min_delay -from $from_node_list -to $to_node_list -100
}
#
# mstable propgation delay
#
proc apply_sdc_dcfifo_mstable_delay {from_node_list to_node_list} {
# mstable delay
if { ![string equal "quartus_syn" $::TimeQuestInfo(nameofexecutable)] } {
set_net_delay -from $from_node_list -to $to_node_list -max -get_value_from_clock_period dst_clock_period -value_multiplier 0.8
}
}
#
# rdptr constraints
#
proc apply_sdc_dcfifo_rdptr {hier_path} {
# get from and to list
set from_node_list [get_keepers $hier_path|auto_generated|*rdptr_g*]
set to_node_list [get_keepers $hier_path|auto_generated|ws_dgrp|dffpipe*|dffe*]
apply_sdc_dcfifo_for_ptrs $from_node_list $to_node_list
# mstable
set from_node_mstable_list [get_keepers $hier_path|auto_generated|ws_dgrp|dffpipe*|dffe*]
set to_node_mstable_list [get_keepers $hier_path|auto_generated|ws_dgrp|dffpipe*|dffe*]
apply_sdc_dcfifo_mstable_delay $from_node_mstable_list $to_node_mstable_list
}
#
# wrptr constraints
#
proc apply_sdc_dcfifo_wrptr {hier_path} {
# control skew for bits
set from_node_list [get_keepers $hier_path|auto_generated|delayed_wrptr_g*]
set to_node_list [get_keepers $hier_path|auto_generated|rs_dgwp|dffpipe*|dffe*]
apply_sdc_dcfifo_for_ptrs $from_node_list $to_node_list
# mstable
set from_node_mstable_list [get_keepers $hier_path|auto_generated|rs_dgwp|dffpipe*|dffe*]
set to_node_mstable_list [get_keepers $hier_path|auto_generated|rs_dgwp|dffpipe*|dffe*]
apply_sdc_dcfifo_mstable_delay $from_node_mstable_list $to_node_mstable_list
}

proc apply_sdc_pre_dcfifo {entity_name} {
   set temp_inst_list [get_entity_instances $entity_name]

   # filter for packet_switch_subsys instance only
   foreach each_temp_inst $temp_inst_list {
     if {[string match packet_switch_subsys|* $each_temp_inst] } {
       lappend inst_list $each_temp_inst
     }
   }

   # apply for packet_switch_subsys submodules only
   foreach each_inst $inst_list {
      apply_sdc_dcfifo ${each_inst} 
   }
}

#proc apply_sdc_pre_dcfifo {entity_name} {
#
#set inst_list [get_entity_instances $entity_name]
#
#foreach each_inst $inst_list {
#
#        apply_sdc_dcfifo ${each_inst} 
#
#    }
#}

apply_sdc_pre_dcfifo dcfifo

#set_false_path -from [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|ms_tcam_reset_manager_inst|ms_tcam_reset_sequencer_inst|int_cold_rst_n}] -to [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|ms_tcam_reset_manager_inst|int_cold_rst_n_d}]
#set_false_path -from [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|ms_tcam_reset_manager_inst|st_rst_req_disable_ingress}] -to [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|ms_tcam_reset_manager_inst|lite_rst_req_disable_ingress_d}]
set_false_path -from [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|mgmt_resp_success}] -to [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|sync1_mgmt_resp_success}]
set_false_path -from [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|tg_sync_resp_valid|reg_in}] -to [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|tg_sync_resp_valid|reg_out[0]}]
set_false_path -from [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|err_mgmt_req_valid}] -to [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|sync1_err_mgmt_req_valid}]
set_false_path -from [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|init_done}] -to [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|sync1_init_done}]
set_false_path -from [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|req_fifo_full_clk_extender|data_out}] -to [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|sync1_err_req_fifo_full}]
#set_false_path -from [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|ms_tcam_reset_manager_inst|ss_app_rst_rdy}] -to [get_keepers -no_duplicates {ss_app_rst_rdy_d[0]}]
set_false_path -from [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|ms_tcam_reset_manager_inst|ms_tcam_reset_sequencer_inst|int_cold_rst_n}] -to [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|mgmt_req|dcfifo_component|auto_generated|*aclr|dffe*}]
set_false_path -from [get_keepers -no_duplicates {packet_switch_subsys|packet_switch_top|lite_rst_sync|syn_rst}] -to [get_keepers -no_duplicates {packet_switch_subsys|packet_switch_top|packet_switch_axi_lt_avmm_inst|gen_axi_lt_to_avmm[0].axi_lt_to_avmm_*x|*data_cdc_fifo|auto_generated|*aclr|dffe*}]
set_false_path -from [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|ms_tcam_reset_manager_inst|ms_tcam_reset_sequencer_inst|int_cold_rst_n}] -to [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|mgmt_req|dcfifo_component|auto_generated|*aclr|dffe*}]
set_false_path -from [get_keepers -no_duplicates {packet_switch_subsys|packet_switch_top|lite_rst_sync|syn_rst}] -to [get_keepers -no_duplicates {packet_switch_subsys|packet_switch_top|packet_switch_axi_lt_avmm_inst|gen_axi_lt_to_avmm[0].axi_lt_to_avmm_*x|*addr_cdc_fifo|auto_generated|*aclr|dffe*}]
set_false_path -from [get_keepers -no_duplicates {packet_switch_subsys|packet_switch_top|gen_rst_sync[0].*x_rst_sync|syn_rst}] -to [get_keepers -no_duplicates {packet_switch_subsys|packet_switch_top|packet_switch_axi_lt_avmm_inst|gen_axi_lt_to_avmm[0].axi_lt_to_avmm_*x|bresp_cdc_fifo|auto_generated|*aclr|dffe*}]
set_false_path -from [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|ms_tcam_reset_manager_inst|int_warm_rst_n}] -to [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|mgmt_resp|dcfifo_component|auto_generated|rdaclr|dffe*}]
set_false_path -from [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|ms_tcam_regs_inst|mgmt_ctrl_reg.op_type[2]}] -to [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|sync1_mgmt_req_type[2]}]
set_false_path -from [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|ms_tcam_regs_inst|mgmt_ctrl_reg.op_type*}] -to [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|sync1_mgmt_req_type[*]}]
set_false_path -from [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|entry_vld}] -to [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|sync_entry_vld}]
set_false_path -from [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|ms_tcam_reset_manager_inst|ms_tcam_reset_sequencer_inst|int_warm_rst_n}] -to [get_keepers -no_duplicates {packet_switch_subsys|gen_tcam_inst[0].inst_tcam|mem_ss_cam_0|tcam_inst|ms_tcam_reset_manager_inst|int_warm_rst_n_d1}]

