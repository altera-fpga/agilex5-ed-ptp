//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

module cdc_avmm_sync_v2 #(
    parameter ADDR_WIDTH = 32
   ,parameter DATA_WIDTH = 32
)(
    input  logic                    i_mm_clk
   ,input  logic                    i_mm_reset
   ,output logic                    i_mm_waitrequest
   ,input  logic                    i_mm_write
   ,input  logic                    i_mm_read
   ,input  logic [ADDR_WIDTH - 1:0] i_mm_addr
   ,input  logic [DATA_WIDTH - 1:0] i_mm_writedata
   ,output logic [DATA_WIDTH - 1:0] i_mm_readdata
   ,output logic                    i_mm_readdatavalid
   // AvalonMM slaves
   ,input  logic                    o_mm_clk
   ,input  logic                    o_mm_reset
   ,input  logic                    o_mm_waitrequest
   ,output logic                    o_mm_write
   ,output logic                    o_mm_read
   ,output logic [ADDR_WIDTH - 1:0] o_mm_addr
   ,output logic [DATA_WIDTH - 1:0] o_mm_writedata
   ,input  logic [DATA_WIDTH - 1:0] o_mm_readdata
);

   logic in_mm_transaction_lock;
   logic out_mm_transaction_lock;
   logic new_mm_transaction_on_o_mm_clk;
   logic new_mm_transaction;
   logic mm_cmd_done;
   logic mm_cmd_done_on_mm_clk;
   logic mm_cmd_done_on_mm_clk_reg;
   logic read_reg;
   logic write_reg;

   always_ff @(posedge o_mm_clk) begin
      if (o_mm_reset) begin
         out_mm_transaction_lock <= 1'b0;
      end else if ((o_mm_read || o_mm_write) && !o_mm_waitrequest) begin
         out_mm_transaction_lock <= 1'b0;
      end else if (new_mm_transaction_on_o_mm_clk) begin
         out_mm_transaction_lock <= 1'b1;
      end
   end

   always_ff @(posedge i_mm_clk) begin
      if (i_mm_reset) begin
         in_mm_transaction_lock <= 1'b0;
      end else if (mm_cmd_done_on_mm_clk) begin
         in_mm_transaction_lock <= 1'b0;
      end else if (i_mm_read || i_mm_write) begin
         in_mm_transaction_lock <= 1'b1;
      end
      if (i_mm_reset) begin
         mm_cmd_done_on_mm_clk_reg <= '0;
      end else begin
         mm_cmd_done_on_mm_clk_reg <= mm_cmd_done_on_mm_clk;
      end
   end

   always_ff@(posedge i_mm_clk ) begin
      if (i_mm_reset) begin
         read_reg <= '0;
         write_reg <= '0;
      end else begin
         if (!i_mm_waitrequest && !in_mm_transaction_lock) begin
            read_reg <= i_mm_read;
            write_reg <= i_mm_write;
            o_mm_addr <= i_mm_addr;
            o_mm_writedata <= i_mm_writedata;
         end
      end
   end

   assign new_mm_transaction = (i_mm_read || i_mm_write) && !in_mm_transaction_lock;

   cdc_toggle_synchronizer translate_mm_transaction (
       .in_clk(i_mm_clk),
       .in_reset(i_mm_reset),
       .out_clk(o_mm_clk),
       .in_pulse(new_mm_transaction),
       .out_pulse(new_mm_transaction_on_o_mm_clk)
   );

   always_comb begin
       o_mm_read  = (new_mm_transaction_on_o_mm_clk || out_mm_transaction_lock) && read_reg;
       o_mm_write = (new_mm_transaction_on_o_mm_clk || out_mm_transaction_lock) && write_reg;
       i_mm_waitrequest = in_mm_transaction_lock && !(mm_cmd_done_on_mm_clk_reg && read_reg);
       i_mm_readdatavalid = mm_cmd_done_on_mm_clk_reg && read_reg;
   end

   always_ff@(posedge o_mm_clk) begin
      if(mm_cmd_done) begin
         i_mm_readdata <= o_mm_readdata;
      end
   end

   always_ff @(posedge o_mm_clk) begin
       if (o_mm_reset) begin
           mm_cmd_done<= '0;
       end else if ((new_mm_transaction_on_o_mm_clk || out_mm_transaction_lock) && (o_mm_read || o_mm_write) && !o_mm_waitrequest) begin
           mm_cmd_done <= 1'b1;
       end else begin
           mm_cmd_done <= 1'b0;
       end
   end

   cdc_toggle_synchronizer translate_mm_cmd_done (
       .in_clk   (o_mm_clk),
       .in_reset (o_mm_reset),
       .out_clk  (i_mm_clk),
       .in_pulse (mm_cmd_done),
       .out_pulse(mm_cmd_done_on_mm_clk)
   );
endmodule
