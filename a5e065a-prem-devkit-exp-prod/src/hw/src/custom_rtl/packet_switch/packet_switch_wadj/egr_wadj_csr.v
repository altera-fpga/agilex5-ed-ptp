//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module egr_wadj_csr(

   // control_reg.drop_en
   output reg control_reg_drop_en,
   // cfg_drop_threshold_reg.drop_threshold
   output reg [15:0] cfg_drop_threshold_reg_drop_threshold,

   // Bus interface
   input wire clk,
   input wire reset,
   input wire [31:0] writedata,
   input wire read,
   input wire write,
   input wire [3:0] byteenable,
   output reg [31:0] readdata,
   output reg readdatavalid,
   input wire [3:0] address
);

wire reset_n = !reset;

reg [31:0] scratch_reg_scratch;

// -----------------------------------------------------------------------------
// Protocol management
// -----------------------------------------------------------------------------

reg [31:0] rdata_comb;
always @(posedge clk)
   if (!reset_n) readdata[31:0] <= 32'h00000000; else readdata[31:0] <= rdata_comb[31:0];

// Read data is always valid the cycle after read transaction is asserted
always @(posedge clk)
   if (!reset_n) readdatavalid <= 1'b0; else readdatavalid <= read;

wire we = write;
wire re = read;
wire [3:0] addr = address[3:0];
wire [31:0] din = writedata[31:0];

// -----------------------------------------------------------------------------
// Write byte enables
// -----------------------------------------------------------------------------

// Register scratch_reg
wire [3:0] we_scratch_reg = we & (addr[3:0] == 4'h0) ? byteenable[3:0] : {4{1'b0}};
// Register control_reg
wire we_control_reg = we & (addr[3:0] == 4'h4) ? byteenable[0] : 1'b0;
// Register cfg_drop_threshold_reg
wire [1:0] we_cfg_drop_threshold_reg = we & (addr[3:0] == 4'h8) ? byteenable[1:0] : {2{1'b0}};

// -----------------------------------------------------------------------------
// Read byte enables
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Register scratch_reg implementation
// -----------------------------------------------------------------------------

// scratch_reg_scratch
//    bitfield description: Scratch Register.
//    customType          : RW
//    hwAccess            : NA
//    reset value         : 32'h00000000

always @(posedge clk)
   if (!reset_n) begin
      scratch_reg_scratch <= 32'h00000000;
   end
   else begin
      if (we_scratch_reg[0]) begin
         scratch_reg_scratch[7:0] <= din[7:0];
      end
      if (we_scratch_reg[1]) begin
         scratch_reg_scratch[15:8] <= din[15:8];
      end
      if (we_scratch_reg[2]) begin
         scratch_reg_scratch[23:16] <= din[23:16];
      end
      if (we_scratch_reg[3]) begin
         scratch_reg_scratch[31:24] <= din[31:24];
      end
   end

// -----------------------------------------------------------------------------
// Register control_reg implementation
// -----------------------------------------------------------------------------

// control_reg_drop_en
//    bitfield description: Enable drop threshold to be used for egress width adapter.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 1'h0

always @(posedge clk)
   if (!reset_n) begin
      control_reg_drop_en <= 1'h0;
   end
   else begin
      if (we_control_reg) begin
         control_reg_drop_en <= din[0];
      end
   end

// control_reg_reserved
//    bitfield description: Reserved.
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 31'h00000000
//
// No register generated

// -----------------------------------------------------------------------------
// Register cfg_drop_threshold_reg implementation
// -----------------------------------------------------------------------------

// cfg_drop_threshold_reg_drop_threshold
//    bitfield description: Drop threshold for egress width adapter.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 16'h01f0

always @(posedge clk)
   if (!reset_n) begin
      cfg_drop_threshold_reg_drop_threshold <= 16'h01f0;
   end
   else begin
      if (we_cfg_drop_threshold_reg[0]) begin
         cfg_drop_threshold_reg_drop_threshold[7:0] <= din[7:0];
      end
      if (we_cfg_drop_threshold_reg[1]) begin
         cfg_drop_threshold_reg_drop_threshold[15:8] <= din[15:8];
      end
   end

// cfg_drop_threshold_reg_reserved
//    bitfield description: Reserved.
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 16'h0000
//
// No register generated

// -----------------------------------------------------------------------------
// Data read management
// -----------------------------------------------------------------------------

always @(*)
begin
   rdata_comb = 32'h00000000;
   if (re) begin
      case (addr)
         // Register scratch_reg: scratch_reg_scratch (RW)
         4'h0: begin
            rdata_comb[31:0] = scratch_reg_scratch[31:0];
         end
         // Register control_reg: control_reg_drop_en (RW)
         //                       control_reg_reserved (RO)
         4'h4: begin
            rdata_comb[0] = control_reg_drop_en;
            rdata_comb[31:1] = 31'h00000000;
         end
         // Register cfg_drop_threshold_reg: cfg_drop_threshold_reg_drop_threshold (RW)
         //                                  cfg_drop_threshold_reg_reserved (RO)
         4'h8: begin
            rdata_comb[15:0] = cfg_drop_threshold_reg_drop_threshold[15:0];
            rdata_comb[31:16] = 16'h0000;
         end
         default: begin
            rdata_comb = 32'h00000000;
         end
      endcase
   end
end

endmodule