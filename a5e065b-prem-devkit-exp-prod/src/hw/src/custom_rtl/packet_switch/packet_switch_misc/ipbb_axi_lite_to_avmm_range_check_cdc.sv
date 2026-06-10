//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

//--------------------------------------------------------------------------------------------
// Description: ipbb_axi_lite_to_avmm_range_check_cdc
// 
// - This module converts AXI4-Lite to AVMM Bridge with avmm_address_out_of_range input 
//   which indicates an out-of-range address access.
// - Handles clock domain crossing
// - Supports 32b and 64b address widths.
// - Supports AWREADYLATENCY, WREADYLATENCY, ARREADYLATENCY.
// - Supports single or multiple pending transactions.
//
//--------------------------------------------------------------------------------------------

module ipbb_axi_lite_to_avmm_range_check_cdc #(
	parameter DEVICE_FAMILY  = "Agilex",
	parameter AWADDR_WIDTH   = 32,
    parameter WDATA_WIDTH    = 512,
    parameter ARADDR_WIDTH   = 32,
    parameter RDATA_WIDTH    = 512,
    parameter AWVALID_PSTAGES = 0, // 0 only supported.
    parameter WVALID_PSTAGES  = 0, // 0 only supported.
    parameter BVALID_PSTAGES  = 0, // 0 only supported.
    parameter ARVALID_PSTAGES = 0, // 0 only supported.
    parameter RVALID_PSTAGES  = 0, // 0 only supported.
    parameter AWREADY_PSTAGES = 0, // 0 only supported.
    parameter WREADY_PSTAGES  = 0, // 0 only supported.
    parameter BREADY_PSTAGES  = 0, // 0 only supported.
    parameter ARREADY_PSTAGES = 0, // 0 only supported.
    parameter RREADY_PSTAGES  = 0, // 0 only supported.
    parameter AWREADYLATENCY  = AWVALID_PSTAGES + AWREADY_PSTAGES, // 0 only supported. 
    parameter WREADYLATENCY   = WVALID_PSTAGES + WREADY_PSTAGES, // 0 only supported.
    parameter BREADYLATENCY   = BVALID_PSTAGES + BREADY_PSTAGES, // 0 only supported.
    parameter ARREADYLATENCY  = ARVALID_PSTAGES + ARREADY_PSTAGES, // 0 only supported.
    parameter RREADYLATENCY   = RVALID_PSTAGES + RREADY_PSTAGES, // 0 only supported.
    parameter AVMMADDR_WIDTH  = 32,
    parameter AVMMWDATA_WIDTH = 32,
    parameter AVMMRDATA_WIDTH = 32,
    parameter FIFO_DEPTH      = 4,
    parameter RAM_BLOCK_TYPE  = "AUTO",
	parameter SINGLE_PENDING_TRANSACTION = 0
	
)   (
	input logic                           axi_lite_clk,                           
	input logic                           axi_lite_rst_n,                         
	input logic                           avmm_clk,                           
	input logic                           avmm_rst_n,                         
	
	// Write Address Channel
	input logic [AWADDR_WIDTH-1:0]        awaddr,                        
    input logic                           awvalid,                       
    output logic                          awready,                       
	
	// Write Data Channel
    input logic [WDATA_WIDTH-1:0]         wdata,                         
    input logic                           wvalid,
    input logic [(WDATA_WIDTH/8)-1:0]     wstrb,	
    output logic                          wready,                        
	
	// Write Response Channel
    output logic [1:0]                    bresp,                         
    output logic                          bvalid,                        
    input logic                           bready, 
	
	// Read Address Channel
    input logic [ARADDR_WIDTH-1:0]        araddr,
    input logic                           arvalid,
    output logic                          arready, 
	
	// Read Data Channel
    output logic [1:0]                    rresp,
    output logic [RDATA_WIDTH-1:0]        rdata,
    output logic                          rvalid,
    input logic                           rready,

    // AVMM
    output logic [AVMMADDR_WIDTH-1:0]      avmm_address,
    output logic                           avmm_read,
    input  logic [AVMMRDATA_WIDTH-1:0]     avmm_readdata, 
    output logic                           avmm_write,
    output logic [AVMMWDATA_WIDTH-1:0]     avmm_writedata,
    output logic [(AVMMWDATA_WIDTH/8)-1:0] avmm_byteenable,
    input  logic                           avmm_waitrequest,
	
	input  logic                           avmm_address_out_of_range // triggers DECERR for BRESP/RRESP
);

localparam WADDR_FIFO_DEPTH = FIFO_DEPTH;
localparam WADDR_SKD_CNT = WADDR_FIFO_DEPTH - 1;
localparam WDATA_FIFO_DEPTH = FIFO_DEPTH;
localparam WDATA_SKD_CNT = WDATA_FIFO_DEPTH - 1;
localparam ARADDR_FIFO_DEPTH = FIFO_DEPTH;
localparam ARADDR_SKD_CNT = ARADDR_FIFO_DEPTH - 1;
localparam RDATA_FIFO_DEPTH  = FIFO_DEPTH;
localparam BRESP_FIFO_DEPTH  = FIFO_DEPTH;

localparam BRESP_WIDTH = 2;

localparam WADDR_FIFO_WIDTH = (SINGLE_PENDING_TRANSACTION == 1) ? 1 : AWADDR_WIDTH;
localparam RADDR_FIFO_WIDTH = (SINGLE_PENDING_TRANSACTION == 1) ? 1 : ARADDR_WIDTH;
localparam WDATA_FIFO_WIDTH = (SINGLE_PENDING_TRANSACTION == 1) ? 1 : WDATA_WIDTH+(WDATA_WIDTH/8);
localparam RDATA_FIFO_WIDTH = (SINGLE_PENDING_TRANSACTION == 1) ? 1 : RDATA_WIDTH;
localparam BRESP_FIFO_WIDTH = (SINGLE_PENDING_TRANSACTION == 1) ? 1 : BRESP_WIDTH;


logic write_pending, read_pending;
logic [$clog2(WADDR_FIFO_DEPTH)-1:0] waddr_fifo_cnt;
logic [$clog2(WDATA_FIFO_DEPTH)-1:0] wdata_fifo_cnt;
logic [$clog2(ARADDR_FIFO_DEPTH)-1:0] araddr_fifo_cnt;

logic waddr_fifo_push, waddr_fifo_pop, waddr_fifo_full, waddr_fifo_empty;
logic wdata_fifo_push, wdata_fifo_full, wdata_fifo_pop, wdata_fifo_empty ;
logic araddr_fifo_push, araddr_fifo_full, araddr_fifo_pop, araddr_fifo_empty;

logic [AWADDR_WIDTH-1:0] waddr_fifo_wr_data;
logic [WDATA_WIDTH-1:0] wdata_fifo_wr_data;
logic [ARADDR_WIDTH-1:0] araddr_fifo_wr_data;

logic [WADDR_FIFO_WIDTH-1:0] waddr_fifo_wr_data_reg, waddr_fifo_rd_data;
logic [WDATA_WIDTH-1:0] wdata_fifo_wr_data_reg, wdata_fifo_rd_data;
logic [RADDR_FIFO_WIDTH-1:0] araddr_fifo_wr_data_reg, araddr_fifo_rd_data;

logic [RDATA_FIFO_WIDTH-1:0] rdata_fifo_rd_data, rdata_fifo_wr_data_reg, rdata_popped;
logic [1:0] bresp_reg, rresp_reg;
logic bvalid_reg, rvalid_reg;

logic [AVMMADDR_WIDTH-1:0] avmm_address_reg;
logic [AVMMWDATA_WIDTH-1:0] avmm_writedata_reg;
logic avmm_write_reg, avmm_read_reg;

logic [AWADDR_WIDTH-1:0]        awaddr_regN;
logic                           awvalid_regN;
logic                          awready_w, awready_regN;

logic [WDATA_WIDTH-1:0]         wdata_regN; 
logic                           wvalid_regN;
logic                          wready_w, wready_regN;

logic [ARADDR_WIDTH-1:0]        araddr_regN;
logic                           arvalid_regN;
logic                          arready_w, arready_regN;

 logic [1:0]                    bresp_regN;   
 logic                          bvalid_regN;  

 logic                          rvalid_regN;
logic                           rready_w, rready_regN;

logic [WDATA_WIDTH-1:0]         wdata_pipe;

logic [(WDATA_WIDTH/8)-1:0]     wstrb_regN, wstrb_pipe, wdata_fifo_wr_data_wstrb,
  wdata_fifo_wr_data_wstrb_reg, wdata_fifo_rd_data_wstrb, avmm_byteenable_reg;

  logic waddr_fifo_push_reg, waddr_fifo_push_rising, wdata_fifo_push_reg, wdata_fifo_push_rising,
      araddr_fifo_push_reg, araddr_fifo_push_rising, bresp_fifo_full, bresp_fifo_empty;
  logic [BRESP_FIFO_WIDTH-1:0] bresp_fifo_wr_data, bresp_fifo_rd_data;
  logic [AVMMRDATA_WIDTH-1:0] rdata_reg;
  logic bvalid_reg2, bresp_fifo_push, bresp_vld,
	      bresp_vld_reg, bresp_fifo_pop, write_pending_reg, rvalid_reg2, rdata_fifo_full, 
		  rdata_fifo_empty, rdata_fifo_pop, read_pending_reg,
	      rdata_fifo_push, rdata_vld, rdata_vld_reg;

genvar i;
generate
    // ---------------------------------
    // Write Address Channel
    // ---------------------------------
	if (AWREADYLATENCY == 0) begin: awreadylatency_0
	    always_comb begin
		awaddr_regN               = awaddr;
		awvalid_regN              = awvalid;

		awready = awready_w;
		
		awready_regN = awready_w;
	    end	
	end 
	
    else begin: awreadylatency_nonzero
	
	  // Pipeline stages for Valid path
	  if (AWVALID_PSTAGES == 0) begin: awvalid_pstages_0
       always_comb begin
     	 awvalid_regN              = awvalid;
         awaddr_regN               = awaddr;		 
       end	  
	  end 
	  else begin: awvalid_pstages_nonzero
	   osc_ovs_pipe #(.W (1+AWADDR_WIDTH), .N (AWVALID_PSTAGES)) awvalid_awaddr_pstages_dly (
		 .clk (axi_lite_clk),
		 .dIn ({awvalid,
		        awaddr}),
		 .dOut ({awvalid_regN,
		         awaddr_regN}) 
	   );
	  end 
	  
	  // Pipeline stages for Ready path
	  if (AWREADY_PSTAGES == 0) begin: awready_pstages_0
        always_comb begin
          awready_regN         = awready_w;
          awready              = awready_regN;			 
        end	  
	  end 
	  else begin: awready_pstages_nonzero
   	    osc_ovs_pipe #(.W (1), .N (AWREADY_PSTAGES)) awready_pstages_dly (
   		  .clk (axi_lite_clk),
   		  .dIn (awready_w),
   		  .dOut (awready_regN) 
   	    );
	    always_comb begin
     	  awready              = awready_regN;	
        end	  
	  end
	end // block: awreadylatency_nonzero
	
    // ---------------------------------
    // Write Data Channel
    // ---------------------------------
	if (WREADYLATENCY == 0) begin: wreadylatency_0
	    always_comb begin
		wvalid_regN              = wvalid;

		wready                   = wready_w;
		
		wready_regN = wready_w;
 
        wdata_regN = wdata;

        wstrb_regN = wstrb;
 
	    end

	   // for (i=0; i < WDATA_WIDTH/8; i++) begin : csr_wstrb
       //   assign wdata_regN[(7+(i*8)):(i*8)] = wstrb[i] ? wdata[(7+(i*8)):(i*8)] : '0 ; 
       // end		
	end 
    else begin: wreadylatency_nonzero		
	
	  // Pipeline stages for Valid path
	  if (WVALID_PSTAGES == 0) begin: wvalid_pstages_0
       always_comb begin
     	 wvalid_regN              = wvalid;	

        wdata_regN = wdata;

        wstrb_regN = wstrb;
       end
	   
	   // for (i=0; i < WDATA_WIDTH/8; i++) begin : csr_wstrb
       //   assign wdata_regN[(7+(i*8)):(i*8)] = wstrb[i] ? wdata[(7+(i*8)):(i*8)] : '0 ; 
       // end			   
	  end 
	  else begin: wvalid_pstages_nonzero
	 //for (i=0; i < WDATA_WIDTH/8; i++) begin : csr_wstrb
     //      assign wdata_pipe[(7+(i*8)):(i*8)] = wstrb[i] ? wdata[(7+(i*8)):(i*8)] : '0 ; 
     //    end

      always_comb begin
        wdata_pipe = wdata;
        wstrb_pipe = wstrb;
      end 
	  
	   osc_ovs_pipe #(.W (1+WDATA_WIDTH+(WDATA_WIDTH/8)), .N (WVALID_PSTAGES)) wvalid_wdata_pstages_dly (
		 .clk (axi_lite_clk),
		 .dIn ({wvalid,
		        wdata_pipe,
                wstrb_pipe}),
		 .dOut ({wvalid_regN,
	                 wdata_regN,
                      wstrb_regN}) 
	   );
	  end // block: wvalid_pstages_nonzero
	  
	  // Pipeline stages for Ready path
	  if (WREADY_PSTAGES == 0) begin: wready_pstages_0
        always_comb begin
          wready_regN         = wready_w;
          wready              = wready_regN;			 
        end	  
	  end 
	  else begin: wready_pstages_nonzero
   	    osc_ovs_pipe #(.W (1), .N (WREADY_PSTAGES)) wready_pstages_dly (
   		  .clk  (axi_lite_clk),
   		  .dIn  (wready_w),
   		  .dOut (wready_regN) 
   	    );
	    always_comb begin
     	  wready              = wready_regN;	
        end	  
	  end // block: wready_pstages_nonzero
	  
	end // block: wreadylatency_nonzero

    // ---------------------------------
    // Read Address Channel
    // ---------------------------------
	if (ARREADYLATENCY == 0) begin: arreadylatency_0
	    always_comb begin
		araddr_regN               = araddr;
		arvalid_regN              = arvalid;

		arready = arready_w;
		
		arready_regN = arready_w;
	    end	
	end // block: readylatency_0
    else begin: arreadylatency_nonzero		
	
	  // Pipeline stages for Valid path	 
	  if (ARVALID_PSTAGES == 0) begin: arvalid_pstages_0
       always_comb begin
     	 arvalid_regN              = arvalid;
         araddr_regN               = araddr;		 
       end	  
	  end 
	  else begin: arvalid_pstages_nonzero
	   osc_ovs_pipe #(.W (1+ARADDR_WIDTH), .N (ARVALID_PSTAGES)) arvalid_araddr_pstages_dly (
		 .clk (axi_lite_clk),
		 .dIn ({arvalid,
		        araddr}),
		 .dOut ({arvalid_regN,
		         araddr_regN}) 
	   );
	  end // block: arvalid_pstages_nonzero	

	  // Pipeline stages for Ready path
	  if (ARREADY_PSTAGES == 0) begin: arready_pstages_0
        always_comb begin
          arready_regN         = arready_w;
          arready              = arready_regN;			 
        end	  
	  end 
	  else begin: arready_pstages_nonzero
   	    osc_ovs_pipe #(.W (1), .N (ARREADY_PSTAGES)) arready_pstages_dly (
   		  .clk  (axi_lite_clk),
   		  .dIn  (arready_w),
   		  .dOut (arready_regN) 
   	    );
	    always_comb begin
     	  arready              = arready_regN;	
        end	  
	  end // block: arready_pstages_nonzero

	end // block: arreadylatency_nonzero
   endgenerate
	
   assign awready_w = (waddr_fifo_cnt  < WADDR_SKD_CNT) ? 'b1 : 'b0;
   assign wready_w  = (wdata_fifo_cnt  < WDATA_SKD_CNT) ? 'b1 : 'b0;
   assign arready_w = (araddr_fifo_cnt < ARADDR_SKD_CNT) ? 'b1 : 'b0;

   // Once waitrequest is deasserted, after a read or write request, the response is valid
   assign bresp = (SINGLE_PENDING_TRANSACTION == 1) ? bresp_reg : bresp_fifo_rd_data;
   assign bvalid = bresp_vld;
   assign rdata = (SINGLE_PENDING_TRANSACTION == 1) ? rdata_reg          : 
                   rdata_fifo_pop ? rdata_fifo_rd_data : rdata_popped ;
   assign rresp = rresp_reg;
   //assign rvalid = rdata_vld;
   assign rvalid = !axi_lite_rst_n ? '0 : rdata_vld;
   //assign rvalid = !avmm_rst_n ? '0 : rdata_vld;
	//-----------------------------------------------------------------------------------------
	// Write Address CDC FIFO push
	
    always_ff @ (posedge axi_lite_clk) begin
      if (!axi_lite_rst_n) begin
        waddr_fifo_push       <= 'b0;     
      end else begin
        if (awvalid_regN & awready_regN) begin 
          waddr_fifo_wr_data <= awaddr_regN;
    	   // if (!waddr_fifo_full) 
    	     waddr_fifo_push     <= 'b1;
    	   // else
    	     // waddr_fifo_push     <= 'b0;
    	end else
          //waddr_fifo_wr_data <= waddr_fifo_wr_data;
    	  waddr_fifo_push     <= 'b0;
      end
    end

    always_ff @ (posedge axi_lite_clk) begin
      if (!axi_lite_rst_n) begin
        waddr_fifo_push_reg       <= 'b0;     
      end else begin
        waddr_fifo_push_reg       <= waddr_fifo_push;
        waddr_fifo_wr_data_reg    <= (SINGLE_PENDING_TRANSACTION == 1) ? 1 : waddr_fifo_wr_data;
      end
    end

    assign waddr_fifo_push_rising = waddr_fifo_push_reg & !waddr_fifo_push;

  	dcfifo  waddr_cdc_fifo (
	  .aclr 		(!axi_lite_rst_n),
	  .wrclk 		(axi_lite_clk),
	  .wrreq 		(waddr_fifo_push_rising),
	  .data 		(waddr_fifo_wr_data_reg),
	  .rdclk 		(avmm_clk),
	  .rdreq 		(waddr_fifo_pop),
	  .q 			(waddr_fifo_rd_data),
	  .wrusedw	    (waddr_fifo_cnt),
	  .rdempty	    (waddr_fifo_empty),
	  .wrfull       (waddr_fifo_full),
	  .rdfull       (),
	  .wrempty      (),
	  .rdusedw      (),
	  .eccstatus    ()
	);
	defparam
      waddr_cdc_fifo.intended_device_family  = DEVICE_FAMILY,
      waddr_cdc_fifo.use_eab  = "ON",
      waddr_cdc_fifo.ram_block_type = RAM_BLOCK_TYPE,
      waddr_cdc_fifo.lpm_type  = "dcfifo",
      waddr_cdc_fifo.lpm_width  = WADDR_FIFO_WIDTH, // AWADDR_WIDTH,
      waddr_cdc_fifo.lpm_widthu  = $clog2(WADDR_FIFO_DEPTH),
      waddr_cdc_fifo.lpm_numwords  = WADDR_FIFO_DEPTH,
      waddr_cdc_fifo.lpm_showahead  = "ON",				
      waddr_cdc_fifo.enable_ecc  = "FALSE",
      waddr_cdc_fifo.overflow_checking  = "OFF",
      waddr_cdc_fifo.underflow_checking  = "OFF",
      waddr_cdc_fifo.clocks_are_synchronized = "FALSE", 
      waddr_cdc_fifo.rdsync_delaypipe  = 5,
      waddr_cdc_fifo.wrsync_delaypipe  = 5,
      waddr_cdc_fifo.write_aclr_synch = "ON",
      waddr_cdc_fifo.read_aclr_synch = "ON",
      waddr_cdc_fifo.add_ram_output_register = "ON";

	//-----------------------------------------------------------------------------------------
	// Write Data CDC FIFO
	
    always_ff @ (posedge axi_lite_clk) begin
      if (!axi_lite_rst_n) begin
        wdata_fifo_push      <= 'b0;
      end else begin
        if (wvalid_regN & wready_regN) begin
          wdata_fifo_wr_data <= wdata_regN;
          wdata_fifo_wr_data_wstrb <= wstrb_regN;
    	    // if (!wdata_fifo_full)
    	      wdata_fifo_push  <= 'b1;
    	    // else
    	      // wdata_fifo_push  <= 'b0;
    	  end else
    	    wdata_fifo_push    <= 'b0;
      end
    end

  always_ff @ (posedge axi_lite_clk) begin
    if (!axi_lite_rst_n) begin
      wdata_fifo_push_reg       <= 'b0;     
    end else begin
      wdata_fifo_push_reg       <= wdata_fifo_push;
      wdata_fifo_wr_data_reg    <= (SINGLE_PENDING_TRANSACTION == 1) ? 1 : wdata_fifo_wr_data;
      wdata_fifo_wr_data_wstrb_reg <= (SINGLE_PENDING_TRANSACTION == 1) ? 1 : wdata_fifo_wr_data_wstrb;
    end
  end

  assign wdata_fifo_push_rising = wdata_fifo_push_reg & !wdata_fifo_push;

  	dcfifo  wdata_cdc_fifo (
	  .aclr 		(!axi_lite_rst_n),
	  .wrclk 		(axi_lite_clk),
	  .wrreq 		(wdata_fifo_push_rising),
	  .data 		({wdata_fifo_wr_data_reg,
                      wdata_fifo_wr_data_wstrb_reg}),
	  .rdclk 		(avmm_clk),
	  .rdreq 		(wdata_fifo_pop),
	  .q 			({wdata_fifo_rd_data,
                      wdata_fifo_rd_data_wstrb}),
	  .wrusedw	    (wdata_fifo_cnt),
	  .rdempty	    (wdata_fifo_empty),
	  .wrfull       (wdata_fifo_full),
	  .rdfull       (),
	  .wrempty      (),
	  .rdusedw      (),
	  .eccstatus    ()
	);
	defparam
      wdata_cdc_fifo.intended_device_family  = DEVICE_FAMILY,
      wdata_cdc_fifo.use_eab  = "ON",
      wdata_cdc_fifo.ram_block_type = RAM_BLOCK_TYPE,
      wdata_cdc_fifo.lpm_type  = "dcfifo",
      wdata_cdc_fifo.lpm_width  = WDATA_FIFO_WIDTH, //WDATA_WIDTH+(WDATA_WIDTH/8)
      wdata_cdc_fifo.lpm_widthu  = $clog2(WDATA_FIFO_DEPTH),
      wdata_cdc_fifo.lpm_numwords  = WDATA_FIFO_DEPTH,
      wdata_cdc_fifo.lpm_showahead  = "ON",				
      wdata_cdc_fifo.enable_ecc  = "FALSE",
      wdata_cdc_fifo.overflow_checking  = "OFF",
      wdata_cdc_fifo.underflow_checking  = "OFF",
      wdata_cdc_fifo.clocks_are_synchronized = "FALSE", 
      wdata_cdc_fifo.rdsync_delaypipe  = 5,
      wdata_cdc_fifo.wrsync_delaypipe  = 5,
      wdata_cdc_fifo.write_aclr_synch = "ON",
      wdata_cdc_fifo.read_aclr_synch = "ON",
      wdata_cdc_fifo.add_ram_output_register = "ON";

	//-----------------------------------------------------------------------------------------
	// Read Address CDC FIFO 		  
    
	always_ff @ (posedge axi_lite_clk) begin
      if (!axi_lite_rst_n) begin
        araddr_fifo_push      <= 'b0;
      end else begin
        if (arvalid_regN & arready_regN) begin
          araddr_fifo_wr_data <= araddr_regN;
    	  // if (!araddr_fifo_full)
    	    araddr_fifo_push    <= 1'b1; 
    	  // else
    	    // araddr_fifo_push    <= 'b0;
    	end else
    	  //wdata_fifo_wr_data <= wdata_fifo_wr_data;
    	  araddr_fifo_push    <= 'b0;
      end
    end

   always_ff @ (posedge axi_lite_clk) begin
     if (!axi_lite_rst_n) begin
       araddr_fifo_push_reg       <= 'b0;     
     end else begin
       araddr_fifo_push_reg       <= araddr_fifo_push;
       araddr_fifo_wr_data_reg    <= (SINGLE_PENDING_TRANSACTION == 1) ? 1 : araddr_fifo_wr_data;
     end
   end

   assign araddr_fifo_push_rising = araddr_fifo_push_reg & !araddr_fifo_push;

  	dcfifo  araddr_cdc_fifo (
	  .aclr 		(!axi_lite_rst_n),
	  .wrclk 		(axi_lite_clk),
	  .wrreq 		(araddr_fifo_push_rising),
	  .data 		(araddr_fifo_wr_data_reg),
	  .rdclk 		(avmm_clk),
	  .rdreq 		(araddr_fifo_pop),
	  .q 			(araddr_fifo_rd_data),
	  .wrusedw	    (araddr_fifo_cnt),
	  .rdempty	    (araddr_fifo_empty),
	  .wrfull       (araddr_fifo_full),
	  .rdfull       (),
	  .wrempty      (),
	  .rdusedw      (),
	  .eccstatus    ()
	);
	defparam
      araddr_cdc_fifo.intended_device_family  = DEVICE_FAMILY,
      araddr_cdc_fifo.use_eab  = "ON",
      araddr_cdc_fifo.ram_block_type = RAM_BLOCK_TYPE,
      araddr_cdc_fifo.lpm_type  = "dcfifo",
      araddr_cdc_fifo.lpm_width  = RADDR_FIFO_WIDTH, // ARADDR_WIDTH,
      araddr_cdc_fifo.lpm_widthu  = $clog2(ARADDR_FIFO_DEPTH),
      araddr_cdc_fifo.lpm_numwords  = ARADDR_FIFO_DEPTH,
      araddr_cdc_fifo.lpm_showahead  = "ON",				
      araddr_cdc_fifo.enable_ecc  = "FALSE",
      araddr_cdc_fifo.overflow_checking  = "OFF",
      araddr_cdc_fifo.underflow_checking  = "OFF",
      araddr_cdc_fifo.clocks_are_synchronized = "FALSE", 
      araddr_cdc_fifo.rdsync_delaypipe  = 5,
      araddr_cdc_fifo.wrsync_delaypipe  = 5,
      araddr_cdc_fifo.write_aclr_synch = "ON",
      araddr_cdc_fifo.read_aclr_synch = "ON",
      araddr_cdc_fifo.add_ram_output_register = "ON";
	  
	//-----------------------------------------------------------------------------------------
	// Read Data CDC FIFO
	
    always_ff @ (posedge avmm_clk) begin
      rvalid_reg2 <= rvalid_reg;
	  read_pending_reg <= read_pending;
    end 
	
	always_ff @ (posedge axi_lite_clk) begin
	  rdata_vld_reg <= rdata_vld;
	end

	always_ff @ (posedge axi_lite_clk) begin
	  if (!axi_lite_rst_n) begin
	    rdata_vld <= '0;
	  end else begin
	    if (!rdata_fifo_empty & !rdata_vld) begin
	      rdata_vld <= '1;
		end else if (rready & rdata_vld) begin
		  rdata_vld <= '0;
		end
	  end
    end
	
    assign rdata_fifo_push = rvalid_reg2 & !rvalid_reg; // negedge detect
	assign rdata_fifo_pop = !rdata_vld_reg & rdata_vld; // posedge detect	

    always_ff @ (posedge axi_lite_clk) begin
      if (rdata_fifo_pop)
        rdata_popped <= rdata_fifo_rd_data;

      if (!axi_lite_rst_n)
        rdata_popped <= '0;
    end

    dcfifo  rdata_cdc_fifo (
	  //.aclr 		(!avmm_rst_n),
          .aclr 		(!axi_lite_rst_n),  
 	  .wrclk 		(avmm_clk),
	  .wrreq 		(read_pending_reg & rdata_fifo_push),
	  //.data 		(rdata_reg),
	  .data 		(rdata_fifo_wr_data_reg),
	  .rdclk 		(axi_lite_clk),
	  .rdreq 		(rdata_fifo_pop),
	  .q 			(rdata_fifo_rd_data),
	  .wrusedw	    (),
	  .rdempty	    (rdata_fifo_empty),
	  .wrfull       (rdata_fifo_full),
	  .rdfull       (),
	  .wrempty      (),
	  .rdusedw      (),
	  .eccstatus    ()
	);
	defparam
      rdata_cdc_fifo.intended_device_family  = DEVICE_FAMILY,
      rdata_cdc_fifo.use_eab  = "ON",
      rdata_cdc_fifo.ram_block_type = RAM_BLOCK_TYPE,
      rdata_cdc_fifo.lpm_type  = "dcfifo",
      rdata_cdc_fifo.lpm_width  = RDATA_FIFO_WIDTH, //RDATA_WIDTH,
      rdata_cdc_fifo.lpm_widthu  = $clog2(RDATA_FIFO_DEPTH),
      rdata_cdc_fifo.lpm_numwords  = RDATA_FIFO_DEPTH,
      rdata_cdc_fifo.lpm_showahead  = "ON",				
      rdata_cdc_fifo.enable_ecc  = "FALSE",
      rdata_cdc_fifo.overflow_checking  = "OFF",
      rdata_cdc_fifo.underflow_checking  = "OFF",
      rdata_cdc_fifo.clocks_are_synchronized = "FALSE", 
      rdata_cdc_fifo.rdsync_delaypipe  = 5,
      rdata_cdc_fifo.wrsync_delaypipe  = 5,
      rdata_cdc_fifo.write_aclr_synch = "ON",
      rdata_cdc_fifo.read_aclr_synch = "ON",
      rdata_cdc_fifo.add_ram_output_register = "ON";

	//-----------------------------------------------------------------------------------------
	// Write Response CDC FIFO 	
	
    always_ff @ (posedge avmm_clk) begin
      bvalid_reg2 <= bvalid_reg;
	  write_pending_reg <= write_pending;
    end 
	
	always_ff @ (posedge axi_lite_clk) begin
	  bresp_vld_reg <= bresp_vld;
	end

	always_ff @ (posedge axi_lite_clk) begin
	  if (!axi_lite_rst_n) begin
	    bresp_vld <= '0;
	  end else begin
	    if (!bresp_fifo_empty & !bresp_vld) begin
	      bresp_vld <= '1;
		end else if (bready & bresp_vld) begin
		  bresp_vld <= '0;
		end
	  end
    end
	
	assign bresp_fifo_push = bvalid_reg2 & !bvalid_reg; // negedge detect
	assign bresp_fifo_pop = !bresp_vld_reg & bresp_vld; // posedge detect
	
	dcfifo  bresp_cdc_fifo (
	  .aclr 		(!avmm_rst_n),
	  .wrclk 		(avmm_clk),
	  .wrreq 		(write_pending_reg & bresp_fifo_push), 
	  //.data 		(bresp_reg),
	  .data 		(bresp_fifo_wr_data),
	  .rdclk 		(axi_lite_clk),
	  .rdreq 		(bresp_fifo_pop),
	  .q 			(bresp_fifo_rd_data),
	  .wrusedw	    (),
	  .rdempty	    (bresp_fifo_empty),
	  .wrfull       (bresp_fifo_full),
	  .rdfull       (),
	  .wrempty      (),
	  .rdusedw      (),
	  .eccstatus    ()
	);
	defparam
      bresp_cdc_fifo.intended_device_family  = DEVICE_FAMILY,
      bresp_cdc_fifo.use_eab  = "ON",
      bresp_cdc_fifo.ram_block_type = RAM_BLOCK_TYPE,
      bresp_cdc_fifo.lpm_type  = "dcfifo",
      bresp_cdc_fifo.lpm_width  = BRESP_FIFO_WIDTH, //BRESP_WIDTH,
      bresp_cdc_fifo.lpm_widthu  = $clog2(BRESP_FIFO_DEPTH),
      bresp_cdc_fifo.lpm_numwords  = BRESP_FIFO_DEPTH,
      bresp_cdc_fifo.lpm_showahead  = "ON",				
      bresp_cdc_fifo.enable_ecc  = "FALSE",
      bresp_cdc_fifo.overflow_checking  = "OFF",
      bresp_cdc_fifo.underflow_checking  = "OFF",
      bresp_cdc_fifo.clocks_are_synchronized = "FALSE", 
      bresp_cdc_fifo.rdsync_delaypipe  = 5,
      bresp_cdc_fifo.wrsync_delaypipe  = 5,
      bresp_cdc_fifo.write_aclr_synch = "ON",
      bresp_cdc_fifo.read_aclr_synch = "ON",
      bresp_cdc_fifo.add_ram_output_register = "ON";
		  
  assign avmm_address = avmm_address_reg;
  assign avmm_write = avmm_write_reg;
  assign avmm_writedata = avmm_writedata_reg;
  assign avmm_read = avmm_read_reg;
  assign avmm_byteenable = avmm_byteenable_reg;


  assign rdata_fifo_wr_data_reg = (SINGLE_PENDING_TRANSACTION == 1) ? 1 : rdata_reg;
  assign bresp_fifo_wr_data     = (SINGLE_PENDING_TRANSACTION == 1) ? 1 : bresp_reg;



	//-----------------------------------------------------------------------------------------
	// CDC FIFO pop control		

    // Write operation has higher priority over Read operation
    always_ff @ (posedge avmm_clk) begin
    if (!avmm_rst_n) begin
          waddr_fifo_pop <= 'b0;
          wdata_fifo_pop <= 'b0;
          araddr_fifo_pop <= 'b0;
          avmm_write_reg <= 'b0;
          write_pending  <= 'b0;
          bvalid_reg     <= 'b0;
          bresp_reg      <= 2'b00;
          avmm_read_reg  <= 'b0;
          rvalid_reg     <= 'b0;
          read_pending   <= 'b0;
          rresp_reg      <= 2'b00;
    end else begin
      if (!waddr_fifo_empty & !wdata_fifo_empty & !write_pending & !read_pending) begin 
           avmm_address_reg   <= (SINGLE_PENDING_TRANSACTION == 1) ? waddr_fifo_wr_data : waddr_fifo_rd_data;
           avmm_writedata_reg <= (SINGLE_PENDING_TRANSACTION == 1) ? wdata_fifo_wr_data : wdata_fifo_rd_data;
           avmm_byteenable_reg <= (SINGLE_PENDING_TRANSACTION == 1) ? wdata_fifo_wr_data_wstrb : wdata_fifo_rd_data_wstrb;
           avmm_write_reg     <= 'b1;
           write_pending      <= 'b1;
           waddr_fifo_pop     <= 'b1;
           wdata_fifo_pop     <= 'b1;
      end else if (write_pending) begin
           waddr_fifo_pop <= 'b0;
           wdata_fifo_pop <= 'b0;
        if (!avmm_waitrequest) begin
          avmm_write_reg <= 'b0;
          bresp_reg      <= avmm_address_out_of_range ? 2'b11 : 2'b00;
          bvalid_reg     <= 'b1;
        end else if (!bresp_fifo_full & bvalid_reg) begin // wait until fifo is ready to be written
          bvalid_reg    <= 'b0;
          write_pending <= 'b0;
          //Complete Write sequence
        end   
      end else if (!araddr_fifo_empty & !read_pending & !write_pending) begin
          avmm_address_reg <= (SINGLE_PENDING_TRANSACTION == 1) ? araddr_fifo_wr_data : araddr_fifo_rd_data;
          avmm_read_reg    <= 'b1;
          read_pending     <= 'b1;
          araddr_fifo_pop <= 'b1;
      end else if (read_pending) begin
          araddr_fifo_pop <= 'b0;
        if (!avmm_waitrequest) begin
          avmm_read_reg <= 'b0;
          rdata_reg     <= avmm_readdata;
          rresp_reg     <= avmm_address_out_of_range ? 2'b11 : 2'b00;
          rvalid_reg    <= 'b1;
        end else if (!rdata_fifo_full & rvalid_reg) begin // wait until fifo is ready to be written
          rvalid_reg   <= 'b0;
          read_pending <= 'b0;
          //Complete Read sequence
        end
      end 
    end
    end

endmodule
