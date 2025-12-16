//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module general_csr #(
    parameter HSSI_PORT = 2
   ,parameter DMA_CH    = 6
   ,parameter DBG_CNTR_EN = 0
   )
   (
   // status_reg.rx_init_done
   input wire status_reg_rx_init_done_i,
   // status_reg.tx_init_done
   input wire status_reg_tx_init_done_i,

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
wire [4:0] addr = address[4:0];
wire [31:0] din = writedata[31:0];

// -----------------------------------------------------------------------------
// Write byte enables
// -----------------------------------------------------------------------------

// Register scratch_reg
wire [3:0] we_scratch_reg = we & (addr[4:0] == 5'h00) ? byteenable[3:0] : {4{1'b0}};

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
// Register status_reg implementation
// -----------------------------------------------------------------------------

// status_reg_major_version
//    bitfield description: Major version number.
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 4'h1
//
// No register generated

// status_reg_minor_version
//    bitfield description: Minor version number.
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 4'h0
//
// No register generated

// status_reg_total_hssi_ports
//    bitfield description: Indicates how many total HSSI ports are enabled.
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 4'h1
//
// No register generated

// status_reg_dma_ports
//    bitfield description: Indicates how many DMA ports are enabled per each HSSI port.
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 4'h1
//
// No register generated

// status_reg_user_ports
//    bitfield description: Indicates how many User ports are enabled per each HSSI port.
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 4'h1
//
// No register generated

// status_reg_debug_counter_en
//    bitfield description: Indicates if Debug Counters are enabled.
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 1'h0
//
// No register generated

// status_reg_rx_init_done
//    bitfield description: Indicates RX is ready to receive traffic.
//    customType          : RO
//    hwAccess            : WO
//    reset value         : 1'h0
//    inputPort           : status_reg_rx_init_done_i
//
// No register generated

// status_reg_tx_init_done
//    bitfield description: Indicates TX is ready to receive traffic.
//    customType          : RO
//    hwAccess            : WO
//    reset value         : 1'h0
//    inputPort           : status_reg_tx_init_done_i
//
// No register generated

// status_reg_reserved
//    bitfield description: Reserved.
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 9'h000
//
// No register generated

// -----------------------------------------------------------------------------
// Register reserved_0_reg implementation
// -----------------------------------------------------------------------------

// reserved_0_reg_reserved
//    bitfield description: Reserved.
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 32'h00000000
//
// No register generated

// -----------------------------------------------------------------------------
// Register reserved_1_reg implementation
// -----------------------------------------------------------------------------

// reserved_1_reg_reserved
//    bitfield description: Reserved.
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 32'h00000000
//
// No register generated

// -----------------------------------------------------------------------------
// Register reserved_2_reg implementation
// -----------------------------------------------------------------------------

// reserved_2_reg_reserved
//    bitfield description: Reserved.
//    customType          : RO
//    hwAccess            : NA
//    reset value         : 32'h00000000
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
         5'h00: begin
            rdata_comb[31:0] = scratch_reg_scratch[31:0];
         end
         // Register status_reg: status_reg_major_version (RO)
         //                      status_reg_minor_version (RO)
         //                      status_reg_total_hssi_ports (RO)
         //                      status_reg_dma_ports (RO)
         //                      status_reg_user_ports (RO)
         //                      status_reg_debug_counter_en (RO)
         //                      status_reg_rx_init_done (RO)
         //                      status_reg_tx_init_done (RO)
         //                      status_reg_reserved (RO)
         5'h04: begin
            rdata_comb[3:0] = 4'h1;
            rdata_comb[7:4] = 4'h0;
            rdata_comb[11:8] = HSSI_PORT;
            rdata_comb[15:12] = DMA_CH/HSSI_PORT;
            rdata_comb[19:16] = HSSI_PORT; // User ports must equal HSSI ports in current design
            rdata_comb[20] = DBG_CNTR_EN;
            rdata_comb[21] = status_reg_rx_init_done_i;
            rdata_comb[22] = status_reg_tx_init_done_i;
            rdata_comb[31:23] = 9'h000;
         end
         // Register reserved_0_reg: reserved_0_reg_reserved (RO)
         5'h08: begin
            rdata_comb[31:0] = 32'h00000000;
         end
         // Register reserved_1_reg: reserved_1_reg_reserved (RO)
         5'h0c: begin
            rdata_comb[31:0] = 32'h00000000;
         end
         // Register reserved_2_reg: reserved_2_reg_reserved (RO)
         5'h10: begin
            rdata_comb[31:0] = 32'h00000000;
         end
         default: begin
            rdata_comb = 32'h00000000;
         end
      endcase
   end
end

endmodule