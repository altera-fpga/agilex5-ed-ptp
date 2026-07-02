if {$param_value eq "10G_NON_ANLT"} {
puts "Info: Configuration selected is 10G_NON_ANLT"

set_global_assignment -name IP_FILE ../src/ip/subsys_hssi/gts_systempll.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_hssi/ethernet_hip.ip

} elseif {$param_value eq "25G_NON_ANLT"} {
puts "Info: Configuration selected is 25G_NON_ANLT"

set_global_assignment -name VERILOG_MACRO SM_PTP_CFG_25G 

set_global_assignment -name IP_FILE ../src/ip/subsys_hssi/ethernet_hip_25G.ip
set_global_assignment -name IP_FILE ../src/ip/subsys_hssi/gts_systempll_25G.ip
}
