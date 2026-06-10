# ######################################################################## 
# Copyright (C) 2025 Altera Corporation.
# SPDX-License-Identifier: MIT
# ######################################################################## 


proc apply_sdc_dcfifo {hier_path} {
   apply_sdc_wraclr $hier_path
   apply_sdc_dcfifo_wrptr $hier_path
}

# common constraint setting proc
proc apply_sdc_dcfifo_for_ptrs {from_node_list to_node_list} {
   # control skew for bits
   set_max_skew -from $from_node_list -to $to_node_list -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8
   # path delay (exception for net delay)
#   if { ![string equal "quartus_syn" $::TimeQuestInfo(nameofexecutable)] } {
#      set_net_delay -from $from_node_list -to $to_node_list -max -get_value_from_clock_period dst_clock_period -value_multiplier 0.8
#   }
   #relax setup and hold calculation
   set_max_delay -from $from_node_list -to $to_node_list 100
   set_min_delay -from $from_node_list -to $to_node_list -100
}

# mstable propgation delay
proc apply_sdc_dcfifo_mstable_delay {from_node_list to_node_list} {
   # mstable delay
   if { ![string equal "quartus_syn" $::TimeQuestInfo(nameofexecutable)] } {
      set_net_delay -from $from_node_list -to $to_node_list -max -get_value_from_clock_period dst_clock_period -value_multiplier 0.8
   }
}

# wrptr constraints
proc apply_sdc_dcfifo_wrptr {hier_path} {
   # control skew for bits
   set from_node_list [get_keepers $hier_path|dcfifo_component|auto_generated|delayed_wrptr_g*]
   set to_node_list [get_keepers $hier_path|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*]
   apply_sdc_dcfifo_for_ptrs $from_node_list $to_node_list
   # mstable
   set from_node_mstable_list [get_keepers $hier_path|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*]
   set to_node_mstable_list [get_keepers $hier_path|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*]
   apply_sdc_dcfifo_mstable_delay $from_node_mstable_list $to_node_mstable_list
}

# aclr constraints
proc apply_sdc_wraclr {hier_path} {
   set from_node_list [get_keepers *reset_controller*chain_out]
   set to_node_list [get_keepers $hier_path|dcfifo_component|auto_generated|wraclr|dffe*]
   apply_sdc_dcfifo_for_ptrs $from_node_list $to_node_list
   set from_node_mstable_list [get_keepers $hier_path|dcfifo_component|auto_generated|wraclr|dffe*]
   set to_node_mstable_list [get_keepers $hier_path|dcfifo_component|auto_generated|wraclr|dffe*]
   apply_sdc_dcfifo_mstable_delay $from_node_mstable_list $to_node_mstable_list
}

proc apply_sdc_pre_dcfifo {entity_name} {
   set inst_list [get_entity_instances $entity_name]
   foreach each_inst $inst_list {
      apply_sdc_dcfifo ${each_inst} 
   }
}

apply_sdc_pre_dcfifo dc_fifo_param
