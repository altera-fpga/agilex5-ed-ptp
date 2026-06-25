
`ifndef SM_PTP_DATA_PATH_MID_SIM_ETH_RST_SEQ__SV
`define SM_PTP_DATA_PATH_MID_SIM_ETH_RST_SEQ__SV

class sm_ptp_data_path_mid_sim_eth_rst_seq extends sm_ptp_basic_seq;

  rand bit [1:0] cfg_h2d = 2'b10;
  rand int       num_of_h2d0_desc = 2;
  rand int       num_of_h2d1_desc = 2;
  rand int       num_of_d2h0_desc = 2;
  rand int       num_of_d2h1_desc = 2;
  rand bit[15:0] ins_ptr_h2d0_q = 2;
  rand bit[15:0] ins_ptr_h2d1_q = 2;
  rand bit[15:0] ins_ptr_d2h0_q = 2;
  rand bit[15:0] ins_ptr_d2h1_q = 2;

  // TODO
  // bit descr_irq_en[] -
  //                      for each of the descriptors that are configured
  //                      currently irq is 1 for all descriptors

  `uvm_object_utils_begin(sm_ptp_data_path_mid_sim_eth_rst_seq)
    `uvm_field_int(cfg_h2d, UVM_ALL_ON)
  `uvm_object_utils_end

  sm_ptp_initiate_desc_fetch_seq     q_csr_seq;

  sm_ptp_axi_slave_host_response_seq host_resp_seq;

  constraint valid_num_of_descriptors_n_q_ptr {
    num_of_h2d0_desc >= 2;
    num_of_h2d0_desc <= 128;
    num_of_h2d1_desc >= 2;
    num_of_h2d1_desc <= 128;
    num_of_d2h0_desc >= 2;
    num_of_d2h0_desc <= 128;
    num_of_d2h1_desc >= 2;
    num_of_d2h1_desc <= 128;

    ins_ptr_h2d0_q <= num_of_h2d0_desc;
    ins_ptr_h2d1_q <= num_of_h2d1_desc;
    ins_ptr_d2h0_q <= num_of_d2h0_desc;
    ins_ptr_d2h1_q <= num_of_d2h1_desc;

    solve num_of_h2d0_desc before ins_ptr_h2d0_q;
    solve num_of_h2d1_desc before ins_ptr_h2d1_q;
    solve num_of_d2h0_desc before ins_ptr_d2h0_q;
    solve num_of_d2h1_desc before ins_ptr_d2h1_q;
  }

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  function new(name = "sm_ptp_data_path_mid_sim_eth_rst_seq");
    super.new(name);
  endfunction: new

  // ----------------------------------------------------------------------
  // ----------------------------------------------------------------------
  task body();

    super.body();

    `uvm_info(get_full_name(),
              $sformatf({"data path sequence vars are:\n",
                         "cfg_h2d = %b\n",
                         "num_of_h2d0_desc = %0d\n",
                         "num_of_h2d1_desc = %0d\n",
                         "num_of_d2h0_desc = %0d\n",
                         "num_of_d2h1_desc = %0d\n",
                         "ins_ptr_h2d0_q  = %0d\n",
                         "ins_ptr_h2d1_q  = %0d\n",
                         "ins_ptr_d2h0_q  = %0d\n",
                         "ins_ptr_d2h1_q  = %0d\n"},
                         cfg_h2d,
                         num_of_h2d0_desc, num_of_h2d1_desc,
                         num_of_d2h0_desc, num_of_d2h1_desc,
                         ins_ptr_h2d0_q, ins_ptr_h2d1_q,
                         ins_ptr_d2h0_q, ins_ptr_d2h1_q
                       ),
              UVM_LOW)

    fork
      begin
        bit [`SVT_AXI_MAX_DATA_WIDTH-1:0] reg_data[];
        bit [`SVT_AXI_WSTRB_WIDTH-1:0] 	  wstrb [];

        `uvm_create(q_csr_seq)
          q_csr_seq.cfg_h2d = 2'b00;
          q_csr_seq.cfg_d2h = 2'b00;

          if (cfg_h2d[0] == 1) begin
            q_csr_seq.cfg_h2d[0] = 1'b1;
            if (port_lvl_loopbk == 1)
              q_csr_seq.cfg_d2h[0] = 1'b1;
            else
              q_csr_seq.cfg_d2h[1] = 1'b1;
          end
          if (cfg_h2d[1] == 1) begin
            q_csr_seq.cfg_h2d[1] = 1'b1;
            if (port_lvl_loopbk == 1)
              q_csr_seq.cfg_d2h[1] = 1'b1;
            else
              q_csr_seq.cfg_d2h[0] = 1'b1;
          end
          `uvm_info(get_full_name(),
                    $sformatf(" cfg_h2d = %b, cfg_d2h = %b",
                              q_csr_seq.cfg_h2d, q_csr_seq.cfg_d2h),
                    UVM_LOW)

          q_csr_seq.num_of_h2d_desc[0] = num_of_h2d0_desc;
          q_csr_seq.num_of_h2d_desc[1] = num_of_h2d1_desc;
          q_csr_seq.num_of_d2h_desc[0] = num_of_d2h0_desc;
          q_csr_seq.num_of_d2h_desc[1] = num_of_d2h1_desc;

          q_csr_seq.ins_ptr_h2d_q[0] = ins_ptr_h2d0_q;
          q_csr_seq.ins_ptr_h2d_q[1] = ins_ptr_h2d1_q;
          q_csr_seq.ins_ptr_d2h_q[0] = ins_ptr_d2h0_q;
          q_csr_seq.ins_ptr_d2h_q[1] = ins_ptr_d2h1_q;

        `uvm_send(q_csr_seq)

        #10ns;
        reg_data = new[1];
        wstrb    = new[1];

        reg_data[0] = 0;
        reg_data[0][5:0] = 5'h1;
        reg_data[0][3] = 0;
        wstrb[0] = 'hf;

        axi_master_write(
                .address('h4020_0000),
                .burst_sz(svt_axi_transaction::BURST_SIZE_32BIT),
                .data(reg_data),
                .burst_length(1),
                .wstrb(wstrb)
        );
      end
      begin
        `uvm_do_on(host_resp_seq, p_sequencer.slave_sequencer[0])
      end
    join
  endtask: body

endclass: sm_ptp_data_path_mid_sim_eth_rst_seq

`endif // SM_PTP_DATA_PATH_MID_SIM_ETH_RST_SEQ__SV
