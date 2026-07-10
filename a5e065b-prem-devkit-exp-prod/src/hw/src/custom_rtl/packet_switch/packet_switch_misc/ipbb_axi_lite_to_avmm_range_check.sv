//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

//--------------------------------------------------------------------------------------------
// Description: ipbb_axi_lite_to_avmm_range_check
// 
// - This module converts AXI4-Lite to AVMM Bridge with avmm_address_out_of_range input 
//   which indicates an out-of-range address access.
// - Supports 32b and 64b address widths.
// - Supports AWREADYLATENCY, WREADYLATENCY, ARREADYLATENCY.
// - Only supports single pending transactions.
//
//--------------------------------------------------------------------------------------------

module ipbb_axi_lite_to_avmm_range_check #(
	parameter DEVICE_FAMILY  = "Agilex",
	parameter AWADDR_WIDTH   = 32,
    parameter WDATA_WIDTH    = 512,
    parameter ARADDR_WIDTH   = 32,
    parameter RDATA_WIDTH    = 512,
    parameter AWVALID_PSTAGES = 0, // Defines the number of pipe stages required on the VALID path to the IP.
    parameter WVALID_PSTAGES  = 0, // Same as AWVALID_PSTAGES but for Write Data channel.
    parameter BVALID_PSTAGES  = 0, // Only applicable to Responder Side.
    parameter ARVALID_PSTAGES = 0, // Same as AWVALID_PSTAGES but for Read Address channel.
    parameter RVALID_PSTAGES  = 0, // Only applicable to Responder Side
    parameter AWREADY_PSTAGES = 0, // Defines the number of pipe stages required on the READY path to the IP.
    parameter WREADY_PSTAGES  = 0, // Same as AWREADY_PSTAGES but for Write Data channel.
    parameter BREADY_PSTAGES  = 0, // Only applicable to Responder Side
    parameter ARREADY_PSTAGES = 0, // Same as AWREADY_PSTAGES but for Read Address channel.
    parameter RREADY_PSTAGES  = 0, // Only applicable to Responder Side.
    parameter AWREADYLATENCY  = AWVALID_PSTAGES + AWREADY_PSTAGES, 
    parameter WREADYLATENCY   = WVALID_PSTAGES + WREADY_PSTAGES, 
    parameter BREADYLATENCY   = BVALID_PSTAGES + BREADY_PSTAGES, // Only applicable to Responder Side.
    parameter ARREADYLATENCY  = ARVALID_PSTAGES + ARREADY_PSTAGES,
    parameter RREADYLATENCY   = RVALID_PSTAGES + RREADY_PSTAGES, // Only applicable to Responder Side.
    parameter AVMMADDR_WIDTH  = 32,
    parameter AVMMWDATA_WIDTH = 32,
    parameter AVMMRDATA_WIDTH = 32,
    parameter SINGLE_PENDING_TRANSACTION = 1
	
)   (
	input logic                           clk,                           
	input logic                           rst_n,                         
	
	input logic [AWADDR_WIDTH-1:0]        awaddr,                        
    input logic                           awvalid,                       
    output logic                          awready,                       
	
    input logic [WDATA_WIDTH-1:0]         wdata,                         
    input logic                           wvalid,
    input logic [(WDATA_WIDTH/8)-1:0]     wstrb,	
    output logic                          wready,                        
	
    output logic [1:0]                    bresp,                         
    output logic                          bvalid,                        
    input logic                           bready, //ready for response   
	
    input logic [ARADDR_WIDTH-1:0]        araddr,
    input logic                           arvalid,
    output logic                          arready, 
	
    output logic [1:0]                    rresp,
    output logic [RDATA_WIDTH-1:0]        rdata,
    output logic                          rvalid,
    input logic                           rready, //ready for data

    // AVMM
    output logic [AVMMADDR_WIDTH-1:0]      avmm_address,
    output logic                           avmm_read,
    input  logic [AVMMRDATA_WIDTH-1:0]     avmm_readdata,
    output logic                           avmm_write,
    output logic [AVMMWDATA_WIDTH-1:0]     avmm_writedata,
    output logic [(AVMMWDATA_WIDTH/8)-1:0] avmm_byteenable,
    input  logic                           avmm_waitrequest,
	
	input  logic                          avmm_address_out_of_range // triggers DECERR for BRESP/RRESP
);
localparam WADDR_SKD_CNT = AWREADYLATENCY + 'h3;
localparam WDATA_SKD_CNT = WREADYLATENCY  + 'h3;
localparam ARADDR_SKD_CNT = ARREADYLATENCY + 'h3;

localparam WADDR_FIFO_DEPTH = AWREADYLATENCY +'h4;
localparam WDATA_FIFO_DEPTH = WREADYLATENCY  +'h4;
localparam ARADDR_FIFO_DEPTH = ARREADYLATENCY + 'h4;

logic write_pending, read_pending;
logic [$clog2(WADDR_FIFO_DEPTH)-1:0] waddr_fifo_cnt;
logic [$clog2(WDATA_FIFO_DEPTH)-1:0] wdata_fifo_cnt;
logic [$clog2(ARADDR_FIFO_DEPTH)-1:0] araddr_fifo_cnt;

logic waddr_fifo_push, waddr_fifo_pop, waddr_fifo_full, waddr_fifo_empty;
logic wdata_fifo_push, wdata_fifo_full, wdata_fifo_pop, wdata_fifo_empty ;
logic araddr_fifo_push, araddr_fifo_full, araddr_fifo_pop, araddr_fifo_empty;

logic [AWADDR_WIDTH-1:0] waddr_fifo_wr_data, waddr_fifo_wr_data_reg, waddr_fifo_rd_data;
logic [WDATA_WIDTH-1:0] wdata_fifo_wr_data, wdata_fifo_wr_data_reg, wdata_fifo_rd_data;
logic [ARADDR_WIDTH-1:0] araddr_fifo_wr_data, araddr_fifo_wr_data_reg, araddr_fifo_rd_data;

logic [RDATA_WIDTH-1:0] rdata_reg, rdata_hold;
logic [1:0] bresp_reg, rresp_reg;
logic bvalid_reg, rvalid_reg, rvalid_hold;

logic [AVMMADDR_WIDTH-1:0] avmm_address_reg;
logic [AVMMWDATA_WIDTH-1:0] avmm_writedata_reg;
logic [(AVMMWDATA_WIDTH/8)-1:0] avmm_byteenable_reg;
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

 logic [1:0]                    bresp_regN, bresp_hold;   
 logic                          bvalid_regN, bvalid_hold;  
logic                           bready_w, bready_regN;


 logic [1:0]                    rresp_regN, rresp_hold;
 logic [RDATA_WIDTH-1:0]        rdata_regN;
 logic                          rvalid_regN;
logic                           rready_w, rready_regN;

logic [WDATA_WIDTH-1:0]         wdata_pipe;
logic [(WDATA_WIDTH/8)-1:0]     wstrb_reg, wstrb_reg_c1, wstrb_fifo_rd_data;

logic waddr_fifo_push_reg, waddr_fifo_push_rising, wdata_fifo_push_reg, wdata_fifo_push_rising,
      araddr_fifo_push_reg, araddr_fifo_push_rising;

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
		 .clk (clk),
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
   		  .clk (clk),
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
	    end

	    // for (i=0; i < WDATA_WIDTH/8; i++) begin : csr_wstrb
          // assign wdata_regN[(7+(i*8)):(i*8)] = wstrb[i] ? wdata[(7+(i*8)):(i*8)] : '0 ; 
        // end		
        assign wdata_regN = wdata; 
	end 
    else begin: wreadylatency_nonzero		
	
	  // Pipeline stages for Valid path
	  if (WVALID_PSTAGES == 0) begin: wvalid_pstages_0
       always_comb begin
     	 wvalid_regN              = wvalid;	
       end
	   
	   // for (i=0; i < WDATA_WIDTH/8; i++) begin : csr_wstrb
         // assign wdata_regN[(7+(i*8)):(i*8)] = wstrb[i] ? wdata[(7+(i*8)):(i*8)] : '0 ; 
       // end			   
 
       assign wdata_regN = wdata; 

	  end 
	  else begin: wvalid_pstages_nonzero
	 for (i=0; i < WDATA_WIDTH/8; i++) begin : csr_wstrb
           assign wdata_pipe[(7+(i*8)):(i*8)] = wstrb[i] ? wdata[(7+(i*8)):(i*8)] : '0 ; 
         end
	  
	   osc_ovs_pipe #(.W (1+WDATA_WIDTH), .N (WVALID_PSTAGES)) wvalid_wdata_pstages_dly (
		 .clk (clk),
		 .dIn ({wvalid,
		        wdata_pipe}),
		 .dOut ({wvalid_regN,
	             wdata_regN}) 
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
   		  .clk  (clk),
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
		 .clk (clk),
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
   		  .clk  (clk),
   		  .dIn  (arready_w),
   		  .dOut (arready_regN) 
   	    );
	    always_comb begin
     	  arready              = arready_regN;	
        end	  
	  end // block: arready_pstages_nonzero

	end // block: arreadylatency_nonzero
   endgenerate

logic rready_pending, bready_pending;

generate
if (SINGLE_PENDING_TRANSACTION) begin: single_trans
assign awready_w = 'b1;
assign wready_w  = 'b1;
assign arready_w = 'b1;

assign bresp = bready & !bready_pending ? bresp_reg : bresp_hold;
assign bvalid = bready & !bready_pending ? bvalid_reg : bvalid_hold;
assign rdata = rready & !rready_pending ? rdata_reg : rdata_hold;
assign rresp = rready & !rready_pending ? rresp_reg : rresp_hold;
assign rvalid = rready & !rready_pending ? rvalid_reg : rvalid_hold;

always_ff @ (posedge clk) begin
  if (!rready & read_pending & !avmm_waitrequest & !rready_pending) begin
    rvalid_hold <= '1;
    rdata_hold <= avmm_readdata;
    rresp_hold <= avmm_address_out_of_range ? 2'b11 : 2'b00;
    rready_pending <= '1;
  end else if (rready & rready_pending) begin
    rvalid_hold <= '0;
    rready_pending <= '0;
  end

  if (!bready & write_pending & !avmm_waitrequest & !bready_pending) begin
    bvalid_hold <= '1;
    bresp_hold <= avmm_address_out_of_range ? 2'b11 : 2'b00;
    bready_pending <= '1;
  end else if (bready & bready_pending) begin
    bvalid_hold <= '0;
    bready_pending <= '0;
  end

  if (~rst_n) begin
    rvalid_hold <= '0;
    rdata_hold <= '0;
    rresp_hold <= '0;
    bresp_hold <= '0;
    bvalid_hold <= '0;

    rready_pending <= '0;
    bready_pending <= '0;
  end

end

// MUX between Write and Read
// Write operation has higher priority over Read operation
always_ff @ (posedge clk) begin
    if (~rst_n) begin
              avmm_write_reg     <= 'b0;
              bvalid_reg         <= 'b0;
              bresp_reg          <= 2'b00;
              avmm_read_reg      <= 'b0;
              rvalid_reg         <= 'b0;
              rresp_reg          <= 2'b00;
			  write_pending      <= 1'b0;
              read_pending       <= 1'b0;
    end else begin
	          avmm_write_reg     <= awvalid_regN;
	          avmm_address_reg   <= awvalid_regN ? awaddr_regN : araddr_regN;
              avmm_read_reg      <= arvalid_regN & ~write_pending;
              avmm_writedata_reg <= wdata_regN;
              avmm_byteenable_reg<= wstrb;

			  bresp_reg          <= avmm_address_out_of_range         ? 2'b11 : 2'b00;
              bvalid_reg         <= ~avmm_waitrequest & write_pending ? 'b1 : 'b0;
              rresp_reg          <= avmm_address_out_of_range         ? 2'b11 : 2'b00;
              rvalid_reg         <= ~avmm_waitrequest & read_pending  ? 'b1 : 'b0;
			  rdata_reg          <= avmm_readdata;

			  if (~write_pending & awvalid_regN) begin
				write_pending    <= 1'b1;
			  end else if (write_pending & ~avmm_waitrequest) begin
				write_pending    <= 1'b0;
			  end                  

			  if (~read_pending & arvalid_regN) begin
				read_pending    <= 1'b1;
			  end else if (read_pending & ~avmm_waitrequest) begin
				read_pending    <= 1'b0;
			  end
    end
end


assign avmm_address    = avmm_address_reg;
assign avmm_write      = avmm_write_reg;
assign avmm_writedata  = avmm_writedata_reg;
assign avmm_read       = avmm_read_reg;
assign avmm_byteenable = avmm_byteenable_reg;


end else begin: not_single_trans

	
assign awready_w = (waddr_fifo_cnt  < WADDR_SKD_CNT) ? 'b1 : 'b0;
assign wready_w  = (wdata_fifo_cnt  < WDATA_SKD_CNT) ? 'b1 : 'b0;
assign arready_w = (araddr_fifo_cnt < ARADDR_SKD_CNT) ? 'b1 : 'b0;

assign bresp = bresp_reg;
assign bvalid = bvalid_reg;
assign rdata = rdata_reg;
assign rresp = rresp_reg;
assign rvalid = rvalid_reg;
// Once waitrequest is deasserted, after a read or write request, the response is valid

// Write ADDR
always_ff @ (posedge clk) begin
  if (~rst_n) begin
    waddr_fifo_push       <= 'b0;     
  end else begin
    if (awvalid_regN & awready_regN) begin 
      waddr_fifo_wr_data <= awaddr_regN;
	   if (~waddr_fifo_full) 
	     waddr_fifo_push     <= 'b1;
	   else
	     waddr_fifo_push     <= 'b0;
	end else
      //waddr_fifo_wr_data <= waddr_fifo_wr_data;
	  waddr_fifo_push     <= 'b0;
  end
end

always_ff @ (posedge clk) begin
  if (~rst_n) begin
    waddr_fifo_push_reg       <= 'b0;     
  end else begin
    waddr_fifo_push_reg       <= waddr_fifo_push;
    waddr_fifo_wr_data_reg    <= waddr_fifo_wr_data;
  end
end

assign waddr_fifo_push_rising = waddr_fifo_push_reg & ~waddr_fifo_push;

	scfifo  waddr_fifo (
          .clock                    (clk),
          .data                     (waddr_fifo_wr_data_reg),
          .rdreq                    (waddr_fifo_pop),
          .wrreq                    (waddr_fifo_push_rising),
          .almost_full              (),
          .full                     (waddr_fifo_full),    
          .q                        (waddr_fifo_rd_data),
          .aclr                     (1'b0),
          .almost_empty             (),
          .eccstatus                (), 
          .empty                    (waddr_fifo_empty),     
          .sclr                     (~rst_n),
          .usedw                    (waddr_fifo_cnt) );     
      defparam
          waddr_fifo.add_ram_output_register  = "ON",
          //waddr_fifo.almost_full_value  = 96,
          waddr_fifo.enable_ecc  = "FALSE",
          waddr_fifo.intended_device_family  = DEVICE_FAMILY,
          waddr_fifo.ram_block_type  = "AUTO",
          waddr_fifo.lpm_numwords  = WADDR_FIFO_DEPTH,
          waddr_fifo.lpm_showahead  = "ON",
          waddr_fifo.lpm_type  = "scfifo",
          waddr_fifo.lpm_width  = AWADDR_WIDTH,
          waddr_fifo.lpm_widthu  = $clog2(WADDR_FIFO_DEPTH),
          waddr_fifo.overflow_checking  = "OFF",
          waddr_fifo.underflow_checking  = "OFF", 
          waddr_fifo.use_eab  = "ON";  
	
// Write Data
always_ff @ (posedge clk) begin
  if (~rst_n) begin
    wdata_fifo_push      <= 'b0;
  end else begin
    if (wvalid_regN & wready_regN) begin
      wdata_fifo_wr_data <= wdata_regN;
      wstrb_reg          <= wstrb;
	  if (~wdata_fifo_full)
	    wdata_fifo_push  <= 'b1;
	  else
	    wdata_fifo_push  <= 'b0;
	end else
	  //wdata_fifo_wr_data <= wdata_fifo_wr_data;
	  wdata_fifo_push    <= 'b0;
  end
end

always_ff @ (posedge clk) begin
  if (~rst_n) begin
    wdata_fifo_push_reg       <= 'b0;     
  end else begin
    wdata_fifo_push_reg       <= wdata_fifo_push;
    wdata_fifo_wr_data_reg    <= wdata_fifo_wr_data;
    wstrb_reg_c1              <= wstrb_reg;
  end
end

assign wdata_fifo_push_rising = wdata_fifo_push_reg & ~wdata_fifo_push;

		scfifo  wdata_fifo (
          .clock                    (clk),
          .data                     ({wdata_fifo_wr_data_reg,wstrb_reg_c1}),
          .rdreq                    (wdata_fifo_pop),
          .wrreq                    (wdata_fifo_push_rising),
          .almost_full              (),
          .full                     (wdata_fifo_full),    
          .q                        ({wdata_fifo_rd_data,wstrb_fifo_rd_data}),
          .aclr                     (1'b0),
          .almost_empty             (),
          .eccstatus                (), 
          .empty                    (wdata_fifo_empty),     
          .sclr                     (~rst_n),
          .usedw                    (wdata_fifo_cnt) );     
      defparam
          wdata_fifo.add_ram_output_register  = "ON",
          //wdata_fifo.almost_full_value  = 96,
          wdata_fifo.enable_ecc  = "FALSE",
          wdata_fifo.intended_device_family  = DEVICE_FAMILY,
          wdata_fifo.ram_block_type  = "AUTO",
          wdata_fifo.lpm_numwords  = WDATA_FIFO_DEPTH,
          wdata_fifo.lpm_showahead  = "ON",
          wdata_fifo.lpm_type  = "scfifo",
          wdata_fifo.lpm_width  = WDATA_WIDTH+(WDATA_WIDTH/8),
          wdata_fifo.lpm_widthu  = $clog2(WDATA_FIFO_DEPTH),
          wdata_fifo.overflow_checking  = "OFF",
          wdata_fifo.underflow_checking  = "OFF", 
          wdata_fifo.use_eab  = "ON";  
		  
// Read 
always_ff @ (posedge clk) begin
  if (~rst_n) begin
    araddr_fifo_push      <= 'b0;
  end else begin
    if (arvalid_regN & arready_regN) begin
      araddr_fifo_wr_data <= araddr_regN;
	  if (~araddr_fifo_full)
	    araddr_fifo_push    <= 1'b1; 
	  else
	    araddr_fifo_push    <= 'b0;
	end else
	  //wdata_fifo_wr_data <= wdata_fifo_wr_data;
	  araddr_fifo_push    <= 'b0;
  end
end

always_ff @ (posedge clk) begin
  if (~rst_n) begin
    araddr_fifo_push_reg       <= 'b0;     
  end else begin
    araddr_fifo_push_reg       <= araddr_fifo_push;
    araddr_fifo_wr_data_reg    <= araddr_fifo_wr_data;
  end
end

assign araddr_fifo_push_rising = araddr_fifo_push_reg & ~araddr_fifo_push;

		scfifo  araddr_fifo (
          .clock                    (clk),
          .data                     (araddr_fifo_wr_data_reg),
          .rdreq                    (araddr_fifo_pop),
          .wrreq                    (araddr_fifo_push_rising),
          .almost_full              (),
          .full                     (araddr_fifo_full),    
          .q                        (araddr_fifo_rd_data),
          .aclr                     (1'b0),
          .almost_empty             (),
          .eccstatus                (), 
          .empty                    (araddr_fifo_empty),     
          .sclr                     (~rst_n),
          .usedw                    (araddr_fifo_cnt) );     
      defparam
          araddr_fifo.add_ram_output_register  = "ON",
          //araddr_fifo.almost_full_value  = 96,
          araddr_fifo.enable_ecc  = "FALSE",
          araddr_fifo.intended_device_family  = DEVICE_FAMILY,
          araddr_fifo.ram_block_type  = "AUTO",
          araddr_fifo.lpm_numwords  = ARADDR_FIFO_DEPTH,
          araddr_fifo.lpm_showahead  = "ON",
          araddr_fifo.lpm_type  = "scfifo",
          araddr_fifo.lpm_width  = ARADDR_WIDTH,
          araddr_fifo.lpm_widthu  = $clog2(ARADDR_FIFO_DEPTH),
          araddr_fifo.overflow_checking  = "OFF",
          araddr_fifo.underflow_checking  = "OFF", 
          araddr_fifo.use_eab  = "ON";  
		  
assign avmm_address = avmm_address_reg;
assign avmm_write = avmm_write_reg;
assign avmm_writedata = avmm_writedata_reg;
assign avmm_byteenable = avmm_byteenable_reg;
assign avmm_read = avmm_read_reg;

// MUX between Write and Read
// Write operation has higher priority over Read operation
always_ff @ (posedge clk) begin
if (~rst_n) begin
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
  if (~waddr_fifo_empty & ~wdata_fifo_empty & ~write_pending & ~read_pending) begin 
       avmm_address_reg   <= waddr_fifo_rd_data;
                 avmm_writedata_reg <= wdata_fifo_rd_data;
                 avmm_byteenable_reg <= wstrb_fifo_rd_data;
                 avmm_write_reg     <= 'b1;
                 write_pending      <= 'b1;
                 waddr_fifo_pop <= 'b1;
                 wdata_fifo_pop <= 'b1;
  end else if (write_pending) begin
                 waddr_fifo_pop <= 'b0;
                 wdata_fifo_pop <= 'b0;
              if (~avmm_waitrequest) begin
                avmm_write_reg <= 'b0;
                bresp_reg      <= avmm_address_out_of_range ? 2'b11 : 2'b00;
                bvalid_reg     <= 'b1;
              end else if (bready & bvalid_reg) begin
                bvalid_reg    <= 'b0;
                write_pending <= 'b0;
                //Complete Write sequence
              end   
  end else if (~araddr_fifo_empty & ~read_pending & ~write_pending) begin
                avmm_address_reg <= araddr_fifo_rd_data;
                avmm_read_reg    <= 'b1;
                
                read_pending     <= 'b1;
                araddr_fifo_pop <= 'b1;
  end else if (read_pending) begin
                araddr_fifo_pop <= 'b0;
              if (~avmm_waitrequest) begin
                avmm_read_reg <= 'b0;
                rdata_reg     <= avmm_readdata;
                rresp_reg     <= avmm_address_out_of_range ? 2'b11 : 2'b00;
                rvalid_reg    <= 'b1;
              end else if (rready & rvalid_reg) begin
                rvalid_reg   <= 'b0;
                read_pending <= 'b0;
                //Complete Read sequence
              end
  end 
end
end

end
endgenerate

endmodule
