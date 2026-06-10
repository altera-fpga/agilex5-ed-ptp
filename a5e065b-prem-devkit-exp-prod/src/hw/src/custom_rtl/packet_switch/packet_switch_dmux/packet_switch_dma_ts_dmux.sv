//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

//////////////////////////////////////////////////////////////////////////////////////////////
// Description:
// msgDMA timestamp demux
// 
//
//
//////////////////////////////////////////////////////////////////////////////////////////////

module packet_switch_dma_ts_dmux
   #( parameter TX_EGR_TS_WIDTH             = 96
     ,parameter FINGERPRINT_FLD_WIDTH       = 32 // total available fingerprint field width.
     ,parameter SYS_FINGERPRINT_WIDTH       = 20 // system specified fingerprint width. max:28.
     ,parameter TDATA_WIDTH                 = TX_EGR_TS_WIDTH+FINGERPRINT_FLD_WIDTH
     ,parameter NUM_INTF                    = 9 // max dma channels (8) + user port (1)
     ,parameter EGR_FIFO_DEPTH              = 512
   ) 

  (
    //----------------------------------------------------------------------------------------
    // Clocks
     input var logic                                          clk

    //----------------------------------------------------------------------------------------
    // Resets 
    ,input var logic                                          rst

    //-----------------------------------------------------------------------------------------
    // ingress interface
    ,input var logic                                          hssi2dmux_0_tvalid
    ,input var logic [TDATA_WIDTH-1:0]                        hssi2dmux_0_tdata

    ,input var logic                                          hssi2dmux_1_tvalid
    ,input var logic [TDATA_WIDTH-1:0]                        hssi2dmux_1_tdata

    ,output var logic                                         dmux2hssi_tready

    //----------------------------------------------------------------------------------------
    // egress port interface
    ,output var logic [NUM_INTF-1:0]                          dmux2egrpt_0_tvalid
    ,output var logic [NUM_INTF-1:0][TDATA_WIDTH-1:0]         dmux2egrpt_0_tdata

    ,output var logic [NUM_INTF-1:0]                          dmux2egrpt_1_tvalid
    ,output var logic [NUM_INTF-1:0][TDATA_WIDTH-1:0]         dmux2egrpt_1_tdata
                
    ,input var logic [NUM_INTF-1:0]                           egrpt2dmux_tready
   );
   import packet_switch_pkg::*;

   localparam MAX_DMA_CHANNELS = 8;

   localparam PT_WD = packet_switch_pkg::PORTS_WIDTH;

   localparam EGR_FIFO_THRESHOLD = EGR_FIFO_DEPTH - 32;

   localparam MAX_DMA = 8; 

   localparam MAX_PT = MAX_DMA + 1; // DMA+USER ports

   logic [TX_EGR_TS_WIDTH-1:0] igr_timestamp;

   logic [FINGERPRINT_FLD_WIDTH-1:0] igr_fp;

   logic [MAX_PT-1:0] egr_fifo_wr, egr_fifo_rdy;

   logic [3:0] fp_decode;

   logic [MAX_PT-1:0] egr_fifo_rd, egr_fifo_tlast, egr_fifo_empty,
     egr_fifo_overflow, egr_fifo_underflow, egr_fifo_full;

   logic [MAX_PT-1:0][$clog2(EGR_FIFO_DEPTH)-1:0] egr_fifo_occ;
   logic [MAX_PT-1:0][TDATA_WIDTH-1:0] dmux2egrpt_0_tdata_r;

   logic [TDATA_WIDTH-1:0] tdata0_c1, tdata0_c1_mod, tdata1_c1;

   logic [MAX_PT-1:0] dmux2egrpt_0_tvalid_c1;

   logic tvalid0_c1, tvalid1_c1;

   logic [31:0] rst_reg;
   // Generate arrays of reset to be used in submodule
   always_ff @(posedge clk) begin
      rst_reg <= '{default:rst};
   end

   //------------------------------------------------------------------------------------------

   // cycle 1
   always_ff @(posedge clk) begin
     // split tdata
     {igr_fp, igr_timestamp} <= hssi2dmux_0_tdata;
     
     tdata0_c1 <= hssi2dmux_0_tdata;
     tdata1_c1 <= hssi2dmux_1_tdata;
     
     tvalid0_c1 <= hssi2dmux_0_tvalid;
     tvalid1_c1 <= hssi2dmux_1_tvalid;
   end

   always_comb begin
     // decode 4b after user specified fingerprint width
     fp_decode = igr_fp[(SYS_FINGERPRINT_WIDTH+PT_WD)-1:SYS_FINGERPRINT_WIDTH];
     
     dmux2egrpt_0_tvalid_c1 = '0;
     case (fp_decode)
       'd0:     dmux2egrpt_0_tvalid_c1[0] = tvalid0_c1; // dma_0
       'd1:     dmux2egrpt_0_tvalid_c1[1] = tvalid0_c1; // dma_1
       'd2:     dmux2egrpt_0_tvalid_c1[2] = tvalid0_c1; // dma_2
       'd3:     dmux2egrpt_0_tvalid_c1[3] = tvalid0_c1; // rsvd(dma_3)
       'd4:     dmux2egrpt_0_tvalid_c1[4] = tvalid0_c1; // rsvd(dma_4)
       'd5:     dmux2egrpt_0_tvalid_c1[5] = tvalid0_c1; // rsvd(dma_5)
       'd6:     dmux2egrpt_0_tvalid_c1[6] = tvalid0_c1; // rsvd(dma_6)
       'd7:     dmux2egrpt_0_tvalid_c1[7] = tvalid0_c1; // rsvd(dma_7)
       'd8:     dmux2egrpt_0_tvalid_c1[8] = tvalid0_c1; // user
       default: dmux2egrpt_0_tvalid_c1 = '0;
     endcase

	 // zero timestamp ingress port identifier
	 tdata0_c1_mod = tdata0_c1;
	 tdata0_c1_mod[TX_EGR_TS_WIDTH+SYS_FINGERPRINT_WIDTH +: PT_WD] = '0;

     dmux2hssi_tready = '1;
   end

   // cycle 2
   always_ff @(posedge clk) begin
     dmux2egrpt_0_tvalid <= dmux2egrpt_0_tvalid_c1;

     for (int i=0; i < NUM_INTF; i++) begin
       dmux2egrpt_1_tvalid[i] <= dmux2egrpt_0_tvalid_c1[i] & tvalid1_c1;
       dmux2egrpt_0_tdata[i] <= tdata0_c1_mod;
       dmux2egrpt_1_tdata[i] <= tdata1_c1;
     end

   end // always_ff
 
/*
   always_comb begin
     // split tdata
     {igr_fp, igr_timestamp} = hssi2dmux_0_tdata;

     // decode 4b after user specified fingerprint width
     fp_decode = igr_fp[(SYS_FINGERPRINT_WIDTH+PT_WD)-1:SYS_FINGERPRINT_WIDTH];

     egr_fifo_wr = '0;
     case (fp_decode)
       'd0:     egr_fifo_wr[0] = hssi2dmux_0_tvalid & egr_fifo_rdy[0]; // dma_0
       'd1:     egr_fifo_wr[1] = hssi2dmux_0_tvalid & egr_fifo_rdy[1]; // dma_1
       'd2:     egr_fifo_wr[2] = hssi2dmux_0_tvalid & egr_fifo_rdy[2]; // dma_2
       'd3:     egr_fifo_wr[3] = hssi2dmux_0_tvalid & egr_fifo_rdy[3]; // dma_3
       'd4:     egr_fifo_wr[4] = hssi2dmux_0_tvalid & egr_fifo_rdy[4]; // dma_4
       'd5:     egr_fifo_wr[5] = hssi2dmux_0_tvalid & egr_fifo_rdy[5]; // dma_5
       'd6:     egr_fifo_wr[6] = hssi2dmux_0_tvalid & egr_fifo_rdy[6]; // dma_6
       'd7:     egr_fifo_wr[7] = hssi2dmux_0_tvalid & egr_fifo_rdy[7]; // dma_7
       default: egr_fifo_wr[8] = hssi2dmux_0_tvalid & egr_fifo_rdy[8]; // user
     endcase
   end // always_comb


   // traffic to dma is expected to have low bandwidth,
   // so the egr_fifo should be able drain out
   always_comb begin
     dmux2hssi_tready = &egr_fifo_rdy;
   end
  
   always_ff @(posedge clk) begin
     for (int i=0; i < MAX_PT; i++) begin
      egr_fifo_rdy[i] <= egr_fifo_occ[i] < EGR_FIFO_THRESHOLD;
     end
   end
   
   logic [MAX_PT-1:0] egrpt2dmux_tready_int, dmux2egrpt_0_tvalid_int;
   
   // always_comb begin
	// egrpt2dmux_tready_int = {5'b0, egrpt2dmux_tready};
	// dmux2egrpt_0_tvalid = dmux2egrpt_0_tvalid_int[NUM_INTF-1:0];
    // dmux2egrpt_0_tdata = dmux2egrpt_0_tdata_r[NUM_INTF-1:0];
   // end
   
   always_comb begin
    for (int i=0; i < MAX_PT; i++) begin
     // egr_fifo_rd[i] = egrpt2dmux_tready_int[i] 
     egr_fifo_rd[i] = egrpt2dmux_tready[i] 
                      & !egr_fifo_empty[i];

     dmux2egrpt_0_tvalid[i] = !egr_fifo_empty[i];  
	 
	// zero timestamp ingress port identifier
	dmux2egrpt_0_tdata[i] = dmux2egrpt_0_tdata_r[i];
	dmux2egrpt_0_tdata[i][TX_EGR_TS_WIDTH+SYS_FINGERPRINT_WIDTH +: PT_WD] = '0;

    end
   end
   
   genvar i;
   generate
     for (i=0; i < MAX_PT; i++) begin
       packet_switch_ipbb_sdc_fifo_inff 
         #( .DWD ( 1
                  +TDATA_WIDTH
                  +TDATA_WIDTH
                  )
           ,.NUM_WORDS (EGR_FIFO_DEPTH) ) egr_fifo
         (//------------------------------------------------------------------------------------
          // clk/rst
          .clk1 (clk)
          ,.clk2 (clk)
          ,.rst (rst_reg[0])
       
          // inputs
          ,.din ({ hssi2dmux_1_tvalid
                  ,hssi2dmux_1_tdata 
                  ,hssi2dmux_0_tdata})
          ,.wrreq (egr_fifo_wr[i])
          ,.rdreq (egr_fifo_rd[i])
       
          // outputs
          ,.dout ({ dmux2egrpt_1_tvalid[i]
                   ,dmux2egrpt_1_tdata[i]
                   ,dmux2egrpt_0_tdata_r[i]}) 
          ,.rdempty (egr_fifo_empty[i]) 
          ,.rdempty_lkahd () 
          ,.wrfull (egr_fifo_full[i])
          ,.wrusedw (egr_fifo_occ[i])
          ,.overflow (egr_fifo_overflow[i])
          ,.underflow (egr_fifo_underflow[i])
          );
		  
		
      end // for (int i=0; i < NUM_INTF; i=i+1)
   endgenerate
*/
endmodule