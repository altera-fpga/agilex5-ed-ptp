//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

//--------------------------------------------------------------------------------------------
// Description: packet_switch_ipbb_sdc_fifo_inff
// 
// - scfifo, dcfifo wrapper with optional input FF
//
//--------------------------------------------------------------------------------------------

module packet_switch_ipbb_sdc_fifo_inff 
 # (
    parameter DWD      = 2,
    parameter DEVICE_FAMILY = "Stratix 10",
    parameter NUM_WORDS = 8,
    parameter lpm_type = "scfifo",
    parameter RAM_BLOCK_TYPE = "AUTO",
    parameter NO_INFF = 0		 // no input ff		
    ) 
   (
    input logic 			  clk1,
    input logic 			  clk2,
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

   logic [(DWD-1):0] 			  din_dly;
   logic                                  wrreq_dly, fifo_push;
   logic [$clog2(NUM_WORDS) -1:0] 	  cnt;

   logic wrfull_c1, rdempty_c1, rdreq_c1, wrreq_dly_c1;
   
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
	 packet_switch_pipe_dly #( .W (  DWD
			       + 1   )
			 ,.N (1)   ) pipe_dly
	   (
	    .clk (clk1)
	    ,.dIn ({din
		    ,wrreq })
	    
	    ,.dOut ({din_dly
		     ,wrreq_dly})
	    );
      end // else: !if(NO_INFF == 1)
      
   endgenerate

   packet_switch_pipe_dly #( .W (1)
		  ,.N (2)   ) pipe_dly2
     (
       .clk (clk1)
      ,.dIn (wrreq_dly)

      ,.dOut (fifo_push)
      );
 
   always_ff @(posedge clk1) begin
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
   
   always_ff @(posedge clk1) begin
		rdreq_c1     <= rdreq;
		rdempty_c1   <= rdempty;
		wrfull_c1    <= wrfull;
		wrreq_dly_c1 <= wrreq_dly;
	end
   
   generate
      if (lpm_type == "dcfifo") begin
	 dcfifo dcfifo_inst 
	   (
	    .aclr 	 (rst),
	    .wrclk 	(clk1),
	    .wrreq 	(wrreq_dly),
	    .data 	(din_dly),
	    .rdclk 	(clk2),
	    .rdreq 	(rdreq),
	    .q 		(dout),
	    .wrusedw	(wrusedw),
	    .rdempty	(rdempty),
	    
	    .wrfull     (wrfull),
	    .rdfull     (),
	    .wrempty    (),
	    .rdusedw    (),
	    .eccstatus  ()
	    );
	 defparam
	   dcfifo_inst.intended_device_family  = DEVICE_FAMILY,
	   dcfifo_inst.use_eab  = "ON",
	   dcfifo_inst.lpm_hint  = 
            "MAXIMUM_DEPTH=16,DISABLE_DCFIFO_EMBEDDED_TIMING_CONSTRAINT=TRUE",
	   dcfifo_inst.ram_block_type = RAM_BLOCK_TYPE,
	   dcfifo_inst.lpm_type  = "dcfifo",
	   dcfifo_inst.lpm_width  = DWD,
	   dcfifo_inst.lpm_widthu  = $clog2(NUM_WORDS),
	   dcfifo_inst.lpm_numwords  = NUM_WORDS,
	   dcfifo_inst.lpm_showahead  = "ON",				
	   dcfifo_inst.enable_ecc  = "FALSE",
	   dcfifo_inst.overflow_checking  = "OFF",
	   dcfifo_inst.underflow_checking  = "OFF",
	   // If clk1 and clk2 are synchronized (have same source with diff multiple) 
	   // then change to true and remove delaypipe
	   dcfifo_inst.clocks_are_synchronized = "TRUE", 
	   //dcfifo_inst.rdsync_delaypipe  = 5,
	   //dcfifo_inst.wrsync_delaypipe  = 5,
	   dcfifo_inst.write_aclr_synch = "ON",
	   dcfifo_inst.read_aclr_synch = "ON",
	   dcfifo_inst.add_ram_output_register = "ON";


	 //------------------------------------------------------------------------------------
	 // synopsys translate_off
	 event ev_err;
	 always @(ev_err) #1000 $finish;

	 always_ff @(posedge clk1) begin
	    if (wrfull & wrreq_dly) begin
	       $display ("EV_ERROR: fifo ov_err %m");
	       -> ev_err;
	    end
	 end

	 always_ff @(posedge clk2) begin
	    if (rdempty & rdreq & !rst) begin
	       $display ("EV_ERROR: fifo ud_err %m");
	       -> ev_err;
	    end
	 end
	 // synopsys translate_on
	 //------------------------------------------------------------------------------------
	 //overflow and underflow	 
	 always_ff @(posedge clk1) begin
	    if (wrfull & wrreq_dly) overflow <= '1;
	 end
	 always_ff @(posedge clk2) begin
	   if (rst) underflow <= '0; 
           else if (rdempty & rdreq)    underflow <= '1;
	 end
	 
      end else begin
	 scfifo  scfifo_inst 
	   (
	    .clock                    (clk1),
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

	 always_ff @(posedge clk1) begin
	    if (wrfull & wrreq_dly) begin
	       $display ("EV_ERROR: fifo ov_err %m");
	       -> ev_err;
	    end
	 end

	 always_ff @(posedge clk2) begin
	    if (rdempty & rdreq & !rst) begin
	       $display ("EV_ERROR: fifo ud_err %m");
	       -> ev_err;
	    end
	 end
	 // synopsys translate_on
	 //------------------------------------------------------------------------------------
	 //overflow and underflow	 
	 always_ff @(posedge clk1) begin
	    overflow <= wrfull_c1 & wrreq_dly_c1;
	 end
	 always_ff @(posedge clk2) begin
	    if (rst)
              underflow <= '0;
            else
	    underflow <= rdempty_c1 & rdreq_c1;
	 end
      end
	  
	
	
   endgenerate
endmodule
