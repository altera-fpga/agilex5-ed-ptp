//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

module packet_switch_rx_dbg #(
   parameter NUM_PIPELINE                 = 2
  ,parameter DMA_CHNL                     = 6
  ,parameter DMA_CHNL_PER_PIPE            = DMA_CHNL/NUM_PIPELINE
  ,parameter NUM_EGR_INTF                 = DMA_CHNL_PER_PIPE + 1
  ,parameter CNTR_WIDTH                   = 32
  ,parameter ADDR_WIDTH                   = 8
  ,parameter DATA_WIDTH                   = 32
) (
  
   input var logic [NUM_PIPELINE-1:0]                     clk
  ,input var logic [NUM_PIPELINE-1:0]                     rst

  // avmm interface
  ,input var logic [NUM_PIPELINE-1:0] [ADDR_WIDTH-1:0]    avmm_address

  ,input var logic [NUM_PIPELINE-1:0]                     avmm_write
  ,input var logic [NUM_PIPELINE-1:0] [DATA_WIDTH-1:0]    avmm_writedata
  ,input var logic [NUM_PIPELINE-1:0] [(DATA_WIDTH/8)-1:0] avmm_byteenable
  
  ,input var logic [NUM_PIPELINE-1:0]                     avmm_read
  ,output var logic [NUM_PIPELINE-1:0] [DATA_WIDTH-1:0]   avmm_readdata
  ,output var logic [NUM_PIPELINE-1:0]                    avmm_readdatavalid

  // hssi to igr_wadj
  ,input var logic [NUM_PIPELINE-1:0]                     hssi2iwadj_tvalid
  ,input var logic [NUM_PIPELINE-1:0]                     hssi2iwadj_tready
  ,input var logic [NUM_PIPELINE-1:0]                     hssi2iwadj_tlast

  ,input var logic [NUM_PIPELINE-1:0]                     iwadj2pars_tvalid
  ,input var logic [NUM_PIPELINE-1:0]                     iwadj2pars_tready
  ,input var logic [NUM_PIPELINE-1:0]                     iwadj2pars_tlast

  ,input var logic [NUM_PIPELINE-1:0]                     pars2lu_tvalid
  ,input var logic [NUM_PIPELINE-1:0]                     pars2lu_tready
  ,input var packet_switch_pkg::SEGMENT_INFO_S 
                   [NUM_PIPELINE-1:0]                     pars2lu_seg_info

  ,input var logic [NUM_PIPELINE-1:0][NUM_EGR_INTF-1:0]   lu2ewadj_tvalid
  ,input var logic [NUM_PIPELINE-1:0][NUM_EGR_INTF-1:0]   lu2ewadj_tready
  ,input var packet_switch_pkg::SEGMENT_INFO_S 
                   [NUM_PIPELINE-1:0][NUM_EGR_INTF-1:0]   lu2ewadj_seg_info
  
  ,input var logic [NUM_PIPELINE-1:0]                     lk_drop_tvalid
  ,input var packet_switch_pkg::TCAM_RESULT_S 
                   [NUM_PIPELINE-1: 0]                    lk_drop_tuser_result
  ,input var logic [NUM_PIPELINE-1:0]                     lk_drop_tuser_found

  ,input var logic [NUM_PIPELINE-1:0]                     ewadj_user_tvalid
  ,input var logic [NUM_PIPELINE-1:0]                     ewadj_user_tready
  ,input var logic [NUM_PIPELINE-1:0]                     ewadj_user_tlast

  ,input var logic [NUM_PIPELINE-1:0]                     ewadj_dma_tvalid
  ,input var logic [NUM_PIPELINE-1:0]                     ewadj_dma_tready
  ,input var logic [NUM_PIPELINE-1:0]                     ewadj_dma_tlast

  ,input var logic [DMA_CHNL-1:0]                         dmux2dma_tvalid
  ,input var logic [DMA_CHNL-1:0]                         dmux2dma_tready
  ,input var logic [DMA_CHNL-1:0]                         dmux2dma_tlast

  ,input var logic [NUM_PIPELINE-1:0]                     iwadj_dbg_cnt_drop_en
  ,input var logic [NUM_PIPELINE-1:0][7:0] 			      dmux_dbg_cnt_drop_en
  ,input var logic [NUM_PIPELINE-1:0]                     ewadj_dbg_cnt_drop_en
);

import packet_switch_pkg::*;

// rx ingress interface - hssi to igr_wadj
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                                 hssi2iwadj_cnt_prev;
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                                 hssi2iwadj_cnt_next;

// rx ingress interface - igr_wadj to parser
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                                 iwadj2pars_cnt_prev;
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                                 iwadj2pars_cnt_next;

// rx ingress interface - parser to lkup
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                                 pars2lkup_cnt_prev;
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                                 pars2lkup_cnt_next;

// rx ingress interface - lkup drop count
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                                 lkup_drop_cnt_prev;
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                                 lkup_drop_cnt_next;

// rx ingress interface - lkup to egr_wadj user
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                                 lkup2ewadj_user_cnt_prev;
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                                 lkup2ewadj_user_cnt_next;

// rx egress interface - egr_wadj to user ch
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                                 ewadj2user_cnt_prev;
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                                 ewadj2user_cnt_next;

// rx ingress interface - ewadj user drop count
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                                 ewadj_user_drop_cnt_prev;
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                                 ewadj_user_drop_cnt_next;

// rx ingress interface - lkup to egr_wadj dma
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                                 lkup2ewadj_dma_cnt_prev;
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                                 lkup2ewadj_dma_cnt_next;

// rx egress interface - dma egr_wadj to dmux
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                                 ewadj2dmux_dma_cnt_prev;
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                                 ewadj2dmux_dma_cnt_next;

logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                                 rx_iwadj_drop_cnt_prev;
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                                 rx_iwadj_drop_cnt_next;

// rx ingress interface - ewadj user drop count
logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0] [CNTR_WIDTH-1:0]          dmux_dma_drop_cnt_prev;
logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0] [CNTR_WIDTH-1:0]          dmux_dma_drop_cnt_next;

// rx egress interface - dmux to dma ch
logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0] [CNTR_WIDTH-1:0]          dmux2dma_cnt_prev;
logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0] [CNTR_WIDTH-1:0]          dmux2dma_cnt_next;

// counter enables
logic [NUM_PIPELINE-1:0]                            hssi2iwadj_cnt_en;
logic [NUM_PIPELINE-1:0]                            iwadj2pars_cnt_en;
logic [NUM_PIPELINE-1:0]                            pars2lkup_cnt_en;
logic [NUM_PIPELINE-1:0]                            lkup_drop_cnt_en;

logic [NUM_PIPELINE-1:0]                            lkup2ewadj_user_cnt_en;
logic [NUM_PIPELINE-1:0]                            ewadj2user_cnt_en;
logic [NUM_PIPELINE-1:0]                            ewadj_user_drop_cnt_en, rx_iwadj_drop_cnt_drop_en;

logic [NUM_PIPELINE-1:0]                            lkup2ewadj_dma_cnt_en;
logic [NUM_PIPELINE-1:0]                            ewadj2dmux_dma_cnt_en;
logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]     dmux_dma_drop_cnt_en;
logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]     dmux2dma_cnt_en;
logic [DMA_CHNL-1:0]                                dmux2dma_cnt_en_w;

genvar num_pp, i, j;
generate

     for (i = 0; i < NUM_PIPELINE; i++) begin
       for (j = 0; j < DMA_CHNL_PER_PIPE; j++) begin
        always_ff @(posedge clk[i]) begin
          dmux2dma_cnt_en_w[(i*DMA_CHNL_PER_PIPE)+j] <= 
                        dmux2dma_tvalid[(i*DMA_CHNL_PER_PIPE)+j] 
                        & dmux2dma_tready[(i*DMA_CHNL_PER_PIPE)+j] 
                        & dmux2dma_tlast[(i*DMA_CHNL_PER_PIPE)+j];
        end //always_ff
       end // for
     end // for

  for (num_pp = 0; num_pp < NUM_PIPELINE; num_pp++) begin

    always_ff @(posedge clk[num_pp]) begin
      hssi2iwadj_cnt_en[num_pp] <= hssi2iwadj_tvalid[num_pp] & 
                                   hssi2iwadj_tready[num_pp] & 
                                   hssi2iwadj_tlast[num_pp];

      iwadj2pars_cnt_en[num_pp] <= iwadj2pars_tvalid[num_pp] & 
                                   iwadj2pars_tready[num_pp] & 
                                   iwadj2pars_tlast[num_pp];


      pars2lkup_cnt_en[num_pp] <= pars2lu_tvalid[num_pp] & 
                                  pars2lu_tready[num_pp] & 
                                  pars2lu_seg_info[num_pp].eop;

      lkup_drop_cnt_en[num_pp] <= (lk_drop_tvalid[num_pp] & 
                                  lk_drop_tuser_result[num_pp].drop & 
                                  lk_drop_tuser_found[num_pp]) || 
                                  (lk_drop_tvalid[num_pp] & 
                                  !lk_drop_tuser_found[num_pp]);

      lkup2ewadj_user_cnt_en[num_pp] <= lu2ewadj_tvalid[num_pp][1] & 
                                        lu2ewadj_tready[num_pp][1] & 
                                        lu2ewadj_seg_info[num_pp][1].eop;

      ewadj2user_cnt_en[num_pp] <= ewadj_user_tvalid[num_pp] & 
                                   ewadj_user_tready[num_pp] & 
                                   ewadj_user_tlast[num_pp];

      ewadj_user_drop_cnt_en[num_pp] <= ewadj_dbg_cnt_drop_en[num_pp];

      rx_iwadj_drop_cnt_drop_en[num_pp] <= iwadj_dbg_cnt_drop_en[num_pp];

      lkup2ewadj_dma_cnt_en[num_pp] <= lu2ewadj_tvalid[num_pp][0] & 
                                       lu2ewadj_tready[num_pp][0] & 
                                       lu2ewadj_seg_info[num_pp][0].eop;


      ewadj2dmux_dma_cnt_en[num_pp] <= ewadj_dma_tvalid[num_pp] & 
                                       ewadj_dma_tready[num_pp] & 
                                       ewadj_dma_tlast[num_pp];

      dmux_dma_drop_cnt_en[num_pp] <= dmux_dbg_cnt_drop_en[num_pp][DMA_CHNL_PER_PIPE-1:0]; 

      dmux2dma_cnt_en[num_pp] <= dmux2dma_cnt_en_w[(num_pp*DMA_CHNL_PER_PIPE) + DMA_CHNL_PER_PIPE - 1:num_pp*DMA_CHNL_PER_PIPE]; 
    end

    packet_switch_dbg_cntr #(
      .CNTR_WIDTH(CNTR_WIDTH)
    ) hssi2iwadj_cntr (
      .clk                                   (clk[num_pp])
      ,.rst                                   (rst[num_pp])
      ,.enable                                (hssi2iwadj_cnt_en[num_pp])
      ,.cntr_i                                (hssi2iwadj_cnt_prev[num_pp])
      ,.cntr_o                                (hssi2iwadj_cnt_next[num_pp])
    );

    packet_switch_dbg_cntr #(
      .CNTR_WIDTH(CNTR_WIDTH)
    ) iwadj2pars_cntr (
      .clk                                   (clk[num_pp])
      ,.rst                                   (rst[num_pp])
      ,.enable                                (iwadj2pars_cnt_en[num_pp])
      ,.cntr_i                                (iwadj2pars_cnt_prev[num_pp])
      ,.cntr_o                                (iwadj2pars_cnt_next[num_pp])
    );

    packet_switch_dbg_cntr #(
      .CNTR_WIDTH(CNTR_WIDTH)
    ) pars2lkup_cntr (
      .clk                                   (clk[num_pp])
      ,.rst                                   (rst[num_pp])
      ,.enable                                (pars2lkup_cnt_en[num_pp])
      ,.cntr_i                                (pars2lkup_cnt_prev[num_pp])
      ,.cntr_o                                (pars2lkup_cnt_next[num_pp])
    );

    packet_switch_dbg_cntr #(
      .CNTR_WIDTH(CNTR_WIDTH)
    ) lkup_drop_cntr (
      .clk                                   (clk[num_pp])
      ,.rst                                   (rst[num_pp])
      ,.enable                                (lkup_drop_cnt_en[num_pp])
      ,.cntr_i                                (lkup_drop_cnt_prev[num_pp])
      ,.cntr_o                                (lkup_drop_cnt_next[num_pp])
    );

    packet_switch_dbg_cntr #(
      .CNTR_WIDTH(CNTR_WIDTH)
    ) lkup2ewadj_user_cntr (
      .clk                                   (clk[num_pp])
      ,.rst                                   (rst[num_pp])
      ,.enable                                (lkup2ewadj_user_cnt_en[num_pp])
      ,.cntr_i                                (lkup2ewadj_user_cnt_prev[num_pp])
      ,.cntr_o                                (lkup2ewadj_user_cnt_next[num_pp])
    );

    packet_switch_dbg_cntr #(
      .CNTR_WIDTH(CNTR_WIDTH)
    ) ewadj2user_cntr (
      .clk                                   (clk[num_pp])
      ,.rst                                   (rst[num_pp])
      ,.enable                                (ewadj2user_cnt_en[num_pp])
      ,.cntr_i                                (ewadj2user_cnt_prev[num_pp])
      ,.cntr_o                                (ewadj2user_cnt_next[num_pp])
    );

    packet_switch_dbg_cntr #(
      .CNTR_WIDTH(CNTR_WIDTH)
    ) ewadj_user_drop_cntr (
      .clk                                   (clk[num_pp])
      ,.rst                                   (rst[num_pp])
      ,.enable                                (ewadj_user_drop_cnt_en[num_pp])
      ,.cntr_i                                (ewadj_user_drop_cnt_prev[num_pp])
      ,.cntr_o                                (ewadj_user_drop_cnt_next[num_pp])
    );

    packet_switch_dbg_cntr #(
      .CNTR_WIDTH(CNTR_WIDTH)
    ) iwadj_drop_cntr (
      .clk                                   (clk[num_pp])
      ,.rst                                   (rst[num_pp])
      ,.enable                                (rx_iwadj_drop_cnt_drop_en[num_pp])
      ,.cntr_i                                (rx_iwadj_drop_cnt_prev[num_pp])
      ,.cntr_o                                (rx_iwadj_drop_cnt_next[num_pp])
    );

    packet_switch_dbg_cntr #(
      .CNTR_WIDTH(CNTR_WIDTH)
    ) lkup2ewadj_dma_cntr (
      .clk                                   (clk[num_pp])
      ,.rst                                   (rst[num_pp])
      ,.enable                                (lkup2ewadj_dma_cnt_en[num_pp])
      ,.cntr_i                                (lkup2ewadj_dma_cnt_prev[num_pp])
      ,.cntr_o                                (lkup2ewadj_dma_cnt_next[num_pp])
    );

    packet_switch_dbg_cntr #(
      .CNTR_WIDTH(CNTR_WIDTH)
    ) ewadj2dmux_dma_cntr (
      .clk                                   (clk[num_pp])
      ,.rst                                   (rst[num_pp])
      ,.enable                                (ewadj2dmux_dma_cnt_en[num_pp])
      ,.cntr_i                                (ewadj2dmux_dma_cnt_prev[num_pp])
      ,.cntr_o                                (ewadj2dmux_dma_cnt_next[num_pp])
    );

    packet_switch_dbg_cntr #(
      .CNTR_WIDTH(CNTR_WIDTH)
      ,.NUM_CNTR(DMA_CHNL_PER_PIPE)
    ) dmux_dma_drop_cntr (
      .clk                                   (clk[num_pp])
      ,.rst                                   (rst[num_pp])
      ,.enable                                (dmux_dma_drop_cnt_en[num_pp])
      ,.cntr_i                                (dmux_dma_drop_cnt_prev[num_pp])
      ,.cntr_o                                (dmux_dma_drop_cnt_next[num_pp])
    );

    packet_switch_dbg_cntr #(
      .CNTR_WIDTH(CNTR_WIDTH)
      ,.NUM_CNTR(DMA_CHNL_PER_PIPE)
    ) dmux2dma_cntr (
      .clk                                   (clk[num_pp])
      ,.rst                                   (rst[num_pp])
      ,.enable                                (dmux2dma_cnt_en[num_pp])
      ,.cntr_i                                (dmux2dma_cnt_prev[num_pp])
      ,.cntr_o                                (dmux2dma_cnt_next[num_pp])
    );


    packet_switch_rx_dbg_cntr_intf #(
       .INST_ID(num_pp)
      ,.DMA_CHNL_PER_PIPE(DMA_CHNL_PER_PIPE)
      ,.BASE_ADDR(RX_DBG_CNT_START_ADDR+(num_pp*PORT_OFFSET))
      ,.MAX_ADDR('h3C)
      ,.ADDR_WIDTH(ADDR_WIDTH)
      ,.DATA_WIDTH(DATA_WIDTH)
      ,.CNTR_WIDTH(CNTR_WIDTH)
    ) packet_switch_rx_dbg_cntr_intf_inst (
       .clk                                                   (clk[num_pp])
      ,.rst                                                   (rst[num_pp])

      // avmm interface
      ,.avmm_writedata                                        (avmm_writedata[num_pp])
      ,.avmm_read                                             (avmm_read[num_pp])
      ,.avmm_write                                            (avmm_write[num_pp])
      ,.avmm_byteenable                                       (avmm_byteenable[num_pp])
      ,.avmm_readdata                                         (avmm_readdata[num_pp])
      ,.avmm_readdatavalid                                    (avmm_readdatavalid[num_pp])
      ,.avmm_address                                          (avmm_address[num_pp])
      
      ,.hssi2iwadj_cnt_prev                                   (hssi2iwadj_cnt_prev[num_pp])
      ,.hssi2iwadj_cnt_next                                   (hssi2iwadj_cnt_next[num_pp])

      ,.iwadj2pars_cnt_prev                                   (iwadj2pars_cnt_prev[num_pp])
      ,.iwadj2pars_cnt_next                                   (iwadj2pars_cnt_next[num_pp])

      ,.pars2lkup_cnt_prev                                    (pars2lkup_cnt_prev[num_pp])
      ,.pars2lkup_cnt_next                                    (pars2lkup_cnt_next[num_pp])

      ,.lkup_drop_cnt_prev                                    (lkup_drop_cnt_prev[num_pp])
      ,.lkup_drop_cnt_next                                    (lkup_drop_cnt_next[num_pp])

      ,.lkup2ewadj_user_cnt_prev                              (lkup2ewadj_user_cnt_prev[num_pp])
      ,.lkup2ewadj_user_cnt_next                              (lkup2ewadj_user_cnt_next[num_pp])

      ,.ewadj2user_cnt_prev                                   (ewadj2user_cnt_prev[num_pp])
      ,.ewadj2user_cnt_next                                   (ewadj2user_cnt_next[num_pp])

      ,.ewadj_user_drop_cnt_prev                              (ewadj_user_drop_cnt_prev[num_pp])
      ,.ewadj_user_drop_cnt_next                              (ewadj_user_drop_cnt_next[num_pp])

      ,.lkup2ewadj_dma_cnt_prev                               (lkup2ewadj_dma_cnt_prev[num_pp])
      ,.lkup2ewadj_dma_cnt_next                               (lkup2ewadj_dma_cnt_next[num_pp])

      ,.rx_iwadj_drop_cnt_prev                                (rx_iwadj_drop_cnt_prev[num_pp])
      ,.rx_iwadj_drop_cnt_next                                (rx_iwadj_drop_cnt_next[num_pp])

      ,.ewadj2dmux_dma_cnt_prev                               (ewadj2dmux_dma_cnt_prev[num_pp])
      ,.ewadj2dmux_dma_cnt_next                               (ewadj2dmux_dma_cnt_next[num_pp])

      ,.dmux_dma_drop_cnt_prev                                (dmux_dma_drop_cnt_prev[num_pp])
      ,.dmux_dma_drop_cnt_next                                (dmux_dma_drop_cnt_next[num_pp])

      ,.dmux2dma_cnt_prev                                     (dmux2dma_cnt_prev[num_pp])
      ,.dmux2dma_cnt_next                                     (dmux2dma_cnt_next[num_pp])

    );
  end
endgenerate
endmodule

