//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module rx_dbg_csr(

   // hssi2iwadj_stats_reg.transferred_stats
   input wire we_hssi2iwadj_stats_reg_transferred_stats,
   input wire [31:0] hssi2iwadj_stats_reg_transferred_stats_i,
   output reg [31:0] hssi2iwadj_stats_reg_transferred_stats,
   // iwadj2pars_stats_reg.transferred_stats
   input wire we_iwadj2pars_stats_reg_transferred_stats,
   input wire [31:0] iwadj2pars_stats_reg_transferred_stats_i,
   output reg [31:0] iwadj2pars_stats_reg_transferred_stats,
   // pars2lkup_stats_reg.transferred_stats
   input wire we_pars2lkup_stats_reg_transferred_stats,
   input wire [31:0] pars2lkup_stats_reg_transferred_stats_i,
   output reg [31:0] pars2lkup_stats_reg_transferred_stats,
   // lkup_drop_stats_reg.dropped_stats
   input wire we_lkup_drop_stats_reg_dropped_stats,
   input wire [31:0] lkup_drop_stats_reg_dropped_stats_i,
   output reg [31:0] lkup_drop_stats_reg_dropped_stats,
   // lkup2ewadj_user_stats_reg.transferred_stats
   input wire we_lkup2ewadj_user_stats_reg_transferred_stats,
   input wire [31:0] lkup2ewadj_user_stats_reg_transferred_stats_i,
   output reg [31:0] lkup2ewadj_user_stats_reg_transferred_stats,
   // ewadj2user_stats_reg.transferred_stats
   input wire we_ewadj2user_stats_reg_transferred_stats,
   input wire [31:0] ewadj2user_stats_reg_transferred_stats_i,
   output reg [31:0] ewadj2user_stats_reg_transferred_stats,
   // ewadj_user_drop_stats_reg.dropped_stats
   input wire we_ewadj_user_drop_stats_reg_dropped_stats,
   input wire [31:0] ewadj_user_drop_stats_reg_dropped_stats_i,
   output reg [31:0] ewadj_user_drop_stats_reg_dropped_stats,
   // lkup2ewadj_dma_stats_reg.transferred_stats
   input wire we_lkup2ewadj_dma_stats_reg_transferred_stats,
   input wire [31:0] lkup2ewadj_dma_stats_reg_transferred_stats_i,
   output reg [31:0] lkup2ewadj_dma_stats_reg_transferred_stats,
   // ewadj2dmux_dma_stats_reg.transferred_stats
   input wire we_ewadj2dmux_dma_stats_reg_transferred_stats,
   input wire [31:0] ewadj2dmux_dma_stats_reg_transferred_stats_i,
   output reg [31:0] ewadj2dmux_dma_stats_reg_transferred_stats,
   // dmux_dma_0_drop_stats_reg.dropped_stats
   input wire we_dmux_dma_0_drop_stats_reg_dropped_stats,
   input wire [31:0] dmux_dma_0_drop_stats_reg_dropped_stats_i,
   output reg [31:0] dmux_dma_0_drop_stats_reg_dropped_stats,
   // dmux_dma_1_drop_stats_reg.dropped_stats
   input wire we_dmux_dma_1_drop_stats_reg_dropped_stats,
   input wire [31:0] dmux_dma_1_drop_stats_reg_dropped_stats_i,
   output reg [31:0] dmux_dma_1_drop_stats_reg_dropped_stats,
   // dmux_dma_2_drop_stats_reg.dropped_stats
   input wire we_dmux_dma_2_drop_stats_reg_dropped_stats,
   input wire [31:0] dmux_dma_2_drop_stats_reg_dropped_stats_i,
   output reg [31:0] dmux_dma_2_drop_stats_reg_dropped_stats,
   // dmux2dma_0_stats_reg.transferred_stats
   input wire we_dmux2dma_0_stats_reg_transferred_stats,
   input wire [31:0] dmux2dma_0_stats_reg_transferred_stats_i,
   output reg [31:0] dmux2dma_0_stats_reg_transferred_stats,
   // dmux2dma_1_stats_reg.transferred_stats
   input wire we_dmux2dma_1_stats_reg_transferred_stats,
   input wire [31:0] dmux2dma_1_stats_reg_transferred_stats_i,
   output reg [31:0] dmux2dma_1_stats_reg_transferred_stats,
   // dmux2dma_2_stats_reg.transferred_stats
   input wire we_dmux2dma_2_stats_reg_transferred_stats,
   input wire [31:0] dmux2dma_2_stats_reg_transferred_stats_i,
   output reg [31:0] dmux2dma_2_stats_reg_transferred_stats,
   // rx_iwadj_drop_stats_reg.dropped_stats
   input wire we_rx_iwadj_drop_stats_reg_dropped_stats,
   input wire [31:0] rx_iwadj_drop_stats_reg_dropped_stats_i,
   output reg [31:0] rx_iwadj_drop_stats_reg_dropped_stats,

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

// Register hssi2iwadj_stats_reg
wire [3:0] we_hssi2iwadj_stats_reg = we & (addr[5:0] == 6'h00) ? byteenable[3:0] : {4{1'b0}};
// Register iwadj2pars_stats_reg
wire [3:0] we_iwadj2pars_stats_reg = we & (addr[5:0] == 6'h04) ? byteenable[3:0] : {4{1'b0}};
// Register pars2lkup_stats_reg
wire [3:0] we_pars2lkup_stats_reg = we & (addr[5:0] == 6'h08) ? byteenable[3:0] : {4{1'b0}};
// Register lkup_drop_stats_reg
wire [3:0] we_lkup_drop_stats_reg = we & (addr[5:0] == 6'h0c) ? byteenable[3:0] : {4{1'b0}};
// Register lkup2ewadj_user_stats_reg
wire [3:0] we_lkup2ewadj_user_stats_reg = we & (addr[5:0] == 6'h10) ? byteenable[3:0] : {4{1'b0}};
// Register ewadj2user_stats_reg
wire [3:0] we_ewadj2user_stats_reg = we & (addr[5:0] == 6'h14) ? byteenable[3:0] : {4{1'b0}};
// Register ewadj_user_drop_stats_reg
wire [3:0] we_ewadj_user_drop_stats_reg = we & (addr[5:0] == 6'h18) ? byteenable[3:0] : {4{1'b0}};
// Register lkup2ewadj_dma_stats_reg
wire [3:0] we_lkup2ewadj_dma_stats_reg = we & (addr[5:0] == 6'h1c) ? byteenable[3:0] : {4{1'b0}};
// Register ewadj2dmux_dma_stats_reg
wire [3:0] we_ewadj2dmux_dma_stats_reg = we & (addr[5:0] == 6'h20) ? byteenable[3:0] : {4{1'b0}};
// Register dmux_dma_0_drop_stats_reg
wire [3:0] we_dmux_dma_0_drop_stats_reg = we & (addr[5:0] == 6'h24) ? byteenable[3:0] : {4{1'b0}};
// Register dmux_dma_1_drop_stats_reg
wire [3:0] we_dmux_dma_1_drop_stats_reg = we & (addr[5:0] == 6'h28) ? byteenable[3:0] : {4{1'b0}};
// Register dmux_dma_2_drop_stats_reg
wire [3:0] we_dmux_dma_2_drop_stats_reg = we & (addr[5:0] == 6'h2c) ? byteenable[3:0] : {4{1'b0}};
// Register dmux2dma_0_stats_reg
wire [3:0] we_dmux2dma_0_stats_reg = we & (addr[5:0] == 6'h30) ? byteenable[3:0] : {4{1'b0}};
// Register dmux2dma_1_stats_reg
wire [3:0] we_dmux2dma_1_stats_reg = we & (addr[5:0] == 6'h34) ? byteenable[3:0] : {4{1'b0}};
// Register dmux2dma_2_stats_reg
wire [3:0] we_dmux2dma_2_stats_reg = we & (addr[5:0] == 6'h38) ? byteenable[3:0] : {4{1'b0}};
// Register rx_iwadj_drop_stats_reg
wire [3:0] we_rx_iwadj_drop_stats_reg = we & (addr[5:0] == 6'h3c) ? byteenable[3:0] : {4{1'b0}};

// -----------------------------------------------------------------------------
// Read byte enables
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Register hssi2iwadj_stats_reg implementation
// -----------------------------------------------------------------------------

// hssi2iwadj_stats_reg_transferred_stats
//    bitfield description : Indicates number of packets transferred between the 2 interfaces.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : hssi2iwadj_stats_reg_transferred_stats_i
//    hardware write enable: we_hssi2iwadj_stats_reg_transferred_stats

always @(posedge clk)
   if (!reset_n) begin
      hssi2iwadj_stats_reg_transferred_stats <= 32'h00000000;
   end
   else begin
      if (we_hssi2iwadj_stats_reg[0] || we_hssi2iwadj_stats_reg[1] || we_hssi2iwadj_stats_reg[2] || we_hssi2iwadj_stats_reg[3]) begin
         if (we_hssi2iwadj_stats_reg[0]) begin
            hssi2iwadj_stats_reg_transferred_stats[7:0] <= ~din[7:0] & hssi2iwadj_stats_reg_transferred_stats[7:0];
         end
         if (we_hssi2iwadj_stats_reg[1]) begin
            hssi2iwadj_stats_reg_transferred_stats[15:8] <= ~din[15:8] & hssi2iwadj_stats_reg_transferred_stats[15:8];
         end
         if (we_hssi2iwadj_stats_reg[2]) begin
            hssi2iwadj_stats_reg_transferred_stats[23:16] <= ~din[23:16] & hssi2iwadj_stats_reg_transferred_stats[23:16];
         end
         if (we_hssi2iwadj_stats_reg[3]) begin
            hssi2iwadj_stats_reg_transferred_stats[31:24] <= ~din[31:24] & hssi2iwadj_stats_reg_transferred_stats[31:24];
         end
      end
      else begin
         if (we_hssi2iwadj_stats_reg_transferred_stats) begin
            hssi2iwadj_stats_reg_transferred_stats[31:0] <= hssi2iwadj_stats_reg_transferred_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register iwadj2pars_stats_reg implementation
// -----------------------------------------------------------------------------

// iwadj2pars_stats_reg_transferred_stats
//    bitfield description : Indicates number of packets transferred between the 2 interfaces.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : iwadj2pars_stats_reg_transferred_stats_i
//    hardware write enable: we_iwadj2pars_stats_reg_transferred_stats

always @(posedge clk)
   if (!reset_n) begin
      iwadj2pars_stats_reg_transferred_stats <= 32'h00000000;
   end
   else begin
      if (we_iwadj2pars_stats_reg[0] || we_iwadj2pars_stats_reg[1] || we_iwadj2pars_stats_reg[2] || we_iwadj2pars_stats_reg[3]) begin
         if (we_iwadj2pars_stats_reg[0]) begin
            iwadj2pars_stats_reg_transferred_stats[7:0] <= ~din[7:0] & iwadj2pars_stats_reg_transferred_stats[7:0];
         end
         if (we_iwadj2pars_stats_reg[1]) begin
            iwadj2pars_stats_reg_transferred_stats[15:8] <= ~din[15:8] & iwadj2pars_stats_reg_transferred_stats[15:8];
         end
         if (we_iwadj2pars_stats_reg[2]) begin
            iwadj2pars_stats_reg_transferred_stats[23:16] <= ~din[23:16] & iwadj2pars_stats_reg_transferred_stats[23:16];
         end
         if (we_iwadj2pars_stats_reg[3]) begin
            iwadj2pars_stats_reg_transferred_stats[31:24] <= ~din[31:24] & iwadj2pars_stats_reg_transferred_stats[31:24];
         end
      end
      else begin
         if (we_iwadj2pars_stats_reg_transferred_stats) begin
            iwadj2pars_stats_reg_transferred_stats[31:0] <= iwadj2pars_stats_reg_transferred_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register pars2lkup_stats_reg implementation
// -----------------------------------------------------------------------------

// pars2lkup_stats_reg_transferred_stats
//    bitfield description : Indicates number of packets transferred between the 2 interfaces.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : pars2lkup_stats_reg_transferred_stats_i
//    hardware write enable: we_pars2lkup_stats_reg_transferred_stats

always @(posedge clk)
   if (!reset_n) begin
      pars2lkup_stats_reg_transferred_stats <= 32'h00000000;
   end
   else begin
      if (we_pars2lkup_stats_reg[0] || we_pars2lkup_stats_reg[1] || we_pars2lkup_stats_reg[2] || we_pars2lkup_stats_reg[3]) begin
         if (we_pars2lkup_stats_reg[0]) begin
            pars2lkup_stats_reg_transferred_stats[7:0] <= ~din[7:0] & pars2lkup_stats_reg_transferred_stats[7:0];
         end
         if (we_pars2lkup_stats_reg[1]) begin
            pars2lkup_stats_reg_transferred_stats[15:8] <= ~din[15:8] & pars2lkup_stats_reg_transferred_stats[15:8];
         end
         if (we_pars2lkup_stats_reg[2]) begin
            pars2lkup_stats_reg_transferred_stats[23:16] <= ~din[23:16] & pars2lkup_stats_reg_transferred_stats[23:16];
         end
         if (we_pars2lkup_stats_reg[3]) begin
            pars2lkup_stats_reg_transferred_stats[31:24] <= ~din[31:24] & pars2lkup_stats_reg_transferred_stats[31:24];
         end
      end
      else begin
         if (we_pars2lkup_stats_reg_transferred_stats) begin
            pars2lkup_stats_reg_transferred_stats[31:0] <= pars2lkup_stats_reg_transferred_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register lkup_drop_stats_reg implementation
// -----------------------------------------------------------------------------

// lkup_drop_stats_reg_dropped_stats
//    bitfield description : Indicates number of packets dropped.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : lkup_drop_stats_reg_dropped_stats_i
//    hardware write enable: we_lkup_drop_stats_reg_dropped_stats

always @(posedge clk)
   if (!reset_n) begin
      lkup_drop_stats_reg_dropped_stats <= 32'h00000000;
   end
   else begin
      if (we_lkup_drop_stats_reg[0] || we_lkup_drop_stats_reg[1] || we_lkup_drop_stats_reg[2] || we_lkup_drop_stats_reg[3]) begin
         if (we_lkup_drop_stats_reg[0]) begin
            lkup_drop_stats_reg_dropped_stats[7:0] <= ~din[7:0] & lkup_drop_stats_reg_dropped_stats[7:0];
         end
         if (we_lkup_drop_stats_reg[1]) begin
            lkup_drop_stats_reg_dropped_stats[15:8] <= ~din[15:8] & lkup_drop_stats_reg_dropped_stats[15:8];
         end
         if (we_lkup_drop_stats_reg[2]) begin
            lkup_drop_stats_reg_dropped_stats[23:16] <= ~din[23:16] & lkup_drop_stats_reg_dropped_stats[23:16];
         end
         if (we_lkup_drop_stats_reg[3]) begin
            lkup_drop_stats_reg_dropped_stats[31:24] <= ~din[31:24] & lkup_drop_stats_reg_dropped_stats[31:24];
         end
      end
      else begin
         if (we_lkup_drop_stats_reg_dropped_stats) begin
            lkup_drop_stats_reg_dropped_stats[31:0] <= lkup_drop_stats_reg_dropped_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register lkup2ewadj_user_stats_reg implementation
// -----------------------------------------------------------------------------

// lkup2ewadj_user_stats_reg_transferred_stats
//    bitfield description : Indicates number of packets transferred between the 2 interfaces.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : lkup2ewadj_user_stats_reg_transferred_stats_i
//    hardware write enable: we_lkup2ewadj_user_stats_reg_transferred_stats

always @(posedge clk)
   if (!reset_n) begin
      lkup2ewadj_user_stats_reg_transferred_stats <= 32'h00000000;
   end
   else begin
      if (we_lkup2ewadj_user_stats_reg[0] || we_lkup2ewadj_user_stats_reg[1] || we_lkup2ewadj_user_stats_reg[2] || we_lkup2ewadj_user_stats_reg[3]) begin
         if (we_lkup2ewadj_user_stats_reg[0]) begin
            lkup2ewadj_user_stats_reg_transferred_stats[7:0] <= ~din[7:0] & lkup2ewadj_user_stats_reg_transferred_stats[7:0];
         end
         if (we_lkup2ewadj_user_stats_reg[1]) begin
            lkup2ewadj_user_stats_reg_transferred_stats[15:8] <= ~din[15:8] & lkup2ewadj_user_stats_reg_transferred_stats[15:8];
         end
         if (we_lkup2ewadj_user_stats_reg[2]) begin
            lkup2ewadj_user_stats_reg_transferred_stats[23:16] <= ~din[23:16] & lkup2ewadj_user_stats_reg_transferred_stats[23:16];
         end
         if (we_lkup2ewadj_user_stats_reg[3]) begin
            lkup2ewadj_user_stats_reg_transferred_stats[31:24] <= ~din[31:24] & lkup2ewadj_user_stats_reg_transferred_stats[31:24];
         end
      end
      else begin
         if (we_lkup2ewadj_user_stats_reg_transferred_stats) begin
            lkup2ewadj_user_stats_reg_transferred_stats[31:0] <= lkup2ewadj_user_stats_reg_transferred_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register ewadj2user_stats_reg implementation
// -----------------------------------------------------------------------------

// ewadj2user_stats_reg_transferred_stats
//    bitfield description : Indicates number of packets transferred between the 2 interfaces.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : ewadj2user_stats_reg_transferred_stats_i
//    hardware write enable: we_ewadj2user_stats_reg_transferred_stats

always @(posedge clk)
   if (!reset_n) begin
      ewadj2user_stats_reg_transferred_stats <= 32'h00000000;
   end
   else begin
      if (we_ewadj2user_stats_reg[0] || we_ewadj2user_stats_reg[1] || we_ewadj2user_stats_reg[2] || we_ewadj2user_stats_reg[3]) begin
         if (we_ewadj2user_stats_reg[0]) begin
            ewadj2user_stats_reg_transferred_stats[7:0] <= ~din[7:0] & ewadj2user_stats_reg_transferred_stats[7:0];
         end
         if (we_ewadj2user_stats_reg[1]) begin
            ewadj2user_stats_reg_transferred_stats[15:8] <= ~din[15:8] & ewadj2user_stats_reg_transferred_stats[15:8];
         end
         if (we_ewadj2user_stats_reg[2]) begin
            ewadj2user_stats_reg_transferred_stats[23:16] <= ~din[23:16] & ewadj2user_stats_reg_transferred_stats[23:16];
         end
         if (we_ewadj2user_stats_reg[3]) begin
            ewadj2user_stats_reg_transferred_stats[31:24] <= ~din[31:24] & ewadj2user_stats_reg_transferred_stats[31:24];
         end
      end
      else begin
         if (we_ewadj2user_stats_reg_transferred_stats) begin
            ewadj2user_stats_reg_transferred_stats[31:0] <= ewadj2user_stats_reg_transferred_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register ewadj_user_drop_stats_reg implementation
// -----------------------------------------------------------------------------

// ewadj_user_drop_stats_reg_dropped_stats
//    bitfield description : Indicates number of packets dropped.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : ewadj_user_drop_stats_reg_dropped_stats_i
//    hardware write enable: we_ewadj_user_drop_stats_reg_dropped_stats

always @(posedge clk)
   if (!reset_n) begin
      ewadj_user_drop_stats_reg_dropped_stats <= 32'h00000000;
   end
   else begin
      if (we_ewadj_user_drop_stats_reg[0] || we_ewadj_user_drop_stats_reg[1] || we_ewadj_user_drop_stats_reg[2] || we_ewadj_user_drop_stats_reg[3]) begin
         if (we_ewadj_user_drop_stats_reg[0]) begin
            ewadj_user_drop_stats_reg_dropped_stats[7:0] <= ~din[7:0] & ewadj_user_drop_stats_reg_dropped_stats[7:0];
         end
         if (we_ewadj_user_drop_stats_reg[1]) begin
            ewadj_user_drop_stats_reg_dropped_stats[15:8] <= ~din[15:8] & ewadj_user_drop_stats_reg_dropped_stats[15:8];
         end
         if (we_ewadj_user_drop_stats_reg[2]) begin
            ewadj_user_drop_stats_reg_dropped_stats[23:16] <= ~din[23:16] & ewadj_user_drop_stats_reg_dropped_stats[23:16];
         end
         if (we_ewadj_user_drop_stats_reg[3]) begin
            ewadj_user_drop_stats_reg_dropped_stats[31:24] <= ~din[31:24] & ewadj_user_drop_stats_reg_dropped_stats[31:24];
         end
      end
      else begin
         if (we_ewadj_user_drop_stats_reg_dropped_stats) begin
            ewadj_user_drop_stats_reg_dropped_stats[31:0] <= ewadj_user_drop_stats_reg_dropped_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register lkup2ewadj_dma_stats_reg implementation
// -----------------------------------------------------------------------------

// lkup2ewadj_dma_stats_reg_transferred_stats
//    bitfield description : Indicates number of packets transferred between the 2 interfaces.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : lkup2ewadj_dma_stats_reg_transferred_stats_i
//    hardware write enable: we_lkup2ewadj_dma_stats_reg_transferred_stats

always @(posedge clk)
   if (!reset_n) begin
      lkup2ewadj_dma_stats_reg_transferred_stats <= 32'h00000000;
   end
   else begin
      if (we_lkup2ewadj_dma_stats_reg[0] || we_lkup2ewadj_dma_stats_reg[1] || we_lkup2ewadj_dma_stats_reg[2] || we_lkup2ewadj_dma_stats_reg[3]) begin
         if (we_lkup2ewadj_dma_stats_reg[0]) begin
            lkup2ewadj_dma_stats_reg_transferred_stats[7:0] <= ~din[7:0] & lkup2ewadj_dma_stats_reg_transferred_stats[7:0];
         end
         if (we_lkup2ewadj_dma_stats_reg[1]) begin
            lkup2ewadj_dma_stats_reg_transferred_stats[15:8] <= ~din[15:8] & lkup2ewadj_dma_stats_reg_transferred_stats[15:8];
         end
         if (we_lkup2ewadj_dma_stats_reg[2]) begin
            lkup2ewadj_dma_stats_reg_transferred_stats[23:16] <= ~din[23:16] & lkup2ewadj_dma_stats_reg_transferred_stats[23:16];
         end
         if (we_lkup2ewadj_dma_stats_reg[3]) begin
            lkup2ewadj_dma_stats_reg_transferred_stats[31:24] <= ~din[31:24] & lkup2ewadj_dma_stats_reg_transferred_stats[31:24];
         end
      end
      else begin
         if (we_lkup2ewadj_dma_stats_reg_transferred_stats) begin
            lkup2ewadj_dma_stats_reg_transferred_stats[31:0] <= lkup2ewadj_dma_stats_reg_transferred_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register ewadj2dmux_dma_stats_reg implementation
// -----------------------------------------------------------------------------

// ewadj2dmux_dma_stats_reg_transferred_stats
//    bitfield description : Indicates number of packets transferred between the 2 interfaces.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : ewadj2dmux_dma_stats_reg_transferred_stats_i
//    hardware write enable: we_ewadj2dmux_dma_stats_reg_transferred_stats

always @(posedge clk)
   if (!reset_n) begin
      ewadj2dmux_dma_stats_reg_transferred_stats <= 32'h00000000;
   end
   else begin
      if (we_ewadj2dmux_dma_stats_reg[0] || we_ewadj2dmux_dma_stats_reg[1] || we_ewadj2dmux_dma_stats_reg[2] || we_ewadj2dmux_dma_stats_reg[3]) begin
         if (we_ewadj2dmux_dma_stats_reg[0]) begin
            ewadj2dmux_dma_stats_reg_transferred_stats[7:0] <= ~din[7:0] & ewadj2dmux_dma_stats_reg_transferred_stats[7:0];
         end
         if (we_ewadj2dmux_dma_stats_reg[1]) begin
            ewadj2dmux_dma_stats_reg_transferred_stats[15:8] <= ~din[15:8] & ewadj2dmux_dma_stats_reg_transferred_stats[15:8];
         end
         if (we_ewadj2dmux_dma_stats_reg[2]) begin
            ewadj2dmux_dma_stats_reg_transferred_stats[23:16] <= ~din[23:16] & ewadj2dmux_dma_stats_reg_transferred_stats[23:16];
         end
         if (we_ewadj2dmux_dma_stats_reg[3]) begin
            ewadj2dmux_dma_stats_reg_transferred_stats[31:24] <= ~din[31:24] & ewadj2dmux_dma_stats_reg_transferred_stats[31:24];
         end
      end
      else begin
         if (we_ewadj2dmux_dma_stats_reg_transferred_stats) begin
            ewadj2dmux_dma_stats_reg_transferred_stats[31:0] <= ewadj2dmux_dma_stats_reg_transferred_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register dmux_dma_0_drop_stats_reg implementation
// -----------------------------------------------------------------------------

// dmux_dma_0_drop_stats_reg_dropped_stats
//    bitfield description : Indicates number of dma ch0 packets dropped.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : dmux_dma_0_drop_stats_reg_dropped_stats_i
//    hardware write enable: we_dmux_dma_0_drop_stats_reg_dropped_stats

always @(posedge clk)
   if (!reset_n) begin
      dmux_dma_0_drop_stats_reg_dropped_stats <= 32'h00000000;
   end
   else begin
      if (we_dmux_dma_0_drop_stats_reg[0] || we_dmux_dma_0_drop_stats_reg[1] || we_dmux_dma_0_drop_stats_reg[2] || we_dmux_dma_0_drop_stats_reg[3]) begin
         if (we_dmux_dma_0_drop_stats_reg[0]) begin
            dmux_dma_0_drop_stats_reg_dropped_stats[7:0] <= ~din[7:0] & dmux_dma_0_drop_stats_reg_dropped_stats[7:0];
         end
         if (we_dmux_dma_0_drop_stats_reg[1]) begin
            dmux_dma_0_drop_stats_reg_dropped_stats[15:8] <= ~din[15:8] & dmux_dma_0_drop_stats_reg_dropped_stats[15:8];
         end
         if (we_dmux_dma_0_drop_stats_reg[2]) begin
            dmux_dma_0_drop_stats_reg_dropped_stats[23:16] <= ~din[23:16] & dmux_dma_0_drop_stats_reg_dropped_stats[23:16];
         end
         if (we_dmux_dma_0_drop_stats_reg[3]) begin
            dmux_dma_0_drop_stats_reg_dropped_stats[31:24] <= ~din[31:24] & dmux_dma_0_drop_stats_reg_dropped_stats[31:24];
         end
      end
      else begin
         if (we_dmux_dma_0_drop_stats_reg_dropped_stats) begin
            dmux_dma_0_drop_stats_reg_dropped_stats[31:0] <= dmux_dma_0_drop_stats_reg_dropped_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register dmux_dma_1_drop_stats_reg implementation
// -----------------------------------------------------------------------------

// dmux_dma_1_drop_stats_reg_dropped_stats
//    bitfield description : Indicates number of dma ch1 packets dropped.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : dmux_dma_1_drop_stats_reg_dropped_stats_i
//    hardware write enable: we_dmux_dma_1_drop_stats_reg_dropped_stats

always @(posedge clk)
   if (!reset_n) begin
      dmux_dma_1_drop_stats_reg_dropped_stats <= 32'h00000000;
   end
   else begin
      if (we_dmux_dma_1_drop_stats_reg[0] || we_dmux_dma_1_drop_stats_reg[1] || we_dmux_dma_1_drop_stats_reg[2] || we_dmux_dma_1_drop_stats_reg[3]) begin
         if (we_dmux_dma_1_drop_stats_reg[0]) begin
            dmux_dma_1_drop_stats_reg_dropped_stats[7:0] <= ~din[7:0] & dmux_dma_1_drop_stats_reg_dropped_stats[7:0];
         end
         if (we_dmux_dma_1_drop_stats_reg[1]) begin
            dmux_dma_1_drop_stats_reg_dropped_stats[15:8] <= ~din[15:8] & dmux_dma_1_drop_stats_reg_dropped_stats[15:8];
         end
         if (we_dmux_dma_1_drop_stats_reg[2]) begin
            dmux_dma_1_drop_stats_reg_dropped_stats[23:16] <= ~din[23:16] & dmux_dma_1_drop_stats_reg_dropped_stats[23:16];
         end
         if (we_dmux_dma_1_drop_stats_reg[3]) begin
            dmux_dma_1_drop_stats_reg_dropped_stats[31:24] <= ~din[31:24] & dmux_dma_1_drop_stats_reg_dropped_stats[31:24];
         end
      end
      else begin
         if (we_dmux_dma_1_drop_stats_reg_dropped_stats) begin
            dmux_dma_1_drop_stats_reg_dropped_stats[31:0] <= dmux_dma_1_drop_stats_reg_dropped_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register dmux_dma_2_drop_stats_reg implementation
// -----------------------------------------------------------------------------

// dmux_dma_2_drop_stats_reg_dropped_stats
//    bitfield description : Indicates number of dma ch2 packets dropped.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : dmux_dma_2_drop_stats_reg_dropped_stats_i
//    hardware write enable: we_dmux_dma_2_drop_stats_reg_dropped_stats

always @(posedge clk)
   if (!reset_n) begin
      dmux_dma_2_drop_stats_reg_dropped_stats <= 32'h00000000;
   end
   else begin
      if (we_dmux_dma_2_drop_stats_reg[0] || we_dmux_dma_2_drop_stats_reg[1] || we_dmux_dma_2_drop_stats_reg[2] || we_dmux_dma_2_drop_stats_reg[3]) begin
         if (we_dmux_dma_2_drop_stats_reg[0]) begin
            dmux_dma_2_drop_stats_reg_dropped_stats[7:0] <= ~din[7:0] & dmux_dma_2_drop_stats_reg_dropped_stats[7:0];
         end
         if (we_dmux_dma_2_drop_stats_reg[1]) begin
            dmux_dma_2_drop_stats_reg_dropped_stats[15:8] <= ~din[15:8] & dmux_dma_2_drop_stats_reg_dropped_stats[15:8];
         end
         if (we_dmux_dma_2_drop_stats_reg[2]) begin
            dmux_dma_2_drop_stats_reg_dropped_stats[23:16] <= ~din[23:16] & dmux_dma_2_drop_stats_reg_dropped_stats[23:16];
         end
         if (we_dmux_dma_2_drop_stats_reg[3]) begin
            dmux_dma_2_drop_stats_reg_dropped_stats[31:24] <= ~din[31:24] & dmux_dma_2_drop_stats_reg_dropped_stats[31:24];
         end
      end
      else begin
         if (we_dmux_dma_2_drop_stats_reg_dropped_stats) begin
            dmux_dma_2_drop_stats_reg_dropped_stats[31:0] <= dmux_dma_2_drop_stats_reg_dropped_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register dmux2dma_0_stats_reg implementation
// -----------------------------------------------------------------------------

// dmux2dma_0_stats_reg_transferred_stats
//    bitfield description : Indicates number of packets transferred between the 2 interfaces.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : dmux2dma_0_stats_reg_transferred_stats_i
//    hardware write enable: we_dmux2dma_0_stats_reg_transferred_stats

always @(posedge clk)
   if (!reset_n) begin
      dmux2dma_0_stats_reg_transferred_stats <= 32'h00000000;
   end
   else begin
      if (we_dmux2dma_0_stats_reg[0] || we_dmux2dma_0_stats_reg[1] || we_dmux2dma_0_stats_reg[2] || we_dmux2dma_0_stats_reg[3]) begin
         if (we_dmux2dma_0_stats_reg[0]) begin
            dmux2dma_0_stats_reg_transferred_stats[7:0] <= ~din[7:0] & dmux2dma_0_stats_reg_transferred_stats[7:0];
         end
         if (we_dmux2dma_0_stats_reg[1]) begin
            dmux2dma_0_stats_reg_transferred_stats[15:8] <= ~din[15:8] & dmux2dma_0_stats_reg_transferred_stats[15:8];
         end
         if (we_dmux2dma_0_stats_reg[2]) begin
            dmux2dma_0_stats_reg_transferred_stats[23:16] <= ~din[23:16] & dmux2dma_0_stats_reg_transferred_stats[23:16];
         end
         if (we_dmux2dma_0_stats_reg[3]) begin
            dmux2dma_0_stats_reg_transferred_stats[31:24] <= ~din[31:24] & dmux2dma_0_stats_reg_transferred_stats[31:24];
         end
      end
      else begin
         if (we_dmux2dma_0_stats_reg_transferred_stats) begin
            dmux2dma_0_stats_reg_transferred_stats[31:0] <= dmux2dma_0_stats_reg_transferred_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register dmux2dma_1_stats_reg implementation
// -----------------------------------------------------------------------------

// dmux2dma_1_stats_reg_transferred_stats
//    bitfield description : Indicates number of packets transferred between the 2 interfaces.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : dmux2dma_1_stats_reg_transferred_stats_i
//    hardware write enable: we_dmux2dma_1_stats_reg_transferred_stats

always @(posedge clk)
   if (!reset_n) begin
      dmux2dma_1_stats_reg_transferred_stats <= 32'h00000000;
   end
   else begin
      if (we_dmux2dma_1_stats_reg[0] || we_dmux2dma_1_stats_reg[1] || we_dmux2dma_1_stats_reg[2] || we_dmux2dma_1_stats_reg[3]) begin
         if (we_dmux2dma_1_stats_reg[0]) begin
            dmux2dma_1_stats_reg_transferred_stats[7:0] <= ~din[7:0] & dmux2dma_1_stats_reg_transferred_stats[7:0];
         end
         if (we_dmux2dma_1_stats_reg[1]) begin
            dmux2dma_1_stats_reg_transferred_stats[15:8] <= ~din[15:8] & dmux2dma_1_stats_reg_transferred_stats[15:8];
         end
         if (we_dmux2dma_1_stats_reg[2]) begin
            dmux2dma_1_stats_reg_transferred_stats[23:16] <= ~din[23:16] & dmux2dma_1_stats_reg_transferred_stats[23:16];
         end
         if (we_dmux2dma_1_stats_reg[3]) begin
            dmux2dma_1_stats_reg_transferred_stats[31:24] <= ~din[31:24] & dmux2dma_1_stats_reg_transferred_stats[31:24];
         end
      end
      else begin
         if (we_dmux2dma_1_stats_reg_transferred_stats) begin
            dmux2dma_1_stats_reg_transferred_stats[31:0] <= dmux2dma_1_stats_reg_transferred_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register dmux2dma_2_stats_reg implementation
// -----------------------------------------------------------------------------

// dmux2dma_2_stats_reg_transferred_stats
//    bitfield description : Indicates number of packets transferred between the 2 interfaces.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : dmux2dma_2_stats_reg_transferred_stats_i
//    hardware write enable: we_dmux2dma_2_stats_reg_transferred_stats

always @(posedge clk)
   if (!reset_n) begin
      dmux2dma_2_stats_reg_transferred_stats <= 32'h00000000;
   end
   else begin
      if (we_dmux2dma_2_stats_reg[0] || we_dmux2dma_2_stats_reg[1] || we_dmux2dma_2_stats_reg[2] || we_dmux2dma_2_stats_reg[3]) begin
         if (we_dmux2dma_2_stats_reg[0]) begin
            dmux2dma_2_stats_reg_transferred_stats[7:0] <= ~din[7:0] & dmux2dma_2_stats_reg_transferred_stats[7:0];
         end
         if (we_dmux2dma_2_stats_reg[1]) begin
            dmux2dma_2_stats_reg_transferred_stats[15:8] <= ~din[15:8] & dmux2dma_2_stats_reg_transferred_stats[15:8];
         end
         if (we_dmux2dma_2_stats_reg[2]) begin
            dmux2dma_2_stats_reg_transferred_stats[23:16] <= ~din[23:16] & dmux2dma_2_stats_reg_transferred_stats[23:16];
         end
         if (we_dmux2dma_2_stats_reg[3]) begin
            dmux2dma_2_stats_reg_transferred_stats[31:24] <= ~din[31:24] & dmux2dma_2_stats_reg_transferred_stats[31:24];
         end
      end
      else begin
         if (we_dmux2dma_2_stats_reg_transferred_stats) begin
            dmux2dma_2_stats_reg_transferred_stats[31:0] <= dmux2dma_2_stats_reg_transferred_stats_i[31:0];
         end
      end
   end

// -----------------------------------------------------------------------------
// Register rx_iwadj_drop_stats_reg implementation
// -----------------------------------------------------------------------------

// rx_iwadj_drop_stats_reg_dropped_stats
//    bitfield description : Indicates number of packets dropped.
//                           // Write 1 to Clear.
//    customType           : W1C
//    hwAccess             : RW
//    reset value          : 32'h00000000
//    inputPort            : rx_iwadj_drop_stats_reg_dropped_stats_i
//    hardware write enable: we_rx_iwadj_drop_stats_reg_dropped_stats

always @(posedge clk)
   if (!reset_n) begin
      rx_iwadj_drop_stats_reg_dropped_stats <= 32'h00000000;
   end
   else begin
      if (we_rx_iwadj_drop_stats_reg[0] || we_rx_iwadj_drop_stats_reg[1] || we_rx_iwadj_drop_stats_reg[2] || we_rx_iwadj_drop_stats_reg[3]) begin
         if (we_rx_iwadj_drop_stats_reg[0]) begin
            rx_iwadj_drop_stats_reg_dropped_stats[7:0] <= ~din[7:0] & rx_iwadj_drop_stats_reg_dropped_stats[7:0];
         end
         if (we_rx_iwadj_drop_stats_reg[1]) begin
            rx_iwadj_drop_stats_reg_dropped_stats[15:8] <= ~din[15:8] & rx_iwadj_drop_stats_reg_dropped_stats[15:8];
         end
         if (we_rx_iwadj_drop_stats_reg[2]) begin
            rx_iwadj_drop_stats_reg_dropped_stats[23:16] <= ~din[23:16] & rx_iwadj_drop_stats_reg_dropped_stats[23:16];
         end
         if (we_rx_iwadj_drop_stats_reg[3]) begin
            rx_iwadj_drop_stats_reg_dropped_stats[31:24] <= ~din[31:24] & rx_iwadj_drop_stats_reg_dropped_stats[31:24];
         end
      end
      else begin
         if (we_rx_iwadj_drop_stats_reg_dropped_stats) begin
            rx_iwadj_drop_stats_reg_dropped_stats[31:0] <= rx_iwadj_drop_stats_reg_dropped_stats_i[31:0];
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
         // Register hssi2iwadj_stats_reg: hssi2iwadj_stats_reg_transferred_stats (W1C)
         6'h00: begin
            rdata_comb[31:0] = hssi2iwadj_stats_reg_transferred_stats[31:0];
         end
         // Register iwadj2pars_stats_reg: iwadj2pars_stats_reg_transferred_stats (W1C)
         6'h04: begin
            rdata_comb[31:0] = iwadj2pars_stats_reg_transferred_stats[31:0];
         end
         // Register pars2lkup_stats_reg: pars2lkup_stats_reg_transferred_stats (W1C)
         6'h08: begin
            rdata_comb[31:0] = pars2lkup_stats_reg_transferred_stats[31:0];
         end
         // Register lkup_drop_stats_reg: lkup_drop_stats_reg_dropped_stats (W1C)
         6'h0c: begin
            rdata_comb[31:0] = lkup_drop_stats_reg_dropped_stats[31:0];
         end
         // Register lkup2ewadj_user_stats_reg: lkup2ewadj_user_stats_reg_transferred_stats (W1C)
         6'h10: begin
            rdata_comb[31:0] = lkup2ewadj_user_stats_reg_transferred_stats[31:0];
         end
         // Register ewadj2user_stats_reg: ewadj2user_stats_reg_transferred_stats (W1C)
         6'h14: begin
            rdata_comb[31:0] = ewadj2user_stats_reg_transferred_stats[31:0];
         end
         // Register ewadj_user_drop_stats_reg: ewadj_user_drop_stats_reg_dropped_stats (W1C)
         6'h18: begin
            rdata_comb[31:0] = ewadj_user_drop_stats_reg_dropped_stats[31:0];
         end
         // Register lkup2ewadj_dma_stats_reg: lkup2ewadj_dma_stats_reg_transferred_stats (W1C)
         6'h1c: begin
            rdata_comb[31:0] = lkup2ewadj_dma_stats_reg_transferred_stats[31:0];
         end
         // Register ewadj2dmux_dma_stats_reg: ewadj2dmux_dma_stats_reg_transferred_stats (W1C)
         6'h20: begin
            rdata_comb[31:0] = ewadj2dmux_dma_stats_reg_transferred_stats[31:0];
         end
         // Register dmux_dma_0_drop_stats_reg: dmux_dma_0_drop_stats_reg_dropped_stats (W1C)
         6'h24: begin
            rdata_comb[31:0] = dmux_dma_0_drop_stats_reg_dropped_stats[31:0];
         end
         // Register dmux_dma_1_drop_stats_reg: dmux_dma_1_drop_stats_reg_dropped_stats (W1C)
         6'h28: begin
            rdata_comb[31:0] = dmux_dma_1_drop_stats_reg_dropped_stats[31:0];
         end
         // Register dmux_dma_2_drop_stats_reg: dmux_dma_2_drop_stats_reg_dropped_stats (W1C)
         6'h2c: begin
            rdata_comb[31:0] = dmux_dma_2_drop_stats_reg_dropped_stats[31:0];
         end
         // Register dmux2dma_0_stats_reg: dmux2dma_0_stats_reg_transferred_stats (W1C)
         6'h30: begin
            rdata_comb[31:0] = dmux2dma_0_stats_reg_transferred_stats[31:0];
         end
         // Register dmux2dma_1_stats_reg: dmux2dma_1_stats_reg_transferred_stats (W1C)
         6'h34: begin
            rdata_comb[31:0] = dmux2dma_1_stats_reg_transferred_stats[31:0];
         end
         // Register dmux2dma_2_stats_reg: dmux2dma_2_stats_reg_transferred_stats (W1C)
         6'h38: begin
            rdata_comb[31:0] = dmux2dma_2_stats_reg_transferred_stats[31:0];
         end
         // Register rx_iwadj_drop_stats_reg: rx_iwadj_drop_stats_reg_dropped_stats (W1C)
         6'h3c: begin
            rdata_comb[31:0] = rx_iwadj_drop_stats_reg_dropped_stats[31:0];
         end
         default: begin
            rdata_comb = 32'h00000000;
         end
      endcase
   end
end

endmodule