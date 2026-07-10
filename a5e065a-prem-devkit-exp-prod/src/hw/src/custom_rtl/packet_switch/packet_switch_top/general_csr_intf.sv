//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module general_csr_intf
   #( parameter BASE_ADDR        = 'h0
     ,parameter MAX_ADDR         = 'h8
     ,parameter ADDR_WIDTH       = 8
     ,parameter DATA_WIDTH       = 32
     ,parameter HSSI_PORT        = 2
     ,parameter DMA_CH           = 6
     ,parameter DBG_CNTR_EN      = 0
   ) 

  (
    //---------------------------------------------------------------------------------------
    // Clock
    input var logic                        clk
    //---------------------------------------------------------------------------------------
    // Reset
    ,input var logic                       rst
    //---------------------------------------------------------------------------------------
    // AVMM interface
    ,input var logic [ADDR_WIDTH-1:0]      avmm_address
    ,input var logic                       avmm_read
    ,output var logic [DATA_WIDTH-1:0]     avmm_readdata 
    ,input var logic                       avmm_write
    ,input var logic [DATA_WIDTH-1:0]      avmm_writedata
    ,input var logic [(DATA_WIDTH/8)-1:0]  avmm_byteenable
    ,output var logic                      avmm_readdata_valid

    //-----------------------------------------------------------------------------------------
    // init_done
    ,input var logic [HSSI_PORT-1:0]       rx_init_done
    ,input var logic [HSSI_PORT-1:0]       tx_init_done
   );

   import packet_switch_pkg::*;
   localparam CSR_ADDR_WIDTH = $clog2(MAX_ADDR);

   logic [ADDR_WIDTH-1:0]      avmm_address_chkd;
   logic                       avmm_read_chkd;
   logic                       avmm_write_chkd;
   logic [DATA_WIDTH-1:0]      avmm_writedata_chkd;
   logic [(DATA_WIDTH/8)-1:0]  avmm_byteenable_chkd;

   logic [HSSI_PORT-1:0] rx_init_done_sync, tx_init_done_sync;

   genvar i;
   generate
    for (i=0; i < HSSI_PORT; i++) begin
     altera_std_synchronizer #( .depth(3)
                               ) rx_sync
      (//------------------------------------------------------------------------------------
       .clk (clk) 
       ,.reset_n (!rst)
       ,.din  (rx_init_done[i]) 
       ,.dout (rx_init_done_sync[i])
       );

     altera_std_synchronizer #( .depth(3)
                               ) tx_sync
      (//------------------------------------------------------------------------------------
       .clk (clk) 
       ,.reset_n (!rst)
       ,.din  (tx_init_done[i]) 
       ,.dout (tx_init_done_sync[i])
       );
    end // for
   endgenerate

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

	general_csr #(
      .HSSI_PORT (HSSI_PORT)
     ,.DMA_CH    (DMA_CH)
     ,.DBG_CNTR_EN (DBG_CNTR_EN)
    ) general_csr_inst (
	// inputs
     .status_reg_rx_init_done_i (&rx_init_done_sync)
	,.status_reg_tx_init_done_i (&tx_init_done_sync)

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