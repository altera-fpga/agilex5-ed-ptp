//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 



//////////////////////////////////////////////////////////////////////////////////////////////
// Description:
//
//
//////////////////////////////////////////////////////////////////////////////////////////////

module packet_switch_avmm_addr_chk
   #( parameter BASE_ADDR        = 'h0
     ,parameter MAX_ADDR         = 'h8 // max address offset
     ,parameter ADDR_WIDTH       = 8
     ,parameter DATA_WIDTH       = 32
   ) 

  (
    //---------------------------------------------------------------------------------------
    // Clock
    input var logic                        clk
    //---------------------------------------------------------------------------------------
    //---------------------------------------------------------------------------------------

    //-----------------------------------------------------------------------------------------
    // AVMM interface

    // ingress
    ,input var logic [ADDR_WIDTH-1:0]     igr_avmm_address
    ,input var logic                      igr_avmm_read
    ,input var logic                      igr_avmm_write
    ,input var logic [DATA_WIDTH-1:0]     igr_avmm_writedata
    ,input var logic [(DATA_WIDTH/8)-1:0] igr_avmm_byteenable

    // ingress
    ,output var logic [ADDR_WIDTH-1:0]    egr_avmm_address
    ,output var logic                     egr_avmm_read
    ,output var logic                     egr_avmm_write
    ,output var logic [DATA_WIDTH-1:0]    egr_avmm_writedata
    ,output var logic [(DATA_WIDTH/8)-1:0] egr_avmm_byteenable

   );

   import packet_switch_pkg::*;

   logic [ADDR_WIDTH:0] adj_addr; // msb for signed
   

   logic [DATA_WIDTH-1:0] igr_wrdata;
   logic [(DATA_WIDTH/8)-1:0] igr_byteenable;

   logic igr_read, igr_wr;

   always_ff @ (posedge clk) begin

     // adjusted addr
     adj_addr <= igr_avmm_address - BASE_ADDR[ADDR_WIDTH-1:0];
     igr_read <= igr_avmm_read;
     igr_wr <= igr_avmm_write;
     igr_wrdata <= igr_avmm_writedata;
     igr_byteenable <= igr_avmm_byteenable;

     // -----------------

     egr_avmm_read <= (adj_addr[ADDR_WIDTH-1:0] > MAX_ADDR) 
                       | adj_addr[ADDR_WIDTH] ? '0 : igr_read;
     egr_avmm_write <= (adj_addr[ADDR_WIDTH-1:0] > MAX_ADDR)
                       | adj_addr[ADDR_WIDTH] ? '0 : igr_wr;
     egr_avmm_writedata <= igr_wrdata;
     egr_avmm_byteenable <= igr_byteenable;
     egr_avmm_address <= adj_addr[ADDR_WIDTH-1:0];
   end

endmodule