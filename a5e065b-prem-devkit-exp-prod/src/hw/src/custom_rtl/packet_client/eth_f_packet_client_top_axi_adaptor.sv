//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


`timescale 1 ps / 1 ps
import sm_ptp_pkg::*;
module eth_f_packet_client_top_axi_adaptor #(
	parameter WIDTH		         = 64,
        parameter WORDS                  = 1,
        parameter EMPTY_WIDTH            = 6
    )(
	    
   	input   logic                                   i_arst,
        input   logic                                   i_clk_tx,
        input   logic                                   i_clk_rx,
 	
			  //---Avst 2 AXI TX IF---
				//AVST TX
        output   logic                     		o_avst_tx_ready,
        input  logic                       		i_avst_tx_valid,
        input  logic                       		i_avst_tx_sop,
        input  logic                       		i_avst_tx_eop,
        input  logic    [EMPTY_WIDTH-1:0]   		i_avst_tx_empty,
        input  logic    [WIDTH*WORDS-1:0]   		i_avst_tx_data,
        input  logic                       		i_avst_tx_error,
        input  logic                       		i_avst_tx_skip_crc,
        //input  logic   [WIDTH-1:0]            i_avst_tx_preamble,   // for 40/50G;
	
      //AXI TX	
        input logic                                     i_axis_tx_ready,
        output logic                                    o_axis_tx_valid,
        output logic    [WIDTH*WORDS-1:0]               o_axis_tx_tdata,
        output logic    [WIDTH*WORDS/8-1:0]             o_axis_tx_tkeep,
        output logic                                    o_axis_tx_tlast,
        //output logic    [511:0]	         	        o_axis_tx_tuser,
		  output logic    [AXIST_CTRL_USER_W-1:0]	         	        o_axis_tx_tuser,
			 
			 // AXI 2 AVST RX IF
   output logic     				o_axis_rx_ready,
	input  logic			                i_axis_rx_valid,
	input  logic    [WIDTH*WORDS-1:0]               i_axis_rx_tdata,
	input  logic                                    i_axis_rx_tlast,
	input  logic    [WIDTH*WORDS/8-1:0]             i_axis_rx_tkeep,
	//input  logic    [511:0]                         i_axis_rx_tuser,
	input  logic    [AXIST_CTRL_USER_W-1:0]                         i_axis_rx_tuser,

     // AVST Rx
   input logic                             	i_avst_rx_ready,
   output logic                          	o_avst_rx_valid,
	output logic    [WIDTH*WORDS-1:0]         	o_avst_rx_tdata,
	output logic    [EMPTY_WIDTH*WORDS-1:0]         	o_avst_rx_empty,
	output logic                            	o_avst_rx_sop,
	output logic                           	o_avst_rx_eop,
	output logic            o_tx_st_eop_sync_with_macsec_tuser_error	 		
	);
	
	logic [EMPTY_WIDTH-1:0] sop_empty_bytes,eop_empty_bytes;
	logic                   frame_in_prog;
	logic                   frame_start;
	logic                   frame_end;
        logic                   tmp_avst_rx_valid; 
        logic                   tmp_avst_rx_eop ;  
        logic                   tmp_avst_rx_sop ;  
        logic [EMPTY_WIDTH-1:0] tmp_avst_rx_empty ;
        logic [WIDTH*WORDS-1:0] tmp_avst_rx_tdata_shft;
        logic [WIDTH*WORDS-1:0] tmp_avst_rx_tdata;
      //  logic                   sop_empty_bytes;
      //  logic                   eop_empty_bytes;
	//avst 2 axi Tx Path
        logic [31:0] tlast_seg;
        assign tlast_seg = (WORDS*WIDTH==64)? '0 : (WORDS*WIDTH/64 -1 - i_avst_tx_empty[EMPTY_WIDTH-1:3]);//WORDS*WIDTH/64 -1 - i_avst_tx_empty[EMPTY_WIDTH-1:3];

        always_comb begin
        o_axis_tx_tuser = 0;

        o_axis_tx_tuser[tlast_seg] = i_avst_tx_eop;
    
        end
        assign  o_avst_tx_ready =  i_axis_tx_ready;
        assign 	o_axis_tx_valid =  i_avst_tx_valid;
	assign  o_axis_tx_tlast =  i_avst_tx_eop;
	assign  o_axis_tx_tkeep =  i_avst_tx_eop ? ({(WIDTH*WORDS/8){1'b1}} >> i_avst_tx_empty) : {(WIDTH*WORDS/8){1'b1}};
	genvar j;
	generate for (j=0;j<(WIDTH*WORDS/8);j++) begin : data_byte_flip_tx
         assign o_axis_tx_tdata[j*8 +: 8] =  i_avst_tx_data[WIDTH*WORDS-j*8-1 -: 8];
        end endgenerate

       // axi 2 avst Rx Path
	assign frame_start = i_axis_rx_valid ? o_axis_rx_ready : 1'b0;
	assign frame_end   = i_axis_rx_valid ? o_axis_rx_ready & i_axis_rx_tlast : 1'b0;
  
	always @(posedge i_clk_rx, negedge i_arst) begin
        if(!i_arst) begin
         frame_in_prog <= 1'b0;
        end else begin
        frame_in_prog <= (frame_in_prog | frame_start) & ~frame_end;
        end
        end	

        always @*
        begin
          eop_empty_bytes = 0;
          for(int i=0;i<WORDS*WIDTH/8;i++)
          if(!i_axis_rx_tkeep[WORDS*WIDTH/8-1-i])
           eop_empty_bytes = i+1;
        end

        always @*
        begin
        sop_empty_bytes = 0;
        for(int i=0;i<WORDS*WIDTH/8;i++)
        if(!i_axis_rx_tkeep[i])
          sop_empty_bytes = i+1;
        end


	genvar k;
	
	
        //assign o_axis_rx_ready =   i_avst_rx_ready;
	assign tmp_avst_rx_valid = i_axis_rx_valid;
	assign tmp_avst_rx_eop   = i_axis_rx_tlast;
	assign tmp_avst_rx_sop   = i_axis_rx_valid & ~frame_in_prog;
	assign tmp_avst_rx_empty = i_axis_rx_tlast ? eop_empty_bytes :  tmp_avst_rx_sop? sop_empty_bytes :  {(WIDTH*WORDS/8){1'b0}};
	
	generate for (k=0;k<(WIDTH*WORDS/8);k++) begin : data_byte_flip_rx
		assign o_avst_rx_tdata [k*8 +: 8] = tmp_avst_rx_tdata [WIDTH*WORDS-k*8-1 -: 8];
	end
	endgenerate

        assign tmp_avst_rx_tdata_shft = tmp_avst_rx_sop? i_axis_rx_tdata >> (sop_empty_bytes*8) : i_axis_rx_tdata;


       avst_data_merger #(
       .WIDTH( WIDTH),
		 .WORDS(WORDS), 
       .CWIDTH ( 2                ) // Channel Width
       //.EWIDTH ( $clog2(DWIDTH/8) )  // Empty Width
       ) data_pack (
       .clk_i           (i_clk_rx),
       .rst_n_i         (i_arst),
       .rx_st_sop_i     (tmp_avst_rx_sop),
       .rx_st_eop_i     (tmp_avst_rx_eop),
       .rx_st_valid_i   (tmp_avst_rx_valid),
       .rx_st_data_i    (tmp_avst_rx_tdata_shft),
       .rx_st_empty_i   (tmp_avst_rx_empty),
       .rx_st_channel_i ('d0)      ,
       .rx_st_ready_o   (o_axis_rx_ready),
       .tx_st_sop_o     (o_avst_rx_sop),
       .tx_st_eop_o     (o_avst_rx_eop),
       .tx_st_valid_o   (o_avst_rx_valid),
       .tx_st_data_o    (tmp_avst_rx_tdata),
       .tx_st_empty_o   (o_avst_rx_empty),
       .tx_st_channel_o (),
		 .tx_st_eop_sync_with_macsec_tuser_error (o_tx_st_eop_sync_with_macsec_tuser_error),
       .tx_st_ready_i   (i_avst_rx_ready)
       );
//assign o_avst_rx_empty[EMPTY_WIDTH-1]=1'b0;

endmodule	
