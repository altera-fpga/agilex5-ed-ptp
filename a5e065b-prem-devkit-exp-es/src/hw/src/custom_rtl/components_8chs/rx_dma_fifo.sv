//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module rx_dma_fifo #(
    parameter string DEVICE                = "s10" //must be "a10" or "s10"
   ,parameter int    USE_RX_READY          = 0
   ,parameter int    MEMORY_CAPACITY_WORDS = 512
   ,parameter int    AVST_DATA_WIDTH       = 128
   ,parameter int    AVST_ERROR_WIDTH      = 6
   ,parameter int    TS_WIDTH              = 96
   ,parameter int    TS_RESP_WIDTH         = 256
   ,parameter int    AVST_EMPTY_WIDTH      = 4
   ,parameter int    TO_CNTR_WIDTH         = 20
) (
    input  logic                        in_st_clk
   ,input  logic                        in_st_rst
   ,input  logic                        out_st_clk
   ,input  logic                        out_st_rst
   ,input  logic                        csr_clk
   ,input  logic                        csr_rst

   ,input  logic                        in_st_sop
   ,input  logic                        in_st_valid
   ,input  logic                        in_st_eop
   ,input  logic [AVST_DATA_WIDTH-1:0]  in_st_data
   ,input  logic [AVST_EMPTY_WIDTH-1:0] in_st_empty
   ,input  logic [AVST_ERROR_WIDTH-1:0] in_st_error

   ,input  logic                        in_ts_valid
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

   logic                     ts_fifo_rst, ts_fifo_empty;
   logic [TS_WIDTH-1:0]      ts_data, ts_data_f;
   logic [TO_CNTR_WIDTH-1:0] to_cntr;

   always_comb out_st_error = '0;

   cdc_packet_fifo #(
       .USE_RX_READY          (USE_RX_READY)
      ,.DEVICE                (DEVICE)
      ,.MEMORY_CAPACITY_WORDS (MEMORY_CAPACITY_WORDS)
      ,.AVST_DATA_WIDTH       (AVST_DATA_WIDTH)
      ,.RX_AVST_READY_LATENCY (RX_AVST_READY_LATENCY)
      ,.AVST_USER_WIDTH       (TS_WIDTH)
      ,.AVST_ERROR_WIDTH      (FIFO_ERROR_WIDTH)
   ) cdc_packet_fifo (
       .in_avst_clk           (in_st_clk)
      ,.in_avst_reset         (in_st_rst)
      ,.in_avst_ready         ()
      ,.in_avst_valid         (in_st_valid)
      ,.in_avst_startofpacket (in_st_sop)
      ,.in_avst_endofpacket   (in_st_eop)
      ,.in_avst_error         ('0)
      ,.in_avst_empty         (in_st_empty)
      ,.in_avst_data          (in_st_data)
      ,.in_avst_user          (in_ts_data)

      ,.out_avst_clk          (out_st_clk)
      ,.out_avst_reset        (out_st_rst)
      ,.out_avst_ready        (out_st_ready)
      ,.out_avst_valid        (out_st_valid)
      ,.out_avst_startofpacket(out_st_sop)
      ,.out_avst_endofpacket  (out_st_eop)
      ,.out_avst_empty        (out_st_empty)
      ,.out_avst_data         (out_st_data)
      ,.out_avst_user         (ts_data)

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

   parameter_scfifo #(
       .ADDR_WIDTH        (4)
      ,.DATA_WIDTH        (TS_WIDTH)
      ,.ALMOST_FULL_VALUE (3)
      ,.RAM_BLOCK_TYPE    ("MLAB")
      ,.NUMBER_WORDS      (6)
   ) ts_fifo (
       .clock      (out_st_clk)
      ,.aclr       (ts_fifo_rst)
      ,.wrreq      (out_st_ready & out_st_sop & out_st_valid)
      ,.rdreq      (in_ts_resp_ready & in_ts_resp_valid)
      ,.data       (ts_data)
      ,.almost_full()
      ,.empty      (ts_fifo_empty)
      ,.full       ()
      ,.q          (ts_data_f)
      ,.usedw      ()
   );

   always_comb begin
      in_ts_resp_ready = out_ts_resp_ready;
      out_ts_resp_valid = in_ts_resp_valid;
      out_ts_resp_data[159:0] = {'0, in_ts_resp_data[127:0]};
      out_ts_resp_data[255:160] = ts_data_f;
   end

   always_ff @(posedge out_st_clk) begin
      if(out_st_rst) begin
         ts_fifo_rst <= '1;
         to_cntr <= '0;
      end else begin
         ts_fifo_rst <= &to_cntr;
         if(in_ts_resp_ready & in_ts_resp_valid) begin
            to_cntr <= '0;
         end else if(!ts_fifo_empty) begin
            to_cntr <= to_cntr + 1'b1;
         end
      end
   end
endmodule
