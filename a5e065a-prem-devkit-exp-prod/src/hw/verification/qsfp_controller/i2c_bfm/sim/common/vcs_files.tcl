
namespace eval i2c_bfm {
  proc get_memory_files {QSYS_SIMDIR} {
    set memory_files [list]
    return $memory_files
  }
  
  proc get_common_design_files {QSYS_SIMDIR} {
    set design_files [dict create]
    return $design_files
  }
  
  proc get_design_files {QSYS_SIMDIR} {
    set design_files [dict create]
    dict set design_files "altera_i2cslave_to_avlmm_bridge.v" "$QSYS_SIMDIR/../altera_i2cslave_to_avlmm_bridge_1910/sim/altera_i2cslave_to_avlmm_bridge.v"
    dict set design_files "altr_i2c_avl_mst_intf_gen.v"       "$QSYS_SIMDIR/../altera_i2cslave_to_avlmm_bridge_1910/sim/altr_i2c_avl_mst_intf_gen.v"      
    dict set design_files "altr_i2c_clk_cnt.v"                "$QSYS_SIMDIR/../altera_i2cslave_to_avlmm_bridge_1910/sim/altr_i2c_clk_cnt.v"               
    dict set design_files "altr_i2c_condt_det.v"              "$QSYS_SIMDIR/../altera_i2cslave_to_avlmm_bridge_1910/sim/altr_i2c_condt_det.v"             
    dict set design_files "altr_i2c_databuffer.v"             "$QSYS_SIMDIR/../altera_i2cslave_to_avlmm_bridge_1910/sim/altr_i2c_databuffer.v"            
    dict set design_files "altr_i2c_rxshifter.v"              "$QSYS_SIMDIR/../altera_i2cslave_to_avlmm_bridge_1910/sim/altr_i2c_rxshifter.v"             
    dict set design_files "altr_i2c_slvfsm.v"                 "$QSYS_SIMDIR/../altera_i2cslave_to_avlmm_bridge_1910/sim/altr_i2c_slvfsm.v"                
    dict set design_files "altr_i2c_spksupp.v"                "$QSYS_SIMDIR/../altera_i2cslave_to_avlmm_bridge_1910/sim/altr_i2c_spksupp.v"               
    dict set design_files "altr_i2c_txout.v"                  "$QSYS_SIMDIR/../altera_i2cslave_to_avlmm_bridge_1910/sim/altr_i2c_txout.v"                 
    dict set design_files "altr_i2c_txshifter.v"              "$QSYS_SIMDIR/../altera_i2cslave_to_avlmm_bridge_1910/sim/altr_i2c_txshifter.v"             
    dict set design_files "i2c_bfm.v"                         "$QSYS_SIMDIR/i2c_bfm.v"                                                                    
    return $design_files
  }
  
  proc get_elab_options {SIMULATOR_TOOL_BITNESS} {
    set ELAB_OPTIONS ""
    if ![ string match "bit_64" $SIMULATOR_TOOL_BITNESS ] {
    } else {
    }
    return $ELAB_OPTIONS
  }
  
  
  proc get_sim_options {SIMULATOR_TOOL_BITNESS} {
    set SIM_OPTIONS ""
    if ![ string match "bit_64" $SIMULATOR_TOOL_BITNESS ] {
    } else {
    }
    return $SIM_OPTIONS
  }
  
  
  proc get_env_variables {SIMULATOR_TOOL_BITNESS} {
    set ENV_VARIABLES [dict create]
    set LD_LIBRARY_PATH [dict create]
    dict set ENV_VARIABLES "LD_LIBRARY_PATH" $LD_LIBRARY_PATH
    if ![ string match "bit_64" $SIMULATOR_TOOL_BITNESS ] {
    } else {
    }
    return $ENV_VARIABLES
  }
  
  
}
