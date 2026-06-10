//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module packet_demux #(
    parameter int NUM_PORTS = 4
   ,parameter int AVST_ERROR_WIDTH = 1
   ,parameter int USER_DATA_WIDTH = 64
   ,parameter int BIT_POSITION = 0
   ,parameter int USE_MULTICAST = 0//cannot use multicast when bit position is 0
   ,parameter int AVST_DATA_WIDTH = 64
   ,localparam int AVST_CHANNEL_WIDTH = (BIT_POSITION) ? NUM_PORTS : components_pkg::get_width(NUM_PORTS)
   ,localparam int AVST_EMPTY_WIDTH = components_pkg::get_width(AVST_DATA_WIDTH) - 3
) (
    input                                   clk
   ,input                                   rst
   ,output logic                            i_avst_ready
   ,input  logic                            i_avst_valid
   ,input  logic                            i_avst_startofpacket
   ,input  logic                            i_avst_endofpacket
   ,input  logic [AVST_CHANNEL_WIDTH-1:0]   i_avst_channel
   ,input  logic [AVST_ERROR_WIDTH-1:0]     i_avst_error
   ,input  logic [AVST_EMPTY_WIDTH-1:0]     i_avst_empty
   ,input  logic [AVST_DATA_WIDTH-1:0]      i_avst_data
   ,input  logic [USER_DATA_WIDTH-1:0]      i_avst_user_data
   ,input  logic                            o_avst_ready[NUM_PORTS]
   ,output logic                            o_avst_valid[NUM_PORTS]
   ,output logic                            o_avst_startofpacket[NUM_PORTS]
   ,output logic                            o_avst_endofpacket[NUM_PORTS]
   ,output logic [AVST_ERROR_WIDTH-1:0]     o_avst_error[NUM_PORTS]
   ,output logic [AVST_EMPTY_WIDTH-1:0]     o_avst_empty[NUM_PORTS]
   ,output logic [AVST_DATA_WIDTH-1:0]      o_avst_data[NUM_PORTS]
   ,output logic [USER_DATA_WIDTH-1:0]      o_avst_user_data[NUM_PORTS]
);

   logic                            r_startofpacket [NUM_PORTS];
   logic                            r_valid         [NUM_PORTS];
   logic                            r_endofpacket   [NUM_PORTS];
   logic [AVST_DATA_WIDTH-1:0]      r_data          [NUM_PORTS];
   logic [USER_DATA_WIDTH-1:0]      r_user_data     [NUM_PORTS];
   logic [AVST_EMPTY_WIDTH-1:0]     r_empty         [NUM_PORTS];
   logic [AVST_ERROR_WIDTH-1:0]     r_error         [NUM_PORTS];
   logic [AVST_CHANNEL_WIDTH-1:0]   r_channel       [NUM_PORTS];
   logic [NUM_PORTS - 1: 0]         masked_r_valid             ;

   logic                            rg_i_avst_startofpacket;
   logic                            rg_i_avst_valid        ;
   logic                            rg_i_avst_endofpacket  ;
   logic [AVST_DATA_WIDTH-1:0]      rg_i_avst_data         ;
   logic [USER_DATA_WIDTH-1:0]      rg_i_avst_user_data    ;
   logic [AVST_EMPTY_WIDTH-1:0]     rg_i_avst_empty        ;
   logic [AVST_ERROR_WIDTH-1:0]     rg_i_avst_error        ;
   logic [AVST_CHANNEL_WIDTH-1:0]   rg_i_avst_channel      ;
   //===================================
   logic [NUM_PORTS-1:0]            wire_ready;

   always_ff @ (posedge clk) begin
      if (rst) begin
         rg_i_avst_valid <= '0;
      end else if (i_avst_ready) begin
         rg_i_avst_startofpacket <=   i_avst_startofpacket;
         rg_i_avst_valid         <=   i_avst_valid;
         rg_i_avst_endofpacket   <=   i_avst_endofpacket;
         rg_i_avst_data          <=   i_avst_data;
         rg_i_avst_user_data     <=   i_avst_user_data;
         rg_i_avst_empty         <=   i_avst_empty;
         rg_i_avst_error         <=   i_avst_error;
         rg_i_avst_channel       <=   i_avst_channel;
      end
   end

   always_comb begin
      for (int i = 0; i < NUM_PORTS; i++) begin
         r_startofpacket[i]  =   '0;
         r_valid[i]          =   '0;
         r_endofpacket[i]    =   '0;
         r_data[i]           =   '0;
         r_user_data[i]      =   '0;
         r_empty[i]          =   '0;
         r_error[i]          =   '0;
         if (BIT_POSITION == 1) begin
            if (rg_i_avst_channel[i]) begin
               r_startofpacket[i]       =   rg_i_avst_startofpacket;
               r_endofpacket[i]         =   rg_i_avst_endofpacket;
               r_data[i]                =   rg_i_avst_data;
               r_user_data[i]           =   rg_i_avst_user_data;
               r_empty[i]               =   rg_i_avst_empty;
               r_error [i]              =   rg_i_avst_error;
               r_valid [i] = rg_i_avst_valid & i_avst_ready;
               r_channel[i] = rg_i_avst_channel;
            end
         end else begin
            if (rg_i_avst_channel == i) begin
               r_startofpacket[i]       =   rg_i_avst_startofpacket;
               r_endofpacket[i]         =   rg_i_avst_endofpacket;
               r_data[i]                =   rg_i_avst_data;
               r_user_data[i]           =   rg_i_avst_user_data;
               r_empty[i]               =   rg_i_avst_empty;
               r_error [i]              =   rg_i_avst_error;
               r_valid [i] = rg_i_avst_valid & i_avst_ready;
               r_channel[i] = rg_i_avst_channel;
            end
         end
      end
   end

   for(genvar i = 0; i < NUM_PORTS; i++) begin : O_AVST_ASSIGN
      always_comb begin
         o_avst_startofpacket[i] =   r_startofpacket[i];
         o_avst_endofpacket[i]   =   r_endofpacket[i];
         o_avst_error[i]         =   r_error[i];
         o_avst_empty[i]         =   r_empty[i];
         o_avst_data [i]         =   r_data[i];
         o_avst_user_data [i]    =   r_user_data[i];
      end
   end

   if(USE_MULTICAST == 1) begin
      for(genvar i = 0; i < NUM_PORTS; i++) begin : MULTICAST_CASE
         always_comb begin
            if (o_avst_ready[i]) begin
               if (&wire_ready) begin
                  masked_r_valid [i] = r_valid[i] && r_channel[i][i];
               end else begin
                  masked_r_valid [i] = '0;
               end
            end else begin
               masked_r_valid [i] = r_valid[i] && r_channel[i][i];
            end
         end
         always_comb begin
               o_avst_valid[i]         =   masked_r_valid [i];
         end
      end
   end else begin
      for(genvar i = 0; i < NUM_PORTS; i++) begin : NON_MULTICAST_CASE
            always_comb begin
               o_avst_valid[i]         =   r_valid[i];
            end
      end
   end

   for(genvar i = 0; i < NUM_PORTS; i++) begin : gen_wire_ready
      always_comb wire_ready[i] = o_avst_ready[i];
   end

   always_comb i_avst_ready = &wire_ready;

endmodule
