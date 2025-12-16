//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module cdc_packet_fifo #(
    parameter int         USE_RX_READY                = 1
   ,parameter string      DEVICE                      = "s10" //must be "a10" or "s10"
   ,parameter int         MEMORY_CAPACITY_WORDS       = 256
   ,parameter int         AVST_DATA_WIDTH             = 64//has to be 32 or 64
   ,parameter int         RX_AVST_READY_LATENCY       = 0
   ,parameter int         AVST_USER_WIDTH             = 12
   ,parameter int         AVST_ERROR_WIDTH            = 1
   ,localparam int        AVST_EMPTY_WIDTH            = components_pkg::get_width(AVST_DATA_WIDTH)-3
   ,localparam int        MEMORY_ADDRESS_WIDTH        = components_pkg::get_width(MEMORY_CAPACITY_WORDS)
   ,localparam int        CSR_MM_DATA_WIDTH           = 64
   ,localparam int        CSR_MM_ADDR_WIDTH           = 10
      //Registers addresses
) (
/* fill_level
* - works on out_avst_clk
* - is provided in number of words of MEMORY_DATA_WIDTH filled in pkt fifo
* - depends on MEMORY_CAPACITY_WORDS
*/

    input  logic                             in_avst_clk
   ,input  logic                             in_avst_reset
   ,output logic                             in_avst_ready
   ,input  logic                             in_avst_valid
   ,input  logic                             in_avst_startofpacket
   ,input  logic                             in_avst_endofpacket
   ,input  logic [AVST_ERROR_WIDTH-1:0]      in_avst_error
   ,input  logic [AVST_EMPTY_WIDTH-1:0]      in_avst_empty
   ,input  logic [AVST_DATA_WIDTH-1:0]       in_avst_data
   ,input  logic [AVST_USER_WIDTH-1:0]       in_avst_user

   ,input  logic                             out_avst_clk
   ,input  logic                             out_avst_reset
   ,input  logic                             out_avst_ready
   ,output logic                             out_avst_valid
   ,output logic                             out_avst_startofpacket
   ,output logic                             out_avst_endofpacket
   ,output logic [AVST_EMPTY_WIDTH-1:0]      out_avst_empty
   ,output logic [AVST_DATA_WIDTH-1:0]       out_avst_data
   ,output logic [AVST_USER_WIDTH-1:0]       out_avst_user

   //avalon_mm_if csr_mm
   ,input  logic                             csr_mm_clk
   ,input  logic                             csr_mm_reset
   ,output logic                             csr_mm_waitrequest
   ,input  logic                             csr_mm_read
   ,input  logic                             csr_mm_write
   ,input  logic [CSR_MM_ADDR_WIDTH-1:0]     csr_mm_address
   ,input  logic [CSR_MM_DATA_WIDTH-1:0]     csr_mm_writedata
   ,output logic                             csr_mm_readdatavalid
   ,output logic [CSR_MM_DATA_WIDTH-1:0]     csr_mm_readdata

   ,output logic [MEMORY_ADDRESS_WIDTH-1:0]  fill_level_on_tx_clk
);

   localparam int    MEMORY_FULL             = (USE_RX_READY) ? MEMORY_CAPACITY_WORDS-4 - RX_AVST_READY_LATENCY : MEMORY_CAPACITY_WORDS-4; // -3 should be enough; -4 is safer option
   localparam int    MEMORY_DATA_WIDTH       = AVST_DATA_WIDTH + 2 + AVST_EMPTY_WIDTH + AVST_USER_WIDTH;
   localparam int    STAT_CNTRS_WIDTH        = 32;
   localparam int SPB = AVST_DATA_WIDTH/8;
   initial begin: design_rule_checks
      if (SPB != 2 && SPB != 4 && SPB != 8 && SPB != 16 && SPB != 32 && SPB != 64 && SPB != 128) begin
         $display("ERROR: Unsuported bus size. Supported sizes: 2B, 4B, 8B, 16B, 32B, 64B, 128B");
         $stop;
      end
   end

   logic                                     csr_mm_readdatavalid_reg;
   //avalon_mm_if csr_mm_on_rx_clk
   logic                                     csr_mm_on_rx_clk_read;
   logic                                     csr_mm_on_rx_clk_write;
   logic [CSR_MM_ADDR_WIDTH-1:0]             csr_mm_on_rx_clk_address;
   logic [CSR_MM_DATA_WIDTH-1:0]             csr_mm_on_rx_clk_readdata;

   logic [MEMORY_DATA_WIDTH-1:0]             rx_data_ext;
   logic                                     write_enable;
   logic                                     write_ready;
   logic [MEMORY_DATA_WIDTH-1:0]             write_data;
   logic [MEMORY_ADDRESS_WIDTH-1:0]          write_pointer;
   logic [MEMORY_ADDRESS_WIDTH-1:0]          write_read_pointer;
   logic                                     write_full;  
   logic                                     read_enable;
   logic                                     read_enable_q1;
   logic                                     read_valid;
   logic                                     read_ready;
   logic [MEMORY_DATA_WIDTH-1:0]             read_data;
   logic [MEMORY_ADDRESS_WIDTH-1:0]          read_pointer;
   logic [MEMORY_ADDRESS_WIDTH-1:0]          read_write_pointer;
   logic                                     read_empty; 
   logic [MEMORY_ADDRESS_WIDTH-1:0]          latest_startofpacket_address;
   logic [MEMORY_ADDRESS_WIDTH-1:0]          eop_write_ptr_for_gray_convertion;
   logic                                     RG_rx_startofpacket;
   logic                                     RG_rx_endofpacket;
   logic                                     lock_write_full;
   logic                                     csr_avmm_write_on_tx_clk;
   logic [STAT_CNTRS_WIDTH-1:0]              drop_cnt_written_packets;
   logic [STAT_CNTRS_WIDTH-1:0]              drop_cnt_full;
   logic [STAT_CNTRS_WIDTH-1:0]              drop_cnt_error;
   logic                                     init_done;
   logic                                     rx_packet_in_process;
   logic                                     RG_rx_packet_in_process;
   logic                                     RG_rx_ready;
   logic                                     RG_rx_valid;
   logic                                     RG_rx_error_was_resent;
   logic [MEMORY_ADDRESS_WIDTH-1:0]          write_fill_level;
   logic [MEMORY_ADDRESS_WIDTH-1:0]          read_fill_level;
   logic                                     rx_ready_local;

   always_comb fill_level_on_tx_clk               = read_fill_level;

   //-- CSR Avalon MM begin --
   cdc_avmm_sync_v2 #(
       .ADDR_WIDTH     (CSR_MM_ADDR_WIDTH)
      ,.DATA_WIDTH     (AVST_DATA_WIDTH)
   ) cdc_avmm_sync_inst (
       .i_mm_waitrequest    (csr_mm_waitrequest)
      ,.i_mm_read           (csr_mm_read)
      ,.i_mm_write          (csr_mm_write)
      ,.i_mm_addr           (csr_mm_address)
      ,.i_mm_writedata      (csr_mm_writedata)
      ,.i_mm_readdatavalid  (csr_mm_readdatavalid_reg)
      ,.i_mm_readdata       (csr_mm_readdata)
      ,.i_mm_clk            (csr_mm_clk)
      ,.i_mm_reset          (csr_mm_reset)
      ,.o_mm_read           (csr_mm_on_rx_clk_read)
      ,.o_mm_write          (csr_mm_on_rx_clk_write)
      ,.o_mm_addr           (csr_mm_on_rx_clk_address)
      ,.o_mm_readdata       (csr_mm_on_rx_clk_readdata)
      ,.o_mm_waitrequest    ('0)
      ,.o_mm_clk            (in_avst_clk)
      ,.o_mm_reset          (in_avst_reset)
   );

   localparam bit [1:0] DROP_CNTR_FULL_ADDR             = 2'b00
                       ,DROP_CNTR_ERROR_ADDR            = 2'b01
                       ,DROP_CNTR_WRITTEN_PACKETS_ADDR  = 2'b10;

   always_ff @(posedge csr_mm_clk) begin
      csr_mm_readdatavalid <= csr_mm_readdatavalid_reg;
   end

   always_ff @(posedge in_avst_clk) begin
      if (in_avst_reset) begin
         csr_mm_on_rx_clk_readdata <= '0;
      end else if (csr_mm_on_rx_clk_read) begin
         case (csr_mm_on_rx_clk_address)
            DROP_CNTR_FULL_ADDR: begin
               csr_mm_on_rx_clk_readdata <= drop_cnt_full;
            end
            DROP_CNTR_ERROR_ADDR: begin
               csr_mm_on_rx_clk_readdata <= drop_cnt_error;
            end
            DROP_CNTR_WRITTEN_PACKETS_ADDR: begin
               csr_mm_on_rx_clk_readdata <= drop_cnt_written_packets;
            end
            default: begin
               csr_mm_on_rx_clk_readdata <= 32'hDEF0DEF0;
            end
         endcase
      end
   end
// -- CSR Avalon MM end --
   always_comb begin
      write_fill_level    = write_pointer - write_read_pointer;
      write_full          = write_fill_level >= MEMORY_FULL[MEMORY_ADDRESS_WIDTH-1:0];
      read_empty          = (read_pointer == read_write_pointer);
      read_ready          = out_avst_ready || !out_avst_valid;
      read_enable         = !read_empty && read_ready;
   end

   always_comb rx_data_ext[AVST_DATA_WIDTH-1:0]    = in_avst_data;
   always_comb in_avst_ready                       = USE_RX_READY ? write_ready : init_done;

   if (RX_AVST_READY_LATENCY!=0) begin : ready_latency_not_zero

      logic rx_ready_adjusted_to_latency_zero;
      logic [RX_AVST_READY_LATENCY-1:0] data_for_shift_reg;
      logic [RX_AVST_READY_LATENCY-1:0] rx_ready_shift_reg;

      always_comb rx_ready_adjusted_to_latency_zero = rx_ready_shift_reg[RX_AVST_READY_LATENCY-1];

      always_ff @(posedge in_avst_clk) begin
         rx_ready_shift_reg <= data_for_shift_reg;
      end

      always_comb rx_ready_local = rx_ready_adjusted_to_latency_zero;

      if (RX_AVST_READY_LATENCY==1) begin : ready_latency_one
         always_comb data_for_shift_reg = in_avst_ready;
      end else if (RX_AVST_READY_LATENCY>1) begin : ready_latency_bigger_than_one
         always_comb data_for_shift_reg = {rx_ready_shift_reg[RX_AVST_READY_LATENCY-2:0],in_avst_ready};
      end
   end else begin : ready_latency_zero
      always_comb rx_ready_local = in_avst_ready;
   end

   always_comb out_avst_valid = read_valid;
   always_comb out_avst_data = read_data[AVST_DATA_WIDTH-1:0];

   always_ff @(posedge in_avst_clk) begin
      if (in_avst_reset) begin
         latest_startofpacket_address <= 1'b0;
      end else if (write_enable && RG_rx_valid && RG_rx_ready &&  RG_rx_endofpacket) begin
         latest_startofpacket_address <= write_pointer + 1'b1;
      end
   end

   always_ff @(posedge in_avst_clk) begin
      if (in_avst_reset) begin
         write_ready <= 1'b0;
         write_enable <= 1'b0;
         init_done <= 1'b0;
         lock_write_full <= 1'b0;
      end else begin
         init_done <= 1'b1;
         write_ready <= !write_full;
         write_enable <= in_avst_valid && rx_ready_local
            && !(in_avst_error!=0 && in_avst_endofpacket)
            &&(!lock_write_full || (in_avst_startofpacket && !write_full))
            && (rx_packet_in_process || in_avst_startofpacket);
         if (write_full) begin
            lock_write_full <= (USE_RX_READY ? 1'b0 : 1'b1);
         end else if (in_avst_valid && rx_ready_local && in_avst_startofpacket) begin
            lock_write_full <= 1'b0;
         end
      end
   end

   always_ff @(posedge in_avst_clk) begin
      if (in_avst_reset) begin
         rx_packet_in_process <= 1'b0;
      end else if (in_avst_valid && rx_ready_local && in_avst_startofpacket
         && !in_avst_endofpacket) begin
         rx_packet_in_process <= 1'b1;
      end else if (in_avst_valid && rx_ready_local && in_avst_endofpacket) begin
         rx_packet_in_process <= 1'b0;
      end
   end

   always_ff @(posedge in_avst_clk) begin
      if (in_avst_reset) begin
         drop_cnt_written_packets <= '0;
      end else if (csr_mm_on_rx_clk_write) begin
         drop_cnt_written_packets <= '0;
      end else if (write_enable && RG_rx_endofpacket && RG_rx_valid && RG_rx_ready && !RG_rx_error_was_resent) begin
         drop_cnt_written_packets <= drop_cnt_written_packets + 1'b1;
      end
   end

   cdc_synchronizer #(
      .WIDTH(1)
   ) inst_cdc_sync__csr_avn_write_sync (
      .out_clk(out_avst_clk),
      .out_reset(out_avst_reset),
      .in_data(csr_mm_write),
      .out_data(csr_avmm_write_on_tx_clk)
   );

   always_ff @(posedge in_avst_clk) begin
      if (in_avst_reset) begin
         drop_cnt_full <= '0;
      end else if (csr_mm_on_rx_clk_write) begin
         drop_cnt_full <= '0;
      end else if (!write_enable && RG_rx_endofpacket && RG_rx_valid && RG_rx_ready && !RG_rx_error_was_resent && (RG_rx_packet_in_process || RG_rx_startofpacket) && lock_write_full) begin
         drop_cnt_full <= drop_cnt_full + 1'b1;
      end
   end

   always_ff @(posedge in_avst_clk) begin
      if (in_avst_reset) begin
         drop_cnt_error <= '0;
      end else if (csr_mm_on_rx_clk_write) begin
         drop_cnt_error <= '0;
      end else if (in_avst_valid && rx_ready_local && (in_avst_error!=0 && in_avst_endofpacket)) begin
         drop_cnt_error <= drop_cnt_error + 1'b1;
      end
   end

   always_ff @(posedge in_avst_clk) begin
      if (in_avst_reset) begin
         write_data <= '0;
         RG_rx_startofpacket <= '0;
         RG_rx_endofpacket <= '0;
         RG_rx_valid <= '0;
         RG_rx_ready <= '0;
         RG_rx_packet_in_process <= '0;
         RG_rx_error_was_resent <= '0;
      end else begin
         write_data <= rx_data_ext;
         RG_rx_startofpacket <= in_avst_startofpacket;
         RG_rx_endofpacket <= in_avst_endofpacket;
         RG_rx_valid <= in_avst_valid;
         RG_rx_ready <= rx_ready_local;
         RG_rx_packet_in_process <= rx_packet_in_process;
         RG_rx_error_was_resent <= (in_avst_error != 0);
      end
   end

   always_ff @(posedge out_avst_clk) begin
      if (out_avst_reset) begin
         read_valid <= 1'b0;
         read_enable_q1 <= 1'b0;
      end else if (read_ready) begin
         read_enable_q1 <= read_enable;
         read_valid <= read_enable_q1;
      end
   end

   always_ff @(posedge in_avst_clk) begin
      if (in_avst_reset) begin
         write_pointer <= '0;
         eop_write_ptr_for_gray_convertion <= '0;
      end else if (write_enable) begin
         if (in_avst_valid && rx_ready_local
            && ((rx_packet_in_process && in_avst_startofpacket)
            || (in_avst_error!=0 && in_avst_endofpacket
            && !(RG_rx_endofpacket && RG_rx_valid && RG_rx_ready)))) begin
               write_pointer <= latest_startofpacket_address;
         end else begin
            write_pointer <= write_pointer + 1'b1;
         end
         if (RG_rx_valid && RG_rx_endofpacket) begin
            eop_write_ptr_for_gray_convertion <= write_pointer + 1'b1;
         end
      end else if (lock_write_full
         ||(in_avst_valid && rx_ready_local && rx_packet_in_process && in_avst_startofpacket)
         || (in_avst_valid && rx_ready_local && in_avst_error!=0 && in_avst_endofpacket)) begin
         write_pointer <= latest_startofpacket_address;
      end
   end

   period_bus_sync #(
      .BUS_SIZE (MEMORY_ADDRESS_WIDTH)
   ) translate_write_pointer (
      .in_clk(in_avst_clk),
      .in_reset(in_avst_reset),
      .out_clk(out_avst_clk),
      .out_reset(out_avst_reset),
      .in_data(eop_write_ptr_for_gray_convertion),
      .out_data(read_write_pointer)
   );

   period_bus_sync #(
      .BUS_SIZE (MEMORY_ADDRESS_WIDTH)
   ) translate_fill_level (
      .in_clk(in_avst_clk),
      .in_reset(in_avst_reset),
      .out_clk(out_avst_clk),
      .out_reset(out_avst_reset),
      .in_data(write_fill_level),
      .out_data(read_fill_level)
   );

   always_ff @(posedge out_avst_clk) begin
      if (out_avst_reset) begin
         read_pointer <= '0;
      end else if (read_enable) begin
         read_pointer <= read_pointer + 1'b1;
      end else begin
         read_pointer <= read_pointer;
      end
   end

   period_bus_sync #(
      .BUS_SIZE (MEMORY_ADDRESS_WIDTH)
   ) translate_read_pointer (
      .in_clk(out_avst_clk),
      .in_reset(out_avst_reset),
      .out_clk(in_avst_clk),
      .out_reset(in_avst_reset),
      .in_data(read_pointer),
      .out_data(write_read_pointer)
   );

   if(DEVICE=="a10") begin
      a10_memory #(
         .CAPACITY(MEMORY_CAPACITY_WORDS),
         .DATA_WIDTH(MEMORY_DATA_WIDTH)
      ) memory_a10 (
         .read_areset(1'b0),
         .write_clk(in_avst_clk),
         .write_enable(write_enable),
         .write_pointer(write_pointer),
         .write_data(write_data),
         .read_clk(out_avst_clk),
         .read_ready(read_ready),
         .read_enable(read_enable),
         .read_pointer(read_pointer),
         .read_data(read_data)
      );
   end else if(DEVICE=="s10") begin
      s10_memory #(
         .CAPACITY(MEMORY_CAPACITY_WORDS),
         .DATA_WIDTH(MEMORY_DATA_WIDTH)
      ) memory_s10 (
         .read_areset(1'b0),
         .write_clk(in_avst_clk),
         .write_enable(write_enable),
         .write_pointer(write_pointer),
         .write_data(write_data),
         .read_clk(out_avst_clk),
         .read_ready(read_ready),
         .read_enable(read_enable),
         .read_pointer(read_pointer),
         .read_data(read_data)
      );
   end

   always_comb rx_data_ext[AVST_DATA_WIDTH+:(2+AVST_EMPTY_WIDTH+AVST_USER_WIDTH)] = {
      in_avst_startofpacket, in_avst_endofpacket, in_avst_empty, in_avst_user};

   always_comb {out_avst_startofpacket, out_avst_endofpacket, out_avst_empty, out_avst_user} =
      read_data[AVST_DATA_WIDTH+:(2+AVST_EMPTY_WIDTH+AVST_USER_WIDTH)];

endmodule