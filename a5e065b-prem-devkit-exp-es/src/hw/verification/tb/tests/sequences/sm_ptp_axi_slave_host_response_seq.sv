//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//########################################################################
//#AXI Slave response sequence
//#This class extends from the "svt_axi_slave_base_sequence" used to provide slave response 
//#to the Slave[0] present in the System agent.
//#This class acts as Host that will return descriptor/data to prefetcher/agent through AXI4 READ channel 
//#based on the AXI4 packet received 
//########################################################################
`ifndef SM_PTP_AXI_SLAVE_MSGDMA_HOST_RESPONSE_SEQ__SV
`define SM_PTP_AXI_SLAVE_MSGDMA_HOST_RESPONSE_SEQ__SV

/**
==========================================================================================
IMPORTS
==========================================================================================
*/
import axi_base_sequence_pkg::*;

parameter WAIT_FOR_SOC_NEXT_TRANSACTION_TIMEOUT_NS = 5000000; // 5ms default;
/**
==========================================================================================
CLASS
==========================================================================================
*/
class sm_ptp_axi_slave_host_response_seq extends svt_axi_slave_base_sequence;

  rand bit h2d_ch_en [`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  rand bit d2h_ch_en [`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  rand bit h2d_descr_poll_en[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  rand bit d2h_descr_poll_en[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  rand int h2d_sw_owned[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][];
  rand int d2h_sw_owned[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][];
  svt_axi_slave_transaction req_resp;
  
  /** UVM Object Utility macro */
  `uvm_object_utils_begin(sm_ptp_axi_slave_host_response_seq)
    // `uvm_field_int(h2d_descr_poll_en, UVM_ALL_ON)
    // `uvm_field_int(d2h_descr_poll_en, UVM_ALL_ON)
    // `uvm_field_int(sw_owned, UVM_ALL_ON)
  `uvm_object_utils_end
  // TBD
  `uvm_declare_p_sequencer(svt_axi_slave_sequencer)
  
  // ---------------
  // Instantiations
  // ---------------
  // struct packed from "axi_base_sequence_pkg.sv"
  e_address_type  address_type;
  e_agent_type    agent_type;
  e_agent_port    agent_port;
  e_agent_channel agent_chan;
  int desc_size = 3; 

  // Typedef struct packed from "axi_base_sequence_pkg".
  t_h2d_st_descriptor	h2d_st_data_desc_1;
  eth_pkt             eth_pkt_1;
  // ----------
  // Variables
  // ----------
  int burst_size = 0; 
  int burst_size_bits = 0; 
  int burst_size_bytes = 0; 
  int burst_length = 0; 
  int up_burst_length = 0; 

  rand bit [15:0] h2d_max_desc[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  rand bit [15:0] d2h_max_desc[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  rand bit [15:0] h2d_desc_length[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][];
  rand bit [15:0] d2h_desc_length[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][];
  rand bit [47:0] h2d_da[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT]; 
  rand bit [47:0] h2d_sa[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT]; 
  rand bit [15:0] h2d_eth[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  rand bit [31:0] resp_time_in_ns;

  // Stores the number of descriptors requested through AR Channel.
  int num_of_desc_requested_per_arlen = 0;
  int num_of_desc_requested_per_awlen = 0;
  
  // Counter for the number of descriptors fetched------------
  int desc_offset_per_memrd_pkt_request = 0;
  int desc_offset_per_memwr_pkt_request = 0;
  
  // Queue to store router_tdata & router_tkeep_queue
  bit [511:0] rdesc0_queue[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][$];
  bit [511:0] wdesc0_queue[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][$];

  bit [255:0] rdata_out[];
  bit [255:0] poll_data;
  bit [511:0] rdesc_pop;
  bit [511:0] wdesc_pop;
  bit [511:0] data_pop[5:0];
  
  int soc_timer_counter_ns 	= 0; 
  int host_read_pkt_received = 0; 
  int host_write_pkt_received = 0; 
  logic  [31:0] ctrl;
  logic  [31:0] next_descptr;
  logic  [31:0] rd_addr,wr_addr;
  logic  [47:0] da,sa;
  logic  [15:0] len;
  int  seq_num; 
  int  start;
  int h2d_desc_wrbk_cntr[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  int d2h_desc_wrbk_cntr[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  bit end_sequence;

  bit [7:0] rd_buffer[*];
  int rd_buffer_pointer;
  int h2d_desc_cntr[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  int d2h_desc_cntr[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  int sw_owned_h2d_cntr[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  int sw_owned_d2h_cntr[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];

  bit [63:0] h2d_desc_ptr[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][];
  bit [63:0] d2h_desc_ptr[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT][];
  bit ignore_redundant_addr;
  bit [63:0] prev_h2d_addr[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  bit [63:0] prev_d2h_addr[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];

  bit [1:0]  d2h_wrbk_descr_repeat[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  bit [63:0] d2h_wrbk_descr_nxt_exp_addr[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  bit [1:0]  h2d_wrbk_descr_repeat[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];
  bit [63:0] h2d_wrbk_descr_nxt_exp_addr[`SM_PTP_MAX_PORTS][`SM_MSGDMA_MAX_CHANN_PER_PORT];

  // ==========================================================================================
  // CONSTRUCTOR
  // ==========================================================================================
  function new(string name="sm_ptp_axi_slave_host_response_seq");
    super.new(name);
    foreach (h2d_desc_wrbk_cntr[i,j]) h2d_desc_wrbk_cntr[i][j] = 0;
    foreach (d2h_desc_wrbk_cntr[i,j]) d2h_desc_wrbk_cntr[i][j] = 0;
    end_sequence = 0;
  endfunction

  // ==========================================================================================
  // CONSTRAINTS
  // ==========================================================================================
  constraint dma_c {
    foreach (h2d_desc_length[i,j]) h2d_desc_length[i][j].size() == h2d_max_desc[i][j];
    foreach (d2h_desc_length[i,j]) d2h_desc_length[i][j].size() == d2h_max_desc[i][j];
    soft foreach (h2d_desc_length[i,j,k]) h2d_desc_length[i][j][k] inside  {[64:1500]};
    soft foreach (d2h_desc_length[i,j,k]) d2h_desc_length[i][j][k] == 1500;
    soft foreach (h2d_max_desc[i,j]) h2d_max_desc[i][j] inside {[2:40]};
    soft foreach (d2h_max_desc[i,j]) d2h_max_desc[i][j] inside {[2:40]};
    foreach (h2d_sw_owned[i,j]) h2d_sw_owned[i][j].size() == h2d_max_desc[i][j];
    soft foreach (h2d_sw_owned[i,j,k]) h2d_sw_owned[i][j][k] inside {[0:16]};
    foreach (d2h_sw_owned[i,j]) d2h_sw_owned[i][j].size() == d2h_max_desc[i][j];
    soft foreach (d2h_sw_owned[i,j,k]) d2h_sw_owned[i][j][k] inside {[0:16]};
    foreach (h2d_max_desc[i,j]) solve h2d_max_desc[i][j] before h2d_sw_owned[i][j].size();
    foreach (d2h_max_desc[i,j]) solve d2h_max_desc[i][j] before d2h_sw_owned[i][j].size();
    foreach (h2d_desc_length[i,j,k]) {
      solve h2d_max_desc[i][j] before h2d_desc_length[i][j].size();
      solve h2d_desc_length[i][j].size() before h2d_desc_length[i][j][k];
    }
    foreach (d2h_desc_length[i,j,k]) {
      solve d2h_max_desc[i][j] before d2h_desc_length[i][j].size();
      solve d2h_desc_length[i][j].size() before d2h_desc_length[i][j][k];
    }
  }

  // ==========================================================================================
  // TEST SEQUENCE
  // ==========================================================================================
  virtual task body();
    bit wait_for_timer_block_to_kill_seq = 0;
    svt_configuration get_cfg;
    
    super.body();
    `uvm_info("body", "Entered ...", UVM_NONE)
    // ---------------Print cfg values-------------- //
    for (int i=0; i<`SM_PTP_NUM_PORTS; i++) begin
      for (int j=0; j<`SM_MSGDMA_NUM_CHANN_PER_PORT; j++) begin
        `uvm_info(get_full_name(),
                  $sformatf({"received values from sequence",
                             "\nh2d_max_desc[%0d][%0d] %0d",
                             "\nh2d_da[%0d][%0d] %0h, h2d_sa[%0d][%0d] %0h,",
                             "\nh2d_descr_poll_en[%0d][%0d] %0d"},
                            i, j, h2d_max_desc[i][j], i, j, h2d_da[i][j],
                            i, j, h2d_sa[i][j], i, j, h2d_descr_poll_en[i][j]),
                  UVM_NONE)
      end
    end
    foreach (h2d_desc_length[i,j,k])
      `uvm_info(get_full_name(),
                $sformatf("h2d_desc_length[%0d][%0d][%0d] %0d", i, j, k, h2d_desc_length[i][j][k]),
                UVM_NONE)
    for (int i=0; i<`SM_PTP_NUM_PORTS; i++) begin
      for (int j=0; j<`SM_MSGDMA_NUM_CHANN_PER_PORT; j++) begin
        `uvm_info(get_full_name(),
                  $sformatf({"received values from sequence",
                             "\nd2h_max_desc[%0d][%0d] %0d\nd2h_descr_poll_en[%0d][%0d] %0d"},
                            i, j, d2h_max_desc[i][j], i, j, d2h_descr_poll_en[i][j]),
                  UVM_NONE)
      end
    end
    foreach (d2h_desc_length[i,j,k])
      `uvm_info(get_full_name(),
                $sformatf("d2h_desc_length[%0d][%0d][%0d] %0d", i, j, k, d2h_desc_length[i][j][k]),
                UVM_NONE)
    foreach (h2d_sw_owned[i,j])
      if (h2d_descr_poll_en[i][j] == 1)
        foreach (h2d_sw_owned[i][j][k])
          `uvm_info(get_full_name(),
                    $sformatf("received_value from sequence: h2d_sw_owned[%0d][%0d][%0d]=%0d", i, j, k, h2d_sw_owned[i][j][k]),
                    UVM_NONE)
    foreach (d2h_sw_owned[i,j])
      if (d2h_descr_poll_en[i][j] == 1)
        foreach (d2h_sw_owned[i][j][k])
          `uvm_info(get_full_name(),
                    $sformatf("received_value from sequence: d2h_sw_owned[%0d][%0d][%0d]=%0d", i, j, k, d2h_sw_owned[i][j][k]),
                    UVM_NONE)
    // ---------------Print cfg values-------------- //
    
    foreach (h2d_desc_ptr[i,j]) h2d_desc_ptr[i][j] = new[h2d_max_desc[i][j]+1];
    foreach (d2h_desc_ptr[i,j]) d2h_desc_ptr[i][j] = new[d2h_max_desc[i][j]+1];

    p_sequencer.get_cfg(get_cfg);
    if (!$cast(cfg, get_cfg)) begin
      `uvm_fatal("body", "Unable to $cast the configuration to a svt_axi_port_configuration class");
    end
    
    // consumes responses sent by driver
    soc_timer_counter_ns = 0;

    for (bit [1:0] port_num=0; port_num<`SM_PTP_NUM_PORTS; port_num++)
      for (bit [1:0] ch_num=0; ch_num<`SM_MSGDMA_NUM_CHANN_PER_PORT; ch_num++) 
        load_descriptor_queue(port_num, ch_num);

    fork 
      begin: timer
        while (soc_timer_counter_ns < resp_time_in_ns ) begin
          #1ns;   
          if (((host_read_pkt_received == 1) || (host_write_pkt_received == 1)) && (end_sequence == 0)) begin
            soc_timer_counter_ns = 0;
            `uvm_info(get_full_name(), "reset soc_timer_counter_ns", UVM_NONE);
          end else if ((end_sequence == 1) && (tb_top.end_response_seq == 1)) begin
            `uvm_info(get_full_name(), "call to end sequence", UVM_NONE)
            soc_timer_counter_ns = resp_time_in_ns;
          end else begin
            soc_timer_counter_ns += 1;
          end
        end
        `uvm_info(get_type_name(), "Timer stops waiting for subsequent memory read request packets.", UVM_NONE)
        disable main_body;
        disable wait_for_descr_finish;
        disable wait_for_dma_req;
      end 

      begin: main_body
        forever begin
          //Get the response request from the slave sequencer. The response request is
          //provided to the slave sequencer by the slave port monitor, through
          //TLM port.

          `uvm_info(get_full_name( ), "peek in the sequencer port for request packet", UVM_NONE)
          p_sequencer.response_request_port.peek(req_resp);
          $cast(req,req_resp);
          `uvm_info("transaction to slave", $sformatf("xact_IN:\n%s", req_resp.sprint()), UVM_LOW)

          //----------------------------------------------------------------------------------
          // Host write respond 
          //----------------------------------------------------------------------------------
          if (req_resp.xact_type == svt_axi_slave_transaction::WRITE)begin
             `uvm_info(get_full_name(),
                       $sformatf("REQ IS FOR WRBK DESC/DMA DATA WRITE"),
                       UVM_LOW)
            host_write_pkt_received = 1;
            respond_to_write_req();
            $display (" WRITE TXN ENDS");
          end

          //----------------------------------------------------------------------------------
          // Host read respond 
          //---------------------------------------------------------------------------------- 
          if (req_resp.xact_type == svt_axi_slave_transaction::READ)begin
             `uvm_info(get_full_name(),
                       $sformatf("REQ IS FOR DESC/DMA DATA READ"),
                       UVM_LOW)
            `uvm_info(get_full_name(), "Received READ packet", UVM_NONE)
            host_read_pkt_received = 1;
            respond_to_read_req();
          end //end of READ transaction 
        end
      end 

      begin: wait_for_descr_finish
        if (h2d_ch_en[0][0] == 1) begin
`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
          `SM_PTP_HOST_WAIT_FOR_ALL_DESCR_WRBKS(0, 0, 0, 0)
`else
          `SM_PTP_HOST_WAIT_FOR_ALL_DESCR_WRBKS(0, 0, 1, 0)
`endif
        end
        if (`SM_MSGDMA_NUM_CHANN_PER_PORT > 1) begin
          if (h2d_ch_en[0][1] == 1) begin
`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
            `SM_PTP_HOST_WAIT_FOR_ALL_DESCR_WRBKS(0, 1, 0, 1)
`else
            `SM_PTP_HOST_WAIT_FOR_ALL_DESCR_WRBKS(0, 1, 1, 1)
`endif
          end
        end
        if (`SM_PTP_NUM_PORTS > 1) begin
          if (h2d_ch_en[1][0] == 1) begin
`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
            `SM_PTP_HOST_WAIT_FOR_ALL_DESCR_WRBKS(1, 0, 1, 0)
`else
            `SM_PTP_HOST_WAIT_FOR_ALL_DESCR_WRBKS(1, 0, 0, 0)
`endif
          end
          if (`SM_MSGDMA_NUM_CHANN_PER_PORT > 1) begin
            if (h2d_ch_en[1][1] == 1) begin
`ifdef SM_PTP_PORT_LEVEL_LOOPBACK
              `SM_PTP_HOST_WAIT_FOR_ALL_DESCR_WRBKS(1, 1, 1, 1)
`else
              `SM_PTP_HOST_WAIT_FOR_ALL_DESCR_WRBKS(1, 1, 0, 1)
`endif
            end
          end
        end

        end_sequence = 1;
        tb_top.all_dma_desc_done = 1;
        `uvm_info(get_full_name(),
                  "all D2H descriptors are serviced",
                  UVM_NONE)
        wait (wait_for_timer_block_to_kill_seq == 1);
      end

      begin: wait_for_dma_req
        forever begin
          wait ((host_write_pkt_received == 1) || (host_read_pkt_received == 1));
          #1ns;
          if (host_read_pkt_received == 1) host_read_pkt_received = 0; 
          if (host_write_pkt_received == 1) host_write_pkt_received = 0;
        end
      end
    join_any
    `uvm_info("Exiting_body", "sm_ptp_axi_slave_host_response_seq...!! ", UVM_NONE)
  endtask: body 

  //----------------------------------------------------------------------------------
  // Host write respond 
  //----------------------------------------------------------------------------------
  virtual task respond_to_write_req();
    bit [511:0] wr_data[];
    bit [63:0] matched_element[$];

    `uvm_info(get_full_name(), "Received WRITE packet", UVM_LOW)
    $cast(address_type,req_resp.addr[30:28]); 

    $cast(agent_type,req_resp.addr[27]);
    $cast(agent_chan,req_resp.addr[26:25]);
    $cast(agent_port,req_resp.addr[24:23]);
    $cast(burst_length,req_resp.burst_length);

    if (address_type == DMA_DATA) begin
      `uvm_info(get_full_name(),
                "Address type received for WR DMA DATA",
                UVM_NONE)
    end else if (address_type == DESCR) begin   
      `uvm_info(get_full_name(),
                "Address type received for DESC WR BACK",
                UVM_NONE)
    end
    `uvm_info(get_full_name(),
              $sformatf("\nagent_type : %0d\nagent_port : %0d\nagent_chan : %0d\nburst_length : %0d",
                        agent_type, agent_port, agent_chan, burst_length),
              UVM_HIGH)

    if (address_type == DESCR) begin
      if (agent_type == H2D_ST_AGENT) begin
        `uvm_info(get_full_name(),
                  $sformatf("pre-match: prev_h2d_addr[%0d][%0d] = %0h, req_resp.addr %0h",
                             agent_port, agent_chan, prev_h2d_addr[agent_port][agent_chan], req_resp.addr),
                  UVM_DEBUG)

        matched_element = h2d_desc_ptr[agent_port][agent_chan].find_first with (item == req_resp.addr);
        `uvm_info(get_full_name(),
                  $sformatf("matched_element[0]=%0h, req_resp.addr %0h",
                             matched_element[0], req_resp.addr),
                  UVM_DEBUG)

        if (h2d_wrbk_descr_repeat[agent_port][agent_chan] == 2) begin
          if (req_resp.addr == h2d_wrbk_descr_nxt_exp_addr[agent_port][agent_chan])
            h2d_desc_wrbk_cntr[agent_port][agent_chan] = h2d_desc_wrbk_cntr[agent_port][agent_chan] + 1;
          h2d_wrbk_descr_repeat[agent_port][agent_chan] = 0;
        end

        if (prev_h2d_addr[agent_port][agent_chan] == req_resp.addr) begin
          ignore_redundant_addr = 1;
          if ((h2d_wrbk_descr_repeat[agent_port][agent_chan] == 1) && (matched_element[0] == req_resp.addr)) begin
            h2d_wrbk_descr_repeat[agent_port][agent_chan] = 2;
            h2d_wrbk_descr_nxt_exp_addr[agent_port][agent_chan] = req_resp.addr+'h20;
          end
        end else begin
          if ((h2d_wrbk_descr_repeat[agent_port][agent_chan] == 0) && (matched_element[0] == req_resp.addr)) begin 
            h2d_wrbk_descr_repeat[agent_port][agent_chan] = 1;
            h2d_wrbk_descr_nxt_exp_addr[agent_port][agent_chan] = req_resp.addr;
          end
        end

        `uvm_info(get_full_name(),
                  $sformatf("\nh2d_wrbk_descr_repeat[%0d][%0d] = %0d\nh2d_wrbk_descr_nxt_exp_addr[%0d][%0d] = %0h",
                            agent_port, agent_chan, h2d_wrbk_descr_repeat[agent_port][agent_chan],
                            agent_port, agent_chan, h2d_wrbk_descr_nxt_exp_addr[agent_port][agent_chan]),
                  UVM_DEBUG)
        // if ((matched_element[0] == req_resp.addr) && (ignore_redundant_addr == 0))
        //   h2d_desc_wrbk_cntr[agent_port][agent_chan] = h2d_desc_wrbk_cntr[agent_port][agent_chan] + 1;
        // else if (ignore_redundant_addr == 1) ignore_redundant_addr = 0;

        `uvm_info(get_full_name(),
                  $sformatf("h2d_desc_wrbk_cntr[%0d][%0d] %0d",
                            agent_port, agent_chan, h2d_desc_wrbk_cntr[agent_port][agent_chan]), UVM_DEBUG);
        prev_h2d_addr[agent_port][agent_chan] = req_resp.addr;
      end else if (agent_type == D2H_ST_AGENT) begin
        `uvm_info(get_full_name(),
                  $sformatf("pre-match: prev_d2h_addr[%0d][%0d] = %0h, req_resp.addr %0h",
                             agent_port, agent_chan, prev_d2h_addr[agent_port][agent_chan], req_resp.addr),
                  UVM_DEBUG)

        matched_element = d2h_desc_ptr[agent_port][agent_chan].find_first with (item == req_resp.addr);
        `uvm_info(get_full_name(),
                  $sformatf("matched_element[0]=%0h, req_resp.addr %0h",
                             matched_element[0], req_resp.addr),
                  UVM_DEBUG)

        if (d2h_wrbk_descr_repeat[agent_port][agent_chan] == 2) begin
          if (req_resp.addr == d2h_wrbk_descr_nxt_exp_addr[agent_port][agent_chan])
            d2h_desc_wrbk_cntr[agent_port][agent_chan] = d2h_desc_wrbk_cntr[agent_port][agent_chan] + 1;
          d2h_wrbk_descr_repeat[agent_port][agent_chan] = 0;
        end

        if (prev_d2h_addr[agent_port][agent_chan] == req_resp.addr) begin 
          ignore_redundant_addr = 1;
          if ((d2h_wrbk_descr_repeat[agent_port][agent_chan] == 1) && (matched_element[0] == req_resp.addr)) begin
            d2h_wrbk_descr_repeat[agent_port][agent_chan] = 2;
            d2h_wrbk_descr_nxt_exp_addr[agent_port][agent_chan] = req_resp.addr+'h20;
          end
        end else begin
          if ((d2h_wrbk_descr_repeat[agent_port][agent_chan] == 0) && (matched_element[0] == req_resp.addr)) begin 
            d2h_wrbk_descr_repeat[agent_port][agent_chan] = 1;
            d2h_wrbk_descr_nxt_exp_addr[agent_port][agent_chan] = req_resp.addr;
          end
        end

        `uvm_info(get_full_name(),
                  $sformatf("\nd2h_wrbk_descr_repeat[%0d][%0d] = %0d\nd2h_wrbk_descr_nxt_exp_addr[%0d][%0d] = %0h",
                            agent_port, agent_chan, d2h_wrbk_descr_repeat[agent_port][agent_chan],
                            agent_port, agent_chan, d2h_wrbk_descr_nxt_exp_addr[agent_port][agent_chan]),
                  UVM_DEBUG)
        // if ((matched_element[0] == req_resp.addr) && (ignore_redundant_addr == 0))
        //   d2h_desc_wrbk_cntr[agent_port][agent_chan] = d2h_desc_wrbk_cntr[agent_port][agent_chan] + 1;
        // else if (ignore_redundant_addr == 1) ignore_redundant_addr = 0;
        
        `uvm_info(get_full_name(),
                  $sformatf("d2h_desc_wrbk_cntr[%0d][%0d] %0d",
                            agent_port, agent_chan, d2h_desc_wrbk_cntr[agent_port][agent_chan]), UVM_DEBUG);
        prev_d2h_addr[agent_port][agent_chan] = req_resp.addr;
      end
    end

    `uvm_info(get_full_name(), "sending BRESP to slave sequencer", UVM_LOW)
    `uvm_rand_send_with(req, {	
                         bresp == svt_axi_slave_transaction::OKAY;
                         foreach (addr_ready_delay[i]) 
                           {addr_ready_delay[i] == 0;}
                         foreach (wready_delay[i])
                           {wready_delay[i] == 0;}
                       })
  endtask: respond_to_write_req

  //----------------------------------------------------------------------------------
  // Host Read respond 
  //----------------------------------------------------------------------------------
  virtual task respond_to_read_req();
    //----------------------------------------------------------------------------------------
    // STEP 1::Checks format type and assign values to address_type, agent_type and agent_port
    //----------------------------------------------------------------------------------------
    $cast(address_type,req_resp.addr[30:28]); 
    if (address_type == CSR) begin
      $cast(agent_type,req_resp.addr[21:20]);
      $cast(agent_port,req_resp.addr[16:13]);
      $cast(burst_length,req_resp.burst_length);
    end else begin
      $cast(agent_type,req_resp.addr[27]);
      $cast(agent_chan,req_resp.addr[26:25]);
      $cast(agent_port,req_resp.addr[24:23]);
      $cast(burst_length,req_resp.burst_length);
      $cast(burst_size,req_resp.burst_size);
      if (address_type == DMA_DATA) begin
        burst_size_bytes = (2**burst_size);
        burst_size_bits = burst_size_bytes*8;
        up_burst_length = burst_length/8;
      end
    end

    `uvm_info(get_full_name(),
              $sformatf("\nRead address (%0h) type is %s\nfor agent %0s @ port %0d, channel %0d",
                         req_resp.addr, address_type.name(), agent_type.name(), agent_port, agent_chan),
              UVM_DEBUG)
    `uvm_info(get_full_name(),
              $sformatf("\nburst_length %0d, burst_size %0d, burst_size_bits %0d",
                         burst_length, burst_size, burst_size_bits),
              UVM_DEBUG)

    //----------------------------------------------------------------------------------------
    // STEP 2::Address type == DESCR, construct rdata to prefetcher, to return descriptors
    //----------------------------------------------------------------------------------------
    if (address_type == DESCR) begin
      $display("=================================================================================");
      $display("Memory read request for descriptor request: 256'h%0h", req_resp.addr);
      $display("=================================================================================");
      
      num_of_desc_requested_per_arlen = burst_length;
      `uvm_info(get_full_name(),
                $sformatf("num_of_desc_requested_per_arlen : %0d",num_of_desc_requested_per_arlen),
                UVM_DEBUG)
      
      // Initialize before processing the request of an memory read packet.
      desc_offset_per_memrd_pkt_request = 0;

      `uvm_info(get_full_name,
                $sformatf("burst_len %0d, h2d_poll_en[%0d][%0d] %0d, d2h_poll_en[%0d][%0d] %0d",
                          req_resp.burst_length, agent_port, agent_chan, h2d_descr_poll_en[agent_port][agent_chan],
                          agent_port, agent_chan, d2h_descr_poll_en[agent_port][agent_chan]),
                UVM_DEBUG)
      `uvm_info(get_full_name,
                $sformatf("sw_owne_h2d_cntr[%0d][%0d] %0d, h2d_sw_owned[%0d][%0d][%0d]=[%0d]",
                          agent_port, agent_chan, sw_owned_h2d_cntr[agent_port][agent_chan],
                          agent_port, agent_chan, h2d_desc_cntr[agent_port][agent_chan],
                          h2d_sw_owned[agent_port][agent_chan][h2d_desc_cntr[agent_port][agent_chan]]),
                UVM_DEBUG)
      `uvm_info(get_full_name,
                $sformatf("sw_owne_d2h_cntr[%0d][%0d] %0d, d2h_sw_owned[%0d][%0d][%0d]=[%0d]",
                          agent_port, agent_chan, sw_owned_d2h_cntr[agent_port][agent_chan],
                          agent_port, agent_chan, d2h_desc_cntr[agent_port][agent_chan], d2h_sw_owned[agent_port][agent_chan][d2h_desc_cntr[agent_port][agent_chan]]),
                UVM_DEBUG)
      if ((req_resp.burst_length == 1) &&
          ((h2d_descr_poll_en[agent_port][agent_chan] == 1) || (d2h_descr_poll_en[agent_port][agent_chan] == 1))) begin
        if (agent_type == H2D_ST_AGENT) begin
          if (h2d_desc_cntr[agent_port][agent_chan]>=h2d_max_desc[agent_port][agent_chan])
            poll_data = {PORT0_END_DESC_CTRL, 224'd0}; // sw owned
          else if (sw_owned_h2d_cntr[agent_port][agent_chan] !== h2d_sw_owned[agent_port][agent_chan][h2d_desc_cntr[agent_port][agent_chan]]) begin
            poll_data = {PORT0_END_DESC_CTRL, 224'd0}; // sw owned
            sw_owned_h2d_cntr[agent_port][agent_chan] = sw_owned_h2d_cntr[agent_port][agent_chan]+1;
          end else begin
            poll_data = {PORT0_START_DESC_CTRL, 224'd0}; // hw_owned
            sw_owned_h2d_cntr[agent_port][agent_chan] = 0;
          end
        end else if (agent_type == D2H_ST_AGENT) begin
          if (d2h_desc_cntr[agent_port][agent_chan]>=d2h_max_desc[agent_port][agent_chan])
            poll_data = {PORT0_END_DESC_CTRL, 224'd0}; // sw owned
          else if (sw_owned_d2h_cntr[agent_port][agent_chan] !== d2h_sw_owned[agent_port][agent_chan][d2h_desc_cntr[agent_port][agent_chan]]) begin
            poll_data = {PORT0_END_DESC_CTRL, 224'd0}; // sw owned
            sw_owned_d2h_cntr[agent_port][agent_chan] = sw_owned_d2h_cntr[agent_port][agent_chan]+1;
          end else begin
            poll_data = {PORT0_START_DESC_CTRL, 224'd0}; // hw_owned
            sw_owned_d2h_cntr[agent_port][agent_chan] = 0;
          end
        end
        rdata_out = new[req_resp.burst_length]; //burst_length changed to 0 temporarily. TBD
        rdata_out[0] = poll_data;
      end else begin
        load_descriptor();
        if (agent_type == H2D_ST_AGENT) h2d_desc_cntr[agent_port][agent_chan] = h2d_desc_cntr[agent_port][agent_chan]+1;
        if (agent_type == D2H_ST_AGENT) d2h_desc_cntr[agent_port][agent_chan] = d2h_desc_cntr[agent_port][agent_chan]+1;
      end

      // send req_resp to driver
      `uvm_info("body", "sending Descriptors to slave sequencer ", UVM_NONE)
      `uvm_rand_send_with(req, {	
                                foreach (data[index])   {
                                  data[index] == rdata_out[index]; }
                                foreach (rresp[index]) {
                                  rresp[index] == svt_axi_slave_transaction::OKAY; }
                                foreach (rvalid_delay[i])   {
                                  rvalid_delay[i] == 0; }
                                foreach (addr_ready_delay[i])   {
                                  addr_ready_delay[i] == 0; }
                               })
      desc_offset_per_memrd_pkt_request = 0;
    end //end of DESCR

    //----------------------------------------------------------------------------------------
    // STEP 3::Address type == DMA, construct rdata to Agents, to return DMA data
    //----------------------------------------------------------------------------------------
    if (address_type == DMA_DATA) begin
      $display("=================================================================================");
      $display("Memory read request for DMA data request: 256'h%0h", req_resp.addr);
      $display("=================================================================================");
      
      // send req_resp to driver
      `uvm_info("body", "sending DMA data to slave sequencer ", UVM_NONE)
      rdata_out = new[burst_length]; //burst_length changed to 0 temporarily. TBD

      for (int j=0; j<burst_length; j++) begin
        for (int b=0; b<burst_size_bytes; b++) begin
          rdata_out[j][8*b+:8] = rd_buffer[(burst_size_bytes*j)+req_resp.addr+b];
        end
      end

      #0;
      if (!req.randomize() with {
                                foreach (rresp[index]) {
                                 	rresp[index] == svt_axi_slave_transaction::OKAY; }
                                foreach (rvalid_delay[i])   {
                                  rvalid_delay[i] == 0; }
                                foreach (addr_ready_delay[i])   {
                                  addr_ready_delay[i] == 0; }
      }) `uvm_error(get_full_name(), "Randomization failure...")
      else begin
        foreach (req.data[i])
          req.data[i] = rdata_out[i];
      end
      `uvm_send(req)
    end //end of DMA_DATA
  endtask: respond_to_read_req

  //----------------------------------------------------------------------------------
  // Create descriptor queue
  //----------------------------------------------------------------------------------
  task load_descriptor_queue(bit [1:0] port_num, bit [1:0] ch_num);
    logic [31:0] sctrl;
    logic [31:0] ectrl;

    h2d_st_data_desc_1.Reserved = 'h0;
    h2d_st_data_desc_1.NextDescptrU = 'h0;
    h2d_st_data_desc_1.WriteAddressU = 'h0;
    h2d_st_data_desc_1.ReadAddressU = 'h0; 
    h2d_st_data_desc_1.Stride = 'h0;
    h2d_st_data_desc_1.Reserved1 = 'h0;
    h2d_st_data_desc_1.Status = 'h0;
    h2d_st_data_desc_1.ActualBytesTransfered = 'h0;

    // h2d_desc_ptr[port_num][0] = 'h14000000;
    h2d_desc_ptr[port_num][ch_num][0] = {1'b0, `DESCR, `H2D_ST_AGENT, ch_num, port_num, 23'h0};

    `uvm_info(get_full_name(), $sformatf("Load H2D Descr Q for port num %0d, ch_num %0d", port_num, ch_num), UVM_DEBUG)

    for (int r = 0; r <h2d_max_desc[port_num][ch_num];r++) begin // No.of desc
      if (r ==0) begin 
        ctrl = PORT0_START_DESC_CTRL;
        seq_num = r;
        // next_descptr = 'h14010000; 
        next_descptr = h2d_desc_ptr[port_num][ch_num][0]+'h100;
        h2d_desc_ptr[port_num][ch_num][r+1] = next_descptr;
        // rd_addr = PORT0_TXDMA_ADDR+(32'h1000_0000*port_num);
        rd_addr = {1'b0, `DMA_DATA, `H2D_ST_AGENT, ch_num, port_num, 23'h0};
        `uvm_info(get_full_name(),
                  $sformatf("first h2d Descr-rd_addr %0h, next desc addr %0h for port num %0d, ch_num %0d",
                            rd_addr, next_descptr, port_num, ch_num),
                  UVM_DEBUG)
      end else if (r>=1 && r<h2d_max_desc[port_num][ch_num]-1) begin 
        ctrl = PORT0_START_DESC_CTRL;
        seq_num = r;
        next_descptr = next_descptr +'h100;
        h2d_desc_ptr[port_num][ch_num][r+1] = next_descptr;
        rd_addr = rd_addr + h2d_desc_length[port_num][ch_num][r-1];//'h60A;
      end else if (r==h2d_max_desc[port_num][ch_num]-1) begin 
        ctrl = PORT0_END_DESC_CTRL;
        seq_num = r;
        next_descptr = next_descptr +'h100;
        h2d_desc_ptr[port_num][ch_num][r+1] = next_descptr;
        rd_addr = rd_addr + h2d_desc_length[port_num][ch_num][r-1];//'h60A;
      end
      h2d_st_data_desc_1.Control = ctrl;
      h2d_st_data_desc_1.BurstSeqnumber = seq_num;
      h2d_st_data_desc_1.NextDescptrL = next_descptr;
      h2d_st_data_desc_1.Length = h2d_desc_length[port_num][ch_num][r];
      h2d_st_data_desc_1.WriteAddressL = 'h0;
      h2d_st_data_desc_1.ReadAddressL = rd_addr;
      rdesc0_queue[port_num][ch_num].push_back({
        h2d_st_data_desc_1.Control, // SOP and EOP set
        h2d_st_data_desc_1.Reserved,
        h2d_st_data_desc_1.NextDescptrU,
        h2d_st_data_desc_1.WriteAddressU,
        h2d_st_data_desc_1.ReadAddressU, 
        h2d_st_data_desc_1.Stride,
        h2d_st_data_desc_1.BurstSeqnumber,
        h2d_st_data_desc_1.Reserved1,
        h2d_st_data_desc_1.Status,
        h2d_st_data_desc_1.ActualBytesTransfered,
        h2d_st_data_desc_1.NextDescptrL,
        h2d_st_data_desc_1.Length, 
        h2d_st_data_desc_1.WriteAddressL,
        h2d_st_data_desc_1.ReadAddressL}); 
      $display("rdesc0_queue[%0d][%0d][%0d]:%h", port_num, ch_num, r, rdesc0_queue[port_num][ch_num][r]);
      $display ("IN PORT0 RDESC QUEUE");
      load_read_buffer(rd_addr, h2d_desc_length[port_num][ch_num][r], port_num, ch_num);
    end // for loop for no of descr

    // d2h_desc_ptr[0][0] = 'h10000000;
    d2h_desc_ptr[port_num][ch_num][0] = {1'b0, `DESCR, `D2H_ST_AGENT, ch_num, port_num, 23'h0};

    for (int w = 0; w <d2h_max_desc[port_num][ch_num]; w++) begin // No.of desc
      if (w ==0 ) begin 
        ctrl = PORT0_START_DESC_CTRL;
        seq_num = w;
        // next_descptr = 'h10010000; 
        next_descptr = d2h_desc_ptr[port_num][ch_num][0]+'h100;
        d2h_desc_ptr[port_num][ch_num][w+1] = next_descptr;
        // wr_addr = PORT0_RXDMA_ADDR+(32'h1000_0000*port_num);
        wr_addr = {1'b0, `DMA_DATA, `D2H_ST_AGENT, ch_num, port_num, 23'h0};
        `uvm_info(get_full_name(),
                  $sformatf("first d2h Descr-wr_addr %0h, next desc addr %0h for port num %0d, ch_num %0d",
                            wr_addr, next_descptr, port_num, ch_num),
                  UVM_DEBUG)
      end else if (w>=1 && w<d2h_max_desc[port_num][ch_num]-1) begin 
        ctrl = PORT0_START_DESC_CTRL;
        seq_num = w;
        next_descptr = next_descptr +'h100;
        d2h_desc_ptr[port_num][ch_num][w+1] = next_descptr;
        wr_addr =  wr_addr + d2h_desc_length[port_num][ch_num][w-1];// 'h610;
      end else if (w==d2h_max_desc[port_num][ch_num]-1) begin 
        if (d2h_descr_poll_en[port_num][ch_num] == 1)
          ctrl = PORT0_START_DESC_CTRL;
        else
          ctrl = PORT0_END_DESC_CTRL;
        seq_num = w;
        next_descptr = next_descptr +'h100;
        d2h_desc_ptr[port_num][ch_num][w+1] = next_descptr;
        wr_addr =  wr_addr + d2h_desc_length[port_num][ch_num][w-1];// 'h610;
      end
      h2d_st_data_desc_1.Control = ctrl;
      h2d_st_data_desc_1.BurstSeqnumber = seq_num;
      h2d_st_data_desc_1.NextDescptrL = next_descptr;
      h2d_st_data_desc_1.Length = d2h_desc_length[port_num][ch_num][w];
      h2d_st_data_desc_1.WriteAddressL = wr_addr;
      h2d_st_data_desc_1.ReadAddressL = 'h0;
      wdesc0_queue[port_num][ch_num].push_back({
        h2d_st_data_desc_1.Control, // SOP and EOP set
        h2d_st_data_desc_1.Reserved,
        h2d_st_data_desc_1.NextDescptrU,
        h2d_st_data_desc_1.WriteAddressU,
        h2d_st_data_desc_1.ReadAddressU, 
        h2d_st_data_desc_1.Stride,
        h2d_st_data_desc_1.BurstSeqnumber,
        h2d_st_data_desc_1.Reserved1,
        h2d_st_data_desc_1.Status,
        h2d_st_data_desc_1.ActualBytesTransfered,
        h2d_st_data_desc_1.NextDescptrL,
        h2d_st_data_desc_1.Length, 
        h2d_st_data_desc_1.WriteAddressL,
        h2d_st_data_desc_1.ReadAddressL}); 
      $display("wdesc0_queue[%0d][%0d][%0d]:%h", port_num, ch_num, w, wdesc0_queue[port_num][ch_num][w]);
      $display ("IN PORT0 WDESC QUEUE");
    end   
  endtask: load_descriptor_queue

  //----------------------------------------------------------------------------------
  // Lod descriptor fields
  //----------------------------------------------------------------------------------
  virtual task load_descriptor();
    while (desc_offset_per_memrd_pkt_request < num_of_desc_requested_per_arlen) begin
      desc_offset_per_memrd_pkt_request++;
      $display("desc_offset_per_memrd_pkt_request",desc_offset_per_memrd_pkt_request);
      $display("num_of_desc_requested_per_arlen",num_of_desc_requested_per_arlen);
      if (desc_offset_per_memrd_pkt_request	== num_of_desc_requested_per_arlen) begin
        if (agent_type == H2D_ST_AGENT) begin
          rdata_out = new[burst_length]; 
          rdesc_pop = rdesc0_queue[agent_port][agent_chan].pop_front();
          for (int i=0; i<burst_length; i++) begin 
             $display("%d, rdesc_pop = %h",i,rdesc_pop);
             rdata_out[i] = rdesc_pop[256*i+:256];
             $display("rdata_out[%0d]:%h",i,rdata_out[i]);
             $display ("IN PORT0 RDESC POP");
          end
        end else if (agent_type == D2H_ST_AGENT) begin
          rdata_out = new[burst_length]; 
          wdesc_pop = wdesc0_queue[agent_port][agent_chan].pop_front();
          for (int i=0; i<burst_length; i++) begin 
            $display("%d, wdesc_pop = %h",i,wdesc_pop);
            rdata_out[i] = wdesc_pop[256*i+:256];
            $display("rdata_out[%0d]:%h",i,rdata_out[i]);
            $display ("IN PORT0 WDESC POP");
          end
        end   
      end
    end //end of WHILE LOOP
  endtask: load_descriptor


  //----------------------------------------------------------------------------------
  // Load read buffer memory
  //----------------------------------------------------------------------------------
  task load_read_buffer(int addr, int bytes, bit [1:0] port_num, bit [1:0] ch_num);
    bit [511:0] pkd_arr;

    sa = h2d_sa[port_num][ch_num];
    da = h2d_da[port_num][ch_num];
    len = h2d_eth[port_num][ch_num];

    `uvm_info(get_full_name(),
              $sformatf({"\nfor addr %0h, \nloaded sa=%0h from h2d_sa[%0d][%0d]=%0h",
                         "\nloaded da=%0h from h2d_da[%0d][%0d]=%0h"}, addr,
                        sa, port_num, ch_num, h2d_sa[port_num][ch_num],
                        da, port_num, ch_num, h2d_da[port_num][ch_num]),
              UVM_DEBUG)

    eth_pkt_1.data3 = $random;
    eth_pkt_1.data2 = $random;
    eth_pkt_1.data1 = $random;
    eth_pkt_1.data0 = $random;
    eth_pkt_1.len = {<<8{len}};
    eth_pkt_1.sa = {<<8{sa}};
    eth_pkt_1.da = {<<8{da}};

    // enter random data for the unused addresses
    if ((addr-rd_buffer_pointer)>1) begin
      for (int j=1; j<(addr-rd_buffer_pointer);j++) begin
        if (!rd_buffer.exists(rd_buffer_pointer+j))
          rd_buffer[rd_buffer_pointer+j] = $random;
      end
    end

    // load eth pkt at the confugred rd addr in the descr
    for (int i = 0; i<bytes; i++) begin
      if (i<64) begin
        rd_buffer[addr+i] = eth_pkt_1[8*i+:8];
      end else begin
        rd_buffer[addr+i] = $random;
      end

      if (i == (bytes-1)) rd_buffer_pointer = addr+i;
    end
  endtask: load_read_buffer
endclass:sm_ptp_axi_slave_host_response_seq

`endif // SM_PTP_AXI_SLAVE_MSGDMA_HOST_RESPONSE_SEQ__SV

