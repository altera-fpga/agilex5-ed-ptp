//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module ts_pack #(
    parameter int DATA_WIDTH = 96
   ,parameter int FP_WIDTH   = 8
   ,parameter int NUM_PORTS  = 8
) (
    input  logic                            clk
   ,input  logic                            rst

   ,input  logic [NUM_PORTS-1:0]            i_ts_valid
   ,input  logic [NUM_PORTS*DATA_WIDTH-1:0] i_ts_data
   ,input  logic [NUM_PORTS*FP_WIDTH-1:0]   i_ts_fp

   ,output logic                            o_ts_0_valid
   ,output logic [DATA_WIDTH-1:0]           o_ts_0_data
   ,output logic [FP_WIDTH-1:0]             o_ts_0_fp

   ,output logic                            o_ts_1_valid
   ,output logic [DATA_WIDTH-1:0]           o_ts_1_data
   ,output logic [FP_WIDTH-1:0]             o_ts_1_fp

   ,output logic                            o_ts_2_valid
   ,output logic [DATA_WIDTH-1:0]           o_ts_2_data
   ,output logic [FP_WIDTH-1:0]             o_ts_2_fp

   ,output logic                            o_ts_3_valid
   ,output logic [DATA_WIDTH-1:0]           o_ts_3_data
   ,output logic [FP_WIDTH-1:0]             o_ts_3_fp

   ,output logic                            o_ts_4_valid
   ,output logic [DATA_WIDTH-1:0]           o_ts_4_data
   ,output logic [FP_WIDTH-1:0]             o_ts_4_fp

   ,output logic                            o_ts_5_valid
   ,output logic [DATA_WIDTH-1:0]           o_ts_5_data
   ,output logic [FP_WIDTH-1:0]             o_ts_5_fp

   ,output logic                            o_ts_6_valid
   ,output logic [DATA_WIDTH-1:0]           o_ts_6_data
   ,output logic [FP_WIDTH-1:0]             o_ts_6_fp

   ,output logic                            o_ts_7_valid
   ,output logic [DATA_WIDTH-1:0]           o_ts_7_data
   ,output logic [FP_WIDTH-1:0]             o_ts_7_fp
);

   logic [NUM_PORTS-1:0]                  ts_valid;
   logic [NUM_PORTS-1:0][DATA_WIDTH-1:0]  ts_data;
   logic [NUM_PORTS-1:0][FP_WIDTH-1:0]    ts_fp;

   always_comb begin
      ts_valid = i_ts_valid;
      ts_data  = i_ts_data;
      ts_fp    = i_ts_fp;

      o_ts_0_valid = ts_valid[0];
      o_ts_0_data  = ts_data[0];
      o_ts_0_fp    = ts_fp[0];

      o_ts_1_valid = ts_valid[1];
      o_ts_1_data  = ts_data[1];
      o_ts_1_fp    = ts_fp[1];

      o_ts_2_valid = ts_valid[2];
      o_ts_2_data  = ts_data[2];
      o_ts_2_fp    = ts_fp[2];

      o_ts_3_valid = ts_valid[3];
      o_ts_3_data  = ts_data[3];
      o_ts_3_fp    = ts_fp[3];

      o_ts_4_valid = ts_valid[4];
      o_ts_4_data  = ts_data[4];
      o_ts_4_fp    = ts_fp[4];

      o_ts_5_valid = ts_valid[5];
      o_ts_5_data  = ts_data[5];
      o_ts_5_fp    = ts_fp[5];

      o_ts_6_valid = ts_valid[6];
      o_ts_6_data  = ts_data[6];
      o_ts_6_fp    = ts_fp[6];

      o_ts_7_valid = ts_valid[7];
      o_ts_7_data  = ts_data[7];
      o_ts_7_fp    = ts_fp[7];
   end

endmodule
