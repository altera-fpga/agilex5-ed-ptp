//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module packet_switch_igr_arb
   #( parameter TDATA_WIDTH                 = 512
     ,parameter TKEEP_WIDTH                 = TDATA_WIDTH/8
     ,parameter USERMETADATA_WIDTH          = 1
     ,parameter NUM_INTF                    = 4 // max interfaces/priorities is 4.
     ,parameter DMA_CHNL_PER_PIPE           = 3 
     ,parameter USER_IGR_FIFO_DEPTH         = 512
     ,parameter BASE_ADDR                   = 'h0
     ,parameter MAX_ADDR                    = 'h8
     ,parameter ADDR_WIDTH                  = 8
     ,parameter DATA_WIDTH                  = 32
   ) 

  (
    //----------------------------------------------------------------------------------------
    // Clocks
    input var logic                                    clk

    //----------------------------------------------------------------------------------------
    // Resets 
    ,input var logic                                   rst

    //-----------------------------------------------------------------------------------------
    // ingress interface
    ,input var logic [NUM_INTF-1:0]                          iwadj2iarb_tvalid
    ,input var logic [NUM_INTF-1:0][TDATA_WIDTH-1:0]         iwadj2iarb_tdata
    ,input var logic [NUM_INTF-1:0][TKEEP_WIDTH-1:0]         iwadj2iarb_tkeep
    ,input var logic [NUM_INTF-1:0][USERMETADATA_WIDTH-1:0]  iwadj2iarb_tuser_usermetadata
    ,input var packet_switch_pkg::SEGMENT_INFO_S [NUM_INTF-1:0] iwadj2iarb_tuser_segment_info
     
    ,input var logic [NUM_INTF-1:0]                 iwadj2iarb_sop_detect // index 0 unused
    ,input var logic [NUM_INTF-1:0]                 iwadj_fifo_empty // index 0 unused
    ,output var logic [NUM_INTF-1:0]                iarb2iwadj_fifo_pop // index 0 unused
    ,output var logic [NUM_INTF-1:0]                iarb2iwadj_tready // index 1-(NUM_INTF-1) unused

    //----------------------------------------------------------------------------------------
    // HSSI TX interface
    ,output var logic                                        iarb2hssi_tvalid
    ,output var logic [TDATA_WIDTH-1:0]                      iarb2hssi_tdata
    ,output var logic [TKEEP_WIDTH-1:0]                      iarb2hssi_tkeep
    ,output var logic [USERMETADATA_WIDTH-1:0]               iarb2hssi_tuser_usermetadata
    ,output var packet_switch_pkg::SEGMENT_INFO_S               iarb2hssi_tuser_segment_info
											                 
    ,input var logic                                         hssi2iarb_tready

    //----------------------------------------------------------------------------------------
    // lookup interface
    // ,input var logic                                   lu2iarb_fc

    //----------------------------------------------------------------------------------------
    // scheduler interface
    // credit return per igr_port
    // ,input var logic [NUM_INTF-1:0]                   sch2iarb_crd_ret

    //-----------------------------------------------------------------------------------------
    // AVMM interface

    ,input var logic [ADDR_WIDTH-1:0]     avmm_address
    ,input var logic                      avmm_read
    ,output var logic [DATA_WIDTH-1:0]    avmm_readdata 
    ,input var logic                      avmm_write
    ,input var logic [DATA_WIDTH-1:0]     avmm_writedata
    ,input var logic [(DATA_WIDTH/8)-1:0] avmm_byteenable
    ,output var logic                     avmm_readdata_valid

   );
   import packet_switch_pkg::*;

   localparam IGR_FIFO_DEPTH = 512;
   localparam EGR_FIFO_DEPTH = 512*3;
   localparam IGR_FIFO_THRESHOLD = IGR_FIFO_DEPTH - 32;
   localparam USER_IGR_FIFO_THRESHOLD = USER_IGR_FIFO_DEPTH - 32;
   localparam EGR_FIFO_THRESHOLD = EGR_FIFO_DEPTH - 32;

   localparam RR_GNT_FIFO_DEPTH = 12;
   localparam RR_GNT_FIFO_THRESHOLD = RR_GNT_FIFO_DEPTH-5;
   localparam RR_GNT_FIFO_DEPTH_WD = $clog2(RR_GNT_FIFO_DEPTH);

   localparam NUM_QUE = 1; // number of queue per priority
   localparam NUM_QUE_WIDTH = ($clog2(NUM_QUE) == 0) ? 1 : $clog2(NUM_QUE);

   localparam NUM_PRIORITY = NUM_INTF;
   localparam MAX_NUM_PRIORITY = 4;
   localparam NUM_PRIORITY_WIDTH = $clog2(NUM_PRIORITY); 

   // skip over LSB (user) to start at DMA indicies defined at top level
   localparam DMA_START_INDEX = NUM_INTF-DMA_CHNL_PER_PIPE;  

   logic [NUM_PRIORITY-1:0][NUM_QUE-1:0] rr_req;
   
   logic [$clog2(NUM_PRIORITY)-1:0] rr_gnt_sel;

   logic [NUM_PRIORITY-1:0][TDATA_WIDTH-1:0] pkt_tdata;

   logic [NUM_PRIORITY-1:0][TKEEP_WIDTH-1:0] pkt_tkeep;

   logic [NUM_PRIORITY-1:0][USERMETADATA_WIDTH-1:0] pkt_tuser_usermetadata;

   logic [MAX_NUM_PRIORITY-1:0][3:0]  cfg_priority, sel_port_to_priority;

   packet_switch_pkg::SEGMENT_INFO_S [NUM_PRIORITY-1:0] pkt_tuser_segment_info;

   logic [NUM_INTF-1:0][$clog2(IGR_FIFO_DEPTH)-1:0] igr_fifo_occ; // index 0 unused
   logic [$clog2(USER_IGR_FIFO_DEPTH)-1:0] user_igr_fifo_occ;
   logic [$clog2(EGR_FIFO_DEPTH)-1:0] egr_fifo_occ;

   logic [NUM_INTF-1:0] igr_fifo_rd, igr_fifo_empty, igr_fifo_full,
     igr_fifo_overflow, igr_fifo_underflow, igr_fifo_eop_det, iwadj_sop_detect,
     sop_detect;

   logic [TDATA_WIDTH-1:0]                      iarb2hssi_tdata_w, egr_fifo_pkt_tdata;

   logic [TKEEP_WIDTH-1:0]                      iarb2hssi_tkeep_w, egr_fifo_pkt_tkeep;

   logic [USERMETADATA_WIDTH-1:0]               iarb2hssi_tuser_usermetadata_w, egr_fifo_pkt_tuser_usermetadata;

   packet_switch_pkg::SEGMENT_INFO_S               iarb2hssi_tuser_segment_info_w, egr_fifo_pkt_tuser_segment_info;

   logic egr_fifo_wr, egr_fifo_rd, igr_pkt_state,
     egr_fifo_empty, egr_fifo_rdy, rr_gnt_sel_vld, rr_gnt_pop,
     rst_reg_c1, rst_reg_c2, rst_reg_posedge, rst_req_state,
     egr_sop_state, gnt_in_flight;

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
      if (iarb2hssi_tvalid & hssi2iarb_tready & egr_sop_state)
	    egr_sop_state <= '0;
      else if (iarb2hssi_tvalid & iarb2hssi_tuser_segment_info.eop & hssi2iarb_tready)
	    egr_sop_state <= '1;
      
      if (rst_reg[1])
	    egr_sop_state <= '1;      
   end


     always_ff @(posedge clk) begin
       // user port
       iarb2iwadj_tready[0] <= (user_igr_fifo_occ < USER_IGR_FIFO_THRESHOLD);

       // egr_fifo_rdy
       egr_fifo_rdy <= egr_fifo_occ < EGR_FIFO_THRESHOLD;
     end

    // map ports to their respective priorities
     always_ff @(posedge clk) begin
       // cfg_priority[0] : dma_0
       // cfg_priority[1] : dma_1
       // cfg_priority[2] : dma_2
       // cfg_priority[3] : user

       // determine which port is priority 0
       if (cfg_priority[0] == 'd0)
           sel_port_to_priority[0] <= 'd1; // dma_0
       else if (cfg_priority[1] == 'd0)
           sel_port_to_priority[0] <= 'd2; // dma_1
       else if (cfg_priority[2] == 'd0)
           sel_port_to_priority[0] <= 'd3; // dma_2
       else
           sel_port_to_priority[0] <= 'd0; // user
 
       // determine which port is priority 1
       if (cfg_priority[0] == 'd1)
           sel_port_to_priority[1] <= 'd1; // dma_0
       else if (cfg_priority[1] == 'd1)    
           sel_port_to_priority[1] <= 'd2; // dma_1
       else if (cfg_priority[2] == 'd1)    
           sel_port_to_priority[1] <= 'd3; // dma_2
       else                                
           sel_port_to_priority[1] <= 'd0; // user
 
       // determine which port is priority 2
       if (cfg_priority[0] == 'd2)
           sel_port_to_priority[2] <= 'd1; // dma_0
       else if (cfg_priority[1] == 'd2)    
           sel_port_to_priority[2] <= 'd2; // dma_1
       else if (cfg_priority[2] == 'd2)    
           sel_port_to_priority[2] <= 'd3; // dma_2
       else                                
           sel_port_to_priority[2] <= 'd0; // user
 
       // determine which port is priority 3
       if (cfg_priority[0] == 'd3)
           sel_port_to_priority[3] <= 'd1; // dma_0
       else if (cfg_priority[1] == 'd3)    
           sel_port_to_priority[3] <= 'd2; // dma_1
       else if (cfg_priority[2] == 'd3)    
           sel_port_to_priority[3] <= 'd3; // dma_2
       else                                
           sel_port_to_priority[3] <= 'd0; // user

     end // always_ff

     // user_igr_pkt_state
     always_ff @(posedge clk) begin
       if (iwadj2iarb_tvalid[0] & iarb2iwadj_tready[0] & iwadj2iarb_tuser_segment_info[0].eop)
         igr_pkt_state <= '0;
       else if (iwadj2iarb_tvalid[0] & iarb2iwadj_tready[0])
         igr_pkt_state <= '1;
     
       if (rst)
         igr_pkt_state <= '0;
     end
  
     // iwadj_sop_detect
     always_comb begin
       sop_detect[0] = iwadj2iarb_tvalid[0] & iarb2iwadj_tready[0] & !igr_pkt_state;
     end
 
     // map iwadj_sop_detect to sop_detect
     always_comb begin
       for (int i=DMA_START_INDEX; i < NUM_INTF; i=i+1) begin
         sop_detect[i] = iwadj2iarb_sop_detect[i];
       end
     end

   //------------------------------------------------------------------------------------------
   // priority arbitration   

     // rr_req
     always_comb begin
      for (int i=0; i < NUM_INTF; i=i+1) begin
       rr_req[i] = sop_detect[sel_port_to_priority[i]] ;
                   // & pkt_tuser_segment_info[sel_port_to_priority[i]].sop
                   // & rr_gnt_fifo_rdy;
      end
     end

   packet_switch_ipbb_pref_rrarb
     #( .N (NUM_INTF)
	,.NUM_REQ (IGR_FIFO_DEPTH)
	,.PREF_GNT_DEPTH (NUM_INTF > 4 ? NUM_INTF*2 : 8)
	) rrarb
       (
	.clk  (clk)
	,.rst (rst_reg[0])
	
	// inputs
	,.req (rr_req)	
	,.gnt_in_flight (gnt_in_flight)
	,.gnt_pop (rr_gnt_pop)
	
	// outputs
	,.gnt (rr_gnt_sel)
	,.gnt_vld (rr_gnt_sel_vld)
	,.num_pref_gnt ()
	);

   //------------------------------------------------------------------------------------------
   // gnt_in_flight: will stall lower priority requests in rrarb
   always_ff @(posedge clk) begin
    if ((|igr_fifo_rd) & pkt_tuser_segment_info[sel_port_to_priority[rr_gnt_sel]].eop)
      gnt_in_flight <= '0;
    else if (|igr_fifo_rd)
      gnt_in_flight <= '1;
   
    if (rst)
      gnt_in_flight <= '0;
   end

   always_comb begin
     for (int i=DMA_START_INDEX; i < NUM_INTF; i=i+1) begin
       igr_fifo_empty[i] = iwadj_fifo_empty[i];
     end

     // igr_fifo_rd
     igr_fifo_rd = '0;
     igr_fifo_rd[sel_port_to_priority[rr_gnt_sel]] = egr_fifo_rdy 
               & !igr_fifo_empty[sel_port_to_priority[rr_gnt_sel]]
               & rr_gnt_sel_vld; 

     for (int i=0; i < NUM_INTF; i=i+1) begin
       iarb2iwadj_fifo_pop[i] = igr_fifo_rd[i];
     end

     for (int i=DMA_START_INDEX; i < NUM_INTF; i=i+1) begin
       pkt_tdata[i] = iwadj2iarb_tdata[i];
       pkt_tkeep[i] = iwadj2iarb_tkeep[i];
       pkt_tuser_usermetadata[i] = iwadj2iarb_tuser_usermetadata[i];
       pkt_tuser_segment_info[i] = iwadj2iarb_tuser_segment_info[i];
       
       iarb2iwadj_tready[i] = '1;
     end

     // rr_gnt_pop
     rr_gnt_pop = igr_fifo_rd[sel_port_to_priority[rr_gnt_sel]]
             & pkt_tuser_segment_info[sel_port_to_priority[rr_gnt_sel]].eop;

     // egr_fifo_wr
     // egr_fifo_wr = |igr_fifo_rd;
  
     // egr_fifo_rd
     egr_fifo_rd = !egr_fifo_empty & hssi2iarb_tready;
   

     // outputs
     iarb2hssi_tvalid = (rst_reg_posedge & !egr_sop_state) ? '1 :
                           rst_req_state ? '0 : !egr_fifo_empty;
     iarb2hssi_tdata = iarb2hssi_tdata_w;
     iarb2hssi_tkeep = (rst_reg_posedge & !egr_sop_state) ? '1 :
                           iarb2hssi_tkeep_w;
     iarb2hssi_tuser_usermetadata = iarb2hssi_tuser_usermetadata_w;
     iarb2hssi_tuser_segment_info =  iarb2hssi_tuser_segment_info_w;
     iarb2hssi_tuser_segment_info.eop =  (rst_reg_posedge & !egr_sop_state) ? '1 :
                           rst_req_state ? '0 : iarb2hssi_tuser_segment_info_w.eop;
   end
   
    always_ff @(posedge clk) begin
      egr_fifo_wr <= |igr_fifo_rd;
         egr_fifo_pkt_tdata <= pkt_tdata[sel_port_to_priority[rr_gnt_sel]];
         egr_fifo_pkt_tkeep <= pkt_tkeep[sel_port_to_priority[rr_gnt_sel]];
         egr_fifo_pkt_tuser_usermetadata <= pkt_tuser_usermetadata[sel_port_to_priority[rr_gnt_sel]];
         egr_fifo_pkt_tuser_segment_info <= pkt_tuser_segment_info[sel_port_to_priority[rr_gnt_sel]];
    end

    

     //------------------------------------------------------------------------------------------
     // user port igr fifo

     packet_switch_ipbb_sdc_fifo_inff #( .DWD ( TDATA_WIDTH 
                           +TKEEP_WIDTH
                           +USERMETADATA_WIDTH
                           +SEGMENT_INFO_WIDTH 
                           )
                     ,.NUM_WORDS (USER_IGR_FIFO_DEPTH) ) user_igr_fifo
     (//------------------------------------------------------------------------------------
      // clk/rst
      .clk1 (clk)
      ,.clk2 (clk)
      ,.rst (rst_reg[1])

      // inputs
      ,.din ({ iwadj2iarb_tdata[0]
              ,iwadj2iarb_tkeep[0]
              ,iwadj2iarb_tuser_usermetadata[0]
              ,iwadj2iarb_tuser_segment_info[0]
             })
      ,.wrreq (iwadj2iarb_tvalid[0] & iarb2iwadj_tready[0])
      ,.rdreq (igr_fifo_rd[0])

      // outputs
      ,.dout ({ pkt_tdata[0]
               ,pkt_tkeep[0]
               ,pkt_tuser_usermetadata[0]
               ,pkt_tuser_segment_info[0]
              }) 
      ,.rdempty (igr_fifo_empty[0]) 
      ,.rdempty_lkahd () 
      ,.wrfull (igr_fifo_full[0])
      ,.wrusedw (user_igr_fifo_occ)
      ,.overflow (igr_fifo_overflow[0])
      ,.underflow (igr_fifo_underflow[0])
      ); 

    //------------------------------------------------------------------------------------------
    // sfw egr fifo

    packet_switch_ipbb_sfw_fifo #( .DW ( TDATA_WIDTH 
                          +TKEEP_WIDTH
                          +USERMETADATA_WIDTH
                          +SEGMENT_INFO_WIDTH 
                          )
                    ,.DEPTH (EGR_FIFO_DEPTH) ) egr_fifo
    (//------------------------------------------------------------------------------------
     // clk/rst
     .clk (clk)
     ,.rst (rst_reg[2])

     // inputs
     ,.din ({ egr_fifo_pkt_tdata
             ,egr_fifo_pkt_tkeep
             ,egr_fifo_pkt_tuser_usermetadata
             ,egr_fifo_pkt_tuser_segment_info
            })
     ,.push (egr_fifo_wr)
     ,.rel_ptr (egr_fifo_wr  
                 & egr_fifo_pkt_tuser_segment_info.eop)
     ,.pop (egr_fifo_rd)

     // outputs
     ,.dout ({ iarb2hssi_tdata_w
              ,iarb2hssi_tkeep_w
              ,iarb2hssi_tuser_usermetadata_w
              ,iarb2hssi_tuser_segment_info_w
             }) 
     ,.empty (egr_fifo_empty) 
     ,.full ()
     ,.cnt (egr_fifo_occ)
     ,.overflow ()
     ,.underflow ()
     ); 

   //------------------------------------------------------------------------------------------
   // csr interface

   igr_arb_csr_intf
   #( .BASE_ADDR  (BASE_ADDR) 
     ,.MAX_ADDR   (MAX_ADDR)
     ,.ADDR_WIDTH (ADDR_WIDTH)
     ,.DATA_WIDTH (DATA_WIDTH)
     ,.NUM_INTF   (MAX_NUM_PRIORITY) ) csr_intf
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
    ,.avmm_readdata (avmm_readdata)  
    ,.avmm_readdata_valid (avmm_readdata_valid)

    //-----------------------------------------------------------------------------------------
    // CSR Priority Port 
    // output
    ,.cfg_priority (cfg_priority)

   );

endmodule