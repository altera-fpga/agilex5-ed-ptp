//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module tx_dma_fifo #(
    parameter string DEVICE                = "s10" //must be "a10" or "s10"
   ,parameter int    USE_RX_READY          = 1
   ,parameter int    MEMORY_CAPACITY_WORDS = 512
   ,parameter int    AVST_DATA_WIDTH       = 128
   ,parameter int    AVST_ERROR_WIDTH      = 6
   ,parameter int    TS_FIFOS_ADDR_WIDTH   = 9
   ,parameter int    TS_WIDTH              = 96
   ,parameter int    TS_RESP_WIDTH         = 256
   ,parameter int    TS_FP_WIDTH           = 20
   ,parameter int    AVST_EMPTY_WIDTH      = 4
   ,parameter int    DEBUG_EN              = 1
) (
    input  logic                        in_st_clk
   ,input  logic                        in_st_rst
   ,input  logic                        out_st_clk
   ,input  logic                        out_st_rst
   ,input  logic                        ts_resp_clk
   ,input  logic                        ts_resp_rst
   ,input  logic                        csr_clk
   ,input  logic                        csr_rst

   ,output logic                        in_st_ready
   ,input  logic                        in_st_sop
   ,input  logic                        in_st_valid
   ,input  logic                        in_st_eop
   ,input  logic [AVST_DATA_WIDTH-1:0]  in_st_data
   ,input  logic [AVST_EMPTY_WIDTH-1:0] in_st_empty
   ,input  logic [AVST_ERROR_WIDTH-1:0] in_st_error

   ,output logic                        out_ts_req_valid
   ,output logic [TS_FP_WIDTH-1:0]      out_ts_req_fingerprint

   ,input  logic                        in_ts_valid
   ,input  logic [TS_FP_WIDTH-1:0]      in_ts_fp
   ,input  logic [TS_WIDTH-1:0]         in_ts_data

   ,input  logic                        out_st_ready
   ,output logic                        out_st_sop
   ,output logic                        out_st_valid
   ,output logic                        out_st_eop
   ,output logic [AVST_DATA_WIDTH-1:0]  out_st_data
   ,output logic [AVST_EMPTY_WIDTH-1:0] out_st_empty
   ,output logic [AVST_ERROR_WIDTH-1:0] out_st_error

   ,output logic                        in_ts_resp_ready
   ,input  logic                        in_ts_resp_valid
   ,input  logic [TS_RESP_WIDTH-1:0]    in_ts_resp_data

   ,input  logic                        out_ts_resp_ready
   ,output logic                        out_ts_resp_valid
   ,output logic [TS_RESP_WIDTH-1:0]    out_ts_resp_data
);

   localparam int RX_AVST_READY_LATENCY = 0;
   localparam int FIFO_ERROR_WIDTH = 1;
   localparam int CDC_FIFO_USR_WIDTH = 1;

   logic                       ts_fifo_empty, ts_fifo_rdreq;
   logic [TS_FP_WIDTH-1:0]     fingerprint;
   logic [TS_WIDTH-1:0]        resp_ts_data;

   always_comb out_st_error = '0;

   cdc_packet_fifo #(
       .USE_RX_READY          (USE_RX_READY)
      ,.DEVICE                (DEVICE)
      ,.MEMORY_CAPACITY_WORDS (MEMORY_CAPACITY_WORDS)
      ,.AVST_DATA_WIDTH       (AVST_DATA_WIDTH)
      ,.RX_AVST_READY_LATENCY (RX_AVST_READY_LATENCY)
      ,.AVST_USER_WIDTH       (CDC_FIFO_USR_WIDTH)
      ,.AVST_ERROR_WIDTH      (FIFO_ERROR_WIDTH)
   ) cdc_packet_fifo (
       .in_avst_clk           (in_st_clk)
      ,.in_avst_reset         (in_st_rst)
      ,.in_avst_ready         (in_st_ready)
      ,.in_avst_valid         (in_st_valid)
      ,.in_avst_startofpacket (in_st_sop)
      ,.in_avst_endofpacket   (in_st_eop)
      ,.in_avst_error         ('0)
      ,.in_avst_empty         (in_st_empty)
      ,.in_avst_data          (in_st_data)
      ,.in_avst_user          ('0)

      ,.out_avst_clk          (out_st_clk)
      ,.out_avst_reset        (out_st_rst)
      ,.out_avst_ready        (out_st_ready)
      ,.out_avst_valid        (out_st_valid)
      ,.out_avst_startofpacket(out_st_sop)
      ,.out_avst_endofpacket  (out_st_eop)
      ,.out_avst_empty        (out_st_empty)
      ,.out_avst_data         (out_st_data)
      ,.out_avst_user         ()

      ,.csr_mm_clk            (csr_clk)
      ,.csr_mm_reset          (csr_rst)
      ,.csr_mm_waitrequest    ()
      ,.csr_mm_read           ('0)
      ,.csr_mm_write          ('0)
      ,.csr_mm_address        ()
      ,.csr_mm_writedata      ()
      ,.csr_mm_readdatavalid  ()
      ,.csr_mm_readdata       ()

      ,.fill_level_on_tx_clk  ()
   );

   //always_comb out_ts_req_valid = '1;
   always_comb out_ts_req_valid = out_st_valid & out_st_sop & out_st_ready;
   always_comb out_ts_req_fingerprint = fingerprint;

   always_ff @(posedge out_st_clk) begin
      if(out_st_rst) begin
         fingerprint <= '0;
      end else begin
         if(out_st_ready && out_st_sop && out_st_valid) begin
            fingerprint <= fingerprint + 1'b1;
         end
      end
   end

   dc_fifo_param #(
       .ADDR_WIDTH     (TS_FIFOS_ADDR_WIDTH)
      ,.DATA_WIDTH     (TS_WIDTH)
      ,.RAM_BLOCK_TYPE ("M20K") //MLAB or M20K
      ,.NUMBER_WORDS   (0)
   ) ts_fifo (
      //wr clk domain
       .wrclk  (ts_resp_clk)
      ,.wrreq  (in_ts_valid)
      ,.wrfull ()
      ,.data   (in_ts_data)
      //rd clk domain
      ,.rdclk  (in_st_clk)
      ,.aclr   (in_st_rst)
      ,.rdreq  (ts_fifo_rdreq)
      ,.q      (resp_ts_data)
      ,.rdempty(ts_fifo_empty)
   );

   always_comb begin
      in_ts_resp_ready = out_ts_resp_ready & ~ts_fifo_empty;
      ts_fifo_rdreq = ~ts_fifo_empty & in_ts_resp_valid & in_ts_resp_ready;
      out_ts_resp_valid = in_ts_resp_valid & ~ts_fifo_empty;
      out_ts_resp_data[159:0] = {'0, in_ts_resp_data[127:0]};
      out_ts_resp_data[255:160] = resp_ts_data;
   end


endmodule
