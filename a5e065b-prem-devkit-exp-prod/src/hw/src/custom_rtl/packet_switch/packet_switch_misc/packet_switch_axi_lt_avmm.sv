//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


//////////////////////////////////////////////////////////////////////////////////////////////
// Description:
// AXI-Lite to AVMM converter using 2 clk domains
// 
// Tables below shows the Region that each module or reserved space is mapped to:
//
//
// CLK    Instance                                 Start   End
// --------------------------------------------------------------
// AXI_L  General                                  0x0     0x10
// AXI_L  Reserved                                 0x14    0x3C
// TX     Ingress Arbiter 0                        0x40    0x48
// RX     Egress RX Demux 0                        0x4C    0x70
// RX     Ingress RX Width Adapter 0               0x74    0x7C
// RX     Egress RX Width Adapter 0 (User port)    0x80    0x88
// AXI_L  *Reserved                                0x8C    0xFC
// AXI_L  TCAM 0 (16KB)                            0x100   0x40FC
// AXI_L  Reserved                                 0x4100  0x413C
// TX     Ingress Arbiter 1                        0x4140  0x4148
// RX     Egress RX Demux 1                        0x414C  0x4170
// RX     Ingress RX Width Adapter 1               0x4174  0x417C
// RX     Egress RX Width Adapter 1 (User port)    0x4180  0x4188
// AXI_L  *Reserved                                0x418C  0x41FC
// AXI_L  TCAM 1 (16KB)                            0x4200  0x81FC
// AXI_L  Reserved                                 0x8200  0xFFFF
//
// * If debug counters are enabled,
//  the following table shows how the Reserved space mapping for port 0 for example:
//  CLK    Instance                                 Start   End
//  --------------------------------------------------------------
//  TX     TX Debug Counters                        0x8C    0xA8
//  RX     RX Debug Counters                        0xAC    0xE8
//  AXI_L  Reserved                                 0xEC    0xFC
//
//////////////////////////////////////////////////////////////////////////////////////////////

module packet_switch_axi_lt_avmm
   #( parameter DEVICE_FAMILY    = "Agilex"
     ,parameter ADDR_WIDTH       = 8
     ,parameter DATA_WIDTH       = 32
     ,parameter AVMM_MAX_LATENCY = 5 // cycles of when avmm_write updates targeted register
     ,parameter HSSI_PORT        = 2 
     ,parameter DMA_CH           = 6
     ,parameter DBG_CNTR_EN      = 0
   ) 

  (
    //---------------------------------------------------------------------------------------
    // Clocks
    input var logic                        axi_lite_clk
   ,input var logic [HSSI_PORT-1:0]        tx_clk
   ,input var logic [HSSI_PORT-1:0]        rx_clk
    //---------------------------------------------------------------------------------------

    //---------------------------------------------------------------------------------------
    // Resets 
    ,input var logic                       axi_lt_rst
    ,input var logic [HSSI_PORT-1:0]       tx_rst
    ,input var logic [HSSI_PORT-1:0]       rx_rst
    //---------------------------------------------------------------------------------------

    //-----------------------------------------------------------------------------------------
    // AXI-Lite interface

    // Write Address Channel
    ,input var logic [ADDR_WIDTH-1:0]      awaddr                        
    ,input var logic                       awvalid                       
    ,output var logic                      awready                       
										   
    // Write Data Channel                  
    ,input var logic [DATA_WIDTH-1:0]      wdata                         
    ,input var logic                       wvalid
    ,input var logic [(DATA_WIDTH/8)-1:0]  wstrb	
    ,output var logic                      wready                        

    // Write Response Channel
    ,output var logic [1:0]                bresp                         
    ,output var logic                      bvalid                        
    ,input var logic                       bready 

    // Read Address Channel
    ,input var logic [ADDR_WIDTH-1:0]      araddr
    ,input var logic                       arvalid
    ,output var logic                      arready

    // Read Data Channel
    ,output var logic [1:0]                rresp
    ,output var logic [DATA_WIDTH-1:0]     rdata
    ,output var logic                      rvalid
    ,input var logic                       rready

    //-----------------------------------------------------------------------------------------
    // TCAM csr interface: 

    //-----WRITE ADDRESS CHANNEL-------
    ,output var logic [HSSI_PORT-1:0][ADDR_WIDTH - 1:0]     axi_lite_tcam_awaddr_o 
    ,output var logic [HSSI_PORT-1:0]                       axi_lite_tcam_awvalid_o
															  
    ,input var logic  [HSSI_PORT-1:0]                       axi_lite_tcam_awready_i
											
     //-----WRITE DATA CHANNEL----------                           
    ,output var logic  [HSSI_PORT-1:0][DATA_WIDTH - 1:0]     axi_lite_tcam_wdata_o 
    ,output var logic  [HSSI_PORT-1:0]                       axi_lite_tcam_wvalid_o
    ,output var logic  [HSSI_PORT-1:0][(DATA_WIDTH/8) - 1:0] axi_lite_tcam_wstrb_o
							     			                 
    ,input var logic   [HSSI_PORT-1:0]                       axi_lite_tcam_wready_i
								     		                
     //-----WRITE RESPONSE CHANNEL------                           
    ,input var logic [HSSI_PORT-1:0][1:0]                   axi_lite_tcam_bresp_i 
    ,input var logic [HSSI_PORT-1:0]                        axi_lite_tcam_bvalid_i
									     		
    ,output var logic [HSSI_PORT-1:0]                        axi_lite_tcam_bready_o 
									     		      
     //-----READ ADDRESS CHANNEL-------                            
    ,output var logic  [HSSI_PORT-1:0][ADDR_WIDTH - 1:0]    axi_lite_tcam_araddr_o 
    ,output var logic  [HSSI_PORT-1:0]                      axi_lite_tcam_arvalid_o
									      		    
    ,input var logic   [HSSI_PORT-1:0]                      axi_lite_tcam_arready_i 
									      	
     //-----READ DATA CHANNEL----------                        
    ,input var logic [HSSI_PORT-1:0][1:0]                   axi_lite_tcam_rresp_i
     
    ,input var logic  [HSSI_PORT-1:0][DATA_WIDTH - 1:0]     axi_lite_tcam_rdata_i
    ,input var logic  [HSSI_PORT-1:0]                       axi_lite_tcam_rvalid_i   
											
    ,output var logic [HSSI_PORT-1:0]                       axi_lite_tcam_rready_o  
    //-----------------------------------------------------------------------------------------
    // AVMM interface

    ,output var logic [HSSI_PORT-1:0][ADDR_WIDTH-1:0]     tx_avmm_address
    ,output var logic [HSSI_PORT-1:0]                     tx_avmm_read
    ,input  var logic [HSSI_PORT-1:0][DATA_WIDTH-1:0]     tx_avmm_readdata 
    ,output var logic [HSSI_PORT-1:0]                     tx_avmm_write
    ,output var logic [HSSI_PORT-1:0][DATA_WIDTH-1:0]     tx_avmm_writedata
    ,output var logic [HSSI_PORT-1:0][(DATA_WIDTH/8)-1:0] tx_avmm_byteenable
    ,input  var logic [HSSI_PORT-1:0]                     tx_avmm_readdata_valid
									       
    ,output var logic [HSSI_PORT-1:0][ADDR_WIDTH-1:0]     rx_avmm_address
    ,output var logic [HSSI_PORT-1:0]                     rx_avmm_read
    ,input  var logic [HSSI_PORT-1:0][DATA_WIDTH-1:0]     rx_avmm_readdata 
    ,output var logic [HSSI_PORT-1:0]                     rx_avmm_write
    ,output var logic [HSSI_PORT-1:0][DATA_WIDTH-1:0]     rx_avmm_writedata
    ,output var logic [HSSI_PORT-1:0][(DATA_WIDTH/8)-1:0] rx_avmm_byteenable
    ,input  var logic [HSSI_PORT-1:0]                     rx_avmm_readdata_valid

    //----------------------------------------------------------------------------------------- 
    // init_done status
    ,input var logic [HSSI_PORT-1:0]                      tx_init_done	
    ,input var logic [HSSI_PORT-1:0]                      rx_init_done

   );

   import packet_switch_pkg::*;

   localparam MAX_PORTS        = 8; 

   // reserved space after end of port registers
   localparam GEN_END_RSVD_START_ADDR = 
     //(HSSI_PORT > 1) ? (HSSI_PORT*PORT_OFFSET)+RSVD_1_END_ADDR+'h4 :
     (HSSI_PORT > 1) ? ((HSSI_PORT-1)*PORT_OFFSET)+RSVD_1_END_ADDR+'h4 :
        RSVD_1_END_ADDR+'h4;

   // -------------------------------------------------------------------
   logic [1:0][DATA_WIDTH-1:0] avmm_readdata_bp;

   logic [1:0] avmm_write_waitreq, avmm_access_rsvd_posedge,
     avmm_write_dly, avmm_access_rsvd, avmm_access_rsvd_c1, gen_reg_bresp, 
     gen_reg_bresp_w, gen_reg_rresp, gen_reg_rresp_w;

   logic awaddr_fifo_rd, awaddr_fifo_wr, awaddr_fifo_empty,
     awaddr_fifo_overflow, awaddr_fifo_underflow, 
     wdata_fifo_wr, wdata_fifo_rd, wdata_fifo_empty,
     wdata_fifo_overflow, wdata_fifo_underflow, gen_reg_bvalid, gen_reg_rvalid;

   logic awaddr_fifo_occ, wdata_fifo_occ;
   
   logic [ADDR_WIDTH-1:0]      tx_awaddr, rx_awaddr;                                        
            
   logic [DATA_WIDTH-1:0]      wdata_dout, gen_reg_rdata, gen_reg_rdata_w, 
     gen_reg_avmm_writedata;                    
   logic [(DATA_WIDTH/8)-1:0]  gen_reg_avmm_byteenable;                    
   logic [HSSI_PORT-1:0]       tx_wvalid, tx_rvalid,
                               rx_rvalid, tx_awvalid, rx_awvalid;
   logic [(DATA_WIDTH/8)-1:0]  tx_wstrb, rx_wstrb, wstrb_dout;       

   logic [HSSI_PORT-1:0][ADDR_WIDTH-1:0] tx_araddr, rx_araddr;
   
   logic [HSSI_PORT-1:0][DATA_WIDTH-1:0] rx_avmm_readdata_bp, tx_rdata_w,
     rx_rdata_w;

   logic [ADDR_WIDTH-1:0]  awaddr_dout, gen_reg_araddr, gen_reg_avmm_address;

   logic gen_reg_avmm_write, gen_reg_avmm_write_c1, gen_reg_avmm_access_rsvd, 
     gen_reg_avmm_access_rsvd_c1, gen_reg_avmm_read, gen_reg_avmm_read_c1, 
     gen_reg_avmm_access_rsvd_posedge, gen_reg_avmm_write_waitreq, 
     gen_reg_avmm_write_dly, gen_reg_awready, gen_reg_wready, gen_reg_pending,
     gen_reg_awvalid, gen_reg_arready, gen_reg_arvalid, gen_reg_avmm_access_rsvd_dly,
     gen_reg_avmm_readdata_valid, gen_reg_avmm_readdata_valid_c1;
  
   logic [DATA_WIDTH-1:0] gen_reg_avmm_readdata_bp, gen_reg_avmm_readdata;
         
   logic [HSSI_PORT-1:0] tx_bvalid, rx_bvalid, tx_arready, rx_arready,
     tx_awready, rx_awready, tx_wready, rx_wready, tx_pending, rx_pending,
     tx_avmm_write_waitreq, tx_avmm_write_dly, rx_avmm_access_rsvd, 
     rx_avmm_access_rsvd_c1, rx_avmm_write_waitreq, rx_avmm_write_dly,
     tx_arvalid, rx_arvalid, rx_avmm_access_rsvd_posedge, rx_avmm_read_c1,
     rx_avmm_write_c1, tcam_wr_rsp_state, tcam_wr_rsp_pending, 
     tcam_rd_rsp_pending, tcam_rd_rsp_state, awaddr_fifo_rd_w, rx_avmm_access_rsvd_dly;

   logic [HSSI_PORT-1:0][1:0] tx_bresp_w, rx_bresp_w, tx_rresp_w, rx_rresp_w;

   logic [MAX_PORTS-1:0] axi_lite_tcam_bvalid_w, axi_lite_tcam_rvalid_w;
   logic [MAX_PORTS-1:0][1:0] axi_lite_tcam_bresp_w, axi_lite_tcam_rresp_w,
     tx_bresp, rx_bresp, tx_rresp, rx_rresp;
   logic [MAX_PORTS-1:0][DATA_WIDTH-1:0] axi_lite_tcam_rdata_w, tx_rdata, rx_rdata;

    // -------------------------------------------------------------------
    // write request fifos used in case data comes before address

    always_ff @ (posedge axi_lite_clk) begin
      awready <= awaddr_fifo_occ <= 'd1;
      wready <= wdata_fifo_occ <= 'd1;
    end

    always_comb begin
      awaddr_fifo_wr = awvalid & awready;
      wdata_fifo_wr = wvalid & wready;

      arready = (&tx_arready) & (&rx_arready) & (&axi_lite_tcam_arready_i);
    end

    packet_switch_ipbb_sdc_fifo_inff 
      #( .DWD (ADDR_WIDTH)
        ,.NUM_WORDS (2) ) awaddr_fifo
      (//---------------------------------------------------------------
       // clk/rst
       .clk1 (axi_lite_clk)
       ,.clk2 (axi_lite_clk)
       ,.rst (axi_lt_rst)
    
       // inputs
       ,.din (awaddr)
       ,.wrreq (awaddr_fifo_wr)
       ,.rdreq (awaddr_fifo_rd)
    
       // outputs
       ,.dout (awaddr_dout) 
       ,.rdempty (awaddr_fifo_empty)
       ,.rdempty_lkahd () 
       ,.wrfull ()
       ,.wrusedw (awaddr_fifo_occ)
       ,.overflow (awaddr_fifo_overflow)
       ,.underflow (awaddr_fifo_underflow)
       );

    packet_switch_ipbb_sdc_fifo_inff 
      #( .DWD ((DATA_WIDTH/8)
               +DATA_WIDTH)
        ,.NUM_WORDS (2) ) wdata_fifo
      (//---------------------------------------------------------------
       // clk/rst
       .clk1 (axi_lite_clk)
       ,.clk2 (axi_lite_clk)
       ,.rst (axi_lt_rst)
    
       // inputs
       ,.din ({ wstrb
               ,wdata})
       ,.wrreq (wdata_fifo_wr)
       ,.rdreq (wdata_fifo_rd)
    
       // outputs
       ,.dout ({ wstrb_dout
                ,wdata_dout}) 
       ,.rdempty (wdata_fifo_empty)
       ,.rdempty_lkahd () 
       ,.wrfull ()
       ,.wrusedw (wdata_fifo_occ)
       ,.overflow (wdata_fifo_overflow)
       ,.underflow (wdata_fifo_underflow)
       );

    // -------------------------------------------------------------------
    // determine which region is the register access targeting

    // General region
    always_ff @ (posedge axi_lite_clk) begin
      // write request
      if (!awaddr_fifo_empty 
          & !wdata_fifo_empty 
          & gen_reg_awready
          & gen_reg_wready 
          & ((awaddr_dout <= GEN_RSVD_END_ADDR) // gen_rsvd_region
            | (awaddr_dout >= GEN_END_RSVD_START_ADDR)) // after end of port reg map
          & !gen_reg_pending) begin
        gen_reg_awvalid <= '1;
        gen_reg_pending <= '1;
      // end else if (awaddr_fifo_empty 
                  // & wdata_fifo_empty) begin
      end else begin
        gen_reg_awvalid <= '0;
        gen_reg_pending <= '0;
      end  

      // read request
      if (arvalid 
          & gen_reg_arready 
          & ((araddr <= GEN_RSVD_END_ADDR) // gen_rsvd_region
            | (araddr >= GEN_END_RSVD_START_ADDR)) // after end of port reg map
          ) begin
        gen_reg_arvalid <= arvalid;
        gen_reg_araddr  <= araddr;
      end else begin
        gen_reg_arvalid <= '0;
      end  
      if (axi_lt_rst) begin
        gen_reg_awvalid <= '0;
        gen_reg_arvalid <= '0;
        gen_reg_pending <= '0;
        gen_reg_araddr <= '0;
      end      
    end // always_ff

    generate 
     if (DBG_CNTR_EN) begin
      // ----------------------
      // debug counter enabled

      // TX region
      always_ff @ (posedge axi_lite_clk) begin
       for (int i=0; i < HSSI_PORT; i++) begin
        // write request
        if (!awaddr_fifo_empty 
            & !wdata_fifo_empty 
            & tx_awready[i]
            & tx_wready[i] 
            & (( (awaddr_dout >= TX_IGR_ARB_START_ADDR+(i*PORT_OFFSET)) 
             && (awaddr_dout <= TX_IGR_ARB_END_ADDR+(i*PORT_OFFSET))
                )
               |
                ((awaddr_dout >= TX_DBG_CNT_START_ADDR+(i*PORT_OFFSET)) 
              && (awaddr_dout <= TX_DBG_CNT_END_ADDR+(i*PORT_OFFSET)))
                )
            & !tx_pending[i]) begin
          tx_awvalid[i] <= '1;
          tx_pending[i] <= '1;
        // end else if (awaddr_fifo_empty 
                    // & wdata_fifo_empty) begin
        end else begin
          tx_awvalid[i] <= '0;
          tx_pending[i] <= '0;
        end  
      
        // read request
        if (arvalid 
            & tx_arready[i] 
            & (  ((araddr >= TX_IGR_ARB_START_ADDR+(i*PORT_OFFSET))
              && (araddr <= TX_IGR_ARB_END_ADDR+(i*PORT_OFFSET)))
              |  ((araddr >= TX_DBG_CNT_START_ADDR+(i*PORT_OFFSET))
              && (araddr <= TX_DBG_CNT_END_ADDR+(i*PORT_OFFSET)))
                )
            ) begin
          tx_arvalid[i] <= arvalid;
          tx_araddr[i]  <= araddr;
        end else begin
          tx_arvalid <= '0;
        end  
      
        if (axi_lt_rst) begin
          tx_awvalid[i] <= '0;
          tx_arvalid[i] <= '0;
          tx_pending[i] <= '0;
          tx_araddr[i] <= '0;
        end      
      
       end // for
      end // always_ff

    // RX region
    always_ff @ (posedge axi_lite_clk) begin
     for (int i=0; i < HSSI_PORT; i++) begin
      // write request
      if (!awaddr_fifo_empty 
          & !wdata_fifo_empty 
          & rx_awready[i]
          & rx_wready[i]
                // egr_dmux to end of first rsvd region
          & (   ((awaddr_dout >= RX_EGR_DMUX_START_ADDR+(i*PORT_OFFSET))
             &&  (awaddr_dout <= RSVD_0_END_ADDR+(i*PORT_OFFSET)))
 
                // second rsvd region
             || ((awaddr_dout >= RSVD_1_START_ADDR+(i*PORT_OFFSET))
             &&  (awaddr_dout <= RSVD_1_END_ADDR+(i*PORT_OFFSET)))

                // dbg cnt region
             || ((awaddr_dout >= RX_DBG_CNT_START_ADDR+(i*PORT_OFFSET))
             &&  (awaddr_dout <= RX_DBG_CNT_END_ADDR+(i*PORT_OFFSET)))
             )
          & !rx_pending[i]) begin
        rx_awvalid[i] <= '1;
        rx_pending[i] <= '1;
      // end else if (awaddr_fifo_empty 
                  // & wdata_fifo_empty) begin
      end else begin
        rx_awvalid[i] <= '0;
        rx_pending[i] <= '0;
      end      
    
      // read request
      if (arvalid 
          & rx_arready[i] 
                // egr_dmux to end of first rsvd region
          & (   ((araddr >= RX_EGR_DMUX_START_ADDR+(i*PORT_OFFSET))
             &&  (araddr <= RSVD_0_END_ADDR+(i*PORT_OFFSET)))
 
                // second rsvd region
             || ((araddr >= RSVD_1_START_ADDR+(i*PORT_OFFSET))
             &&  (araddr <= RSVD_1_END_ADDR+(i*PORT_OFFSET)))

                // dbg cnt region
             || ((araddr >= RX_DBG_CNT_START_ADDR+(i*PORT_OFFSET))
             &&  (araddr <= RX_DBG_CNT_END_ADDR+(i*PORT_OFFSET)))
             )
          ) begin
        rx_arvalid[i] <= arvalid;
        rx_araddr[i] <= araddr;
      end else begin
        rx_arvalid[i] <= '0;
      end
	
      if (axi_lt_rst) begin
        rx_awvalid[i] <= '0;
        rx_arvalid[i] <= '0;
        rx_pending[i] <= '0;
        rx_araddr[i] <= '0;
      end 

     end // for
    end // always_ff

     end // if (DBG_CNTR_EN)
     else begin
      // ----------------------
      // debug counter disabled

      // TX region
      always_ff @ (posedge axi_lite_clk) begin
       for (int i=0; i < HSSI_PORT; i++) begin
        // write request
        if (!awaddr_fifo_empty 
            & !wdata_fifo_empty 
            & tx_awready[i]
            & tx_wready[i] 
            & ( (awaddr_dout >= TX_IGR_ARB_START_ADDR+(i*PORT_OFFSET)) 
             && (awaddr_dout <= TX_IGR_ARB_END_ADDR+(i*PORT_OFFSET))
                )
            & !tx_pending[i]) begin
          tx_awvalid[i] <= '1;
          tx_pending[i] <= '1;
        // end else if (awaddr_fifo_empty 
                    // & wdata_fifo_empty) begin
          end else begin
          tx_awvalid[i] <= '0;
          tx_pending[i] <= '0;
        end  
      
        // read request
        if (arvalid 
            & tx_arready[i] 
            & (  (araddr >= TX_IGR_ARB_START_ADDR+(i*PORT_OFFSET))
              && (araddr <= TX_IGR_ARB_END_ADDR+(i*PORT_OFFSET))
                )
            ) begin
          tx_arvalid[i] <= arvalid;
          tx_araddr[i]  <= araddr;
        end else begin
          tx_arvalid[i] <= '0;
        end  
      
        if (axi_lt_rst) begin
          tx_awvalid[i] <= '0;
          tx_arvalid[i] <= '0;
          tx_pending[i] <= '0;
          tx_araddr[i] <= '0;
        end      
      
       end // for
      end // always_ff

    // RX region
    always_ff @ (posedge axi_lite_clk) begin
     for (int i=0; i < HSSI_PORT; i++) begin
      // write request
      if (!awaddr_fifo_empty 
          & !wdata_fifo_empty 
          & rx_awready[i]
          & rx_wready[i]
                // egr_dmux to end of first rsvd region
          & (   ((awaddr_dout >= RX_EGR_DMUX_START_ADDR+(i*PORT_OFFSET))
             &&  (awaddr_dout <= RSVD_0_END_ADDR+(i*PORT_OFFSET)))
 
                // second rsvd region
             || ((awaddr_dout >= RSVD_1_START_ADDR+(i*PORT_OFFSET))
             &&  (awaddr_dout <= RSVD_1_END_ADDR+(i*PORT_OFFSET)))
             )
          & !rx_pending[i]) begin
        rx_awvalid[i] <= '1;
        rx_pending[i] <= '1;
      // end else if (awaddr_fifo_empty 
                  // & wdata_fifo_empty) begin
       end else begin
        rx_awvalid[i] <= '0;
        rx_pending[i] <= '0;
      end      
    
      // read request
      if (arvalid 
          & rx_arready[i] 
                // egr_dmux to end of first rsvd region
          & (   ((araddr >= RX_EGR_DMUX_START_ADDR+(i*PORT_OFFSET))
             &&  (araddr <= RSVD_0_END_ADDR+(i*PORT_OFFSET)))
 
                // second rsvd region
             || ((araddr >= RSVD_1_START_ADDR+(i*PORT_OFFSET))
             &&  (araddr <= RSVD_1_END_ADDR+(i*PORT_OFFSET)))
             )
          ) begin
        rx_arvalid[i] <= arvalid;
        rx_araddr[i] <= araddr;
      end else begin
        rx_arvalid[i] <= '0;
      end
	
      if (axi_lt_rst) begin
        rx_awvalid[i] <= '0;
        rx_arvalid[i] <= '0;
        rx_pending[i] <= '0;
        rx_araddr[i] <= '0;
      end 

     end // for
    end // always_ff
     
     end // if (!DBG_CNTR_EN)
    endgenerate

    // TCAM region
    always_comb begin
     for (int i=0; i < HSSI_PORT; i++) begin
      // write request
      if (!awaddr_fifo_empty 
          & !wdata_fifo_empty 
          & ((awaddr_dout >= TCAM_START_ADDR+(i*PORT_OFFSET)) 
              && (awaddr_dout <= TCAM_END_ADDR+(i*PORT_OFFSET)))
           ) begin
        axi_lite_tcam_awvalid_o[i] = '1;
        axi_lite_tcam_awaddr_o[i]  = awaddr_dout - (TCAM_START_ADDR[ADDR_WIDTH-1:0]+(i*PORT_OFFSET));
   
        axi_lite_tcam_wdata_o[i]  = wdata_dout;
        axi_lite_tcam_wvalid_o[i] = '1;
        axi_lite_tcam_wstrb_o[i]  = wstrb_dout;
        
      end else begin
        axi_lite_tcam_awvalid_o[i] = '0;
        axi_lite_tcam_awaddr_o[i] = '0;

        axi_lite_tcam_wdata_o[i] = '0;
        axi_lite_tcam_wvalid_o[i] = '0;
        axi_lite_tcam_wstrb_o[i] = '0;
      end

      // read request
      if (arvalid & (araddr >= TCAM_START_ADDR+(i*PORT_OFFSET)) 
                  & (araddr <= TCAM_END_ADDR+(i*PORT_OFFSET))) begin
        axi_lite_tcam_araddr_o[i]  = araddr - (TCAM_START_ADDR[ADDR_WIDTH-1:0]+(i*PORT_OFFSET));
        axi_lite_tcam_arvalid_o[i] = arvalid;
      end else begin
        axi_lite_tcam_araddr_o[i]  = '0;
        axi_lite_tcam_arvalid_o[i] = '0;
      end

     end // for

    end

    // tcam_wr_rsp_pending, tcam_rd_rsp_pending : assert pending wr or rd response
    always_ff @(posedge axi_lite_clk) begin
     for (int i=0; i < HSSI_PORT; i++) begin
      if (!awaddr_fifo_empty & !wdata_fifo_empty 
          & ((awaddr_dout >= TCAM_START_ADDR+(i*PORT_OFFSET)) 
              && (awaddr_dout <= TCAM_END_ADDR+(i*PORT_OFFSET)))
          )
        tcam_wr_rsp_pending[i] <= '1;
      else
        tcam_wr_rsp_pending[i] <= '0;

      if (arvalid & (araddr >= TCAM_START_ADDR+(i*PORT_OFFSET)) 
                  & (araddr <= TCAM_END_ADDR+(i*PORT_OFFSET)))
        tcam_rd_rsp_pending[i] <= '1;
      else
        tcam_rd_rsp_pending[i] <= '0;
     end // for
    end

    // tcam_wr_rsp_state: state to hold until received bvalid
    always_ff @(posedge axi_lite_clk) begin
     for (int i=0; i < HSSI_PORT; i++) begin
      if (tcam_wr_rsp_pending[i] & !tcam_wr_rsp_state[i])
        tcam_wr_rsp_state[i] <= '1;
      else if (tcam_wr_rsp_state[i] & axi_lite_tcam_bvalid_i[i] & axi_lite_tcam_bready_o[i])
        tcam_wr_rsp_state[i] <= '0;
	  	  
      if (axi_lt_rst)
        tcam_wr_rsp_state[i] <= '0;
     end // for
    end   


    // tcam_rd_rsp_state: state to hold until received rvalid
    always_ff @(posedge axi_lite_clk) begin
     for (int i=0; i < HSSI_PORT; i++) begin
      if (tcam_rd_rsp_pending[i] & !tcam_rd_rsp_state[i])
        tcam_rd_rsp_state[i] <= '1;
      else if (tcam_rd_rsp_state[i] & axi_lite_tcam_rvalid_i[i] & axi_lite_tcam_rready_o[i])
        tcam_rd_rsp_state[i] <= '0;
	  
      if (axi_lt_rst)
        tcam_rd_rsp_state[i] <= '0;
     end // for
    end    

    always_comb begin
     for (int i=0; i < HSSI_PORT; i++) begin
      // read from awaddr_fifo and wdata_fifo
      if (!awaddr_fifo_empty & !wdata_fifo_empty &
           ((awaddr_dout >= TCAM_START_ADDR+(i*PORT_OFFSET)) 
           && (awaddr_dout <= TCAM_END_ADDR+(i*PORT_OFFSET))) 
           & axi_lite_tcam_awready_i[i] & axi_lite_tcam_wready_i[i])
          awaddr_fifo_rd_w[i] = '1;
      else 
        awaddr_fifo_rd_w[i] = '0;
      
     end // for

      awaddr_fifo_rd = |awaddr_fifo_rd_w | (|rx_awvalid) | (|tx_awvalid) | gen_reg_awvalid;
      wdata_fifo_rd  = awaddr_fifo_rd;
    end   

    genvar i;
    generate
    for (i=0; i < HSSI_PORT; i++) begin
     packet_switch_pipe_dly #( 
              .W(1),
              .N(AVMM_MAX_LATENCY)) tx_avmm_pipe
          (.clk (tx_clk[i])
          ,.dIn (tx_avmm_write[i])
          ,.dOut (tx_avmm_write_dly[i]) );
	 
     always_ff @ (posedge tx_clk[i]) begin
       // waitreq
       tx_avmm_write_waitreq[i] <= !tx_avmm_write_dly[i];
     end

    packet_switch_pipe_dly #( 
             .W(1+1),
             .N(AVMM_MAX_LATENCY)) rx_avmm_pipe
         (.clk (rx_clk[i])
         ,.dIn ({rx_avmm_write[i]
                ,rx_avmm_access_rsvd[i]})
         ,.dOut ({rx_avmm_write_dly[i]
                 ,rx_avmm_access_rsvd_dly[i]}) );

    end // for
    endgenerate 

    // General region AVMM, General region reserved accesses, reserved end space
    always_ff @ (posedge axi_lite_clk) begin
      // if ( (gen_reg_avmm_read | gen_reg_avmm_write) & 
      if (gen_reg_avmm_read & 
	      ( (gen_reg_avmm_address >= GEN_RSVD_START_ADDR)
          & (gen_reg_avmm_address <= GEN_RSVD_END_ADDR))

          | (gen_reg_avmm_address >= GEN_END_RSVD_START_ADDR) 
           ) begin
        gen_reg_avmm_access_rsvd <= '1;
        gen_reg_avmm_readdata_bp <= '0;
      end else begin
        gen_reg_avmm_access_rsvd <= '0;
        gen_reg_avmm_readdata_bp <= gen_reg_avmm_readdata;
      end
      
      // cycle delay
      gen_reg_avmm_readdata_valid_c1 <= gen_reg_avmm_readdata_valid;
      
      // waitreq
      gen_reg_avmm_write_waitreq <= !gen_reg_avmm_write_dly 
                                    & !gen_reg_avmm_access_rsvd_dly;
    end // always_ff  

    packet_switch_pipe_dly #( 
             .W(1+1),
             .N(AVMM_MAX_LATENCY)) gen_reg_avmm_pipe
         (.clk (axi_lite_clk)
         ,.dIn ({gen_reg_avmm_write
               ,gen_reg_avmm_access_rsvd})
         ,.dOut ({gen_reg_avmm_write_dly,
                  gen_reg_avmm_access_rsvd_dly}) );
    
    // RX AVMM, RX reserved accesses
    generate
     for (i=0; i < HSSI_PORT; i++) begin
     
     if (DBG_CNTR_EN) begin

      always_ff @ (posedge rx_clk[i]) begin
        if ( (rx_avmm_read[i]) & 
	        (((rx_avmm_address[i] >= DBG_CNT_RSVD_START_ADDR+(i*PORT_OFFSET))
            & (rx_avmm_address[i] <= RSVD_0_END_ADDR+(i*PORT_OFFSET)))
	  
            | ((rx_avmm_address[i] >= RSVD_1_START_ADDR+(i*PORT_OFFSET))
            &  (rx_avmm_address[i] <= RSVD_1_END_ADDR+(i*PORT_OFFSET))))
            ) begin
          rx_avmm_access_rsvd[i] <= '1;
          rx_avmm_readdata_bp[i] <= '0;
        end else begin
          rx_avmm_access_rsvd[i] <= '0;
          rx_avmm_readdata_bp[i] <= rx_avmm_readdata[i];
        end
        
        // cycle delay
        rx_avmm_access_rsvd_c1[i] <= rx_avmm_access_rsvd[i];
        rx_avmm_read_c1[i]        <= rx_avmm_read[i];
        rx_avmm_write_c1[i]       <= rx_avmm_write[i];
        
        // waitreq
         rx_avmm_write_waitreq[i] <= !rx_avmm_write_dly[i] 
                                     & !rx_avmm_access_rsvd_dly[i];
       end // always_ff  

     end // if (DBG_CNTR_EN)
     else begin

      always_ff @ (posedge rx_clk[i]) begin
        if ( (rx_avmm_read[i]) & 
	        (((rx_avmm_address[i] >= RSVD_0_START_ADDR+(i*PORT_OFFSET))
            & (rx_avmm_address[i] <= RSVD_0_END_ADDR+(i*PORT_OFFSET)))
	  
            | ((rx_avmm_address[i] >= RSVD_1_START_ADDR+(i*PORT_OFFSET))
            &  (rx_avmm_address[i] <= RSVD_1_END_ADDR+(i*PORT_OFFSET))))
            ) begin
          rx_avmm_access_rsvd[i] <= '1;
          rx_avmm_readdata_bp[i] <= '0;
        end else begin
          rx_avmm_access_rsvd[i] <= '0;
          rx_avmm_readdata_bp[i] <= rx_avmm_readdata[i];
        end
        
        // waitreq
         rx_avmm_write_waitreq[i] <= !rx_avmm_write_dly[i] 
                                     & !rx_avmm_access_rsvd_dly[i];
       end // always_ff  

     end // if (!DBG_CNTR_EN)

    end // for
    endgenerate

    // -------------------------------------------------------------------
    // combine tx, rx, TCAM output signals

    always_comb begin

     axi_lite_tcam_bvalid_w = '0;
     axi_lite_tcam_bresp_w = '0;
     axi_lite_tcam_rvalid_w = '0;
     axi_lite_tcam_rresp_w = '0;
     axi_lite_tcam_rdata_w = '0;

     tx_rresp = '0;
     rx_rresp = '0;

     tx_bresp = '0;
     rx_bresp = '0;

     tx_rdata = '0;
     rx_rdata = '0;

     gen_reg_bresp = gen_reg_bvalid ? gen_reg_bresp_w : '0;
     gen_reg_rresp = gen_reg_rvalid ? gen_reg_rresp_w : '0;
     gen_reg_rdata = gen_reg_rvalid ? gen_reg_rdata_w : '0;

     for (int i=0; i < HSSI_PORT; i++) begin
        axi_lite_tcam_bready_o[i] = bready;
        axi_lite_tcam_rready_o[i] = rready;
        axi_lite_tcam_bvalid_w[i] = axi_lite_tcam_bvalid_i[i];
        axi_lite_tcam_bresp_w[i] = axi_lite_tcam_bvalid_i[i] ? axi_lite_tcam_bresp_i[i] : '0;
        axi_lite_tcam_rvalid_w[i] = axi_lite_tcam_rvalid_i[i];
        axi_lite_tcam_rresp_w[i] = axi_lite_tcam_rvalid_i[i] ? axi_lite_tcam_rresp_i[i] : '0;
        axi_lite_tcam_rdata_w[i] = axi_lite_tcam_rvalid_i[i] ? axi_lite_tcam_rdata_i[i] : '0;        

        tx_rresp[i] = tx_rvalid[i] ? tx_rresp_w[i] : '0;
        rx_rresp[i] = rx_rvalid[i] ? rx_rresp_w[i] : '0;

        tx_bresp[i] = tx_bvalid[i] ? tx_bresp_w[i] : '0;
        rx_bresp[i] = rx_bvalid[i] ? rx_bresp_w[i] : '0;

        tx_rdata[i] = tx_rvalid[i] ? tx_rdata_w[i] : '0;
        rx_rdata[i] = rx_rvalid[i] ? rx_rdata_w[i] : '0;

     end // for

      if (axi_lt_rst) begin
        bvalid = '0;
        rvalid = '0;
        bresp = '0;
        rresp = '0;
        rdata = '0;
      end else begin

         // mask off stale tcam signals if no pending TCAM transaction
        if (|tcam_wr_rsp_state) begin
          bvalid = axi_lite_tcam_bvalid_w[0] 
                 | axi_lite_tcam_bvalid_w[1]
                 | axi_lite_tcam_bvalid_w[2]
                 | axi_lite_tcam_bvalid_w[3]
                 | axi_lite_tcam_bvalid_w[4]
                 | axi_lite_tcam_bvalid_w[5]
                 | axi_lite_tcam_bvalid_w[6]
                 | axi_lite_tcam_bvalid_w[7];

          bresp  = axi_lite_tcam_bresp_w[0]
                 | axi_lite_tcam_bresp_w[1]
                 | axi_lite_tcam_bresp_w[2]
                 | axi_lite_tcam_bresp_w[3]
                 | axi_lite_tcam_bresp_w[4]
                 | axi_lite_tcam_bresp_w[5]
                 | axi_lite_tcam_bresp_w[6]
                 | axi_lite_tcam_bresp_w[7];
        end else begin
          bvalid = (|tx_bvalid) | (|rx_bvalid) | gen_reg_bvalid ;
          bresp = gen_reg_bresp
                | tx_bresp[0]
                | tx_bresp[1]
                | tx_bresp[2]
                | tx_bresp[3]
                | tx_bresp[4]
                | tx_bresp[5]
                | tx_bresp[6]
                | tx_bresp[7]

                | rx_bresp[0]
                | rx_bresp[1]
                | rx_bresp[2]
                | rx_bresp[3]
                | rx_bresp[4]
                | rx_bresp[5]
                | rx_bresp[6]
                | rx_bresp[7];
        end

        // mask off stale tcam signals if no pending TCAM transaction
        if (|tcam_rd_rsp_state) begin
          rvalid = axi_lite_tcam_rvalid_w[0]
                 | axi_lite_tcam_rvalid_w[1]
                 | axi_lite_tcam_rvalid_w[2]
                 | axi_lite_tcam_rvalid_w[3]
                 | axi_lite_tcam_rvalid_w[4]
                 | axi_lite_tcam_rvalid_w[5]
                 | axi_lite_tcam_rvalid_w[6]
                 | axi_lite_tcam_rvalid_w[7];

          rresp = axi_lite_tcam_rresp_w[0]
                | axi_lite_tcam_rresp_w[1]
                | axi_lite_tcam_rresp_w[2]
                | axi_lite_tcam_rresp_w[3]
                | axi_lite_tcam_rresp_w[4]
                | axi_lite_tcam_rresp_w[5]
                | axi_lite_tcam_rresp_w[6]
                | axi_lite_tcam_rresp_w[7];

          rdata = axi_lite_tcam_rdata_w[0]
                | axi_lite_tcam_rdata_w[1]
                | axi_lite_tcam_rdata_w[2]
                | axi_lite_tcam_rdata_w[3]
                | axi_lite_tcam_rdata_w[4]
                | axi_lite_tcam_rdata_w[5]
                | axi_lite_tcam_rdata_w[6]
                | axi_lite_tcam_rdata_w[7];
        end else begin
          rvalid = (|tx_rvalid) | (|rx_rvalid) | gen_reg_rvalid;
          rresp = gen_reg_rresp
                | tx_rresp[0]
                | tx_rresp[1]
                | tx_rresp[2]
                | tx_rresp[3]
                | tx_rresp[4]
                | tx_rresp[5]
                | tx_rresp[6]
                | tx_rresp[7]

                | rx_rresp[0]
                | rx_rresp[1]
                | rx_rresp[2]
                | rx_rresp[3]
                | rx_rresp[4]
                | rx_rresp[5]
                | rx_rresp[6]
                | rx_rresp[7];

          rdata = gen_reg_rdata 
                | tx_rdata[0]
                | tx_rdata[1] 
                | tx_rdata[2] 
                | tx_rdata[3] 
                | tx_rdata[4] 
                | tx_rdata[5] 
                | tx_rdata[6] 
                | tx_rdata[7]

                | rx_rdata[0]
                | rx_rdata[1]
                | rx_rdata[2]
                | rx_rdata[3]
                | rx_rdata[4]
                | rx_rdata[5]
                | rx_rdata[6]
                | rx_rdata[7];
        end

      end

    end // always_comb

    // -------------------------------------------------------------------

    // general register region
    ipbb_axi_lite_to_avmm_range_check #(
        .DEVICE_FAMILY   (DEVICE_FAMILY)
       ,.AWADDR_WIDTH    (ADDR_WIDTH)
       ,.WDATA_WIDTH     (DATA_WIDTH)
       ,.ARADDR_WIDTH    (ADDR_WIDTH)
       ,.RDATA_WIDTH     (DATA_WIDTH)
       ,.AVMMADDR_WIDTH  (ADDR_WIDTH)
       ,.AVMMWDATA_WIDTH (DATA_WIDTH)
       ,.AVMMRDATA_WIDTH (DATA_WIDTH) ) axi_lt_to_avmm_sclk (
     
      // inputs
       .clk            (axi_lite_clk)                     
      ,.rst_n          (!axi_lt_rst)
    
      // Write Address Channel
      // inputs
      ,.awaddr  (awaddr_dout)              
      ,.awvalid (gen_reg_awvalid)    
      // output          
      ,.awready (gen_reg_awready)
    
      // Write Data Channel
      // inputs
      ,.wdata  (wdata_dout)              
      ,.wvalid (gen_reg_awvalid)
      ,.wstrb  (wstrb_dout)
      // output 
      ,.wready (gen_reg_wready)
    
      // Write Response Channel
      // outputs 
      ,.bresp  (gen_reg_bresp_w)              
      ,.bvalid (gen_reg_bvalid)           
      // input   
      ,.bready (bready)
    
      // Read Address Channel
      // inputs   
      ,.araddr  (gen_reg_araddr)
      ,.arvalid (gen_reg_arvalid)
      // output
      ,.arready (gen_reg_arready)
    
      // Read Data Channel
      // outputs 
      ,.rresp  (gen_reg_rresp_w)
      ,.rdata  (gen_reg_rdata_w)
      ,.rvalid (gen_reg_rvalid)
      // input
      ,.rready (rready)
    
      // AVMM initiator interface
      // outputs
      ,.avmm_address              (gen_reg_avmm_address)
      ,.avmm_read                 (gen_reg_avmm_read)
      ,.avmm_write                (gen_reg_avmm_write)
      ,.avmm_writedata            (gen_reg_avmm_writedata)
      ,.avmm_byteenable           (gen_reg_avmm_byteenable)
      // inputs
      ,.avmm_readdata             (gen_reg_avmm_readdata_bp)
      ,.avmm_waitrequest          (!gen_reg_avmm_readdata_valid_c1 & gen_reg_avmm_write_waitreq)
                                    // & !gen_reg_avmm_access_rsvd_posedge)
      ,.avmm_address_out_of_range ('0) // access beyond addr map
     );

   generate 
    for (i=0; i < HSSI_PORT; i++) begin: gen_axi_lt_to_avmm

   // tx pipeline
   ipbb_axi_lite_to_avmm_range_check_cdc #(
       .DEVICE_FAMILY   (DEVICE_FAMILY)
      ,.AWADDR_WIDTH    (ADDR_WIDTH)
      ,.WDATA_WIDTH     (DATA_WIDTH)
      ,.ARADDR_WIDTH    (ADDR_WIDTH)
      ,.RDATA_WIDTH     (DATA_WIDTH)
      ,.AVMMADDR_WIDTH  (ADDR_WIDTH)
      ,.AVMMWDATA_WIDTH (DATA_WIDTH)
      ,.AVMMRDATA_WIDTH (DATA_WIDTH) ) axi_lt_to_avmm_tx (
    
     // inputs
      .axi_lite_clk   (axi_lite_clk)                     
     ,.axi_lite_rst_n (!axi_lt_rst)
     ,.avmm_clk       (tx_clk[i])              
     ,.avmm_rst_n     (!tx_rst[i])
   
     // Write Address Channel
     // inputs
     ,.awaddr  (awaddr_dout)              
     ,.awvalid (tx_awvalid[i])    
     // output          
     ,.awready (tx_awready[i])
   
     // Write Data Channel
     // inputs
     ,.wdata  (wdata_dout)              
     ,.wvalid (tx_awvalid[i])
     ,.wstrb  (wstrb_dout)
     // output 
     ,.wready (tx_wready[i])
   
     // Write Response Channel
     // outputs 
     ,.bresp  (tx_bresp_w[i])              
     ,.bvalid (tx_bvalid[i])           
     // input   
     ,.bready (bready)
   
     // Read Address Channel
     // inputs   
     ,.araddr  (tx_araddr[i])
     ,.arvalid (tx_arvalid[i])
     // output
     ,.arready (tx_arready[i])
   
     // Read Data Channel
     // outputs 
     ,.rresp  (tx_rresp_w[i])
     ,.rdata  (tx_rdata_w[i])
     ,.rvalid (tx_rvalid[i])
     // input
     ,.rready (rready)
   
     // AVMM initiator interface
     // outputs
     ,.avmm_address              (tx_avmm_address[i])
     ,.avmm_read                 (tx_avmm_read[i])
     ,.avmm_write                (tx_avmm_write[i])
     ,.avmm_writedata            (tx_avmm_writedata[i])
     ,.avmm_byteenable           (tx_avmm_byteenable[i])
     // inputs
     ,.avmm_readdata             (tx_avmm_readdata[i])
     ,.avmm_waitrequest          (!tx_avmm_readdata_valid[i] & tx_avmm_write_waitreq[i]) 
                                  // | !tx_avmm_access_rsvd_posedge)

     ,.avmm_address_out_of_range ('0) // access beyond addr map
    );
   
   // rx pipeline
   ipbb_axi_lite_to_avmm_range_check_cdc #(
       .DEVICE_FAMILY   (DEVICE_FAMILY)
      ,.AWADDR_WIDTH    (ADDR_WIDTH)
      ,.WDATA_WIDTH     (DATA_WIDTH)
      ,.ARADDR_WIDTH    (ADDR_WIDTH)
      ,.RDATA_WIDTH     (DATA_WIDTH)
      ,.AVMMADDR_WIDTH  (ADDR_WIDTH)
      ,.AVMMWDATA_WIDTH (DATA_WIDTH)
      ,.AVMMRDATA_WIDTH (DATA_WIDTH) ) axi_lt_to_avmm_rx (
    
     // inputs
      .axi_lite_clk   (axi_lite_clk)                     
     ,.axi_lite_rst_n (!axi_lt_rst)
     ,.avmm_clk       (rx_clk[i])              
     ,.avmm_rst_n     (!rx_rst[i])
   
     // Write Address Channel
     // inputs
     ,.awaddr  (awaddr_dout)              
     ,.awvalid (rx_awvalid[i])    
     // output          
     ,.awready (rx_awready[i])
   
     // Write Data Channel
     // inputs
     ,.wdata  (wdata_dout)              
     ,.wvalid (rx_awvalid[i])
     ,.wstrb  (wstrb_dout)
     // output 
     ,.wready (rx_wready[i])
   
     // Write Response Channel
     // outputs 
     ,.bresp  (rx_bresp_w[i])              
     ,.bvalid (rx_bvalid[i])           
     // input   
     ,.bready (bready)
   
     // Read Address Channel
     // inputs   
     ,.araddr  (rx_araddr[i])
     ,.arvalid (rx_arvalid[i])
     // output
     ,.arready (rx_arready[i])
   
     // Read Data Channel
     // outputs 
     ,.rresp  (rx_rresp_w[i])
     ,.rdata  (rx_rdata_w[i])
     ,.rvalid (rx_rvalid[i])
     // input
     ,.rready (rready)
   
     // AVMM initiator interface
     // outputs
     ,.avmm_address              (rx_avmm_address[i])
     ,.avmm_read                 (rx_avmm_read[i])
     ,.avmm_write                (rx_avmm_write[i])
     ,.avmm_writedata            (rx_avmm_writedata[i])
     ,.avmm_byteenable           (rx_avmm_byteenable[i])
     // inputs
     ,.avmm_readdata             (rx_avmm_readdata_bp[i])
     ,.avmm_waitrequest          (!rx_avmm_readdata_valid[i] & rx_avmm_write_waitreq[i])
                                  // & !rx_avmm_access_rsvd_posedge[i])
     ,.avmm_address_out_of_range ('0) // access beyond addr map
    );
 
    end // for
   endgenerate

   // csr intf
   general_csr_intf
   #( .BASE_ADDR  (GEN_START_ADDR) 
     ,.MAX_ADDR   (GEN_END_ADDR)
     ,.ADDR_WIDTH (ADDR_WIDTH)
     ,.DATA_WIDTH (DATA_WIDTH)
     ,.HSSI_PORT  (HSSI_PORT)
     ,.DMA_CH     (DMA_CH)
     ,.DBG_CNTR_EN (DBG_CNTR_EN)
      ) csr_intf
   (//------------------------------------------------------------------------------------
    // Clock
    // input
    .clk (axi_lite_clk)
  
    // Reset
    ,.rst (axi_lt_rst)
  
    //-----------------------------------------------------------------------------------------
    // AVMM interface
  
    // inputs
    ,.avmm_address   (gen_reg_avmm_address)
    ,.avmm_read      (gen_reg_avmm_read)
    ,.avmm_write     (gen_reg_avmm_write)
    ,.avmm_writedata (gen_reg_avmm_writedata)
    ,.avmm_byteenable (gen_reg_avmm_byteenable)
  
    // outputs
    ,.avmm_readdata (gen_reg_avmm_readdata)  
    ,.avmm_readdata_valid (gen_reg_avmm_readdata_valid)
  
    //-----------------------------------------------------------------------------------------
    // init_done
    // inputs
    ,.rx_init_done (rx_init_done)
    ,.tx_init_done (tx_init_done)
  
   );


endmodule
