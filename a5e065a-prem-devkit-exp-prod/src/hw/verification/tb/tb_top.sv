//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//#########################################################################

/**
 * Abstract:
 * Top-level SystemVerilog tb_top.
 * It instantites the interface and interconnect wrapper.  Clock generation
 * is also  done in the same file.  It includes each test file and initiates
 * the UVM phase manager by calling run_test().
 */
`timescale 1ns/1ps

//======================================================
// Common Package / Interface - PCIE/SOC/DMA 
//======================================================

module tb_top ();
  //======================================================
  // Import Package  
  //======================================================
	import uvm_pkg::*;			// Import UVM package
	import svt_uvm_pkg::*;		// Import SVT UVM package
	import svt_axi_uvm_pkg::*;	// Import the AXI VIP package
	
	/* Include all test files */

  //======================================================
  // Wire declaration
  //======================================================
  wire        ssgdma_h2d0_st_tvalid     ;
  wire        ssgdma_h2d0_st_tready     ;
  wire [63:0] ssgdma_h2d0_st_tdata      ;
  wire        ssgdma_h2d0_st_tid        ;
  wire [7:0]  ssgdma_h2d0_st_tkeep      ;
  wire        ssgdma_h2d0_st_tlast      ;
  wire        ssgdma_h2d0_st_eth_tvalid ;
  wire        ssgdma_h2d0_st_eth_tready ;
  wire [95:0] ssgdma_h2d0_st_eth_tdata  ;
  wire        ssgdma_h2d0_st_eth_tid    ;
  wire        ssgdma_h2d1_st_tvalid     ;
  wire        ssgdma_h2d1_st_tready     ;
  wire [63:0] ssgdma_h2d1_st_tdata      ;
  wire        ssgdma_h2d1_st_tid        ;
  wire [7:0]  ssgdma_h2d1_st_tkeep      ;
  wire        ssgdma_h2d1_st_tlast      ;
  wire        ssgdma_h2d1_st_eth_tvalid ;
  wire        ssgdma_h2d1_st_eth_tready ;
  wire [95:0] ssgdma_h2d1_st_eth_tdata  ;
  wire        ssgdma_h2d1_st_eth_tid    ;
  wire        ssgdma_d2h0_st_tvalid     ;
  wire        ssgdma_d2h0_st_tready     ;
  wire [63:0] ssgdma_d2h0_st_tdata      ;
  wire        ssgdma_d2h0_st_tid        ;
  wire [7:0]  ssgdma_d2h0_st_tkeep      ;
  wire        ssgdma_d2h0_st_tlast      ;
  wire        ssgdma_d2h0_st_eth_tvalid ;
  wire        ssgdma_d2h0_st_eth_tready ;
  wire [95:0] ssgdma_d2h0_st_eth_tdata  ;
  wire        ssgdma_d2h0_st_eth_tid    ;
  wire        ssgdma_d2h1_st_tvalid     ;
  wire        ssgdma_d2h1_st_tready     ;
  wire [63:0] ssgdma_d2h1_st_tdata      ;
  wire        ssgdma_d2h1_st_tid        ;
  wire [7:0]  ssgdma_d2h1_st_tkeep      ;
  wire        ssgdma_d2h1_st_tlast      ;
  wire        ssgdma_d2h1_st_eth_tvalid ;
  wire        ssgdma_d2h1_st_eth_tready ;
  wire [95:0] ssgdma_d2h1_st_eth_tdata  ;
  wire        ssgdma_d2h1_st_eth_tid    ;

  wire [`SM_PTP_NUM_PORTS-1:0]  serial_data;
  wire [`SM_PTP_NUM_PORTS-1:0]  serial_data_n;

  wire        clk_bdg_100_clk;
  wire        clk_bdg_250_clk;
  wire        iopll_locked_export;

  bit clk_100m;
  bit clk_161m;
  bit clk_156m;
  bit clk_125m;
  bit clk_312m;

  bit ninit_done;
  bit h2f_reset;
  bit reset_n;
  bit system_reset_n;
  bit fpga_reset_n;
  
	bit reset_h2d_st;
	bit reset_h2d_mm;
	bit reset_soc_host;
	
	bit irq;
	bit [9:0] sdl8_arlen;
	int watchdog_timeout_slave;
	int watchdog_timeout_master;

  bit all_dma_desc_done = 0;
  bit end_response_seq = 0;
  bit reconfig_reset;

  //======================================================
  // Interface Instantiation
  //======================================================
	/* VIP Interface instance representing the AXI system */
	svt_axi_if 		axi_if();		// AXI VIP interface
  sm_ptp_reset_if 	sm_ptp_reset_if(); // common reset 
  sm_ptp_ehip_port_if ehip_if();
	
  //======================================================
  // Clock & reset 
  //======================================================
	/** Testbench clock generators */
	parameter simulation_cycle = 4;
  
  /* 100MHz clk */
  initial begin
    clk_100m <= 0;
    forever #5ns clk_100m <= ~clk_100m;
  end

  /* 156MHz clk */
  initial begin
    clk_156m <= 0;
    forever #3200ps clk_156m <= ~clk_156m;
  end

  /* 161MHz clk */
  initial begin
    clk_161m <= 0;
    forever #3100ps clk_161m <= ~clk_161m;
  end

  /* 125MHz clk */
  initial begin
    clk_125m <= 0;
    forever #4000ps clk_125m <= ~clk_125m;
  end

  /* 312.5MHz clk */
  initial begin
    clk_312m <= 0;
    forever #1600ps clk_312m <= ~clk_312m;
  end

  initial begin
    sm_ptp_reset_if.resetn = 1;
    fpga_reset_n = 1;
    // force dut.h2f_reset = 0;
    force tb_top.dut.gen_mulit_inst[0].hssi_ss_top.u0.i_reconfig_clk=clk_125m;
    force tb_top.dut.gen_mulit_inst[0].hssi_ss_top.u0.i_reconfig_reset=reconfig_reset ;
    force tb_top.dut.gen_mulit_inst[1].hssi_ss_top.u0.i_reconfig_clk=clk_125m;
    force tb_top.dut.gen_mulit_inst[1].hssi_ss_top.u0.i_reconfig_reset=reconfig_reset ;
    reconfig_reset =1;
    #10ns reconfig_reset=0;
  end

  initial begin
    force dut.ninit_done = 1;
    #10000ns;
    force dut.ninit_done = 0;
  end

  /* Apply clk to AXI interface */
	// assign axi_if.common_aclk = clk_100m;
  assign axi_if.master_if[0].aclk = `SM_PTP_H2F_CLK;
  assign axi_if.slave_if[0].aclk  = `SM_PTP_F2H_CLK;
  assign sm_ptp_reset_if.clk = clk_100m;
  assign sm_ptp_reset_if.ninit_done = ninit_done;

  //======================================================
  // Verification IP
  //======================================================
  // axi_if.slave -> F2H for data transfer
  assign axi_if.slave_if[0].aresetn = dut.iopll_locked_export_100M; // sm_ptp_reset_if.resetn;
  // axi_if.master -> H2F for CSR access
  assign axi_if.master_if[0].aresetn = dut.iopll_locked_export_125M; // sm_ptp_reset_if.resetn;

  //======================================================
  // DUT Instantiation
  //======================================================
  top #(
      .A0_PAGE_END_ADDR(128)
       )
   dut (
        .fpga_clk_100          (clk_100m),
        .fpga_reset_n          (sm_ptp_reset_if.resetn),
`ifdef NUM_CHANNELS_2
  `ifdef SM_PTP_PORT_LEVEL_LOOPBACK
        .i_rx_serial_data      ({serial_data[1], serial_data[0]}),
        .i_rx_serial_data_n    ({serial_data_n[1], serial_data_n[0]}),
        .o_tx_serial_data      ({serial_data[1], serial_data[0]}),
        .o_tx_serial_data_n    ({serial_data_n[1], serial_data_n[0]}),
  `else
        .i_rx_serial_data      ({serial_data[0], serial_data[1]}),
        .i_rx_serial_data_n    ({serial_data_n[0], serial_data_n[1]}),
        .o_tx_serial_data      ({serial_data[1], serial_data[0]}),
        .o_tx_serial_data_n    ({serial_data_n[1], serial_data_n[0]}),
  `endif
`else
        .i_rx_serial_data      (serial_data[0]),
        .i_rx_serial_data_n    (serial_data_n[0]),
        .o_tx_serial_data      (serial_data[0]),
        .o_tx_serial_data_n    (serial_data_n[0]),
`endif
        .i_clk_ref_p           ({`SM_PTP_NUM_PORTS{clk_156m}}),
        //.i_refclk2pll_p        (clk_156m),
        .qsfp_i2c_scl          (),
        .qsfp_i2c_sda          (),
        .qsfpa_modprsln        (2'b00), // active low
        .i_clk_master_tod      (clk_156m),
        .intn_qsfp             ('0)
  );

  //======================================================
  // AXI - DUT connections
  //======================================================
  `include "tb_dut_connections.svh"

  //======================================================
  // START TEST
  //======================================================
	initial begin
		/** Set the reset interface on the virtual sequencer */
    uvm_config_db#(virtual sm_ptp_reset_if.axi_reset_modport)::set(uvm_root::get(), "uvm_test_top.env.rst_sequencer", "reset_mp", sm_ptp_reset_if.axi_reset_modport);

		/**
		* Provide the AXI SV interface to the AXI System ENV. This step
		* establishes the connection between the AXI System ENV and the HDL
		* Interconnect wrapper, through the AXI interface.
		*/
		uvm_config_db#(svt_axi_vif)::set(uvm_root::get(), "uvm_test_top.env.axi_system_env", "vif", axi_if);

		uvm_config_db#(virtual sm_ptp_ehip_port_if)::set(uvm_root::get(), "uvm_test_top.env.ehip_port_mon", "vif", ehip_if);

		/** Start the UVM tests */
		run_test();
	end

  //======================================================
  // Waveform Dumps 
  //======================================================
  initial begin
    // Enable debugging
    `ifdef postprocess
      $vcdpluson(0,tb_top);
      $vcdplustraceon(tb_top);
      $vcdplusdeltacycleon;
      $vcdplusglitchon;
    `elsif VCS_DUMP
      $vcdplusfile("dump.vpd");
      $vcdpluson(0,tb_top);
      // $vcdplusmemon#
      // #(0,tb_top);
    `endif
  end
endmodule
