//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//#########################################################################

`ifndef SM_PTP_ALL_PORTS_MID_SIM_RST_SEQ__SV
`define SM_PTP_ALL_PORTS_MID_SIM_RST_SEQ__SV

class sm_ptp_mid_sim_sys_rst_seq extends sm_ptp_basic_seq;

  `uvm_object_utils(sm_ptp_mid_sim_sys_rst_seq)

  sm_ptp_basic_data_path_seq     seq_h;

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  function new(name = "sm_ptp_mid_sim_sys_rst_seq");
    super.new(name);
  endfunction: new

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task body();
    bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] key [3];
    bit [47:0] sa [`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
    bit [47:0] da [`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];

    super.body();

    `uvm_info(get_full_name(), "config rules for user client 0", UVM_LOW)
    key[0] = 'hdddd_dddd;
    key[1] = 'haaaa_dddd;
    key[2] = 'haaaa_aaaa;
`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
    configure_tcam0(1, key, 0);
`else
    configure_tcam1(1, key, 0);
`endif
    da[0][0] = {key[1][15:0], key[0][31:0]};
    sa[0][0] = {key[2][31:0], key[1][31:16]};
    key[0] = 'hcccc_cccc;
    key[1] = 'hbbbb_cccc;
    key[2] = 'hbbbb_bbbb;
`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
    configure_tcam0(2, key, 1);
`else
    configure_tcam1(2, key, 1);
`endif
    da[0][1] = {key[1][15:0], key[0][31:0]};
    sa[0][1] = {key[2][31:0], key[1][31:16]};

    fork
      begin: resp_en
        `uvm_info(get_full_name(), "config dma port 0 to start traffic", UVM_LOW)
        `uvm_do_with(seq_h, {
                             h2d_en[0][0] == 1;
                             h2d_en[0][1] == 1;
                             h2d_en[1][0] == 0;
                             h2d_en[1][1] == 0;
`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
                             d2h_en[0][0] == 1;
                             d2h_en[0][1] == 1;
                             d2h_en[1][0] == 0;
                             d2h_en[1][1] == 0;
`else
                             d2h_en[0][0] == 0;
                             d2h_en[0][1] == 0;
                             d2h_en[1][0] == 1;
                             d2h_en[1][1] == 1;
`endif
                             foreach (num_of_h2d_desc[i,j]) num_of_h2d_desc[i][j] == 4;
                             foreach (num_of_d2h_desc[i,j]) num_of_d2h_desc[i][j] == 4;
                             foreach (h2d_pyld_len[i,j,k])
                               h2d_pyld_len[i][j][k] == 90;
                             foreach (d2h_pyld_len[i,j,k])
                                 d2h_pyld_len[i][j][k] == 90;
                             foreach (h2d_poll_en[i,j]) h2d_poll_en[i][j] == 0;
                             foreach (d2h_poll_en[i,j]) d2h_poll_en[i][j] == 0;
                             foreach (dma_da[i,j]) dma_da[i][j] == da[i][j];
                             foreach (dma_sa[i,j]) dma_sa[i][j] == sa[i][j];
                            })
        `uvm_info(get_full_name(), "config done dma port 0 to start traffic", UVM_LOW)
      end
      begin: apply_rst
        bit [`SVT_AXI_MAX_DATA_WIDTH-1:0]        data [];
        bit [`SVT_AXI_MAX_DATA_WIDTH-1:0]        rd_data [];
        bit [`SVT_AXI_WSTRB_WIDTH-1:0] 	         wstrb [];

        wait (seq_h.host_resp_seq !== null);
        wait (seq_h.host_resp_seq.d2h_desc_wrbk_cntr[1][0] !== 0);
        data = new[1];
        wstrb = new[1];

        // apply rst on p0 rx pcs
        data[0] = 0;
        data[0][2] = 1;
        wstrb[0] = 'hf;
        axi_master_write(
            .address(`SM_PTP_HSSI_CSR_PORT0_SOFT_IP_BASE+'h8), .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .burst_length(1), .data(data), .wstrb(wstrb)
        );

        data[0] = 0;
        data[0] = {14'd0, 2'b11, 12'd0, 4'b1101};
        wstrb[0] = 'hf;
        axi_master_write(
            .address(`SM_PTP_USER_CSR_CTRL_REG), .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .burst_length(1), .data(data), .wstrb(wstrb)
        );

        // wait for RX PCS ready to be de-assserted
        // while (rd_data[0][0] == 1) begin
        //   axi_master_read (
        //     .address(`SM_PTP_USER_CSR_STATUS_REG),
        //     .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT), .burst_length(1), .data(rd_data)
        //   );
        // end

        axi_master_read(
          .address(`SM_PTP_USER_CSR_CTRL_REG),
          .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT), .burst_length(1), .data(rd_data)
        );
        foreach (rd_data[i])$display($time,"user csr status reg data[%0d] = %0h", i, rd_data[i]);

        // #100ns;
        // $finish();

        /*
        // apply soft reset on DMA Rx
        data[0] = 0;
        data[0][2] = 1'b1;
        wstrb[0] = 'hf;
        axi_master_write(
            .address(`SM_PTP_SSGDMA_CSR_ADDR+'h80), .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
            .burst_length(1), .data(data), .wstrb(wstrb)
        );

        // wait for DMA soft reset to complete
        while (rd_data[0][2] == 1) begin
          axi_master_read(
            .address(`SM_PTP_SSGDMA_CSR_ADDR+'h80),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT), .burst_length(1), .data(rd_data)
          );
        end

        // wait for PCS ready to be assserted
        while (rd_data[0][0] == 0) begin
          axi_master_read(
            .address(`SM_PTP_USER_CSR_STATUS_REG),
            .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT), .burst_length(1), .data(rd_data)
          );
        end*/
      end
    join

    #100us;

    // wait_for_pkts_to_complete(0, 100);
    `uvm_info(get_full_name(), "Read pkt client perf stats", UVM_LOW)
    //read_pkt_client0_perf_stats();
    //match_sop_eop(0);
    // poll_eth_stats();
  endtask: body

endclass: sm_ptp_mid_sim_sys_rst_seq

`endif // SM_PTP_ALL_PORTS_MID_SIM_RST_SEQ__SV
