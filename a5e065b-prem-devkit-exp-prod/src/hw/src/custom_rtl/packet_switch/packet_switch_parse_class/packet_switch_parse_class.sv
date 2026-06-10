//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

//`default_nettype none
module packet_switch_parse_class
   #( parameter TDATA_WIDTH                 = 512
     ,parameter INST_ID                     = 0
     ,parameter USERMETADATA_WIDTH          = 1
   ) 

  (
    //----------------------------------------------------------------------------------------
    // Clocks
    input var logic                                    clk

    //----------------------------------------------------------------------------------------
    // Resets 
    ,input var logic                                   rst

    //----------------------------------------------------------------------------------------
    // ingress arbiter interface
    ,input var logic                                   iwadj2pars_tvalid
    ,input var logic [TDATA_WIDTH-1:0]                 iwadj2pars_tdata
    ,input var logic [TDATA_WIDTH/8-1:0]               iwadj2pars_tkeep
    ,input var logic [USERMETADATA_WIDTH-1:0]          iwadj2pars_tuser_usermetadata
    ,input var packet_switch_pkg::SEGMENT_INFO_S          iwadj2pars_tuser_segment_info
    
    ,output var logic                                  pars2iwadj_tready

    //----------------------------------------------------------------------------------------
    // lookup interface
    ,output var logic                                  pars2lu_tvalid
    ,output var logic [TDATA_WIDTH-1:0]                pars2lu_tdata
    ,output var logic [USERMETADATA_WIDTH-1:0]         pars2lu_tuser_usermetadata
    ,output var packet_switch_pkg::SEGMENT_INFO_S         pars2lu_tuser_segment_info
    ,output var packet_switch_pkg::tuple_map_S            pars2lu_tuser_tuple_map // vld at sop
     
    // ,input var logic                                   lu2pars_tready
    ,input var logic                                   lu2pars_fifo_rd
    ,output var logic                                  pars2lu_fifo_empty
    
    ,output var logic                                  pars2lu_tcam_req_fifo_empty
    ,input var logic                                   lu2pars_tcam_req_fifo_rd

   );
   import packet_switch_pkg::*;

   localparam CLASSIFY_FIFO_DEPTH = 16;
   localparam CLASSIFY_FIFO_THRESHOLD = CLASSIFY_FIFO_DEPTH - 8;

   packet_switch_pkg::SEGMENT_INFO_S hdr_segment_info, aln_tuser_segment_info;

   packet_switch_pkg::tuple_map_S    classify_tuser_tuple_map;
   packet_switch_hdr_pkg::HDR_ID_e   classify_hdr_id, dbg_hdr_id;

   logic [(TDATA_WIDTH*2)-1:0]    hdr_data;

   logic [TDATA_WIDTH-1:0]        aln_tdata;

   logic [USERMETADATA_WIDTH-1:0] aln_tuser_usermetadata;

   packet_switch_pkg::tuple_map_S classify_fifo_tuser_tuple_map;
   packet_switch_hdr_pkg::HDR_ID_e classify_fifo_hdr_id;

   logic [$clog2(CLASSIFY_FIFO_DEPTH)-1:0] classify_fifo_occ;

   logic hdr_vld, classify_tvalid, aln_fifo_pop, aln_fifo_empty, 
     aln_eop_state, aln_fifo_rdy,
     classify_fifo_pop, classify_fifo_empty, classify_fifo_full,
     classify_fifo_rdy;
   
   logic [31:0] rst_reg;
   // Generate arrays of reset to be used in submodule
   always_ff @(posedge clk) begin
      rst_reg <= '{default:rst};
   end

   always_ff @(posedge clk) begin
     classify_fifo_rdy <= classify_fifo_occ < CLASSIFY_FIFO_THRESHOLD;

     pars2iwadj_tready <= aln_fifo_rdy & classify_fifo_rdy;
   end 

   //-------------------------------------------------------------------------------------
   // parse_class_igr_intf
   
   parse_class_igr_intf
      #( .TDATA_WIDTH (TDATA_WIDTH) 
        ,.USERMETADATA_WIDTH (USERMETADATA_WIDTH)
      ) parse_class_igr_intf_inst 
       (//------------------------------------------------------------------------------------
       // Clocks
       .clk (clk)

       // Resets 
       ,.rst (rst_reg[0])

       //-------------------------------------------------------------------------------------
       // ingress arbiter interface
       // inputs
       ,.tvalid             (iwadj2pars_tvalid)
       ,.tdata              (iwadj2pars_tdata)
       ,.tkeep              (iwadj2pars_tkeep)
       ,.tuser_usermetadata (iwadj2pars_tuser_usermetadata)
       ,.tuser_segment_info (iwadj2pars_tuser_segment_info)

       //-------------------------------------------------------------------------------------
       // parse_class_l2l3l4 interface
       // outputs
       ,.hdr_vld          (hdr_vld)
       ,.hdr_data         (hdr_data)
       ,.hdr_segment_info (hdr_segment_info)

       //-------------------------------------------------------------------------------------
       // align fifo interface
       // outputs
       ,.aln_fifo_tdata              (aln_tdata)
       ,.aln_fifo_tuser_usermetadata (aln_tuser_usermetadata)
       ,.aln_fifo_tuser_segment_info (aln_tuser_segment_info)
       ,.aln_fifo_rdy                (aln_fifo_rdy) 
       ,.aln_fifo_empty              (pars2lu_fifo_empty) 
       // inputs
       ,.aln_fifo_pop                (lu2pars_fifo_rd)
   );

   //-------------------------------------------------------------------------------------
   // parse_class_l2l3l4

   parse_class_l2l3l4
      #( .TDATA_WIDTH (TDATA_WIDTH) ) parse_class_l2l3l4_inst 
       (//------------------------------------------------------------------------------------
       // Clocks
       .clk (clk)

       // Resets 
       ,.rst (rst_reg[1])

       //-------------------------------------------------------------------------------------
       // parse_class_igr_intf
       // inputs
       ,.hdr_vld (hdr_vld)
       ,.hdr_data (hdr_data)
       ,.hdr_segment_info (hdr_segment_info)

       //-------------------------------------------------------------------------------------
       // classify interface   
       // outputs
       ,.classify_tvalid (classify_tvalid)
       ,.classify_tuser_tuple_map (classify_tuser_tuple_map)
       ,.classify_hdr_id (classify_hdr_id)
      );

   // order: tcam request interface first, then packet interface
   always_comb begin
     pars2lu_tvalid = lu2pars_fifo_rd;
     pars2lu_tdata = aln_tdata;
     pars2lu_tuser_usermetadata = aln_tuser_usermetadata;
     pars2lu_tuser_segment_info = aln_tuser_segment_info;

     // tcam request interface
     pars2lu_tuser_tuple_map = classify_fifo_tuser_tuple_map;
     dbg_hdr_id = classify_fifo_hdr_id;
     pars2lu_tcam_req_fifo_empty = classify_fifo_empty;

   end

  packet_switch_ipbb_sdc_fifo_inff 
     #( .DWD ( packet_switch_pkg::tuple_map_width
              +packet_switch_hdr_pkg::hdr_id_width
              )
       ,.RAM_BLOCK_TYPE ("MLAB")
       ,.NUM_WORDS (CLASSIFY_FIFO_DEPTH) ) classify_fifo
     (//------------------------------------------------------------------------------------
      // clk/rst
      .clk1 (clk)
      ,.clk2 (clk)
      ,.rst (rst)

      // inputs
      ,.din ({ classify_tuser_tuple_map
              ,classify_hdr_id
              })
      ,.wrreq (classify_tvalid)
      ,.rdreq (lu2pars_tcam_req_fifo_rd)

      // outputs
      ,.dout ({ classify_fifo_tuser_tuple_map
               ,classify_fifo_hdr_id
               }) 
      ,.rdempty (classify_fifo_empty)
      ,.rdempty_lkahd ()
      ,.wrfull (classify_fifo_full)
      ,.wrusedw (classify_fifo_occ)
      ,.overflow ()
      ,.underflow ()
      );


   //------------------------------------------------------------------------------------------
   // debug printouts

   `ifdef DBG_STMT_ON

   // synopsys translate_off
  
   logic [31:0] igr_cnt, egr_cnt, tcam_req;

   always_ff @(posedge clk) begin
      // igr_cnt
      if (iwadj2pars_tvalid & pars2iwadj_tready & iwadj2pars_tuser_segment_info.eop) begin
        igr_cnt <= igr_cnt + 1'b1;
      end

      if (iwadj2pars_tvalid & pars2iwadj_tready) begin
	 $display("[PD_DBG] rx_pipe id:%0d parse_class: igr_cnt='d%0d; data='h%0h; sop='h%0h; eop='h%0h; time=%0t"
          ,INST_ID
          ,igr_cnt
          ,iwadj2pars_tdata
		  ,iwadj2pars_tuser_segment_info.sop
		  ,iwadj2pars_tuser_segment_info.eop
		  ,$time);
      end

      // egr_cnt
      if (pars2lu_tvalid & pars2lu_tuser_segment_info.eop) begin
        egr_cnt <= egr_cnt + 1'b1;
      end

 	  if (pars2lu_tvalid) begin
	 $display("[PD_DBG] rx_pipe id:%0d parse_class: egr_cnt='d%0d; data='h%0h; sop='h%0h; eop='h%0h; time=%0t"
          ,INST_ID
          ,egr_cnt
          ,pars2lu_tdata
          ,pars2lu_tuser_segment_info.sop
          ,pars2lu_tuser_segment_info.eop
		  ,$time);
      end

      // tcam_req
      if (lu2pars_tcam_req_fifo_rd) begin
        tcam_req <= tcam_req + 1'b1;
      end

 	  if (lu2pars_tcam_req_fifo_rd) begin
	 $display("[PD_DBG] rx_pipe id:%0d parse_class: tcam_req='d%0d; time=%0t"
          ,INST_ID
          ,tcam_req
		  ,$time);

	 $display("[PD_DBG] rx_pipe id:%0d parse_class: tcam_req='d%0d; hdr_id= %0s;"
          ,INST_ID
          ,tcam_req
          ,dbg_hdr_id);

	 $display("[PD_DBG] rx_pipe id:%0d parse_class: tcam_req='d%0d; flagField='h%0h; messageType='h%0h;"
          ,INST_ID
          ,tcam_req
          ,pars2lu_tuser_tuple_map.flagField
          ,pars2lu_tuser_tuple_map.messageType);

	 $display("[PD_DBG] rx_pipe id:%0d parse_class: tcam_req='d%0d; ip_protocol='h%0h; ethtype='h%0h;"
          ,INST_ID
          ,tcam_req
          ,pars2lu_tuser_tuple_map.ip_protocol
          ,pars2lu_tuser_tuple_map.ethtype);

	 $display("[PD_DBG] rx_pipe id:%0d parse_class: tcam_req='d%0d; tci_vlana='h%0h; tci_vlanb='h%0h;"
          ,INST_ID
          ,tcam_req
          ,pars2lu_tuser_tuple_map.tci_vlana
          ,pars2lu_tuser_tuple_map.tci_vlanb);

	 $display("[PD_DBG] rx_pipe id:%0d parse_class: tcam_req='d%0d; l4_src_port='h%0h; l4_dst_port='h%0h;"
          ,INST_ID
          ,tcam_req
          ,pars2lu_tuser_tuple_map.l4_src_port                        
          ,pars2lu_tuser_tuple_map.l4_dst_port);

	 $display("[PD_DBG] rx_pipe id:%0d parse_class: tcam_req='d%0d; src_ip='h%0h; dst_ip='h%0h;"
          ,INST_ID
          ,tcam_req
          ,pars2lu_tuser_tuple_map.src_ip                        
          ,pars2lu_tuser_tuple_map.dst_ip);

	 $display("[PD_DBG] rx_pipe id:%0d parse_class: tcam_req='d%0d; src_mac='h%0h; dst_mac='h%0h;"
          ,INST_ID
          ,tcam_req
          ,pars2lu_tuser_tuple_map.src_mac
          ,pars2lu_tuser_tuple_map.dst_mac);

      end

      if (rst) begin
        igr_cnt <= '0;
        egr_cnt <= '0;
        tcam_req <= '0;
      end
   end		
   // synopsys translate_on
 `endif


endmodule
