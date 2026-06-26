//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module lkup_tcam_intf
   #( parameter USERMETADATA_WIDTH          = 1

     ,parameter TCAM_KEY_WIDTH              = packet_switch_pkg::tuple_map_width
     ,parameter TCAM_RESULT_WIDTH           = packet_switch_pkg::TCAM_RESULT_WIDTH
     ,parameter TCAM_ENTRIES                = 64
     ,parameter TCAM_USERMETADATA_WIDTH     = 1
     ,parameter CHTID_WIDTH                 = 1
   ) 

  (
    //----------------------------------------------------------------------------------------
    // Clocks
    input var logic                                    clk

    //----------------------------------------------------------------------------------------
    // Resets 
    ,input var logic                                   rst

    //-------------------------------------------------------------------------------------------
    // tcam interface
    // result response
    ,input var logic                                   tcam_rsp_tvalid
    ,input var packet_switch_pkg::TCAM_RESULT_S           tcam_rsp_tuser_result
    ,input var logic                                   tcam_rsp_tuser_found
    ,input var logic  [TCAM_USERMETADATA_WIDTH-1:0]    tcam_rsp_tuser_usermetadata 
    ,output var logic                                  tcam_rsp_tready

    // key request:
    ,input var logic                                   tcam_req_tready   								      		      
    ,output var logic                                  tcam_req_tvalid
    ,output var logic [CHTID_WIDTH-1:0]                tcam_req_tid // [PD] to do
    ,output var packet_switch_pkg::tuple_map_S            tcam_req_tuser_key
    ,output var logic [TCAM_USERMETADATA_WIDTH-1:0]    tcam_req_tuser_usermetadata

    //----------------------------------------------------------------------------------------
    // ingress interface
    ,input var logic                                   tvalid
    ,input var logic [USERMETADATA_WIDTH-1:0]          tuser_usermetadata
    ,input var packet_switch_pkg::SEGMENT_INFO_S          tuser_segment_info
    ,input var packet_switch_pkg::tuple_map_S             tuser_lu_key
    
    ,input var logic                                   pars2lu_tcam_req_fifo_empty
    ,output var logic                                  lu2pars_tcam_req_fifo_rd

    //----------------------------------------------------------------------------------------
    // ccm interface
    ,output var packet_switch_pkg::TCAM_RESULT_S          tcam_rsp_result
    ,output var logic                                  tcam_rsp_found
    ,output var logic [TCAM_USERMETADATA_WIDTH-1:0]    tcam_rsp_usermetadata 

    ,output var logic                                  rsp_fifo_empty
    ,input var logic                                   rsp_fifo_rd

   );
   import packet_switch_pkg::*;

   localparam REQ_FIFO_DEPTH = 16;
   localparam REQ_FIFO_THRESHOLD = REQ_FIFO_DEPTH-8;
   localparam RSP_FIFO_DEPTH = REQ_FIFO_DEPTH;
   localparam RSP_FIFO_THRESHOLD = RSP_FIFO_DEPTH-8;

   logic req_fifo_wr, req_fifo_rd, req_fifo_empty, req_fifo_full,
         req_fifo_overflow, req_fifo_underflow;
   packet_switch_pkg::tuple_map_S req_fifo_dout;

   logic rsp_fifo_wr, rsp_fifo_full,
         rsp_fifo_overflow, rsp_fifo_underflow, rsp_fifo_rdy;

   logic [$clog2(REQ_FIFO_DEPTH)-1:0] req_fifo_occ;
   logic [$clog2(RSP_FIFO_DEPTH)-1:0] rsp_fifo_occ;
    
   logic [31:0] rst_reg;
   // Generate arrays of reset to be used in submodule
   always_ff @(posedge clk) begin
      rst_reg <= '{default:rst};
   end

   always_ff @(posedge clk) begin
     rsp_fifo_rdy <= rsp_fifo_occ < RSP_FIFO_THRESHOLD;
   end
  
   //----------------------------------------------------------------------------------------
   // tcam request

   always_comb begin 
     lu2pars_tcam_req_fifo_rd = tcam_req_tready & !pars2lu_tcam_req_fifo_empty & rsp_fifo_rdy;

     tcam_req_tvalid = !pars2lu_tcam_req_fifo_empty & rsp_fifo_rdy;
     tcam_req_tid = '0;
     tcam_req_tuser_key = tuser_lu_key;
     tcam_req_tuser_usermetadata = '0;
   end

   //----------------------------------------------------------------------------------------
   // rsp_fifo

   always_comb begin
     tcam_rsp_tready = rsp_fifo_rdy;

     rsp_fifo_wr = tcam_rsp_tvalid & tcam_rsp_tready;

     tcam_rsp_usermetadata = '0;
   end
   
   packet_switch_ipbb_sdc_fifo_inff 
     #( .DWD ( 1
              +TCAM_RESULT_WIDTH
               )
       ,.RAM_BLOCK_TYPE ("MLAB")
       ,.NUM_WORDS (RSP_FIFO_DEPTH) ) rsp_fifo
     (//------------------------------------------------------------------------------------
      // clk/rst
      .clk1 (clk)
      ,.clk2 (clk)
      ,.rst (rst_reg[0])

      // inputs
      ,.din ({ tcam_rsp_tuser_found
              ,tcam_rsp_tuser_result
             })
      ,.wrreq (rsp_fifo_wr)
      ,.rdreq (rsp_fifo_rd)

      // outputs
      ,.dout ({ tcam_rsp_found,
                tcam_rsp_result
              }) 
      ,.rdempty (rsp_fifo_empty)
      ,.rdempty_lkahd () 
      ,.wrfull (rsp_fifo_full)
      ,.wrusedw (rsp_fifo_occ)
      ,.overflow (rsp_fifo_overflow)
      ,.underflow (rsp_fifo_underflow)
      );

endmodule
