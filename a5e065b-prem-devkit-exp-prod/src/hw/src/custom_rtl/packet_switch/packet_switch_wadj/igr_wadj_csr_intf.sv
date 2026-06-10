//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module igr_wadj_csr_intf
   #( parameter INUM_SEG         = 1       
     ,parameter BASE_ADDR        = 'h0
     ,parameter MAX_ADDR         = 'h8
     ,parameter ADDR_WIDTH       = 8
     ,parameter DATA_WIDTH       = 32
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
    // CSR cfg reg Output
    ,output var logic                      cfg_rx_pause_en
    ,output var logic [15:0]               cfg_rx_pause_threshold
    ,output var logic [15:0]               cfg_drop_threshold
   );

   import packet_switch_pkg::*;

   logic [ADDR_WIDTH-1:0]      avmm_address_chkd;
   logic                       avmm_read_chkd;
   logic                       avmm_write_chkd, cfg_rx_pause_en_w;
   logic [DATA_WIDTH-1:0]      avmm_writedata_chkd;
   logic [(DATA_WIDTH/8)-1:0]  avmm_byteenable_chkd;

   logic [15:0]               cfg_rx_pause_threshold_w, cfg_drop_threshold_w;

   localparam CSR_ADDR_WIDTH = $clog2(MAX_ADDR); // 'h8 = 4'b1000 -> log2(8) = 3

   always_ff @ (posedge clk) begin
     cfg_rx_pause_en        <= cfg_rx_pause_en_w;
     cfg_rx_pause_threshold <= cfg_rx_pause_threshold_w;
     cfg_drop_threshold     <= cfg_drop_threshold_w;
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
	generate
		if(INUM_SEG==1) begin: rate10G25G
		  igr_wadj_10G_csr igr_wadj_10G_csr_inst (
			// Outputs
			 .control_reg_cfg_rx_pause_en          (cfg_rx_pause_en_w)
			,.cfg_threshold_reg_rx_pause_threshold (cfg_rx_pause_threshold_w)
			,.cfg_threshold_reg_drop_threshold     (cfg_drop_threshold_w)

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
		end //rate10G25G
		else begin : otherthan10G25G
			igr_wadj_csr igr_wadj_csr_inst (
			// Outputs
		     .cfg_control_reg_cfg_rx_pause_en      (cfg_rx_pause_en_w)
			,.cfg_threshold_reg_rx_pause_threshold (cfg_rx_pause_threshold_w)
			,.cfg_threshold_reg_drop_threshold     (cfg_drop_threshold_w)

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
		end //otherthan10G25G
	endgenerate

endmodule