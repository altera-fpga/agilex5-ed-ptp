//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module packet_mux_pd_8chs #(
    parameter int ERROR_WIDTH   = 0
   ,parameter int DATA_WIDTH    = 8
   ,parameter int EMPTY_WIDTH   = 1
   ,parameter int CHANNEL_WIDTH = 3
   ,parameter int TS_DATA_WIDTH = 8
) (
    input  logic                     clk
   ,input  logic                     rst

   ,output logic                     i_avst_0_ready
   ,input  logic                     i_avst_0_valid
   ,input  logic                     i_avst_0_startofpacket
   ,input  logic                     i_avst_0_endofpacket
   ,input  logic [ERROR_WIDTH-1:0]   i_avst_0_error
   ,input  logic [EMPTY_WIDTH-1:0]   i_avst_0_empty
   ,input  logic [DATA_WIDTH-1:0]    i_avst_0_data

   ,input  logic                     i_ts_0_valid
   ,input  logic [TS_DATA_WIDTH-1:0] i_ts_0_data

   ,output logic                     i_avst_1_ready
   ,input  logic                     i_avst_1_valid
   ,input  logic                     i_avst_1_startofpacket
   ,input  logic                     i_avst_1_endofpacket
   ,input  logic [ERROR_WIDTH-1:0]   i_avst_1_error
   ,input  logic [EMPTY_WIDTH-1:0]   i_avst_1_empty
   ,input  logic [DATA_WIDTH-1:0]    i_avst_1_data

   ,input  logic                     i_ts_1_valid
   ,input  logic [TS_DATA_WIDTH-1:0] i_ts_1_data

   ,output logic                     i_avst_2_ready
   ,input  logic                     i_avst_2_valid
   ,input  logic                     i_avst_2_startofpacket
   ,input  logic                     i_avst_2_endofpacket
   ,input  logic [ERROR_WIDTH-1:0]   i_avst_2_error
   ,input  logic [EMPTY_WIDTH-1:0]   i_avst_2_empty
   ,input  logic [DATA_WIDTH-1:0]    i_avst_2_data

   ,input  logic                     i_ts_2_valid
   ,input  logic [TS_DATA_WIDTH-1:0] i_ts_2_data

   ,output logic                     i_avst_3_ready
   ,input  logic                     i_avst_3_valid
   ,input  logic                     i_avst_3_startofpacket
   ,input  logic                     i_avst_3_endofpacket
   ,input  logic [ERROR_WIDTH-1:0]   i_avst_3_error
   ,input  logic [EMPTY_WIDTH-1:0]   i_avst_3_empty
   ,input  logic [DATA_WIDTH-1:0]    i_avst_3_data

   ,input  logic                     i_ts_3_valid
   ,input  logic [TS_DATA_WIDTH-1:0] i_ts_3_data

   ,output logic                     i_avst_4_ready
   ,input  logic                     i_avst_4_valid
   ,input  logic                     i_avst_4_startofpacket
   ,input  logic                     i_avst_4_endofpacket
   ,input  logic [ERROR_WIDTH-1:0]   i_avst_4_error
   ,input  logic [EMPTY_WIDTH-1:0]   i_avst_4_empty
   ,input  logic [DATA_WIDTH-1:0]    i_avst_4_data

   ,input  logic                     i_ts_4_valid
   ,input  logic [TS_DATA_WIDTH-1:0] i_ts_4_data

   ,output logic                     i_avst_5_ready
   ,input  logic                     i_avst_5_valid
   ,input  logic                     i_avst_5_startofpacket
   ,input  logic                     i_avst_5_endofpacket
   ,input  logic [ERROR_WIDTH-1:0]   i_avst_5_error
   ,input  logic [EMPTY_WIDTH-1:0]   i_avst_5_empty
   ,input  logic [DATA_WIDTH-1:0]    i_avst_5_data

   ,input  logic                     i_ts_5_valid
   ,input  logic [TS_DATA_WIDTH-1:0] i_ts_5_data

   ,output logic                     i_avst_6_ready
   ,input  logic                     i_avst_6_valid
   ,input  logic                     i_avst_6_startofpacket
   ,input  logic                     i_avst_6_endofpacket
   ,input  logic [ERROR_WIDTH-1:0]   i_avst_6_error
   ,input  logic [EMPTY_WIDTH-1:0]   i_avst_6_empty
   ,input  logic [DATA_WIDTH-1:0]    i_avst_6_data

   ,input  logic                     i_ts_6_valid
   ,input  logic [TS_DATA_WIDTH-1:0] i_ts_6_data

   ,output logic                     i_avst_7_ready
   ,input  logic                     i_avst_7_valid
   ,input  logic                     i_avst_7_startofpacket
   ,input  logic                     i_avst_7_endofpacket
   ,input  logic [ERROR_WIDTH-1:0]   i_avst_7_error
   ,input  logic [EMPTY_WIDTH-1:0]   i_avst_7_empty
   ,input  logic [DATA_WIDTH-1:0]    i_avst_7_data

   ,input  logic                     i_ts_7_valid
   ,input  logic [TS_DATA_WIDTH-1:0] i_ts_7_data

   ,input  logic                     o_avst_ready
   ,output logic                     o_avst_valid
   ,output logic                     o_avst_startofpacket
   ,output logic                     o_avst_endofpacket
   ,output logic [CHANNEL_WIDTH-1:0] o_avst_channel
   ,output logic [ERROR_WIDTH-1:0]   o_avst_error
   ,output logic [EMPTY_WIDTH-1:0]   o_avst_empty
   ,output logic [DATA_WIDTH-1:0]    o_avst_data

   ,output logic                     o_ts_valid
   ,output logic [TS_DATA_WIDTH-1:0] o_ts_data
);

   localparam int NUM_PORTS = 8;

   logic                       avst_ready[NUM_PORTS];
   logic [CHANNEL_WIDTH - 1:0] avst_channel[NUM_PORTS] = '{default:'0};
   logic                       avst_valid[NUM_PORTS];
   logic                       avst_startofpacket[NUM_PORTS];
   logic                       avst_endofpacket[NUM_PORTS];
   logic [ERROR_WIDTH-1:0]     avst_error[NUM_PORTS];
   logic [EMPTY_WIDTH-1:0]     avst_empty[NUM_PORTS];
   logic [DATA_WIDTH-1:0]      avst_data[NUM_PORTS];
   logic [TS_DATA_WIDTH-1:0]   avst_user_data[NUM_PORTS];

   always_comb begin
      i_avst_0_ready = avst_ready[0];
      i_avst_1_ready = avst_ready[1];
      i_avst_2_ready = avst_ready[2];
      i_avst_3_ready = avst_ready[3];
      i_avst_4_ready = avst_ready[4];
      i_avst_5_ready = avst_ready[5];
      i_avst_6_ready = avst_ready[6];
      i_avst_7_ready = avst_ready[7];

      avst_valid[0]         = i_avst_0_valid;
      avst_startofpacket[0] = i_avst_0_startofpacket;
      avst_endofpacket[0]   = i_avst_0_endofpacket;
      avst_error[0]         = i_avst_0_error;
      avst_empty[0]         = i_avst_0_empty;
      avst_data[0]          = i_avst_0_data;
      avst_user_data[0]     = i_ts_0_data;

      avst_valid[1]         = i_avst_1_valid;
      avst_startofpacket[1] = i_avst_1_startofpacket;
      avst_endofpacket[1]   = i_avst_1_endofpacket;
      avst_error[1]         = i_avst_1_error;
      avst_empty[1]         = i_avst_1_empty;
      avst_data[1]          = i_avst_1_data;
      avst_user_data[1]     = i_ts_1_data;

      avst_valid[2]         = i_avst_2_valid;
      avst_startofpacket[2] = i_avst_2_startofpacket;
      avst_endofpacket[2]   = i_avst_2_endofpacket;
      avst_error[2]         = i_avst_2_error;
      avst_empty[2]         = i_avst_2_empty;
      avst_data[2]          = i_avst_2_data;
      avst_user_data[2]     = i_ts_2_data;

      avst_valid[3]         = i_avst_3_valid;
      avst_startofpacket[3] = i_avst_3_startofpacket;
      avst_endofpacket[3]   = i_avst_3_endofpacket;
      avst_error[3]         = i_avst_3_error;
      avst_empty[3]         = i_avst_3_empty;
      avst_data[3]          = i_avst_3_data;
      avst_user_data[3]     = i_ts_3_data;

      avst_valid[4]         = i_avst_4_valid;
      avst_startofpacket[4] = i_avst_4_startofpacket;
      avst_endofpacket[4]   = i_avst_4_endofpacket;
      avst_error[4]         = i_avst_4_error;
      avst_empty[4]         = i_avst_4_empty;
      avst_data[4]          = i_avst_4_data;
      avst_user_data[4]     = i_ts_4_data;

      avst_valid[5]         = i_avst_5_valid;
      avst_startofpacket[5] = i_avst_5_startofpacket;
      avst_endofpacket[5]   = i_avst_5_endofpacket;
      avst_error[5]         = i_avst_5_error;
      avst_empty[5]         = i_avst_5_empty;
      avst_data[5]          = i_avst_5_data;
      avst_user_data[5]     = i_ts_5_data;

      avst_valid[6]         = i_avst_6_valid;
      avst_startofpacket[6] = i_avst_6_startofpacket;
      avst_endofpacket[6]   = i_avst_6_endofpacket;
      avst_error[6]         = i_avst_6_error;
      avst_empty[6]         = i_avst_6_empty;
      avst_data[6]          = i_avst_6_data;
      avst_user_data[6]     = i_ts_6_data;

      avst_valid[7]         = i_avst_7_valid;
      avst_startofpacket[7] = i_avst_7_startofpacket;
      avst_endofpacket[7]   = i_avst_7_endofpacket;
      avst_error[7]         = i_avst_7_error;
      avst_empty[7]         = i_avst_7_empty;
      avst_data[7]          = i_avst_7_data;
      avst_user_data[7]     = i_ts_7_data;

      o_ts_valid            = o_avst_valid;
   end

   packet_mux #(
       .NUM_PORTS          (NUM_PORTS)
      ,.USER_DATA_WIDTH    (TS_DATA_WIDTH)
      ,.MAX_MUXED_CHANNELS (4)
      ,.AVST_ERROR_WIDTH   (ERROR_WIDTH)
      ,.AVST_DATA_WIDTH    (DATA_WIDTH)
      ,.BIT_POSITION       (0)
      ,.PRIORITY_CH_0      (0)
   ) packet_mux (
       .clk                  (clk)
      ,.rst                  (rst)

      ,.i_avst_ready         (avst_ready)
      ,.i_avst_valid         (avst_valid)
      ,.i_avst_startofpacket (avst_startofpacket)
      ,.i_avst_endofpacket   (avst_endofpacket)
      ,.i_avst_channel       (avst_channel)
      ,.i_avst_error         (avst_error)
      ,.i_avst_empty         (avst_empty)
      ,.i_avst_data          (avst_data)
      ,.i_avst_user_data     (avst_user_data)

      ,.o_avst_ready         (o_avst_ready)
      ,.o_avst_valid         (o_avst_valid)
      ,.o_avst_startofpacket (o_avst_startofpacket)
      ,.o_avst_endofpacket   (o_avst_endofpacket)
      ,.o_avst_channel       (o_avst_channel)
      ,.o_avst_error         (o_avst_error)
      ,.o_avst_empty         (o_avst_empty)
      ,.o_avst_data          (o_avst_data)
      ,.o_avst_user_data     (o_ts_data)
   );

endmodule
