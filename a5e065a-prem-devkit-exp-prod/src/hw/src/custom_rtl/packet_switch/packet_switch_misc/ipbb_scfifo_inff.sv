//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

//--------------------------------------------------------------------------------------------
// Description: ipbb_scfifo_inff
// 
// - scfifo wrapper with optional input FF
//
//--------------------------------------------------------------------------------------------

module ipbb_scfifo_inff 
 # (
    parameter DWD      = 2,
    parameter DEVICE_FAMILY = "Stratix 10",
    parameter NUM_WORDS = 8,
    parameter lpm_type = "scfifo",
    //parameter RAM_BLOCK_TYPE = "AUTO",
    parameter NO_INFF  = 0,		 // no input ff	
    parameter USE_MLAB = 0 	         // set this bit if NUM_WORDS <=32 and
                                         // want to force MLAB
    ) 
   (
    input logic 			  clk,
    
    input logic 			  rst, 
    input logic [(DWD-1):0] 		  din,
    input logic 			  wrreq,
    input logic 			  rdreq,
    
    output logic [(DWD-1):0] 		  dout, 
    output logic 			  rdempty,
    output logic 			  wrfull,
    output logic [$clog2(NUM_WORDS) -1:0] wrusedw,

    // rdempty_lkahd is valid for scfifo mode only and rdreq should not uses this signal
    // to generate the combination logic 
    output logic 			  rdempty_lkahd,

    //overflow & underflow signals
    output logic 			  overflow,
    output logic 			  underflow
    );

   localparam RAM_BLOCK_TYPE = 
               (USE_MLAB == 1) & (NUM_WORDS <= 32) ? "MLAB" : "AUTO";
   
   
   logic [(DWD-1):0] 			  din_dly;
   logic                                  wrreq_dly, fifo_push;
   logic [$clog2(NUM_WORDS) -1:0] 	  cnt;
   logic wrfull_c1, wrreq_dly_c1, rdreq_c1, rdempty_c1;
   
   generate
      // no input ff
      if (NO_INFF == 1) begin
	 always_comb begin
	    din_dly   = din;
	    wrreq_dly = wrreq;
	 end
      end

      // input ff
      else begin
	 ipbb_pipe #( .W (  DWD
			       + 1   )
			 ,.N (1)   ) pipe_dly
	   (
	    .clk (clk)
	    ,.dIn ({din
		    ,wrreq })
	    
	    ,.dOut ({din_dly
		     ,wrreq_dly})
	    );
      end // else: !if(NO_INFF == 1)
      
   endgenerate

   ipbb_pipe #( .W (1)
		  ,.N (2)   ) pipe_dly2
     (
       .clk (clk)
      ,.dIn (wrreq_dly)

      ,.dOut (fifo_push)
      );
 
   always_ff @(posedge clk) begin
      if (fifo_push & !rdreq)
	cnt <= cnt + 1'b1;
      else if (!fifo_push & rdreq)
	cnt <= cnt - 1'b1;
      
      if (rst)
	cnt <= '0;     
   end
   
   always_comb begin
      // rdempty_lkahd is valid for scfifo mode only
      rdempty_lkahd = 
        (!fifo_push & rdreq & (cnt == 'd1)) ? '1 
                                              : rdempty;
   end
   
   
   generate     
      scfifo  scfifo_inst 
	(
	 .clock                    (clk),
	 .data                     (din_dly),
	 .rdreq                    (rdreq),
	 .wrreq                    (wrreq_dly),
	 .almost_full              (),
	 .full                     (wrfull),    
	 .q                        (dout),
	 .aclr                     (1'b0),
	 .almost_empty             (),
	 .eccstatus                (), 
	 .empty                    (rdempty),     
	 .sclr                     (rst),
	 .usedw                    (wrusedw));     
      defparam
	scfifo_inst.add_ram_output_register  = "ON",
	// scfifo_inst.almost_full_value  = FIFO_ALMOST_FULL,
	scfifo_inst.enable_ecc  = "FALSE",
	scfifo_inst.intended_device_family  = DEVICE_FAMILY,
	scfifo_inst.ram_block_type  = RAM_BLOCK_TYPE,
	scfifo_inst.lpm_numwords  = NUM_WORDS,
	scfifo_inst.lpm_showahead  = "ON",
	scfifo_inst.lpm_type  = "scfifo",
	scfifo_inst.lpm_width  = DWD,
	scfifo_inst.lpm_widthu  = $clog2(NUM_WORDS),
	scfifo_inst.overflow_checking  = "OFF",
	scfifo_inst.underflow_checking  = "OFF", 
	scfifo_inst.use_eab  = "ON";
      
      
      //------------------------------------------------------------------------------------
      // synopsys translate_off
      event ev_err;
      always @(ev_err) #1000 $finish;
      
      always_ff @(posedge clk) begin
	 if (wrfull & wrreq_dly) begin
	    $display ("EV_ERROR: fifo ov_err %m");
	    -> ev_err;
	 end
      end
      
      always_ff @(posedge clk) begin
	 if (rdempty & rdreq & !rst) begin
	    $display ("EV_ERROR: fifo ud_err %m");
	    -> ev_err;
	 end
      end
      // synopsys translate_on
      //------------------------------------------------------------------------------------
	 
	 //overflow and underflow	 
	 always_ff @(posedge clk) begin
			wrfull_c1 <= wrfull;
			wrreq_dly_c1 <= wrreq_dly;
			rdreq_c1 <= rdreq;
			rdempty_c1 <= rdempty;
	        overflow <= wrfull_c1 & wrreq_dly_c1 & !rdreq_c1;
		    if (rst)
		      underflow <= '0;
	            else
		    underflow <= rdempty_c1 & rdreq_c1;
	 end    
	 


   endgenerate
endmodule
