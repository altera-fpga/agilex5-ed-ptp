//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module tx_dbg_csr(

   // dma2iwadj_ch0_stats_reg.transferred_stats
   input wire we_dma2iwadj_ch0_stats_reg_transferred_stats,
   input wire [31:0] dma2iwadj_ch0_stats_reg_transferred_stats_i,
   output reg [31:0] dma2iwadj_ch0_stats_reg_transferred_stats,
   // dma2iwadj_ch1_stats_reg.transferred_stats
   input wire we_dma2iwadj_ch1_stats_reg_transferred_stats,
   input wire [31:0] dma2iwadj_ch1_stats_reg_transferred_stats_i,
   output reg [31:0] dma2iwadj_ch1_stats_reg_transferred_stats,
   // dma2iwadj_ch2_stats_reg.transferred_stats
   input wire we_dma2iwadj_ch2_stats_reg_transferred_stats,
   input wire [31:0] dma2iwadj_ch2_stats_reg_transferred_stats_i,
   output reg [31:0] dma2iwadj_ch2_stats_reg_transferred_stats,
   // iwadj2iarb_ch0_stats_reg.transferred_stats
   input wire we_iwadj2iarb_ch0_stats_reg_transferred_stats,
   input wire [31:0] iwadj2iarb_ch0_stats_reg_transferred_stats_i,
   output reg [31:0] iwadj2iarb_ch0_stats_reg_transferred_stats,
   // iwadj2iarb_ch1_stats_reg.transferred_stats
   input wire we_iwadj2iarb_ch1_stats_reg_transferred_stats,
   input wire [31:0] iwadj2iarb_ch1_stats_reg_transferred_stats_i,
   output reg [31:0] iwadj2iarb_ch1_stats_reg_transferred_stats,
   // iwadj2iarb_ch2_stats_reg.transferred_stats
   input wire we_iwadj2iarb_ch2_stats_reg_transferred_stats,
   input wire [31:0] iwadj2iarb_ch2_stats_reg_transferred_stats_i,
   output reg [31:0] iwadj2iarb_ch2_stats_reg_transferred_stats,
   // user2iarb_stats_reg.transferred_stats
   input wire we_user2iarb_stats_reg_transferred_stats,
   input wire [31:0] user2iarb_stats_reg_transferred_stats_i,
   output reg [31:0] user2iarb_stats_reg_transferred_stats,
   // iarb2hssi_stats_reg.transferred_stats
   input wire we_iarb2hssi_stats_reg_transferred_stats,
   input wire [31:0] iarb2hssi_stats_reg_transferred_stats_i,
   output reg [31:0] iarb2hssi_stats_reg_transferred_stats,

   // Bus interface
   input wire clk,
   input wire reset,
   input wire [31:0] writedata,
   input wire read,
   input wire write,
   input wire [3:0] byteenable,
   output reg [31:0] readdata,
   output reg readdatavalid,
   input wire [4:0] address
);

wire reset_n = !reset;

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
wire [4:0] addr = address[4:0];
wire [31:0] din = writedata[31:0];

// -----------------------------------------------------------------------------
// Write byte enables
// -----------------------------------------------------------------------------

// Register dma2iwadj_ch0_stats_reg
wire [3:0] we_dma2iwadj_ch0_stats_reg = we & (addr[4:0] == 5'h00) ? byteenable[3:0] : {4{1'b0}};
// Register dma2iwadj_ch1_stats_reg
wire [3:0] we_dma2iwadj_ch1_stats_reg = we & (addr[4:0] == 5'h04) ? byteenable[3:0] : {4{1'b0}};
// Register dma2iwadj_ch2_stats_reg
wire [3:0] we_dma2iwadj_ch2_stats_reg = we & (addr[4:0] == 5'h08) ? byteenable[3:0] : {4{1'b0}};
// Register iwadj2iarb_ch0_stats_reg
wire [3:0] we_iwadj2iarb_ch0_stats_reg = we & (addr[4:0] == 5'h0c) ? byteenable[3:0] : {4{1'b0}};
// Register iwadj2iarb_ch1_stats_reg
wire [3:0] we_iwadj2iarb_ch1_stats_reg = we & (addr[4:0] == 5'h10) ? byteenable[3:0] : {4{1'b0}};
// Register iwadj2iarb_ch2_stats_reg
wire [3:0] we_iwadj2iarb_ch2_stats_reg = we & (addr[4:0] == 5'h14) ? byteenable[3:0] : {4{1'b0}};
// Register user2iarb_stats_reg
wire [3:0] we_user2iarb_stats_reg = we & (addr[4:0] == 5'h18) ? byteenable[3:0] : {4{1'b0}};
// Register iarb2hssi_stats_reg
wire [3:0] we_iarb2hssi_stats_reg = we & (addr[4:0] == 5'h1c) ? byteenable[3:0] : {4{1'b0}};

// -----------------------------------------------------------------------------
// Read byte enables
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Register dma2iwadj_ch0_stats_reg implementation
// -----------------------------------------------------------------------------

// dma2iwadj_ch0_stats_reg_transferred_stats
//    bitfield description : Indicates number of packets transferred between the 2 interfaces.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : dma2iwadj_ch0_stats_reg_transferred_stats_i
//    hardware write enable: we_dma2iwadj_ch0_stats_reg_transferred_stats

always @(posedge clk)
   if (!reset_n) begin
      dma2iwadj_ch0_stats_reg_transferred_stats <= 32'h00000000;
   end
   else begin
      if (we_dma2iwadj_ch0_stats_reg[0] || we_dma2iwadj_ch0_stats_reg[1] || we_dma2iwadj_ch0_stats_reg[2] || we_dma2iwadj_ch0_stats_reg[3]) begin
         if (we_dma2iwadj_ch0_stats_reg[0]) begin
            dma2iwadj_ch0_stats_reg_transferred_stats[7:0] <= ~din[7:0] & dma2iwadj_ch0_stats_reg_transferred_stats[7:0];
         end
         if (we_dma2iwadj_ch0_stats_reg[1]) begin
            dma2iwadj_ch0_stats_reg_transferred_stats[15:8] <= ~din[15:8] & dma2iwadj_ch0_stats_reg_transferred_stats[15:8];
         end
         if (we_dma2iwadj_ch0_stats_reg[2]) begin
            dma2iwadj_ch0_stats_reg_transferred_stats[23:16] <= ~din[23:16] & dma2iwadj_ch0_stats_reg_transferred_stats[23:16];
         end
         if (we_dma2iwadj_ch0_stats_reg[3]) begin
            dma2iwadj_ch0_stats_reg_transferred_stats[31:24] <= ~din[31:24] & dma2iwadj_ch0_stats_reg_transferred_stats[31:24];
         end
      end
      else begin
         if (we_dma2iwadj_ch0_stats_reg_transferred_stats) begin
            dma2iwadj_ch0_stats_reg_transferred_stats[31:0] <= dma2iwadj_ch0_stats_reg_transferred_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register dma2iwadj_ch1_stats_reg implementation
// -----------------------------------------------------------------------------

// dma2iwadj_ch1_stats_reg_transferred_stats
//    bitfield description : Indicates number of packets transferred between the 2 interfaces.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : dma2iwadj_ch1_stats_reg_transferred_stats_i
//    hardware write enable: we_dma2iwadj_ch1_stats_reg_transferred_stats

always @(posedge clk)
   if (!reset_n) begin
      dma2iwadj_ch1_stats_reg_transferred_stats <= 32'h00000000;
   end
   else begin
      if (we_dma2iwadj_ch1_stats_reg[0] || we_dma2iwadj_ch1_stats_reg[1] || we_dma2iwadj_ch1_stats_reg[2] || we_dma2iwadj_ch1_stats_reg[3]) begin
         if (we_dma2iwadj_ch1_stats_reg[0]) begin
            dma2iwadj_ch1_stats_reg_transferred_stats[7:0] <= ~din[7:0] & dma2iwadj_ch1_stats_reg_transferred_stats[7:0];
         end
         if (we_dma2iwadj_ch1_stats_reg[1]) begin
            dma2iwadj_ch1_stats_reg_transferred_stats[15:8] <= ~din[15:8] & dma2iwadj_ch1_stats_reg_transferred_stats[15:8];
         end
         if (we_dma2iwadj_ch1_stats_reg[2]) begin
            dma2iwadj_ch1_stats_reg_transferred_stats[23:16] <= ~din[23:16] & dma2iwadj_ch1_stats_reg_transferred_stats[23:16];
         end
         if (we_dma2iwadj_ch1_stats_reg[3]) begin
            dma2iwadj_ch1_stats_reg_transferred_stats[31:24] <= ~din[31:24] & dma2iwadj_ch1_stats_reg_transferred_stats[31:24];
         end
      end
      else begin
         if (we_dma2iwadj_ch1_stats_reg_transferred_stats) begin
            dma2iwadj_ch1_stats_reg_transferred_stats[31:0] <= dma2iwadj_ch1_stats_reg_transferred_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register dma2iwadj_ch2_stats_reg implementation
// -----------------------------------------------------------------------------

// dma2iwadj_ch2_stats_reg_transferred_stats
//    bitfield description : Indicates number of packets transferred between the 2 interfaces.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : dma2iwadj_ch2_stats_reg_transferred_stats_i
//    hardware write enable: we_dma2iwadj_ch2_stats_reg_transferred_stats

always @(posedge clk)
   if (!reset_n) begin
      dma2iwadj_ch2_stats_reg_transferred_stats <= 32'h00000000;
   end
   else begin
      if (we_dma2iwadj_ch2_stats_reg[0] || we_dma2iwadj_ch2_stats_reg[1] || we_dma2iwadj_ch2_stats_reg[2] || we_dma2iwadj_ch2_stats_reg[3]) begin
         if (we_dma2iwadj_ch2_stats_reg[0]) begin
            dma2iwadj_ch2_stats_reg_transferred_stats[7:0] <= ~din[7:0] & dma2iwadj_ch2_stats_reg_transferred_stats[7:0];
         end
         if (we_dma2iwadj_ch2_stats_reg[1]) begin
            dma2iwadj_ch2_stats_reg_transferred_stats[15:8] <= ~din[15:8] & dma2iwadj_ch2_stats_reg_transferred_stats[15:8];
         end
         if (we_dma2iwadj_ch2_stats_reg[2]) begin
            dma2iwadj_ch2_stats_reg_transferred_stats[23:16] <= ~din[23:16] & dma2iwadj_ch2_stats_reg_transferred_stats[23:16];
         end
         if (we_dma2iwadj_ch2_stats_reg[3]) begin
            dma2iwadj_ch2_stats_reg_transferred_stats[31:24] <= ~din[31:24] & dma2iwadj_ch2_stats_reg_transferred_stats[31:24];
         end
      end
      else begin
         if (we_dma2iwadj_ch2_stats_reg_transferred_stats) begin
            dma2iwadj_ch2_stats_reg_transferred_stats[31:0] <= dma2iwadj_ch2_stats_reg_transferred_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register iwadj2iarb_ch0_stats_reg implementation
// -----------------------------------------------------------------------------

// iwadj2iarb_ch0_stats_reg_transferred_stats
//    bitfield description : Indicates number of packets transferred between the 2 interfaces.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : iwadj2iarb_ch0_stats_reg_transferred_stats_i
//    hardware write enable: we_iwadj2iarb_ch0_stats_reg_transferred_stats

always @(posedge clk)
   if (!reset_n) begin
      iwadj2iarb_ch0_stats_reg_transferred_stats <= 32'h00000000;
   end
   else begin
      if (we_iwadj2iarb_ch0_stats_reg[0] || we_iwadj2iarb_ch0_stats_reg[1] || we_iwadj2iarb_ch0_stats_reg[2] || we_iwadj2iarb_ch0_stats_reg[3]) begin
         if (we_iwadj2iarb_ch0_stats_reg[0]) begin
            iwadj2iarb_ch0_stats_reg_transferred_stats[7:0] <= ~din[7:0] & iwadj2iarb_ch0_stats_reg_transferred_stats[7:0];
         end
         if (we_iwadj2iarb_ch0_stats_reg[1]) begin
            iwadj2iarb_ch0_stats_reg_transferred_stats[15:8] <= ~din[15:8] & iwadj2iarb_ch0_stats_reg_transferred_stats[15:8];
         end
         if (we_iwadj2iarb_ch0_stats_reg[2]) begin
            iwadj2iarb_ch0_stats_reg_transferred_stats[23:16] <= ~din[23:16] & iwadj2iarb_ch0_stats_reg_transferred_stats[23:16];
         end
         if (we_iwadj2iarb_ch0_stats_reg[3]) begin
            iwadj2iarb_ch0_stats_reg_transferred_stats[31:24] <= ~din[31:24] & iwadj2iarb_ch0_stats_reg_transferred_stats[31:24];
         end
      end
      else begin
         if (we_iwadj2iarb_ch0_stats_reg_transferred_stats) begin
            iwadj2iarb_ch0_stats_reg_transferred_stats[31:0] <= iwadj2iarb_ch0_stats_reg_transferred_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register iwadj2iarb_ch1_stats_reg implementation
// -----------------------------------------------------------------------------

// iwadj2iarb_ch1_stats_reg_transferred_stats
//    bitfield description : Indicates number of packets transferred between the 2 interfaces.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : iwadj2iarb_ch1_stats_reg_transferred_stats_i
//    hardware write enable: we_iwadj2iarb_ch1_stats_reg_transferred_stats

always @(posedge clk)
   if (!reset_n) begin
      iwadj2iarb_ch1_stats_reg_transferred_stats <= 32'h00000000;
   end
   else begin
      if (we_iwadj2iarb_ch1_stats_reg[0] || we_iwadj2iarb_ch1_stats_reg[1] || we_iwadj2iarb_ch1_stats_reg[2] || we_iwadj2iarb_ch1_stats_reg[3]) begin
         if (we_iwadj2iarb_ch1_stats_reg[0]) begin
            iwadj2iarb_ch1_stats_reg_transferred_stats[7:0] <= ~din[7:0] & iwadj2iarb_ch1_stats_reg_transferred_stats[7:0];
         end
         if (we_iwadj2iarb_ch1_stats_reg[1]) begin
            iwadj2iarb_ch1_stats_reg_transferred_stats[15:8] <= ~din[15:8] & iwadj2iarb_ch1_stats_reg_transferred_stats[15:8];
         end
         if (we_iwadj2iarb_ch1_stats_reg[2]) begin
            iwadj2iarb_ch1_stats_reg_transferred_stats[23:16] <= ~din[23:16] & iwadj2iarb_ch1_stats_reg_transferred_stats[23:16];
         end
         if (we_iwadj2iarb_ch1_stats_reg[3]) begin
            iwadj2iarb_ch1_stats_reg_transferred_stats[31:24] <= ~din[31:24] & iwadj2iarb_ch1_stats_reg_transferred_stats[31:24];
         end
      end
      else begin
         if (we_iwadj2iarb_ch1_stats_reg_transferred_stats) begin
            iwadj2iarb_ch1_stats_reg_transferred_stats[31:0] <= iwadj2iarb_ch1_stats_reg_transferred_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register iwadj2iarb_ch2_stats_reg implementation
// -----------------------------------------------------------------------------

// iwadj2iarb_ch2_stats_reg_transferred_stats
//    bitfield description : Indicates number of packets transferred between the 2 interfaces.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : iwadj2iarb_ch2_stats_reg_transferred_stats_i
//    hardware write enable: we_iwadj2iarb_ch2_stats_reg_transferred_stats

always @(posedge clk)
   if (!reset_n) begin
      iwadj2iarb_ch2_stats_reg_transferred_stats <= 32'h00000000;
   end
   else begin
      if (we_iwadj2iarb_ch2_stats_reg[0] || we_iwadj2iarb_ch2_stats_reg[1] || we_iwadj2iarb_ch2_stats_reg[2] || we_iwadj2iarb_ch2_stats_reg[3]) begin
         if (we_iwadj2iarb_ch2_stats_reg[0]) begin
            iwadj2iarb_ch2_stats_reg_transferred_stats[7:0] <= ~din[7:0] & iwadj2iarb_ch2_stats_reg_transferred_stats[7:0];
         end
         if (we_iwadj2iarb_ch2_stats_reg[1]) begin
            iwadj2iarb_ch2_stats_reg_transferred_stats[15:8] <= ~din[15:8] & iwadj2iarb_ch2_stats_reg_transferred_stats[15:8];
         end
         if (we_iwadj2iarb_ch2_stats_reg[2]) begin
            iwadj2iarb_ch2_stats_reg_transferred_stats[23:16] <= ~din[23:16] & iwadj2iarb_ch2_stats_reg_transferred_stats[23:16];
         end
         if (we_iwadj2iarb_ch2_stats_reg[3]) begin
            iwadj2iarb_ch2_stats_reg_transferred_stats[31:24] <= ~din[31:24] & iwadj2iarb_ch2_stats_reg_transferred_stats[31:24];
         end
      end
      else begin
         if (we_iwadj2iarb_ch2_stats_reg_transferred_stats) begin
            iwadj2iarb_ch2_stats_reg_transferred_stats[31:0] <= iwadj2iarb_ch2_stats_reg_transferred_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register user2iarb_stats_reg implementation
// -----------------------------------------------------------------------------

// user2iarb_stats_reg_transferred_stats
//    bitfield description : Indicates number of packets transferred between the 2 interfaces.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : user2iarb_stats_reg_transferred_stats_i
//    hardware write enable: we_user2iarb_stats_reg_transferred_stats

always @(posedge clk)
   if (!reset_n) begin
      user2iarb_stats_reg_transferred_stats <= 32'h00000000;
   end
   else begin
      if (we_user2iarb_stats_reg[0] || we_user2iarb_stats_reg[1] || we_user2iarb_stats_reg[2] || we_user2iarb_stats_reg[3]) begin
         if (we_user2iarb_stats_reg[0]) begin
            user2iarb_stats_reg_transferred_stats[7:0] <= ~din[7:0] & user2iarb_stats_reg_transferred_stats[7:0];
         end
         if (we_user2iarb_stats_reg[1]) begin
            user2iarb_stats_reg_transferred_stats[15:8] <= ~din[15:8] & user2iarb_stats_reg_transferred_stats[15:8];
         end
         if (we_user2iarb_stats_reg[2]) begin
            user2iarb_stats_reg_transferred_stats[23:16] <= ~din[23:16] & user2iarb_stats_reg_transferred_stats[23:16];
         end
         if (we_user2iarb_stats_reg[3]) begin
            user2iarb_stats_reg_transferred_stats[31:24] <= ~din[31:24] & user2iarb_stats_reg_transferred_stats[31:24];
         end
      end
      else begin
         if (we_user2iarb_stats_reg_transferred_stats) begin
            user2iarb_stats_reg_transferred_stats[31:0] <= user2iarb_stats_reg_transferred_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register iarb2hssi_stats_reg implementation
// -----------------------------------------------------------------------------

// iarb2hssi_stats_reg_transferred_stats
//    bitfield description : Indicates number of packets transferred between the 2 interfaces.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : iarb2hssi_stats_reg_transferred_stats_i
//    hardware write enable: we_iarb2hssi_stats_reg_transferred_stats

always @(posedge clk)
   if (!reset_n) begin
      iarb2hssi_stats_reg_transferred_stats <= 32'h00000000;
   end
   else begin
      if (we_iarb2hssi_stats_reg[0] || we_iarb2hssi_stats_reg[1] || we_iarb2hssi_stats_reg[2] || we_iarb2hssi_stats_reg[3]) begin
         if (we_iarb2hssi_stats_reg[0]) begin
            iarb2hssi_stats_reg_transferred_stats[7:0] <= ~din[7:0] & iarb2hssi_stats_reg_transferred_stats[7:0];
         end
         if (we_iarb2hssi_stats_reg[1]) begin
            iarb2hssi_stats_reg_transferred_stats[15:8] <= ~din[15:8] & iarb2hssi_stats_reg_transferred_stats[15:8];
         end
         if (we_iarb2hssi_stats_reg[2]) begin
            iarb2hssi_stats_reg_transferred_stats[23:16] <= ~din[23:16] & iarb2hssi_stats_reg_transferred_stats[23:16];
         end
         if (we_iarb2hssi_stats_reg[3]) begin
            iarb2hssi_stats_reg_transferred_stats[31:24] <= ~din[31:24] & iarb2hssi_stats_reg_transferred_stats[31:24];
         end
      end
      else begin
         if (we_iarb2hssi_stats_reg_transferred_stats) begin
            iarb2hssi_stats_reg_transferred_stats[31:0] <= iarb2hssi_stats_reg_transferred_stats_i[31:0];
         end
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
         // Register dma2iwadj_ch0_stats_reg: dma2iwadj_ch0_stats_reg_transferred_stats (W1C)
         5'h00: begin
            rdata_comb[31:0] = dma2iwadj_ch0_stats_reg_transferred_stats[31:0];
         end
         // Register dma2iwadj_ch1_stats_reg: dma2iwadj_ch1_stats_reg_transferred_stats (W1C)
         5'h04: begin
            rdata_comb[31:0] = dma2iwadj_ch1_stats_reg_transferred_stats[31:0];
         end
         // Register dma2iwadj_ch2_stats_reg: dma2iwadj_ch2_stats_reg_transferred_stats (W1C)
         5'h08: begin
            rdata_comb[31:0] = dma2iwadj_ch2_stats_reg_transferred_stats[31:0];
         end
         // Register iwadj2iarb_ch0_stats_reg: iwadj2iarb_ch0_stats_reg_transferred_stats (W1C)
         5'h0c: begin
            rdata_comb[31:0] = iwadj2iarb_ch0_stats_reg_transferred_stats[31:0];
         end
         // Register iwadj2iarb_ch1_stats_reg: iwadj2iarb_ch1_stats_reg_transferred_stats (W1C)
         5'h10: begin
            rdata_comb[31:0] = iwadj2iarb_ch1_stats_reg_transferred_stats[31:0];
         end
         // Register iwadj2iarb_ch2_stats_reg: iwadj2iarb_ch2_stats_reg_transferred_stats (W1C)
         5'h14: begin
            rdata_comb[31:0] = iwadj2iarb_ch2_stats_reg_transferred_stats[31:0];
         end
         // Register user2iarb_stats_reg: user2iarb_stats_reg_transferred_stats (W1C)
         5'h18: begin
            rdata_comb[31:0] = user2iarb_stats_reg_transferred_stats[31:0];
         end
         // Register iarb2hssi_stats_reg: iarb2hssi_stats_reg_transferred_stats (W1C)
         5'h1c: begin
            rdata_comb[31:0] = iarb2hssi_stats_reg_transferred_stats[31:0];
         end
         default: begin
            rdata_comb = 32'h00000000;
         end
      endcase
   end
end

endmodule