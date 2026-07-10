//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module parameter_scfifo #(
    parameter int ADDR_WIDTH        = 4
   ,parameter int DATA_WIDTH        = 64
   ,parameter int ALMOST_FULL_VALUE = 3
   ,parameter     RAM_BLOCK_TYPE = "MLAB" //MLAB or M20K
   ,parameter int NUMBER_WORDS      = 0
) (
    input  logic                    clock
   ,input  logic                    aclr
   ,input  logic                    wrreq
   ,input  logic                    rdreq
   ,input  logic [DATA_WIDTH - 1:0] data
   ,output logic                    almost_full
   ,output logic                    empty
   ,output logic                    full
   ,output logic [DATA_WIDTH - 1:0] q
   ,output logic [ADDR_WIDTH - 1:0] usedw
);

   localparam int NUMBER_WORDS_FINAL = (NUMBER_WORDS & RAM_BLOCK_TYPE == "MLAB") ? NUMBER_WORDS : ADDR_WIDTH;
   localparam int ALMOST_FULL = 2**NUMBER_WORDS_FINAL - 1 - ALMOST_FULL_VALUE;
   localparam     RAM_BLOCK_TYPE_STRING = {"RAM_BLOCK_TYPE=", RAM_BLOCK_TYPE};

   scfifo scfifo_component (
       .clock         (clock      )
      ,.data          (data       )
      ,.rdreq         (rdreq      )
      ,.wrreq         (wrreq      )
      ,.almost_full   (almost_full)
      ,.empty         (empty      )
      ,.full          (full       )
      ,.q             (q          )
      ,.aclr          (aclr       )
      ,.almost_empty  (           )
      ,.eccstatus     (           )
      ,.sclr          (1'b0       )
      ,.usedw         (usedw      )
   );
   defparam
      scfifo_component.add_ram_output_register  = "ON",
      scfifo_component.almost_full_value  = ALMOST_FULL,
      scfifo_component.enable_ecc  = "FALSE",
      scfifo_component.intended_device_family  = "Arria 10",
      scfifo_component.lpm_hint  = RAM_BLOCK_TYPE_STRING,
      scfifo_component.lpm_numwords  = 2**NUMBER_WORDS_FINAL,
      scfifo_component.lpm_showahead  = "ON",
      scfifo_component.lpm_type  = "scfifo",
      scfifo_component.lpm_width  = DATA_WIDTH,
      scfifo_component.lpm_widthu  = NUMBER_WORDS_FINAL,
      scfifo_component.overflow_checking  = "ON",
      scfifo_component.underflow_checking  = "ON",
      scfifo_component.use_eab  = "ON";
endmodule
