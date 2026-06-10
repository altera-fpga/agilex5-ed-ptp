//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//########################################################################
//#This is base sequence used to configure PKT CLIENTS,
//#TXDMA and RX DMA for basic data flow.
//########################################################################
class sm_ptp_msgdma_cfg_seq extends sm_ptp_basic_seq;
    
  rand int no_of_transactions ;
  rand int unsigned cfg_sequence_length = 10;
  rand bit h2d_descr_poll_en[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  rand bit d2h_descr_poll_en[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];

  `uvm_object_utils(sm_ptp_msgdma_cfg_seq);
  // `uvm_object_utils_begin(sm_ptp_msgdma_cfg_seq);
  //   `uvm_field_int(h2d_descr_poll_en, UVM_ALL_ON)
  //   `uvm_field_int(d2h_descr_poll_en, UVM_ALL_ON)
  // `uvm_object_utils_end

  function new (string name = "sm_ptp_msgdma_cfg_seq");
    super.new(name);
  endfunction : new

    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0]     data [];
    bit [`SVT_AXI_WSTRB_WIDTH-1:0]        wstrb [];
    bit [31:0]                            addr;
    bit [31:0]                            csr_wdata;   
    bit                                   h2f_cfg_done; 
    rand bit h2d_ch_en[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
    rand bit d2h_ch_en[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];


  constraint ch_en_c {
     soft foreach (h2d_ch_en[i,j]) h2d_ch_en[i][j] == 0;
     soft foreach (d2h_ch_en[i,j]) d2h_ch_en[i][j] == 0;
     ((`SM_PTP_NUM_PORTS == 1) && (`SM_MSGDMA_NUM_CHANN_PER_PORT == 1)) -> h2d_ch_en[0][0] == 1;
     ((`SM_PTP_NUM_PORTS == 1) && (`SM_MSGDMA_NUM_CHANN_PER_PORT == 1)) -> d2h_ch_en[0][0] == 1;
     // TBD
     // if ((`SM_PTP_NUM_PORTS == 1) && (`SM_MSGDMA_NUM_CHANN_PER_PORT == 1))
     //   foreach h2d_ch_en[i] if (i != 0) h2d_ch_en[i] == 0;
     soft foreach (h2d_descr_poll_en[i,j]) h2d_descr_poll_en[i][j] == 0;
     soft foreach (d2h_descr_poll_en[i,j]) d2h_descr_poll_en[i][j] == 0;
  }

  task body();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] rd_data [];

    `uvm_info(get_full_name(), "Body: Entered...", UVM_DEBUG)

    data = new[1];
    wstrb = new[1];
    h2f_cfg_done = 0;

    csr_wdata = 'h0;
    `uvm_info(get_full_name(), "Body:DESC CFG START...", UVM_LOW) 

    for (bit [1:0] i=0; i<`SM_PTP_MAX_PORTS;i++)
      for (bit [1:0] j=0; j<`SM_MSGDMA_NUM_CHANN_PER_PORT;j++)
        `uvm_info(get_full_name(),
                  $sformatf("h2d_ch_en[%0d][%0d] %b, d2h_ch_en[%0d][%0d] %b, desc poll en, h2d[%0d][%0d] %b, d2h[%0d][%0d] %b",
                            i, j, h2d_ch_en[i][j], i, j, d2h_ch_en[i][j], i, j, this.h2d_descr_poll_en[i][j], i, j, this.d2h_descr_poll_en[i][j]),
                  UVM_LOW)

    `uvm_info(get_full_name(), "Reset Tx prefetcher", UVM_LOW)

    addr = `SM_PTP_MSGDMA_TX_PREF_P0_CH0_CSR;
    csr_wdata = 'h4;
    data[0] = csr_wdata;
    axi_master_write(
            .address(addr),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(data),
            .burst_length(1),
            .wstrb(wstrb)
    );

    if (`SM_MSGDMA_NUM_CHANN_PER_PORT > 1) begin
      addr = `SM_PTP_MSGDMA_TX_PREF_P0_CH1_CSR;
      axi_master_write(
              .address(addr),
              .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
              .data(data),
              .burst_length(1),
              .wstrb(wstrb)
      );
    end

    if (`SM_PTP_NUM_PORTS > 1) begin
      addr = `SM_PTP_MSGDMA_TX_PREF_P1_CH0_CSR;
      axi_master_write(
              .address(addr),
              .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
              .data(data),
              .burst_length(1),
              .wstrb(wstrb)
      );

      if (`SM_MSGDMA_NUM_CHANN_PER_PORT > 1) begin
        addr = `SM_PTP_MSGDMA_TX_PREF_P1_CH1_CSR;
        axi_master_write(
                .address(addr),
                .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                .data(data),
                .burst_length(1),
                .wstrb(wstrb)
        );
      end
    end

    `uvm_info(get_full_name(), "Poll for Reset Tx prefetcher to cpmplete", UVM_LOW)
    addr = `SM_PTP_MSGDMA_TX_PREF_P0_CH0_CSR;
    while (rd_data[0][4] == 1) begin
      axi_master_read(
            .address(addr),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .burst_length(1),
            .data(rd_data)
      );
    end
    rd_data.delete();
    if (`SM_MSGDMA_NUM_CHANN_PER_PORT > 1) begin
      addr = `SM_PTP_MSGDMA_TX_PREF_P0_CH1_CSR;
      while (rd_data[0][4] == 1) begin
        axi_master_read(
              .address(addr),
              .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
              .burst_length(1),
              .data(rd_data)
        );
      end
      rd_data.delete();
    end

    if (`SM_PTP_NUM_PORTS > 1) begin
      addr = `SM_PTP_MSGDMA_TX_PREF_P1_CH0_CSR;
      while (rd_data[0][4] == 1) begin
        axi_master_read(
              .address(addr),
              .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
              .burst_length(1),
              .data(rd_data)
        );
      end
      rd_data.delete();

      if (`SM_MSGDMA_NUM_CHANN_PER_PORT > 1) begin
        addr = `SM_PTP_MSGDMA_TX_PREF_P1_CH1_CSR;
        while (rd_data[0][4] == 1) begin
          axi_master_read(
                .address(addr),
                .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                .burst_length(1),
                .data(rd_data)
          );
        end
        rd_data.delete();
      end
    end

    `uvm_info(get_full_name(), "Reset Tx prefetcher complete", UVM_LOW)

    `uvm_info(get_full_name(), "Reset Rx prefetcher", UVM_LOW)
    csr_wdata = 'h4;
    data[0] = csr_wdata;
    addr = `SM_PTP_MSGDMA_RX_PREF_P0_CH0_CSR;
    axi_master_write(
            .address(addr),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .data(data),
            .burst_length(1),
            .wstrb(wstrb)
    );

    if (`SM_MSGDMA_NUM_CHANN_PER_PORT > 1) begin
      addr = `SM_PTP_MSGDMA_RX_PREF_P0_CH1_CSR;
      axi_master_write(
              .address(addr),
              .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
              .data(data),
              .burst_length(1),
              .wstrb(wstrb)
      );
    end

    if (`SM_PTP_NUM_PORTS > 1) begin
      addr = `SM_PTP_MSGDMA_RX_PREF_P1_CH0_CSR;
      axi_master_write(
              .address(addr),
              .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
              .data(data),
              .burst_length(1),
              .wstrb(wstrb)
      );

      if (`SM_MSGDMA_NUM_CHANN_PER_PORT > 1) begin
        addr = `SM_PTP_MSGDMA_RX_PREF_P1_CH1_CSR;
        axi_master_write(
                .address(addr),
                .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                .data(data),
                .burst_length(1),
                .wstrb(wstrb)
        );
      end
    end

    `uvm_info(get_full_name(), "Poll for Reset Rx prefetcher to complete", UVM_LOW)
    addr = `SM_PTP_MSGDMA_RX_PREF_P0_CH0_CSR;
    while (rd_data[0][4] == 1) begin
      axi_master_read(
            .address(addr),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .burst_length(1),
            .data(rd_data)
      );
    end
    rd_data.delete();
    if (`SM_MSGDMA_NUM_CHANN_PER_PORT > 1) begin
      addr = `SM_PTP_MSGDMA_RX_PREF_P0_CH1_CSR;
      while (rd_data[0][4] == 1) begin
        axi_master_read(
              .address(addr),
              .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
              .burst_length(1),
              .data(rd_data)
        );
      end
      rd_data.delete();
    end

    if (`SM_PTP_NUM_PORTS > 1) begin
      addr = `SM_PTP_MSGDMA_RX_PREF_P1_CH0_CSR;
      while (rd_data[0][4] == 1) begin
        axi_master_read(
              .address(addr),
              .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
              .burst_length(1),
              .data(rd_data)
        );
      end
      rd_data.delete();

      if (`SM_MSGDMA_NUM_CHANN_PER_PORT > 1) begin
        addr = `SM_PTP_MSGDMA_RX_PREF_P1_CH1_CSR;
        while (rd_data[0][4] == 1) begin
          axi_master_read(
                .address(addr),
                .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                .burst_length(1),
                .data(rd_data)
          );
        end
        rd_data.delete();
      end
    end
    `uvm_info(get_full_name(), "Reset Rx prefetcher complete", UVM_LOW)

    `uvm_info(get_full_name(), "Body: TX DMA CHANNELS CFG STARTS...", UVM_LOW)

    // Port 0, Channel 0
    if (h2d_ch_en[0][0] == 1) begin
      // csr_wdata = 'h18000000;
      csr_wdata = {1'b0, `DESCR, `H2D_ST_AGENT, 2'd0, 2'd0, 23'h0};
      wstrb[0] = 'hf;
      addr = `SM_PTP_MSGDMA_TX_PREF_P0_CH0_CSR+'h4;
      `uvm_info(get_full_name(), "PORT0 TX DMA CONFIG...", UVM_LOW)
      data[0] = csr_wdata;
      axi_master_write(
              .address(addr),
              .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
              .data(data),
              .burst_length(1),
              .wstrb(wstrb)
      );
 
      addr = `SM_PTP_MSGDMA_TX_PREF_P0_CH0_CSR;
      csr_wdata = {30'h0, h2d_descr_poll_en[0][0], h2d_ch_en[0][0]};
      data[0] = csr_wdata;
      axi_master_write(
              .address(addr),
              .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
              .data(data),
              .burst_length(1),
              .wstrb(wstrb)
      );
    end

    if (`SM_MSGDMA_NUM_CHANN_PER_PORT > 1) begin
      // Port 0, Channel 1
      if (h2d_ch_en[0][1] == 1) begin
        // csr_wdata = {0001_1010_0000, 20'h0} => 'h1600_0000;
        csr_wdata = {1'b0, `DESCR, `H2D_ST_AGENT, 2'd1, 2'd0, 23'h0};
        wstrb[0] = 'hf;
        addr = `SM_PTP_MSGDMA_TX_PREF_P0_CH1_CSR+'h4;
        `uvm_info(get_full_name(), "PORT1 TX DMA CONFIG...", UVM_LOW)
        data[0] = csr_wdata;
        axi_master_write(
                .address(addr),
                .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                .data(data),
                .burst_length(1),
                .wstrb(wstrb)
        );
 
        addr = `SM_PTP_MSGDMA_TX_PREF_P0_CH1_CSR;
        csr_wdata = {30'h0, h2d_descr_poll_en[0][1], h2d_ch_en[0][1]};
        data[0] = csr_wdata;
        axi_master_write(
                .address(addr),
                .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                .data(data),
                .burst_length(1),
                .wstrb(wstrb)
        );
      end
    end

    if (`SM_PTP_NUM_PORTS > 1) begin
      // Port 1, Channel 0
      if (h2d_ch_en[1][0] == 1) begin
        // csr_wdata = {0001_1000_1000, 20'h0} => 'h1880_0000;
        csr_wdata = {1'b0, `DESCR, `H2D_ST_AGENT, 2'd0, 2'd1, 23'h0};
        wstrb[0] = 'hf;
        addr = `SM_PTP_MSGDMA_TX_PREF_P1_CH0_CSR+'h4;
        `uvm_info(get_full_name(), "PORT0 TX DMA CONFIG...", UVM_LOW)
        data[0] = csr_wdata;
        axi_master_write(
                .address(addr),
                .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                .data(data),
                .burst_length(1),
                .wstrb(wstrb)
        );
 
        addr = `SM_PTP_MSGDMA_TX_PREF_P1_CH0_CSR;
        csr_wdata = {30'h0, h2d_descr_poll_en[1][0], h2d_ch_en[1][0]};
        data[0] = csr_wdata;
        axi_master_write(
                .address(addr),
                .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                .data(data),
                .burst_length(1),
                .wstrb(wstrb)
        );
      end

      if (`SM_MSGDMA_NUM_CHANN_PER_PORT > 1) begin
        // Port 1, Channel 1
        if (h2d_ch_en[1][1] == 1) begin
          // csr_wdata = {0001_1010_1000, 20'h0} => 'h1680_0000;
          csr_wdata = {1'b0, `DESCR, `H2D_ST_AGENT, 2'd1, 2'd1, 23'h0};
          wstrb[0] = 'hf;
          addr = `SM_PTP_MSGDMA_TX_PREF_P1_CH1_CSR+'h4;
          `uvm_info(get_full_name(), "PORT1 TX DMA CONFIG...", UVM_LOW)
          data[0] = csr_wdata;
          axi_master_write(
                  .address(addr),
                  .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                  .data(data),
                  .burst_length(1),
                  .wstrb(wstrb)
          );
 
          addr = `SM_PTP_MSGDMA_TX_PREF_P1_CH1_CSR;
          csr_wdata = {30'h0, h2d_descr_poll_en[1][1], h2d_ch_en[1][1]};
          data[0] = csr_wdata;
          axi_master_write(
                  .address(addr),
                  .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                  .data(data),
                  .burst_length(1),
                  .wstrb(wstrb)
          );
        end
      end
    end

    `uvm_info(get_full_name(), "Body: TX DMA CHANNELS CFG ENDS...", UVM_LOW)
    `uvm_info(get_full_name(), "Body: RX DMA CHANNELS CFG STARTS...", UVM_LOW)

    // port 0, Channel 0
    if (d2h_ch_en[0][0] == 1) begin
      // csr_wdata = 'h10000000;
      csr_wdata = {1'b0, `DESCR, `D2H_ST_AGENT, 2'd0, 2'd0, 23'h0};
      addr = `SM_PTP_MSGDMA_RX_PREF_P0_CH0_CSR+'h4;
      `uvm_info(get_full_name(), "PORT0 RX DMA CONFIG...", UVM_LOW)
      data[0] = csr_wdata;
      axi_master_write(
              .address(addr),
              .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
              .data(data),
              .burst_length(1),
              .wstrb(wstrb)
      );
 
      addr = `SM_PTP_MSGDMA_RX_PREF_P0_CH0_CSR;
      csr_wdata = {30'h0, d2h_descr_poll_en[0][0], d2h_ch_en[0][0]};
      data[0] = csr_wdata;
      axi_master_write(
              .address(addr),
              .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
              .data(data),
              .burst_length(1),
              .wstrb(wstrb)
      );
    end

    if (`SM_MSGDMA_NUM_CHANN_PER_PORT > 1) begin
      // port 0, Channel 1
      if (d2h_ch_en[0][1] == 1) begin
        // csr_wdata = {0001_0010_0000, 20'h0} => 'h1200_0000;
        csr_wdata = {1'b0, `DESCR, `D2H_ST_AGENT, 2'd1, 2'd0, 23'h0};
        addr = `SM_PTP_MSGDMA_RX_PREF_P0_CH1_CSR+'h4;
        `uvm_info(get_full_name(), "PORT1 RX DMA CONFIG...", UVM_LOW)
        data[0] = csr_wdata;
        axi_master_write(
                .address(addr),
                .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                .data(data),
                .burst_length(1),
                .wstrb(wstrb)
        );
 
        addr = `SM_PTP_MSGDMA_RX_PREF_P0_CH1_CSR;
        csr_wdata = {30'h0, d2h_descr_poll_en[0][1], d2h_ch_en[0][1]};
        data[0] = csr_wdata;
        axi_master_write(
                .address(addr),
                .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                .data(data),
                .burst_length(1),
                .wstrb(wstrb)
        );
      end
    end

    if (`SM_PTP_NUM_PORTS > 1) begin
      // port 1, Channel 0
      if (d2h_ch_en[1][0] == 1) begin
        // csr_wdata = {0001_0000_1000, 20'h0} => 'h1080_0000;
        csr_wdata = {1'b0, `DESCR, `D2H_ST_AGENT, 2'd0, 2'd1, 23'h0};
        addr = `SM_PTP_MSGDMA_RX_PREF_P1_CH0_CSR+'h4;
        `uvm_info(get_full_name(), "PORT0 RX DMA CONFIG...", UVM_LOW)
        data[0] = csr_wdata;
        axi_master_write(
                .address(addr),
                .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                .data(data),
                .burst_length(1),
                .wstrb(wstrb)
        );
 
        addr = `SM_PTP_MSGDMA_RX_PREF_P1_CH0_CSR;
        csr_wdata = {30'h0, d2h_descr_poll_en[1][0], d2h_ch_en[1][0]};
        data[0] = csr_wdata;
        axi_master_write(
                .address(addr),
                .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                .data(data),
                .burst_length(1),
                .wstrb(wstrb)
        );
      end

      if (`SM_MSGDMA_NUM_CHANN_PER_PORT > 1) begin
        // port 1, Channel 1
        if (d2h_ch_en[1][1] == 1) begin
          // csr_wdata = {0001_0010_1000, 20'h0} => 'h1280_0000;
          csr_wdata = {1'b0, `DESCR, `D2H_ST_AGENT, 2'd1, 2'd1, 23'h0};
          addr = `SM_PTP_MSGDMA_RX_PREF_P1_CH1_CSR+'h4;
          `uvm_info(get_full_name(), "PORT1 RX DMA CONFIG...", UVM_LOW)
          data[0] = csr_wdata;
          axi_master_write(
                  .address(addr),
                  .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                  .data(data),
                  .burst_length(1),
                  .wstrb(wstrb)
          );
 
          addr = `SM_PTP_MSGDMA_RX_PREF_P1_CH1_CSR;
          csr_wdata = {30'h0, d2h_descr_poll_en[1][1], d2h_ch_en[1][1]};
          data[0] = csr_wdata;
          axi_master_write(
                  .address(addr),
                  .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                  .data(data),
                  .burst_length(1),
                  .wstrb(wstrb)
          );
        end
      end
    end

    `uvm_info(get_full_name(), "Body: RX DMA CHANNELS CFG ENDS...", UVM_LOW)
    h2f_cfg_done = 1;
    `uvm_info(get_full_name(), "Body:ENDS...", UVM_DEBUG) 
  endtask: body
endclass : sm_ptp_msgdma_cfg_seq
