# ######################################################################## 
# Copyright (C) 2025 Altera Corporation.
# SPDX-License-Identifier: MIT
# ######################################################################## 
 
package require -exact qsys 22.1


# 
# module bus_clock
# 
set_module_property DESCRIPTION ""
set_module_property NAME bus_clock
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME bus_clock
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false
set_module_property LOAD_ELABORATION_LIMIT 0


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL clock_bus
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file clock_bus.sv SYSTEM_VERILOG PATH clock_bus.sv TOP_LEVEL_FILE


# 
# parameters
# 
add_parameter NUM_PORTS INTEGER 8 ""
set_parameter_property NUM_PORTS DEFAULT_VALUE 8
set_parameter_property NUM_PORTS DISPLAY_NAME NUM_PORTS
set_parameter_property NUM_PORTS WIDTH ""
set_parameter_property NUM_PORTS UNITS None
set_parameter_property NUM_PORTS ALLOWED_RANGES -2147483648:2147483647
set_parameter_property NUM_PORTS DESCRIPTION ""
set_parameter_property NUM_PORTS AFFECTS_GENERATION false
set_parameter_property NUM_PORTS HDL_PARAMETER true
set_parameter_property NUM_PORTS EXPORT true


# 
# display items
# 


# 
# connection point clk_bus_in
# 
add_interface clk_bus_in conduit end
set_interface_property clk_bus_in associatedClock ""
set_interface_property clk_bus_in associatedReset ""
set_interface_property clk_bus_in ENABLED true
set_interface_property clk_bus_in EXPORT_OF ""
set_interface_property clk_bus_in PORT_NAME_MAP ""
set_interface_property clk_bus_in CMSIS_SVD_VARIABLES ""
set_interface_property clk_bus_in SVD_ADDRESS_GROUP ""
set_interface_property clk_bus_in IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port clk_bus_in i_clk_bus clk_bus Input "((NUM_PORTS - 1)) - (0) + 1"


# 
# connection point rst_bus_in
# 
add_interface rst_bus_in conduit end
set_interface_property rst_bus_in associatedClock ""
set_interface_property rst_bus_in associatedReset ""
set_interface_property rst_bus_in ENABLED true
set_interface_property rst_bus_in EXPORT_OF ""
set_interface_property rst_bus_in PORT_NAME_MAP ""
set_interface_property rst_bus_in CMSIS_SVD_VARIABLES ""
set_interface_property rst_bus_in SVD_ADDRESS_GROUP ""
set_interface_property rst_bus_in IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port rst_bus_in i_rst_bus rst_bus Input "((NUM_PORTS - 1)) - (0) + 1"


# 
# connection point clock_source_0
# 
add_interface clock_source_0 clock start
set_interface_property clock_source_0 associatedDirectClock ""
set_interface_property clock_source_0 ENABLED true
set_interface_property clock_source_0 EXPORT_OF ""
set_interface_property clock_source_0 PORT_NAME_MAP ""
set_interface_property clock_source_0 CMSIS_SVD_VARIABLES ""
set_interface_property clock_source_0 SVD_ADDRESS_GROUP ""
set_interface_property clock_source_0 IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port clock_source_0 o_clk_0 clk Output 1


# 
# connection point clock_source_1
# 
add_interface clock_source_1 clock start
set_interface_property clock_source_1 associatedDirectClock ""
set_interface_property clock_source_1 ENABLED true
set_interface_property clock_source_1 EXPORT_OF ""
set_interface_property clock_source_1 PORT_NAME_MAP ""
set_interface_property clock_source_1 CMSIS_SVD_VARIABLES ""
set_interface_property clock_source_1 SVD_ADDRESS_GROUP ""
set_interface_property clock_source_1 IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port clock_source_1 o_clk_1 clk Output 1


# 
# connection point clock_source_2
# 
add_interface clock_source_2 clock start
set_interface_property clock_source_2 associatedDirectClock ""
set_interface_property clock_source_2 ENABLED true
set_interface_property clock_source_2 EXPORT_OF ""
set_interface_property clock_source_2 PORT_NAME_MAP ""
set_interface_property clock_source_2 CMSIS_SVD_VARIABLES ""
set_interface_property clock_source_2 SVD_ADDRESS_GROUP ""
set_interface_property clock_source_2 IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port clock_source_2 o_clk_2 clk Output 1


# 
# connection point clock_source_3
# 
add_interface clock_source_3 clock start
set_interface_property clock_source_3 associatedDirectClock ""
set_interface_property clock_source_3 ENABLED true
set_interface_property clock_source_3 EXPORT_OF ""
set_interface_property clock_source_3 PORT_NAME_MAP ""
set_interface_property clock_source_3 CMSIS_SVD_VARIABLES ""
set_interface_property clock_source_3 SVD_ADDRESS_GROUP ""
set_interface_property clock_source_3 IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port clock_source_3 o_clk_3 clk Output 1


# 
# connection point clock_source_4
# 
add_interface clock_source_4 clock start
set_interface_property clock_source_4 associatedDirectClock ""
set_interface_property clock_source_4 ENABLED true
set_interface_property clock_source_4 EXPORT_OF ""
set_interface_property clock_source_4 PORT_NAME_MAP ""
set_interface_property clock_source_4 CMSIS_SVD_VARIABLES ""
set_interface_property clock_source_4 SVD_ADDRESS_GROUP ""
set_interface_property clock_source_4 IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port clock_source_4 o_clk_4 clk Output 1


# 
# connection point clock_source_5
# 
add_interface clock_source_5 clock start
set_interface_property clock_source_5 associatedDirectClock ""
set_interface_property clock_source_5 ENABLED true
set_interface_property clock_source_5 EXPORT_OF ""
set_interface_property clock_source_5 PORT_NAME_MAP ""
set_interface_property clock_source_5 CMSIS_SVD_VARIABLES ""
set_interface_property clock_source_5 SVD_ADDRESS_GROUP ""
set_interface_property clock_source_5 IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port clock_source_5 o_clk_5 clk Output 1


# 
# connection point clock_source_6
# 
add_interface clock_source_6 clock start
set_interface_property clock_source_6 associatedDirectClock ""
set_interface_property clock_source_6 ENABLED true
set_interface_property clock_source_6 EXPORT_OF ""
set_interface_property clock_source_6 PORT_NAME_MAP ""
set_interface_property clock_source_6 CMSIS_SVD_VARIABLES ""
set_interface_property clock_source_6 SVD_ADDRESS_GROUP ""
set_interface_property clock_source_6 IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port clock_source_6 o_clk_6 clk Output 1


# 
# connection point clock_source_7
# 
add_interface clock_source_7 clock start
set_interface_property clock_source_7 associatedDirectClock ""
set_interface_property clock_source_7 ENABLED true
set_interface_property clock_source_7 EXPORT_OF ""
set_interface_property clock_source_7 PORT_NAME_MAP ""
set_interface_property clock_source_7 CMSIS_SVD_VARIABLES ""
set_interface_property clock_source_7 SVD_ADDRESS_GROUP ""
set_interface_property clock_source_7 IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port clock_source_7 o_clk_7 clk Output 1


# 
# connection point reset_source_0
# 
add_interface reset_source_0 reset start
set_interface_property reset_source_0 associatedClock clock_source_0
set_interface_property reset_source_0 associatedDirectReset ""
set_interface_property reset_source_0 associatedResetSinks ""
set_interface_property reset_source_0 synchronousEdges DEASSERT
set_interface_property reset_source_0 ENABLED true
set_interface_property reset_source_0 EXPORT_OF ""
set_interface_property reset_source_0 PORT_NAME_MAP ""
set_interface_property reset_source_0 CMSIS_SVD_VARIABLES ""
set_interface_property reset_source_0 SVD_ADDRESS_GROUP ""
set_interface_property reset_source_0 IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port reset_source_0 o_rst_0 reset Output 1


# 
# connection point reset_source_1
# 
add_interface reset_source_1 reset start
set_interface_property reset_source_1 associatedClock clock_source_0
set_interface_property reset_source_1 associatedDirectReset ""
set_interface_property reset_source_1 associatedResetSinks ""
set_interface_property reset_source_1 synchronousEdges DEASSERT
set_interface_property reset_source_1 ENABLED true
set_interface_property reset_source_1 EXPORT_OF ""
set_interface_property reset_source_1 PORT_NAME_MAP ""
set_interface_property reset_source_1 CMSIS_SVD_VARIABLES ""
set_interface_property reset_source_1 SVD_ADDRESS_GROUP ""
set_interface_property reset_source_1 IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port reset_source_1 o_rst_1 reset Output 1


# 
# connection point reset_source_2
# 
add_interface reset_source_2 reset start
set_interface_property reset_source_2 associatedClock clock_source_0
set_interface_property reset_source_2 associatedDirectReset ""
set_interface_property reset_source_2 associatedResetSinks ""
set_interface_property reset_source_2 synchronousEdges DEASSERT
set_interface_property reset_source_2 ENABLED true
set_interface_property reset_source_2 EXPORT_OF ""
set_interface_property reset_source_2 PORT_NAME_MAP ""
set_interface_property reset_source_2 CMSIS_SVD_VARIABLES ""
set_interface_property reset_source_2 SVD_ADDRESS_GROUP ""
set_interface_property reset_source_2 IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port reset_source_2 o_rst_2 reset Output 1


# 
# connection point reset_source_3
# 
add_interface reset_source_3 reset start
set_interface_property reset_source_3 associatedClock clock_source_0
set_interface_property reset_source_3 associatedDirectReset ""
set_interface_property reset_source_3 associatedResetSinks ""
set_interface_property reset_source_3 synchronousEdges DEASSERT
set_interface_property reset_source_3 ENABLED true
set_interface_property reset_source_3 EXPORT_OF ""
set_interface_property reset_source_3 PORT_NAME_MAP ""
set_interface_property reset_source_3 CMSIS_SVD_VARIABLES ""
set_interface_property reset_source_3 SVD_ADDRESS_GROUP ""
set_interface_property reset_source_3 IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port reset_source_3 o_rst_3 reset Output 1


# 
# connection point reset_source_4
# 
add_interface reset_source_4 reset start
set_interface_property reset_source_4 associatedClock clock_source_0
set_interface_property reset_source_4 associatedDirectReset ""
set_interface_property reset_source_4 associatedResetSinks ""
set_interface_property reset_source_4 synchronousEdges DEASSERT
set_interface_property reset_source_4 ENABLED true
set_interface_property reset_source_4 EXPORT_OF ""
set_interface_property reset_source_4 PORT_NAME_MAP ""
set_interface_property reset_source_4 CMSIS_SVD_VARIABLES ""
set_interface_property reset_source_4 SVD_ADDRESS_GROUP ""
set_interface_property reset_source_4 IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port reset_source_4 o_rst_4 reset Output 1


# 
# connection point reset_source_5
# 
add_interface reset_source_5 reset start
set_interface_property reset_source_5 associatedClock clock_source_0
set_interface_property reset_source_5 associatedDirectReset ""
set_interface_property reset_source_5 associatedResetSinks ""
set_interface_property reset_source_5 synchronousEdges DEASSERT
set_interface_property reset_source_5 ENABLED true
set_interface_property reset_source_5 EXPORT_OF ""
set_interface_property reset_source_5 PORT_NAME_MAP ""
set_interface_property reset_source_5 CMSIS_SVD_VARIABLES ""
set_interface_property reset_source_5 SVD_ADDRESS_GROUP ""
set_interface_property reset_source_5 IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port reset_source_5 o_rst_5 reset Output 1


# 
# connection point reset_source_6
# 
add_interface reset_source_6 reset start
set_interface_property reset_source_6 associatedClock clock_source_0
set_interface_property reset_source_6 associatedDirectReset ""
set_interface_property reset_source_6 associatedResetSinks ""
set_interface_property reset_source_6 synchronousEdges DEASSERT
set_interface_property reset_source_6 ENABLED true
set_interface_property reset_source_6 EXPORT_OF ""
set_interface_property reset_source_6 PORT_NAME_MAP ""
set_interface_property reset_source_6 CMSIS_SVD_VARIABLES ""
set_interface_property reset_source_6 SVD_ADDRESS_GROUP ""
set_interface_property reset_source_6 IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port reset_source_6 o_rst_6 reset Output 1


# 
# connection point reset_source_7
# 
add_interface reset_source_7 reset start
set_interface_property reset_source_7 associatedClock clock_source_0
set_interface_property reset_source_7 associatedDirectReset ""
set_interface_property reset_source_7 associatedResetSinks ""
set_interface_property reset_source_7 synchronousEdges DEASSERT
set_interface_property reset_source_7 ENABLED true
set_interface_property reset_source_7 EXPORT_OF ""
set_interface_property reset_source_7 PORT_NAME_MAP ""
set_interface_property reset_source_7 CMSIS_SVD_VARIABLES ""
set_interface_property reset_source_7 SVD_ADDRESS_GROUP ""
set_interface_property reset_source_7 IPXACT_REGISTER_MAP_VARIABLES ""

add_interface_port reset_source_7 o_rst_7 reset Output 1

