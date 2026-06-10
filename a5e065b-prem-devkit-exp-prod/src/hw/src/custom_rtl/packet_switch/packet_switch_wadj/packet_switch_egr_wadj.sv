//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


//////////////////////////////////////////////////////////////////////////////////////////////
// Description:
// 
// 
// ------------------------------------------------------------------------------------------
//                 |                |                     | HSSI/USER  |                    |
// Core Data Width | Core Seg Width | HSSI/USER Interface | Data Width |   wadj type        | 
// ------------------------------------------------------------------------------------------
//       512       |       64       |      10G            |    64      | lg2sm (8 to 1)
//       512       |       64       |      25G            |    64      | lg2sm (8 to 1)
//       512       |       128      |      40/50G         |    128     | lg2sm (4 to 1)
//       512       |       512      |      100G           |    512     | lg2sm (1 to 1)
// ------------------------------------------------------------------------------------------
//
//////////////////////////////////////////////////////////////////////////////////////////////

module packet_switch_egr_wadj
   #( parameter DEVICE_FAMILY               = "Agilex"
     ,parameter IGR_SEG_WIDTH               = 512
     ,parameter IGR_NUM_SEG                 = 1
     ,parameter IGR_TDATA_WIDTH             = IGR_SEG_WIDTH*IGR_NUM_SEG
     // ,parameter EGR_SEG_WIDTH               = IGR_SEG_WIDTH
     ,parameter EGR_NUM_SEG                 = 1 // only 1 is supported.
     ,parameter EGR_TDATA_WIDTH             = 128
     ,parameter ITUSER_MD_WIDTH             = 1
     ,parameter ETUSER_MD_WIDTH             = 1   
     ,parameter NUM_IGR_FIFOS               = 12
     ,parameter IGR_FIFO_DEPTH              = 512
     ,parameter SFW_ENABLE                  = 0 // enable store-and-fwd FIFO.
     ,parameter EGR_FIFO_DEPTH              = 512
     ,parameter BYTE_ROTATE                 = 1
     ,parameter WADJ_ID                     = "DMA" // width adjuster ID. "DMA" or "USER"
     ,parameter BASE_ADDR                   = 'h0
     ,parameter MAX_ADDR                    = 'h8
     ,parameter ADDR_WIDTH                  = 8
     ,parameter DATA_WIDTH                  = 32

   ) 

  (
    //----------------------------------------------------------------------------------------
    // Clocks
     input var logic                                   clk

    //----------------------------------------------------------------------------------------
    // Resets 
    ,input var logic                                   rst

    //-----------------------------------------------------------------------------------------
    // ingress interface
    ,input var logic                                   axi_st_tvalid_i
    ,input var logic [IGR_NUM_SEG-1:0]
                      [IGR_SEG_WIDTH-1:0]              axi_st_tdata_i
    ,input var logic [IGR_TDATA_WIDTH/8-1:0]           axi_st_tkeep_i
    ,input var logic [ITUSER_MD_WIDTH-1:0]             axi_st_tuser_usermetadata_i
    ,input var packet_switch_pkg::SEGMENT_INFO_S          axi_st_tuser_segment_info_i
    
    ,output var logic                                  axi_st_tready_o

    //-----------------------------------------------------------------------------------------
    // egress interface
    ,output var logic                                  axi_st_tvalid_o
    ,output var logic [EGR_TDATA_WIDTH-1:0]            axi_st_tdata_o
    ,output var logic [EGR_TDATA_WIDTH/8-1:0]          axi_st_tkeep_o
    ,output var logic                                  axi_st_tlast_o
    ,output var logic [EGR_NUM_SEG-1:0]                axi_st_tuser_last_segment_o
    ,output var logic [ETUSER_MD_WIDTH-1:0]            axi_st_tuser_usermetadata_o
    ,output var packet_switch_pkg::SEGMENT_INFO_S         axi_st_tuser_segment_info_o
     
    ,input var logic                                   axi_st_tready_i

    //-----------------------------------------------------------------------------------------
    // AVMM interface

    ,input var logic [ADDR_WIDTH-1:0]     avmm_address
    ,input var logic                      avmm_read
    ,output var logic [DATA_WIDTH-1:0]    avmm_readdata 
    ,input var logic                      avmm_write
    ,input var logic [DATA_WIDTH-1:0]     avmm_writedata
    ,input var logic [(DATA_WIDTH/8)-1:0] avmm_byteenable
    ,output var logic                     avmm_readdata_valid

    ,output var logic                     dbg_cnt_drop_en

    //----------------------------------------------------------------

   );
   import packet_switch_pkg::*;

   localparam EGR_FIFO_THRESHOLD = EGR_FIFO_DEPTH - 16;

   localparam IGR_TKEEP_WIDTH = IGR_TDATA_WIDTH/8;
   // localparam IKEEP_SEG_WIDTH = IGR_TKEEP_WIDTH/IGR_NUM_SEG;

   localparam EGR_BYTESVLD_WIDTH = $clog2((EGR_TDATA_WIDTH)/8);
   localparam EGR_TKEEP_WIDTH = EGR_TDATA_WIDTH/8;

   localparam IFIFO_DEPTH         = 512;
   localparam IFIFO_WIDTH         = $clog2(IFIFO_DEPTH);
   
   localparam EFIFO_DEPTH         = 512;
   localparam EFIFO_WIDTH         = $clog2(EFIFO_DEPTH);

   packet_switch_pkg::SEGMENT_INFO_S axi_wdj_tuser_segment_info, 
     sfw_fifo_tuser_segment_info, ct_fifo_tuser_segment_info;

   logic dwadj_rdy, dwadj_sop, dwadj_eop, dwadj_vld, egr_fifo_rdy,
         egr_cdc_fifo_rd, egr_cdc_fifo_empty, egr_cdc_fifo_full,
         sfw_fifo_wr, sfw_fifo_rd, sfw_fifo_rel_ptr, sfw_fifo_full, 
         sfw_fifo_empty, sfw_fifo_sop, sfw_fifo_eop, axi_wdj_tvalid,
         axi_wdj_tlast, rst_reg_c1, rst_reg_c2, rst_reg_c3,
         rst_reg_posedge, rst_req_state, sop_state, sfw_fifo_hi_wm,
         sfw_fifo_tlast, sfw_fifo_tlast_segment, ct_fifo_rd,
         ct_fifo_tlast, ct_fifo_empty,
         ct_fifo_full, ct_fifo_overflow, ct_fifo_underflow,
         egr_sop_state;

   logic [$clog2((EGR_TDATA_WIDTH)/8)-1:0] dwadj_bytesvld;

   logic [ETUSER_MD_WIDTH-1:0] dwadj_tuser, egr_cdc_fifo_tuser,
           sfw_fifo_tuser_usermetadata, axi_wdj_tuser_usermetadata,
           ct_fifo_tuser_usermetadata;
   
   logic [EGR_TDATA_WIDTH-1:0] dwadj_data, axi_wdj_tdata, 
           egr_cdc_fifo_dout, sfw_fifo_tdata, ct_fifo_tdata, 
           ct_fifo_dout;

   logic [EGR_TKEEP_WIDTH-1:0] axi_wdj_tkeep, sfw_fifo_tkeep,
           ct_fifo_tkeep;

   logic [EGR_NUM_SEG-1:0] axi_wdj_tlast_segment, ct_fifo_tlast_segment;

   logic [$clog2(EGR_FIFO_DEPTH)-1:0] egr_fifo_cnt, sfw_fifo_cnt,
           ct_fifo_cnt;

   logic [EGR_BYTESVLD_WIDTH-1:0] sfw_fifo_bytesvld;

   logic [IGR_NUM_SEG-1:0]
                      [IGR_SEG_WIDTH-1:0] axi_st_tdata_mod;

   logic cfg_drop_en;
   logic [15:0] cfg_drop_threshold;

   logic [15:0] multicast_port_reg;
   logic multicast_en_reg;

   logic [DATA_WIDTH-1:0] avmm_readdata_w;
   logic avmm_readdata_valid_w;
    
   logic [31:0] rst_reg;
   // Generate arrays of reset to be used in submodule
   always_ff @(posedge clk) begin
      rst_reg <= '{default:rst};
   end

   always_ff @(posedge clk) begin
      // sync rst_reg
      rst_reg_c1 <= rst_reg[0];
      rst_reg_c2 <= rst_reg_c1;

      // rst_reg assertion edge detect
      rst_reg_posedge <= !rst_reg_c2 & rst_reg_c1;
   end

   // generate igr_rst_reg_posedge:  
   //  - de-assert tvalid at the ingress cdc
   //  - intentionally generate tlast during 
   //      igr_rst_reg_posedge cycle.

   always_ff @(posedge clk) begin
      if (rst_reg_posedge)
	    rst_req_state <= '1;
      
      if (rst_reg_c1 & !rst_reg[0])
	    rst_req_state <= '0; 
   end

   // generate egr_sop_state detection:
   always_ff @(posedge clk ) begin
      if (axi_st_tvalid_o & axi_st_tready_i & egr_sop_state)
	    egr_sop_state <= '0;
      else if (axi_st_tvalid_o & axi_st_tlast_o & axi_st_tready_i)
	    egr_sop_state <= '1;
      
      if (rst_reg[1])
	    egr_sop_state <= '1;      
   end

  // localparam EGR_AXI_TDATA_SEG = (EGR_TDATA_WIDTH == 128) ? 2 : 4;
  localparam EGR_WADJ_INUM_SEG = (EGR_TDATA_WIDTH == 64) ? 8 : 
                                   (EGR_TDATA_WIDTH == 128) ? 4 : 1;   
  localparam IKEEP_SEG_WIDTH = IGR_TKEEP_WIDTH/EGR_WADJ_INUM_SEG;

   logic [ITUSER_MD_WIDTH-1:0] axi_wdj_lg2sm_usermetadata_i;
   logic [ETUSER_MD_WIDTH-1:0] tuser_md;

   logic [EGR_WADJ_INUM_SEG-1:0][IKEEP_SEG_WIDTH-1:0] igr_tkeep_per_seg;
   logic [EGR_WADJ_INUM_SEG-1:0] seg_igr_tkeep, tlast_segment;

   // repeat usermetadata for all ingress segments
   always_comb begin
       axi_wdj_lg2sm_usermetadata_i = axi_st_tuser_usermetadata_i;
       axi_wdj_tuser_usermetadata = tuser_md;
   end 

   // last segment
   always_comb begin
     igr_tkeep_per_seg = axi_st_tkeep_i;
     for (int i = 0; i < EGR_WADJ_INUM_SEG; i++) begin
       seg_igr_tkeep[i] = |igr_tkeep_per_seg[i];	 
     end
   end

   generate
   if (EGR_WADJ_INUM_SEG == 8) begin
   
   always_comb begin
     tlast_segment = '0;
       case (1)
       seg_igr_tkeep[7] : begin
         tlast_segment[7] = axi_st_tuser_segment_info_i.eop ? '1 : '0;
       end
       seg_igr_tkeep[6] : begin
         tlast_segment[6] = axi_st_tuser_segment_info_i.eop ? '1 : '0;
       end
       seg_igr_tkeep[5] : begin
         tlast_segment[5] = axi_st_tuser_segment_info_i.eop ? '1 : '0;
       end
       seg_igr_tkeep[4] : begin
         tlast_segment[4] = axi_st_tuser_segment_info_i.eop ? '1 : '0;
       end
       seg_igr_tkeep[3] : begin
         tlast_segment[3] = axi_st_tuser_segment_info_i.eop ? '1 : '0;
       end
       seg_igr_tkeep[2] : begin
         tlast_segment[2] = axi_st_tuser_segment_info_i.eop ? '1 : '0;
       end
       seg_igr_tkeep[1] : begin
         tlast_segment[1] = axi_st_tuser_segment_info_i.eop ? '1 : '0;
       end
       seg_igr_tkeep[0] : begin
         tlast_segment[0] = axi_st_tuser_segment_info_i.eop ? '1 : '0;
       end
       endcase
   end // always_comb

   end else if (EGR_WADJ_INUM_SEG == 4) begin

   always_comb begin
     tlast_segment = '0;
       case (1)
       seg_igr_tkeep[3] : begin
         tlast_segment[3] = axi_st_tuser_segment_info_i.eop ? '1 : '0;
       end
       seg_igr_tkeep[2] : begin
         tlast_segment[2] = axi_st_tuser_segment_info_i.eop ? '1 : '0;
       end
       seg_igr_tkeep[1] : begin
         tlast_segment[1] = axi_st_tuser_segment_info_i.eop ? '1 : '0;
       end
       seg_igr_tkeep[0] : begin
         tlast_segment[0] = axi_st_tuser_segment_info_i.eop ? '1 : '0;
       end
       endcase
   end // always_comb

   end else begin // EGR_WADJ_INUM_SEG == 1

   always_comb begin
     tlast_segment = '0;
     tlast_segment[0] = axi_st_tuser_segment_info_i.eop ? '1 : '0;
      /*
       case (1)
       seg_igr_tkeep[1] : begin
         tlast_segment[1] = axi_st_tuser_segment_info_i.eop ? '1 : '0;
       end
       seg_igr_tkeep[0] : begin
         tlast_segment[0] = axi_st_tuser_segment_info_i.eop ? '1 : '0;
       end
       endcase
      */
    end // always_comb
   end 
   endgenerate

   always_comb begin
     axi_st_tdata_mod = BYTE_ROTATE ? fn_byte_rotate(axi_st_tdata_i) :
                                        axi_st_tdata_i;
   end
       
   // large to small segment converter
   packet_switch_axi_wdj_lg2sm
     #( .IDATA_WIDTH (IGR_TDATA_WIDTH)
       ,.INUM_SEG (EGR_WADJ_INUM_SEG)
       ,.ENUM_SEG (EGR_NUM_SEG)
       ,.ITUSER_MD_WIDTH (ITUSER_MD_WIDTH
                          +packet_switch_pkg::SEGMENT_INFO_WIDTH)
       ,.ETUSER_MD_WIDTH (ETUSER_MD_WIDTH
                          +packet_switch_pkg::SEGMENT_INFO_WIDTH)
       ,.TID_WIDTH (1)
       ,.IFIFO_DEPTH (IFIFO_DEPTH)    
       ,.EFIFO_DEPTH (EFIFO_DEPTH)
      
       ) axi_wdj_lg2sm
   (
     .clk (clk)
    ,.rst (rst_reg[3])
    //-----------------------------------------------------------------------------------------
    // Ingress axi-st interface
    // outputs
    ,.trdy_o (axi_st_tready_o)

    // inputs
    ,.tvld_i (axi_st_tvalid_i)
    ,.tid_i ('0)
    ,.tdata_i (axi_st_tdata_mod)
    ,.tkeep_i (axi_st_tkeep_i)
    ,.tuser_md_i ({axi_wdj_lg2sm_usermetadata_i
                  ,axi_st_tuser_segment_info_i
                   })
    ,.terr_i ('0)
    ,.tlast_i (axi_st_tuser_segment_info_i.eop)
    ,.tlast_segment_i (tlast_segment)

    //-----------------------------------------------------------------------------------------
    // Egress axi-st interface
    // outputs
    ,.tvld_o (axi_wdj_tvalid)
    ,.tid_o ()
    ,.tdata_o (axi_wdj_tdata)
    ,.tkeep_o (axi_wdj_tkeep)
    ,.tuser_md_o ({tuser_md
                  ,axi_wdj_tuser_segment_info})  // to-do: check if repeat for all segments
    ,.terr_o ()
    ,.tlast_o (axi_wdj_tlast)
    // ,.tlast_segment_o (axi_wdj_tlast_segment)
    ,.tlast_segment_o ()

    // inputs
    ,.trdy_i (egr_fifo_rdy) // if SFW_FIFO is enabled, comes from SFW.
                            // else, comes from axi_st_tready_i

    //-----------------------------------------------------------------------------------------
    // CSR config register interface
    ,.cfg_drop_en        ((WADJ_ID == "USER") ? cfg_drop_en        : '0)
    ,.cfg_drop_threshold ((WADJ_ID == "USER") ? cfg_drop_threshold : 16'hFFFF)
    ,.dbg_cnt_drop_en    (dbg_cnt_drop_en)
   
    );
 
     always_comb begin
       egr_fifo_rdy = axi_st_tready_i;
     end

    // regenerate segment info sop and eop
    always_ff @(posedge clk) begin
      if (axi_st_tready_i & axi_wdj_tvalid & axi_wdj_tlast)
        // sop + eop, or eop
        sop_state <= '1;
      else if (axi_st_tready_i & axi_wdj_tvalid & sop_state)
        // sop, or mop
        sop_state <= '0;

      if (rst_reg[3])
        sop_state <= '1;
    end

    always_ff @(posedge clk) begin
      if (sop_state) begin
        multicast_port_reg <= axi_wdj_tuser_segment_info.multicast_port;
        multicast_en_reg   <= axi_wdj_tuser_segment_info.multicast_en;
      end
    end

     always_comb begin
       // mid-sim reset logic enabled
       if (WADJ_ID == "USER") begin
         axi_st_tvalid_o = (rst_reg_posedge & !egr_sop_state) ? '1 :
                           rst_req_state ? '0 : axi_wdj_tvalid;
         axi_st_tdata_o = axi_wdj_tdata;
         axi_st_tkeep_o = (rst_reg_posedge & !egr_sop_state) ? '1 :
                           axi_wdj_tkeep;
         axi_st_tlast_o = (rst_reg_posedge & !egr_sop_state) ? '1 :
                           rst_req_state ? '0 : axi_wdj_tlast;
         // axi_st_tuser_last_segment_o <= ct_fifo_tlast_segment;
         axi_st_tuser_last_segment_o = (rst_reg_posedge & !egr_sop_state) ? '1 :
                           rst_req_state ? '0 : axi_wdj_tlast;
         axi_st_tuser_usermetadata_o = axi_wdj_tuser_usermetadata;
	     
         axi_st_tuser_segment_info_o.sop = sop_state;
         axi_st_tuser_segment_info_o.eop = (rst_reg_posedge & !egr_sop_state) ? '1 :
                           rst_req_state ? '0 : axi_wdj_tlast;   

         axi_st_tuser_segment_info_o.igr_port = axi_wdj_tuser_segment_info.igr_port;    
         axi_st_tuser_segment_info_o.egr_port = axi_wdj_tuser_segment_info.egr_port;   
         axi_st_tuser_segment_info_o.multicast_port = sop_state ? axi_wdj_tuser_segment_info.multicast_port :
                                                                   multicast_port_reg;         
         axi_st_tuser_segment_info_o.multicast_en = sop_state ? axi_wdj_tuser_segment_info.multicast_en : 
                                                                  multicast_en_reg;   
         
         // unused signals- sos, eos, bytesvld, hdr and payld seg
         axi_st_tuser_segment_info_o.sos = '0;
         axi_st_tuser_segment_info_o.eos = '0;
         axi_st_tuser_segment_info_o.bytesvld = '0;
         axi_st_tuser_segment_info_o.hdr_segment = '0;
         axi_st_tuser_segment_info_o.payld_segment = '0;
	     
       end else begin
         // mid-sim reset logic disabled
         axi_st_tvalid_o = axi_wdj_tvalid;
         axi_st_tdata_o = axi_wdj_tdata;
         axi_st_tkeep_o = axi_wdj_tkeep;
         axi_st_tlast_o = axi_wdj_tlast;
         // axi_st_tuser_last_segment_o <= ct_fifo_tlast_segment;
         axi_st_tuser_last_segment_o = axi_wdj_tlast;
         axi_st_tuser_usermetadata_o = axi_wdj_tuser_usermetadata;
	     
         axi_st_tuser_segment_info_o.sop = sop_state;
         axi_st_tuser_segment_info_o.eop = axi_wdj_tlast;       

         axi_st_tuser_segment_info_o.igr_port = axi_wdj_tuser_segment_info.igr_port;    
         axi_st_tuser_segment_info_o.egr_port = axi_wdj_tuser_segment_info.egr_port;   
         axi_st_tuser_segment_info_o.multicast_port = sop_state ? axi_wdj_tuser_segment_info.multicast_port :
                                                                   multicast_port_reg;         
         axi_st_tuser_segment_info_o.multicast_en = sop_state ? axi_wdj_tuser_segment_info.multicast_en : 
                                                                  multicast_en_reg;   
         
         // unused signals- sos, eos, bytesvld, hdr and payld seg
         axi_st_tuser_segment_info_o.sos = '0;
         axi_st_tuser_segment_info_o.eos = '0;
         axi_st_tuser_segment_info_o.bytesvld = '0;
         axi_st_tuser_segment_info_o.hdr_segment = '0;
         axi_st_tuser_segment_info_o.payld_segment = '0;
  
       end
     end // always_comb

     always_comb begin
       if (WADJ_ID == "USER") begin
         avmm_readdata = avmm_readdata_w;
         avmm_readdata_valid = avmm_readdata_valid_w;
       end else begin
         avmm_readdata = '0;
         avmm_readdata_valid = '0;
       end
     end


      // csr intf for User port
     egr_wadj_csr_intf
     #( .BASE_ADDR  (BASE_ADDR) 
       ,.MAX_ADDR   (MAX_ADDR)
       ,.ADDR_WIDTH (ADDR_WIDTH)
       ,.DATA_WIDTH (DATA_WIDTH)) csr_intf
     (//------------------------------------------------------------------------------------
      // Clock
      // input
      .clk (clk)
   
      // Reset
      ,.rst (rst_reg[2])
   
      //-----------------------------------------------------------------------------------------
      // AVMM interface
   
      // inputs
      ,.avmm_address   (avmm_address)
      ,.avmm_read      (avmm_read)
      ,.avmm_write     (avmm_write)
      ,.avmm_writedata (avmm_writedata)
      ,.avmm_byteenable (avmm_byteenable)
   
      // outputs
      ,.avmm_readdata (avmm_readdata_w)  
      ,.avmm_readdata_valid (avmm_readdata_valid_w)
   
      //-----------------------------------------------------------------------------------------
      // CSR Priority Port 
      // output
      ,.cfg_drop_en        (cfg_drop_en)
      ,.cfg_drop_threshold (cfg_drop_threshold)
   
     );

    // -----------------------------------------------------------------------------------------
    function [EGR_TKEEP_WIDTH-1:0] bytes_valid_to_tkeep;
	input logic [EGR_BYTESVLD_WIDTH-1:0] din;

	begin
	    logic [EGR_TKEEP_WIDTH-1:0] tmp_tkeep;

		for (int i = 0; i < EGR_TKEEP_WIDTH; i++) begin
          tmp_tkeep[i] = (i < din ) ? '1 : '0;
        end
		
		bytes_valid_to_tkeep = tmp_tkeep;
	 
	end
    endfunction

   // swapping msb byte to lsb byte
   function [IGR_TDATA_WIDTH/8-1:0] [7:0] fn_byte_rotate
     (input [IGR_TDATA_WIDTH/8-1:0] [7:0] din);
      
      begin
	 logic [IGR_TDATA_WIDTH/8-1:0] [7:0] tmp_din, tmp;
	 tmp_din = din;
	 
	 for (int i = 0; i < IGR_TDATA_WIDTH/8; i++) begin
	    tmp[i] = tmp_din[(IGR_TDATA_WIDTH/8-1)-i];	    
	 end
	 fn_byte_rotate = tmp;
      end
   endfunction

endmodule
