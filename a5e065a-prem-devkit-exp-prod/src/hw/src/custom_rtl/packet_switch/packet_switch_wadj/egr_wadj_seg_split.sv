//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


//////////////////////////////////////////////////////////////////////////////////////////////
// Description:
// convert 1 segment into multiple segments with SOP aligned
//
//////////////////////////////////////////////////////////////////////////////////////////////

module egr_wadj_seg_split
   #( parameter IGR_TDATA_WIDTH             = 512
     ,parameter EGR_TDATA_WIDTH             = 128
     ,parameter EGR_NUM_SEG                 = 2
     ,parameter EGR_SEG_WIDTH               = EGR_TDATA_WIDTH/EGR_NUM_SEG
     ,parameter USERMETADATA_WIDTH          = 1
     ,parameter IGR_FIFO_DEPTH              = 512
     ,parameter EGR_FIFO_DEPTH              = 512
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
    ,input var logic                                   igr_tvalid
    ,input var logic [IGR_TDATA_WIDTH-1:0]             igr_tdata
    ,input var logic [IGR_TDATA_WIDTH/8-1:0]           igr_tkeep
    ,input var logic                                   igr_tlast
    ,input var logic [USERMETADATA_WIDTH-1:0]          igr_tuser_usermetadata
    ,input var packet_switch_pkg::SEGMENT_INFO_S          igr_tuser_segment_info 
    
    ,output var logic                                  igr_tready

    //-----------------------------------------------------------------------------------------
    // egress interface
    ,output var logic                                  egr_tvalid
    ,output var logic [EGR_NUM_SEG-1:0]
                        [EGR_SEG_WIDTH-1:0]            egr_tdata
    ,output var logic [EGR_TDATA_WIDTH/8-1:0]          egr_tkeep
    ,output var logic                                  egr_tlast
    ,output var logic [EGR_NUM_SEG-1:0]                egr_tlast_segment
    ,output var logic [USERMETADATA_WIDTH-1:0]         egr_tuser_usermetadata
    ,output var packet_switch_pkg::SEGMENT_INFO_S         egr_tuser_segment_info
    
    ,input var logic                                   egr_tready
);

   localparam SEGMENT_INFO_WD = packet_switch_pkg::SEGMENT_INFO_WIDTH;

   localparam IGR_FIFO_THRESHOLD = IGR_FIFO_DEPTH - 16;
   localparam EGR_FIFO_THRESHOLD = EGR_FIFO_DEPTH - 16;

   localparam INUM_SEG = IGR_TDATA_WIDTH/EGR_SEG_WIDTH;
   localparam IGR_TKEEP_WIDTH = IGR_TDATA_WIDTH/8;
   localparam IKEEP_SEG_WIDTH = IGR_TKEEP_WIDTH/INUM_SEG;

   localparam EGR_TKEEP_WIDTH = EGR_TDATA_WIDTH/8;
   localparam EKEEP_SEG_WIDTH = EGR_TKEEP_WIDTH/EGR_NUM_SEG;

   logic [EGR_NUM_SEG-1:0][EGR_SEG_WIDTH-1:0] tdata_tmp;
   logic [EGR_NUM_SEG-1:0][EKEEP_SEG_WIDTH-1:0] tkeep_tmp;

   logic [INUM_SEG-1:0][IKEEP_SEG_WIDTH-1:0] igr_fifo_tkeep;
   logic [INUM_SEG-1:0] seg_tkeep;

   logic [INUM_SEG-1:0][EGR_SEG_WIDTH-1:0] igr_fifo_tdata;

   logic [EGR_NUM_SEG-1:0][EKEEP_SEG_WIDTH-1:0] egr_tkeep_per_seg;
   logic [EGR_NUM_SEG-1:0] seg_egr_tkeep;
   
   logic [$clog2(INUM_SEG)-1:0] idata_cyc_cnt;

   logic [$clog2(EGR_NUM_SEG)-1:0] edata_cyc_cnt;

   logic [USERMETADATA_WIDTH-1:0] igr_fifo_tuser_usermetadata;

   packet_switch_pkg::SEGMENT_INFO_S igr_fifo_tuser_segment_info,
     igr_fifo_tuser_segment_info_mod;

   logic igr_fifo_vld, igr_fifo_empty, egr_fifo_rdy,
     igr_fifo_rd, igr_fifo_tlast, egr_fifo_wr, egr_fifo_rd, 
     egr_fifo_empty, igr_fifo_overflow, egr_fifo_overflow, 
     igr_fifo_underflow, egr_fifo_underflow, igr_fifo_full,
     egr_fifo_full, egr_fifo_tlast, igr_fifo_tlast_mod, sop_state;

   logic [$clog2(IGR_FIFO_DEPTH)-1:0] igr_fifo_cnt;
   logic [$clog2(EGR_FIFO_DEPTH)-1:0] egr_fifo_cnt;

   logic [31:0] rst_reg;
   // Generate arrays of reset to be used in submodule
   always_ff @(posedge clk) begin
      rst_reg <= '{default:rst};
   end

   always_comb begin
     for (int i = 0; i < INUM_SEG; i++) begin
       seg_tkeep[i] = |igr_fifo_tkeep[i];	 
     end
   end

   // process two segments in one cycle
   // idata_cyc_cnt : iterates over igr_fifo_tdata
   // edata_cyc_cnt : iterates over tdata_tmp, tkeep_tmp
   always_ff @(posedge clk) begin
      if (rst_reg[0]) begin
	    idata_cyc_cnt <= '0;
	    edata_cyc_cnt <= '0;
      end else begin
        if ( !igr_fifo_empty & !seg_tkeep[idata_cyc_cnt] 
            | (!igr_fifo_empty & !seg_tkeep[idata_cyc_cnt+1])
            | (idata_cyc_cnt == INUM_SEG-2)) begin
	      idata_cyc_cnt <= '0;    
	      edata_cyc_cnt <= '0;    
        end else if (!igr_fifo_empty) begin
	      idata_cyc_cnt <= idata_cyc_cnt + 'h2;    
          // edata_cyc_cnt <= edata_cyc_cnt + 'h1;
        end 
      end
   end

   always_ff @(posedge clk) begin
     igr_tready   <= igr_fifo_cnt < IGR_FIFO_THRESHOLD;
     egr_fifo_rdy <= egr_fifo_cnt < EGR_FIFO_THRESHOLD;
   end

   always_ff @(posedge clk) begin
     // store first egr segment
     tdata_tmp[0] <= igr_fifo_tdata[idata_cyc_cnt];
     tkeep_tmp[0] <= igr_fifo_tkeep[idata_cyc_cnt];

     // store second egr segments
     tdata_tmp[1] <= igr_fifo_tdata[idata_cyc_cnt+1];
     tkeep_tmp[1] <= igr_fifo_tkeep[idata_cyc_cnt+1];

     egr_fifo_wr <= igr_fifo_vld
                   & egr_fifo_rdy;
                   // & ((edata_cyc_cnt == '1)
                   // | !seg_tkeep[idata_cyc_cnt]);
                   // | !seg_tkeep[idata_cyc_cnt];

    // modified signals

    // igr_fifo_tlast_mod <= igr_fifo_tlast & igr_fifo_rd;
    igr_fifo_tlast_mod <= igr_fifo_tuser_segment_info.eop; 
    igr_fifo_tuser_segment_info_mod.sop <= sop_state;  
       
    igr_fifo_tuser_segment_info_mod.eop <= igr_fifo_tuser_segment_info.eop;         
    igr_fifo_tuser_segment_info_mod.sos <= igr_fifo_tuser_segment_info.sos;         
    igr_fifo_tuser_segment_info_mod.eos <= igr_fifo_tuser_segment_info.eos;         
    igr_fifo_tuser_segment_info_mod.bytesvld <= igr_fifo_tuser_segment_info.bytesvld;    
    igr_fifo_tuser_segment_info_mod.hdr_segment <= igr_fifo_tuser_segment_info.hdr_segment; 
    igr_fifo_tuser_segment_info_mod.payld_segment <= 
      igr_fifo_tuser_segment_info.payld_segment;
    igr_fifo_tuser_segment_info_mod.igr_port <= igr_fifo_tuser_segment_info.igr_port;    
    igr_fifo_tuser_segment_info_mod.egr_port <= igr_fifo_tuser_segment_info.egr_port;    

   end
   
   // sop_state
   always_ff @(posedge clk) begin
     // sop
     if (!igr_fifo_empty 
         & igr_fifo_tuser_segment_info.sop
         & !igr_fifo_tuser_segment_info.eop)
       sop_state <= '0;
     
     // sop + eop, or eop
     else if (!igr_fifo_empty 
         & igr_fifo_tuser_segment_info.eop)
       sop_state <= '1;

     if (rst)
       sop_state <= '1;
   end

   always_comb begin
     igr_fifo_rd = !igr_fifo_empty & egr_fifo_rdy 
                   & (idata_cyc_cnt == INUM_SEG-2
                      | !seg_tkeep[idata_cyc_cnt]
                      | !seg_tkeep[idata_cyc_cnt+1]);

     igr_fifo_vld = !igr_fifo_empty;

     egr_fifo_rd = !egr_fifo_empty & egr_tready;

     egr_tvalid = egr_fifo_rd;
   end

   // last_segment
   always_comb begin
     egr_tkeep_per_seg = egr_tkeep;
     for (int i = EGR_NUM_SEG-1; i >= 0; i--) begin
       seg_egr_tkeep[i] = |egr_tkeep_per_seg[i];	 
     end
   end

   // egr_tlast_segment
     generate 
       if (EGR_NUM_SEG == 1) begin
        always_comb begin
          egr_tlast_segment = '0;
          case (1)
          seg_egr_tkeep[0] : begin
            egr_tlast_segment[0] = egr_tlast ? '1 : '0;
          end
          endcase
        end
       end // EGR_NUM_SEG == 1
       else if (EGR_NUM_SEG == 2) begin
         always_comb begin
           egr_tlast_segment = '0;
           case (1)
           seg_egr_tkeep[1] : begin
             egr_tlast_segment[1] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[0] : begin
             egr_tlast_segment[0] = egr_tlast ? '1 : '0;
           end
           endcase
         end
       end // EGR_NUM_SEG == 2
       else if (EGR_NUM_SEG == 4) begin
         always_comb begin
           egr_tlast_segment = '0;
           case (1)
           seg_egr_tkeep[3] : begin
             egr_tlast_segment[3] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[2] : begin
             egr_tlast_segment[2] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[1] : begin
             egr_tlast_segment[1] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[0] : begin
             egr_tlast_segment[0] = egr_tlast ? '1 : '0;
           end
           endcase
         end
       end // EGR_NUM_SEG == 4
       else if (EGR_NUM_SEG == 8) begin
         always_comb begin
           egr_tlast_segment = '0;
           case (1)
           seg_egr_tkeep[7] : begin
             egr_tlast_segment[7] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[6] : begin
             egr_tlast_segment[6] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[5] : begin
             egr_tlast_segment[5] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[4] : begin
             egr_tlast_segment[4] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[3] : begin
             egr_tlast_segment[3] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[2] : begin
             egr_tlast_segment[2] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[1] : begin
             egr_tlast_segment[1] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[0] : begin
             egr_tlast_segment[0] = egr_tlast ? '1 : '0;
           end
           endcase
         end 
       end // EGR_NUM_SEG == 8
       else begin
         always_comb begin
           egr_tlast_segment = '0;
           case (1)
           seg_egr_tkeep[15] : begin
             egr_tlast_segment[15] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[14] : begin
             egr_tlast_segment[14] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[13] : begin
             egr_tlast_segment[13] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[12] : begin
             egr_tlast_segment[12] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[11] : begin
             egr_tlast_segment[11] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[10] : begin
             egr_tlast_segment[10] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[9] : begin
             egr_tlast_segment[9] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[8] : begin
             egr_tlast_segment[8] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[7] : begin
             egr_tlast_segment[7] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[6] : begin
             egr_tlast_segment[6] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[5] : begin
             egr_tlast_segment[5] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[4] : begin
             egr_tlast_segment[4] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[3] : begin
             egr_tlast_segment[3] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[2] : begin
             egr_tlast_segment[2] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[1] : begin
             egr_tlast_segment[1] = egr_tlast ? '1 : '0;
           end
           seg_egr_tkeep[0] : begin
             egr_tlast_segment[0] = egr_tlast ? '1 : '0;
           end
           endcase
         end 
       end // EGR_NUM_SEG == 16
      endgenerate
   

   // igr_fifo
   ipbb_scfifo_inff 
     #( .DWD ( IGR_TDATA_WIDTH
              +IGR_TKEEP_WIDTH
              +USERMETADATA_WIDTH
              +1
              +SEGMENT_INFO_WD
              )
       ,.NUM_WORDS (IGR_FIFO_DEPTH) ) igr_fifo
     (//------------------------------------------------------------------------------------
      // clk/rst
      .clk (clk)
      ,.rst (rst_reg[0])

      // inputs
      ,.din ({ igr_tdata
              ,igr_tkeep
              ,igr_tuser_usermetadata
              ,igr_tlast
              ,igr_tuser_segment_info
             })
      ,.wrreq (igr_tvalid)
      ,.rdreq (igr_fifo_rd)

      // outputs
      ,.dout ({ igr_fifo_tdata
               ,igr_fifo_tkeep
               ,igr_fifo_tuser_usermetadata
               ,igr_fifo_tlast
               ,igr_fifo_tuser_segment_info
              }) 
      ,.rdempty (igr_fifo_empty) 
      ,.rdempty_lkahd () 
      ,.wrfull (igr_fifo_full)
      ,.wrusedw (igr_fifo_cnt)
      ,.overflow (igr_fifo_overflow)
      ,.underflow (igr_fifo_underflow)
      );
 
   // egr_fifo
   ipbb_scfifo_inff 
     #( .DWD ( EGR_TDATA_WIDTH
              +EGR_TKEEP_WIDTH
              +USERMETADATA_WIDTH
              +1
              +SEGMENT_INFO_WD
              )
       ,.NUM_WORDS (EGR_FIFO_DEPTH) ) egr_fifo
     (//------------------------------------------------------------------------------------
      // clk/rst
      .clk  (clk)
      ,.rst (rst_reg[0])

      // inputs
      ,.din ({ tdata_tmp
              ,tkeep_tmp
              ,igr_fifo_tuser_usermetadata
              ,igr_fifo_tlast_mod
              ,igr_fifo_tuser_segment_info_mod
             })
      ,.wrreq (egr_fifo_wr)
      ,.rdreq (egr_fifo_rd)

      // outputs
      ,.dout ({ egr_tdata
               ,egr_tkeep
               ,egr_tuser_usermetadata
               ,egr_tlast
               ,egr_tuser_segment_info
              }) 
      ,.rdempty (egr_fifo_empty) 
      ,.rdempty_lkahd () 
      ,.wrfull (egr_fifo_full)
      ,.wrusedw (egr_fifo_cnt)
      ,.overflow (egr_fifo_overflow)
      ,.underflow (egr_fifo_underflow)
      );

endmodule