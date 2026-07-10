
//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

module cdc_packet_fifo #(
    parameter int         MEMORY_CAPACITY_WORDS       = 256
   ,parameter int         AVST_DATA_WIDTH             = 64//has to be 32 or 64
   ,parameter int         AVST_ERROR_WIDTH            = 1
   ,parameter int         AVST_USER_WIDTH             = 12
   ,localparam int        AVST_EMPTY_WIDTH            = components_pkg::get_width(AVST_DATA_WIDTH)-3
   ,localparam int        MEMORY_ADDRESS_WIDTH        = components_pkg::get_width(MEMORY_CAPACITY_WORDS)
      //Registers addresses
) (
/* fill_level
* - works on out_avst_clk
* - is provided in number of words of MEMORY_DATA_WIDTH filled in pkt fifo
* - depends on MEMORY_CAPACITY_WORDS
*/

    input  logic                             in_avst_clk
   ,input  logic                             in_avst_reset
   ,output logic                             in_avst_ready
   ,input  logic                             in_avst_valid
   ,input  logic                             in_avst_startofpacket
   ,input  logic                             in_avst_endofpacket
   ,input  logic [AVST_EMPTY_WIDTH-1:0]      in_avst_empty
   ,input  logic [AVST_DATA_WIDTH-1:0]       in_avst_data
   ,input  logic [AVST_ERROR_WIDTH-1:0]      in_avst_error
   ,input  logic [AVST_USER_WIDTH-1:0]       in_avst_user

   ,input  logic                             out_avst_clk
   ,input  logic                             out_avst_reset
   ,input  logic                             out_avst_ready
   ,output logic                             out_avst_valid
   ,output logic                             out_avst_startofpacket
   ,output logic                             out_avst_endofpacket
   ,output logic [AVST_EMPTY_WIDTH-1:0]      out_avst_empty
   ,output logic [AVST_DATA_WIDTH-1:0]       out_avst_data
   ,output logic [AVST_USER_WIDTH-1:0]       out_avst_user

);

   localparam int    MEMORY_DATA_WIDTH       = AVST_DATA_WIDTH + 2 + AVST_EMPTY_WIDTH + AVST_USER_WIDTH;
   logic [MEMORY_DATA_WIDTH-1:0]             write_data, read_data  /* synthesis syn_keep = "true"  */;
   logic                                     wrfull, rdempty, pkt_wen, pkt_ren, pkt_full, pkt_empty, wrreq, rdreq  /* synthesis syn_keep = "true"  */;
	logic [31:0]                              wr_pkt_cnt, rd_pkt_cnt /* synthesis syn_keep = "true"  */;
	
		 
   always_comb begin
      write_data = {in_avst_startofpacket, in_avst_endofpacket, in_avst_data, in_avst_empty, in_avst_user};
	  {out_avst_startofpacket, out_avst_endofpacket, out_avst_data, out_avst_empty, out_avst_user} = rdreq ? read_data : '0;
      out_avst_valid = rdreq;
	end

	
   assign in_avst_ready = 	!wrfull;
   assign wrreq         =  in_avst_valid & (!wrfull);
   assign rdreq         =  (!rdempty) && (!pkt_empty) && out_avst_ready;
	
	  
   dc_fifo_param #(
       .ADDR_WIDTH     (MEMORY_ADDRESS_WIDTH)
      ,.DATA_WIDTH     (MEMORY_DATA_WIDTH)
      ,.RAM_BLOCK_TYPE ("M20K") //MLAB or M20K
      ,.NUMBER_WORDS   (0)
   ) cdc_fifo (
      //wr clk domain
       .wrclk  (in_avst_clk)
      ,.wrreq  (wrreq)
      ,.wrfull (wrfull)
      ,.data   (write_data)
      //rd clk domain
      ,.rdclk  (out_avst_clk)
      ,.aclr   (out_avst_reset)
      ,.rdreq  (rdreq)
      ,.q      (read_data)
      ,.rdempty(rdempty)
   );
	
  always_comb begin
    pkt_wen = in_avst_valid & (!pkt_full) & in_avst_endofpacket;
	 pkt_ren = out_avst_endofpacket & (!pkt_empty) && out_avst_ready;
  end
		
  always @(posedge in_avst_clk or posedge in_avst_reset) 
    if(in_avst_reset)  
 	  begin
  	    wr_pkt_cnt <= '0;
 	  end
    else if (in_avst_valid && (!wrfull) && in_avst_endofpacket)
 	  begin
  	 	 wr_pkt_cnt <= wr_pkt_cnt + 1'b1;
 	  end
     
  dc_fifo_param #(
       .ADDR_WIDTH     (MEMORY_ADDRESS_WIDTH)
      ,.DATA_WIDTH     (32)
      ,.RAM_BLOCK_TYPE ("M20K") //MLAB or M20K
      ,.NUMBER_WORDS   (0)
   ) cdc_fifo_pkt_boundary (
      //wr clk domain
       .wrclk  (in_avst_clk)
      ,.wrreq  (pkt_wen)
      ,.wrfull (pkt_full)
      ,.data   (wr_pkt_cnt)
      //rd clk domain
      ,.rdclk  (out_avst_clk)
      ,.aclr   (out_avst_reset)
      ,.rdreq  (pkt_ren)
      ,.q      (rd_pkt_cnt)
      ,.rdempty(pkt_empty)
   );
	
endmodule
