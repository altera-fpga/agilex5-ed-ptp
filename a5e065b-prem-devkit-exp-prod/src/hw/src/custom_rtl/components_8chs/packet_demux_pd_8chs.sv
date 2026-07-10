//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module packet_demux_pd_8chs #(
    parameter int ERROR_WIDTH   = 6
   ,parameter int DATA_WIDTH    = 128
   ,parameter int RX_TS_WIDTH   = 96
   ,parameter int CHANNEL_WIDTH = 3
   ,parameter int EMPTY_WIDTH   = 4
) (
    input  logic                     clk
   ,input  logic                     rst

   ,output logic                     i_avst_ready
   ,input  logic                     i_avst_valid
   ,input  logic                     i_avst_startofpacket
   ,input  logic                     i_avst_endofpacket
   ,input  logic [CHANNEL_WIDTH-1:0] i_avst_channel
   ,input  logic [ERROR_WIDTH-1:0]   i_avst_error
   ,input  logic [EMPTY_WIDTH-1:0]   i_avst_empty
   ,input  logic [DATA_WIDTH-1:0]    i_avst_data

   ,input  logic                     i_ts_valid
   ,input  logic [RX_TS_WIDTH-1:0]   i_ts_data

   ,input  logic                     o_avst_0_ready
   ,output logic                     o_avst_0_valid
   ,output logic                     o_avst_0_startofpacket
   ,output logic                     o_avst_0_endofpacket
   ,output logic [ERROR_WIDTH-1:0]   o_avst_0_error
   ,output logic [EMPTY_WIDTH-1:0]   o_avst_0_empty
   ,output logic [DATA_WIDTH-1:0]    o_avst_0_data

   ,output logic                     o_ts_0_valid
   ,output logic [RX_TS_WIDTH-1:0]   o_ts_0_data

   ,input  logic                     o_avst_1_ready
   ,output logic                     o_avst_1_valid
   ,output logic                     o_avst_1_startofpacket
   ,output logic                     o_avst_1_endofpacket
   ,output logic [ERROR_WIDTH-1:0]   o_avst_1_error
   ,output logic [EMPTY_WIDTH-1:0]   o_avst_1_empty
   ,output logic [DATA_WIDTH-1:0]    o_avst_1_data

   ,output logic                     o_ts_1_valid
   ,output logic [RX_TS_WIDTH-1:0]   o_ts_1_data

   ,input  logic                     o_avst_2_ready
   ,output logic                     o_avst_2_valid
   ,output logic                     o_avst_2_startofpacket
   ,output logic                     o_avst_2_endofpacket
   ,output logic [ERROR_WIDTH-1:0]   o_avst_2_error
   ,output logic [EMPTY_WIDTH-1:0]   o_avst_2_empty
   ,output logic [DATA_WIDTH-1:0]    o_avst_2_data

   ,output logic                     o_ts_2_valid
   ,output logic [RX_TS_WIDTH-1:0]   o_ts_2_data

   ,input  logic                     o_avst_3_ready
   ,output logic                     o_avst_3_valid
   ,output logic                     o_avst_3_startofpacket
   ,output logic                     o_avst_3_endofpacket
   ,output logic [ERROR_WIDTH-1:0]   o_avst_3_error
   ,output logic [EMPTY_WIDTH-1:0]   o_avst_3_empty
   ,output logic [DATA_WIDTH-1:0]    o_avst_3_data

   ,output logic                     o_ts_3_valid
   ,output logic [RX_TS_WIDTH-1:0]   o_ts_3_data

   ,input  logic                     o_avst_4_ready
   ,output logic                     o_avst_4_valid
   ,output logic                     o_avst_4_startofpacket
   ,output logic                     o_avst_4_endofpacket
   ,output logic [ERROR_WIDTH-1:0]   o_avst_4_error
   ,output logic [EMPTY_WIDTH-1:0]   o_avst_4_empty
   ,output logic [DATA_WIDTH-1:0]    o_avst_4_data

   ,output logic                     o_ts_4_valid
   ,output logic [RX_TS_WIDTH-1:0]   o_ts_4_data

   ,input  logic                     o_avst_5_ready
   ,output logic                     o_avst_5_valid
   ,output logic                     o_avst_5_startofpacket
   ,output logic                     o_avst_5_endofpacket
   ,output logic [ERROR_WIDTH-1:0]   o_avst_5_error
   ,output logic [EMPTY_WIDTH-1:0]   o_avst_5_empty
   ,output logic [DATA_WIDTH-1:0]    o_avst_5_data

   ,output logic                     o_ts_5_valid
   ,output logic [RX_TS_WIDTH-1:0]   o_ts_5_data

   ,input  logic                     o_avst_6_ready
   ,output logic                     o_avst_6_valid
   ,output logic                     o_avst_6_startofpacket
   ,output logic                     o_avst_6_endofpacket
   ,output logic [ERROR_WIDTH-1:0]   o_avst_6_error
   ,output logic [EMPTY_WIDTH-1:0]   o_avst_6_empty
   ,output logic [DATA_WIDTH-1:0]    o_avst_6_data

   ,output logic                     o_ts_6_valid
   ,output logic [RX_TS_WIDTH-1:0]   o_ts_6_data

   ,input  logic                     o_avst_7_ready
   ,output logic                     o_avst_7_valid
   ,output logic                     o_avst_7_startofpacket
   ,output logic                     o_avst_7_endofpacket
   ,output logic [ERROR_WIDTH-1:0]   o_avst_7_error
   ,output logic [EMPTY_WIDTH-1:0]   o_avst_7_empty
   ,output logic [DATA_WIDTH-1:0]    o_avst_7_data

   ,output logic                     o_ts_7_valid
   ,output logic [RX_TS_WIDTH-1:0]   o_ts_7_data
);

   localparam int NUM_PORTS = 8;

   logic                   avst_ready[NUM_PORTS];
   logic                   avst_valid[NUM_PORTS];
   logic                   avst_startofpacket[NUM_PORTS];
   logic                   avst_endofpacket[NUM_PORTS];
   logic [ERROR_WIDTH-1:0] avst_error[NUM_PORTS];
   logic [EMPTY_WIDTH-1:0] avst_empty[NUM_PORTS];
   logic [DATA_WIDTH-1:0]  avst_data[NUM_PORTS];
   logic [RX_TS_WIDTH-1:0] avst_user[NUM_PORTS];

   always_comb begin
      avst_ready[0] = o_avst_0_ready;
      avst_ready[1] = o_avst_1_ready;
      avst_ready[2] = o_avst_2_ready;
      avst_ready[3] = o_avst_3_ready;
      avst_ready[4] = o_avst_4_ready;
      avst_ready[5] = o_avst_5_ready;
      avst_ready[6] = o_avst_6_ready;
      avst_ready[7] = o_avst_7_ready;

      o_avst_0_valid         = avst_valid[0];
      o_avst_0_startofpacket = avst_startofpacket[0];
      o_avst_0_endofpacket   = avst_endofpacket[0];
      o_avst_0_error         = avst_error[0];
      o_avst_0_empty         = avst_empty[0];
      o_avst_0_data          = avst_data[0];

      o_avst_1_valid         = avst_valid[1];
      o_avst_1_startofpacket = avst_startofpacket[1];
      o_avst_1_endofpacket   = avst_endofpacket[1];
      o_avst_1_error         = avst_error[1];
      o_avst_1_empty         = avst_empty[1];
      o_avst_1_data          = avst_data[1];

      o_avst_2_valid         = avst_valid[2];
      o_avst_2_startofpacket = avst_startofpacket[2];
      o_avst_2_endofpacket   = avst_endofpacket[2];
      o_avst_2_error         = avst_error[2];
      o_avst_2_empty         = avst_empty[2];
      o_avst_2_data          = avst_data[2];

      o_avst_3_valid         = avst_valid[3];
      o_avst_3_startofpacket = avst_startofpacket[3];
      o_avst_3_endofpacket   = avst_endofpacket[3];
      o_avst_3_error         = avst_error[3];
      o_avst_3_empty         = avst_empty[3];
      o_avst_3_data          = avst_data[3];

      o_avst_4_valid         = avst_valid[4];
      o_avst_4_startofpacket = avst_startofpacket[4];
      o_avst_4_endofpacket   = avst_endofpacket[4];
      o_avst_4_error         = avst_error[4];
      o_avst_4_empty         = avst_empty[4];
      o_avst_4_data          = avst_data[4];

      o_avst_5_valid         = avst_valid[5];
      o_avst_5_startofpacket = avst_startofpacket[5];
      o_avst_5_endofpacket   = avst_endofpacket[5];
      o_avst_5_error         = avst_error[5];
      o_avst_5_empty         = avst_empty[5];
      o_avst_5_data          = avst_data[5];

      o_avst_6_valid         = avst_valid[6];
      o_avst_6_startofpacket = avst_startofpacket[6];
      o_avst_6_endofpacket   = avst_endofpacket[6];
      o_avst_6_error         = avst_error[6];
      o_avst_6_empty         = avst_empty[6];
      o_avst_6_data          = avst_data[6];

      o_avst_7_valid         = avst_valid[7];
      o_avst_7_startofpacket = avst_startofpacket[7];
      o_avst_7_endofpacket   = avst_endofpacket[7];
      o_avst_7_error         = avst_error[7];
      o_avst_7_empty         = avst_empty[7];
      o_avst_7_data          = avst_data[7];
   end

   always_comb begin
      o_ts_0_valid = avst_valid[0] & avst_startofpacket[0];
      o_ts_0_data  = avst_user[0];

      o_ts_1_valid = avst_valid[1] & avst_startofpacket[1];
      o_ts_1_data  = avst_user[1];

      o_ts_2_valid = avst_valid[2] & avst_startofpacket[2];
      o_ts_2_data  = avst_user[2];

      o_ts_3_valid = avst_valid[3] & avst_startofpacket[3];
      o_ts_3_data  = avst_user[3];

      o_ts_4_valid = avst_valid[4] & avst_startofpacket[4];
      o_ts_4_data  = avst_user[4];

      o_ts_5_valid = avst_valid[5] & avst_startofpacket[5];
      o_ts_5_data  = avst_user[5];

      o_ts_6_valid = avst_valid[6] & avst_startofpacket[6];
      o_ts_6_data  = avst_user[6];

      o_ts_7_valid = avst_valid[7] & avst_startofpacket[7];
      o_ts_7_data  = avst_user[7];
   end

   packet_demux #(
       .NUM_PORTS            (NUM_PORTS)
      ,.AVST_ERROR_WIDTH     (ERROR_WIDTH)
      ,.USER_DATA_WIDTH      (RX_TS_WIDTH)
      ,.BIT_POSITION         (0)
      ,.USE_MULTICAST        (0)
      ,.AVST_DATA_WIDTH      (DATA_WIDTH)
   ) packet_demux (
       .clk                  (clk)
      ,.rst                  (rst)

      ,.i_avst_ready         (i_avst_ready)
      ,.i_avst_valid         (i_avst_valid)
      ,.i_avst_startofpacket (i_avst_startofpacket)
      ,.i_avst_endofpacket   (i_avst_endofpacket)
      ,.i_avst_channel       (i_avst_channel)
      ,.i_avst_error         (i_avst_error)
      ,.i_avst_empty         (i_avst_empty)
      ,.i_avst_data          (i_avst_data)
      ,.i_avst_user_data     (i_ts_data)

      ,.o_avst_ready         (avst_ready)
      ,.o_avst_valid         (avst_valid)
      ,.o_avst_startofpacket (avst_startofpacket)
      ,.o_avst_endofpacket   (avst_endofpacket)
      ,.o_avst_error         (avst_error)
      ,.o_avst_empty         (avst_empty)
      ,.o_avst_data          (avst_data)
      ,.o_avst_user_data     (avst_user)
   );

endmodule
