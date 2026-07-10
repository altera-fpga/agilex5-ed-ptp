//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

module packet_switch_tx_dbg #(
   parameter NUM_PIPELINE                 = 2
  ,parameter DMA_CHNL                     = 6
  ,parameter DMA_CHNL_PER_PIPE            = DMA_CHNL/NUM_PIPELINE
  ,parameter CNTR_WIDTH                   = 32
  ,parameter ADDR_WIDTH                   = 8
  ,parameter DATA_WIDTH                   = 32
) (
  
   input var logic [NUM_PIPELINE-1:0]                             clk
  ,input var logic [NUM_PIPELINE-1:0]                             rst

  // avmm interface
  ,input var logic [NUM_PIPELINE-1:0] [ADDR_WIDTH-1:0]            avmm_address

  ,input var logic [NUM_PIPELINE-1:0]                             avmm_write
  ,input var logic [NUM_PIPELINE-1:0] [DATA_WIDTH-1:0]            avmm_writedata
  ,input var logic [NUM_PIPELINE-1:0] [(DATA_WIDTH/8)-1:0]        avmm_byteenable
  
  ,input var logic [NUM_PIPELINE-1:0]                             avmm_read
  ,output var logic [NUM_PIPELINE-1:0] [DATA_WIDTH-1:0]           avmm_readdata
  ,output var logic [NUM_PIPELINE-1:0]                            avmm_readdatavalid

  //    {dma_ch_a, dma_ch_b}
  ,input var logic [DMA_CHNL-1:0]                                 dma2iwadj_tvalid
  ,input var logic [DMA_CHNL-1:0]                                 dma2iwadj_tready
  ,input var logic [DMA_CHNL-1:0]                                 dma2iwadj_tlast

  //    { dma_ch_b,   user_1, dma_ch_a,   user_0}
  // ie { b2, b1, b0, user_1, a2, a1, a0, user_0}
  ,input var logic [NUM_PIPELINE*(DMA_CHNL_PER_PIPE+1)-1:0]  ing2iarb_tvalid
  ,input var logic [NUM_PIPELINE*(DMA_CHNL_PER_PIPE+1)-1:0]  ing2iarb_tready
  ,input var logic [NUM_PIPELINE*(DMA_CHNL_PER_PIPE+1)-1:0]  ing2iarb_tlast

  //    {hssi_0, hssi_1}
  ,input var logic [NUM_PIPELINE-1:0]                             iarb2hssi_tvalid
  ,input var logic [NUM_PIPELINE-1:0]                             iarb2hssi_tready
  ,input var logic [NUM_PIPELINE-1:0]                             iarb2hssi_tlast

);


import packet_switch_pkg::*;

// tx ingress interface - DMA channels into igr_wadj
logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0] [CNTR_WIDTH-1:0]        dma2iwadj_cnt_next;
logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0] [CNTR_WIDTH-1:0]        dma2iwadj_cnt_prev;

// tx ingress interface - DMA channels into igr_arb
logic [NUM_PIPELINE-1:0][(DMA_CHNL_PER_PIPE+1)-1:0] [CNTR_WIDTH-1:0]    iwadj2iarb_cnt_next;
logic [NUM_PIPELINE-1:0][(DMA_CHNL_PER_PIPE+1)-1:0] [CNTR_WIDTH-1:0]    iwadj2iarb_cnt_prev;

// tx egress interface - Outputs to HSSI
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                               iarb2hssi_cnt_next;
logic [NUM_PIPELINE-1:0] [CNTR_WIDTH-1:0]                               iarb2hssi_cnt_prev;


// counter enables 
logic [DMA_CHNL-1:0]                                                    dma2iwadj_cnt_en_w;
logic [NUM_PIPELINE-1:0][DMA_CHNL_PER_PIPE-1:0]                         dma2iwadj_cnt_en;
logic [NUM_PIPELINE-1:0][(DMA_CHNL_PER_PIPE+1)-1:0]                     iwadj2iarb_cnt_en;
logic [NUM_PIPELINE*(DMA_CHNL_PER_PIPE+1)-1:0]                          iwadj2iarb_cnt_en_w;
logic [NUM_PIPELINE-1:0]                                                iarb2hssi_cnt_en;

genvar num_pp, i, j;
generate 
 
     for (i = 0; i < NUM_PIPELINE; i++) begin
       for (j = 0; j < DMA_CHNL_PER_PIPE; j++) begin
        always_ff @(posedge clk[i]) begin
          dma2iwadj_cnt_en_w[(i*DMA_CHNL_PER_PIPE)+j] <= 
                        dma2iwadj_tvalid[(i*DMA_CHNL_PER_PIPE)+j] 
                        & dma2iwadj_tready[(i*DMA_CHNL_PER_PIPE)+j] 
                        & dma2iwadj_tlast[(i*DMA_CHNL_PER_PIPE)+j];
        end //always_ff
       end // for
     end // for

     for (i = 0; i < NUM_PIPELINE; i++) begin
       for (j = 0; j < (DMA_CHNL_PER_PIPE+1); j++) begin
        always_ff @(posedge clk[i]) begin
          iwadj2iarb_cnt_en_w[(i*(DMA_CHNL_PER_PIPE+1))+j] <= 
                        ing2iarb_tvalid[(i*(DMA_CHNL_PER_PIPE+1))+j] 
                        & ing2iarb_tready[(i*(DMA_CHNL_PER_PIPE+1))+j] 
                        & ing2iarb_tlast[(i*(DMA_CHNL_PER_PIPE+1))+j];
        end //always_ff
       end // for
     end // for
  
  for (num_pp = 0; num_pp < NUM_PIPELINE; num_pp++) begin

    always_ff @(posedge clk[num_pp]) begin

      
      dma2iwadj_cnt_en[num_pp] <= dma2iwadj_cnt_en_w[(num_pp*DMA_CHNL_PER_PIPE) + DMA_CHNL_PER_PIPE - 1:num_pp*DMA_CHNL_PER_PIPE];

      // iwadj2iarb_cnt_en[num_pp] <= ing2iarb_tvalid[num_pp] & ing2iarb_tready[num_pp] & ing2iarb_tlast[num_pp];
      iwadj2iarb_cnt_en[num_pp] <= 
         iwadj2iarb_cnt_en_w[(num_pp*(DMA_CHNL_PER_PIPE+1)) + (DMA_CHNL_PER_PIPE+1) - 1:num_pp*(DMA_CHNL_PER_PIPE+1)];

      iarb2hssi_cnt_en[num_pp] <= iarb2hssi_tvalid[num_pp] & iarb2hssi_tready[num_pp] & iarb2hssi_tlast[num_pp];
    end

    packet_switch_dbg_cntr  #(
      .CNTR_WIDTH(CNTR_WIDTH)
      ,.NUM_CNTR(DMA_CHNL_PER_PIPE)
    ) dma2iwadj_cntr (
       .clk                           		(clk[num_pp])
      ,.rst                           		(rst[num_pp])
      ,.enable														(dma2iwadj_cnt_en[num_pp])
      ,.cntr_i                     				(dma2iwadj_cnt_prev[num_pp])
      ,.cntr_o                       			(dma2iwadj_cnt_next[num_pp])
    );

    packet_switch_dbg_cntr  #(
      .CNTR_WIDTH(CNTR_WIDTH)
      ,.NUM_CNTR(DMA_CHNL_PER_PIPE+1)
    ) iwadj2iarb_cntr (
       .clk                           		(clk[num_pp])
      ,.rst                           		(rst[num_pp])
      ,.enable														(iwadj2iarb_cnt_en[num_pp])
      ,.cntr_i                     				(iwadj2iarb_cnt_prev[num_pp])
      ,.cntr_o                       			(iwadj2iarb_cnt_next[num_pp])
    );
  
    packet_switch_dbg_cntr  #(
      .CNTR_WIDTH(CNTR_WIDTH)
    ) iarb2hssi_cntr (
       .clk                           		(clk[num_pp])
      ,.rst                           		(rst[num_pp])
      ,.enable														(iarb2hssi_cnt_en[num_pp])
      ,.cntr_i                     				(iarb2hssi_cnt_prev[num_pp])
      ,.cntr_o                       			(iarb2hssi_cnt_next[num_pp])
    );

    packet_switch_tx_dbg_cntr_intf #(
      .INST_ID(num_pp)
      ,.DMA_CHNL_PER_PIPE(DMA_CHNL_PER_PIPE)
      ,.BASE_ADDR(TX_DBG_CNT_START_ADDR+(num_pp*PORT_OFFSET))
      ,.MAX_ADDR('h20)
      ,.ADDR_WIDTH(ADDR_WIDTH)
      ,.DATA_WIDTH(DATA_WIDTH)
      ,.CNTR_WIDTH(CNTR_WIDTH)
    ) packet_switch_tx_dbg_cntr_intf_inst (
       .clk                                               (clk[num_pp])
      ,.rst                                               (rst[num_pp])

      // avmm interface
      ,.avmm_writedata                                    (avmm_writedata[num_pp])
      ,.avmm_read                                         (avmm_read[num_pp])
      ,.avmm_write                                        (avmm_write[num_pp])
      ,.avmm_byteenable                                   (avmm_byteenable[num_pp])
      ,.avmm_readdata                                     (avmm_readdata[num_pp])
      ,.avmm_readdatavalid                                (avmm_readdatavalid[num_pp])
      ,.avmm_address                                      (avmm_address[num_pp])

      // tx ingress interface - DMA channels into igr_wadj
      ,.dma2iwadj_cnt_next                                (dma2iwadj_cnt_next[num_pp])
      ,.dma2iwadj_cnt_prev                                (dma2iwadj_cnt_prev[num_pp])

      // tx ingress interface - DMA channels into igr_arb
      ,.iwadj2iarb_cnt_next                               (iwadj2iarb_cnt_next[num_pp])
      ,.iwadj2iarb_cnt_prev                               (iwadj2iarb_cnt_prev[num_pp])

      // tx egress interface - Outputs to HSSI
      ,.iarb2hssi_cnt_next                                (iarb2hssi_cnt_next[num_pp])
      ,.iarb2hssi_cnt_prev                                (iarb2hssi_cnt_prev[num_pp])
    );
  end
endgenerate
endmodule