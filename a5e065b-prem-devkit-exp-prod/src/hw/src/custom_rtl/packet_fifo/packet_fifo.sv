// ######################################################################## 
// Copyright (C) 2025 Altera Corporation.
// SPDX-License-Identifier: MIT
// ######################################################################## 
// -------------------------------------------------------------------------- #
  // axis_rx_if.tvalid to axis_tx_if.tvalid (7 clock cycles of data)
  // once axis_rx_if.tlast asserted then next clock cycles we have axis_tx_if.tvalid & data
  //-----------------------------------------------
`timescale 1 ps / 1 ps
module packet_fifo #(
 //parameter MODE              = 1,//1 --> uncontrolled port , 0 --> controlled port
 parameter FIFO_DEPTH               = 4  ,
 parameter DEBUG_ENABLE             = 1 
)
  (
  input                    i_clk,                                    
  input	                   i_rstn, 
  
  axis_if.source           axis_tx_if,    
  axis_if.sink             axis_rx_if,
  output    [FIFO_DEPTH-1:0] fifo_length,
  output    out_read_request,
  output logic [63:0]in_counter,
  output logic [63:0]out_counter

);

  //-----------------------------------------------
  // local paramters
  //-----------------------------------------------
  
 // localparam FIFO_DEPTH               = 4;              
  localparam [31:0]PKT_COUNTER_WIDTH   = 32'd32;
  localparam FIFO_DATA_WIDTH 	      = 1 + $bits(axis_rx_if.tdata)/8 + $bits(axis_rx_if.tdata) + $bits(axis_rx_if.tid);
  localparam TID 	                  = $bits(axis_rx_if.tid);
  localparam TDATA 	                  = $bits(axis_rx_if.tdata);
  localparam TKEEP                    = $bits(axis_rx_if.tdata)/8;
  //localparam BYTE_COUNTER_WIDTH       = 32;
  
  //-----------------------------------------------
  // Signals
  //-----------------------------------------------
 
  logic [PKT_COUNTER_WIDTH-1:0]       rx_pkt_counter;       
  logic [FIFO_DATA_WIDTH-1:0]         fifo_wdata;
  logic [FIFO_DATA_WIDTH-1:0]         fifo_rdata;
  logic [FIFO_DATA_WIDTH-1:0]         temp_fifo_rdata;
  logic 			                  fifo_wreq;
  logic 			                  fifo_rdreq;
  logic 			                  temp_rdreq;
  logic 		                      fifo_full;
  logic 		                      fifo_rdempty;
  
  //----------------------------------------------
  // FIFO write logic
  //----------------------------------------------
  
  assign fifo_wdata        = {axis_rx_if.tlast,axis_rx_if.tkeep,axis_rx_if.tdata,axis_rx_if.tid};
  assign fifo_wreq	       = axis_rx_if.tvalid & axis_rx_if.tready;
  
  //----------------------------------------------
  // Back Pressure 
  //----------------------------------------------
  
  assign axis_rx_if.tready = (!fifo_full);
   
   //---------------------------------------------
  // Rx packet counter
  //----------------------------------------------
  always @(posedge i_clk or negedge i_rstn) begin
    if(!i_rstn)
     rx_pkt_counter <= 'd0;
    else if (temp_fifo_rdata[FIFO_DATA_WIDTH-1] && axis_rx_if.tlast && axis_rx_if.tvalid && axis_rx_if.tready && (axis_tx_if.tready))
     rx_pkt_counter  <= rx_pkt_counter;
    else if (temp_fifo_rdata[FIFO_DATA_WIDTH-1] && (axis_tx_if.tready) ) 
     rx_pkt_counter <= rx_pkt_counter-1'b1;
    else if(axis_rx_if.tlast && axis_rx_if.tvalid && axis_rx_if.tready)
     rx_pkt_counter <= rx_pkt_counter+1'b1;
  end 
  
  //----------------------------------------------
  // FIFO read logic
  //----------------------------------------------  
   assign fifo_rdreq = (rx_pkt_counter > 'd0) ?  axis_tx_if.tready & !fifo_rdempty : 1'b0;
   assign out_read_request = fifo_rdreq;
    always_comb begin
    if(fifo_rdreq )	
      temp_fifo_rdata = fifo_rdata;
    else
      temp_fifo_rdata = 'd0;
  end  
  
   //assign tx_tlast  =  temp_fifo_rdata[TKEEP+TDATA+TID]; 
  //--------------------------------------
  // Enable output AXI-Stream TX
  //--------------------------------------
  
  assign axis_tx_if.tvalid  = (rx_pkt_counter > 'd0) & !fifo_rdempty;//!fifo_rdempty;//fifo_rdreq;
  assign axis_tx_if.tid     = (!fifo_rdempty)? fifo_rdata[TID-1:0]                        : '0  ;
  assign axis_tx_if.tdata   = (!fifo_rdempty)? fifo_rdata[(TDATA+TID)-1:TID]            : '0  ;                        
  assign axis_tx_if.tkeep   = (!fifo_rdempty)? fifo_rdata[(TKEEP+TDATA+TID)-1:TID+TDATA]: '0  ;                        
  assign axis_tx_if.tlast   = temp_fifo_rdata[TKEEP+TDATA+TID]; 
  
//----------------------------------------------
//  SC_FIFO Instance 
//----------------------------------------------

     fim_scfifo  #(
     .DATA_WIDTH (FIFO_DATA_WIDTH),
	 .DEPTH_LOG2 (FIFO_DEPTH),
	 .SHOWAHEAD  ("ON"),
	 .USE_EAB    ("ON")
	 )
     fim_scfifo_inst(
     .clk    (i_clk),
     //.sclr	 (1'b0),
     .sclr	 (!i_rstn),
     .w_data (fifo_wdata),
     .w_req  (fifo_wreq),
     .r_req  (fifo_rdreq),
     .r_data (fifo_rdata),
     .w_usedw(fifo_length),
     .r_usedw(),
     .w_full (fifo_full),
     .w_ready(),
     .r_empty(fifo_rdempty),
     .r_valid () // r_valid is set when r_data is valid.
	  );
	  
	  
	 //`ifndef ALTERA_RESERVED_QIS  
	   
	  generate if(DEBUG_ENABLE) begin
	 
	  always@(posedge i_clk or negedge i_rstn) begin
	  if(!i_rstn)
	  in_counter <='d0;
	  else if(axis_rx_if.tlast && axis_rx_if.tready && axis_rx_if.tvalid)
	  in_counter <= in_counter + 1'b1;
	  else
	  in_counter <= in_counter;
	  end
	  
	  	always@(posedge i_clk or negedge i_rstn) begin
	  if(!i_rstn)
	  out_counter <=0;
	  else if(axis_tx_if.tlast && axis_tx_if.tready && axis_tx_if.tvalid)
	  out_counter <= out_counter +1'b1;
	  else
	  out_counter <= out_counter;
	  end
	  
	  end endgenerate
	  
	//  `endif
	  
	  
endmodule
//-------------------------------------------------------------------------------
//
// End 
//
//-------------------------------------------------------------------------------
