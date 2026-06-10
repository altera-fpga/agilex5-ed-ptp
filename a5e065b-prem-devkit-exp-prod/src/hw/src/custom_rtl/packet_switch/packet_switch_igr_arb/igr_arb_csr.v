//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module igr_arb_csr(

   // cfg_priority_dma.ch_0
   output reg [3:0] cfg_priority_dma_ch_0,
   // cfg_priority_dma.ch_1
   output reg [3:0] cfg_priority_dma_ch_1,
   // cfg_priority_dma.ch_2
   output reg [3:0] cfg_priority_dma_ch_2,
   // cfg_priority_dma.ch_3
   output reg [3:0] cfg_priority_dma_ch_3,
   // cfg_priority_dma.ch_4
   output reg [3:0] cfg_priority_dma_ch_4,
   // cfg_priority_dma.ch_5
   output reg [3:0] cfg_priority_dma_ch_5,
   // cfg_priority_dma.ch_6
   output reg [3:0] cfg_priority_dma_ch_6,
   // cfg_priority_dma.ch_7
   output reg [3:0] cfg_priority_dma_ch_7,
   // cfg_priority_user.port_0
   output reg [3:0] cfg_priority_user_port_0,
   // cfg_priority_user.port_1
   output reg [3:0] cfg_priority_user_port_1,
   // cfg_priority_user.port_2
   output reg [3:0] cfg_priority_user_port_2,
   // cfg_priority_user.port_3
   output reg [3:0] cfg_priority_user_port_3,
   // cfg_priority_user.port_4
   output reg [3:0] cfg_priority_user_port_4,
   // cfg_priority_user.port_5
   output reg [3:0] cfg_priority_user_port_5,
   // cfg_priority_user.port_6
   output reg [3:0] cfg_priority_user_port_6,
   // cfg_priority_user.port_7
   output reg [3:0] cfg_priority_user_port_7,

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
// Register cfg_priority_dma
wire [3:0] we_cfg_priority_dma = we & (addr[3:0] == 4'h4) ? byteenable[3:0] : {4{1'b0}};
// Register cfg_priority_user
wire [3:0] we_cfg_priority_user = we & (addr[3:0] == 4'h8) ? byteenable[3:0] : {4{1'b0}};

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
// Register cfg_priority_dma implementation
// -----------------------------------------------------------------------------

// cfg_priority_dma_ch_0
//    bitfield description: Configured priority level for DMA channel 0.
//                          // 0: highest priority, d15: lowest priority.This register along with cfg_priority_user register (0x8) configures the ingress arbiter priority levels.
//                          // Values across both registers must have unique priority values.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 4'h0

always @(posedge clk)
   if (!reset_n) begin
      cfg_priority_dma_ch_0 <= 4'h0;
   end
   else begin
      if (we_cfg_priority_dma[0]) begin
         cfg_priority_dma_ch_0[3:0] <= din[3:0];
      end
   end

// cfg_priority_dma_ch_1
//    bitfield description: Configured priority level for DMA channel 1.
//                          // 0: highest priority, d15: lowest priority.This register along with cfg_priority_user register (0x8) configures the ingress arbiter priority levels.
//                          // Values across both registers must have unique priority values.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 4'h2

always @(posedge clk)
   if (!reset_n) begin
      cfg_priority_dma_ch_1 <= 4'h2;
   end
   else begin
      if (we_cfg_priority_dma[0]) begin
         cfg_priority_dma_ch_1[3:0] <= din[7:4];
      end
   end

// cfg_priority_dma_ch_2
//    bitfield description: Configured priority level for DMA channel 2.
//                          // 0: highest priority, d15: lowest priority.This register along with cfg_priority_user register (0x8) configures the ingress arbiter priority levels.
//                          // Values across both registers must have unique priority values.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 4'h3

always @(posedge clk)
   if (!reset_n) begin
      cfg_priority_dma_ch_2 <= 4'h3;
   end
   else begin
      if (we_cfg_priority_dma[1]) begin
         cfg_priority_dma_ch_2[3:0] <= din[11:8];
      end
   end

// cfg_priority_dma_ch_3
//    bitfield description: Configured priority level for DMA channel 3.
//                          // 0: highest priority, d15: lowest priority.This register along with cfg_priority_user register (0x8) configures the ingress arbiter priority levels.
//                          // Values across both registers must have unique priority values.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 4'h4

always @(posedge clk)
   if (!reset_n) begin
      cfg_priority_dma_ch_3 <= 4'h4;
   end
   else begin
      if (we_cfg_priority_dma[1]) begin
         cfg_priority_dma_ch_3[3:0] <= din[15:12];
      end
   end

// cfg_priority_dma_ch_4
//    bitfield description: Configured priority level for DMA channel 4.
//                          // 0: highest priority, d15: lowest priority.This register along with cfg_priority_user register (0x8) configures the ingress arbiter priority levels.
//                          // Values across both registers must have unique priority values.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 4'h5

always @(posedge clk)
   if (!reset_n) begin
      cfg_priority_dma_ch_4 <= 4'h5;
   end
   else begin
      if (we_cfg_priority_dma[2]) begin
         cfg_priority_dma_ch_4[3:0] <= din[19:16];
      end
   end

// cfg_priority_dma_ch_5
//    bitfield description: Configured priority level for DMA channel 5.
//                          // 0: highest priority, d15: lowest priority.This register along with cfg_priority_user register (0x8) configures the ingress arbiter priority levels.
//                          // Values across both registers must have unique priority values.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 4'h6

always @(posedge clk)
   if (!reset_n) begin
      cfg_priority_dma_ch_5 <= 4'h6;
   end
   else begin
      if (we_cfg_priority_dma[2]) begin
         cfg_priority_dma_ch_5[3:0] <= din[23:20];
      end
   end

// cfg_priority_dma_ch_6
//    bitfield description: Configured priority level for DMA channel 6.
//                          // 0: highest priority, d15: lowest priority.This register along with cfg_priority_user register (0x8) configures the ingress arbiter priority levels.
//                          // Values across both registers must have unique priority values.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 4'h7

always @(posedge clk)
   if (!reset_n) begin
      cfg_priority_dma_ch_6 <= 4'h7;
   end
   else begin
      if (we_cfg_priority_dma[3]) begin
         cfg_priority_dma_ch_6[3:0] <= din[27:24];
      end
   end

// cfg_priority_dma_ch_7
//    bitfield description: Configured priority level for DMA channel 7.
//                          // 0: highest priority, d15: lowest priority.This register along with cfg_priority_user register (0x8) configures the ingress arbiter priority levels.
//                          // Values across both registers must have unique priority values.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 4'h8

always @(posedge clk)
   if (!reset_n) begin
      cfg_priority_dma_ch_7 <= 4'h8;
   end
   else begin
      if (we_cfg_priority_dma[3]) begin
         cfg_priority_dma_ch_7[3:0] <= din[31:28];
      end
   end

// -----------------------------------------------------------------------------
// Register cfg_priority_user implementation
// -----------------------------------------------------------------------------

// cfg_priority_user_port_0
//    bitfield description: Configured priority level for User_0 port.
//                          // 0: highest priority, d15: lowest priority.This register along with cfg_priority_dma register (0x4) configures the ingress arbiter priority levels.
//                          // Values across both registers must have unique priority values.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 4'h1

always @(posedge clk)
   if (!reset_n) begin
      cfg_priority_user_port_0 <= 4'h1;
   end
   else begin
      if (we_cfg_priority_user[0]) begin
         cfg_priority_user_port_0[3:0] <= din[3:0];
      end
   end

// cfg_priority_user_port_1
//    bitfield description: Configured priority level for User_1 port.
//                          // 0: highest priority, d15: lowest priority.This register along with cfg_priority_dma register (0x4) configures the ingress arbiter priority levels.
//                          // Values across both registers must have unique priority values.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 4'h9

always @(posedge clk)
   if (!reset_n) begin
      cfg_priority_user_port_1 <= 4'h9;
   end
   else begin
      if (we_cfg_priority_user[0]) begin
         cfg_priority_user_port_1[3:0] <= din[7:4];
      end
   end

// cfg_priority_user_port_2
//    bitfield description: Configured priority level for User_2 port.
//                          // 0: highest priority, d15: lowest priority.This register along with cfg_priority_dma register (0x4) configures the ingress arbiter priority levels.
//                          // Values across both registers must have unique priority values.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 4'ha

always @(posedge clk)
   if (!reset_n) begin
      cfg_priority_user_port_2 <= 4'ha;
   end
   else begin
      if (we_cfg_priority_user[1]) begin
         cfg_priority_user_port_2[3:0] <= din[11:8];
      end
   end

// cfg_priority_user_port_3
//    bitfield description: Configured priority level for User_3 port.
//                          // 0: highest priority, d15: lowest priority.This register along with cfg_priority_dma register (0x4) configures the ingress arbiter priority levels.
//                          // Values across both registers must have unique priority values.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 4'hb

always @(posedge clk)
   if (!reset_n) begin
      cfg_priority_user_port_3 <= 4'hb;
   end
   else begin
      if (we_cfg_priority_user[1]) begin
         cfg_priority_user_port_3[3:0] <= din[15:12];
      end
   end

// cfg_priority_user_port_4
//    bitfield description: Configured priority level for User_4 port.
//                          // 0: highest priority, d15: lowest priority.This register along with cfg_priority_dma register (0x4) configures the ingress arbiter priority levels.
//                          // Values across both registers must have unique priority values.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 4'hc

always @(posedge clk)
   if (!reset_n) begin
      cfg_priority_user_port_4 <= 4'hc;
   end
   else begin
      if (we_cfg_priority_user[2]) begin
         cfg_priority_user_port_4[3:0] <= din[19:16];
      end
   end

// cfg_priority_user_port_5
//    bitfield description: Configured priority level for User_5 port.
//                          // 0: highest priority, d15: lowest priority.This register along with cfg_priority_dma register (0x4) configures the ingress arbiter priority levels.
//                          // Values across both registers must have unique priority values.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 4'hd

always @(posedge clk)
   if (!reset_n) begin
      cfg_priority_user_port_5 <= 4'hd;
   end
   else begin
      if (we_cfg_priority_user[2]) begin
         cfg_priority_user_port_5[3:0] <= din[23:20];
      end
   end

// cfg_priority_user_port_6
//    bitfield description: Configured priority level for User_6 port.
//                          // 0: highest priority, d15: lowest priority.This register along with cfg_priority_dma register (0x4) configures the ingress arbiter priority levels.
//                          // Values across both registers must have unique priority values.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 4'he

always @(posedge clk)
   if (!reset_n) begin
      cfg_priority_user_port_6 <= 4'he;
   end
   else begin
      if (we_cfg_priority_user[3]) begin
         cfg_priority_user_port_6[3:0] <= din[27:24];
      end
   end

// cfg_priority_user_port_7
//    bitfield description: Configured priority level for User_7 port.
//                          // 0: highest priority, d15: lowest priority.This register along with cfg_priority_dma register (0x4) configures the ingress arbiter priority levels.
//                          // Values across both registers must have unique priority values.
//    customType          : RW
//    hwAccess            : RO
//    reset value         : 4'hf

always @(posedge clk)
   if (!reset_n) begin
      cfg_priority_user_port_7 <= 4'hf;
   end
   else begin
      if (we_cfg_priority_user[3]) begin
         cfg_priority_user_port_7[3:0] <= din[31:28];
      end
   end

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
         // Register cfg_priority_dma: cfg_priority_dma_ch_0 (RW)
         //                            cfg_priority_dma_ch_1 (RW)
         //                            cfg_priority_dma_ch_2 (RW)
         //                            cfg_priority_dma_ch_3 (RW)
         //                            cfg_priority_dma_ch_4 (RW)
         //                            cfg_priority_dma_ch_5 (RW)
         //                            cfg_priority_dma_ch_6 (RW)
         //                            cfg_priority_dma_ch_7 (RW)
         4'h4: begin
            rdata_comb[3:0] = cfg_priority_dma_ch_0[3:0];
            rdata_comb[7:4] = cfg_priority_dma_ch_1[3:0];
            rdata_comb[11:8] = cfg_priority_dma_ch_2[3:0];
            rdata_comb[15:12] = cfg_priority_dma_ch_3[3:0];
            rdata_comb[19:16] = cfg_priority_dma_ch_4[3:0];
            rdata_comb[23:20] = cfg_priority_dma_ch_5[3:0];
            rdata_comb[27:24] = cfg_priority_dma_ch_6[3:0];
            rdata_comb[31:28] = cfg_priority_dma_ch_7[3:0];
         end
         // Register cfg_priority_user: cfg_priority_user_port_0 (RW)
         //                             cfg_priority_user_port_1 (RW)
         //                             cfg_priority_user_port_2 (RW)
         //                             cfg_priority_user_port_3 (RW)
         //                             cfg_priority_user_port_4 (RW)
         //                             cfg_priority_user_port_5 (RW)
         //                             cfg_priority_user_port_6 (RW)
         //                             cfg_priority_user_port_7 (RW)
         4'h8: begin
            rdata_comb[3:0] = cfg_priority_user_port_0[3:0];
            rdata_comb[7:4] = cfg_priority_user_port_1[3:0];
            rdata_comb[11:8] = cfg_priority_user_port_2[3:0];
            rdata_comb[15:12] = cfg_priority_user_port_3[3:0];
            rdata_comb[19:16] = cfg_priority_user_port_4[3:0];
            rdata_comb[23:20] = cfg_priority_user_port_5[3:0];
            rdata_comb[27:24] = cfg_priority_user_port_6[3:0];
            rdata_comb[31:28] = cfg_priority_user_port_7[3:0];
         end
         default: begin
            rdata_comb = 32'h00000000;
         end
      endcase
   end
end

endmodule