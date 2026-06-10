//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


//////////////////////////////////////////////////////////////////////////////////////////////
// Description:
// Combine 2 cycles of tdata (512b) into 1 cycle of hdr_data (1024b) for further 
// hdr processing.
//
//////////////////////////////////////////////////////////////////////////////////////////////
//`default_nettype none
module parse_class_igr_intf
   #( parameter TDATA_WIDTH                 = 512
     ,parameter USERMETADATA_WIDTH          = 1
     ,parameter SEGMENT_WIDTH               = 128
     ,parameter SEGMENT_DEPTH               = TDATA_WIDTH/SEGMENT_WIDTH // 4
     ,parameter ALN_FIFO_DEPTH              = 512
   ) 

  (
    //----------------------------------------------------------------------------------------
    // Clocks
    input var logic                                    clk

    //----------------------------------------------------------------------------------------
    // Resets 
    ,input var logic                                   rst

    //----------------------------------------------------------------------------------------
    // ingress interface
    ,input var logic                                   tvalid
    ,input var logic [SEGMENT_DEPTH-1:0]
                       [SEGMENT_WIDTH-1:0]             tdata
    ,input var logic [TDATA_WIDTH/8-1:0]               tkeep
    ,input var logic [USERMETADATA_WIDTH-1:0]          tuser_usermetadata
    ,input var packet_switch_pkg::SEGMENT_INFO_S          tuser_segment_info

    //----------------------------------------------------------------------------------------
    // parse_class_l2l3l4 interface
    ,output var logic                                  hdr_vld
    ,output var logic [SEGMENT_DEPTH*2-1:0]
                        [SEGMENT_WIDTH-1:0]            hdr_data
    ,output var packet_switch_pkg::SEGMENT_INFO_S         hdr_segment_info

    //----------------------------------------------------------------------------------------
    // align fifo interface
    ,output var logic [SEGMENT_DEPTH-1:0]
                        [SEGMENT_WIDTH-1:0]            aln_fifo_tdata
    ,output var logic [USERMETADATA_WIDTH-1:0]         aln_fifo_tuser_usermetadata
    ,output var packet_switch_pkg::SEGMENT_INFO_S         aln_fifo_tuser_segment_info
    ,output var logic                                  aln_fifo_rdy
    ,output var logic                                  aln_fifo_empty
    ,input  var logic                                  aln_fifo_pop
   );
   import packet_switch_pkg::*;
   import packet_switch_hdr_pkg::*;

   localparam ALN_FIFO_THRESHOLD = ALN_FIFO_DEPTH - 32;
   localparam TKEEP_WIDTH = TDATA_WIDTH/8;
   
   logic [1:0] hdr_cyc_cnt;
   logic [SEGMENT_DEPTH-1:0][SEGMENT_WIDTH-1:0] hdr_data_reg, tmp_hdr_data_0,
                                                hdr_data_zeros;

   logic [$clog2(ALN_FIFO_DEPTH)-1:0] aln_fifo_occ;

   logic aln_fifo_full, aln_fifo_overflow, aln_fifo_underflow, tmp;

   logic                                   tvalid_c0, tvalid_c1, tvalid_c2;
   logic [TDATA_WIDTH/8-1:0]               tkeep_c0;
   logic [SEGMENT_DEPTH-1:0]
           [SEGMENT_WIDTH-1:0]             tdata_c0, tdata_c1, tdata_c2;
   logic [USERMETADATA_WIDTH-1:0]          tuser_usermetadata_c0, tuser_usermetadata_c1, 
     tuser_usermetadata_c2;
   packet_switch_pkg::SEGMENT_INFO_S          tuser_segment_info_c0, tuser_segment_info_c1, 
     tuser_segment_info_c2;

   always_ff @(posedge clk) begin
     // calculate bytesvld
     tvalid_c1 <= tvalid;
     tdata_c1 <= tdata;
     tuser_usermetadata_c1 <= tuser_usermetadata;
     tuser_segment_info_c1.sop            <= tuser_segment_info.sop;
	 tuser_segment_info_c1.eop            <= tuser_segment_info.eop;
	 tuser_segment_info_c1.sos            <= tuser_segment_info.sos;
	 tuser_segment_info_c1.eos            <= tuser_segment_info.eos;
	 tuser_segment_info_c1.bytesvld       <= tkeep_bytesvld(tkeep);
	 tuser_segment_info_c1.hdr_segment    <= tuser_segment_info.hdr_segment;
	 tuser_segment_info_c1.payld_segment  <= tuser_segment_info.payld_segment;
	 tuser_segment_info_c1.igr_port       <= tuser_segment_info.igr_port;  
	 tuser_segment_info_c1.egr_port       <= tuser_segment_info.egr_port;
	 tuser_segment_info_c1.multicast_port <= '0;
	 tuser_segment_info_c1.multicast_en   <= '0;

     // mask off unused bytes
     tvalid_c2 <= tvalid_c1;
     tdata_c2 <= packet_switch_pkg::fn_mask_bytesvld_64(tuser_segment_info_c1.bytesvld) & tdata_c1;
     tuser_usermetadata_c2 <= tuser_usermetadata_c1;
     tuser_segment_info_c2 <= tuser_segment_info_c1;
   end

   // aln_fifo_rdy
   always_ff @(posedge clk) begin
     aln_fifo_rdy <= aln_fifo_occ < ALN_FIFO_THRESHOLD;
   end
   
   // hdr_cyc_cnt
   always_ff @(posedge clk) begin
     if (rst) begin
       hdr_cyc_cnt <= 'h1;
     end else begin
       if (tvalid_c2 & tuser_segment_info_c2.eop)
         hdr_cyc_cnt <= 'h1;
       else if (tvalid_c2 & !(hdr_cyc_cnt == '1))
         {tmp, hdr_cyc_cnt} <= hdr_cyc_cnt + 'h1;
     end
   end // always_ff

   always_ff @(posedge clk) begin
       // hdr_data_reg
       if (tvalid_c2 & tuser_segment_info_c2.sop & !tuser_segment_info_c2.eop)
         hdr_data_reg <= tdata_c2; // sop
       else if (tvalid_c2 & tuser_segment_info_c2.sop & tuser_segment_info_c2.eop)
         hdr_data_reg <= '0; // sop + eop

       //  hdr_segment_info
       if (tvalid_c2 & tuser_segment_info_c2.sop)
         hdr_segment_info <= tuser_segment_info_c2; // any sop
   end // always_ff

   always_comb begin
     hdr_data_zeros = 512'h0;

    if (tvalid_c2) begin
      case ({tuser_segment_info_c2.sop, tuser_segment_info_c2.eop}) 
        // sop, eop 
        2'b00: begin
           if (hdr_cyc_cnt == 'h2) begin
             hdr_vld = '1;
             hdr_data = {hdr_data_reg, tdata_c2};
           end else begin
             hdr_vld = '0;
             hdr_data = {tdata_c2 ,hdr_data_zeros};
           end
        end

        // sop, eop 
        2'b01: begin
           if (hdr_cyc_cnt == 'h2) begin
             hdr_vld = '1;
             hdr_data = {hdr_data_reg, tdata_c2};
           end else begin
             hdr_vld = '0;
             hdr_data = {tdata_c2 ,hdr_data_zeros};
           end
        end

        // sop, eop 
        2'b10: begin
           hdr_vld = '0;
           hdr_data = {tdata_c2 ,hdr_data_zeros};
        end

        // sop, eop 
        2'b11: begin
           hdr_vld = '1;
           hdr_data = {tdata_c2 ,hdr_data_zeros};
        end
      endcase
    end else begin
      hdr_vld = '0;
      hdr_data = {tdata_c2 ,hdr_data_zeros};
    end // if (tvalid_c2)
   end // always_comb

/*
  packet_switch_pipe_dly #( 
             .W( TDATA_WIDTH
                + USERMETADATA_WIDTH
                + SEGMENT_INFO_WIDTH 
                ),
             .N(2)) pipe_dly
         (.clk (clk)
         ,.dIn ({ tdata
                 ,tuser_usermetadata
                 ,tuser_segment_info
                })
         ,.dOut ({ aln_tdata
                  ,aln_tuser_usermetadata
                  ,aln_tuser_segment_info
                 }));
*/

   packet_switch_ipbb_sdc_fifo_inff 
     #( .DWD ( TDATA_WIDTH
               +USERMETADATA_WIDTH
               +SEGMENT_INFO_WIDTH 
              )
       ,.NUM_WORDS (ALN_FIFO_DEPTH) ) aln_fifo
     (//------------------------------------------------------------------------------------
      // clk/rst
      .clk1 (clk)
      ,.clk2 (clk)
      ,.rst (rst)

      // inputs
      ,.din ({ tdata_c1
              ,tuser_usermetadata_c1
              ,tuser_segment_info_c1
              })
      ,.wrreq (tvalid_c1)
      ,.rdreq (aln_fifo_pop)

      // outputs
      ,.dout ({ aln_fifo_tdata
               ,aln_fifo_tuser_usermetadata
               ,aln_fifo_tuser_segment_info
               }) 
      ,.rdempty (aln_fifo_empty)
      ,.rdempty_lkahd ()
      ,.wrfull (aln_fifo_full)
      ,.wrusedw (aln_fifo_occ)
      ,.overflow (aln_fifo_overflow)
      ,.underflow (aln_fifo_underflow)
      );

	function [$clog2(TKEEP_WIDTH):0] tkeep_bytesvld;
	input logic [TKEEP_WIDTH-1:0] din;
	begin
	    logic [$clog2(TKEEP_WIDTH):0] tmp_sum;
	    logic [$clog2(TKEEP_WIDTH)-1:0] tmp_cnt;
	    
	    tmp_cnt = '0;
	    
	    for (int i = 0; i < TKEEP_WIDTH ; i++) begin
		
		tmp_sum = tmp_cnt + din[i];
		tmp_cnt = tmp_sum[$clog2(TKEEP_WIDTH)-1:0];		
	    end // for 
	    tkeep_bytesvld  = tmp_sum;	    
	end
    endfunction
   
endmodule
