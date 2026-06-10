# (C) 2001-2025 Altera Corporation. All rights reserved.
# Your use of Altera Corporation's design tools, logic functions and other 
# software and tools, and its AMPP partner logic functions, and any output 
# files from any of the foregoing (including device programming or simulation 
# files), and any associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License Subscription 
# Agreement, Altera IP License Agreement, or other applicable 
# license agreement, including, without limitation, that your use is for the 
# sole purpose of programming logic devices manufactured by Altera and sold by 
# Altera or its authorized distributors.  Please refer to the applicable 
# agreement for further details.



set ::syn_flow 0
set ::sta_flow 0
set ::fit_flow 0
set ::pow_flow 0

if { $::TimeQuestInfo(nameofexecutable) == "quartus_map" || $::TimeQuestInfo(nameofexecutable) == "quartus_syn" } {
    set ::syn_flow 1
} elseif { $::TimeQuestInfo(nameofexecutable) == "quartus_sta" } {
    set ::sta_flow 1
} elseif { $::TimeQuestInfo(nameofexecutable) == "quartus_fit" } {
    set ::fit_flow 1
} elseif { $::TimeQuestInfo(nameofexecutable) == "quartus_pow" } {
    set ::pow_flow 1
}

proc apply_sdc_reset_synchronizer {hier_path} {
    global ::fit_flow

    set tmp_pin [get_pins -nowarn ${hier_path}|clrn]
    if {[get_collection_size $tmp_pin] > 0} {
        if {$::fit_flow == 1} {
            set_multicycle_path -through $tmp_pin -to $hier_path -setup 7 -end
            set_multicycle_path -through $tmp_pin -to $hier_path -hold 6 -end
        } else {
            set_false_path -through $tmp_pin -to $hier_path
        }
    }
}

proc apply_sdc_data_synchronizer_input {hier_path} {
    global ::fit_flow

    set tmp_pin [get_pins -nowarn ${hier_path}|d]
    if {[get_collection_size $tmp_pin] > 0} {
        if {$::fit_flow == 1} {
            set_multicycle_path -through $tmp_pin -to $hier_path -setup 7 -end
            set_multicycle_path -through $tmp_pin -to $hier_path -hold 6 -end
        } else {
            set_false_path -through $tmp_pin -to $hier_path
        }
    }
}


proc apply_sdc_dcfifo {hier_path} {
    set nodes [get_keepers -nowarn $hier_path|dcfifo_component|*]

    if {[get_collection_size $nodes] > 0} {
        apply_sdc_dcfifo_rdptr $hier_path

        apply_sdc_dcfifo_wrptr $hier_path

        apply_sdc_dcfifo_aclr $hier_path
    }
}

proc apply_sdc_dcfifo_for_ptrs {from_node_list to_node_list} {
    set_max_skew -from $from_node_list -to $to_node_list -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

    if { ![string equal "quartus_syn" $::TimeQuestInfo(nameofexecutable)] } {
        set_net_delay -from $from_node_list -to $to_node_list -max -get_value_from_clock_period dst_clock_period -value_multiplier 0.8
    }

    set_max_delay -from $from_node_list -to $to_node_list 100
    set_min_delay -from $from_node_list -to $to_node_list -100
}

proc apply_sdc_dcfifo_mstable_delay {from_node_list to_node_list} {
    if { ![string equal "quartus_syn" $::TimeQuestInfo(nameofexecutable)] } {
        set_net_delay -from $from_node_list -to $to_node_list -max -get_value_from_clock_period dst_clock_period -value_multiplier 0.8
    }
}

proc apply_sdc_dcfifo_rdptr {hier_path} {
    set from_node_list [get_keepers $hier_path|dcfifo_component|auto_generated|*rdptr_g*]
    set to_node_list [get_keepers $hier_path|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*]
    apply_sdc_dcfifo_for_ptrs $from_node_list $to_node_list

    set from_node_mstable_list [get_keepers $hier_path|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*]
    set to_node_mstable_list [get_keepers $hier_path|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*]
    apply_sdc_dcfifo_mstable_delay $from_node_mstable_list $to_node_mstable_list
}

proc apply_sdc_dcfifo_wrptr {hier_path} {
    set from_node_list [get_keepers $hier_path|dcfifo_component|auto_generated|delayed_wrptr_g*]
    set to_node_list [get_keepers $hier_path|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*]
    apply_sdc_dcfifo_for_ptrs $from_node_list $to_node_list

    set from_node_mstable_list [get_keepers $hier_path|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*]
    set to_node_mstable_list [get_keepers $hier_path|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*]
    apply_sdc_dcfifo_mstable_delay $from_node_mstable_list $to_node_mstable_list
}

proc apply_sdc_dcfifo_aclr {hier_path} {
    apply_sdc_reset_synchronizer "$hier_path|dcfifo_component|auto_generated|wraclr|dffe*a[0]"
    apply_sdc_reset_synchronizer "$hier_path|dcfifo_component|auto_generated|rdaclr|dffe*a[0]"
}

apply_sdc_dcfifo "tcam_inst|mgmt_req"
apply_sdc_dcfifo "tcam_inst|mgmt_resp"

apply_sdc_data_synchronizer_input "tcam_inst|ms_tcam_reset_manager_inst|lite_rst_req_disable_ingress_d"
apply_sdc_data_synchronizer_input "tcam_inst|ms_tcam_reset_manager_inst|int_cold_rst_n_d"
apply_sdc_data_synchronizer_input "tcam_inst|ms_tcam_reset_manager_inst|int_warm_rst_n_d1"
apply_sdc_data_synchronizer_input "tcam_inst|ms_tcam_reset_manager_inst|axi_lite_sync|app_ss_lite_areset_n"
apply_sdc_data_synchronizer_input "tcam_inst|ms_tcam_reset_manager_inst|enq_axi_st_sync|din_s1"
apply_sdc_data_synchronizer_input "tcam_inst|ms_tcam_reset_manager_inst|axi_lite_sync|din_s1"
apply_sdc_data_synchronizer_input "tcam_inst|sync1_mgmt_req_type[*]"
apply_sdc_data_synchronizer_input "tcam_inst|tg_sync_resp_valid|reg_out[0]"
apply_sdc_data_synchronizer_input "tcam_inst|sync1_init_done"
apply_sdc_data_synchronizer_input "tcam_inst|sync1_err_req_fifo_full"
apply_sdc_data_synchronizer_input "tcam_inst|sync1_err_mgmt_req_valid"
apply_sdc_data_synchronizer_input "tcam_inst|sync1_mgmt_resp_success"
apply_sdc_data_synchronizer_input "tcam_inst|ms_tcam_regs_inst|mgmt_ctrl_reg.success[8]"
apply_sdc_data_synchronizer_input "tcam_inst|sync_entry_vld"


