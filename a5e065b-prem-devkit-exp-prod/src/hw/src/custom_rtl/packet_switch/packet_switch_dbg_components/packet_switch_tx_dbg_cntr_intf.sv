//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

module packet_switch_tx_dbg_cntr_intf #(
   parameter INST_ID              = 0
  ,parameter DMA_CHNL_PER_PIPE    = 3
  ,parameter MAX_DMA_CHNL_PER_PIPE = 3
  ,parameter BASE_ADDR            = 'h0
  ,parameter MAX_ADDR             = 'h8
  ,parameter ADDR_WIDTH           = 8
  ,parameter DATA_WIDTH           = 32
  ,parameter CNTR_WIDTH           = 32
) (
   input var logic                                              clk
  ,input var logic                                              rst

  // avmm stuff
  ,input var logic [DATA_WIDTH-1:0]                             avmm_writedata
  ,input var logic                                              avmm_read
  ,input var logic                                              avmm_write
  ,input var logic [3:0]                                        avmm_byteenable
  ,output var logic [DATA_WIDTH-1:0]                            avmm_readdata
  ,output var logic                                             avmm_readdatavalid
  ,input var logic [ADDR_WIDTH-1:0]                             avmm_address


  // tx ingress interface - DMA channels into igr_wadj
  //    {dma_ch_0-2}
  // ie {a0, a1, a2}
  ,input var logic [DMA_CHNL_PER_PIPE-1:0] [CNTR_WIDTH-1:0]               dma2iwadj_cnt_next
  ,output var logic [MAX_DMA_CHNL_PER_PIPE-1:0] [CNTR_WIDTH-1:0]          dma2iwadj_cnt_prev
  
  // tx ingress interface - DMA channels into igr_arb
  //    {dma_ch_0-2,   user}
  // ie {a0, a1, a2, user_0}
  ,input var logic [(DMA_CHNL_PER_PIPE+1)-1:0] [CNTR_WIDTH-1:0]           iwadj2iarb_cnt_next
  ,output var logic [(MAX_DMA_CHNL_PER_PIPE+1)-1:0] [CNTR_WIDTH-1:0]      iwadj2iarb_cnt_prev

  // tx egress interface - Outputs to HSSI
  ,input var logic [CNTR_WIDTH-1:0]                                       iarb2hssi_cnt_next
  ,output var logic [CNTR_WIDTH-1:0]                                      iarb2hssi_cnt_prev

);

logic [ADDR_WIDTH-1:0]    avmm_address_chkd;
logic                     avmm_read_chkd;
logic                     avmm_write_chkd;
logic [DATA_WIDTH-1:0]    avmm_writedata_chkd;
logic [(DATA_WIDTH/8)-1:0] avmm_byteenable_chkd;

packet_switch_tx_avmm_addr_chk #(
   .INST_ID      (INST_ID)
  ,.BASE_ADDR    (BASE_ADDR)
  ,.ADDR_WIDTH   (ADDR_WIDTH)
  ,.DATA_WIDTH   (DATA_WIDTH)
) packet_switch_tx_avmm_addr_chk_inst (
   .clk                 (clk)
  ,.rst                 (rst)
  // inputs
  ,.avmm_address        (avmm_address)
  ,.avmm_read           (avmm_read)
  ,.avmm_write          (avmm_write)
  ,.avmm_writedata      (avmm_writedata)
  ,.avmm_byteenable     (avmm_byteenable)

  // outputs
  ,.avmm_address_c1     (avmm_address_chkd)
  ,.avmm_read_c1        (avmm_read_chkd)
  ,.avmm_write_c1       (avmm_write_chkd)
  ,.avmm_writedata_c1   (avmm_writedata_chkd)
  ,.avmm_byteenable_c1  (avmm_byteenable_chkd)
);

tx_dbg_csr tx_dbg_csr_inst (

   // dma2iwadj_ch0_stats_reg.transferred_stats
    .we_dma2iwadj_ch0_stats_reg_transferred_stats             ('1)
   ,.dma2iwadj_ch0_stats_reg_transferred_stats_i              (dma2iwadj_cnt_next[0])
   ,.dma2iwadj_ch0_stats_reg_transferred_stats                (dma2iwadj_cnt_prev[0])
   // dma2iwadj_ch1_stats_reg.transferred_stats
   ,.we_dma2iwadj_ch1_stats_reg_transferred_stats             ('1)
   ,.dma2iwadj_ch1_stats_reg_transferred_stats_i              ((DMA_CHNL_PER_PIPE == 2) ? dma2iwadj_cnt_next[1] : 32'h0)
   ,.dma2iwadj_ch1_stats_reg_transferred_stats                (dma2iwadj_cnt_prev[1])
   // dma2iwadj_ch2_stats_reg.transferred_stats
   ,.we_dma2iwadj_ch2_stats_reg_transferred_stats             ('1)
   ,.dma2iwadj_ch2_stats_reg_transferred_stats_i              ((DMA_CHNL_PER_PIPE == 3) ? dma2iwadj_cnt_next[2]: 32'h0)
   ,.dma2iwadj_ch2_stats_reg_transferred_stats                (dma2iwadj_cnt_prev[2])
   // iwadj2iarb_ch0_stats_reg.transferred_stats
   ,.we_iwadj2iarb_ch0_stats_reg_transferred_stats            ('1)
   ,.iwadj2iarb_ch0_stats_reg_transferred_stats_i             (iwadj2iarb_cnt_next[1])
   ,.iwadj2iarb_ch0_stats_reg_transferred_stats               (iwadj2iarb_cnt_prev[1])
   // iwadj2iarb_ch1_stats_reg.transferred_stats
   ,.we_iwadj2iarb_ch1_stats_reg_transferred_stats            ('1)
   ,.iwadj2iarb_ch1_stats_reg_transferred_stats_i             ((DMA_CHNL_PER_PIPE == 2) ? iwadj2iarb_cnt_next[2] : 32'h0)
   ,.iwadj2iarb_ch1_stats_reg_transferred_stats               (iwadj2iarb_cnt_prev[2])
   // iwadj2iarb_ch2_stats_reg.transferred_stats
   ,.we_iwadj2iarb_ch2_stats_reg_transferred_stats            ('1)
   ,.iwadj2iarb_ch2_stats_reg_transferred_stats_i             ((DMA_CHNL_PER_PIPE == 3) ? iwadj2iarb_cnt_next[3] : 32'h0)
   ,.iwadj2iarb_ch2_stats_reg_transferred_stats               (iwadj2iarb_cnt_prev[3])
   // user2iarb_stats_reg.transferred_stats
   ,.we_user2iarb_stats_reg_transferred_stats                 ('1)
   ,.user2iarb_stats_reg_transferred_stats_i                  (iwadj2iarb_cnt_next[0])
   ,.user2iarb_stats_reg_transferred_stats                    (iwadj2iarb_cnt_prev[0])
   // iarb2hssi_stats_reg.transferred_stats
   ,.we_iarb2hssi_stats_reg_transferred_stats                 ('1)
   ,.iarb2hssi_stats_reg_transferred_stats_i                  (iarb2hssi_cnt_next)
   ,.iarb2hssi_stats_reg_transferred_stats                    (iarb2hssi_cnt_prev)

  // Bus interface
  ,.clk                                                       (clk)
  ,.reset                                                     (rst)
  ,.writedata                                                 (avmm_writedata_chkd)
  ,.read                                                      (avmm_read_chkd)
  ,.write                                                     (avmm_write_chkd)
  ,.byteenable                                                (avmm_byteenable_chkd)
  ,.readdata                                                  (avmm_readdata)
  ,.readdatavalid                                             (avmm_readdatavalid)
  ,.address                                                   (avmm_address_chkd[$clog2(MAX_ADDR)-1:0])

);

endmodule
