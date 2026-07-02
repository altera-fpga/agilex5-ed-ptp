//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//########################################################################
// Description:
// This is basic dma sequence whose handle is used in all sequences to enable
// dma ports and configure rspective parameters for the same

`ifndef SM_PTP_BASIC_DATA_PATH_SEQ__SV
`define SM_PTP_BASIC_DATA_PATH_SEQ__SV

class sm_ptp_basic_data_path_seq extends sm_ptp_basic_seq;

  rand int num_of_h2d_desc[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  rand int num_of_d2h_desc[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];

  rand bit [47:0] dma_sa[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  rand bit [47:0] dma_da[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];

  rand int h2d_pyld_len[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][];
  rand int d2h_pyld_len[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][];

  bit csr_cfg_done;
  rand bit h2d_en[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  rand bit d2h_en[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  rand bit h2d_poll_en[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  rand bit d2h_poll_en[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  rand int sw_owned_h2d[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][];
  rand int sw_owned_d2h[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][];

  // TODO
  // bit descr_irq_en[] -
  //                      for each of the descriptors that are configured
  //                      currently irq is 1 for all descriptors

  `uvm_object_utils(sm_ptp_basic_data_path_seq)
  // `uvm_object_utils_begin(sm_ptp_basic_data_path_seq)
  //   `uvm_field_int(h2d_poll_en, UVM_ALL_ON)
  //   `uvm_field_int(d2h_poll_en, UVM_ALL_ON)
  // `uvm_object_utils_end

  sm_ptp_msgdma_cfg_seq     q_csr_seq;

  sm_ptp_axi_slave_host_response_seq host_resp_seq;

  constraint dma_constraints {
    soft foreach (h2d_en[i,j]) h2d_en[i][j] == 0;
    soft foreach (d2h_en[i,j]) d2h_en[i][j] == 0;
    soft foreach (h2d_pyld_len[i,j]) h2d_pyld_len[i][j].size() == num_of_h2d_desc[i][j];
    soft foreach (d2h_pyld_len[i,j]) d2h_pyld_len[i][j].size() == num_of_d2h_desc[i][j];
    soft foreach (h2d_pyld_len[i,j,k]) h2d_pyld_len[i][j][k] inside {[64:1500]};
    soft foreach (d2h_pyld_len[i,j,k]) d2h_pyld_len[i][j][k] == 1500;
    soft foreach (num_of_h2d_desc[i,j]) num_of_h2d_desc[i][j] inside {[2:40]};
    soft foreach (num_of_d2h_desc[i,j]) num_of_d2h_desc[i][j] inside {[2:40]};
    soft (`SM_PTP_NUM_PORTS == 1) -> foreach (num_of_h2d_desc[1][i]) num_of_h2d_desc[1][i] == 0;
    soft (`SM_PTP_NUM_PORTS == 1) -> foreach (num_of_d2h_desc[1][i]) num_of_d2h_desc[1][i] == 0;
    foreach (sw_owned_h2d[i,j]) sw_owned_h2d[i][j].size() == num_of_h2d_desc[i][j];
    soft foreach (sw_owned_h2d[i,j,k]) sw_owned_h2d[i][j][k] inside {[0:16]};
    foreach (sw_owned_d2h[i,j]) sw_owned_d2h[i][j].size() == num_of_d2h_desc[i][j];
    soft foreach (sw_owned_d2h[i,j,k]) sw_owned_d2h[i][j][k] inside {[0:16]};
    soft foreach (dma_sa[i,j]) dma_sa[i][j] == 48'haaaa_aaaa_aaaa;
    soft foreach (dma_da[i,j]) dma_da[i][j] == 48'hdddd_dddd_dddd;
    foreach (num_of_h2d_desc[i,j]) solve num_of_h2d_desc[i][j] before sw_owned_h2d[i][j].size();
    foreach (num_of_d2h_desc[i,j]) solve num_of_d2h_desc[i][j] before sw_owned_d2h[i][j].size();
    foreach (h2d_pyld_len[i,j,k]) {
      solve num_of_h2d_desc[i][j] before h2d_pyld_len[i][j].size();
      solve h2d_pyld_len[i][j].size() before h2d_pyld_len[i][j][k];
    }
    foreach (d2h_pyld_len[i,j,k]) {
      solve num_of_d2h_desc[i][j] before d2h_pyld_len[i][j].size();
      solve d2h_pyld_len[i][j].size() before d2h_pyld_len[i][j][k];
    }
  }

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  function new(name = "sm_ptp_basic_data_path_seq");
    super.new(name);
  endfunction: new

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task body();
    bit rsp_seq_h2d_en[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
    bit rsp_seq_d2h_en[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
    bit rsp_seq_h2d_poll_en[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
    bit rsp_seq_d2h_poll_en[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];

    csr_cfg_done = 0;
    for (bit [1:0] port; port<`SM_PTP_NUM_PORTS; port++) begin
      for (bit [1:0] chan; chan<`SM_MSGDMA_NUM_CHANN_PER_PORT; chan++) begin
        rsp_seq_h2d_en[port][chan] = h2d_en[port][chan];
        rsp_seq_d2h_en[port][chan] = d2h_en[port][chan];
        rsp_seq_h2d_poll_en[port][chan] = h2d_poll_en[port][chan];
        rsp_seq_d2h_poll_en[port][chan] = d2h_poll_en[port][chan];
      end
    end

    fork
      begin
        foreach (h2d_en[i,j])
          `uvm_info(get_full_name(),
                    $sformatf("h2d_en[%0d][%0d] %b, d2h_en[%0d][%0d] %b, descr poll en, h2d[%0d][%0d] %0d, d2h[%0d][%0d] %0d",
                              i, j, h2d_en[i][j], i, j, d2h_en[i][j], i, j, h2d_poll_en[i][j], i, j, d2h_poll_en[i][j]),
                    UVM_LOW)
        `uvm_do_with(q_csr_seq, {
                      foreach (h2d_ch_en[i,j]) h2d_ch_en[i][j] == h2d_en[i][j];
                      foreach (d2h_ch_en[i,j]) d2h_ch_en[i][j] == d2h_en[i][j];
                      foreach (h2d_descr_poll_en[i,j]) h2d_descr_poll_en[i][j] == h2d_poll_en[i][j];
                      foreach (d2h_descr_poll_en[i,j]) d2h_descr_poll_en[i][j] == d2h_poll_en[i][j];
                    })
        `uvm_info(get_full_name(), "desc fetch sequence done", UVM_LOW)
        csr_cfg_done = 1;
      end
      begin
        foreach (h2d_poll_en[i,j])
          `uvm_info(get_full_name(),
                    $sformatf("descr poll en, h2d[%0d][%0d] %0d, d2h[%0d][%0d] %0d",
                              i, j, h2d_poll_en[i][j], i, j, d2h_poll_en[i][j]),
                    UVM_LOW)
        foreach (sw_owned_h2d[i,j,k])
          `uvm_info(get_full_name(), 
                    $sformatf("sw_owned_h2d[%0d][%0d][%0d]=%0d", i, j, k, sw_owned_h2d[i][j][k]),
                    UVM_LOW)
        foreach (sw_owned_d2h[i,j,k])
          `uvm_info(get_full_name(), 
                    $sformatf("sw_owned_d2h[%0d][%0d][%0d]=%0d", i, j, k, sw_owned_d2h[i][j][k]),
                    UVM_LOW)
        foreach (h2d_pyld_len[i,j,k])
          `uvm_info(get_full_name(),
                    $sformatf("cfg h2d_pyld_len[%0d][%0d][%0d]=%0d", i, j, k, h2d_pyld_len[i][j][k]),
                    UVM_DEBUG)
        foreach (d2h_pyld_len[i,j,k])
          `uvm_info(get_full_name(),
                    $sformatf("cfg d2h_pyld_len[%0d][%0d][%0d]=%0d", i, j, k, d2h_pyld_len[i][j][k]),
                    UVM_DEBUG)
        `uvm_do_on_with (host_resp_seq, p_sequencer.slave_sequencer[0], {
                        foreach (h2d_ch_en[i,j]) h2d_ch_en[i][j] == rsp_seq_h2d_en[i][j];
                        foreach (d2h_ch_en[i,j]) d2h_ch_en[i][j] == rsp_seq_d2h_en[i][j];
                        foreach (num_of_h2d_desc[i,j]) 
                                h2d_max_desc[i][j] == num_of_h2d_desc[i][j];
                        foreach (num_of_d2h_desc[i,j]) 
                                d2h_max_desc[i][j] == num_of_d2h_desc[i][j];
                        foreach (h2d_pyld_len[i,j,k]) 
                          h2d_desc_length[i][j][k] == h2d_pyld_len[i][j][k];
                        foreach (d2h_pyld_len[i,j,k])
                          d2h_desc_length[i][j][k] == d2h_pyld_len[i][j][k];
                        foreach (dma_da[i,j])  h2d_da[i][j]  == dma_da[i][j];
                        foreach (dma_sa[i,j])  h2d_sa[i][j]  == dma_sa[i][j];
                        h2d_eth[0][0] == 'h887F;     
                        h2d_eth[0][1] == 'h0800;     
                        h2d_eth[1][0] == 'h887F;     
                        h2d_eth[1][1] == 'h0800;     
                        resp_time_in_ns == 65000;
                        foreach (rsp_seq_h2d_poll_en[i,j])
                                h2d_descr_poll_en[i][j] == rsp_seq_h2d_poll_en[i][j];
                        foreach (rsp_seq_d2h_poll_en[i,j])
                                d2h_descr_poll_en[i][j] == rsp_seq_d2h_poll_en[i][j];
                        foreach (h2d_sw_owned[i,j,k])
                                h2d_sw_owned[i][j][k] == sw_owned_h2d[i][j][k];
                        foreach (d2h_sw_owned[i,j,k])
                                d2h_sw_owned[i][j][k] == sw_owned_d2h[i][j][k];
                        })
        `uvm_info(get_full_name(), "slave respons sequence done", UVM_LOW)
      end
    
      wait (tb_top.all_dma_desc_done == 1) begin
        bit chk_poll_en;
        for (bit [1:0] port=0; port<`SM_PTP_NUM_PORTS; port++)
          for (bit [1:0] chan=0; chan<`SM_MSGDMA_NUM_CHANN_PER_PORT; chan++)
            if (h2d_poll_en[port][chan] || d2h_poll_en[port][chan]) begin
              chk_poll_en = 1;
              break;
            end

        if (chk_poll_en) begin
            `uvm_do_with(q_csr_seq, {
                          foreach (h2d_ch_en[i,j]) h2d_ch_en[i][j] == h2d_en[i][j];
                          foreach (d2h_ch_en[i,j]) d2h_ch_en[i][j] == d2h_en[i][j];
                          foreach (h2d_descr_poll_en[i,j]) h2d_descr_poll_en[i][j] == 0;
                          foreach (d2h_descr_poll_en[i,j]) d2h_descr_poll_en[i][j] == 0;
                        })
        end
        #500ns; // to allow any stale requests to be completed by host resp seq
        tb_top.end_response_seq = 1;
      end
    join
    `uvm_info(get_full_name(), "Body exiting...", UVM_LOW)
  endtask: body

endclass: sm_ptp_basic_data_path_seq

`endif // SM_PTP_BASIC_DATA_PATH_SEQ__SV
