//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module packet_mux #(
    parameter  int NUM_PORTS = 4
   ,parameter  int USER_DATA_WIDTH = 64
   ,parameter  int MAX_MUXED_CHANNELS = 4
   ,parameter  int AVST_ERROR_WIDTH = 0
   ,parameter  int AVST_DATA_WIDTH =64
   ,parameter  int BIT_POSITION = 0
   ,parameter  int PRIORITY_CH_0 = 0
   ,localparam int AVST_EMPTY_WIDTH = components_pkg::get_width(AVST_DATA_WIDTH )-3
   ,localparam  int AVST_CHANNEL_WIDTH = (BIT_POSITION) ? NUM_PORTS : components_pkg::get_width(NUM_PORTS)
   ,localparam  int CHANNEL_WIDTH = components_pkg::get_width(NUM_PORTS)
) (
    input  logic                                 clk
   ,input  logic                                 rst

   ,output logic                                 i_avst_ready[NUM_PORTS]
   ,input  logic                                 i_avst_valid[NUM_PORTS]
   ,input  logic                                 i_avst_startofpacket[NUM_PORTS]
   ,input  logic                                 i_avst_endofpacket[NUM_PORTS]
   ,input  logic [AVST_CHANNEL_WIDTH-1:0]        i_avst_channel[NUM_PORTS]
   ,input  logic [AVST_ERROR_WIDTH-1:0]          i_avst_error[NUM_PORTS]
   ,input  logic [AVST_EMPTY_WIDTH-1:0]          i_avst_empty[NUM_PORTS]
   ,input  logic [AVST_DATA_WIDTH-1:0]           i_avst_data[NUM_PORTS]
   ,input  logic [USER_DATA_WIDTH-1:0]           i_avst_user_data[NUM_PORTS]

   ,input  logic                                 o_avst_ready
   ,output logic                                 o_avst_valid
   ,output logic                                 o_avst_startofpacket
   ,output logic                                 o_avst_endofpacket
   ,output logic [AVST_CHANNEL_WIDTH-1:0]        o_avst_channel
   ,output logic [AVST_ERROR_WIDTH-1:0]          o_avst_error
   ,output logic [AVST_EMPTY_WIDTH-1:0]          o_avst_empty
   ,output logic [AVST_DATA_WIDTH-1:0]           o_avst_data
   ,output logic [USER_DATA_WIDTH-1:0]           o_avst_user_data
);

   localparam STAGES_NUM = NUM_PORTS / MAX_MUXED_CHANNELS;

   logic ch_change_en;
   logic ready_adjusted_to_latency_zero;
   logic ready_for_all_local_pause_on;
   logic packet_in_process;
   logic packet_started;
   logic packet_finished;
   logic [CHANNEL_WIDTH-1:0] wire_active_ch;
   logic [CHANNEL_WIDTH-1:0] active_ch = '0;
   logic                          r_startofpacket [STAGES_NUM + 1][NUM_PORTS];
   logic                          r_valid         [STAGES_NUM + 1][NUM_PORTS];
   logic                          r_endofpacket   [STAGES_NUM + 1][NUM_PORTS];
   logic [AVST_DATA_WIDTH-1:0]    r_data          [STAGES_NUM + 1][NUM_PORTS];
   logic [USER_DATA_WIDTH-1:0]    r_user_data     [STAGES_NUM + 1][NUM_PORTS];
   logic [AVST_EMPTY_WIDTH-1:0]   r_empty         [STAGES_NUM + 1][NUM_PORTS];
   logic [AVST_ERROR_WIDTH-1:0]   r_error         [STAGES_NUM + 1][NUM_PORTS];
   logic [AVST_CHANNEL_WIDTH-1:0] r_channel       [STAGES_NUM + 1][NUM_PORTS];
   logic                          r_ready         [STAGES_NUM + 1][NUM_PORTS];
   logic [CHANNEL_WIDTH-1:0] next_p[STAGES_NUM];
   logic [CHANNEL_WIDTH-1:0] next_p_wire[STAGES_NUM];
   logic [CHANNEL_WIDTH-1:0] curr_p_wire[STAGES_NUM];

   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
         packet_in_process <= 1'b0;
      end else if (packet_started) begin
         packet_in_process <= 1'b1;
      end else if (packet_finished) begin
         packet_in_process <= 1'b0;
      end
   end

   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
          ready_adjusted_to_latency_zero <= 1'b0;
          ready_for_all_local_pause_on <= 1'b0;
      end else begin
         ready_adjusted_to_latency_zero <= o_avst_ready;
         ready_for_all_local_pause_on <= o_avst_ready & (!ch_change_en | (packet_in_process | packet_started));
      end
   end

   always_comb packet_started = ready_for_all_local_pause_on & r_valid[0][active_ch] & r_startofpacket[0][active_ch] & ~r_endofpacket[0][active_ch];
   always_comb packet_finished = ready_for_all_local_pause_on & r_valid[0][active_ch]& r_endofpacket[0][active_ch];
   always_comb ch_change_en = ready_for_all_local_pause_on & ( packet_finished | !r_valid[0][active_ch] & !packet_in_process);

   logic [CHANNEL_WIDTH-1:0] j;


   if (PRIORITY_CH_0) begin

      always_ff @ (posedge clk) begin
         if (rst) begin
            wire_active_ch <= '0;
            active_ch      <= '0;
         end else begin
            if (ch_change_en) begin
               if (r_startofpacket[0][0] && r_valid[0][0]) begin
                  active_ch <= '0;
               end else begin
                  wire_active_ch = (wire_active_ch < NUM_PORTS -1) ? wire_active_ch + 1'b1 : '0;
                  active_ch <= wire_active_ch;
               end
            end
         end
      end

   end else begin

      always_ff @ (posedge clk) begin
         if (ch_change_en) begin
            wire_active_ch = (active_ch < NUM_PORTS -1) ? active_ch + 1'b1 : '0;
            active_ch <= wire_active_ch;
         end
      end

   end

   for(genvar i = 0; i < NUM_PORTS; i++) begin : NUM_PORTS_ASSIGN
      always_comb begin
         i_avst_ready[i] =       r_ready[0][i];
         r_startofpacket[0][i] = i_avst_startofpacket[i];
         r_endofpacket[0][i] =   i_avst_endofpacket[i];
         r_data[0][i] =          i_avst_data[i];
         r_user_data[0][i] =     i_avst_user_data[i];
         r_empty[0][i] =         i_avst_empty[i];
         r_error[0][i] =         i_avst_error[i];
         r_channel[0][i] =       i_avst_channel[i];
         r_valid[0][i] =         i_avst_valid[i] & ready_for_all_local_pause_on;
      end
   end

   always_comb begin
      r_ready = '{default: '0};
      r_ready[0][active_ch] = ready_for_all_local_pause_on;
   end

   for(genvar i = 0; i < STAGES_NUM; i++) begin : stage
      always_comb begin
         curr_p_wire[i] = (i) ? next_p[i-1] : active_ch;
         next_p_wire[i] = (curr_p_wire[i] >> $clog2(MAX_MUXED_CHANNELS));
      end

      always_ff @(posedge clk) begin
         if (ready_adjusted_to_latency_zero) begin
            next_p[i] <= next_p_wire[i];
         end
      end

      always_ff @(posedge clk) begin
         if (rst) begin
            r_startofpacket[i+1][next_p_wire[i]] <= '0;
            r_valid[i+1][next_p_wire[i]]         <= '0;
            r_endofpacket[i+1][next_p_wire[i]]   <= '0;
            r_data[i+1][next_p_wire[i]]          <= '0;
            r_user_data[i+1][next_p_wire[i]]     <= '0;
            r_empty[i+1][next_p_wire[i]]         <= '0;
            r_error[i+1][next_p_wire[i]]         <= '0;
            r_channel[i+1][next_p_wire[i]]       <= '0;
         end else begin
            if (ready_adjusted_to_latency_zero) begin
               r_startofpacket[i+1][next_p_wire[i]] <= r_startofpacket[i][curr_p_wire[i]];
               r_valid[i+1][next_p_wire[i]]         <= r_valid[i][curr_p_wire[i]];
               r_endofpacket[i+1][next_p_wire[i]]   <= r_endofpacket[i][curr_p_wire[i]];
               r_data[i+1][next_p_wire[i]]          <= r_data[i][curr_p_wire[i]];
               r_user_data[i+1][next_p_wire[i]]     <= r_user_data[i][curr_p_wire[i]];
               r_empty[i+1][next_p_wire[i]]         <= r_empty[i][curr_p_wire[i]];
               r_error[i+1][next_p_wire[i]]         <= r_error[i][curr_p_wire[i]];
               r_channel[i+1][next_p_wire[i]] <= (i) ? r_channel[i][curr_p_wire[i]] : active_ch;
            end
         end
      end
   end

   always_comb begin
      o_avst_startofpacket = r_startofpacket[STAGES_NUM][0];
      o_avst_valid         = r_valid[STAGES_NUM][0] & ready_adjusted_to_latency_zero;
      o_avst_endofpacket   = r_endofpacket[STAGES_NUM][0];
      o_avst_data          = r_data[STAGES_NUM][0];
      o_avst_user_data     = r_user_data[STAGES_NUM][0];
      o_avst_empty         = r_empty[STAGES_NUM][0];
      o_avst_error         = |r_error[STAGES_NUM][0];
   end

   if (BIT_POSITION == 1) begin : en_bit_shifting_o_avst_channel
      always_comb o_avst_channel = 1'b1 << r_channel[STAGES_NUM][0];
   end else begin
      always_comb o_avst_channel = r_channel[STAGES_NUM][0];
   end

endmodule
