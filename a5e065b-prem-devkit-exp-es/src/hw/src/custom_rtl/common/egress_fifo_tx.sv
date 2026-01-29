`timescale 1 ps / 1 ps
module egress_fifo_tx #(
 parameter FIFO_DEPTH               = 4 ,
 parameter TX_EGRESS                =104
)
  (
  input                    i_clk,                                    
  input	                   i_rstn, 
  
  input                    in_valid,
  input   [TX_EGRESS-1:0]  in_data_tsp,
 
  input                    in_ready,
  output                   out_valid,
  output   [TX_EGRESS-1:0] out_data,
  output   [TX_EGRESS-1:0] out_data_ts,
  
  output    [FIFO_DEPTH-1:0] fifo_length

);
  

localparam FIFO_DATA_WIDTH 	      = $bits(in_data_tsp);

wire [FIFO_DATA_WIDTH-1:0]fifo_wdata,fifo_rdata;
reg  [FIFO_DATA_WIDTH-1:0]temp_fifo_rdata;
wire fifo_wreq,fifo_rdreq,fifo_full,fifo_rdempty;
  //----------------------------------------------
  // FIFO write logic
  //----------------------------------------------
  
  assign fifo_wdata        = in_data_tsp;
  assign fifo_wreq	       = in_valid;
  
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

  //----------------------------------------------
  // FIFO read logic
  //----------------------------------------------  
   assign fifo_rdreq = !fifo_rdempty & in_ready ;
 
    always_comb begin
    if(fifo_rdreq )	
      temp_fifo_rdata = fifo_rdata;
    else
      temp_fifo_rdata = 'd0;
  end  

  assign out_valid    = !fifo_rdempty;//fifo_rdreq;
  assign out_data     = temp_fifo_rdata;
  assign out_data_ts  = temp_fifo_rdata[95:0];

endmodule	  