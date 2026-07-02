///# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module user_csr_space(

   // CONTROL_REG.p0_i_rst_n
   input wire we_CONTROL_REG_p0_i_rst_n,
   input wire CONTROL_REG_p0_i_rst_n_i,
   output reg CONTROL_REG_p0_i_rst_n,
   // CONTROL_REG.p1_i_rst_n
   input wire we_CONTROL_REG_p1_i_rst_n,
   input wire CONTROL_REG_p1_i_rst_n_i,
   output reg CONTROL_REG_p1_i_rst_n,
   // CONTROL_REG.p0_i_tx_rst_n
   input wire we_CONTROL_REG_p0_i_tx_rst_n,
   input wire CONTROL_REG_p0_i_tx_rst_n_i,
   output reg CONTROL_REG_p0_i_tx_rst_n,
   // CONTROL_REG.p1_i_tx_rst_n
   input wire we_CONTROL_REG_p1_i_tx_rst_n,
   input wire CONTROL_REG_p1_i_tx_rst_n_i,
   output reg CONTROL_REG_p1_i_tx_rst_n,
   // CONTROL_REG.p0_i_rx_rst_n
   input wire we_CONTROL_REG_p0_i_rx_rst_n,
   input wire CONTROL_REG_p0_i_rx_rst_n_i,
   output reg CONTROL_REG_p0_i_rx_rst_n,
   // CONTROL_REG.p1_i_rx_rst_n
   input wire we_CONTROL_REG_p1_i_rx_rst_n,
   input wire CONTROL_REG_p1_i_rx_rst_n_i,
   output reg CONTROL_REG_p1_i_rx_rst_n,
   // ERROR_REG.fp_i_rst_n
   input wire we_ERROR_REG_fp_i_rst_n,
   input wire [1:0] ERROR_REG_fp_i_rst_n_i,
   output reg [1:0] ERROR_REG_fp_i_rst_n,
   // STATUS_REG.p0_rx_pcs_ready
   input wire STATUS_REG_p0_rx_pcs_ready_i,
   // STATUS_REG.p1_rx_pcs_ready
   input wire STATUS_REG_p1_rx_pcs_ready_i,
   // STATUS_REG.p0_tx_lane_stable
   input wire STATUS_REG_p0_tx_lane_stable_i,
   // STATUS_REG.p1_tx_lane_stable
   input wire STATUS_REG_p1_tx_lane_stable_i,
   // STATUS_REG.p0_tx_pll_locked
   input wire STATUS_REG_p0_tx_pll_locked_i,
   // STATUS_REG.p1_tx_pll_locked
   input wire STATUS_REG_p1_tx_pll_locked_i,
   // STATUS_REG.p0_rx_cdr_locked
   input wire STATUS_REG_p0_rx_cdr_locked_i,
   // STATUS_REG.p1_rx_cdr_locked
   input wire STATUS_REG_p1_rx_cdr_locked_i,
   // STATUS_REG.sys_pll_locked
   input wire STATUS_REG_sys_pll_locked_i,
   // FIFO_STATUS_REG.port0_tx_fifo_depth
   input wire [7:0] FIFO_STATUS_REG_port0_tx_fifo_depth_i,
   // FIFO_STATUS_REG.port1_tx_fifo_depth
   input wire [7:0] FIFO_STATUS_REG_port1_tx_fifo_depth_i,
   // FIFO_STATUS_REG.port0_rx_fifo_depth
   input wire [7:0] FIFO_STATUS_REG_port0_rx_fifo_depth_i,
   // FIFO_STATUS_REG.port1_rx_fifo_depth
   input wire [7:0] FIFO_STATUS_REG_port1_rx_fifo_depth_i,

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

// Register CONTROL_REG
wire we_CONTROL_REG = we & (addr[3:0] == 4'h0) ? byteenable[0] : 1'b0;
// Register ERROR_REG
wire we_ERROR_REG = we & (addr[3:0] == 4'h4) ? byteenable[0] : 1'b0;

// -----------------------------------------------------------------------------
// Read byte enables
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Register CONTROL_REG implementation
// -----------------------------------------------------------------------------

// CONTROL_REG_p0_i_rst_n
//    bitfield description : Global reset to Eth port0.
//                           // Self cleared on o_rst_ack_n
//    customType           : RW
//    hwAccess             : RW
//    reset value          : 1'h1
//    inputPort            : CONTROL_REG_p0_i_rst_n_i
//    hardware write enable: we_CONTROL_REG_p0_i_rst_n

always @(posedge clk)
   if (!reset_n) begin
      CONTROL_REG_p0_i_rst_n <= 1'h1;
   end
   else begin
      if (we_CONTROL_REG) begin
         CONTROL_REG_p0_i_rst_n <= din[0];
      end
      else begin
         if (we_CONTROL_REG_p0_i_rst_n) begin
            CONTROL_REG_p0_i_rst_n <= CONTROL_REG_p0_i_rst_n_i;
         end
      end
   end

// CONTROL_REG_p1_i_rst_n
//    bitfield description : Global reset to Eth port1.
//                           // Self cleared on o_rst_ack_n
//    customType           : RW
//    hwAccess             : RW
//    reset value          : 1'h1
//    inputPort            : CONTROL_REG_p1_i_rst_n_i
//    hardware write enable: we_CONTROL_REG_p1_i_rst_n

always @(posedge clk)
   if (!reset_n) begin
      CONTROL_REG_p1_i_rst_n <= 1'h1;
   end
   else begin
      if (we_CONTROL_REG) begin
         CONTROL_REG_p1_i_rst_n <= din[1];
      end
      else begin
         if (we_CONTROL_REG_p1_i_rst_n) begin
            CONTROL_REG_p1_i_rst_n <= CONTROL_REG_p1_i_rst_n_i;
         end
      end
   end

// CONTROL_REG_p0_i_tx_rst_n
//    bitfield description : Resets the entire TX datapath Eth port0.
//                           // Self cleared on o_tx_rst_ack_n
//    customType           : RW
//    hwAccess             : RW
//    reset value          : 1'h1
//    inputPort            : CONTROL_REG_p0_i_tx_rst_n_i
//    hardware write enable: we_CONTROL_REG_p0_i_tx_rst_n

always @(posedge clk)
   if (!reset_n) begin
      CONTROL_REG_p0_i_tx_rst_n <= 1'h1;
   end
   else begin
      if (we_CONTROL_REG) begin
         CONTROL_REG_p0_i_tx_rst_n <= din[2];
      end
      else begin
         if (we_CONTROL_REG_p0_i_tx_rst_n) begin
            CONTROL_REG_p0_i_tx_rst_n <= CONTROL_REG_p0_i_tx_rst_n_i;
         end
      end
   end

// CONTROL_REG_p1_i_tx_rst_n
//    bitfield description : Resets the entire TX datapath Eth port1.
//                           // Self cleared on o_tx_rst_ack_n
//    customType           : RW
//    hwAccess             : RW
//    reset value          : 1'h1
//    inputPort            : CONTROL_REG_p1_i_tx_rst_n_i
//    hardware write enable: we_CONTROL_REG_p1_i_tx_rst_n

always @(posedge clk)
   if (!reset_n) begin
      CONTROL_REG_p1_i_tx_rst_n <= 1'h1;
   end
   else begin
      if (we_CONTROL_REG) begin
         CONTROL_REG_p1_i_tx_rst_n <= din[3];
      end
      else begin
         if (we_CONTROL_REG_p1_i_tx_rst_n) begin
            CONTROL_REG_p1_i_tx_rst_n <= CONTROL_REG_p1_i_tx_rst_n_i;
         end
      end
   end

// CONTROL_REG_p0_i_rx_rst_n
//    bitfield description : Resets the entire RX datapath Eth port0.
//                           // Self cleared on o_rx_rst_ack_n
//    customType           : RW
//    hwAccess             : RW
//    reset value          : 1'h1
//    inputPort            : CONTROL_REG_p0_i_rx_rst_n_i
//    hardware write enable: we_CONTROL_REG_p0_i_rx_rst_n

always @(posedge clk)
   if (!reset_n) begin
      CONTROL_REG_p0_i_rx_rst_n <= 1'h1;
   end
   else begin
      if (we_CONTROL_REG) begin
         CONTROL_REG_p0_i_rx_rst_n <= din[4];
      end
      else begin
         if (we_CONTROL_REG_p0_i_rx_rst_n) begin
            CONTROL_REG_p0_i_rx_rst_n <= CONTROL_REG_p0_i_rx_rst_n_i;
         end
      end
   end

// CONTROL_REG_p1_i_rx_rst_n
//    bitfield description : Resets the entire RX datapath Eth port1.
//                           // Self cleared on o_rx_rst_ack_n
//    customType           : RW
//    hwAccess             : RW
//    reset value          : 1'h1
//    inputPort            : CONTROL_REG_p1_i_rx_rst_n_i
//    hardware write enable: we_CONTROL_REG_p1_i_rx_rst_n

always @(posedge clk)
   if (!reset_n) begin
      CONTROL_REG_p1_i_rx_rst_n <= 1'h1;
   end
   else begin
      if (we_CONTROL_REG) begin
         CONTROL_REG_p1_i_rx_rst_n <= din[5];
      end
      else begin
         if (we_CONTROL_REG_p1_i_rx_rst_n) begin
            CONTROL_REG_p1_i_rx_rst_n <= CONTROL_REG_p1_i_rx_rst_n_i;
         end
      end
   end

// CONTROL_REG_Reserved
//    bitfield description: Reserved
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 26'h0000000
//
// No register generated

// -----------------------------------------------------------------------------
// Register ERROR_REG implementation
// -----------------------------------------------------------------------------

// ERROR_REG_fp_i_rst_n
//    bitfield description : Fingerprint error specific to mSGDMA TX Queue meant for any eth port.
//                           // This bit is used for assertion of IRQ, so it needs to be cleared by SW after serving it.
//    customType           : RW
//    hwAccess             : RW
//    reset value          : 2'h1
//    inputPort            : ERROR_REG_fp_i_rst_n_i
//    hardware write enable: we_ERROR_REG_fp_i_rst_n

always @(posedge clk)
   if (!reset_n) begin
      ERROR_REG_fp_i_rst_n <= 2'h1;
   end
   else begin
      if (we_ERROR_REG) begin
         ERROR_REG_fp_i_rst_n[1:0] <= din[1:0];
      end
      else begin
         if (we_ERROR_REG_fp_i_rst_n) begin
            ERROR_REG_fp_i_rst_n[1:0] <= ERROR_REG_fp_i_rst_n_i[1:0];
         end
      end
   end

// ERROR_REG_Reserved
//    bitfield description: Reserved
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 30'h00000000
//
// No register generated

// -----------------------------------------------------------------------------
// Register STATUS_REG implementation
// -----------------------------------------------------------------------------

// STATUS_REG_p0_rx_pcs_ready
//    bitfield description: Asserts when the Eth port0 RX datapath is ready to receive data
//    customType          : RO
//    hwAccess            : WO
//    reset value         : 1'h0
//    inputPort           : STATUS_REG_p0_rx_pcs_ready_i
//
// No register generated

// STATUS_REG_p1_rx_pcs_ready
//    bitfield description: Asserts when the Eth port1 RX datapath is ready to receive data
//    customType          : RO
//    hwAccess            : WO
//    reset value         : 1'h0
//    inputPort           : STATUS_REG_p1_rx_pcs_ready_i
//
// No register generated

// STATUS_REG_p0_tx_lane_stable
//    bitfield description: Asserts when the Eth port0 TX datapath is ready to send data
//    customType          : RO
//    hwAccess            : WO
//    reset value         : 1'h0
//    inputPort           : STATUS_REG_p0_tx_lane_stable_i
//
// No register generated

// STATUS_REG_p1_tx_lane_stable
//    bitfield description: Asserts when the Eth port1 TX datapath is ready to send data
//    customType          : RO
//    hwAccess            : WO
//    reset value         : 1'h0
//    inputPort           : STATUS_REG_p1_tx_lane_stable_i
//
// No register generated

// STATUS_REG_p0_tx_pll_locked
//    bitfield description: Indicates Eth port0 o_clk_pll is good to use
//    customType          : RO
//    hwAccess            : WO
//    reset value         : 1'h0
//    inputPort           : STATUS_REG_p0_tx_pll_locked_i
//
// No register generated

// STATUS_REG_p1_tx_pll_locked
//    bitfield description: Indicates Eth port1 o_clk_pll is good to use
//    customType          : RO
//    hwAccess            : WO
//    reset value         : 1'h0
//    inputPort           : STATUS_REG_p1_tx_pll_locked_i
//
// No register generated

// STATUS_REG_p0_rx_cdr_locked
//    bitfield description: This signal indicates that the Eth port0 recovered clocks are locked to data
//    customType          : RO
//    hwAccess            : WO
//    reset value         : 1'h0
//    inputPort           : STATUS_REG_p0_rx_cdr_locked_i
//
// No register generated

// STATUS_REG_p1_rx_cdr_locked
//    bitfield description: This signal indicates that the Eth port1 recovered clocks are locked to data
//    customType          : RO
//    hwAccess            : WO
//    reset value         : 1'h0
//    inputPort           : STATUS_REG_p1_rx_cdr_locked_i
//
// No register generated

// STATUS_REG_sys_pll_locked
//    bitfield description: Indicates that Sys PLL is locked.
//    customType          : RO
//    hwAccess            : WO
//    reset value         : 1'h0
//    inputPort           : STATUS_REG_sys_pll_locked_i
//
// No register generated

// STATUS_REG_Reserved
//    bitfield description: Reserved
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 23'h000000
//
// No register generated

// -----------------------------------------------------------------------------
// Register FIFO_STATUS_REG implementation
// -----------------------------------------------------------------------------

// FIFO_STATUS_REG_port0_tx_fifo_depth
//    bitfield description: Port0 Tx packet FIFO depth
//    customType          : RO
//    hwAccess            : WO
//    reset value         : 8'h00
//    inputPort           : FIFO_STATUS_REG_port0_tx_fifo_depth_i
//
// No register generated

// FIFO_STATUS_REG_port1_tx_fifo_depth
//    bitfield description: Port1 Tx packet FIFO depth
//    customType          : RO
//    hwAccess            : WO
//    reset value         : 8'h00
//    inputPort           : FIFO_STATUS_REG_port1_tx_fifo_depth_i
//
// No register generated

// FIFO_STATUS_REG_port0_rx_fifo_depth
//    bitfield description: Port0 Rx packet FIFO depth
//    customType          : RO
//    hwAccess            : WO
//    reset value         : 8'h00
//    inputPort           : FIFO_STATUS_REG_port0_rx_fifo_depth_i
//
// No register generated

// FIFO_STATUS_REG_port1_rx_fifo_depth
//    bitfield description: Port1 Rx packet FIFO depth
//    customType          : RO
//    hwAccess            : WO
//    reset value         : 8'h00
//    inputPort           : FIFO_STATUS_REG_port1_rx_fifo_depth_i
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
         // Register CONTROL_REG: CONTROL_REG_p0_i_rst_n (RW)
         //                       CONTROL_REG_p1_i_rst_n (RW)
         //                       CONTROL_REG_p0_i_tx_rst_n (RW)
         //                       CONTROL_REG_p1_i_tx_rst_n (RW)
         //                       CONTROL_REG_p0_i_rx_rst_n (RW)
         //                       CONTROL_REG_p1_i_rx_rst_n (RW)
         //                       CONTROL_REG_Reserved (RO)
         4'h0: begin
            rdata_comb[0] = CONTROL_REG_p0_i_rst_n;
            rdata_comb[1] = CONTROL_REG_p1_i_rst_n;
            rdata_comb[2] = CONTROL_REG_p0_i_tx_rst_n;
            rdata_comb[3] = CONTROL_REG_p1_i_tx_rst_n;
            rdata_comb[4] = CONTROL_REG_p0_i_rx_rst_n;
            rdata_comb[5] = CONTROL_REG_p1_i_rx_rst_n;
            rdata_comb[31:6] = 26'h0000000;
         end
         // Register ERROR_REG: ERROR_REG_fp_i_rst_n (RW)
         //                     ERROR_REG_Reserved (RO)
         4'h4: begin
            rdata_comb[1:0] = ERROR_REG_fp_i_rst_n[1:0];
            rdata_comb[31:2] = 30'h00000000;
         end
         // Register STATUS_REG: STATUS_REG_p0_rx_pcs_ready (RO)
         //                      STATUS_REG_p1_rx_pcs_ready (RO)
         //                      STATUS_REG_p0_tx_lane_stable (RO)
         //                      STATUS_REG_p1_tx_lane_stable (RO)
         //                      STATUS_REG_p0_tx_pll_locked (RO)
         //                      STATUS_REG_p1_tx_pll_locked (RO)
         //                      STATUS_REG_p0_rx_cdr_locked (RO)
         //                      STATUS_REG_p1_rx_cdr_locked (RO)
         //                      STATUS_REG_sys_pll_locked (RO)
         //                      STATUS_REG_Reserved (RO)
         4'h8: begin
            rdata_comb[0] = STATUS_REG_p0_rx_pcs_ready_i;
            rdata_comb[1] = STATUS_REG_p1_rx_pcs_ready_i;
            rdata_comb[2] = STATUS_REG_p0_tx_lane_stable_i;
            rdata_comb[3] = STATUS_REG_p1_tx_lane_stable_i;
            rdata_comb[4] = STATUS_REG_p0_tx_pll_locked_i;
            rdata_comb[5] = STATUS_REG_p1_tx_pll_locked_i;
            rdata_comb[6] = STATUS_REG_p0_rx_cdr_locked_i;
            rdata_comb[7] = STATUS_REG_p1_rx_cdr_locked_i;
            rdata_comb[8] = STATUS_REG_sys_pll_locked_i;
            rdata_comb[31:9] = 23'h000000;
         end
         // Register FIFO_STATUS_REG: FIFO_STATUS_REG_port0_tx_fifo_depth (RO)
         //                           FIFO_STATUS_REG_port1_tx_fifo_depth (RO)
         //                           FIFO_STATUS_REG_port0_rx_fifo_depth (RO)
         //                           FIFO_STATUS_REG_port1_rx_fifo_depth (RO)
         4'hc: begin
            rdata_comb[7:0] = FIFO_STATUS_REG_port0_tx_fifo_depth_i[7:0];
            rdata_comb[15:8] = FIFO_STATUS_REG_port1_tx_fifo_depth_i[7:0];
            rdata_comb[23:16] = FIFO_STATUS_REG_port0_rx_fifo_depth_i[7:0];
            rdata_comb[31:24] = FIFO_STATUS_REG_port1_rx_fifo_depth_i[7:0];
         end
         default: begin
            rdata_comb = 32'h00000000;
         end
      endcase
   end
end

endmodule
