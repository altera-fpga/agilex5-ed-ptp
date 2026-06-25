//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//########################################################################

`ifndef SM_PTP_QSFP_BASIC_SEQ__SV
  `define SM_PTP_QSFP_BASIC_SEQ__SV

class sm_ptp_qsfp_basic_seq extends sm_ptp_basic_seq;
  `uvm_object_utils(sm_ptp_qsfp_basic_seq)

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  function new(name = "sm_ptp_qsfp_basic_seq");
    super.new(name);
  endfunction: new

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task body();
  endtask: body

  // ------------------------------
  task init_sfp();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] wr_data[];
    bit [`SVT_AXI_WSTRB_WIDTH-1:0] 	  wstrb [];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] rd_data [];

    wr_data = new[1];
    wstrb   = new[1];

    wr_data[0] = 64'h0000_0000_0000_0002;
    wstrb[0]   = 8'hFF;
    axi_master_write(.address(`SM_PTP_QSFP0_SYSTEM_OFFSET+'h20),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_64BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

    wr_data[0] = 64'h0000_0000_0000_0000;
    wstrb[0]   = 8'hFF;
    axi_master_write(.address(`SM_PTP_QSFP0_SYSTEM_OFFSET+'h20),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_64BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

 //   wr_data[0] = 'h1f4; //100KHz
 //   wr_data[0] = 'h7d; //400KHz
    wr_data[0] = 'h000F; // intentionally low value for faster simulation time
    wstrb[0]   = 4'hF;
    axi_master_write(.address(`SM_PTP_QSFP0_SYSTEM_OFFSET+'h60),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

 //   wr_data[0] = 'h1f4; //100KHz
 //   wr_data[0] = 'h7d; //400KHz
    wr_data[0] = 'h000F; // intentionally low value for faster simulation time
    wstrb[0]   = 4'hF;
    axi_master_write(.address(`SM_PTP_QSFP0_SYSTEM_OFFSET+'h64),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

//    wr_data[0] = 'h28;
//    wr_data[0] = 'h3c;
    wr_data[0] = 'h1; // intentionally low value for faster simulation time
    wstrb[0]   = 4'hF;
    axi_master_write(.address(`SM_PTP_QSFP0_SYSTEM_OFFSET+'h68),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

// TBD - check for init done status 0x90 bit[0]

    wr_data[0] = 32'h0000_002b; //I2C CTRL
    wstrb[0]   = 4'hF;
    axi_master_write(.address(`SM_PTP_QSFP0_SYSTEM_OFFSET+'h48),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

    wr_data[0] = 32'h0000_00FF; //delay csr
    wstrb[0]   = 4'hF;
    axi_master_write(.address(`SM_PTP_QSFP0_SYSTEM_OFFSET+'h38),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

  endtask: init_sfp

  // ------------------------------
  task write_a0(
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] addr,
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data[]
  );
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] wr_data[];
    bit [`SVT_AXI_WSTRB_WIDTH-1:0] 	  wstrb [];

    wr_data = new[1];
    wstrb   = new[1];

    wr_data[0] = 'h2A0; // start A0
    wstrb[0]   = 4'hF;
    axi_master_write(.address(`SM_PTP_QSFP0_TFR_CMD),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

    wr_data[0] = addr; // write offset address
    wstrb[0]   = 4'hF;
    axi_master_write(.address(`SM_PTP_QSFP0_TFR_CMD),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

    wr_data[0] = {1'd1,data[0][7:0]}; // write data and stop
    wstrb[0]   = 4'hF;
    axi_master_write(.address(`SM_PTP_QSFP0_TFR_CMD),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

  endtask: write_a0


  // ------------------------------
  task write_a2(
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] addr,
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] data[]
  );
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] wr_data[];
    bit [`SVT_AXI_WSTRB_WIDTH-1:0] 	  wstrb [];

    wr_data = new[1];
    wstrb   = new[1];

    wr_data[0] = 'h2A2; // start A2
    wstrb[0]   = 4'hF;
    axi_master_write(.address(`SM_PTP_QSFP1_TFR_CMD),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

    wr_data[0] = addr; // write offset address
    wstrb[0]   = 4'hF;
    axi_master_write(.address(`SM_PTP_QSFP1_TFR_CMD),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

    wr_data[0] = {1'd1,data[0][7:0]}; // write data and stop
    wstrb[0]   = 4'hF;
    axi_master_write(.address(`SM_PTP_QSFP1_TFR_CMD),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

  endtask: write_a2
  
  // ------------------------------
  task read_a0(bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] addr, int rd_bytes = 1);
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] wr_data[];
    bit [`SVT_AXI_WSTRB_WIDTH-1:0] 	  wstrb [];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] rd_data [];

    wr_data = new[1];
    wstrb   = new[1];

    wr_data[0] = 'h2A0;
    wstrb[0]   = 4'hF;
    axi_master_write(.address(`SM_PTP_QSFP0_TFR_CMD),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

    wr_data[0] = addr;
    wstrb[0]   = 4'hF;
    axi_master_write(.address(`SM_PTP_QSFP0_TFR_CMD),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

    wr_data[0] = 'h2A1;
    wstrb[0]   = 4'hF;
    axi_master_write(.address(`SM_PTP_QSFP0_TFR_CMD),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

    if (rd_bytes > 1) begin
      repeat (rd_bytes-1) begin
        wr_data[0] = 'h000;
        wstrb[0]   = 4'hF;
        axi_master_write(.address(`SM_PTP_QSFP0_TFR_CMD),
                         .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                         .data(wr_data), .burst_length(1), .wstrb(wstrb));
      end
    end

    wr_data[0] = 'h100;
    wstrb[0]   = 4'hF;
    axi_master_write(.address(`SM_PTP_QSFP0_TFR_CMD),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

  endtask: read_a0
  
  // ------------------------------
  task read_a2(bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] addr, int rd_bytes = 1);
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] wr_data[];
    bit [`SVT_AXI_WSTRB_WIDTH-1:0] 	  wstrb [];
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] rd_data [];

    wr_data = new[1];
    wstrb   = new[1];

    wr_data[0] = 'h2A0;
    wstrb[0]   = 4'hF;
    axi_master_write(.address(`SM_PTP_QSFP1_TFR_CMD),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

    wr_data[0] = addr;
    wstrb[0]   = 4'hF;
    axi_master_write(.address(`SM_PTP_QSFP1_TFR_CMD),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

    wr_data[0] = 'h2A1;
    wstrb[0]   = 4'hF;
    axi_master_write(.address(`SM_PTP_QSFP1_TFR_CMD),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

    if (rd_bytes > 1) begin
      repeat (rd_bytes-1) begin
        wr_data[0] = 'h000;
        wstrb[0]   = 4'hF;
        axi_master_write(.address(`SM_PTP_QSFP1_TFR_CMD),
                         .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                         .data(wr_data), .burst_length(1), .wstrb(wstrb));
      end
    end

    wr_data[0] = 'h100;
    wstrb[0]   = 4'hF;
    axi_master_write(.address(`SM_PTP_QSFP1_TFR_CMD),
                     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                     .data(wr_data), .burst_length(1), .wstrb(wstrb));

  endtask: read_a2
endclass: sm_ptp_qsfp_basic_seq

`endif
