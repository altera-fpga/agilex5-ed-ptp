//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module igr_arb_csr_intf
   #( parameter BASE_ADDR        = 'h0
     ,parameter MAX_ADDR         = 'h8
     ,parameter ADDR_WIDTH       = 8
     ,parameter DATA_WIDTH       = 32
     ,parameter NUM_INTF         = 4
   ) 

  (
    //---------------------------------------------------------------------------------------
    // Clock
    input var logic                        clk
    //---------------------------------------------------------------------------------------

    //---------------------------------------------------------------------------------------
    // Reset
    ,input var logic                       rst
    //---------------------------------------------------------------------------------------

    //-----------------------------------------------------------------------------------------
    // AVMM interface

    ,input var logic [ADDR_WIDTH-1:0]      avmm_address
    ,input var logic                       avmm_read
    ,output var logic [DATA_WIDTH-1:0]     avmm_readdata 
    ,input var logic                       avmm_write
    ,input var logic [DATA_WIDTH-1:0]      avmm_writedata
    ,input var logic [(DATA_WIDTH/8)-1:0]  avmm_byteenable
    ,output var logic                      avmm_readdata_valid

    //-----------------------------------------------------------------------------------------
    // CSR Priority Ports Output
    ,output var logic [NUM_INTF-1:0][3:0]  cfg_priority
   );

   import packet_switch_pkg::*;

   logic [ADDR_WIDTH-1:0]      avmm_address_chkd;
   logic                       avmm_read_chkd;
   logic                       avmm_write_chkd;
   logic [DATA_WIDTH-1:0]      avmm_writedata_chkd;
   logic [(DATA_WIDTH/8)-1:0]  avmm_byteenable_chkd;

   localparam CSR_ADDR_WIDTH = $clog2(MAX_ADDR); // 'h8 = 4'b1000 -> log2(8) = 3

   packet_switch_avmm_addr_chk
   #( .BASE_ADDR (BASE_ADDR) 
     ,.MAX_ADDR (MAX_ADDR)
     ,.ADDR_WIDTH (ADDR_WIDTH)
     ,.DATA_WIDTH (DATA_WIDTH) ) avmm_addr_chk
   (//------------------------------------------------------------------------------------
    // Clock
    // input
    .clk (clk)

    //-----------------------------------------------------------------------------------------
    // AVMM interface

    // inputs
    ,.igr_avmm_address   (avmm_address)
    ,.igr_avmm_read      (avmm_read)
    ,.igr_avmm_write     (avmm_write)
    ,.igr_avmm_writedata (avmm_writedata)
    ,.igr_avmm_byteenable (avmm_byteenable)

    // outputs
    ,.egr_avmm_address   (avmm_address_chkd)
    ,.egr_avmm_read      (avmm_read_chkd)
    ,.egr_avmm_write     (avmm_write_chkd)
    ,.egr_avmm_writedata (avmm_writedata_chkd)
    ,.egr_avmm_byteenable (avmm_byteenable_chkd)

   );

   // CSR space

  igr_arb_csr igr_arb_csr_inst (
    // Outputs
    .cfg_priority_dma_ch_0 (cfg_priority[0])
    ,.cfg_priority_dma_ch_1 (cfg_priority[1])
    ,.cfg_priority_dma_ch_2 (cfg_priority[2])
    
    ,.cfg_priority_user_port_0 (cfg_priority[3])

    // unused cfg_priorities
    ,.cfg_priority_dma_ch_3 ()
    ,.cfg_priority_dma_ch_4 ()
    ,.cfg_priority_dma_ch_5 ()
    ,.cfg_priority_dma_ch_6 ()
    ,.cfg_priority_dma_ch_7 ()
    ,.cfg_priority_user_port_1 ()
    ,.cfg_priority_user_port_2 ()
    ,.cfg_priority_user_port_3 ()
    ,.cfg_priority_user_port_4 ()
    ,.cfg_priority_user_port_5 ()
    ,.cfg_priority_user_port_6 ()
    ,.cfg_priority_user_port_7 ()
    // 

    // Bus interface
    ,.clk            (clk)
    ,.reset          (rst)
    ,.address        (avmm_address_chkd[CSR_ADDR_WIDTH:0])
    ,.read           (avmm_read_chkd)
    ,.write          (avmm_write_chkd)
    ,.writedata      (avmm_writedata_chkd)
    ,.readdata       (avmm_readdata)
    ,.readdatavalid  (avmm_readdata_valid)
    ,.byteenable     (avmm_byteenable_chkd)
  );


endmodule