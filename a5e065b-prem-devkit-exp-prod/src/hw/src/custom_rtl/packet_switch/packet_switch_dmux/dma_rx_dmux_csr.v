//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module dma_rx_dmux_csr(

   // control_reg.dma_0_drop_en
   output reg control_reg_dma_0_drop_en,
   // control_reg.dma_1_drop_en
   output reg control_reg_dma_1_drop_en,
   // control_reg.dma_2_drop_en
   output reg control_reg_dma_2_drop_en,
   // control_reg.dma_3_drop_en
   output reg control_reg_dma_3_drop_en,
   // control_reg.dma_4_drop_en
   output reg control_reg_dma_4_drop_en,
   // control_reg.dma_5_drop_en
   output reg control_reg_dma_5_drop_en,
   // control_reg.dma_6_drop_en
   output reg control_reg_dma_6_drop_en,
   // control_reg.dma_7_drop_en
   output reg control_reg_dma_7_drop_en,
   // dma_0_drop_threshold_reg.drop_threshold
   output reg [15:0] dma_0_drop_threshold_reg_drop_threshold,
   // dma_1_drop_threshold_reg.drop_threshold
   output reg [15:0] dma_1_drop_threshold_reg_drop_threshold,
   // dma_2_drop_threshold_reg.drop_threshold
   output reg [15:0] dma_2_drop_threshold_reg_drop_threshold,
   // dma_3_drop_threshold_reg.drop_threshold
   output reg [15:0] dma_3_drop_threshold_reg_drop_threshold,
   // dma_4_drop_threshold_reg.drop_threshold
   output reg [15:0] dma_4_drop_threshold_reg_drop_threshold,
   // dma_5_drop_threshold_reg.drop_threshold
   output reg [15:0] dma_5_drop_threshold_reg_drop_threshold,
   // dma_6_drop_threshold_reg.drop_threshold
   output reg [15:0] dma_6_drop_threshold_reg_drop_threshold,
   // dma_7_drop_threshold_reg.drop_threshold
   output reg [15:0] dma_7_drop_threshold_reg_drop_threshold,

   // Bus interface
   input wire clk,
   input wire reset,
   input wire [31:0] writedata,
   input wire read,
   input wire write,
   input wire [3:0] byteenable,
   output reg [31:0] readdata,
   output reg readdatavalid,
   input wire [5:0] address
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
wire [5:0] addr = address[5:0];
wire [31:0] din = writedata[31:0];

// -----------------------------------------------------------------------------
// Write byte enables
// -----------------------------------------------------------------------------

// Register scratch_reg
wire [3:0] we_scratch_reg = we & (addr[5:0] == 6'h00) ? byteenable[3:0] : {4{1'b0}};
// Register control_reg
wire we_control_reg = we & (addr[5:0] == 6'h04) ? byteenable[0] : 1'b0;
// Register dma_0_drop_threshold_reg
wire [1:0] we_dma_0_drop_threshold_reg = we & (addr[5:0] == 6'h08) ? byteenable[1:0] : {2{1'b0}};
// Register dma_1_drop_threshold_reg
wire [1:0] we_dma_1_drop_threshold_reg = we & (addr[5:0] == 6'h0c) ? byteenable[1:0] : {2{1'b0}};
// Register dma_2_drop_threshold_reg
wire [1:0] we_dma_2_drop_threshold_reg = we & (addr[5:0] == 6'h10) ? byteenable[1:0] : {2{1'b0}};
// Register dma_3_drop_threshold_reg
wire [1:0] we_dma_3_drop_threshold_reg = we & (addr[5:0] == 6'h14) ? byteenable[1:0] : {2{1'b0}};
// Register dma_4_drop_threshold_reg
wire [1:0] we_dma_4_drop_threshold_reg = we & (addr[5:0] == 6'h18) ? byteenable[1:0] : {2{1'b0}};
// Register dma_5_drop_threshold_reg
wire [1:0] we_dma_5_drop_threshold_reg = we & (addr[5:0] == 6'h1c) ? byteenable[1:0] : {2{1'b0}};
// Register dma_6_drop_threshold_reg
wire [1:0] we_dma_6_drop_threshold_reg = we & (addr[5:0] == 6'h20) ? byteenable[1:0] : {2{1'b0}};
// Register dma_7_drop_threshold_reg
wire [1:0] we_dma_7_drop_threshold_reg = we & (addr[5:0] == 6'h24) ? byteenable[1:0] : {2{1'b0}};

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

// control_reg_dma_0_drop_en
//    bitfield description: Enable drop threshold to be used for DMA CH_0.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 1'h0

always @(posedge clk)
   if (!reset_n) begin
      control_reg_dma_0_drop_en <= 1'h0;
   end
   else begin
      if (we_control_reg) begin
         control_reg_dma_0_drop_en <= din[0];
      end
   end

// control_reg_dma_1_drop_en
//    bitfield description: Enable drop threshold to be used for DMA CH_1.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 1'h0

always @(posedge clk)
   if (!reset_n) begin
      control_reg_dma_1_drop_en <= 1'h0;
   end
   else begin
      if (we_control_reg) begin
         control_reg_dma_1_drop_en <= din[1];
      end
   end

// control_reg_dma_2_drop_en
//    bitfield description: Enable drop threshold to be used for DMA CH_2.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 1'h0

always @(posedge clk)
   if (!reset_n) begin
      control_reg_dma_2_drop_en <= 1'h0;
   end
   else begin
      if (we_control_reg) begin
         control_reg_dma_2_drop_en <= din[2];
      end
   end

// control_reg_dma_3_drop_en
//    bitfield description: Enable drop threshold to be used for DMA CH_3.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 1'h0

always @(posedge clk)
   if (!reset_n) begin
      control_reg_dma_3_drop_en <= 1'h0;
   end
   else begin
      if (we_control_reg) begin
         control_reg_dma_3_drop_en <= din[3];
      end
   end

// control_reg_dma_4_drop_en
//    bitfield description: Enable drop threshold to be used for DMA CH_4.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 1'h0

always @(posedge clk)
   if (!reset_n) begin
      control_reg_dma_4_drop_en <= 1'h0;
   end
   else begin
      if (we_control_reg) begin
         control_reg_dma_4_drop_en <= din[4];
      end
   end

// control_reg_dma_5_drop_en
//    bitfield description: Enable drop threshold to be used for DMA CH_5.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 1'h0

always @(posedge clk)
   if (!reset_n) begin
      control_reg_dma_5_drop_en <= 1'h0;
   end
   else begin
      if (we_control_reg) begin
         control_reg_dma_5_drop_en <= din[5];
      end
   end

// control_reg_dma_6_drop_en
//    bitfield description: Enable drop threshold to be used for DMA CH_6.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 1'h0

always @(posedge clk)
   if (!reset_n) begin
      control_reg_dma_6_drop_en <= 1'h0;
   end
   else begin
      if (we_control_reg) begin
         control_reg_dma_6_drop_en <= din[6];
      end
   end

// control_reg_dma_7_drop_en
//    bitfield description: Enable drop threshold to be used for DMA CH_7.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 1'h0

always @(posedge clk)
   if (!reset_n) begin
      control_reg_dma_7_drop_en <= 1'h0;
   end
   else begin
      if (we_control_reg) begin
         control_reg_dma_7_drop_en <= din[7];
      end
   end

// control_reg_reserved
//    bitfield description: Reserved.
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 24'h000000
//
// No register generated

// -----------------------------------------------------------------------------
// Register dma_0_drop_threshold_reg implementation
// -----------------------------------------------------------------------------

// dma_0_drop_threshold_reg_drop_threshold
//    bitfield description: Drop threshold for DMA CH_0.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 16'h01f0

always @(posedge clk)
   if (!reset_n) begin
      dma_0_drop_threshold_reg_drop_threshold <= 16'h01f0;
   end
   else begin
      if (we_dma_0_drop_threshold_reg[0]) begin
         dma_0_drop_threshold_reg_drop_threshold[7:0] <= din[7:0];
      end
      if (we_dma_0_drop_threshold_reg[1]) begin
         dma_0_drop_threshold_reg_drop_threshold[15:8] <= din[15:8];
      end
   end

// dma_0_drop_threshold_reg_reserved
//    bitfield description: Reserved.
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 16'h0000
//
// No register generated

// -----------------------------------------------------------------------------
// Register dma_1_drop_threshold_reg implementation
// -----------------------------------------------------------------------------

// dma_1_drop_threshold_reg_drop_threshold
//    bitfield description: Drop threshold for DMA CH_1.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 16'h01f0

always @(posedge clk)
   if (!reset_n) begin
      dma_1_drop_threshold_reg_drop_threshold <= 16'h01f0;
   end
   else begin
      if (we_dma_1_drop_threshold_reg[0]) begin
         dma_1_drop_threshold_reg_drop_threshold[7:0] <= din[7:0];
      end
      if (we_dma_1_drop_threshold_reg[1]) begin
         dma_1_drop_threshold_reg_drop_threshold[15:8] <= din[15:8];
      end
   end

// dma_1_drop_threshold_reg_reserved
//    bitfield description: Reserved.
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 16'h0000
//
// No register generated

// -----------------------------------------------------------------------------
// Register dma_2_drop_threshold_reg implementation
// -----------------------------------------------------------------------------

// dma_2_drop_threshold_reg_drop_threshold
//    bitfield description: Drop threshold for DMA CH_2.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 16'h01f0

always @(posedge clk)
   if (!reset_n) begin
      dma_2_drop_threshold_reg_drop_threshold <= 16'h01f0;
   end
   else begin
      if (we_dma_2_drop_threshold_reg[0]) begin
         dma_2_drop_threshold_reg_drop_threshold[7:0] <= din[7:0];
      end
      if (we_dma_2_drop_threshold_reg[1]) begin
         dma_2_drop_threshold_reg_drop_threshold[15:8] <= din[15:8];
      end
   end

// dma_2_drop_threshold_reg_reserved
//    bitfield description: Reserved.
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 16'h0000
//
// No register generated

// -----------------------------------------------------------------------------
// Register dma_3_drop_threshold_reg implementation
// -----------------------------------------------------------------------------

// dma_3_drop_threshold_reg_drop_threshold
//    bitfield description: Drop threshold for DMA CH_3.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 16'h01f0

always @(posedge clk)
   if (!reset_n) begin
      dma_3_drop_threshold_reg_drop_threshold <= 16'h01f0;
   end
   else begin
      if (we_dma_3_drop_threshold_reg[0]) begin
         dma_3_drop_threshold_reg_drop_threshold[7:0] <= din[7:0];
      end
      if (we_dma_3_drop_threshold_reg[1]) begin
         dma_3_drop_threshold_reg_drop_threshold[15:8] <= din[15:8];
      end
   end

// dma_3_drop_threshold_reg_reserved
//    bitfield description: Reserved.
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 16'h0000
//
// No register generated

// -----------------------------------------------------------------------------
// Register dma_4_drop_threshold_reg implementation
// -----------------------------------------------------------------------------

// dma_4_drop_threshold_reg_drop_threshold
//    bitfield description: Drop threshold for DMA CH_4.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 16'h01f0

always @(posedge clk)
   if (!reset_n) begin
      dma_4_drop_threshold_reg_drop_threshold <= 16'h01f0;
   end
   else begin
      if (we_dma_4_drop_threshold_reg[0]) begin
         dma_4_drop_threshold_reg_drop_threshold[7:0] <= din[7:0];
      end
      if (we_dma_4_drop_threshold_reg[1]) begin
         dma_4_drop_threshold_reg_drop_threshold[15:8] <= din[15:8];
      end
   end

// dma_4_drop_threshold_reg_reserved
//    bitfield description: Reserved.
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 16'h0000
//
// No register generated

// -----------------------------------------------------------------------------
// Register dma_5_drop_threshold_reg implementation
// -----------------------------------------------------------------------------

// dma_5_drop_threshold_reg_drop_threshold
//    bitfield description: Drop threshold for DMA CH_5.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 16'h01f0

always @(posedge clk)
   if (!reset_n) begin
      dma_5_drop_threshold_reg_drop_threshold <= 16'h01f0;
   end
   else begin
      if (we_dma_5_drop_threshold_reg[0]) begin
         dma_5_drop_threshold_reg_drop_threshold[7:0] <= din[7:0];
      end
      if (we_dma_5_drop_threshold_reg[1]) begin
         dma_5_drop_threshold_reg_drop_threshold[15:8] <= din[15:8];
      end
   end

// dma_5_drop_threshold_reg_reserved
//    bitfield description: Reserved.
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 16'h0000
//
// No register generated

// -----------------------------------------------------------------------------
// Register dma_6_drop_threshold_reg implementation
// -----------------------------------------------------------------------------

// dma_6_drop_threshold_reg_drop_threshold
//    bitfield description: Drop threshold for DMA CH_6.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 16'h01f0

always @(posedge clk)
   if (!reset_n) begin
      dma_6_drop_threshold_reg_drop_threshold <= 16'h01f0;
   end
   else begin
      if (we_dma_6_drop_threshold_reg[0]) begin
         dma_6_drop_threshold_reg_drop_threshold[7:0] <= din[7:0];
      end
      if (we_dma_6_drop_threshold_reg[1]) begin
         dma_6_drop_threshold_reg_drop_threshold[15:8] <= din[15:8];
      end
   end

// dma_6_drop_threshold_reg_reserved
//    bitfield description: Reserved.
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 16'h0000
//
// No register generated

// -----------------------------------------------------------------------------
// Register dma_7_drop_threshold_reg implementation
// -----------------------------------------------------------------------------

// dma_7_drop_threshold_reg_drop_threshold
//    bitfield description: Drop threshold for DMA CH_7.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 16'h01f0

always @(posedge clk)
   if (!reset_n) begin
      dma_7_drop_threshold_reg_drop_threshold <= 16'h01f0;
   end
   else begin
      if (we_dma_7_drop_threshold_reg[0]) begin
         dma_7_drop_threshold_reg_drop_threshold[7:0] <= din[7:0];
      end
      if (we_dma_7_drop_threshold_reg[1]) begin
         dma_7_drop_threshold_reg_drop_threshold[15:8] <= din[15:8];
      end
   end

// dma_7_drop_threshold_reg_reserved
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
         6'h00: begin
            rdata_comb[31:0] = scratch_reg_scratch[31:0];
         end
         // Register control_reg: control_reg_dma_0_drop_en (RW)
         //                       control_reg_dma_1_drop_en (RW)
         //                       control_reg_dma_2_drop_en (RW)
         //                       control_reg_dma_3_drop_en (RW)
         //                       control_reg_dma_4_drop_en (RW)
         //                       control_reg_dma_5_drop_en (RW)
         //                       control_reg_dma_6_drop_en (RW)
         //                       control_reg_dma_7_drop_en (RW)
         //                       control_reg_reserved (RO)
         6'h04: begin
            rdata_comb[0] = control_reg_dma_0_drop_en;
            rdata_comb[1] = control_reg_dma_1_drop_en;
            rdata_comb[2] = control_reg_dma_2_drop_en;
            rdata_comb[3] = control_reg_dma_3_drop_en;
            rdata_comb[4] = control_reg_dma_4_drop_en;
            rdata_comb[5] = control_reg_dma_5_drop_en;
            rdata_comb[6] = control_reg_dma_6_drop_en;
            rdata_comb[7] = control_reg_dma_7_drop_en;
            rdata_comb[31:8] = 24'h000000;
         end
         // Register dma_0_drop_threshold_reg: dma_0_drop_threshold_reg_drop_threshold (RW)
         //                                    dma_0_drop_threshold_reg_reserved (RO)
         6'h08: begin
            rdata_comb[15:0] = dma_0_drop_threshold_reg_drop_threshold[15:0];
            rdata_comb[31:16] = 16'h0000;
         end
         // Register dma_1_drop_threshold_reg: dma_1_drop_threshold_reg_drop_threshold (RW)
         //                                    dma_1_drop_threshold_reg_reserved (RO)
         6'h0c: begin
            rdata_comb[15:0] = dma_1_drop_threshold_reg_drop_threshold[15:0];
            rdata_comb[31:16] = 16'h0000;
         end
         // Register dma_2_drop_threshold_reg: dma_2_drop_threshold_reg_drop_threshold (RW)
         //                                    dma_2_drop_threshold_reg_reserved (RO)
         6'h10: begin
            rdata_comb[15:0] = dma_2_drop_threshold_reg_drop_threshold[15:0];
            rdata_comb[31:16] = 16'h0000;
         end
         // Register dma_3_drop_threshold_reg: dma_3_drop_threshold_reg_drop_threshold (RW)
         //                                    dma_3_drop_threshold_reg_reserved (RO)
         6'h14: begin
            rdata_comb[15:0] = dma_3_drop_threshold_reg_drop_threshold[15:0];
            rdata_comb[31:16] = 16'h0000;
         end
         // Register dma_4_drop_threshold_reg: dma_4_drop_threshold_reg_drop_threshold (RW)
         //                                    dma_4_drop_threshold_reg_reserved (RO)
         6'h18: begin
            rdata_comb[15:0] = dma_4_drop_threshold_reg_drop_threshold[15:0];
            rdata_comb[31:16] = 16'h0000;
         end
         // Register dma_5_drop_threshold_reg: dma_5_drop_threshold_reg_drop_threshold (RW)
         //                                    dma_5_drop_threshold_reg_reserved (RO)
         6'h1c: begin
            rdata_comb[15:0] = dma_5_drop_threshold_reg_drop_threshold[15:0];
            rdata_comb[31:16] = 16'h0000;
         end
         // Register dma_6_drop_threshold_reg: dma_6_drop_threshold_reg_drop_threshold (RW)
         //                                    dma_6_drop_threshold_reg_reserved (RO)
         6'h20: begin
            rdata_comb[15:0] = dma_6_drop_threshold_reg_drop_threshold[15:0];
            rdata_comb[31:16] = 16'h0000;
         end
         // Register dma_7_drop_threshold_reg: dma_7_drop_threshold_reg_drop_threshold (RW)
         //                                    dma_7_drop_threshold_reg_reserved (RO)
         6'h24: begin
            rdata_comb[15:0] = dma_7_drop_threshold_reg_drop_threshold[15:0];
            rdata_comb[31:16] = 16'h0000;
         end
         default: begin
            rdata_comb = 32'h00000000;
         end
      endcase
   end
end

endmodule