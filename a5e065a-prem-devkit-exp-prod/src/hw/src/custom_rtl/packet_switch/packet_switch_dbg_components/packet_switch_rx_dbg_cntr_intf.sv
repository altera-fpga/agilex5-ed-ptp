//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

module packet_switch_rx_dbg_cntr_intf #(
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

  ,input var logic [CNTR_WIDTH-1:0]                             hssi2iwadj_cnt_next
  ,output var logic [CNTR_WIDTH-1:0]                            hssi2iwadj_cnt_prev

  ,input var logic [CNTR_WIDTH-1:0]                             iwadj2pars_cnt_next
  ,output var logic [CNTR_WIDTH-1:0]                            iwadj2pars_cnt_prev

  ,input var logic [CNTR_WIDTH-1:0]                             pars2lkup_cnt_next
  ,output var logic [CNTR_WIDTH-1:0]                            pars2lkup_cnt_prev

  ,input var logic [CNTR_WIDTH-1:0]                             lkup_drop_cnt_next
  ,output var logic [CNTR_WIDTH-1:0]                            lkup_drop_cnt_prev

  ,input var logic [CNTR_WIDTH-1:0]                             lkup2ewadj_user_cnt_next
  ,output var logic [CNTR_WIDTH-1:0]                            lkup2ewadj_user_cnt_prev

  ,input var logic [CNTR_WIDTH-1:0]                             ewadj2user_cnt_next
  ,output var logic [CNTR_WIDTH-1:0]                            ewadj2user_cnt_prev

  ,input var logic [CNTR_WIDTH-1:0]                             rx_iwadj_drop_cnt_next
  ,output var logic [CNTR_WIDTH-1:0]                            rx_iwadj_drop_cnt_prev

  ,input var logic [CNTR_WIDTH-1:0]                             ewadj_user_drop_cnt_next
  ,output var logic [CNTR_WIDTH-1:0]                            ewadj_user_drop_cnt_prev

  ,input var logic [CNTR_WIDTH-1:0]                             lkup2ewadj_dma_cnt_next
  ,output var logic [CNTR_WIDTH-1:0]                            lkup2ewadj_dma_cnt_prev

  ,input var logic [CNTR_WIDTH-1:0]                             ewadj2dmux_dma_cnt_next
  ,output var logic [CNTR_WIDTH-1:0]                            ewadj2dmux_dma_cnt_prev

  ,input var logic [DMA_CHNL_PER_PIPE-1:0][CNTR_WIDTH-1:0]      dmux_dma_drop_cnt_next
  ,output var logic [MAX_DMA_CHNL_PER_PIPE-1:0][CNTR_WIDTH-1:0] dmux_dma_drop_cnt_prev

  ,input var logic [DMA_CHNL_PER_PIPE-1:0][CNTR_WIDTH-1:0]      dmux2dma_cnt_next
  ,output var logic [MAX_DMA_CHNL_PER_PIPE-1:0][CNTR_WIDTH-1:0] dmux2dma_cnt_prev

);

logic [ADDR_WIDTH-1:0]    avmm_address_chkd;
logic                     avmm_read_chkd;
logic                     avmm_write_chkd;
logic [DATA_WIDTH-1:0]    avmm_writedata_chkd;
logic [(DATA_WIDTH/8)-1:0] avmm_byteenable_chkd;

packet_switch_rx_avmm_addr_chk #(
   .INST_ID      (INST_ID)
  ,.BASE_ADDR    (BASE_ADDR)
  ,.ADDR_WIDTH   (ADDR_WIDTH)
  ,.DATA_WIDTH   (DATA_WIDTH)
) packet_switch_rx_avmm_addr_chk_inst (
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

  rx_dbg_csr rx_dbg_csr_inst (
    
  // hssi2iwadj_stats_reg.transferred_stats
   .we_hssi2iwadj_stats_reg_transferred_stats                ('1)
  ,.hssi2iwadj_stats_reg_transferred_stats_i                 (hssi2iwadj_cnt_next)
  ,.hssi2iwadj_stats_reg_transferred_stats                   (hssi2iwadj_cnt_prev)
  // iwadj2pars_stats_reg.transferred_stats
  ,.we_iwadj2pars_stats_reg_transferred_stats                ('1)
  ,.iwadj2pars_stats_reg_transferred_stats_i                 (iwadj2pars_cnt_next)
  ,.iwadj2pars_stats_reg_transferred_stats                   (iwadj2pars_cnt_prev)
  // pars2lkup_stats_reg.transferred_stats
  ,.we_pars2lkup_stats_reg_transferred_stats                 ('1)
  ,.pars2lkup_stats_reg_transferred_stats_i                  (pars2lkup_cnt_next)
  ,.pars2lkup_stats_reg_transferred_stats                    (pars2lkup_cnt_prev)
  // lkup_drop_stats_reg.dropped_stats
  ,.we_lkup_drop_stats_reg_dropped_stats                     ('1)
  ,.lkup_drop_stats_reg_dropped_stats_i                      (lkup_drop_cnt_next)
  ,.lkup_drop_stats_reg_dropped_stats                        (lkup_drop_cnt_prev)
  // lkup2ewadj_user_stats_reg.transferred_stats
  ,.we_lkup2ewadj_user_stats_reg_transferred_stats           ('1)
  ,.lkup2ewadj_user_stats_reg_transferred_stats_i            (lkup2ewadj_user_cnt_next)
  ,.lkup2ewadj_user_stats_reg_transferred_stats              (lkup2ewadj_user_cnt_prev)
  // ewadj2user_stats_reg.transferred_stats
  ,.we_ewadj2user_stats_reg_transferred_stats                ('1)
  ,.ewadj2user_stats_reg_transferred_stats_i                 (ewadj2user_cnt_next)
  ,.ewadj2user_stats_reg_transferred_stats                   (ewadj2user_cnt_prev)
  // ewadj_user_drop_stats_reg.dropped_stats
  ,.we_ewadj_user_drop_stats_reg_dropped_stats               ('1)
  ,.ewadj_user_drop_stats_reg_dropped_stats_i                (ewadj_user_drop_cnt_next)
  ,.ewadj_user_drop_stats_reg_dropped_stats                  (ewadj_user_drop_cnt_prev)
  // lkup2ewadj_dma_stats_reg.transferred_stats
  ,.we_lkup2ewadj_dma_stats_reg_transferred_stats            ('1)
  ,.lkup2ewadj_dma_stats_reg_transferred_stats_i             (lkup2ewadj_dma_cnt_next)
  ,.lkup2ewadj_dma_stats_reg_transferred_stats               (lkup2ewadj_dma_cnt_prev)
  // ewadj2dmux_dma_stats_reg.transferred_stats
  ,.we_ewadj2dmux_dma_stats_reg_transferred_stats            ('1)
  ,.ewadj2dmux_dma_stats_reg_transferred_stats_i             (ewadj2dmux_dma_cnt_next)
  ,.ewadj2dmux_dma_stats_reg_transferred_stats               (ewadj2dmux_dma_cnt_prev)
  // dmux_dma_0_drop_stats_reg.dropped_stats
  ,.we_dmux_dma_0_drop_stats_reg_dropped_stats               ('1)
  ,.dmux_dma_0_drop_stats_reg_dropped_stats_i                (dmux_dma_drop_cnt_next[0])
  ,.dmux_dma_0_drop_stats_reg_dropped_stats                  (dmux_dma_drop_cnt_prev[0])
  // dmux_dma_1_drop_stats_reg.dropped_stats
  ,.we_dmux_dma_1_drop_stats_reg_dropped_stats               ('1)
  ,.dmux_dma_1_drop_stats_reg_dropped_stats_i                ((DMA_CHNL_PER_PIPE == 2) ? dmux_dma_drop_cnt_next[1] : 32'h0)
  ,.dmux_dma_1_drop_stats_reg_dropped_stats                  (dmux_dma_drop_cnt_prev[1])
  // dmux_dma_2_drop_stats_reg.dropped_stats
  ,.we_dmux_dma_2_drop_stats_reg_dropped_stats               ('1)
  ,.dmux_dma_2_drop_stats_reg_dropped_stats_i                ((DMA_CHNL_PER_PIPE == 3) ? dmux_dma_drop_cnt_next[2] : 32'h0)
  ,.dmux_dma_2_drop_stats_reg_dropped_stats                  (dmux_dma_drop_cnt_prev[2])
  // dmux2dma_0_stats_reg.transferred_stats
  ,.we_dmux2dma_0_stats_reg_transferred_stats                ('1)
  ,.dmux2dma_0_stats_reg_transferred_stats_i                 (dmux2dma_cnt_next[0])
  ,.dmux2dma_0_stats_reg_transferred_stats                   (dmux2dma_cnt_prev[0])
  // dmux2dma_1_stats_reg.transferred_stats
  ,.we_dmux2dma_1_stats_reg_transferred_stats                ('1)
  ,.dmux2dma_1_stats_reg_transferred_stats_i                 ((DMA_CHNL_PER_PIPE == 2) ? dmux2dma_cnt_next[1] : 32'h0)
  ,.dmux2dma_1_stats_reg_transferred_stats                   (dmux2dma_cnt_prev[1])
  // dmux2dma_2_stats_reg.transferred_stats
  ,.we_dmux2dma_2_stats_reg_transferred_stats                ('1)
  ,.dmux2dma_2_stats_reg_transferred_stats_i                 ((DMA_CHNL_PER_PIPE == 3) ? dmux2dma_cnt_next[2] : 32'h0)
  ,.dmux2dma_2_stats_reg_transferred_stats                   (dmux2dma_cnt_prev[2])

  ,.we_rx_iwadj_drop_stats_reg_dropped_stats                 ('1)
  ,.rx_iwadj_drop_stats_reg_dropped_stats_i                  (rx_iwadj_drop_cnt_next)
  ,.rx_iwadj_drop_stats_reg_dropped_stats                    (rx_iwadj_drop_cnt_prev)

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
