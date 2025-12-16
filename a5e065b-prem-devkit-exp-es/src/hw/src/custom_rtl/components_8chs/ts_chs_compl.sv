//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module ts_chs_compl #(
    parameter int NUM_PORTS         = 1
   ,parameter int AVST_DATA_WIDTH   = 128
   ,parameter int AVST_ERROR_WIDTH  = 6
   ,parameter int AVST_EMPTY_WIDTH  = 4
   ,parameter int ID_WIDTH          = 20
   ,parameter int DATA_WIDTH        = 96
   ,parameter int TO_CNTR_WIDTH     = 10
   ,parameter int CHANNEL_WIDTH     = $clog2(NUM_PORTS)
   ,parameter int FP_WIDTH          = ID_WIDTH + CHANNEL_WIDTH
) (
    input  logic                            i_ts_req_clk
   ,input  logic                            i_ts_req_rst

   ,input  logic [NUM_PORTS-1:0]            i_clk_bus
   ,input  logic [NUM_PORTS-1:0]            i_rst_bus

   ,output logic                            in_st_ready
   ,input  logic                            in_st_sop
   ,input  logic                            in_st_valid
   ,input  logic                            in_st_eop
   ,input  logic [AVST_DATA_WIDTH-1:0]      in_st_data
   ,input  logic [AVST_EMPTY_WIDTH-1:0]     in_st_empty
   ,input  logic [AVST_ERROR_WIDTH-1:0]     in_st_error

   ,input  logic                            out_st_ready
   ,output logic                            out_st_sop
   ,output logic                            out_st_valid
   ,output logic                            out_st_eop
   ,output logic [AVST_DATA_WIDTH-1:0]      out_st_data
   ,output logic [AVST_EMPTY_WIDTH-1:0]     out_st_empty
   ,output logic [AVST_ERROR_WIDTH-1:0]     out_st_error

   ,input  logic [NUM_PORTS-1:0]            i_ts_valid
   ,input  logic [NUM_PORTS*FP_WIDTH-1:0]   i_ts_fp
   ,input  logic [NUM_PORTS*DATA_WIDTH-1:0] i_ts_data

   ,output logic [NUM_PORTS-1:0]            o_ts_valid
   ,output logic [NUM_PORTS*ID_WIDTH-1:0]   o_ts_fp
   ,output logic [NUM_PORTS*DATA_WIDTH-1:0] o_ts_data
);

   localparam int TS_FIFO_ADDR_WIDTH = 10;
   localparam int TS_REQ_CNTR_WIDTH = 15;
   localparam int TS_NANO_SEC_WIDTH = 32;

//   logic [TS_NANO_SEC_WIDTH-1:0] TIMEOUT = 'd2500000;

   logic [NUM_PORTS-1:0]                 ts_a_valid;
   logic [NUM_PORTS-1:0][FP_WIDTH-1:0]   ts_a_fp;
   logic [NUM_PORTS-1:0][DATA_WIDTH-1:0] ts_a_data;
   logic                                 cur_id_valid[NUM_PORTS];

   logic [NUM_PORTS-1:0]                 ts_p_valid;
   logic [NUM_PORTS-1:0][ID_WIDTH-1:0]   ts_p_fp;
   logic [NUM_PORTS-1:0][DATA_WIDTH-1:0] ts_p_data;

   always_comb begin
      in_st_ready      = out_st_ready;         
      out_st_sop       = in_st_sop  ;
      out_st_valid     = in_st_valid;
      out_st_eop       = in_st_eop  ;
      out_st_data      = in_st_data ;
      out_st_empty     = in_st_empty;
      out_st_error     = in_st_error;


      ts_a_valid = i_ts_valid;
      ts_a_data  = i_ts_data;
      ts_a_fp    = i_ts_fp;

      for(int i = 0; i < NUM_PORTS; i++) begin
         ts_p_valid[i] = cur_id_valid[i];
      end

      o_ts_valid = ts_p_valid;
      o_ts_fp    = ts_p_fp;
      o_ts_data  = ts_p_data;
   end

   for(genvar i = 0; i < NUM_PORTS; i++) begin : ts_ch_resp
      logic                         clk, rst, eth_clk, eth_rst;
      logic                         fifo_wr_req, fifo_wr_req_r, fifo_rd_req, fifo_empty;
      logic                         ts_valid, ts_valid_f, incr_id, equal_id, ts_cntr_dec;
      logic [CHANNEL_WIDTH-1:0]     src_ch;
      logic [ID_WIDTH-1:0]          id, id_r, new_id, new_id_f, id_f;
      logic [DATA_WIDTH-1:0]        ts_data, ts_data_f;
      logic [TO_CNTR_WIDTH-1:0]     to_cntr;
      logic [ID_WIDTH-1:0]          cur_id;
      logic [DATA_WIDTH-1:0]        new_ts_data_f, new_ts_data_fkeep;
      logic [TS_REQ_CNTR_WIDTH-1:0] ts_req_cntr;

      always_comb begin
         eth_clk      = i_clk_bus[i];
         eth_rst      = i_rst_bus[i];
         clk          = i_ts_req_clk;
         rst          = i_ts_req_rst;
         ts_valid     = ts_a_valid[i];
         //{src_ch, id} = ts_a_fp[i];
         id = ts_a_fp[i];
      end

      //always_comb fifo_wr_req = (id[ID_WIDTH-2:0] > new_id[ID_WIDTH-2:0] || id[ID_WIDTH-1] != new_id[ID_WIDTH-1]) & src_ch == i & ts_valid;
      always_comb fifo_wr_req = (id[ID_WIDTH-2:0] > new_id[ID_WIDTH-2:0] || id[ID_WIDTH-1] != new_id[ID_WIDTH-1]) & ts_valid;

      always_ff @(posedge eth_clk) begin
         if(eth_rst) begin
            new_id <= '1;
         end else begin
            if(fifo_wr_req) begin
               new_id <= id;
            end
         end
      end

      always_ff @(posedge eth_clk) begin
         fifo_wr_req_r <= fifo_wr_req;
         id_r <= id;
         ts_data <= ts_a_data[i];

         if(eth_rst) begin
            fifo_wr_req_r <= '0;
         end
      end

      dc_fifo_param #(
          .ADDR_WIDTH     (TS_FIFO_ADDR_WIDTH)
         ,.DATA_WIDTH     (ID_WIDTH+DATA_WIDTH)
         ,.RAM_BLOCK_TYPE ("M20K") //MLAB or M20K
         ,.NUMBER_WORDS   (0)
      ) ts_fifo (
         //wr clk domain
          .wrclk  (eth_clk)
         ,.wrreq  (fifo_wr_req_r)
         ,.wrfull ()
         ,.data   ({id_r, ts_data})
         //rd clk domain
         ,.rdclk  (clk)
         ,.aclr   (rst)
         ,.rdreq  (fifo_rd_req)
         ,.q      ({new_id_f, new_ts_data_f})
         ,.rdempty(fifo_empty)
      );

//      always_comb new_ts_data_fkeep = (fifo_rd_req) ? new_ts_data_f : new_ts_data_fkeep;

      always_comb fifo_rd_req = ~fifo_empty && (cur_id[ID_WIDTH-2:0] >= new_id_f[ID_WIDTH-2:0] || cur_id[ID_WIDTH-1] != new_id_f[ID_WIDTH-1]);   
      always_comb incr_id     = ~fifo_empty && (cur_id[ID_WIDTH-2:0] <= new_id_f[ID_WIDTH-2:0] || cur_id[ID_WIDTH-1] != new_id_f[ID_WIDTH-1]);  

      always_comb ts_cntr_dec = (fifo_rd_req || &to_cntr) && ts_req_cntr;
      always_ff @(posedge clk) begin
         if(rst) begin
            ts_req_cntr <= '0;
         end else begin
            //if(i_ts_req_valid && i_ts_req_channel == i && ts_cntr_dec) begin
           // if(in_st_valid && in_st_sop && ts_cntr_dec) begin                //original
            if(in_st_valid && in_st_eop && ts_cntr_dec && out_st_ready) begin
               ts_req_cntr <= ts_req_cntr;
            //end else if(i_ts_req_valid & i_ts_req_channel == i) begin        
            //end else if(in_st_valid && in_st_sop) begin                      //original
            end else if(in_st_valid && in_st_eop && out_st_ready) begin
               ts_req_cntr <= ts_req_cntr + 1'b1;
            end else if(ts_cntr_dec) begin
               ts_req_cntr <= ts_req_cntr - 1'b1;
            end
         end
      end

      always_ff @(posedge clk) begin
         if(rst) begin
            to_cntr <= '0;
         end else begin
            if(!ts_req_cntr || fifo_rd_req) begin
               to_cntr <= '0;
            end else if(~(&to_cntr)) begin
               to_cntr <= to_cntr + 1'b1;
            end
         end
      end

      always_ff @(posedge clk) begin
         if(rst) begin
            cur_id <= '0;
            cur_id_valid[i] <= '0;
         end else begin
            cur_id_valid[i] <= '0;
            ts_p_fp[i] <= cur_id;
            ts_p_data[i] <= new_ts_data_f;
            if(incr_id) begin
               cur_id_valid[i] <= '1;
               cur_id <= cur_id + 1'b1;
            end else if(&to_cntr && ts_req_cntr) begin
               cur_id_valid[i] <= '1;
               cur_id <= cur_id + 1'b1;
//               ts_p_data[i] <= new_ts_data_fkeep + {48'd0,TIMEOUT,16'd0};   //Fake TS = most recent received TS + TIMEOPUT
               ts_p_data[i] <= 0;                                             //Fake TS = 0     
            end
         end
      end

//      //debug ////////////////////////////////////
//
//      logic [24:0] deb_reqs_cntr/* synthesis noprune */;
//      logic [24:0] deb_in_resps_cntr/* synthesis noprune */;
//      logic [24:0] deb_fifo_rd_cntr/* synthesis noprune */;
//      logic [24:0] deb_out_resps_cntr/* synthesis noprune */;
//      logic [24:0] deb_to_cntr/* synthesis noprune */;
//      //logic [ID_WIDTH-1:0] first_resp_id/* synthesis noprune */;
//      //logic [ID_WIDTH-1:0] second_resp_id/* synthesis noprune */;
//      //logic [ID_WIDTH-1:0] incorrect_resp_id/* synthesis noprune */;
//      //logic [ID_WIDTH-1:0] prev_resp_id/* synthesis noprune */;
//      //logic                get_first_resp_id, get_second_resp_id;
//
//      always_ff @(posedge clk) begin
//         if(rst) begin
//            deb_reqs_cntr <= '0;
//         end else begin
//            //if(i_ts_req_valid & i_ts_req_channel == i) begin
//            if(in_st_valid && in_st_eop) begin
//               deb_reqs_cntr <= deb_reqs_cntr + 1'b1;
//            end
//         end
//      end
//
//      always_ff @(posedge eth_clk) begin
//         if(eth_rst) begin
//            deb_in_resps_cntr <= '0;
//         end else begin
//            if(ts_valid) begin
//               deb_in_resps_cntr <= deb_in_resps_cntr + 1'b1;
//            end
//         end
//      end
//
//      always_ff @(posedge clk) begin
//         if(rst) begin
//            deb_fifo_rd_cntr <= '0;
//         end else begin
//            if(fifo_rd_req) begin
//               deb_fifo_rd_cntr <= deb_fifo_rd_cntr + 1'b1;
//            end
//         end
//      end
//
//      always_ff @(posedge clk) begin
//         if(rst) begin
//            deb_out_resps_cntr <= '0;
//         end else begin
//            if(cur_id_valid[i]) begin
//               deb_out_resps_cntr <= deb_out_resps_cntr + 1'b1;
//            end
//         end
//      end
//
//      always_ff @(posedge clk) begin
//         if(rst) begin
//            deb_to_cntr <= '0;
//         end else begin
//            if(&to_cntr && ts_req_cntr) begin
//               deb_to_cntr <= deb_to_cntr + 1'b1;
//            end
//         end
//      end
//
//      //always_ff @(posedge eth_clk) begin
//      //   if(eth_rst) begin
//      //      get_first_resp_id <= '1;
//      //      get_second_resp_id <= '1;
//      //      first_resp_id <= 'hAAAA;
//      //      second_resp_id <= 'hBBBB;
//      //   end else begin
//      //      if(ts_valid) begin
//      //         get_first_resp_id <= '0;
//      //         if(get_first_resp_id) begin
//      //            first_resp_id <= id;
//      //         end
//      //         if(~get_first_resp_id) begin
//      //            get_second_resp_id <= '0;
//      //            if(get_second_resp_id) begin
//      //               second_resp_id <= id;
//      //            end
//      //         end
//      //      end
//      //   end
//      //end
//
//      //always_ff @(posedge eth_clk) begin
//      //   if(eth_rst) begin
//      //      incorrect_resp_id <= 'hCCCC;
//      //      prev_resp_id <= '0;
//      //   end else begin
//      //      if(ts_valid & ~get_first_resp_id) begin
//      //         prev_resp_id <= id;
//      //         if(prev_resp_id >= id)  begin
//      //            incorrect_resp_id <= id;
//      //         end
//      //      end
//      //   end
//      //end
//
   end
endmodule
