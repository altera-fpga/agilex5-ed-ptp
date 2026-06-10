//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module dma_rx_dmux_csr_intf
   #( parameter BASE_ADDR        = 'h0
     ,parameter MAX_ADDR         = 'h10
     ,parameter ADDR_WIDTH       = 8
     ,parameter DATA_WIDTH       = 32
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
    // CSR Drop enable and Drop threshold
    ,output var logic                      cfg_dma_0_drop_en
    ,output var logic                      cfg_dma_1_drop_en
    ,output var logic                      cfg_dma_2_drop_en
    ,output var logic [15:0]               cfg_dma_0_drop_threshold
    ,output var logic [15:0]               cfg_dma_1_drop_threshold
    ,output var logic [15:0]               cfg_dma_2_drop_threshold
   );

   import packet_switch_pkg::*;

   logic [ADDR_WIDTH-1:0]      avmm_address_chkd;
   logic                       avmm_read_chkd;
   logic                       avmm_write_chkd;
   logic [DATA_WIDTH-1:0]      avmm_writedata_chkd;
   logic [(DATA_WIDTH/8)-1:0]  avmm_byteenable_chkd;

   logic                      cfg_dma_0_drop_en_w, cfg_dma_1_drop_en_w, cfg_dma_2_drop_en_w;
   logic [15:0]               cfg_dma_0_drop_threshold_w, 
     cfg_dma_1_drop_threshold_w, cfg_dma_2_drop_threshold_w;

   localparam CSR_ADDR_WIDTH = $clog2(MAX_ADDR);

   always_ff @ (posedge clk) begin
     cfg_dma_0_drop_en        <= cfg_dma_0_drop_en_w;
     cfg_dma_1_drop_en        <= cfg_dma_1_drop_en_w;
     cfg_dma_2_drop_en        <= cfg_dma_2_drop_en_w;
     cfg_dma_0_drop_threshold <= cfg_dma_0_drop_threshold_w;
     cfg_dma_1_drop_threshold <= cfg_dma_1_drop_threshold_w;
     cfg_dma_2_drop_threshold <= cfg_dma_2_drop_threshold_w;
   end

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

   dma_rx_dmux_csr dma_rx_dmux_csr_inst (
    // Outputs
    .control_reg_dma_0_drop_en  (cfg_dma_0_drop_en_w)
    ,.control_reg_dma_1_drop_en (cfg_dma_1_drop_en_w)
    ,.control_reg_dma_2_drop_en (cfg_dma_2_drop_en_w)
    ,.dma_0_drop_threshold_reg_drop_threshold (cfg_dma_0_drop_threshold_w)
    ,.dma_1_drop_threshold_reg_drop_threshold (cfg_dma_1_drop_threshold_w)
    ,.dma_2_drop_threshold_reg_drop_threshold (cfg_dma_2_drop_threshold_w)

    // unused outputs (not supported)
    ,.control_reg_dma_3_drop_en ()
    ,.control_reg_dma_4_drop_en ()
    ,.control_reg_dma_5_drop_en ()
    ,.control_reg_dma_6_drop_en ()
    ,.control_reg_dma_7_drop_en ()

    ,.dma_3_drop_threshold_reg_drop_threshold ()
    ,.dma_4_drop_threshold_reg_drop_threshold ()
    ,.dma_5_drop_threshold_reg_drop_threshold ()
    ,.dma_6_drop_threshold_reg_drop_threshold ()
    ,.dma_7_drop_threshold_reg_drop_threshold ()
    //

    //Bus Interface 
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