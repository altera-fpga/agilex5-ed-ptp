//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


// ==========================================================================
// Project           : HSSI Subsystem 
// Module            : hssi_scfifo.sv
// Description       : 
// Author            : 
// Created           : 
// Changes           : 
//                   : 
// ==========================================================================1

// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

module hssi_scfifo # ( 
   parameter SIM_EMULATE            = 0,
   parameter enable_ecc             = "FALSE",
   parameter intended_device_family = "Agilex",
   parameter lpm_hint               = "RAM_BLOCK_TYPE=M20K",
   parameter lpm_width              = 494,
   parameter lpm_widthu             = 5,
   parameter lpm_numwords           = 32,
   parameter lpm_type               = "scfifo",
   parameter lpm_showahead          = "OFF",
   parameter overflow_checking      = "OFF",
   parameter underflow_checking     = "OFF",
   parameter almost_full_value      = 4,
   // parameter almost_empty_value     = 31,
   parameter use_eab                = "ON"
)(
                    
   input                       clock,
   input                       aclr,
   input                       sclr,
   
   input                       wrreq,
   input  [lpm_width -1 :0]    data,
   
   input                       rdreq,
   output [lpm_width -1 :0]    q,
           
   output                      almost_empty,
   output                      almost_full,
   output                      empty,
   output                      full,
   output [1:0]                eccstatus,
   output [lpm_widthu-1:0]     usedw,
   output reg                  flag
);

   localparam almost_empty_value     = 2;

 // reg                           empty_d1;
 wire [lpm_width -1 :0]        data_out ;

 always @(posedge clock or posedge aclr) 
 begin
    if (aclr) begin
       flag <= 1'b1;
    end 
    else begin
       flag <= (flag & (!empty))? 1'b0 : flag;
    end
 end
 
 assign q = data_out;
 
/* 
generate 
   if (SIM_EMULATE) begin: FIFO_SIM_EMULATE_ON
   
      always @(posedge clock or posedge aclr) 
      begin
         if (aclr) begin
            flag <= 1'b1;
         end 
         else begin
            flag <= (flag & (!empty))? 1'b0 : flag;
         end
      end
      
	  assign q = data_out;
      
   end
   else begin: FIFO_SIM_EMULATE_OFF
      assign q = data_out;
   end
endgenerate  
*/
 
 /*always @(posedge clock) 
 begin
    empty_d1 <= empty;
 end*/
      
// assign q = data_out;   
      
generate      

if (enable_ecc == "TRUE") begin : SCFIFO_WITH_ECC
scfifo  sc_fifo_inst (
   .clock        ( clock        ),
   .data         ( data         ),
   .wrreq        ( wrreq        ),
   .rdreq        ( rdreq        ),
   .empty        ( empty        ),
   .full         ( full         ),
   .q            ( data_out     ),
   .usedw        ( usedw        ),
   .aclr         ( aclr         ),
   .almost_empty ( almost_empty ),
   .almost_full  ( almost_full  ),
   .eccstatus    ( eccstatus    ),
   .sclr         ( sclr         )
   );
  defparam
    sc_fifo_inst.add_ram_output_register  = "ON",
    sc_fifo_inst.enable_ecc               = enable_ecc,
    sc_fifo_inst.intended_device_family   = intended_device_family,
    sc_fifo_inst.lpm_numwords             = lpm_numwords,
    sc_fifo_inst.lpm_hint                 = lpm_hint,
    sc_fifo_inst.lpm_showahead            = "OFF",
    sc_fifo_inst.lpm_type                 = lpm_type,
    sc_fifo_inst.lpm_width                = lpm_width,
    sc_fifo_inst.lpm_widthu               = lpm_widthu,
    sc_fifo_inst.overflow_checking        = overflow_checking,
    sc_fifo_inst.underflow_checking       = underflow_checking,
    sc_fifo_inst.almost_full_value        = almost_full_value,
    sc_fifo_inst.almost_empty_value       = almost_empty_value,
    sc_fifo_inst.use_eab                  = use_eab;
    
end
else begin : SCFIFO_WITHOUT_ECC
scfifo  sc_fifo_inst (
   .clock        ( clock        ),
   .data         ( data         ),
   .wrreq        ( wrreq        ),
   .rdreq        ( rdreq        ),
   .empty        ( empty        ),
   .full         ( full         ),
   .q            ( data_out     ),
   .usedw        ( usedw        ),
   .aclr         ( aclr         ),
   .almost_empty ( almost_empty ),
   .almost_full  ( almost_full  ),
   .eccstatus    (     ),
   .sclr         ( sclr         )
   );
  defparam
    sc_fifo_inst.add_ram_output_register  = "ON",
    // sc_fifo_inst.enable_ecc               = enable_ecc,
    sc_fifo_inst.intended_device_family   = intended_device_family,
    sc_fifo_inst.lpm_numwords             = lpm_numwords,
    sc_fifo_inst.lpm_hint                 = lpm_hint,
    sc_fifo_inst.lpm_showahead            = "OFF",
    sc_fifo_inst.lpm_type                 = lpm_type,
    sc_fifo_inst.lpm_width                = lpm_width,
    sc_fifo_inst.lpm_widthu               = lpm_widthu,
    sc_fifo_inst.overflow_checking        = overflow_checking,
    sc_fifo_inst.underflow_checking       = underflow_checking,
    sc_fifo_inst.almost_full_value        = almost_full_value,
    sc_fifo_inst.almost_empty_value       = almost_empty_value,
    sc_fifo_inst.use_eab                  = use_eab;
    
end

endgenerate

endmodule

