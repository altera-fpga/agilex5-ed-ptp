//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

module hssi_ets_ts_adapter # (
  parameter FP_WIDTH = 8
)
(
  //Timestamp input
  input                      timestamp_fp_valid,
  input    [FP_WIDTH+95:0]   timestamp_fp_data,
  
  //Timestamp AVST Output
  output                     aso_timestamp_fp_valid,
  output   [95:0]            aso_timestamp_data,
  output   [31:0]            aso_timestamp_fp
);


  assign aso_timestamp_fp_valid = timestamp_fp_valid;
  assign aso_timestamp_fp       = {{(32-FP_WIDTH){1'b0}},timestamp_fp_data[(FP_WIDTH+96-1):96]};
  assign aso_timestamp_data     = timestamp_fp_data[95:0];


endmodule
